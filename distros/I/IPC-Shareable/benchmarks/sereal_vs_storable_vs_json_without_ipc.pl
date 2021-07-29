#!/usr/bin/env perl
use warnings;
use strict;

use Benchmark qw(:all) ;
use JSON qw(-convert_blessed_universally);
use Sereal qw(encode_sereal decode_sereal looks_like_sereal);
use Storable qw(freeze thaw);

if (@ARGV < 1){
    print "\n Need test count argument...\n\n";
    exit;
}

timethese($ARGV[0],
    {
        sereal  => \&serial,
        store   => \&storable,
        json    => \&json,
    },
);

cmpthese($ARGV[0],
    {
        sereal  => \&serial,
        store   => \&storable,
        json    => \&json,
    },
);

sub _data {
    my %h = (
        a => 1,
        b => 2,
        c => [qw(1 2 3)],
        d => {z => 26, y => 25},
    );

    return \%h;
}
sub json {
    my $data = _data();
    my $json = encode_json $data;
    my $perl = decode_json $json;
}
sub serial {
    my $data = _data();
    my $enc = encode_sereal($data);
    my $dec = decode_sereal($enc);
}
sub storable {
    my $data = _data();
    my $ice = freeze($data);
    my $water = thaw($ice);
}

__END__

Benchmark: timing 5000000 iterations of json, sereal, store...
      json: 17 wallclock secs (17.53 usr +  0.00 sys = 17.53 CPU) @ 285225.33/s (n=5000000)
    sereal: 22 wallclock secs (21.78 usr +  0.00 sys = 21.78 CPU) @ 229568.41/s (n=5000000)
     store: 49 wallclock secs (49.55 usr +  0.01 sys = 49.56 CPU) @ 100887.81/s (n=5000000)
           Rate  store sereal   json
store  102312/s     --   -56%   -64%
sereal 233863/s   129%     --   -18%
json   286862/s   180%    23%     --
