use strict;
use warnings;
package HTML::MasonX::Free::Component 0.007;
# ABSTRACT: a component with a "main" method, not just a bunch of text

use parent 'HTML::Mason::Component::FileBased';

#pod =head1 OVERVIEW
#pod
#pod In concept, a Mason component is broken down into special blocks (like once,
#pod shared, init), methods, and subcomponents.  When you render a Mason component,
#pod using it as a template, you aren't calling one of its methods or blocks.
#pod Instead, all the stray code and text that was found I<outside> all of those is
#pod concatenated together and run.
#pod
#pod This is sort of a mess.
#pod
#pod If you use HTML::MasonX::Free::Component as your component class instead,
#pod rendering the component will call its C<main> method instead of all that other
#pod junk.  This component class extends HTML::Mason::Component::FileBased.  If this
#pod is a problem because of your esoteric Mason configuration, don't panic.  Just
#pod read the source.  Seriously, it's tiny.
#pod
#pod This component class is meant to work well with
#pod L<HTML::MasonX::Free::Compiler>, which will let you throw a syntax exception if
#pod there's any significant content outside of blocks, and which can apply
#pod C<default_method_to_call> to calls found when compiling.
#pod
#pod You can pass a C<default_method_to_call> argument to the constructor for this
#pod class, but it's not all that easy to get where you need it, so maybe you should
#pod stick with the default: C<main>
#pod
#pod =cut

sub new {
  my ($class, %arg) = @_;
  my $default_method_to_call = delete $arg{default_method_to_call} || 'main';
  my $self = $class->SUPER::new(%arg);
  $self->{default_method_to_call} = $default_method_to_call;
  return $self;
}

sub run {
  my $self = shift;
  $self->{mfu_count}++;
  $self->call_method($self->{default_method_to_call} => @_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::MasonX::Free::Component - a component with a "main" method, not just a bunch of text

=head1 VERSION

version 0.007

=head1 OVERVIEW

In concept, a Mason component is broken down into special blocks (like once,
shared, init), methods, and subcomponents.  When you render a Mason component,
using it as a template, you aren't calling one of its methods or blocks.
Instead, all the stray code and text that was found I<outside> all of those is
concatenated together and run.

This is sort of a mess.

If you use HTML::MasonX::Free::Component as your component class instead,
rendering the component will call its C<main> method instead of all that other
junk.  This component class extends HTML::Mason::Component::FileBased.  If this
is a problem because of your esoteric Mason configuration, don't panic.  Just
read the source.  Seriously, it's tiny.

This component class is meant to work well with
L<HTML::MasonX::Free::Compiler>, which will let you throw a syntax exception if
there's any significant content outside of blocks, and which can apply
C<default_method_to_call> to calls found when compiling.

You can pass a C<default_method_to_call> argument to the constructor for this
class, but it's not all that easy to get where you need it, so maybe you should
stick with the default: C<main>

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
