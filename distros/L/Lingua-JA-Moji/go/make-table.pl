#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Lingua::JA::Moji ':all';
use File::Slurper 'write_text';
my $outfile = "$Bin/table.go";
my %consonant;
my %vowel;
for my $o (0x3000..0x3100) {
    my $k = chr ($o);
    if (! is_hiragana ($k)) {
	next;
    }
    if ($k eq 'ん') {
	$consonant{$k} = 'n';
	$vowel{$k} = '';
	next;
    }
    if ($k eq 'っ') {
	$consonant{$k} = 'xts';
	$vowel{$k} = 'u';
	next;
    }
    my $romaji = kana2romaji ($k);
#    print $romaji, "\n";
    my ($consonant, $vowel) = ($romaji =~ /^(.*)([aiueo])$/);
    $consonant{$k} = $consonant;
    $vowel{$k} = $vowel;
}
my $table = <<EOF;
package moji

var Consonant = map[rune]string {
EOF
for my $k (sort keys %consonant) {
    $table .= "'$k': \"$consonant{$k}\",\n";
}
$table .= <<EOF;
}

var Vowel = map[rune]string {
EOF
for my $k (sort keys %vowel) {
    $table .= "'$k': \"$vowel{$k}\",\n";
}
$table .= <<EOF;
}
EOF

write_text ($outfile, $table);
exit;
