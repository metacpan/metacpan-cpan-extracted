use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }

use IMDB::JSON;
my $i = IMDB::JSON->new;

my $res = $i->byid("tt0343818");
if($res->{name} eq 'I, Robot'){
	$loaded++;
}

