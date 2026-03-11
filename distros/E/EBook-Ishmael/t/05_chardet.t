#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use EBook::Ishmael::CharDet;

use File::Spec;

use EBook::Ishmael::Dir;

sub slurp {

    my ($file) = @_;

    open my $fh, '<', $file or die "Failed to open $file: $!";
    binmode $fh;
    my $slurp = do { local $/; <$fh> };
    close $fh;

    return $slurp;

}

my $DATA_DIR = File::Spec->catfile(qw/t data chardet/);

my %TEST_ENCODINGS = (
    'ascii'     => 'ASCII',
    'big5'      => 'Big5',
    'utf8'      => 'UTF-8',
    'gb2312'    => 'GB2312',
    'hz'        => 'hz',
    'eucjp'     => 'EUC-JP',
    'iso2022jp' => 'iso-2022-jp',
    'shiftjis'  => 'Shift_JIS',
    'euckr'     => 'EUC-KR',
    'iso2022kr' => 'iso-2022-kr',
    'cp1250'    => 'CP1250',
    'cp1251'    => 'CP1251',
    'cp1252'    => 'CP1252',
    'cp1253'    => 'CP1253',
    'cp1254'    => 'CP1254',
    'cp1255'    => 'CP1255',
    'cp1256'    => 'CP1256',
    'iso88595'  => 'iso-8859-5',
);

for my $e (sort keys %TEST_ENCODINGS) {
    my $want = $TEST_ENCODINGS{ $e };
    my $tesdir = File::Spec->catfile($DATA_DIR, $e);
    for my $f (dir($tesdir)) {
        my ($basename) = $f =~ /[\/\\]([^\/\\]+)$/;
        my $slurp = slurp($f);
        is(chardet($slurp), $want, "$e/$basename ok");
    }
}

done_testing;
