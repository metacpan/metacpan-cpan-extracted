package Image::Caa;

use strict;
use warnings;

our $VERSION = '1.01';

# dark colors
use constant CAA_COLOR_BLACK		=> 0;
use constant CAA_COLOR_RED		=> 1;
use constant CAA_COLOR_GREEN		=> 2;
use constant CAA_COLOR_YELLOW		=> 3;
use constant CAA_COLOR_BLUE		=> 4;
use constant CAA_COLOR_MAGENTA		=> 5;
use constant CAA_COLOR_CYAN		=> 6;
use constant CAA_COLOR_LIGHTGRAY	=> 7;

# light colors
use constant CAA_COLOR_DARKGRAY		=> 8;
use constant CAA_COLOR_LIGHTRED		=> 9;
use constant CAA_COLOR_LIGHTGREEN	=> 10;
use constant CAA_COLOR_BROWN		=> 11;
use constant CAA_COLOR_LIGHTBLUE	=> 12;
use constant CAA_COLOR_LIGHTMAGENTA	=> 13;
use constant CAA_COLOR_LIGHTCYAN	=> 14;
use constant CAA_COLOR_WHITE		=> 15;

use constant CAA_LOOKUP_VAL		=> 32;
use constant CAA_LOOKUP_SAT		=> 32;
use constant CAA_LOOKUP_HUE		=> 16;

use constant CAA_HSV_XRATIO		=> 6;
use constant CAA_HSV_YRATIO		=> 3;
use constant CAA_HSV_HRATIO		=> 3;


sub new {
	my $class = shift;
	my %opts = @_;
	my $opts = \%opts;

	my $self = bless {}, $class;

	$self->{driver} = $self->load_submodule($opts->{driver} || 'DriverANSI', $opts);
	$self->{dither} = $self->load_submodule($opts->{dither} || 'DitherNone', $opts);
	$self->{solid_background} = $opts->{black_bg} ? 0 : 1;

	$self->{hsv_palette} = [
		# weight, hue, saturation, value
		4,    0x0,    0x0,    0x0,   # black
		5,    0x0,    0x0,    0x5ff, # 30%
		5,    0x0,    0x0,    0x9ff, # 70%
		4,    0x0,    0x0,    0xfff, # white
		3,    0x1000, 0xfff,  0x5ff, # dark yellow
		2,    0x1000, 0xfff,  0xfff, # light yellow
		3,    0x0,    0xfff,  0x5ff, # dark red
		2,    0x0,    0xfff,  0xfff  # light red
	];

	$self->init();

	return $self;
}


sub init {
	my ($self) = @_;

	$self->{hsv_distances}	= [];

	for (my $v = 0; $v < CAA_LOOKUP_VAL; $v++){
	for (my $s = 0; $s < CAA_LOOKUP_SAT; $s++){
	for (my $h = 0; $h < CAA_LOOKUP_HUE; $h++){

		my $val = 0xfff * $v / (CAA_LOOKUP_VAL - 1);
		my $sat = 0xfff * $s / (CAA_LOOKUP_SAT - 1);
		my $hue = 0xfff * $h / (CAA_LOOKUP_HUE - 1);

		# Initialise distances to the distance between pure black HSV
		# coordinates and our white colour (3)

		my $outbg = 3;
		my $outfg = 3;
		my $distbg = $self->HSV_DISTANCE(0, 0, 0, 3);
		my $distfg = $self->HSV_DISTANCE(0, 0, 0, 3);


		# Calculate distances to eight major colour values and store the
		# two nearest points in our lookup table.

		for (my $i = 0; $i < 8; $i++){

			my $dist = $self->HSV_DISTANCE($hue, $sat, $val, $i);

			if ($dist <= $distbg){

				$outfg = $outbg;
				$distfg = $distbg;
				$outbg = $i;
				$distbg = $dist;

			}elsif ($dist <= $distfg){

				$outfg = $i;
				$distfg = $dist;
			}
		}

		$self->{hsv_distances}->[$v]->[$s]->[$h] = ($outfg << 4) | $outbg;
	}
	}
	}
}

