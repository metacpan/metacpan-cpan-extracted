use strict;
use warnings;
use lib 't';
use Test::More 'no_plan';
use Encode;
use Encode::JP::Emoji;
require "test-util.pl";

sub read_scsv {
    my $file = shift;
    my $table = [];
    open(SCSV, $file) or die "$! - $file\n";
    while(<SCSV>) {
        next if /^#/;
        s/\s+$//s;
        push @$table, $_;
    }
    close(SCSV);
    $table;
}

my $table = read_scsv('t/EmojiSources.txt');
    
for my $line (@$table) {
    my($standardH, $docomoH, $kddiwebH, $softbankH) = split(/;/, $line);
    next unless $standardH;

    my $standardU = encode 'utf8' => join '' => map {chr hex $_} split(/\s+/, $standardH);
    my $standardS = decode 'x-utf8-e4u-unicode' => $standardU;
    my $standardR = encode 'x-utf8-e4u-unicode' => $standardS;
    SKIP: {
        skip "U+$standardH (Google U+FEB64)" => 1 if ($standardS eq "\x{FEB64}");
        is(ohex($standardR), ohex($standardU), "$standardH standard round-trip");
    }

    if ($docomoH) {
        my $docomoS = decode 'x-sjis-e4u-docomo' => pack 'H*' => $docomoH;
        my $docomoR = uc unpack 'H*' => encode 'x-sjis-e4u-docomo' => $standardS;
        is(shex($standardS), shex($docomoS), "$standardH docomo decode ($docomoH)");
        is($docomoR, $docomoH, "$standardH docomo docomo ($docomoH)");
    }
    if ($kddiwebH) {
        my $kddiwebS = decode 'x-sjis-e4u-kddiweb' => pack 'H*' => $kddiwebH;
        my $kddiwebR = uc unpack 'H*' => encode 'x-sjis-e4u-kddiweb' => $standardS;
        is(shex($standardS), shex($kddiwebS), "$standardH kddiweb decode ($kddiwebH)");
        is($kddiwebR, $kddiwebH, "$standardH kddiweb encode ($kddiwebH)");
    }
    if ($softbankH) {
        my $softbankS = decode 'x-sjis-e4u-softbank3g' => pack 'H*' => $softbankH;
        my $softbankR = uc unpack 'H*' => encode 'x-sjis-e4u-softbank3g' => $standardS;
        is(shex($standardS), shex($softbankS), "$standardH softbank decode ($softbankH)");
        is($softbankR, $softbankH, "$standardH softbank encode ($softbankH)");
    }
}
