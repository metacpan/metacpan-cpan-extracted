package FilmAffinity::Movie;

use strict;
use warnings;

use JSON;
use Encode;
use Readonly;
use Scalar::Util qw(looks_like_number);
use Text::Trim;
use LWP::RobotUA;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;

use Moose;
use MooseX::Privacy;

use FilmAffinity::Utils qw/buildRobot/;

=head1 NAME

FilmAffinity::Movie - Perl interface to FilmAffinity

=head1 VERSION

Version 0.10

=cut

our $VERSION = 0.10;

=head1 SYNOPSIS

Retrieve information about a filmaffinity movie

    use FilmAffinity::Movie;

    my $movie = FilmAffinity::Movie->new(
      id    => $movieID,
      delay => $delay || 5,
    );

    $movie->parse();

Via the command-line program filmaffinity-get-movie-info.pl

=head1 DESCRIPTION

=head2 Overview

FilmAffinity::Movie is a Perl interface to FilmAffinity. You can use
this module to retrieve information about a movie.

=head2 Constructor

=over 4

=item new()

Object's constructor. You should pass as parameter the movieID

    my $movie = FilmAffinity::Movie->new( id => '932476' );

=back

=head2 Options

=over 4

=item delay

Set the minimum delay between requests to the server, in seconds.

    my $parser = FilmAffinity::Movie->new(
      userID => '932476',
      delay  => 20,
    );

By default, the delay is 5 seconds

=back

=head1 ACCESSORS

=head2 $movie->id

get id

=head2 $movie->title

get title

=head2 $movie->originaltitle

get original title

=head2 $movie->year

get year

=head2 $movie->duration

get running time (in minutes)

=head2 $movie->synopsis

get synopsis

=head2 $movie->website

get url of the movie website

=head2 $movie->country

get country

=head2 $movie->cover

get url of the cover

=head2 $movie->rating

get site rating

=head2 $movie->myrating

get personal rating

=head2 $movie->votes

get number of votes

=head2 $movie->genre

get genres list

=head2 $movie->topic

get topics list

=head2 $movie->cast

get cast list

=head2 $movie->director

get directors list

=head2 $movie->composer

get composers list

=head2 $movie->screenwriter

get screenwriters list

=head2 $movie->cinematographer

get cinematographers list

=head2 $movie->studio

get studios list

=head2 $movie->producer

get producers list

=cut

has id       => ( is => 'ro', isa => 'Int', required => 1, );
has title    => ( is => 'rw', isa => 'Str', );
has originaltitle    => ( is => 'rw', isa => 'Str', );
has year     => ( is => 'rw', isa => 'Int', );
has duration => ( is => 'rw', isa => 'Int', );
has synopsis => ( is => 'rw', isa => 'Str', );
has website  => ( is => 'rw', isa => 'Str', );
has country  => ( is => 'rw', isa => 'Str', );
has cover    => ( is => 'rw', isa => 'Str', );
has rating   => ( is => 'rw', isa => 'Num', );
has votes    => ( is => 'rw', isa => 'Num', );
has myrating => ( is => 'rw', isa => 'Num', );

has genre => ( is => 'rw', isa => 'ArrayRef[Str]', );
has topic => ( is => 'rw', isa => 'ArrayRef[Str]', );

has cast     => ( is => 'rw', isa => 'ArrayRef[Str]', );
has director => ( is => 'rw', isa => 'ArrayRef[Str]', );
has composer => ( is => 'rw', isa => 'ArrayRef[Str]', );

has screenwriter    => ( is => 'rw', isa => 'ArrayRef[Str]', );
has cinematographer => ( is => 'rw', isa => 'ArrayRef[Str]', );

has studio   => ( is => 'rw', isa => 'ArrayRef[Str]', );
has producer => ( is => 'rw',  );


has tree => (
  is      => 'rw',
  isa     => 'HTML::TreeBuilder',
  traits  => [qw/Private/],
);

has ua => (
  is      => 'rw',
  isa     => 'LWP::RobotUA',
  traits  => [qw/Private/],
);

my $MOVIE_URL     = 'http://www.filmaffinity.com/en/film';
my $XPATH_TITLE   = '//h1[@id="main-title"]';
my $XPATH_RATING  = '//div[@id="movie-rat-avg"]';
my $XPATH_VOTE    = '//div[@id="movie-count-rat"]/span';
my $XPATH_COUNTRY = '//span[@id="country-img"]/img/@title';
my $XPATH_COVER   = '//div[@id="movie-main-image-container"]/a/img/@src';

my @JSON_FIELD = qw(
  id title year synopsis website duration cast director composer screenwriter
  cinematographer genre topic studio producer country cover rating votes
  originaltitle myrating
);

