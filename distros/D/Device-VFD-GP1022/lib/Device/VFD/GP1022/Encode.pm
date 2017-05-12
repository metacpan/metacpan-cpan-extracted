package Device::VFD::GP1022::Encode;

use strict;
use warnings;
use Encode ();

sub new {
    my $class = shift;
    bless {}, $class;
}

sub encode {
    my($self, $str) = @_;

    my @chars;
    for my $char (split //, $str) {
        push @chars, convert($char);
    }
    join '', @chars;
}

sub convert {
    my $char = shift;

    my @char_code = unpack 'C*', $char;
    if (scalar(@char_code) eq 1) {
        my $code = $char_code[0] - 32;
        my($c, $d) = (($code % 32), int($code / 32));
        $c |= 128 if $d && $d % 2;
        return pack('CC', $c, int($d / 2));
    }

    my $jis = Encode::encode('7bit-jis', $char);

    my @byte = split //, $jis;
    my $jis1 = $byte[3];
    my $jis2 = $byte[4];


    my @jis_a = reverse split '', unpack 'B*', $jis2;
    my @jis_b = reverse split '', unpack 'B*', $jis1;

    my @jis_c = qw(0 0 0 0 0 0 0 0);
    my @jis_d = qw(0 0 0 0 0 0 0 0);

    @jis_c[0,1,2,3,4,7] = (@jis_a[0,1,2,3,4], $jis_b[0]);
    @jis_d[0,1,2] = @jis_b[1,2,3];

    if (check_bit(\@jis_b, 0, 1, 0)) {
        # not kanji
        @jis_d[2,3] = @jis_a[5,6];
    } elsif (check_bit(\@jis_b, 0, 1, 1)) {
        # kanji1-1
        @jis_c[5,6] = @jis_a[5,6];
        $jis_d[3]   = $jis_b[6];
    } elsif (check_bit(\@jis_b, 1, 0, 0)) {
        # kanji1-2
        @jis_c[5,6] = @jis_a[5,6];
        $jis_d[3]   = $jis_b[6];
    } elsif (check_bit(\@jis_b, 1, 0, 1)) {
        # kanji2-1
        @jis_c[5,6] = @jis_a[5,6];
        @jis_d[3,4] = ($jis_b[5], 1);
    } elsif (check_bit(\@jis_b, 1, 1, 0)) {
        # kanji2-2
        @jis_c[5,6] = @jis_a[5,6];
        @jis_d[3,4] = ($jis_b[5], 1);
    } elsif (check_bit(\@jis_b, 1, 1, 1)) {
        # kanji2-3
        @jis_d[2,3,4] = (@jis_a[5,6], 1);
    } else {
        # other
        return pack('CC', 0,0);
    }

    return pack('B*', join('', reverse @jis_c)), pack('B*', join('', reverse @jis_d));
}

sub check_bit {
    my($bits, $b7, $b6, $b5) = @_;
    return 1 if $bits->[6] eq $b7 && $bits->[5] eq $b6 && $bits->[4] eq $b5;
    return 0;
}

1;
