#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny ':all';
use Map::Tube::CLI;
use Test::More;

my $min_tcm = 1.39;
eval "use Map::Tube::London $min_tcm";
plan skip_all => "Map::Tube::London $min_tcm required" if $@;

is(capture_stdout { Map::Tube::CLI->new({ map => 'London', start => 'Baker Street', end => 'Euston Square' })->run },
   "Baker Street (Bakerloo, Circle, Hammersmith and City, Jubilee, Metropolitan), Great Portland Street (Circle, Hammersmith and City, Metropolitan), Euston Square (Circle, Hammersmith and City, Metropolitan, Street)\n",
   "Route check"
  );

is(capture_stdout { Map::Tube::CLI->new({ map => 'London', list_lines => 1 })->run },
"Bakerloo,
Central,
Circle,
DLR,
District,
Elizabeth,
Hammersmith and City,
Jubilee,
Liberty,
Lioness,
Metropolitan,
Mildmay,
Northern,
Piccadilly,
Street,
Suffragette,
Tunnel,
Victoria,
Waterloo and City,
Weaver,
Windrush
",
   "List of lines"
  );

eval { Map::Tube::CLI->new };
like($@, qr/Missing required arguments: map/, 'Missing map argument');

eval { Map::Tube::CLI->new({ map => 'X' }) };
like($@, qr/ERROR: Unsupported Map/, 'Non-existent map');

eval { Map::Tube::CLI->new({ map => 'London', start => 'Y', end => 'Baker Streeet' }) };
like($@, qr/Invalid Station Name/, 'Non-existent start station');

eval { Map::Tube::CLI->new({ map => 'London', start => 'Baker Street', end => 'Z' }) };
like($@, qr/Invalid Station Name/i, 'Non-existent end station');

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, end => 'Baker Street' }) };
like($@, qr/ERROR: Missing Station Name/i, 'Missing start station name');

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, start => 'Baker Street' }) };
like($@, qr/ERROR: Missing Station Name/, 'Missing end station name');

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, start => 'Y', end => 'Baker Street' }) };
like($@, qr/Invalid Station Name/, 'Non-existent start station name');

eval { Map::Tube::CLI->new({ map => 'London', preferred => 1, start => 'Baker Street', end => 'Z' }) };
like($@, qr/Invalid Station Name/, 'Non-existent end station name');

eval { Map::Tube::CLI->new({ map => 'London', generate_map => 1, line => 'X' }) };
like($@, qr/Invalid Line Name/, 'Non-existent line name');

done_testing;
