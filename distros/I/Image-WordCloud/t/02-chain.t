use strict;
use warnings;

use Test::More tests => 2;
use Image::WordCloud;

my $gd = Image::WordCloud->new()
	->add_stop_words('bunch')
	->words('a bunch of words')
	->cloud();
	
isa_ok($gd, 'GD::Image', 'Method chaining returns proper GD::Image object');

my $wc = Image::WordCloud->new();
$wc->add_stop_words('bunch')
	 ->words('a bunch of words');

is(scalar keys %{ $wc->words() }, 1, 'Stop words being set up right with method chaining');
