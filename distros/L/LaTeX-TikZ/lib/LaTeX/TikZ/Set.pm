package LaTeX::TikZ::Set;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set - Base role for LaTeX::TikZ set objects.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Context;
use LaTeX::TikZ::Scope;

use LaTeX::TikZ::Tools;

use Mouse::Role;

=head1 ATTRIBUTES

=head2 C<mods>

Returns the list of the L<LaTeX::TikZ::Mod> objects associated with the current set.

=cut

has '_mods' => (
 is       => 'ro',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Mod]]',
 init_arg => 'mods',
 default  => sub { [ ] },
 lazy     => 1,
);

sub mods { @{$_[0]->_mods} }

=head1 METHODS

This method is required by the interface :

=over 4

=item *

C<draw $formatter, $context>

Returns an array reference of TikZ code lines required to effectively draw the current set object, formatted by the L<LaTeX::TikZ::Formatter> object C<$formatter>.
The current evaluation context is passed as the L<LaTeX::TikZ::Context> object C<$context>.

=back

=cut

requires qw<
 draw
>;

=head2 C<mod>

    $set->mod(@mods)

Apply the given list of L<LaTeX::TikZ::Mod> objects to the current set.

=cut

my $ltm_tc  = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod');
my $ltml_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Layer');
my $ltmc_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Clip');

sub mod {
 my $set = shift;

 my @mods = map $ltm_tc->coerce($_), @_;
 $ltm_tc->assert_valid($_) for @mods;

 push @{$set->_mods}, @mods;

 $set;
}

around 'draw' => sub {
 my ($orig, $set, $tikz, $pcxt) = @_;

 my $cxt = LaTeX::TikZ::Context->new(
  parent => $pcxt,
  mods   => [ $set->mods ],
 );

 my $body = $set->$orig($tikz, $cxt);

 my @mods = $cxt->effective_mods;
 if (@mods) {
  $body = LaTeX::TikZ::Scope->new(
   mods => [ map $_->apply($tikz), @mods ],
   body => $body,
  );
 }

 $body;
};

=head2 C<layer>

    $set->layer($layer)

Puts the current set in the corresponding layer.
This is a shortcut for C<< $set->mod(Tikz->layer($layer)) >>.

=cut

sub layer {
 my $set = shift;

 return $set unless @_;

 my $layer = $_[0];
 $set->mod(
  $ltml_tc->check($layer) ? $layer
                          : LaTeX::TikZ::Mod::Layer->new(name => $layer)
 )
}

=head2 C<clip>

    $set->clip($path)

Clips the current set by the path given by C<$path>.
This is a shortcut for C<< $set->mod(Tikz->clip($path)) >>.

=cut

sub clip {
 my $set = shift;

 return $set unless @_;

 $set->mod(
  map {
   $ltmc_tc->check($_) ? $_ : LaTeX::TikZ::Mod::Clip->new(clip => $_)
  } @_
 )
}

=head1 SEE ALSO

L<LaTeX::TikZ>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Set
