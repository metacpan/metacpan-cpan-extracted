use strict;
use warnings;

use lib 't/';
use MockSite;

use FilmAffinity::Movie;

use Test::MockObject::Extends;
use Test::More tests => 1;

my $faMovie = FilmAffinity::Movie->new({
  id    => 0,
  delay => 1,
});
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
is($faMovie->title, q{}, 'empty title');
