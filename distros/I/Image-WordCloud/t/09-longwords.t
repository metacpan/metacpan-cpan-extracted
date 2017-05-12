use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use File::Spec;
use Image::WordCloud;
use GD::Text::Align;

my $font_dir = File::Spec->catdir('.', 'share', 'fonts');

# Don't prune boring words for this test
my $wc = new Image::WordCloud(
	image_size   => [800, 800],
	prune_boring => 0,
	font_path    => $font_dir
);

# Init a bunch of words
my @words = qw/this is a bunch of words resurrection/;
my @tempwords = @words;
my %wordhash = map { shift @tempwords => $_ } (1 .. ($#tempwords+1));
$wc->words(\%wordhash);

# Initial maximum font size
my $init_max = $wc->_init_max_font_size();

# Create a test image string
my $t = new GD::Text::Align(new GD::Image);
$t->set_text('thisisreallyaverylongworddontyouthinkIdo');

my $max = $wc->_max_font_size();

ok($max < $init_max, 		"Maximum font size is being adjusted");

note(sprintf "Scaled font size from [%s to %s]", $init_max, $max);
