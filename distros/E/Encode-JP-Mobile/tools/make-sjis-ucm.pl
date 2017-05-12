#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Path::Class;
use YAML;
use Encode;
use Encode::JP::Mobile;

my @encodings = (
    +{
        name        => 'x-sjis-airh-raw',
        alias       => "x-sjis-airedge-raw",
        carrier     => 'AirHPhone',
        table_maker => \&airh_table,
    },
    +{
        name        => 'x-sjis-docomo-raw',
        alias       => 'x-sjis-imode-raw',
        carrier     => 'DoCoMo',
        table_maker => table_maker_maker( 'docomo-table.yaml' ),
    },
    +{
        name        => 'x-sjis-kddi-auto-raw',
        alias       => 'x-sjis-ezweb-auto-raw',
        carrier     => 'KDDI/AU',
        table_maker => table_maker_maker( 'kddi-table.yaml', 'unicode_auto' ),
    },
    +{
        name        => 'x-sjis-kddi-cp932-raw',
        alias       => 'x-sjis-ezweb-cp932-raw',
        carrier     => 'KDDI/AU',
        table_maker => table_maker_maker( 'kddi-table.yaml' ),
    },
    +{
        name        => 'x-sjis-softbank-auto-raw',
        alias       => 'x-sjis-vodafone-auto-raw',
        carrier     => 'SoftBank',
        table_maker => table_maker_maker( 'softbank-table.yaml', 'unicode', 'sjis_auto' ),
        is_skip     => \&is_skip_softbank_auto,
    },
);

&main;exit;

sub airh_table {
    my $sort_key = shift;

    my @ret;
    my $add_to_ret = sub {
        my $x = shift;
        push @ret,
          +{
            unicode => sprintf('%X', $x ),
            sjis    => unpack( 'H*', encode( 'cp932', chr $x ) ),
          };
    };
    my $map = join "", Encode::JP::Mobile::InAirEdgePictograms(), Encode::JP::Mobile::InDoCoMoPictograms();
    for my $line (split /\n/, $map) {
        if ($line =~ /\t/) {
            my ($min, $max) = map { hex $_ } split /\t/, $line;
            my $i = $min;
            while ($i <= $max) {
                $add_to_ret->($i);
                $i++;
            }
        } else {
            $add_to_ret->(hex $line);
        }
    }
    @ret;
}

sub table_maker_maker {
    my ($file, $unicode_key, $sjis_key) = @_;
    $unicode_key ||= 'unicode';
    $sjis_key ||= 'sjis';

    sub {
        map { +{ unicode => $_->{$unicode_key}, sjis => $_->{$sjis_key} } }
          grep { $_->{$sjis_key} }
          sort { hex( $a->{$unicode_key} ) <=> hex( $b->{$unicode_key} ) }
          @{ YAML::LoadFile( file( $FindBin::Bin, '..', 'dat', $file ) ) };
    };
}

sub is_skip_softbank_auto {
    my $line = shift;

    # x-sjis-softbank-auto ではIBM拡張漢字の領域をつぶして絵文字用につかっている模様。
    # たとえば、U+52AF は IBM EXT では \xFB\x77 で、NEC EXT. では \xEE\x5B と表現できる(see cp932.ucm)
    # このうち、\xFB\x77 の方を絵文字領域として使用しているのだ。
    if ($line =~ /^<U[0-9A-F]+> (\S+) \|\d/) {
        if (in_softbank_pictogram($1)) {
            return 1;
        }
    }
    return;
}

my $sjis_auto_map;
sub in_softbank_pictogram {
    my $sjis = shift;
    $sjis_auto_map ||=
      +{ map { ( uc hexify( $_->{sjis} ) ) => 1 }
          grep { $_->{sjis} }
          table_maker_maker( 'softbank-table.yaml', 'unicode', 'sjis_auto' )->()
      };
    return $sjis_auto_map->{uc $sjis};
}

sub hexify {
    local $_ = shift;
    s/(..)/\\x$1/g;
    $_;
}

sub header {
    my $encoding = shift;

    return <<"...";
<code_set_name> "$encoding->{name}"
<code_set_alias> "$encoding->{alias}"
...
}

sub footer() {
    return <<'...';
END CHARMAP
...
}

sub generate_ucm {
    my $encoding = shift;
    my $cp932 = file($FindBin::Bin, '..', 'ucm', 'cp932.ucm')->openr;

    my $fh = file($FindBin::Bin, '..', 'ucm', "$encoding->{name}.ucm")->openw;
    $fh->print(header($encoding));
    while (<$cp932>) {
        next if /^#/;
        next if /<code_set_name> "cp932"/;
        next if /PRIVATE USE AREA/;
        next if /END CHARMAP/;
        next if $encoding->{is_skip} && $encoding->{is_skip}->($_);
        $fh->print($_);
    }
    $fh->print('<U301C> \x81\x60 |1 # WAVE DUSH', "\n"); # ad-hoc solution for  FULLWIDTH TILDE Problem.
    $fh->print("# below are copied from $encoding->{carrier}'s pictogram map\n");
    for my $row ($encoding->{table_maker}->()) {
        $fh->print(sprintf "<U%s> %s |0 # $encoding->{carrier} Pictogram\n", $row->{'unicode'}, hexify($row->{sjis}));
    }
    $fh->print(footer);
}

sub main {
    for my $encoding (@encodings) {
        generate_ucm($encoding);
    }
}

