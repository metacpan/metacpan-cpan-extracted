use Test::More tests => 16;
use strict;
use warnings;
use v5.24;

# Tests for LRC -- Longitudinal Redundancy Checking

use_ok 'Device::Modbus::ASCII::ADU';

my @tests = (
    [ pack('C',   96),   160,     'Simple value smaller than 255'  ],
    [ pack('H2', 'f3'),   13,     'Another small number'           ],
    [ pack('H*', '02F4'), 10,     'With string longer than a char' ],
    [ pack('H*', '030100130013'), 214, 'Example read coils request'],
    [ pack('H*', '0103020280'),   120, 'Actual result from sensor' ],
);

foreach my $t (@tests) {
    my ($str, $manual, $test) = @$t;
    # my $lrc = unpack 'C*', Device::Modbus::ASCII::ADU->lrc_for($str);
    my $lrc = Device::Modbus::ASCII::ADU->lrc_for($str);
    is $lrc, long_lrc($str), $test;
    is length(pack 'C*', $lrc), 1, 'Length of LRC is correct for ' . unpack 'H*', $str;
    is $lrc, $manual, "As compared to manual calculation of $manual"; 
}

done_testing();

sub long_lrc {
    my $a        = shift;
    my @chars    = split //, $a;
    my $sum      = 0;
    $sum        += $_ foreach map { unpack 'C', $_ } @chars;
    no warnings 'pack';
    my $last_chr = unpack 'C', substr pack('C*', $sum), 0, 1;
    my $lrc      = 0xFF - $last_chr + 1;
    return $lrc;
}

