use strict;
use warnings;
use 5.008_001;
use Encode;

sub shex {
    join '' => map {sprintf('\x{%04X}',ord)} split //, $_[0];
}

sub ohex {
    join '' => map {sprintf('\x%02X',$_)} unpack('C0C*', $_[0]);
}

sub read_tsv {
    my $file = shift;
    my $table = {};
    open(TSV, $file) or die "$! - $file\n";
    while(<TSV>) {
        next if /^#/;
        my( $utf8, $sjis ) = split(/\s+/, $_);
        $table->{$sjis} = $utf8;
    }
    close(TSV);
    $table;
}

sub google_list {
    my $encode1 = 'x-sjis-e4u-docomo-pp';
    my $encode2 = 'x-sjis-e4u-kddiweb-pp';
    my $encode3 = 'x-sjis-e4u-softbank3g-pp';

    my $table1 = read_tsv('t/docomo-table.tsv');
    my $table2 = read_tsv('t/kddi-table.tsv');
    my $table3 = read_tsv('t/softbank-table.tsv');

    my $check = {};
    foreach my $sjisH (keys %$table1) {
        my $strS = decode $encode1 => pack ('H*' => $sjisH);
        $check->{$strS} ++;
    }
    foreach my $sjisH (keys %$table2) {
        my $strS = decode $encode2 => pack ('H*' => $sjisH);
        $check->{$strS} ++;
    }
    foreach my $sjisH (keys %$table3) {
        my $strS = decode $encode3 => pack ('H*' => $sjisH);
        $check->{$strS} ++;
    }

    [sort keys %$check];
}

1;
