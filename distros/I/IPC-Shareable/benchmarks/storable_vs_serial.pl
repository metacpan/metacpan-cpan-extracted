#!/usr/bin/env perl
use warnings;
use strict;

use Benchmark qw(:all) ;
use IPC::Shareable;
use Sereal qw(encode_sereal decode_sereal looks_like_sereal);
use Storable qw(freeze thaw);

if (@ARGV < 1){
    print "\n Need test count argument...\n\n";
    exit;
}

timethese($ARGV[0],
    {
        'sereal' => \&sereal,
        'store ' => \&storable,
    },
);

cmpthese($ARGV[0],
    {
        'sereal' => \&sereal,
        'store ' => \&storable,
    },
);

sub default {
     return {
        a => 1,
        b => 2,
        c => [qw(1 2 3)],
        d => {z => 26, y => 25},
    };
}
sub sereal {
    my $base_data = default();

    tie my %hash, 'IPC::Shareable', 'sere', {
        create  => 1,
        destroy => 1,
        serializer => 'sereal'
    };

    %hash = %$base_data;

    $hash{struct} = {a => [qw(b c d)]};

    tied(%hash)->clean_up_all;

}
sub storable {
    my $base_data = default();

    tie my %hash, 'IPC::Shareable', 'stor', {
        create  => 1,
        destroy => 1,
        serializer => 'storable'
    };

    %hash = %$base_data;

    $hash{struct} = {a => [qw(b c d)]};

    tied(%hash)->clean_up_all;
}

__END__

Benchmark: timing 10000 iterations of sereal, store ...
    sereal: 18 wallclock secs ( 9.58 usr +  8.60 sys = 18.18 CPU) @ 550.06/s (n=10000)
    store : 18 wallclock secs (10.88 usr +  7.13 sys = 18.01 CPU) @ 555.25/s (n=10000)
        Rate store  sereal
store  545/s     --    -0%
sereal 547/s     0%     --


