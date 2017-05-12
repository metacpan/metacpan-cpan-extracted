use strict;
use warnings;

use IO::All -utf8;
use lib 't/';

use Test::More tests => 5;

use_ok('FilmAffinity::UserRating');

my $content    = io('t/resources/user-rating-sample.html')->all;
my $userParser = FilmAffinity::UserRating->new( userID => '000000' );
$userParser->parseString($content);

my %movies = %{$userParser->movies()};
is(scalar keys %movies, 30, 'number of title/rating per page');

is($userParser->username, 'JohnSmith', 'username');

$content = io('t/resources/user-rating-without-next.html')->all;
$userParser->parseString($content);

my %films = (
  '201496' => { 'title' => 'Iron Man', 'rating' => 8},
  '516117' => { 'title' => 'The Invasion', 'rating' => 6},
  '551026' => { 'title' => 'The Astronaut\'s Wife', 'rating' => 5},
  '170262' => { 'title' => 'Untraceable', 'rating' => 7},
  '966177' => { 'title' => 'Into the Wild', 'rating' => 9},
);

$content = io('t/resources/user-rating-short.html')->all;
$userParser = FilmAffinity::UserRating->new( userID => '000000' );
$userParser->parseString($content);

%movies = %{$userParser->movies()};

is(scalar keys %movies, 5, 'number of title/rating per page');
is_deeply(\%movies, \%films, 'Same structure');