sub init_instance {
	my ($self) = @_;

	$self->{lookup_colors}	= [];

	# These ones are constant
	$self->{lookup_colors}->[0] = CAA_COLOR_BLACK;
	$self->{lookup_colors}->[1] = CAA_COLOR_DARKGRAY;
	$self->{lookup_colors}->[2] = CAA_COLOR_LIGHTGRAY;
	$self->{lookup_colors}->[3] = CAA_COLOR_WHITE;

	# These ones will be overwritten
	$self->{lookup_colors}->[4] = CAA_COLOR_MAGENTA;
	$self->{lookup_colors}->[5] = CAA_COLOR_LIGHTMAGENTA;
	$self->{lookup_colors}->[6] = CAA_COLOR_RED;
	$self->{lookup_colors}->[7] = CAA_COLOR_LIGHTRED;
}

#
# Draw a bitmap on the screen.
#
# Draw a bitmap at the given coordinates. The bitmap can be of any size and
# will be stretched to the text area.
#
# x1 X coordinate of the upper-left corner of the drawing area.
# y1 Y coordinate of the upper-left corner of the drawing area.
# x2 X coordinate of the lower-right corner of the drawing area.
# y2 Y coordinate of the lower-right corner of the drawing area.
# image Image Magick picture object to be drawn.
#

