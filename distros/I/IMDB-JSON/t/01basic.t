use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }

use IMDB::JSON;
my $i = IMDB::JSON->new;

my $res = $i->search("The Thing", 1982);

if($res->{actor}->[0]->{name} eq 'Kurt Russell'){
	$loaded++;
}
