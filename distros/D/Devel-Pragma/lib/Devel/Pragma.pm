package Devel::Pragma;

use 5.008001;

# make sure this is loaded first
use Lexical::SealRequireHints;

use strict;
use warnings;

use Carp qw(carp croak);
use Scalar::Util;
use XSLoader;

use base qw(Exporter);

our $VERSION = '1.1.0';
our @EXPORT_OK = qw(my_hints hints new_scope ccstash scope fqname);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

XSLoader::load(__PACKAGE__, $VERSION);

# return a reference to the hints hash
sub my_hints() {
    # set HINT_LOCALIZE_HH (0x20000)
    $^H |= 0x20000;
    return \%^H;
}

BEGIN { *hints = \&my_hints }

# make sure the "enable lexically-scoped %^H" flag is set (on by default in 5.10)
sub check_hints() {
    unless ($^H & 0x20000) {
        carp('Devel::Pragma: unexpected $^H (HINT_LOCALIZE_HH bit not set) - setting it now, but results may be unreliable');
    }
    return hints; # create it if it doesn't exist - in some perls, it starts out NULL
}

# return a unique integer ID for the current scope
sub scope() {
    check_hints;
    xs_scope();
}

# return a boolean indicating whether this is the first time "use MyPragma" has been called in this scope
sub new_scope(;$) {
    my $caller = shift || caller;
    my $hints = check_hints();

    # this is %^H as an integer - it changes as scopes are entered/exited i.e. it's a unique
    # identifier for the currently-compiling scope (the scope in which new_scope
    # is called)
    #
    # we don't need to stack/unstack it in %^H as %^H itself takes care of that
    # note: we need to call this *after* %^H is referenced (and possibly autovivified) above
    #
    # every time new_scope is called, we write this scope ID to $^H{"Devel::Pragma::new_scope::$caller"}.
    # if $^H{"Devel::Pragma::new_scope::$caller"} == scope() (i.e. the stored scope ID is the same as the
    # current scope ID), then we're augmenting the current scope; otherwise we're in a new scope - i.e.
    # a nested or outer scope that didn't previously "use MyPragma"

    my $current_scope = scope();
    my $id = "Devel::Pragma::new_scope::$caller";
    my $old_scope = exists($hints->{$id}) ? $hints->{$id} : 0;
    my $new_scope; # is this a scope in which new_scope has not previously been called?

    if ($current_scope == $old_scope) {
        $new_scope = 0;
    } else {
        $hints->{$id} = $current_scope;
        $new_scope = 1;
    }

    return $new_scope;
}

