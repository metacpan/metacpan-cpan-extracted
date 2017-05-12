package LaTeX::TikZ::Point::Math::Complex;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Point::Math::Complex - Coerce Math::Complex points into LaTeX::TikZ::Point objects.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Math::Complex;

use LaTeX::TikZ::Point;

use Mouse::Util::TypeConstraints qw<class_type coerce from via>;

my $mc_tc = class_type 'Math::Complex';

coerce 'LaTeX::TikZ::Point::Autocoerce'
    => from 'Math::Complex'
    => via { LaTeX::TikZ::Point->new(x => $_->Re, y => $_->Im); };

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

1; # End of LaTeX::TikZ::Point::Math::Complex
