use strict;
use warnings;

use Test::More tests => 10;
use Test::Warn;
use File::Spec;
use File::Find::Rule;
use Image::WordCloud;

my $wc = new Image::WordCloud(font => 'arial');
is($wc->{'font'}, 'arial', "'font' option being set right");

# Make sure the font accessors return something
isnt($wc->_get_font(), 			undef, "_get_font() returns a value");
isnt($wc->_get_all_fonts(), undef, "_get_all_fonts() returns a value");


$wc = new Image::WordCloud();
my $num_fonts = scalar(@{ $wc->{'fonts'} });

ok($num_fonts > 0,		'Found font or fonts to use with no options');
note('Found ' . $num_fonts . ' fonts to use');

my $font_dir = File::Spec->catdir('.', 'share', 'fonts');
ok(-d $font_dir, 			"Found font directory in dist") or diag("Font directory '$font_dir' not found");

$wc = new Image::WordCloud( font_path => $font_dir );
is($wc->{'font_path'}, $font_dir,	"'font_path' being set right");

warning_like(
	sub { $wc = new Image::WordCloud( font_path => "blarg" ) },
	[
		qr/Specified font path .+? not found/,
		qr/No usable font path or font file found, only fonts available will be from libgd, which suck/,
	],
	"Missing font directory produces warning");

my @font_files = File::Find::Rule->new()
	->extras({ untaint => 1})
	->file()
	->name('*.ttf')
	->in($font_dir);

my $font_file = $font_files[0];
ok(-f $font_file,			"Found a font file in the font directory") or diag("Returned font file: '$font_file'");

$wc = new Image::WordCloud(font_file => $font_file);
is($wc->{'font_file'}, $font_file, 	"Font file option is being set");

warning_like(sub { $wc = new Image::WordCloud( font_file => "blarg" ) }, qr/Specified font file .+? not found/, "Missing font file produces warning");