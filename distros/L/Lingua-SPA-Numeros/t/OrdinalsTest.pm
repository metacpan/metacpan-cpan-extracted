package OrdinalsTest;

use utf8;

use strict;
use warnings;

use Lingua::SPA::Numeros;

use lib '.';
use CardinalsTest;

#########################

sub init {
    my $self      = shift;
    my $cardinal  = shift;
    my %t_ordinal = (
        0  => '',
        1  => 'primer_',
        2  => 'segund_',
        3  => 'tercer_',
        4  => 'cuart_',
        5  => 'quint_',
        6  => 'sext_',
        7  => 'séptim_',
        8  => 'octav_',
        9  => 'noven_',
        10 => 'décim_',
        11 => 'undécim_',
        12 => 'duodécim_',
        13 => 'decimotercer_',
        14 => 'decimocuart_',
        15 => 'decimoquint_',
        16 => 'decimosext_',
        17 => 'decimoséptim_',
        18 => 'decimoctav_',
        19 => 'decimonoven_',
        20 => 'vigésim_',
        21 => 'vigesimoprimer_',
        22 => 'vigesimosegund_',
        23 => 'vigesimotercer_',
        24 => 'vigesimocuart_',
        25 => 'vigesimoquint_',
        26 => 'vigesimosext_',
        27 => 'vigesimoséptim_',
        28 => 'vigesimoctav_',
        29 => 'vigesimonoven_',
        30 => 'trigésim_',
        31 => 'trigésim_ primer_',
        32 => 'trigésim_ segund_',
        33 => 'trigésim_ tercer_',
        34 => 'trigésim_ cuart_',
        35 => 'trigésim_ quint_',
        36 => 'trigésim_ sext_',
        37 => 'trigésim_ séptim_',
        38 => 'trigésim_ octav_',
        39 => 'trigésim_ noven_',
        40 => 'cuadragésim_',
        41 => 'cuadragésim_ primer_',
        42 => 'cuadragésim_ segund_',
        95 => 'nonagésim_ quint_',
        96 => 'nonagésim_ sext_',
        97 => 'nonagésim_ séptim_',
        98 => 'nonagésim_ octav_',
        99 => 'nonagésim_ noven_'
    );
    my @numeros = sort { $a <=> $b } keys %t_ordinal;

    my $i = 100;
    for my $c (qw/ c duoc tric cuadring quing sexc septig octing noning /) {
        for my $j (@numeros) {
            $t_ordinal{ $i + $j } = $c . "entésim_ " . $t_ordinal{$j};
        }
        $t_ordinal{$i} = $c . "entésim_";
        $i += 100;
    }

    for my $m (@numeros) {
        next unless $m;
        for my $c (@numeros) {
            for my $j ( 0, 100, 200, 900 ) {
                my $m1 = $m + $j;
                my $c1 = $c + $j;
                my $name
                    = ( $m1 == 1 ? '' : $cardinal->get($m1) ) . "milésim_ " . $t_ordinal{$c1};
                $name =~ s/\s+$//;
                $t_ordinal{ $m1 * 1000 + $c1 } = $name;
            }
        }
    }

    for my $num ( 1 .. 5, 19 .. 24, 38 .. 42, 996 .. 999 ) {
        my $numg = $num;
        my $nums = ( $num == 1 ? '' : $cardinal->get($num) );
        my $numb = $t_ordinal{$num};
        my $k    = $num * 1000 + $num;
        my $kg   = $k;
        my $ks   = $cardinal->get($k);
        my $kb   = $t_ordinal{$k};
        $ks =~ s/^un mil\b/mil/;

        for my $m ( CardinalsTest::llones() ) {
            $numg             = sprintf( "%s%06d", $numg, $num );
            $numb             = $nums . "${m}illonésim_ " . $numb;
            $t_ordinal{$numg} = $numb;
            $kg               = sprintf( "%s%06d", $kg, $k );
            $kb               = $ks . "${m}illonésim_ " . $kb;
            $t_ordinal{$kg}   = $kb;
        }
    }
    $t_ordinal{100000} = "cienmilésim_";
    $i = 6;
    for my $m ( CardinalsTest::llones() ) {
        $t_ordinal{ "1" . ( "0" x $i ) } = "${m}illonésim_";
        $t_ordinal{ "1" . ( "0" x ( $i + 1 ) ) } = "diez${m}illonésim_";
        $t_ordinal{ "1" . ( "0" x ( $i + 2 ) ) } = "cien${m}illonésim_";
        $t_ordinal{ "1" . ( "0" x ( $i + 3 ) ) } = "mil${m}illonésim_";
        $t_ordinal{ "1" . ( "0" x ( $i + 4 ) ) } = "diez mil${m}illonésim_";
        $t_ordinal{ "1" . ( "0" x ( $i + 5 ) ) } = "cien mil${m}illonésim_";

        $t_ordinal{ "2" . ( "0" x $i ) } = "dos${m}illonésim_";
        $i += 6;
    }
    bless \%t_ordinal, ref $self || $self;
}

sub get {
    my ( $self, $num, $exp, $gen ) = @_;
    $exp = 0   unless defined $exp;
    $gen = 'o' unless defined $gen;
    $num .= "0" x $exp;
    die("Unexistent number") unless exists $self->{$num};
    my $rv = $self->{$num};
    $rv =~ s/_/$gen/g;
    $rv;
}

1;
