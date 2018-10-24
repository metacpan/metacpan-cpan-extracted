#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::Moji ':all';
binmode STDOUT, ":encoding(utf8)";
for (qw/あったか〜い つめた〜い ん〜 アッタカ〜イ/) {
    my $word = $_;
    while ($word =~ /(\p{InKana})〜/ && $1 ne 'ん') {
	my $kana = $1;
	my $romaji = kana2romaji ($kana);
	$romaji =~ s/[^aiueo]//g;
	my $vowel = romaji2kana ($romaji);
	if ($kana =~ /\p{InHiragana}/) {
	    $vowel = kata2hira ($vowel);
	}
        $word =~ s/$kana〜/$kana$vowel/g;
    }
    print "$_ -> $word\n";
}




