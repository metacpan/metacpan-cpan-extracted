use strict;
use warnings;

use File::Spec;
use File::Temp;

use Image::Magick::CommandParser;

use Test::More;

# ------------------------------------------------

my(@test) =
(
{
	command	=> 'convert logo:',
	count	=> 1,
	glob	=> '',
},
{
	command	=> 'convert logo: output.png',
	count	=> 2,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85 output.png',
	count	=> 3,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85 -shade 110x90 output.png',
	count	=> 4,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85 canvas:none -shade 110x90 output.png',
	count	=> 5,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85 ( +clone canvas:none -shade 110x90 ) output.png',
	count	=> 6,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85 ( canvas:none +clone -shade 110x90 ) output.png',
	count	=> 7,
	glob	=> '',
},
{
	command	=> 'convert logo: canvas:none +clone output.png',
	count	=> 8,
	glob	=> '',
},
{
	command	=> 'convert gradient:red-green -gravity East output.png',
	count	=> 9,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg rose.png',
	count	=> 10,
	glob	=> '',
},
{
	command	=> 'convert label.gif -compose Plus button.gif',
	count	=> 11,
	glob	=> '',
},
{
	command	=> 'convert label.gif ( +clone -shade 110x90 -normalize -negate +clone -compose Plus -composite ) button.gif',
	count	=> 12,
	glob	=> '',
},
{
	command	=> 'convert label.gif ( +clone -shade 110x90 -normalize -negate +clone -compose Plus -composite ) ( -clone 0 -shade 110x50 -normalize -channel BG -fx 0 +channel -matte ) -delete 0 +swap -compose Multiply -composite button.gif',
	count	=> 13,
	glob	=> '',
},
{
	command	=> 'convert magick:logo -label "%m:%f %wx%h" logo.png',
	comment	=> q|See also test 51, which switches " and '|,
	count	=> 14,
	glob	=> '',
},
{
	command	=> 'convert magick:logo -label "%m:%f %wx%h %n" logo.png',
	count	=> 15,
	glob	=> '',
},
{
	command	=> 'convert magick:rose -label @t/label.1.txt -format "%l label" rose.png',
	count	=> 16,
	glob	=> 'convert magick:rose -label "%wx%h" -format "%l label" rose.png',
},
{
	command	=> 'convert -label @t/label.1.txt magick:rose -format "%l label" rose.png',
	count	=> 17,
	glob	=> 'convert -label "%wx%h" magick:rose -format "%l label" rose.png',
},
{
	command	=> 'convert rose.jpg -resize 50% rose.png',
	count	=> 18,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60x40% rose.png',
	count	=> 19,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60%x40 rose.png',
	count	=> 20,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60%x40% rose.png',
	count	=> 21,
	glob	=> '',
},
{
	command	=> 'convert -background lightblue -fill blue -font FreeSerif -pointsize 72 -label Marpa Marpa.png',
	count	=> 22,
	glob	=> '',
},
{
	command	=> 'convert -background lightblue -fill blue -font DejaVu-Serif-Italic -pointsize 72 -label Marpa Marpa.png',
	count	=> 23,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85^ output.png',
	count	=> 24,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85! output.png',
	count	=> 25,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85< output.png',
	count	=> 26,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85> output.png',
	count	=> 27,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85+0+0 output.png',
	count	=> 28,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 50%+0+0 rose.png',
	count	=> 29,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60x40%+0+0 rose.png',
	count	=> 30,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60%x40+0+0 rose.png',
	count	=> 31,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60%x40%+0+0 rose.png',
	count	=> 32,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 50%!+0+0 rose.png',
	count	=> 33,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60x40%<+0+0 rose.png',
	count	=> 34,
	glob	=> '',
},
{
	command	=> 'convert rose.jpg -resize 60%x40>+0+0 rose.png',
	count	=> 35,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85^ output.png',
	count	=> 36,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85! output.png',
	count	=> 37,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85< output.png',
	count	=> 38,
	glob	=> '',
},
{
	command	=> 'convert logo: -size 320x85> output.png',
	count	=> 39,
	glob	=> '',
},
{
	command	=> 'convert pattern:bricks -size 320x85 output.png',
	count	=> 40,
	glob	=> '',
},
{
	command	=> 'convert rgb:camera.image -size 320x85 output.png',
	count	=> 41,
	glob	=> '',
},
{
	command	=> 'convert - -size 320x85 output.png',
	count	=> 42,
	glob	=> '',
},
{
	command	=> 'convert gif:- -size 320x85 output.png',
	count	=> 43,
	glob	=> '',
},
{
	command	=> 'convert fd:3 -size 320x85 output.png',
	count	=> 44,
	glob	=> '',
},
{
	command	=> 'convert gif:fd:3 -size 320x85 output.png',
	count	=> 45,
	glob	=> '',
},
{
	command	=> 'convert fd:3 png:fd:4 gif:fd:5 fd:6 -append output.png',
	count	=> 46,
	glob	=> '',
},
{
	command	=> 'convert colors/*s*.png -append output.png',
	count	=> 47,
	glob	=> 'convert colors/fuchsia.png colors/silver.png -append output.png',
},
{
	command	=> 'convert label.gif +clone 0,4,5 button.gif',
	count	=> 48,
	glob	=> '',
},
{
	command	=> 'convert label.gif +clone -1 button.gif',
	count	=> 49,
	glob	=> '',
},
{
	command	=> q|convert magick:logo -resize '10000@' wiz10000.png|,
	count	=> 50,
	glob	=> '',
},
{
	command	=> q|convert magick:logo -label '%m:%f %wx%h' logo.png|,
	comment	=> q|See also test 14, which switches " and '|,
	count	=> 51,
	glob	=> '',
},
{
	command	=> 'convert magick:logo -size 320x85 gif:-',
	count	=> 52,
	glob	=> '',
},
);
my($limit)		= shift || 0;
my($maxlevel)	= shift || 'notice';
my($parser)		= Image::Magick::CommandParser -> new(maxlevel => $maxlevel);

my($expected);
my($got);
my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$result = $parser -> run(command => $$test{command});

	if ($result == 0)
	{
		$got		= $parser -> result;
		$expected	= $$test{glob} ? $$test{glob} : $$test{command};

		is_deeply($got, $expected, "$$test{count}: $expected");
	}
	else
	{
		die "Test $$test{count} failed to return 0 from run()\n";
	}
}

done_testing;
