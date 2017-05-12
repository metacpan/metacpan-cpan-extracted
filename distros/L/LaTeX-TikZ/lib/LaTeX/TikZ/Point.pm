package LaTeX::TikZ::Point;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Point - Internal representation of what LaTeX::TikZ consider as 2D points.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Mouse;
use Mouse::Util::TypeConstraints qw<
 coerce from via
 find_type_constraint
 register_type_constraint
>;

=head1 ATTRIBUTES

=head2 C<x>

The abscissa of the point.

=cut

has 'x' => (
 is       => 'ro',
 isa      => 'Num',
 required => 1,
);

=head2 C<y>

The ordinate of the point.

=cut

has 'y' => (
 is       => 'ro',
 isa      => 'Num',
 required => 1,
);

use LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;

register_type_constraint(
 LaTeX::TikZ::Meta::TypeConstraint::Autocoerce->new(
  name   => 'LaTeX::TikZ::Point::Autocoerce',
  target => find_type_constraint(__PACKAGE__),
 ),
);

coerce 'LaTeX::TikZ::Point::Autocoerce'
    => from 'LaTeX::TikZ::Point'
    => via { $_ };

coerce 'LaTeX::TikZ::Point::Autocoerce'
    => from 'Num'
    => via { LaTeX::TikZ::Point->new(x => $_, y => 0) };

coerce 'LaTeX::TikZ::Point::Autocoerce'
    => from 'ArrayRef'
    => via { LaTeX::TikZ::Point->new(x => $_->[0], y => $_->[1]) };

__PACKAGE__->meta->make_immutable;

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

1; # End of LaTeX::TikZ::Point
