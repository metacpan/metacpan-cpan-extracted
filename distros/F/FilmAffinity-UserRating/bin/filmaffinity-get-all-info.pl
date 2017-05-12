#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Carp;
use English qw/-no_match_vars/;
use Readonly;
use IO::All -utf8;
use List::Compare;
use IO::Interactive qw/is_interactive/;
use FilmAffinity::Movie;
use FilmAffinity::Utils qw/data2tsv/;
use FilmAffinity::UserRating;

=head1 NAME

filmaffinity-get-all-info.pl

=head1 DESCRIPTION

Get information from filmaffinity about a film and all ratings from a user

=head1 VERSION

Version 0.10

=head1 USAGE

  ./filmaffinity-get-all-info.pl --userid=123456 --destination=path/to/my/folder

  ./filmaffinity-get-all-info.pl --userid=123456 --destination=path/to/my/folder --delay=2

  ./filmaffinity-get-all-info.pl --userid=123456 --destination=path/to/my/folder --force

=head1 REQUIRED ARGUMENTS

=over 2

=item --userid=123456

userid from filmaffinity

=item --destination=/home/william/filmaffinity

destination folder

=back

=head1 OPTIONS

=over 2

=item --delay=3

delay between requests

=item --force

force to retrieve all movies

=back

=cut

our $VERSION = '0.10';

my ( $userID, $delay, $destination, $force, $help );

GetOptions(
  'userid=i'      => \$userID,
  'delay=i'       => \$delay,
  'destination=s' => \$destination,
  'force'         => \$force,
  'help'          => \$help,
) || pod2usage(2);

if ( $help || !$userID || !$destination ) {
  pod2usage(1);
  exit 0;
}

setFileSystem();

my $userParser = FilmAffinity::UserRating->new(
  userID => $userID,
  delay  => $delay || $DELAY,
);
my $ref_movies = $userParser->parse();
my $tsv        = data2tsv($ref_movies);
$tsv > io( $destination . '/ratings.list' );

my @listOfRemoteMovieId = keys %{$ref_movies};
my @listOfLocalMovieId  = getListOfLocalMovieId();

my $listCompare =
  List::Compare->new( \@listOfLocalMovieId, \@listOfRemoteMovieId, );

my @listOfMovieToRetrieve =
  $force ? @listOfRemoteMovieId : $listCompare->get_Ronly();

my $progress;
if ( is_interactive() ) {
  my $value = eval {
    require Term::ProgressBar;
    $progress = Term::ProgressBar->new(
      {
        name   => 'jsonize movie information',
        count  => scalar @listOfMovieToRetrieve,
        remove => 1
      }
    );
  };
  if ($EVAL_ERROR) {
    carp
'Could not create progress bar. We can continue, but no progress will be reported';
  }
}

my $count = 0;
foreach my $id (@listOfMovieToRetrieve) {

  my $movie = FilmAffinity::Movie->new(
    id    => $id,
    delay => $delay || $DELAY,
  );
  $movie->parse();
  $movie->myrating( $ref_movies->{$id}->{rating} );

  my $json = $movie->toJSON();
  $json > io( $destination . '/json/' . $id . '.json' );

  $count++;
  $progress->update($count) if $progress;
}

sub setFileSystem {
  mkdir $destination;
  mkdir $destination . '/json';
  return;
}

sub getListOfLocalMovieId {
  my @listOfLocalMovie = ();
  my @content          = io( $destination . '/json' )->all();
  foreach my $file (@content) {
    my $filename = $file->filename;
    $filename =~ s/[.]json//xms;
    push @listOfLocalMovie, $filename;
  }
  return @listOfLocalMovie;
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-filmaffinity-userrating at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FilmAffinity-UserRating>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc filmaffinity-get-all-info.pl

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
