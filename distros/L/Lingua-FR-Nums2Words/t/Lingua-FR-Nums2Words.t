use strict;
use Test::More tests => 13;

BEGIN {
	use_ok('Lingua::FR::Nums2Words', ':all')
};

my @numbers = qw(3 6 19 -123);
my @ok_results = ('trois', 'six', 'dix-neuf', 'moins cent vingt trois');
my @results = num2word(@numbers);
ok(eq_array(\@results, \@ok_results));

is(num2word(0), 'zéro');
is(num2word(1), 'un');
is(num2word(-1), 'moins un');
is(num2word(1234), 'mille deux cent trente quatre');
is(num2word(100), 'cent');
is(num2word(200), 'deux cents');
is(num2word(123456), 'cent vingt trois mille quatre cent cinquante six');
is(num2word(1900450), 'un million neuf cent mille quatre cent cinquante');
is(num2word(4000000000), 'quatre milliards');
is(num2word(98), 'quatre-vingt-dix huit');
is(num2word(9999), 'neuf mille neuf cent quatre-vingt-dix neuf');
