#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Readonly;
use IO::All -utf8;
use FilmAffinity::Utils qw/data2tsv/;
use FilmAffinity::UserRating;

=head1 NAME

filmaffinity-get-ratings.pl

=head1 DESCRIPTION

Get ratings from filmaffinity for a user and print them in Tab-separated values

=head1 VERSION

Version 1.01

=head1 USAGE

  filmaffinity-get-rating.pl --userid=123456

  filmaffinity-get-rating.pl --userid=123456 --delay=2

  filmaffinity-get-rating.pl --userid=123456 --output=/home/william/myvote.list

=head1 REQUIRED ARGUMENTS

=over 2

=item --userid=192076

userid from filmaffinity

=back

=head1 OPTIONS

=over 2

=item --delay=3

delay between requests

=item --output=/home/william/rating.list

output file

=back

=cut

our $VERSION = '1.01';

Readonly my $DELAY => 5;

my ( $userID, $delay, $output, $help );

GetOptions(
  'userid=i' => \$userID,
  'delay=i'  => \$delay,
  'output=s' => \$output,
  'help'     => \$help,
) || pod2usage(2);

if ( $help || !$userID ) {
  pod2usage(1);
  exit 0;
}

my $userParser = FilmAffinity::UserRating->new(
  userID => $userID,
  delay  => $delay || $DELAY,
);

my $ref_movies = $userParser->parse();

my $tsv = data2tsv($ref_movies);

$output ? $tsv > io($output) : print $tsv;

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-filmaffinity-userrating at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FilmAffinity-UserRating>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc filmaffinity-get-ratings.pl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FilmAffinity-UserRating>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FilmAffinity-UserRating>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FilmAffinity-UserRating>

=item * Search CPAN

L<http://search.cpan.org/dist/FilmAffinity-UserRating/>

=back

=head1 SEE ALSO

L<http://www.filmaffinity.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 William Belle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
