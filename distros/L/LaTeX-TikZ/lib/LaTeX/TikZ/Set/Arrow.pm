package LaTeX::TikZ::Set::Arrow;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Arrow - A combined set object representing an arrow.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Carp ();

use LaTeX::TikZ::Point;

use LaTeX::TikZ::Set::Line;

use LaTeX::TikZ::Interface;

use Mouse::Util::TypeConstraints 'find_type_constraint';

my $ltp_tc = find_type_constraint('LaTeX::TikZ::Point::Autocoerce');

LaTeX::TikZ::Interface->register(
 arrow => sub {
  shift;

  Carp::confess('Not enough arguments') unless @_ >= 2;

  my $from = $ltp_tc->coerce(shift);

  my $to;
  if ($_[0] eq 'dir') {
   my $dir = $ltp_tc->coerce($_[1]);
   $to = LaTeX::TikZ::Point->new(
    x => $from->x + $dir->x,
    y => $from->y + $dir->y,
   );
  } else {
   $to = $_[0];
  }

  LaTeX::TikZ::Set::Line->new(
   from => $from,
   to   => $to,
  )->mod('->');
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

1; # End of LaTeX::TikZ::Set::Arrow