sub draw_bitmap{
	my ($self, $x1, $y1, $x2, $y2, $image) = @_;

	my $w = $x2-$x1;
	my $h = $y2-$y1;

	my $iw = 0;
	my $ih = 0;
	my $h_pad = 0;
	my $v_pad = 0;

	if (defined $image){

		# resize to fit in the box

		$image->Scale('100%,67%');
		my $x = $image->Resize(geometry => ($w-2).'x'.($h-2));
		warn "$x" if "$x";

		($iw, $ih) = $image->Get('columns', 'rows');

		$h_pad = 1 + int(($w - $iw) / 2);
		$v_pad = 1 + int(($h - $ih) / 2);
	}

	$self->init_instance();
	$self->{driver}->init();


	# Only used when background is black

	my $white_colors = [
		CAA_COLOR_BLACK,
		CAA_COLOR_DARKGRAY,
		CAA_COLOR_LIGHTGRAY,
		CAA_COLOR_WHITE,
	];

	my $light_colors = [
		CAA_COLOR_LIGHTMAGENTA,
		CAA_COLOR_LIGHTRED,
		CAA_COLOR_YELLOW,
		CAA_COLOR_LIGHTGREEN,
		CAA_COLOR_LIGHTCYAN,
		CAA_COLOR_LIGHTBLUE,
		CAA_COLOR_LIGHTMAGENTA,
	];

	my $dark_colors = [
		CAA_COLOR_MAGENTA,
		CAA_COLOR_RED,
		CAA_COLOR_BROWN,
		CAA_COLOR_GREEN,
		CAA_COLOR_CYAN,
		CAA_COLOR_BLUE,
		CAA_COLOR_MAGENTA,
	];


	# FIXME: choose better characters!

	my $density_chars = 
		"    ".
		".   ".
		"..  ".
		"....".
		"::::".
		";=;=".
		"tftf".
		'%$%$'.
		"&KSZ".
		"WXGM".
		'@@@@'.
		"8888".
		"####".
		"????";

	my @density_chars = split //, $density_chars;
	$density_chars = \@density_chars;

	my $density_chars_size = scalar(@{$density_chars}) - 1;

	my $x = 0;
	my $y = 0;
	my $deltax = 0;
	my $deltay = 0;


	my $tmp;
	if ($x1 > $x2){ $tmp = $x2; $x2 = $x1; $x1 = $tmp; }
	if ($y1 > $y2){ $tmp = $y2; $y2 = $y1; $y1 = $tmp; }

	$deltax = $x2 - $x1 + 1;
	$deltay = $y2 - $y1 + 1;


	for ($y = $y1 > 0 ? $y1 : 0; $y <= $y2; $y++){
	$self->{dither}->init($y);
	for ($x = $x1 > 0 ? $x1 : 0; $x <= $x2; $x++){

		my $ch = 0;
		my $r = 0;
		my $g = 0;
		my $b = 0;
		my $a = 0;
		my $hue = 0;
		my $sat = 0;
		my $val = 0;
		my $fromx = 0;
		my $fromy = 0;
		my $tox = 0;
		my $toy = 0;
		my $myx = 0;
		my $myy = 0;
		my $dots = 0;
		my $outfg = 0;
		my $outbg = 0;
		my $outch = chr 0;

		#  First get RGB

		if (defined $image){

			my $px = ($x - $x1) - $h_pad;
			my $py = ($y - $y1) - $v_pad;

			my $to_l = $px < 0;
			my $to_t = $py < 0;
			my $to_r = $px >= $iw;
			my $to_b = $py >= $ih;

			if ($to_l || $to_t || $to_r || $to_b){

				$r = 0xfff;
				$g = 0xfff;
				$b = 0xfff;

			}else{

				($r, $g, $b, $a) = split /,/, $image->Get("pixel[$px,$py]");

				$r >>= 4;
				$g >>= 4;
				$b >>= 4;
			}

			#if (bitmap->has_alpha && a < 0x800) continue;

			# Now get HSV from RGB
			($hue, $sat, $val) = $self->rgb2hsv_default($r, $g, $b);

		}else{

			$hue = int(0x5fff * (($x-$x1) / ($x2-$x1)));
			$sat = int(0xfff * (($y-$y1) / ($y2-$y1)));
			$val = int(0xfff * (($y-$y1) / ($y2-$y1)));
			$val = 0x777;
		}


		# The hard work: calculate foreground and background colours,
		# as well as the most appropriate character to output.

		if ($self->{solid_background}){

			my $point = chr 0;
			my $distfg = 0;
			my $distbg = 0;

			$self->{lookup_colors}->[4] = $dark_colors->[1 + $hue / 0x1000];
			$self->{lookup_colors}->[5] = $light_colors->[1 + $hue / 0x1000];
			$self->{lookup_colors}->[6] = $dark_colors->[$hue / 0x1000];
			$self->{lookup_colors}->[7] = $light_colors->[$hue / 0x1000];

			my $idx_v = ($val + $self->{dither}->get() * (0x1000 / CAA_LOOKUP_VAL) / 0x100) * (CAA_LOOKUP_VAL - 1) / 0x1000;
			my $idx_s = ($sat + $self->{dither}->get() * (0x1000 / CAA_LOOKUP_SAT) / 0x100) * (CAA_LOOKUP_SAT - 1) / 0x1000;
			my $idx_h = (($hue & 0xfff) + $self->{dither}->get() * (0x1000 / CAA_LOOKUP_HUE) / 0x100) * (CAA_LOOKUP_HUE - 1) / 0x1000;

			$point = $self->{hsv_distances}->[$idx_v]->[$idx_s]->[$idx_h];

			$distfg = $self->HSV_DISTANCE($hue % 0xfff, $sat, $val, ($point >> 4));
			$distbg = $self->HSV_DISTANCE($hue % 0xfff, $sat, $val, ($point & 0xf));

			# Sanity check due to the lack of precision in hsv_distances,
			# and distbg can be > distfg because of dithering fuzziness.

			if ($distbg > $distfg){ $distbg = $distfg; }

			$outfg = $self->{lookup_colors}->[($point >> 4)];
			$outbg = $self->{lookup_colors}->[($point & 0xf)];

			$ch = $distbg * 2 * ($density_chars_size - 1) / ($distbg + $distfg);
			$ch = 4 * $ch + $self->{dither}->get() / 0x40;

			if ($ch >= scalar(@{$density_chars})){

				$ch = scalar(@{$density_chars}) - 1;
			}

			$outch = $density_chars->[$ch];

		}else{

			$outbg = CAA_COLOR_BLACK;

			if ($sat < 0x200 + $self->{dither}->get() * 0x8){

				$outfg = $white_colors->[1 + ($val * 2 + $self->{dither}->get() * 0x10) / 0x1000];

			}elsif ($val > 0x800 + $self->{dither}->get() * 0x4){

				$outfg = $light_colors->[($hue + $self->{dither}->get() * 0x10) / 0x1000];

			}else{
				$outfg = $dark_colors->[($hue + $self->{dither}->get() * 0x10) / 0x1000];
			}

			$ch = ($val + 0x2 * $self->{dither}->get()) * 10 / 0x1000;
			$ch = 4 * $ch + $self->{dither}->get() / 0x40;

			$outch = $density_chars->[$ch];
		}

		# Now output the character
		$self->{driver}->set_color($outfg, $outbg);
		$self->{driver}->putchar($x, $y, $outch);

		$self->{dither}->increment();
	}
	}

	$self->{driver}->fini();
}

