use 5.006;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny ':all';
use Map::Tube::CLI;
use Test::More;

my $min_tcm = 0.82;
eval "use Map::Tube::London $min_tcm";
plan skip_all => "Map::Tube::London $min_tcm required" if $@;

is(capture_stdout { Map::Tube::CLI->new({ map => 'London', start => 'Baker Street', end => 'Euston Square' })->run },
   "Baker Street (Bakerloo, Circle, Hammersmith & City, Jubilee, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)\n");

eval { Map::Tube::CLI->new };
like($@, qr/Missing required arguments: map/);

eval { Map::Tube::CLI->new({ map => 'X' }) };
like($@, qr/ERROR: Unsupported Map/);

eval { Map::Tube::CLI->new({ map => 'London', start => 'Y', end => 'Z' }) };
like($@, qr/Invalid Station Name/);

eval { Map::Tube::CLI->new({ map => 'London', start => 'Baker Street', end => 'Z' }) };
like($@, qr/Invalid Station Name/i);

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1 }) };
like($@, qr/ERROR: Missing Station Name/i);

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, start => 'Y' }) };
like($@, qr/ERROR: Missing Station Name/);

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, start => 'Y', end => 'Z' }) };
like($@, qr/Invalid Station Name/);

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, start => 'Baker Street', end => 'Z' }) };
like($@, qr/Invalid Station Name/);

eval { Map::Tube::CLI->new({ map => 'London', generate_map => 1, line => 'X' }) };
like($@, qr/Invalid Line Name/);

done_testing();
