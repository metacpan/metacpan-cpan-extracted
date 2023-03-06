package Ethereum::RPC::Contract::Helper::UnitConversion;

use strict;
use warnings;
use Math::BigInt;

our $VERSION = '0.05';

=head1 NAME

    Ethereum::RPC::Contract::Helper::UnitConversion - Ethereum Unit Converter

    wei:        '1'
    kwei:       '1E3'
    mwei:       '1E6'
    gwei:       '1E9'
    szabo:      '1E12'
    finney:     '1E15'
    ether:      '1E18'
    kether:     '1E21'
    mether:     '1E24'
    gether:     '1E27'
    tether:     '1E30'

=cut

sub to_wei {
    return to_hex(shift, 1);
}

sub to_kwei {
    return to_hex(shift, 1E3);
}

sub to_mwei {
    return to_hex(shift, 1E6);
}

sub to_gwei {
    return to_hex(shift, 1E9);
}

sub to_szabo {
    return to_hex(shift, 1E12);
}

sub to_finney {
    return to_hex(shift, 1E15);
}

sub to_ether {
    return to_hex(shift, 1E18);
}

sub to_kether {
    return to_hex(shift, 1E21);
}

sub to_mether {
    return to_hex(shift, 1E24);
}

sub to_gether {
    return to_hex(shift, 1E27);
}

sub to_tether {
    return to_hex(shift, 1E30);
}

sub to_hex {
    my ($number, $precision) = @_;
    return "0x" . Math::BigFloat->new($number)->bmul($precision)->to_hex;
}

1;
