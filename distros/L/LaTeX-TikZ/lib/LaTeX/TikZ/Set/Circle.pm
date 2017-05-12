package LaTeX::TikZ::Set::Circle;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Circle - A set object representing a circle.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Set::Point;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use LaTeX::TikZ::Tools;

use Mouse;
use Mouse::Util::TypeConstraints;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Path> role, and as such implements the L</path> method.

=cut

with 'LaTeX::TikZ::Set::Path';

=head1 ATTRIBUTES

=head2 C<center>

A L<LaTeX::TikZ::Set::Point> object describing the center of the circle.

=cut

has 'center' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Set::Point',
 required => 1,
 coerce   => 1,
);

=head2 C<radius>

The radius of the circle as a non-negative real number.

=cut

has 'radius' => (
 is       => 'ro',
 isa      => subtype('Num' => where { LaTeX::TikZ::Tools::numcmp($_, 0) > 0 }),
 required => 1,
);

=head1 METHODS

=head2 C<path>

=cut

sub path {
 my $set  = shift;
 my $tikz = $_[0];

 $set->center->path(@_) . ' circle (' . $tikz->len($set->radius) . ')';
}

=head2 C<begin>

=cut

sub begin { $_[0]->center->begin }

=head2 C<end>

=cut

sub end { $_[0]->center->end }

LaTeX::TikZ::Interface->register(
 circle => sub {
  shift;

  __PACKAGE__->new(center => $_[0], radius => $_[1]);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(
   center => $set->center->$functor(@args),
   radius => $set->radius,
  );
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set>, L<LaTeX::TikZ::Set::Path>.

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

1; # End of LaTeX::TikZ::Set::Circle
