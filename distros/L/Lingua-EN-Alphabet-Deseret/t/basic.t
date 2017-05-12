use strict;
use warnings;
use Lingua::EN::Alphabet::Deseret;
use Test::More;
use utf8;

binmode DATA, ':utf8';
binmode STDOUT, ':utf8';

my @lines;
while (<DATA>) {
	chomp;
	push @lines, $_;
}

if (0) {
	# use this to generate test data
	while (@lines) {
		my $latin = shift @lines;
		shift @lines;
		
		print "$latin\n".
		Lingua::EN::Alphabet::Deseret::transliterate($latin)."\n";
	}
	exit;
}

plan tests => (scalar(@lines))/2;

while (@lines) {
	my $latin = shift @lines;
	my $deseret = shift @lines;

	is (Lingua::EN::Alphabet::Deseret::transliterate($latin),
		$deseret, $latin);
}

__DATA__
Deseret first BOOK
𐐔𐐯𐑅𐐨𐑉𐐯𐐻 𐑁𐐨𐑉𐑅𐐻 𐐒𐐋𐐗
bred
𐐺𐑉𐐯𐐼
Let us go to school.
𐐢𐐯𐐻 𐐲𐑅 𐑀𐐬 𐐻𐐭 𐑅𐐿𐐭𐑊.
make haste.
𐑋𐐩𐐿 𐐸𐐩𐑅𐐻.
BOY
𐐒𐐦
FEW few FEW
𐐙𐐧 𐑁𐑏 𐐙𐐧
badger
𐐺𐐰𐐾𐐨𐑉
