#!/usr/bin/env perl
use warnings;
use strict;

use Benchmark qw(:all) ;
use Sereal qw(encode_sereal decode_sereal looks_like_sereal);
use Storable qw(freeze thaw);

if (@ARGV < 1){
    print "\n Need test count argument...\n\n";
    exit;
}

timethese($ARGV[0],
    {
        'sereal' => \&serial,
        'store ' => \&storable,
    },
);

cmpthese($ARGV[0],
    {
        'sereal' => \&serial,
        'store ' => \&storable,
    },
);

sub serial {
    my %h = (
        a => 1,
        b => 2,
        c => [qw(1 2 3)],
        d => {z => 26, y => 25},
    );

    my $enc = encode_sereal(\%h);
    my $dec = decode_sereal($enc);
}
sub storable {
    my %h = (
        a => 1,
        b => 2,
        c => [qw(1 2 3)],
        d => {z => 26, y => 25},
    );

    my $ice = freeze(\%h);
    my $water = thaw($ice);
}

__END__

Benchmark: timing 3000000 iterations of sereal, store ...
    sereal: 12 wallclock secs (13.11 usr +  0.00 sys = 13.11 CPU) @ 228832.95/s (n=3000000)
    store : 32 wallclock secs (31.02 usr +  0.00 sys = 31.02 CPU) @ 96711.80/s (n=3000000)
           Rate store  sereal
store  105374/s     --   -55%
sereal 231660/s   120%     --

