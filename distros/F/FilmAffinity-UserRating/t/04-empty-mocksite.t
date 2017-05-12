use strict;
use warnings;

use lib 't/';
use MockSite;

use FilmAffinity::UserRating;

use Test::MockObject::Extends;
use Test::More tests => 1;

my $userParser = FilmAffinity::UserRating->new({
   userID => '000000',
   delay  => 1,
});

my $mock = Test::MockObject::Extends->new( $userParser );

my $urlRoot = MockSite::mockLocalSite('t/resources/filmaffinity-local-site-x');

$mock->mock(
  'p_buildUrl' =>
    sub {my ($self, $page,) = @_;
      return $urlRoot.'/user-rating-page-'.$page.'.html';}
);

my $ref_movies = $mock->parse();
isnt(\%{$ref_movies}, 'empty hash');