# given a short name (e.g. "foo"), expand it into a fully-qualified name with the caller's package prefixed
# e.g. "main::foo"
#
# if the name is already fully-qualified, return it unchanged
sub fqname ($;$) {
    my $name = shift;
    my ($package, $subname);

    $name =~ s{'}{::}g;

    if ($name =~ /::/) {
        ($package, $subname) = $name =~ m{^(.+)::(\w+)$};
    } else {
        my $caller = @_ ? shift : ccstash();
        ($package, $subname) = ($caller, $name);
    }

    return wantarray ? ($package, $subname) : "$package\::$subname";
}

# helper function: return true if $ref ISA $class - works with non-references, unblessed references and objects
sub _isa($$) {
    my ($ref, $class) = @_;
    return Scalar::Util::blessed($ref) ? $ref->isa($class) : ref($ref) eq $class;
}

# make sure "enable lexically-scoped %^H" is set in older perls, and export the requested functions
sub import {
    my $class = shift;
    $^H |= 0x20000; # set HINT_LOCALIZE_HH (0x20000)
    $class->export_to_level(1, undef, @_);
}

1;

__END__

=head1 NAME

Devel::Pragma - helper functions for developers of lexical pragmas

=head1 SYNOPSIS

    package MyPragma;

    use Devel::Pragma qw(:all);

    sub import {
        my ($class, %options) = @_;
        my $hints  = hints;        # the builtin (%^H) used to implement lexical pragmas
        my $caller = ccstash();    # the name of the currently-compiling package (stash)

        unless ($hints->{MyPragma}) { # top-level
            $hints->{MyPragma} = 1;
        }

        if (new_scope($class)) {
            ...
        }

        my $scope_id = scope();
    }

=head1 DESCRIPTION

This module provides helper functions for developers of lexical pragmas (and a few functions that may
be useful to non-pragma developers as well).

Pragmas can be used both in older versions of perl (from 5.8.1), which had limited support, and in
the most recent versions, which have improved support.

=head1 EXPORTS

C<Devel::Pragma> exports the following functions on demand. They can all be imported at once by using
the C<:all> tag. e.g.

    use Devel::Pragma qw(:all);

=head2 hints

This function enables the scoped behaviour of the hints hash (C<%^H>) and then returns a reference to it.

The hints hash is a compile-time global variable (which is also available at runtime in recent perls) that
can be used to implement lexically-scoped features and pragmas. This function provides a convenient
way to access this hash without the need to perform the bit-twiddling that enables it on older perls.
In addition, this module loads L<Lexical::SealRequireHints>, which implements bugfixes
that are required for the correct operation of the hints hash on older perls (< 5.12.0).

Typically, C<hints> should be called from a pragma's C<import> (and optionally C<unimport>) method:

    package MyPragma;

    use Devel::Pragma qw(hints);

    sub import {
        my $class = shift;
        my $hints = hints;

        if ($hints->{MyPragma}) {
            # ...
        } else {
            $hints->{MyPragma} = ...;
        }

        # ...
    }

=head2 new_scope

This function returns true if the currently-compiling scope differs from the scope being compiled the last
time C<new_scope> was called. Subsequent calls will return false while the same scope is being compiled.

C<new_scope> takes an optional parameter that is used to uniquely identify its caller. This should usually be
supplied as the pragma's class name unless C<new_scope> is called by a module that is not intended
to be subclassed. e.g.

    package MyPragma;

    sub import {
        my ($class, %options) = @_;

        if (new_scope($class)) {
            ...
        }
    }

If not supplied, the identifier defaults to the name of the calling package.

=head2 scope

This returns an integer that uniquely identifies the currently-compiling scope. It can be used to
distinguish or compare scopes.

A warning is issued if C<scope> (or C<new_scope>) is called in a context in which it doesn't make sense i.e. if the
scoped behaviour of C<%^H> has not been enabled - either by explicitly modifying C<$^H>, or by calling
L<"hints">.

=head2 ccstash

Returns the name of the currently-compiling package (stash). It only works inside code that's being C<required>,
either in a BEGIN block via C<use> or at runtime. In practice, its use should be restricted to compile-time i.e.
C<import> methods and any other methods/functions that can be traced back to C<import>.

When called from code that isn't being C<require>d, it returns undef.

It can be used as a replacement for the scalar form of C<caller> to provide the name of the package in which
C<use MyPragma> is called. Unlike C<caller>, it returns the same value regardless of the number of
intervening calls before C<MyPragma::import> is reached.

    package Caller;

    use Callee;

    package Callee;

    use Devel::Pragma qw(ccstash);

    sub import {
        A();
    }

    sub A() {
        B();
    }

    sub B {
        C();
    }

    sub C {
        say ccstash; # Caller
    }

=head2 fqname

Takes a subroutine name and an optional caller (package name). If no caller is supplied, it defaults
to L<"ccstash">, which requires C<fqname> to be called from C<import> (or a function/method that can
be traced back to C<import>).

It returns the supplied name in package-qualified form. In addition, old-style C<'> separators are
converted to new-style C<::>.

If the name contains no separators, then the C<caller>/C<ccstash> package name is prepended.
If the name is already package-qualified, it is returned unchanged.

In list context, C<fqname> returns the package and unqualified subroutine name (e.g. 'Foo::Bar' and 'baz'),
and in scalar context it returns the package and sub name joined by '::' (e.g. 'Foo::Bar::baz').

e.g.

    package MyPragma::Loader;

    use MyPragma (\&coderef, 'foo', 'MyPragmaLoader::bar');

    package MyPragma;

    sub import {
        my ($class, @listeners) = @_;
        my @subs;

        for my $listener (@listeners) {
            push @subs, handle_sub($listener);
        }
    }

    sub handle_sub {
        my $sub = shift

        if (ref($ub) eq 'CODE') {
            return $sub;
        } else {
            handle_name($sub);
        }
    }

    sub handle_name {
        my ($package, $name) = fqname($name); # uses ccstash e.g. foo -> MyPragma::Loader::foo
        my $sub = $package->can($name);
        die "no such sub: $package\::$name" unless ($sub);
        return $sub;
    }

=head1 VERSION

1.1.0

=head1 SEE ALSO

=over

=item * L<Devel::Hints|Devel::Hints>

=item * L<Lexical::Hints|Lexical::Hints>

=item * L<Lexical::SealRequireHints|Lexical::SealRequireHints>

=item * L<perlpragma|perlpragma>

=item * L<pragma|pragma>

=item * http://tinyurl.com/45pwzo

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2016 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
