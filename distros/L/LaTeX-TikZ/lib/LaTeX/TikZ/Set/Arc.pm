package LaTeX::TikZ::Set::Arc;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Arc - A combined set object representing an arc.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Carp          ();
use Math::Complex ();
use Math::Trig    ();

use LaTeX::TikZ::Point;

use LaTeX::TikZ::Set::Circle;
use LaTeX::TikZ::Set::Polyline;

use LaTeX::TikZ::Interface;

use LaTeX::TikZ::Tools;

use Mouse::Util::TypeConstraints 'find_type_constraint';

my $ltp_tc = find_type_constraint('LaTeX::TikZ::Point::Autocoerce');

LaTeX::TikZ::Interface->register(
 arc => sub {
  shift;
  Carp::confess('Tikz->arc($first_point, $second_point, $center)') if @_ < 3;
  my ($a, $b, $c) = @_;

  for ($a, $b, $c) {
   my $p = $ltp_tc->coerce($_);
   $ltp_tc->assert_valid($p);
   $_ = Math::Complex->make($p->x, $p->y);
  }

  my $r = abs($a - $c);
  Carp::confess("The two first points aren't on a circle of center the last")
                             unless LaTeX::TikZ::Tools::numeq(abs($b - $c), $r);

  my $set = LaTeX::TikZ::Set::Circle->new(
   center => $c,
   radius => $r,
  );

  my $factor = 1/32;

  my $theta  = (($b - $c) / ($a - $c))->arg;
  my $points = int(abs($theta) / abs(Math::Trig::acos(0.95)));
  $theta    /= $points + 1;
  my $rho    = (1 / cos($theta)) / (1 - $factor);

  my $ua = ($a - $c) * (1 - $factor) + $c;
  my $ub = ($b - $c) * (1 - $factor) + $c;

  my @outside = map { $_ * $rho + $c } (
   $a - $c,
   (map { ($a - $c) * Math::Complex->emake(1, $_ * $theta) } 1 .. $points),
   $b - $c,
  );

  $set->clip(
   LaTeX::TikZ::Set::Polyline->new(
    points => [ $ua, @outside, $ub ],
    closed => 1,
   ),
  );
 },
);

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set>.

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

1; # End of LaTeX::TikZ::Set::Arc