my $FIELD = [
  {
    accessor => 'originaltitle',
    faTag    => 'Original title',
  },
  {
    accessor => 'year',
    faTag    => 'Year',
  },
  {
    accessor => 'synopsis',
    faTag    => 'Synopsis / Plot',
  },
  {
    accessor => 'website',
    faTag    => 'Official Site',
  },
  {
    accessor   => 'duration',
    faTag      => 'Running Time',
    cleanerSub => \&p_cleanDuration,
  },
  {
    accessor   => 'cast',
    faTag      => 'Cast',
    cleanerSub => \&p_cleanPerson,
  },
  {
    accessor   => 'director',
    faTag      => 'Director',
    cleanerSub => \&p_cleanPerson,
  },
  {
    accessor   => 'composer',
    faTag      => 'Music',
    cleanerSub => \&p_cleanPerson,
  },
  {
    accessor   => 'screenwriter',
    faTag      => 'Screenwriter',
    cleanerSub => \&p_cleanPerson,
  },
  {
    accessor   => 'cinematographer',
    faTag      => 'Cinematography',
    cleanerSub => \&p_cleanPerson,
  },
  {
    accessor   => 'genre',
    faTag      => 'Genre',
    cleanerSub => \&p_cleanGenre,
  },
  {
    accessor   => 'topic',
    faTag      => 'Genre',
    cleanerSub => \&p_cleanGenre,
  },
  {
    accessor   => 'studio',
    faTag      => 'Production Co.',
    cleanerSub => \&p_cleanStudio,
  },
  {
    accessor   => 'producer' ,
    faTag      => 'Production Co.',
    cleanerSub => \&p_cleanStudio,
  },
];

Readonly my $SECONDS => 5;

sub BUILD {
  my ($self, $args) = @_;

  $self->tree( HTML::TreeBuilder->new() );
  $self->ua( buildRobot( $args->{delay} || $SECONDS ) );
  return;
}

=head1 SUBROUTINES/METHODS

=head2 $movie->parse()

This method will get the content of the filmaffinity webpage and retrieve
all information about the movie

=cut

sub parse {
  my $self = shift;

  my $content = $self->getContent();
  $self->parsePage($content);
  return;
}


=head2 $movie->getContent()

This method will get the content of the filmaffinity webpage

=cut

sub getContent {
  my ($self) = @_;

  my $url = $self->p_buildUrlMovie($self->id);

  my $response = $self->ua->get($url);
  if ($response->is_success){
    return $response->content();
  }
}

=head2 $movie->parsePage($content)

This method parses a page of filmaffinity that is available as
a single string in memory.

=cut

sub parsePage {
  my ($self, $content) = @_;

  $content = decode('utf-8', $content);
  $self->tree->parse($content);

  foreach my $data (@{$FIELD}){
    $self->p_findField($data);
  }

  $self->p_findRating();
  $self->p_findVotes();
  $self->country( $self->tree->findvalue( $XPATH_COUNTRY ) );
  $self->cover( $self->tree->findvalue( $XPATH_COVER ) );
  $self->title( trim($self->tree->findvalue( $XPATH_TITLE )) );

  $self->tree->delete();
  return;
}



=head2 $movie->toJSON()

This method will export all movie informations in JSON format

=cut

sub toJSON {
  my $self = shift;

  my %data;
  foreach my $field (@JSON_FIELD){
    $data{$field} = $self->$field() if defined $self->$field();
  };

  return to_json(\%data, {pretty => 1});
}

private_method p_findField => sub {
  my ( $self, $data ) = @_;

  my @nodes = $self->tree->findnodes( '//dl[@class="movie-info"]/dt' );
  foreach my $node (@nodes){
    if ( trim( $node->as_text() ) eq $data->{faTag} ){

      my $searched_node = $node->right();

      my $accessor = $data->{accessor};

      my $value = trim( $searched_node->as_text() );

      next if $value eq q{};

      if (defined $data->{cleanerSub}){
        $value = $data->{cleanerSub}($value, $accessor);
      }

      next if not defined $value;

      $self->$accessor( $value );
      last;
    }
  }
};

private_method p_findRating => sub {
  my $self = shift;

  my $rating = $self->tree->findvalue( $XPATH_RATING );

  return if not defined $rating or $rating eq q{};
  $self->rating( trim($rating) );
};

private_method p_findVotes => sub {
  my $self = shift;

  my $votes = $self->tree->findvalue( $XPATH_VOTE );

  return if not defined $votes or $votes eq q{};
  $votes =~ s/\D//gixms;
  $self->votes( trim($votes) );
};

private_method p_buildUrlMovie => sub {
  my ($self, $id) = @_;

  return $MOVIE_URL.$id.'.html';
};

private_method p_removeTextBetweenParenthesis => sub {
  my $content = shift;

  $content =~ s/[(].*[)]//gxms;
  return $content;
};

private_method p_cleanDuration => sub {
  my $value = shift;
  $value =~ s/min[.]//gixms;
  $value = trim($value);

  if ( looks_like_number($value) ){
    return $value;
  }
  return;
};

private_method p_cleanPerson => sub {
  my $value = shift;

  my @persons = split m/,/xms, $value;
  @persons = map {trim (p_removeTextBetweenParenthesis($_) )} @persons;
  return \@persons;
};

private_method p_cleanGenre => sub {
  my ($value, $field) = @_;

  my $pos = $field eq 'genre' ? 0 : 1;
  my @list = split m/[|]/xms, $value;

  if ( defined $list[$pos]){
    my @genres = trim ( split m/[.]/xms, $list[$pos] );
    return \@genres;
  }
  return;
};

private_method p_cleanStudio => sub {
  my ($value, $field) = @_;

  my $pos = $field eq 'studio' ? 0 : 1;
  my @list = split m/[.]\sProducer: /xms, $value;

  my @studio = ();
  if (not defined $list[$pos]){
    return;
  } else {
    @studio = trim ( split m{ / }xms, $list[$pos] );
    return \@studio;
  }
};

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-filmaffinity-userrating at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FilmAffinity-UserRating>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FilmAffinity::Movie

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

1; # End of FilmAffinity::Movie
