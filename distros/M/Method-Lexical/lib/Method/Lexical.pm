package Method::Lexical;

use 5.008001;

use strict;
use warnings;

use B::Hooks::EndOfScope;
use B::Hooks::OP::Check;
use B::Hooks::OP::Annotation;
use Carp qw(carp confess);
use Devel::Pragma qw(ccstash fqname my_hints new_scope on_require);
use XSLoader;

our $VERSION = '0.30';
our @CARP_NOT = qw(B::Hooks::EndOfScope);

XSLoader::load(__PACKAGE__, $VERSION);

my $DEBUG = xs_get_debug(); # flag indicating whether debug messages should be printed

# The key under which the $installed hash is installed in %^H i.e. 'Method::Lexical'
# Defined as a preprocessor macro in Lexical.xs to ensure the Perl and XS are kept in sync
my $METHOD_LEXICAL = xs_signature();

# accessors for the debug flags - note there is one for Perl ($DEBUG) and one defined
# in the XS (METHOD_LEXICAL_DEBUG). The accessors ensure that the two are kept in sync
sub _get_debug()   { $DEBUG }
sub _set_debug($)  { xs_set_debug($DEBUG = shift || 0) }

# This logs method installations/uninstallations
sub _debug {
    my ($class, $action, $fqname) = @_;
    carp "$class: $action $fqname";
}

# return true if $ref ISA $class - works with non-references, unblessed references and objects
sub _isa($$) {
    my ($ref, $class) = @_;
    return Scalar::Util::blessed(ref) ? $ref->isa($class) : ref($ref) eq $class;
}

# given a fully-qualified subroutine name (e.g. Foo::Bar::baz) load the module (Foo::Bar)
sub _load($) {
    my $fqname = shift;
    my ($module, $subname) = fqname($fqname);

    eval "require $module";

    if ($@) {
        no strict 'refs';
        # don't raise an error if the package is declared in an already-loaded file
        confess "Can't load $module for subroutine $fqname: $@" unless (%{"$module\::"});
    }
}

# install one or more lexical methods in the current scope
#
# import() has to keep track of two things:
#
# 1) $installed keeps track of *all* currently active lexical methods so that Lexical.xs
#    can track them without needing to know the subclass of Method::Lexical that installed them
# 2) $class_data keeps track of which subs have been installed by this class (which may be a subclass of
#    Method::Lexical) in this scope, so that they can be unimported with "no MyPragma (...)"

sub import {
    my $class = shift;
    my %bindings = ((@_ == 1) && _isa($_[0], 'HASH')) ? %{shift()} : @_; # hash or hashref

    return unless (%bindings);

    my $autoload = delete $bindings{-autoload};
    my $debug = delete $bindings{-debug};
    my $hints = my_hints;
    my $caller = ccstash();
    my $installed;

    if (defined $debug) {
        my $old_debug = _get_debug();
        if ($debug != $old_debug) {
            _set_debug($debug);
            on_scope_end { _set_debug($old_debug) };
        }
    }

    if (new_scope($METHOD_LEXICAL)) {
        my $top_level = 0;
        my $temp = $hints->{$METHOD_LEXICAL};

        if ($temp) {
            # the hash is cloned to ensure that inner/nested scopes don't clobber/contaminate
            # outer/previous scopes with their new bindings. Likewise, unimport installs
            # a new hash to ensure that previous bindings aren't clobbered e.g.
            #
            #   {
            #        package Foo;
            #
            #        use Method::Lexical bar => sub { ... };
            #
            #        Foo->new->bar();
            #
            #        no Method::Lexical; # don't clobber the bindings associated with the previous method call
            #   }

            $installed = $hints->{$METHOD_LEXICAL} = { %$temp }; # clone
        } else {
            $top_level = 1;
            $installed = $hints->{$METHOD_LEXICAL} = {}; # create

            # disable Method::Lexical altogether when we leave the top-level scope in which it was enabled
            on_scope_end \&xs_leave;

            # disable/re-enable check hooks before/after require
            on_require \&xs_leave, \&xs_enter;

            xs_enter();
        }
    } else {
        $installed = $hints->{$METHOD_LEXICAL}; # augment
    }

    # Note: the class-specific data is stored under "Method::Lexical($subclass)" rather than
    # $subclass. The subclass might well have its own uses for $^H{$subclass}, so we keep
    # our mitts off it
    #
    # Also, the unadorned class name can't be used as a key if $METHOD_LEXICAL is 'Method::Lexical' (which
    # it is) as the two uses conflict with and clobber each other

    my $subclass = "$METHOD_LEXICAL($class)";
    my $class_data;

    # never use $class as the identifier for new_scope() here - see above
    if (new_scope($subclass)) {
        my $temp = $hints->{$subclass};

        $class_data = $hints->{$subclass} = $temp ? { %$temp } : {}; # clone/create
    } else {
        $class_data = $hints->{$subclass}; # augment
    }

    for my $name (keys %bindings) {
        my $sub = $bindings{$name};

        # normalize bindings
        unless (_isa($sub, 'CODE')) {
            my $_autoload = $sub =~ s{^\+}{}; # autoload this sub's package
            my $subname = fqname($sub); # XXX watch out for fqname returning a list

            if ($_autoload || $autoload) {
                _load($subname);
            }

            $sub = do {
                no strict 'refs';
                *{$subname}{CODE}
            } || confess "Can't find subroutine for target $name: '$subname'";
        }

        my $fqname = fqname($name, $caller);

        if ($DEBUG) {
            if (exists $installed->{$fqname}) {
                $class->_debug('redefining', $fqname);
            } else {
                $class->_debug('creating', $fqname);
            }
        }

        $installed->{$fqname} = $sub;
        $class_data->{$fqname} = $sub;
    }
}

