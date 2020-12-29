#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use JSON::Create;

my %emojis = (
    animals => {
	kingkong => '🦍',
	goat => '🐐',
	elephant => '🐘',
    },
    fruit => {
	grape => '🍇',
	watermelon => '🍉',
	melon => '🍈',
    },
    baka => { # Japanese words
	'ば' => 'か',
	'あ' => 'ほ',
	'ま' => 'ぬけ',
    },
);
my $jc = JSON::Create->new ();

my @moons = qw!🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘!;
my $i = 0;
for (@moons) {
    $emojis{moons}{$_} = $i;
    $i++;
}

$jc->sort (1);
$jc->indent (1);
binmode STDOUT, ":encoding(utf8)";
print $jc->run (\%emojis);
