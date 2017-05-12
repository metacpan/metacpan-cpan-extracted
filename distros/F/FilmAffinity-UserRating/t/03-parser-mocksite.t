use strict;
use warnings;

use lib 't/';
use MockSite;

use FilmAffinity::UserRating;

use Test::MockObject::Extends;
use Test::More tests => 4;

my $userParser = FilmAffinity::UserRating->new( userID => '000000' );

my $mock = Test::MockObject::Extends->new( $userParser );

my $urlRoot = MockSite::mockLocalSite('t/resources/filmaffinity-local-site');

$mock->mock(
  'p_buildUrl' =>
    sub {my ($self, $page,) = @_;
      return $urlRoot.'/user-rating-page-'.$page.'.html';}
);

my $ref_movies = $mock->parse();

is(scalar keys %{$ref_movies}, 61, 'number of movie rated');

my $title  = $ref_movies->{267002}->{title};
my $rating = $ref_movies->{267002}->{rating};

is($title, 'Watchmen', 'same title');
is($rating, 9, 'same rating');

is($ref_movies->{575554}->{title}, '[*REC]', 'check demoronization');