# uninstall one or more lexical subs from the current scope
sub unimport {
    my $class = shift;
    my $hints = my_hints;
    my $subclass = "$METHOD_LEXICAL($class)";
    my $class_data;

    return unless (($^H & 0x20000) && ($class_data = $hints->{$subclass}));

    my $caller = ccstash();
    my @subs = @_ ? (map { scalar(fqname($_, $caller)) } @_) : keys(%$class_data);
    my $installed = $hints->{$METHOD_LEXICAL};
    my $new_installed = { %$installed }; # clone
    my $deleted = 0;

    for my $fqname (@subs) {
        my $sub = $class_data->{$fqname};

        if ($sub) { # the coderef of the method this subclass installed
            # if the current sub ($installed->{$fqname}) is the sub this module installed ($class_data->{$fqname})
            if (Scalar::Util::refaddr($sub) == Scalar::Util::refaddr($installed->{$fqname})) {
                $class->_debug('unimporting', $fqname) if ($DEBUG);

                # what import adds, unimport taketh away
                delete $new_installed->{$fqname};
                delete $class_data->{$fqname};

                ++$deleted;
            } else {
                carp "$class: attempt to unimport a shadowed lexical method: $fqname";
            }
        } else {
            carp "$class: attempt to unimport an undefined lexical method: $fqname";
        }
    }

    if ($deleted) {
        $hints->{$METHOD_LEXICAL} = $new_installed;
    }
}

1;

__END__

=head1 NAME

Method::Lexical - private methods and lexical method overrides

=head1 SYNOPSIS

    package MyPragma;

    use base qw(Method::Lexical);

    sub import {
        shift->SUPER::import(
            'private'         => sub { ... },
            'UNIVERSAL::dump' => '+Data::Dump::pp'
        )
    }

=cut

=pod

    #!/usr/bin/env perl

    my $self = bless {};

    {
        use MyPragma;

        $self->private(); # OK
        $self->dump();    # OK
    }

    $self->private; # Can't locate object method "private" via package "main"
    $self->dump;    # Can't locate object method "dump" via package "main"

=head1 DESCRIPTION

C<Method::Lexical> is a lexically-scoped pragma that implements lexical methods i.e. methods
whose use is restricted to the lexical scope in which they are imported or declared.

The C<use Method::Lexical> statement takes a hashref or a list of key/value pairs in which the keys are method
names and the values are subroutine references or strings containing the package-qualified name of the
method to be called. Unqualifed method names in keys are installed as methods in the currently-compiling package.
The following example summarizes the types of keys and values that can be supplied.

    use Method::Lexical {
        foo              => \&foo,               # unqualified method-name key: installed in the currently-compiling package e.g. main::foo
        MyClass::foo     => \&foo,               # qualified method-name key: installed in the specified package
        bar              => sub { ... },         # anonymous sub value
        baz              => \&baz,               # coderef value
        quux             => 'main::quux',        # sub name value: unqualified names are resolved to the currently-compiling package
        dump             => '+Data::Dump::dump', # autoload Data::Dump
       'UNIVERSAL::dump' => \&Data::Dump::dump,  # define a universal method
       'UNIVERSAL::isa'  => \&my_isa,            # override a universal method
      '-autoload'        => 1,                   # autoload modules for all subs passed by name
      '-debug'           => 1                    # show diagnostic messages
    };

