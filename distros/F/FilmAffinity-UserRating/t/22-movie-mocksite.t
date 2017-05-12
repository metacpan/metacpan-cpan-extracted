use strict;
use warnings;

use lib 't/';
use MockSite;

use JSON;
use Encode;
use IO::All;
use File::Basename;
use File::Find::Rule;
use FilmAffinity::Movie;

use Test::JSON;
use Test::MockObject::Extends;
use Test::LongString;
use Test::More tests => 168;

my @listMovies = File::Find::Rule->file()->name('*.html')->in(
  't/resources/filmaffinity-local-movie'
);

foreach my $movie (@listMovies){

  my ($id) = fileparse($movie, '.html');
  my $faMovie = FilmAffinity::Movie->new( id => $id);
  my $mock    = Test::MockObject::Extends->new( $faMovie );
  my $urlRoot = MockSite::mockLocalSite('t/resources/filmaffinity-local-movie');

  $mock->mock(
    'p_buildUrlMovie' =>
      sub {
        my ($self, $id) = @_;
        return $urlRoot.'/'.$id.'.html';
      }
  );

  $mock->parse();

  my $jsonContent < io('t/resources/json-movie/'.$id.'.json');
  my $jsonData = from_json( $jsonContent );

  is($faMovie->title(),         $jsonData->{title},         'title');
  is($faMovie->originaltitle(), $jsonData->{originaltitle}, 'originaltitle');
  is($faMovie->year(),          $jsonData->{year},          'year');
  is($faMovie->duration(),      $jsonData->{duration},      'duration');
  is($faMovie->synopsis(),      $jsonData->{synopsis},      'synopsis');
  is($faMovie->website(),       $jsonData->{website},       'website');

  is($faMovie->country(),  $jsonData->{country},  'country');
  is($faMovie->cover(),    $jsonData->{cover},    'cover');

  is($faMovie->rating(),    $jsonData->{rating},    'rating');
  is($faMovie->votes(),     $jsonData->{votes},    'votes');

  is_deeply($faMovie->cast(),     $jsonData->{cast},     'cast');
  is_deeply($faMovie->director(), $jsonData->{director}, 'director');
  is_deeply($faMovie->composer(), $jsonData->{composer}, 'composer');

  is_deeply($faMovie->screenwriter(),    $jsonData->{screenwriter},    'screenwriter');
  is_deeply($faMovie->cinematographer(), $jsonData->{cinematographer}, 'cinematographer');

  is_deeply($faMovie->genre(), $jsonData->{genre}, 'genre');
  is_deeply($faMovie->topic(), $jsonData->{topic}, 'topic');

  is_deeply($faMovie->studio(),   $jsonData->{studio},   'studio');
  is_deeply($faMovie->producer(), $jsonData->{producer}, 'producer');

  is_valid_json($faMovie->toJSON(), 'is valid json');
  is_json($faMovie->toJSON(), $jsonContent, 'same json');
}
