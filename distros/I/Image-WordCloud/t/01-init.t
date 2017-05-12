use strict;
use warnings;

use Test::More tests => 9;
use Cwd;
use File::Spec;
use Image::WordCloud;

my $wc = Image::WordCloud->new();

isa_ok($wc, 'Image::WordCloud', 						"Instantiating right object");

$wc = Image::WordCloud->new(
  image_size     => [200, 210],
	word_count     => 25,
	prune_boring   => 0,
	font           => 'AveriaRegular',
	background     => [2, 2, 2],
	border_padding => 12,
);

# Make sure the options are being set right
is_deeply($wc->{'image_size'}, [200, 210],	"'image_size' being set right");
is($wc->{'word_count'},   25,								"'word_count' being set right");
is($wc->{'prune_boring'}, 0,								"'prune_boring' being set right");
is($wc->{'font'}, 'AveriaRegular',					"'font' being set right");
is($wc->{'border_padding'}, 12,							"'border_padding' being set right");
is_deeply($wc->{'background'}, [2, 2, 2],		"'background' being set right");

$wc = Image::WordCloud->new(font_path => '.');
is ($wc->{'font_path'}, '.', 								"'font_path' being set right");

$wc = Image::WordCloud->new(font_file => $0);
is ($wc->{'font_file'}, $0, 								"'font_file' being set right");

#my $stop_word_file = File::Spec->catfile('.', 'share', 
#is($wc->{'stop_word_file'}, 0,							"prune_boring being set right");