package FilmAffinity::UserRating;

use 5.006;
use strict;
use warnings;

use Encode;
use Readonly;
use Text::Trim;
use LWP::RobotUA;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;

use Moose;
use MooseX::Privacy;

use FilmAffinity::Utils qw/buildRobot demoronize/;

=head1 NAME

FilmAffinity::UserRating - Perl interface to FilmAffinity

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Get filmaffinity voted movies from a user

    use FilmAffinity::UserRating;

    my $parser = FilmAffinity::UserRating->new( userID => '123456' );

    my $ref_movies = $parser->parse();

Via the command-line program filmaffinity-get-ratings.pl

=head1 DESCRIPTION

=head2 Overview

FilmAffinity::UserRating is a Perl interface to FilmAffinity. You can use
this module to retrieve your rated movies.

=head2 Constructor

=over 4

=item new()

Object's constructor. You should pass as parameter the userID

    my $parser = FilmAffinity::UserRating->new( userID => '123456' );

=back

=head2 Options

=over 4

=item delay

Set the minimum delay between requests to the server, in seconds.

    my $parser = FilmAffinity::UserRating->new(
      userID => '123456',
      delay  => 20,
    );

By default, the delay is 5 seconds

=back

=head1 ACCESSORS

=head2 $parser->userID

get userID

=cut

has userID => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

=head2 $parser->username

get username

=cut

has username => (
  is     => 'ro',
  isa    => 'Str',
  writer => 'p_username',
);

=head2 $parser->movies

get movies

=cut

has movies => (
  is      => 'rw',
  isa     => 'HashRef[Str]',
  default => sub { {} },
);

has ua => (
  is      => 'rw',
  isa     => 'LWP::RobotUA',
  traits  => [qw/Private/],
);

Readonly my $SECONDS => 5;
my $RATING_URL   = 'http://www.filmaffinity.com/en/userratings.php?orderby=2&';
my $XPATH_ID     = '//div[@class="user-ratings-movie-item"]/div/@data-movie-id';
my $XPATH_TITLE  = '//div[@class="mc-title"]/a';
my $XPATH_RATING = '//div[@class="ur-mr-rat"]';

sub BUILD {
  my ($self, $args) = @_;

  $self->ua( buildRobot( $args->{delay} || $SECONDS ) );

  return;
}

=head1 SUBROUTINES/METHODS

=head2 $parser->parse()

This function parses all rating pages of filmaffinity from a user.

    my $ref_movies = $parser->parse();

=cut

sub parse {
  my $self = shift;

  my ($next, $page) = (1, 1);
  while ( $next ){
    my $url = $self->p_buildUrl( $page );
    my $response = $self->ua->get($url);
    if ($response->is_success){
      my $content = $response->decoded_content();
      $self->parseString($content);
      $next = $self->p_isNextPage($content);
      $page++;
    } else {
      $next = 0;
    }
  }
  return $self->movies;
}

=head2 $parser->parseString($content)

This function parses a page of filmaffinity that is available as
a single string in memory.

    $parser->parseString($content);

=cut

sub parseString {
  my ($self, $content) = @_;

  $content = demoronize($content);
  $content = decode('iso8859-1', $content);

  my $tree = HTML::TreeBuilder->new();
  $tree->parse($content);
  $self->p_username($tree->findvalue( '//span[@id="nick"]' ));

  my @ids       = $tree->findnodes_as_strings( $XPATH_ID );
  my @titles    = $tree->findnodes_as_strings( $XPATH_TITLE );
  my @ratings   = $tree->findnodes_as_strings( $XPATH_RATING );

  $self->p_buildMovieInfo(\@ids, \@titles, \@ratings);

  $tree->delete();
  return;
}

private_method p_buildUrl => sub {
  my ($self, $page) = @_;

  return $RATING_URL.'p='.$page.'&user_id='.$self->userID;
};

private_method p_buildMovieInfo => sub {
  my ($self, $ref_ids, $ref_titles, $ref_ratings) = @_;

  for my $i (0..(@{$ref_titles}-1)){
    $self->movies->{${$ref_ids}[$i]} = {
      'title'  => demoronize(${$ref_titles}[$i]),
      'rating' => ${$ref_ratings}[$i],
    }
  }
};

private_method p_isNextPage => sub {
  my ($self, $content) = @_;

  if ($content =~ m/>&gt;&gt;<\/a><\/div><\/div>/xms){
    return 1;
  }
  return 0;
};

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-filmaffinity-userrating at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FilmAffinity-UserRating>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FilmAffinity::UserRating


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

1; # End of FilmAffinity::UserRating
