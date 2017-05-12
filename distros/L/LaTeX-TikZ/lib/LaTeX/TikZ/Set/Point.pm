package LaTeX::TikZ::Set::Point;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Point - A set object representing a point.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Point;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use Mouse;
use Mouse::Util::TypeConstraints;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Path> role, and as such implements the L</path> method.

=cut

with 'LaTeX::TikZ::Set::Path';

=head1 ATTRIBUTES

=head2 C<point>

The L<LaTeX::TikZ::Point> object representing the underlying geometrical point.

=cut

has 'point' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Point::Autocoerce',
 required => 1,
 coerce   => 1,
 handles  => [ qw<x y> ],
);

=head2 C<label>

An optional label for the point.

=cut

has 'label' => (
 is      => 'rw',
 isa     => 'Maybe[Str]',
 default => undef,
);

=head2 C<pos>

The position of the label around the point.

=cut

enum 'LaTeX::TikZ::Set::Point::Positions' => (
 'below left',
 'below',
 'below right',
 'right',
 'above right',
 'above',
 'above left',
 'left',
);

has 'pos' => (
 is  => 'rw',
 isa => 'Maybe[LaTeX::TikZ::Set::Point::Positions]',
);

coerce 'LaTeX::TikZ::Set::Point'
    => from 'Any'
    => via { __PACKAGE__->new(point => $_) };

coerce 'LaTeX::TikZ::Point::Autocoerce'
    => from 'LaTeX::TikZ::Set::Point'
    => via { $_->point };

=head1 METHODS

=head2 C<path>

=cut

sub path {
 my ($set, $tikz) = @_;

 my $p = $set->point;

 my $path = '(' . $tikz->len($p->x) . ',' . $tikz->len($p->y) . ')';

 my $label = $set->label;
 if (defined $label) {
  my $pos = $set->pos;
  $pos = 'above' unless defined $pos;

  my $size = sprintf '%0.1fpt', 2 * $tikz->scale / 5;
  $path .= " [fill] circle ($size) " . $tikz->label($label, $pos);
 }

 $path;
}

=head2 C<begin>

=cut

sub begin { $_[0]->point }

=head2 C<end>

=cut

sub end { $_[0]->point }

LaTeX::TikZ::Interface->register(
 point => sub {
  shift;

  my $point;
  if (@_ == 0) {
   $point = 0;
  } elsif (@_ % 2) {
   $point = shift;
  } else { # @_ even, @_ >= 2
   $point = [ shift, shift ];
  }

  __PACKAGE__->new(point => $point, @_);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(
   point => $set->point,
   label => $set->label,
   pos   => $set->pos,
  );
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set::Path>.

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

1; # End of LaTeX::TikZ::Set::Point
