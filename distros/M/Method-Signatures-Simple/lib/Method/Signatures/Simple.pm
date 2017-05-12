package Method::Signatures::Simple;
{
  $Method::Signatures::Simple::VERSION = '1.07';
}

use warnings;
use strict;

=head1 NAME

Method::Signatures::Simple - Basic method declarations with signatures, without source filters

=head1 VERSION

version 1.07

=cut

use base 'Devel::Declare::MethodInstaller::Simple';

sub import {
    my $class = shift;
    my %opts  = @_;
    $opts{into} ||= caller;

    my $meth = delete $opts{name} || delete $opts{method_keyword};
    my $func = delete $opts{function_keyword};

    # if no options are provided at all, then we supply defaults
    unless (defined $meth || defined $func) {
        $meth = 'method';
        $func = 'func';
    }

    # we only install keywords that are requested
    if (defined $meth) {
        $class->install_methodhandler(
        name     => $meth,
        invocant => '$self',
        %opts,
        );
    }
    if (defined $func) {
        $class->install_methodhandler(
          name     => $func,
          %opts,
          invocant => undef,
        );
    }
}

sub strip_proto {
    my $self = shift;
    my ($proto) = $self->SUPER::strip_proto()
      or return '';
    # we strip comments and newlines here, and stash the number of newlines.
    # we will re-inject the newlines in strip_attrs(), because DD does not
    # like it when you inject them into the following code block. it does not
    # object to tacking on newlines to the code attribute spec though.
    # (see the call to inject_if_block() in DD::MethodInstaller::Simple->parser)
    $proto =~ s/\s*#.*$//mg;
    $self->{__nls} = $proto =~ s/[\r\n]//g;
    $proto;
}

sub strip_attrs {
    my $self = shift;
    my ($attrs) = $self->SUPER::strip_attrs();
    $attrs ||= '';
    $attrs .= $/ x $self->{__nls} if $self->{__nls};
    $attrs;
}

sub parse_proto {
    my $self = shift;
    my ($proto) = @_;
    $proto ||= '';
    $proto =~ s/\s*#.*$//mg;
    $proto =~ s/^\s+//mg;
    $proto =~ s/\s+$//mg;
    $proto =~ s/[\r\n]//g;
    my $invocant = $self->{invocant};

    $invocant = $1 if $proto =~ s{(\$\w+)\s*:\s*}{};

    my $inject = '';
    $inject .= "my ${invocant} = shift;" if $invocant;
    $inject .= "my ($proto) = \@_;"      if defined $proto and length $proto;
    $inject .= '();'; # fix for empty method body

    return $inject;
}


=head1 SYNOPSIS

    # -- a basic class -- #
    package User;
    use Method::Signatures::Simple;

    method new ($class: $name, $email) {
        my $user = {
            id    => new_id(42),
            name  => $name,
            email => $email,
        };
        bless $user, $class;
    }

    func new_id ($seed) {
        state $id = $seed;
        $id++;
    }

    method name  { $self->{name};  }
    method email { $self->{email}; }
    1;


    # -- other features -- #
    # attributes
    method foo : lvalue { $self->{foo} }

    # change invocant name
    use Method::Signatures::Simple invocant => '$this';
    method foo ($bar) { $this->bar($bar) }
    method bar ($class: $bar) { $class->baz($bar) }

    # use a different function keyword
    use Method::Signatures::Simple function_keyword => 'fun';
    fun triple ($num) { 3 * $num }

    # use a different method keyword
    use Method::Signatures::Simple method_keyword => 'action';
    action foo { $self->bar }

=head1 RATIONALE

This module provides basic C<method> and C<func> keywords with simple
signatures. It's intentionally simple, and is supposed to be a stepping stone
for its bigger brothers L<MooseX::Method::Signatures> and
L<Method::Signatures>.  It only has a small benefit over regular subs, so
if you want more features, look at those modules.  But if you're looking
for a small amount of syntactic sugar, this might just be enough.

=head1 FEATURES

=over 4

=item * invocant

The C<method> keyword automatically injects the annoying C<my $self = shift;>
for you. You can rename the invocant with the first argument, followed by a
colon:

    method ($this:) {}
    method ($this: $that) {}

The C<func> keyword doesn't inject an invocant, but does do the signature
processing below:

    func ($that) {}

=item * signature

The signature C<($sig)> is transformed into C<"my ($sig) = \@_;">. That way, we
mimic perl's usual argument handling.

    method foo ($bar, $baz, %opts) {
    func xyzzy ($plugh, @zorkmid) {

    # becomes

    sub foo {
        my $self = shift;
        my ($bar, $baz, %opts) = @_;

    sub xyzzy {
        my ($plugh, @zorkmid) = @_;

=back

=head1 ADVANCED CONFIGURATION

Since this module subclasses L<Devel::Declare::MethodInstaller::Simple>, you
can change the keywords and the default invocant with import arguments. These
changes affect the current scope.

=over 4

=item * change the invocant name

    use Method::Signatures::Simple invocant => '$this';
    method x { $this->{x} }
    method y { $this->{y} }

    # and this of course still works:
    method z ($self:) { $self->{z} }

=item * change the keywords

You can install a different keyword (instead of the default 'method' and
'func'), by passing names to the C<use> line:

    use Method::Signatures::Simple method_keyword   => 'action',
                                   function_keyword => 'thing';

    action foo ($some, $args) { ... }
    thing bar ($whatever) { ... }

One benefit of this is that you can use this module together with e.g.
L<MooseX::Declare>:

    # untested
    use MooseX::Declare;

    class Foo {
        use Method::Signatures::Simple method_keyword => 'routine';
        method x (Int $x) { ... }    # from MooseX::Method::Signatures
        routine y ($y) { ... }       # from this module
    }

If you specify neither C<method_keyword> nor C<function_keyword>, then we
default to injecting C<method> and C<func>. If you only specify one of these
options, then we only inject that one keyword into your scope.

Examples:

    # injects 'method' and 'func'
    use Method::Signatures::Simple;

    # only injects 'action'
    use Method::Signatures::Simple method_keyword => 'action';

    # only injects 'procedure'
    use Method::Signatures::Simple function_keyword => 'procedure';

    # injects 'action' and 'function'
    use Method::Signatures::Simple method_keyword   => 'action',
                                   function_keyword => 'function';

=item * install several keywords

You're not limited to a single C<use> line, so you can install several keywords with the same
semantics as 'method' into the current scope:

    use Method::Signatures::Simple; # provides 'method' and 'func'
    use Method::Signatures::Simple method_keyword => 'action';

    method x { ... }
    func y { ... }
    action z { ... }

=back

=begin pod-coverage

=over 4

=item parse_proto

Overridden.

=back

=end pod-coverage

=head1 AUTHOR

Rhesa Rozendaal, C<< <rhesa at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-method-signatures-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-Signatures-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Method::Signatures::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Signatures-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Method-Signatures-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Method-Signatures-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Method-Signatures-Simple>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * MSTROUT

For writing L<Devel::Declare> and providing the core concepts.

=item * MSCHWERN

For writing L<Method::Signatures> and publishing about it. This is what got my attention.

=item * FLORA

For helping me abstracting the Devel::Declare bits and suggesting improvements.

=item * CHIPS

For suggesting we add a 'func' keyword.

=back

=head1 SEE ALSO

L<Devel::Declare>, L<Method::Signatures>, L<MooseX::Method::Signatures>.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Method::Signatures::Simple