=head1 OPTIONS

C<Method::Lexical> options are prefixed with a hyphen to distinguish them from method names.
The following options are supported.

=head2 -autoload

If the C<value> is a string containing a package-qualified subroutine name, then the subroutine's module is
automatically loaded. This can either be done on a per-method basis by prefixing the C<value>
with a C<+>, or for all C<value> arguments with qualified names by supplying the
C<-autoload> option with a true value e.g.

    use Method::Lexical {
         foo       => 'MyFoo::foo',
         bar       => 'MyBar::bar',
         baz       => 'MyBaz::baz',
       '-autoload' => 1
    };

or

    use MyFoo;
    use MyBaz;

    use Method::Lexical
         foo =>  'MyFoo::foo',
         bar => '+MyBar::bar', # autoload MyBar
         baz =>  'MyBaz::baz';

This option should not be confused with lexical AUTOLOAD methods, which are also supported e.g.

    use Method::Lexical
        AUTOLOAD             => sub { ... },
       'UNIVERSAL::AUTOLOAD' => \&autoload;

=head2 -debug

A trace of the module's actions can be enabled or disabled lexically by supplying the C<-debug> option
with a true or false value. The trace is printed to STDERR.

e.g.

    use Method::Lexical {
         foo    => \&foo,
         bar    => sub { ... },
       '-debug' => 1
    };

=head1 METHODS

=head2 import

C<Method::Lexical::import> can be called indirectly via C<use Method::Lexical> or can be overridden by subclasses to create
lexically-scoped pragmas that export methods whose use is restricted to the calling scope e.g.

    package Universal::Dump;

    use base qw(Method::Lexical);

    sub import { shift->SUPER::import('UNIVERSAL::dump' => '+Data::Dump::dump') }

    1;

Client code can then import lexical methods from the module:

    #!/usr/bin/env perl

    use CGI;

    {
        use Universal::Dump;

        say CGI->new->dump; # OK
    }

    eval { CGI->new->dump };
    warn $@; # Can't locate object method "dump" via package "CGI"

=head2 unimport

C<Method::Lexical::unimport> removes the specified lexical methods from the current scope, or all lexical methods
if no arguments are supplied.

    use Method::Lexical foo => \&foo;

    my $self = bless {};

    {
        use Method::Lexical
             bar             => sub { ... },
            'UNIVERSAL::baz' => sub { ... };

        $self->foo(); # OK
        $self->bar(); # OK
        $self->baz(); # OK

        no Method::Lexical qw(foo);

        eval { $self->foo() };
        warn $@; # Can't locate object method "foo" via package "main"

        $self->bar(); # OK
        $self->baz(); # OK

        no Method::Lexical;

        eval { $self->bar() };
        warn $@; # Can't locate object method "bar" via package "main"

        eval { $self->baz() };
        warn $@; # Can't locate object method "baz" via package "main"
    }

    $self->foo(); # OK

Unimports are specific to the class supplied in the C<no> statement, so pragmas that subclass
C<Method::Lexical> inherit an C<unimport> method that only removes the methods they installed e.g.

    {
        use MyPragma qw(foo bar baz);

        use Method::Lexical quux => \&quux;

        $self->foo();  # OK
        $self->quux(); # OK

        no MyPragma qw(foo); # unimports foo
        no MyPragma;         # unimports bar and baz
        no Method::Lexical;  # unimports quux
    }

=head1 CAVEATS

Lexical methods must be defined before any invocations of those methods are compiled, otherwise
those invocations will be compiled as ordinary method calls. This won't work:

    sub public {
        my $self = shift;
        $self->private(); # not a private method; compiled as an ordinary (public) method call
    }

    use Method::Lexical private => sub { ... };

This works:

    use Method::Lexical private => sub { ... };

    sub public {
        my $self = shift;
        $self->private(); # OK
    }

Method calls on glob or filehandle invocants are interpreted as ordinary method calls.

The method resolution order for lexical method calls on pre-5.10 perls is currently fixed at depth-first search.

=head1 VERSION

0.30

=head1 SEE ALSO

=over

=item * L<mysubs|mysubs>

=item * L<Sub::Lexical|Sub::Lexical>

=item * L<Class::Fields|Class::Fields>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