sub rgb2hsv_default {
	my ($self, $r, $g, $b) = @_;

	my ($hue, $sat, $val) = (0, 0, 0);

	my $min = $r;
	my $max = $r;

	$min = $g if $min > $g;
	$max = $g if $max < $g;
	$min = $b if $min > $b;
	$max = $b if $max < $b;

	my $delta = $max - $min; # 0 - 0xfff
	$val = $max; # 0 - 0xfff

	if ($delta){

		$sat = 0xfff * $delta / $max; # 0 - 0xfff

		# Generate *hue between 0 and 0x5fff

		if ($r == $max){
			$hue = 0x1000 + 0x1000 * ($g - $b) / $delta;
		}elsif ($g == $max){
			$hue = 0x3000 + 0x1000 * ($b - $r) / $delta;
		}else{
			$hue = 0x5000 + 0x1000 * ($r - $g) / $delta;
		}
	}else{
		$sat = 0;
		$hue = 0;
	}

	return ($hue, $sat, $val);
}


sub HSV_DISTANCE{
	my ($self, $h, $s, $v, $index) = @_;

	my $v1 = $v - $self->{hsv_palette}->[$index * 4 + 3];
	my $s1 = $s - $self->{hsv_palette}->[$index * 4 + 2];
	my $h1 = $h - $self->{hsv_palette}->[$index * 4 + 1];

	my $s2 = $self->{hsv_palette}->[$index * 4 + 3] ? CAA_HSV_YRATIO * $s1 * $s1 : 0;
	my $h2 = $self->{hsv_palette}->[$index * 4 + 2] ? CAA_HSV_HRATIO * $h1 * $h1 : 0;

	return $self->{hsv_palette}->[$index * 4] * ((CAA_HSV_XRATIO * $v1 * $v1) + $s2 + $h2);
}

sub load_submodule {
	my ($self, $module, $args) = @_;

	eval "require Image::Caa::$module";
	warn $@ if $@;

	my $obj = undef;
	eval "\$obj = new Image::Caa::$module(\$args)";
	warn $@ if $@;

	if (!$@ && defined $obj){

		return $obj;
	}

	die "Image::Caa - Couldn't load 'Image::Caa::$module'";
}

1;

__END__

=head1 NAME

Image::Caa - Colored ASCII Art

=head1 SYNOPSIS

  use Image::Caa;
  use Image::Magick;


  # load an image

  my $image = Image::Magick->new;
  $image->Read('sunset.jpg');


  # display it as ASCII Art

  my $caa = new Image::Caa();
  $caa->draw_bitmap(0, 0, 40, 20, $image);


  # some fancy options

  my $caa = new Image::Caa(
    driver => 'DriverANSI',
    dither => 'DitherOrdered8',
    black_bg => 1,
  );
  $caa->draw_bitmap(0, 0, 40, 20, $image);

=head1 DESCRIPTION

This module outputs C<Image::Magick> image objects as ASCII Art, using a variety of output
dithering modes and output drivers (currently supported is a plain old ANSI termical
output driver and a curses driver).

=head1 METHODS

=over

=item C<new( opt =E<gt> 'value', ... )>

Returns a new C<Image::Caa> object. The options are as follows:

=over

=item * C<driver>

Output driver. Valid values are:

=over

=item * C<DriverANSI> (default)

=item * C<DriverCurses>

=back

=item * C<dither>

Dithering mode. Valid values are:

=over

=item * C<DitherNone> (default)

=item * C<DitherOrdered2>

=item * C<DitherOrdered4>

=item * C<DitherOrdered8>

=item * C<DitherRandom>

=back

=item * C<black_bg>

Set to 1 to enable black background mode.
By default, we use colored backgrounds to allow 256 colors (16 foreground x 16 background)

=item * C<window>

Used only by the Curses output driver. Indicates the Curses window to write output into.

=back

=item C<draw_bitmap($x1, $y1, $x2, $y2, $image)>

Draws the image C<$image> within the box bounded by C<($x1,$y1)-($x2,$y2)>.
Note that the default (ANSI) output driver ignores the origin position as uses
only the absolute box size.

=back

=head1 EXTENDING

Both the dithering and driver backends are plugable and fairly easy to create - just create 
modules in the Image::Caa::* namespace. Dither modules need to implement the C<new()>, 
C<init($line)>, C<get()> and C<increment()> methods. Driver modules need to implement the 
C<new()>, C<init()>, C<set_color($fg, $bg)>, C<putchar($x, $y, $char)> and C<fini()> methods.
Look at the existing modules for guidance.

=head1 AUTHORS

Copyright (C) 2006, Cal Henderson <cal@iamcal.com>

This library is based on libcaca's bitmap.c

libcaca is Copyright (C) 2004 Sam Hocevar <sam@zoy.org>

libcaca is licensed under the GNU Lesser General Publice License

=head1 SEE ALSO

L<Image::Magick>, L<http://sam.zoy.org/libcaca/>

=cut
