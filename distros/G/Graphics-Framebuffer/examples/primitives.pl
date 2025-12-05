#!/usr/bin/env perl

##############################################################################
# This script shows you how each graphics primitive and operation works.  It #
# has not been optimized on purpose, so you can see how each is written.     #
##############################################################################

use strict;

use Graphics::Framebuffer;
use List::Util qw(min max shuffle);
use Time::HiRes qw(sleep time alarm);
use Getopt::Long;
use Pod::Usage;

# Just for debugging and will cause a lot of overhead, hence why it is normally commented out.
# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '6.09';
}

our $F;

my $new_x;
my $new_y;
my $dev      = 0;     # Framebuffer device
my $psize    = 1;     # Pixel size
my $delay    = 3;     # Delay in seconds
my $noaccel  = FALSE; # Turn on/off C acceleration
my $nosplash = FALSE; # Turn on/off the splash screen
my $ignore_x = FALSE; # Ignore the check for X-Windows/Wayland
my $small    = FALSE; # Force a small screen for debugging core dumps
my $help     = FALSE; # Shows a brief help screen
my $man      = FALSE; # Shows the full POD manual
my $errors   = FALSE;
my $show_func;

GetOptions(
	'help|?'           => \$help,
	'man'              => \$man,
    'x=i'              => \$new_x,
    'y=i'              => \$new_y,
    'dev=i'            => \$dev,
    'pixel=i'          => \$psize,
    'noaccel'          => \$noaccel,
    'nosplash'         => \$nosplash,
    'delay=i'          => \$delay,
    'func=s'           => \$show_func,
    'ignore-x-windows' => \$ignore_x,
    'small'            => \$small,
	'errors'           => \$errors,
);

pod2usage(1) if ($help); # Show brief help
pod2usage(-exitval => 0, -verbose => 2) if ($man); # Show the full POD manual

$noaccel = ($noaccel) ? 1 : 0;    # Only 1 or 0 please
if ($small) { # force a centered 320x200 screen for core dump debugging
    $new_x = 320;
    $new_y = 200;
}

my $images_path = (-e 'images/4KTest_Pattern.png') ? 'images' : 'examples/images';

my $splash = ($nosplash) ? 0 : 2;
print "\n\nGathering images...\n";
$| = 1;
opendir(my $DIR, $images_path);
chomp(my @files = readdir($DIR));
closedir($DIR);

our @IMAGES;
our @ANIM;
our $STAMP = sprintf('%.1', time);

if (defined($new_x)) { # Ignore kernel structure and force a specific resolution
    $F = Graphics::Framebuffer->new(
		'FB_DEVICE'        => "/dev/fb$dev",
		'SHOW_ERRORS'      => $errors,
		'SIMULATED_X'      => $new_x,
		'SIMULATED_Y'      => $new_y,
		'ACCELERATED'      => !$noaccel,
		'SPLASH'           => 0,
		'RESET'            => TRUE,
		'IGNORE_X_WINDOWS' => $ignore_x,
	);
} else { # Adhere to the kernel structuter for the screen layout (normal usage)
    $F = Graphics::Framebuffer->new(
		'FB_DEVICE'        => "/dev/fb$dev",
		'SHOW_ERRORS'      => $errors,
		'ACCELERATED'      => !$noaccel,
		'SPLASH'           => 0,
		'RESET'            => TRUE,
		'IGNORE_X_WINDOWS' => $ignore_x,
	);
}
# Trap all means to end, and exit cleanly
$SIG{'QUIT'} = $SIG{'INT'} = $SIG{'KILL'} = $SIG{'HUP'} = $SIG{'TERM'} = sub { eval { $F->text_mode(); exec('reset'); }; };

my $sinfo = $F->screen_dimensions(); # Get the screen demensions
$F->cls('OFF'); # Clear the screen and turn off the cursor

my $screen_width  = $sinfo->{'width'};
my $screen_height = $sinfo->{'height'};

# Everything is based on a 3840x2160 screen, but different resolutions
# are mathematically scaled.  It's better to scale down than to scale up.

my $xm = $screen_width / 3840;
my $ym = $screen_height / 2160;

my $XX = $screen_width;
my $YY = $screen_height;

# Determine the center point of the screen
my $center_x = $F->{'X_CLIP'} + ($F->{'W_CLIP'} / 2);
my $center_y = $F->{'Y_CLIP'} + ($F->{'H_CLIP'} / 2);
# Some Raspberry Pis are very slow.  This detects them and allows the code to adjust.
# Only those that are BCM2708 and BCM2709 are detected (the slow ones).
my $rpi      = ($F->{'fscreeninfo'}->{'id'} =~ /BCM270(8|9)/i) ? TRUE : FALSE;

$delay *= 3 if ($rpi);    # Older Raspberry PIs are sloooooow.  Let's give extra time for each test
my $BW = 0;
if ($rpi) {
    print "Putting tennis balls on the walker, because this is a Raspberry PI (or equally slow clone)\n";
    sleep 3;
}

print_it($F, ' ', '00FFFFFF');
$F->{'SPLASH'} = $splash;
$F->splash($Graphics::Framebuffer::VERSION) unless ($nosplash);

my $DORKSMILE;

# Pre-load the images

foreach my $file (@files) {
    next if ($file =~ /^\.+/ || $file =~ /Test/i || -d "$images_path/$file"); # Ignore the test pattern and directories
	if ($file =~ /\.gif$/i) {
		print_it($F, "Loading Animation > $file", '00FFFFFF', undef, 1);
		my $image;
		if ($XX > 320) { # Only load native for larger screens
			$image = $F->load_image(
				{
					'file'   => "$images_path/$file",
					'center' => CENTER_XY
				}
			);
			push(@ANIM,$image);
		}
		$image = $F->load_image(
			{
				'width'  => $XX,
				'height' => $YY - $F->{'Y_CLIP'},
				'file'   => "$images_path/$file",
				'center' => CENTER_XY
			}
		);
		push(@ANIM,$image);
		push(@ANIM,$image) if ($XX <= 320); # "Native" is really scaled down for tiny screens.
	} else {
		print_it($F, "Loading Image > $file", '00FFFFFF', undef, 1);
		my $image = $F->load_image(
			{
				'x'            => 0,
				'y'            => 0,
				'width'        => $XX,
				'height'       => $F->{'H_CLIP'},
				'file'         => "$images_path/$file",
				'convertalpha' => ($file =~ /wolf|Crescent/i) ? 1 : 0,
				'center'       => CENTER_XY,
			}
		);
		if (defined($image)) {
			if ($file =~ /Solid/) {
				$DORKSMILE = $image;
			} else {
				push(@IMAGES, $image);
			}
		}
	}
}

$F->cls();

# This is a hash calling each demo.  It typically just passes through the framebuffer object
# The hash names are also used for the "--func=" option.

##################################
my %func = (
	'Drop'                              => sub { drop(shift); },
    'Color Mapping'                     => sub { color_mapping(shift); },
    'Plotting'                          => sub { plotting(shift); },
    'Lines'                             => sub { lines(shift, 0); },
    'Angle Lines'                       => sub { angle_lines(shift, 0); },
    'Polygons'                          => sub { polygons(shift, 0); },
    'Antialiased Lines'                 => sub { lines(shift, 1); },
    'Antialiased Angle Lines'           => sub { angle_lines(shift, 1); },
    'Antialiased Polygons'              => sub { polygons(shift, 1); },
    'Boxes'                             => sub { boxes(shift); },
    'Rounded Boxes'                     => sub { rounded_boxes(shift); },
    'Circles'                           => sub { circles(shift); },
    'Ellipses'                          => sub { ellipses(shift); },
    'Arcs'                              => sub { arcs(shift); },
    'Poly Arcs'                         => sub { poly_arcs(shift); },
    'Beziers'                           => sub { beziers(shift); },
    'Filled Boxes'                      => sub { filled_boxes(shift); },
    'Filled Rounded Boxes'              => sub { filled_rounded_boxes(shift); },
    'Filled Circles'                    => sub { filled_circles(shift); },
    'Filled Ellipses'                   => sub { filled_ellipses(shift); },
    'Filled Pies'                       => sub { filled_pies(shift); },
    'Filled Polygons'                   => sub { filled_polygons(shift); },
    'Hatch Filled Boxes'                => sub { hatch_filled_boxes(shift); },
    'Hatch Filled Rounded Boxes'        => sub { hatch_filled_rounded_boxes(shift); },
    'Hatch Filled Circles'              => sub { hatch_filled_circles(shift); },
    'Hatch Filled Ellipses'             => sub { hatch_filled_ellipses(shift); },
    'Hatch Filled Pies'                 => sub { hatch_filled_pies(shift); },
    'Hatch Filled Polygons'             => sub { hatch_filled_polygons(shift); },
    'Vertical Gradient Boxes'           => sub { gradient_boxes(shift, 'vertical'); },
    'Vertical Gradient Rounded Boxes'   => sub { gradient_rounded_boxes(shift, 'vertical'); },
    'Vertical Gradient Circles'         => sub { gradient_circles(shift, 'vertical'); },
    'Vertical Gradient Ellipses'        => sub { gradient_ellipses(shift, 'vertical'); },
    'Vertical Gradient Pies'            => sub { gradient_pies(shift, 'vertical'); },
    'Vertical Gradient Polygons'        => sub { gradient_polygons(shift, 'vertical'); },
    'Horizontal Gradient Boxes'         => sub { gradient_boxes(shift, 'horizontal'); },
    'Horizontal Gradient Rounded Boxes' => sub { gradient_rounded_boxes(shift, 'horizontal'); },
    'Horizontal Gradient Circles'       => sub { gradient_circles(shift, 'horizontal'); },
    'Horizontal Gradient Ellipses'      => sub { gradient_ellipses(shift, 'horizontal'); },
    'Horizontal Gradient Pies'          => sub { gradient_pies(shift, 'horizontal'); },
    'Horizontal Gradient Polygons'      => sub { gradient_polygons(shift, 'horizontal'); },
    'Texture Filled Boxes'              => sub { texture_filled_boxes(shift); },
    'Texture Filled Rounded Boxes'      => sub { texture_filled_rounded_boxes(shift); },
    'Texture Filled Circles'            => sub { texture_filled_circles(shift); },
    'Texture Filled Ellipses'           => sub { texture_filled_ellipses(shift); },
    'Texture Filled Pies'               => sub { texture_filled_pies(shift); },
    'Texture Filled Polygons'           => sub { texture_filled_polygons(shift); },
    'Flood Fill'                        => sub { flood_fill(shift); },
    'TrueType Fonts'                    => sub { truetype_fonts(shift); },
    'TrueType Printing'                 => sub { truetype_printing(shift); },
    'Rotate TrueType Fonts'             => sub { rotate_truetype_fonts(shift); },
    'Color Replace Non-Clipped'         => sub { color_replace(shift, 0); },
    'Color Replace Clipped'             => sub { color_replace(shift, 1); },
    'Blitting'                          => sub { blitting(shift); },
    'Blit Move'                         => sub { blit_move(shift); },
    'Rotate'                            => sub { rotate(shift); },
    'Flipping'                          => sub { flipping(shift); },
    'Monochrome'                        => sub { monochrome(shift); },
    'XOR Mode Drawing'                  => sub { mode_drawing(shift,1); },
    'OR Mode Drawing'                   => sub { mode_drawing(shift,2); },
    'AND Mode Drawing'                  => sub { mode_drawing(shift,3); },
    'MASK Mode Drawing'                 => sub { mode_drawing(shift,4); },
    'UNMASK Mode Drawing'               => sub { mode_drawing(shift,5); },
    'ALPHA Mode Drawing'                => sub { mode_drawing(shift,6); },
    'ADD Mode Drawing'                  => sub { mode_drawing(shift,7); },
    'SUBTRACT Mode Drawing'             => sub { mode_drawing(shift,8); },
    'MULTIPLY Mode Drawing'             => sub { mode_drawing(shift,9); },
    'DIVIDE Mode Drawing'               => sub { mode_drawing(shift,10); },
    'Animated'                          => sub { animated(shift); },
);

my @order;
if (defined($show_func)) { # If the "--func" option is used, the they are run only
    @order = split(/,/, $show_func);
} else {
    @order = ( # Define the order to run for each demo
        'Color Mapping',
        'Plotting',
        'Lines',
        'Angle Lines',
        'Polygons',
        'Antialiased Lines',
        'Antialiased Angle Lines',
        'Antialiased Polygons',
        'Boxes',
        'Rounded Boxes',
        'Circles',
        'Ellipses',
        'Arcs',
        'Poly Arcs',
        'Beziers',
		'Drop',
        'Filled Boxes',
        'Filled Rounded Boxes',
        'Filled Circles',
        'Filled Ellipses',
        'Filled Pies',
        'Filled Polygons',
        'Hatch Filled Boxes',
        'Hatch Filled Rounded Boxes',
        'Hatch Filled Circles',
        'Hatch Filled Ellipses',
        'Hatch Filled Pies',
        'Hatch Filled Polygons',
        'Vertical Gradient Boxes',
        'Vertical Gradient Rounded Boxes',
        'Vertical Gradient Circles',
        'Vertical Gradient Ellipses',
        'Vertical Gradient Pies',
        'Vertical Gradient Polygons',
        'Horizontal Gradient Boxes',
        'Horizontal Gradient Rounded Boxes',
        'Horizontal Gradient Circles',
        'Horizontal Gradient Ellipses',
        'Horizontal Gradient Pies',
        'Horizontal Gradient Polygons',
        'Texture Filled Boxes',
        'Texture Filled Rounded Boxes',
        'Texture Filled Circles',
        'Texture Filled Ellipses',
        'Texture Filled Pies',
        'Texture Filled Polygons',
        'Flood Fill',
        'TrueType Fonts',
        'TrueType Printing',
        'Rotate TrueType Fonts',
        'Color Replace Non-Clipped',
        'Color Replace Clipped',
        'Blitting',
        'Blit Move',
        'Rotate',
        'Flipping',
        'Monochrome',
        'XOR Mode Drawing',
        'OR Mode Drawing',
        'AND Mode Drawing',
        'MASK Mode Drawing',
        'UNMASK Mode Drawing',
        'ALPHA Mode Drawing',
        'ADD Mode Drawing',
        'SUBTRACT Mode Drawing',
#        'MULTIPLY Mode Drawing', # These are nuts and not really helpful
#        'DIVIDE Mode Drawing',
        'Animated',
    );
}

# Each demo is run with and without C acceleration
foreach my $name (@order) {
    if (exists($func{$name})) {
		unless ($name =~ /^(Color Mapping|ADD|SUBTRACT|Rotate TrueType Fonts|TrueType|Flipping)/) {
			$F->cls();
			$F->acceleration(PERL);
			$func{$name}->($name . ' -> Pure-Perl');
		}
		$F->cls();
		$F->acceleration(SOFTWARE);
		$func{$name}->($name . ' -> C Accelerated');
		sleep $delay unless($name =~ /Plot|Lines|Poly|Boxes|Circles|Ellipses|Arcs|Beziers|Pies/);
    }
}

##################################

$F->clip_reset();      # Turn off any clipping
$F->attribute_reset(); # Reset attributes to their defaults
$F->text_mode();       # Turn off graphics mode and restore text mode
$F->cls('ON');         # Clear the screen and turn the cursor on
undef($F);             # Destroy the framebuffer object

exit(0);

sub drop {
	# Bases on some BASIC code I found on a Facebook group
	my $name = shift;
	print_it($F, $name);

	my $xs = 3;
	my $xp = $xs * 96;
	my $xr = $xs * pi;
	my $xf = $xr / $xp;
	my $ys = 112;

	for (my $zi=-64;$zi<=64;$zi++) {
		my $zt = $zi * ($xp / 64);
		my $zs = $zt * $zt;
		my $xl = int(sqrt($xp * $xp - $zs) + 0.5);
		for (my $xi=-($xl);$xi<=$xl;$xi++) {
			my $xt = sqrt($xi * $xi + $zs) * $xf;
			my $yy = (sin($xt) + sin($xt * 3) * 0.4) * $ys;
			my $x1 = $xi + $zi + $screen_width / 2;
			my $y1 = ($screen_height / 2) - $yy + $zi;
			if ($F->acceleration()) {
				$F->set_color(
					{
						'alpha' => 255,
						'red'   => 255,
						'green' => 255,
						'blue'  => 0,
					}
				);
			} else {
				$F->set_color(
					{
						'alpha' => 255,
						'red'   => 0,
						'green' => 255,
						'blue'  => 0,
					}
				);
			}
			$F->plot(
				{
					'x' => $x1,
					'y' => $y1,
				}
			);
			$F->set_color(
				{
					'red'   => 0,
					'green' => 0,
					'blue'  => 0,
				}
			);
			$F->line(
				{
					'x'  => $x1,
					'y'  => ($y1 + 1),
					'xx' => $x1,
					'yy' => (($screen_height / 2) + 205),
				}
			);
		}
	}
}

sub color_mapping { # Shows Red-Green-Blue to see if color mapping is correct (in the proper order).
	my $name = shift;
	print_it($F, $name);
    $F->rbox(
        {
            'filled'   => 1,
            'x'        => 0,
            'y'        => $F->{'Y_CLIP'},
            'width'    => $XX,
            'height'   => $F->{'H_CLIP'},
            'gradient' => {
                'direction' => 'horizontal',
                'colors'    => {
                    'red'   => [255, 255, 0,   0,   0,   255],
                    'green' => [0,   255, 255, 255, 0,   0],
                    'blue'  => [0,   0,   0,   255, 255, 255]
                }
            }
        }
    );

    sleep $delay / 2;

    $F->rbox(
        {
            'filled'   => 1,
            'x'        => 0,
            'y'        => $F->{'Y_CLIP'},
            'width'    => $XX,
            'height'   => $F->{'H_CLIP'},
            'gradient' => {
                'direction' => 'vertical',
                'colors'    => {
                    'red'   => [255, 255, 0,   0,   0,   255],
                    'green' => [0,   255, 255, 255, 0,   0],
                    'blue'  => [0,   0,   0,   255, 255, 255]
                }
            }
        }
    );

    sleep $delay / 2 unless ($rpi);

    my $image = $F->load_image(
        {
            'x'      => 0,
            'y'      => $F->{'Y_CLIP'},
            'width'  => $XX,
            'height' => $YY - $F->{'Y_CLIP'},
            'center' => CENTER_XY,
            'file'   => "$images_path/4KTest_Pattern.png"
        }
    );
    $F->blit_write($image);
}

sub plotting {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $x = int(rand($screen_width));
        my $y = int(rand($screen_height));
        $F->set_color(
			{
				'alpha' => 255,
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
			}
		);
        $F->plot(
			{
				'x'          => $x,
				'y'          => $y,
				'pixel_size' => $psize,
			}
		);
    }
}

sub lines {
    my $name = shift;
    my $aa   = shift;

	print_it($F, $name);
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->line(
			{
				'x'           => int(rand($XX)),
				'y'           => int(rand($YY)),
				'xx'          => int(rand($XX)),
				'yy'          => int(rand($YY)),
				'antialiased' => $aa,
				'pixel_size'  => $psize,
			}
		);
    }
} ## end sub lines

sub angle_lines {
    my $name = shift;
    my $aa   = shift;

	print_it($F, $name);

    my $s     = time + $delay;
    my $angle = 0;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->angle_line(
			{
				'x'           => $center_x,
				'y'           => $center_y,
				'radius'      => int($F->{'H_CLIP'} / 2),
				'angle'       => $angle,
				'antialiased' => $aa,
				'pixel_size'  => $psize,
			}
		);
        $angle = ($F->acceleration()) ? $angle + .5 : $angle + 1;
        $angle -= 360 if ($angle >= 360);
    }
}

sub boxes {
    my $name = shift;
	print_it($F, $name);
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->box(
			{
				'x'          => int(rand($XX)),
				'y'          => int(rand($YY)),
				'xx'         => int(rand($XX)),
				'yy'         => int(rand($YY)),
				'pixel_size' => $psize,
			}
		);
    }
}

sub filled_boxes {
    my $name = shift;
	print_it($F, $name);
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->box(
			{
				'x'      => int(rand($XX)),
				'y'      => int(rand($YY)),
				'xx'     => int(rand($XX)),
				'yy'     => int(rand($YY)),
				'filled' => 1,
			}
		);
    }
}

sub gradient_boxes {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $x  = int(rand($XX));
        my $xx = int(rand($XX));
        my $y  = int(rand($YY));
        my $yy = int(rand($YY));
        my $h  = max($yy, $y) - min($yy, $y);
        my $w  = max($xx, $x) - min($xx, $x);
        next if ($w < 10 || $h < 10);
        my $count = min($h, int(rand(10)) + 2);
        my @red   = map { $_ = int(rand(256)) } (1 .. $count);
        my @green = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue  = map { $_ = int(rand(256)) } (1 .. $count);

        $F->box(
            {
                'x'        => $x,
                'y'        => $y,
                'xx'       => $xx,
                'yy'       => $yy,
                'filled'   => 1,
                'gradient' => {
                    'direction' => $direction,
                    'colors'    => {
                        'red'   => \@red,
                        'green' => \@green,
                        'blue'  => \@blue,
                    }
                }
            }
        );
    }
}

sub hatch_filled_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'alpha' => 255,
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
			}
		);
        $F->set_b_color(
			{
				'alpha' => 255,
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
			}
		);
        my $x  = int(rand($XX));
        my $xx = int(rand($XX));
        my $y  = int(rand($YY));
        my $yy = int(rand($YY));
        my $h  = max($yy, $y) - min($yy, $y);
        my $w  = max($xx, $x) - min($xx, $x);
        next if ($w < 10 || $h < 10);

        $F->box(
            {
                'x'      => $x,
                'y'      => $y,
                'xx'     => $xx,
                'yy'     => $yy,
                'filled' => 1,
                'hatch'  => $HATCHES[int(rand(scalar(@HATCHES)))]
            }
        );
    }
    $F->attribute_reset();
}

sub texture_filled_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s) {
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->box(
            {
                'x'       => int(rand($XX)),
                'y'       => int(rand($YY)),
                'xx'      => int(rand($XX)),
                'yy'      => int(rand($YY)),
                'filled'  => 1,
                'texture' => $image
            }
        );
    }
}

sub rounded_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->box(
			{
				'x'          => int(rand($XX)),
				'y'          => int(rand($YY)),
				'xx'         => int(rand($XX)),
				'yy'         => int(rand($YY)),
				'radius'     => 4 + rand($XX / 16),
				'pixel_size' => $psize,
			}
		);
    }
}

sub filled_rounded_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->box(
			{
				'x'      => int(rand($XX)),
				'y'      => int(rand($YY)),
				'xx'     => int(rand($XX)),
				'yy'     => int(rand($YY)),
				'radius' => 4 + rand($XX / 16),
				'filled' => 1 });
    }
}

sub hatch_filled_rounded_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->set_b_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->box(
			{
				'x'      => int(rand($XX)),
				'y'      => int(rand($YY)),
				'xx'     => int(rand($XX)),
				'yy'     => int(rand($YY)),
				'radius' => 4 + rand($XX / 16),
				'filled' => 1,
				'hatch'  => $HATCHES[int(rand(scalar(@HATCHES)))],
			}
		);
    }
    $F->attribute_reset();
}

sub gradient_rounded_boxes {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $x  = int(rand($XX));
        my $xx = int(rand($XX));
        my $y  = int(rand($YY));
        my $yy = int(rand($YY));
        my $w  = max($xx, $x) - min($xx, $x);
        my $h  = max($yy, $y) - min($yy, $y);
        next if ($w < 10 || $h < 10);
        my $count = min($w, int(rand(10)) + 2);
        my @red   = map { $_ = int(rand(256)) } (1 .. $count);
        my @green = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue  = map { $_ = int(rand(256)) } (1 .. $count);
        $F->box(
            {
                'x'        => $x,
                'y'        => $y,
                'xx'       => $xx,
                'yy'       => $yy,
                'radius'   => 4 + rand($XX / 16),
                'filled'   => 1,
                'gradient' => {
                    'direction' => $direction,
                    'colors'    => {
                        'red'   => \@red,
                        'green' => \@green,
                        'blue'  => \@blue,
                    }
                }
            }
        );
    }
}

sub texture_filled_rounded_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s) {
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->box(
            {
                'x'       => int(rand($XX)),
                'y'       => int(rand($YY)),
                'xx'      => int(rand($XX)),
                'yy'      => int(rand($YY)),
                'radius'  => rand($XX / 16),
                'filled'  => 1,
                'texture' => $image
            }
        );
    }
}

sub circles {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'          => int(rand($XX)),
				'y'          => int(rand($YY)),
				'radius'     => rand($center_y),
				'pixel_size' => $psize,
			}
		);
    }
}

sub filled_circles {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'      => int(rand($XX)),
				'y'      => int(rand($YY)),
				'radius' => rand($center_y),
				'filled' => 1,
			}
		);
    }
}

sub hatch_filled_circles {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->set_b_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'      => int(rand($XX)),
				'y'      => int(rand($YY)),
				'radius' => rand($center_y),
				'filled' => 1,
				'hatch'  => $HATCHES[int(rand(scalar(@HATCHES)))],
			}
		);
    }
    $F->attribute_reset();
}

sub gradient_circles {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $x     = int(rand($XX));
        my $r     = int(rand($center_y) + 20);
        my $w     = $r * 2;
        my $count = min($w, int(rand(10)) + 2);
        my @red   = map { $_ = int(rand(256)) } (1 .. $count);
        my @green = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue  = map { $_ = int(rand(256)) } (1 .. $count);
        $F->circle(
            {
                'x'        => $x,
                'y'        => int(rand($YY)),
                'radius'   => $r,
                'filled'   => 1,
                'gradient' => {
                    'direction' => $direction,
                    'colors'    => {
                        'red'   => \@red,
                        'green' => \@green,
                        'blue'  => \@blue,
                    }
                }
            }
        );
    }
}

sub texture_filled_circles {
    my $name = shift;
	print_it($F, $name);

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s) {
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->circle(
            {
                'x'       => int(rand($XX)),
                'y'       => int(rand($YY)),
                'radius'  => rand($center_y),
                'filled'  => 1,
                'texture' => $image
            }
        );
    }
}

sub arcs {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->arc(
			{
				'x'             => int(rand($XX)),
				'y'             => int(rand($YY)),
				'radius'        => rand($center_y),
				'start_degrees' => rand(360),
				'end_degrees'   => rand(360),
				'pixel_size'    => $psize,
			}
		);
    }
}

sub poly_arcs {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->poly_arc(
			{
				'x'             => int(rand($XX)),
				'y'             => int(rand($YY)),
				'radius'        => rand($center_y),
				'start_degrees' => rand(360),
				'end_degrees'   => rand(360),
				'pixel_size'    => $psize,
			}
		);
    }
}

sub filled_pies {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->filled_pie(
			{
				'x' => int(rand($XX)),
				'y' => int(rand($YY)),
				'radius' => rand($center_y),
				'start_degrees' => rand(360),
				'end_degrees' => rand(360),
			}
		);
    }
}

sub hatch_filled_pies {
    my $name = shift;
	print_it($F, $name);

    my $s = time + ($delay * 2);
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->set_b_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->filled_pie(
			{
				'x'             => int(rand($XX)),
				'y'             => int(rand($YY)),
				'radius'        => rand($center_y),
				'start_degrees' => rand(360),
				'end_degrees'   => rand(360),
				'hatch'         => $HATCHES[int(rand(scalar(@HATCHES)))],
			}
		);
    }
    $F->attribute_reset();
}

sub gradient_pies {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $x     = int(rand($XX));
        my $r     = int(rand($center_y) + 20);
        my $w     = $r * 2;
        my $count = min($w, int(rand(10)) + 2);
        my @red   = map { $_ = int(rand(256)) } (1 .. $count);
        my @green = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue  = map { $_ = int(rand(256)) } (1 .. $count);
        $F->filled_pie(
            {
                'x'             => $x,
                'y'             => int(rand($YY)),
                'radius'        => $r,
                'start_degrees' => rand(360),
                'end_degrees'   => rand(360),
                'gradient'      => {
                    'direction' => $direction,
                    'colors'    => {
                        'red'   => \@red,
                        'green' => \@green,
                        'blue'  => \@blue,
                    }
                }
            }
        );
    }
}

sub texture_filled_pies {
    my $name = shift;
	print_it($F, $name);

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;

    while (time < $s) {
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        my $x     = int(rand($XX));
        my $r     = int(rand($center_y) + 20);

        $F->filled_pie(
            {
                'x'             => $x,
                'y'             => int(rand($YY)),
                'radius'        => $r,
                'start_degrees' => rand(360),
                'end_degrees'   => rand(360),
                'texture'       => $image,
            }
        );
    }
}

sub ellipses {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->ellipse(
			{
				'x'          => int(rand($XX)),
				'y'          => int(rand($YY)),
				'xradius'    => rand($center_x),
				'yradius'    => rand($center_y),
				'pixel_size' => $psize,
			}
		);
    }
}

sub filled_ellipses {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red' => int(rand(256)),
				'green' => int(rand(256)),
				'blue' => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->ellipse(
			{
				'x'       => int(rand($XX)),
				'y'       => int(rand($YY)),
				'xradius' => rand($center_x),
				'yradius' => rand($center_y),
				'filled'  => 1,
			}
		);
    }
}

sub hatch_filled_ellipses {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->set_b_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->ellipse(
			{
				'x' => int(rand($XX)),
				'y' => int(rand($YY)),
				'xradius' => rand($center_x),
				'yradius' => rand($center_y),
				'filled' => 1,
				'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))],
			}
		);
    }
    $F->attribute_reset();
}

sub gradient_ellipses {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $rh    = int(rand($center_y) + 20);
        my $h     = $rh * 2;
        my $count = min($h, int(rand(10)) + 2);
        my @red   = map { $_ = int(rand(256)) } (1 .. $count);
        my @green = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue  = map { $_ = int(rand(256)) } (1 .. $count);
        $F->ellipse(
            {
                'x'        => int(rand($XX)),
                'y'        => int(rand($YY)),
                'xradius'  => rand($center_x),
                'yradius'  => $rh,
                'filled'   => 1,
                'gradient' => {
                    'direction' => $direction,
                    'colors'    => {
                        'red'   => \@red,
                        'green' => \@green,
                        'blue'  => \@blue,
                    }
                }
            }
        );
    }
}

sub texture_filled_ellipses {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->ellipse(
            {
                'x'       => int(rand($XX)),
                'y'       => int(rand($YY)),
                'xradius' => int(rand($center_x)),
                'yradius' => int(rand($center_y)),
                'filled'  => 1,
                'texture' => $image
            }
        );
    }
}

sub polygons {
    my $name = shift;
    my $aa   = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red' => int(rand(256)),
				'green' => int(rand(256)),
				'blue' => int(rand(256)),
			}
		);
        my $points = 4;
        my $coords = [];
        foreach my $p (1 .. $points) {
            push(@{$coords}, int(rand($XX)), int(rand($YY)));
        }
        $F->polygon(
            {
                'coordinates' => $coords,
                'antialiased' => $aa,
                'pixel_size'  => $psize
            }
        );
    }
}

sub filled_polygons {
    my $name = shift;
	print_it($F, $name);

    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        my $points = 4;
        my $coords = [];
        foreach my $p (1 .. $points) {
            push(@{$coords}, int(rand($XX)), int(rand($YY)));
        }
        $F->polygon(
            {
                'coordinates' => $coords,
                'filled'      => 1,
            }
        );
    }
}

sub hatch_filled_polygons {
    my $name = shift;
	print_it($F, $name);

    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->set_b_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        my $points = 4;
        my $coords = [];
        foreach my $p (1 .. $points) {
            push(@{$coords}, int(rand($XX)), int(rand($YY)));
        }
        $F->polygon(
            {
                'coordinates' => $coords,
                'filled'      => 1,
                'hatch'       => $HATCHES[int(rand(scalar(@HATCHES)))]
            }
        );
    }
    $F->attribute_reset();
}

sub gradient_polygons {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s) {
        my $count  = int(rand(10)) + 2;
        my @red    = map { $_ = int(rand(256)) } (1 .. $count);
        my @green  = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue   = map { $_ = int(rand(256)) } (1 .. $count);
        my $points = 4;
        my $coords = [];
        foreach my $p (1 .. $points) {
            push(@{$coords}, int(rand($XX)), int(rand($YY)));
        }
        $F->polygon(
            {
                'coordinates' => $coords,
                'filled'      => 1,
                'gradient'    => {
                    'direction' => $direction,
                    'colors'    => {
                        'red'   => \@red,
                        'green' => \@green,
                        'blue'  => \@blue,
                    }
                }
            }
        );
    }
}

sub texture_filled_polygons {
    my $name = shift;
	print_it($F, $name);

    $F->mask_mode() if ($F->acceleration());

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s) {
        my $image  = $IMAGES[int(rand(scalar(@IMAGES)))];
        my $points = 4;
        my $coords = [];
        foreach my $p (1 .. $points) {
            push(@{$coords}, int(rand($XX)), int(rand($YY)));
        }
        $F->polygon(
            {
                'coordinates' => $coords,
                'filled'      => 1,
                'texture'     => $image
            }
        );
    }
}

sub beziers {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        my @coords = ();
        foreach my $c (1 .. int(rand(20))) {
            push(@coords, int(rand($XX)), int(rand($YY)));
        }
        $F->bezier(
			{
				'coordinates' => \@coords,
				'points'      => 100,
				'pixel_size'  => $psize,
			}
		);
    }
}

sub truetype_fonts {
    my $name = shift;
	print_it($F, $name);

    my @fonts = (keys %{ $F->{'FONTS'} });
    my $g     = time + $delay;
    while (time < $g) {
        my $x    = int(rand(1200 * $xm));
        my $y    = int(rand(2160 * $ym));
        my $h    = ($YY <= 240 || $F->{'BITS'} == 16) ? (6 + rand(60)) : (8 + int(rand(300 * $ym)));
        my $ws   = ($XX <= 320 || $F->{'BITS'} == 16) ? rand(2)        : rand(4);
        my $font = $fonts[int(rand(scalar(@fonts)))];
        my $b    = $F->ttf_print(
            {
                'x'            => $x,
                'y'            => $y,
                'height'       => $h,
                'wscale'       => $ws,
                'color'        => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
                'text'         => $font,
                'font_path'    => $F->{'FONTS'}->{$font}->{'path'},
                'face'         => $F->{'FONTS'}->{$font}->{'font'},
                'bounding_box' => 1,

                #                'center'       => 3
            }
        );
        if (defined($b)) {
            $b->{'x'} = rand($F->{'XX_CLIP'} - $b->{'pwidth'});
            $F->ttf_print($b);
        }
    }
}

sub truetype_printing {
    my $name = shift;
	print_it($F, $name);

    $F->ttf_paragraph(
        {
            'x'       => 0,
            'y'       => 60 * $ym,
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 400,
            'justify' => 'justified',
            'size'    => int($YY / 75),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );

    $F->clip_set(
        {
            'x'  => $XX / 4,
            'y'  => $YY / 3,
            'xx' => (3 * ($XX / 4)),
            'yy' => (2 * ($YY / 3)),
        }
    );
    $F->ttf_paragraph(
        {
            'x'       => $XX / 4,
            'y'       => ($YY / 4) + 30,
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 200,
            'justify' => 'justified',
            'size'    => int($YY / 33),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );
    $F->clip_reset();
}

sub rotate_truetype_fonts {
    my $name = shift;
	print_it($F, $name);

    my $g     = time + $delay * 3;
    my $angle = 270;
    my $x     = $XX / 2;
    my $y     = $YY / 2;
    my $h     = ($YY <= 240 || $F->{'BITS'} == 16) ? 12 * $ym : 60 * $ym;
    my $ws    = 1;
	my $b;

    while (time < $g) {
        $b = $F->ttf_print(
            {
                'x'            => $x,
                'y'            => $y,
                'height'       => $h,
                'wscale'       => $ws,
                'color'        => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
                'text'         => "   $angle DEGREES   ",
                'rotate'       => $angle,
                'bounding_box' => TRUE,
                'center'       => CENTER_XY,
            }
        );
        if (defined($b)) {
            $F->ttf_print($b);
		} else {
			last;
        }
		$F->vsync();
        $angle++;
        $angle = 270 if ($angle >= 360);
    }
}

sub flood_fill {
    my $name = shift;
	print_it($F, $name);
    $F->clip_reset();

    if ($XX > 255) {    # && !$rpi) {
#        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->polygon(
			{
				'coordinates' => [
					440 * $xm,
					190 * $ym,
					3040 * $xm,
					160 * $xm,
					2320 * $xm,
					$YY,
					1920 * $xm,
					1080 * $ym,
					1520 * $xm,
					1560 * $ym
				],
			}
		);

        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->polygon(
			{
				'coordinates' => [
					2540 * $xm,
					1140 * $ym,
					1940 * $xm,
					340 * $ym,
					1200 * $xm,
					1000 * $ym
				],
			}
		);

        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'      => 1200 * $xm,
				'y'      => 640 * $ym,
				'radius' => 200 * $xm,
			}
		);

        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);

        $F->fill(
			{
				'x'       => int(700 * $xm),
				'y'       => int(500 * $ym),
#				'texture' => $image,
			}
		);

        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->fill(
			{
				'x' => 1920 * $xm,
				'y' => 880 * $ym,
			}
		);
    } else {
        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->polygon(
			{
				'coordinates' => [
					$center_x,
					3,
					3,
					$YY - 3,
					$center_x,
					$center_y,
					$XX - 3,
					$YY - 4,
				],
			}
		);

        $F->set_color(
			{
				'red'   => int(rand(256)),
				'green' => int(rand(256)),
				'blue'  => int(rand(256)),
				'alpha' => 255,
			}
		);
        $F->fill(
			{
				'x' => 3,
				'y' => 3,
			}
		);
    }
}

sub color_replace {
    my $name    = shift;
    my $clipped = shift;
	print_it($F, $name);

    my $x = $F->{'XRES'} / 4;
    my $y = $F->{'YRES'} / 4;

    $F->attribute_reset();
    $F->blit_write($DORKSMILE);
    $F->clip_set(
		{
			'x'  => $x,
			'y'  => $y,
			'xx' => $x * 3,
			'yy' => $y * 3,
		}
	) if ($clipped);
    my $s = time + $delay;
    while (time < $s) {
        my $pixel = $F->pixel(
			{
				'x' => $XX / 2,
				'y' => $YY / 2,
			}
		);
        my $r     = $pixel->{'red'};
        my $g     = $pixel->{'green'};
        my $b     = $pixel->{'blue'};
        my $a     = $pixel->{'alpha'};
        my $R     = int(rand(256));
        my $G     = int(rand(256));
        my $B     = int(rand(256));
        my $A     = 255;
        $F->replace_color(
            {
                'old' => {
					'red'   => $r,
					'green' => $g,
					'blue'  => $b,
                },
                'new' => {
					'red'   => $R,
					'green' => $G,
					'blue'  => $B,
					'alpha' => $A,
                }
            }
        );
    }
	$F->clip_reset();
}

sub blitting {
    my $name = shift;
	print_it($F, $name);

    my $s     = time + $delay;
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale'     => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );
    while (time < $s) {
        $image->{'x'} = abs(rand($XX - $image->{'width'}));
        $image->{'y'} = $F->{'Y_CLIP'} + abs(rand(($YY - $F->{'Y_CLIP'}) - $image->{'height'}));
        $F->blit_write($image);
    }
}

sub blit_move {
    my $name = shift;
	print_it($F, $name);

    $F->attribute_reset();
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale'     => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );
    my $x = 0;
    my $y = 40 * $ym;
	my $y_clip = $F->{'Y_CLIP'};
    $image->{'x'} = $x;
    $image->{'y'} = $y;
    $F->blit_write($image);
    my $s = time + $delay;

    while (time < $s) {
		$x = abs(rand($XX - $image->{'width'}));
		$y = $y_clip + abs(rand(($YY - $y_clip) - $image->{'height'}));
        $image = $F->blit_move(
			{
				%{$image},
				'x_dest' => abs($x),
				'y_dest' => int(abs($y)),
			}
		);
        $x++;
        $y += .5;
		sleep .0166666667;
        $F->vsync();
    }
}

sub rotate {
    my $name = shift;
	print_it($F, "Counter Clockwise $name");
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale'     => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );
    my $angle = 0;

	print_it($F, "Counter Clockwise $name");

    my $s     = time + $delay;
    my $count = 0;

    while (time < $s || $count < 6) {
        my $rot = $F->blit_transform(
            {
                'rotate' => {
                    'degrees' => $angle,
                    'quality' => 'quick',
                },
                'blit_data' => $image,
            }
        );
        $rot = $F->blit_transform(
            {
                'center'    => CENTER_XY,
                'blit_data' => $rot,
            }
        );

        $F->blit_write($rot);

        $angle++;
        $angle = 0 if ($angle >= 360);
        $count++;
    }

    $angle = 0;
	print_it($F, "Clockwise $name");
    $s     = time + $delay;
    $count = 0;
    while (time < $s || $count < 6) {
        my $rot = $F->blit_transform(
            {
                'rotate' => {
                    'degrees' => $angle,
                    'quality' => 'quick',
                },
                'blit_data' => $image,
            }
        );
        $rot = $F->blit_transform(
            {
                'center'    => CENTER_XY,
                'blit_data' => $rot,
            }
        );

        $F->blit_write($rot);

        $angle--;
        $angle = 0 if ($angle <= -360);
        $count++;
    }
}

sub flipping {
    my $name  = shift;
    my $r     = rand(scalar(@IMAGES));
    my $image = $IMAGES[$r];
    $image->{'image'} = "$IMAGES[$r]->{'image'}";

    my $s    = time + $delay * 2;
    my $zoom = time + $delay;
	print_it($F, $name);
    while (time < $s) {
        foreach my $dir (qw(normal horizontal vertical both)) {
            print_it($F, "$name $dir");
            unless ($dir eq 'normal') {
                my $rot = $F->blit_transform(
                    {
                        'flip'      => $dir,
                        'blit_data' => $image
                    }
                );
                $F->blit_write($rot);
            } else {
                $r                = rand(scalar(@IMAGES));
                $image            = $IMAGES[$r];
                $image->{'image'} = "$IMAGES[$r]->{'image'}";
                $F->blit_write($image);
            }
			sleep .0166666667;
            $F->vsync();
        }
    }
}

sub monochrome {
    my $name  = shift;
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
	print_it($F, $name);
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale'     => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );

    my $mono = { %{$image} };
    $mono->{'image'} = $F->monochrome({ 'image' => $image->{'image'}, 'bits' => $F->{'BITS'} });
    my $s = time + $delay;

    while (time < $s) {
        $mono->{'x'} = abs(rand($XX - $mono->{'width'}));
        $mono->{'y'} = $F->{'Y_CLIP'} + abs(rand(($YY - $F->{'Y_CLIP'}) - $mono->{'height'}));
        $F->blit_write($mono);
    }
}

sub animated {
    my $name = shift;
	print_it($F, $name . ' -> Loading...');

    opendir(my $DIR, $images_path);
    chomp(my @list = readdir($DIR));
    closedir($DIR);
    my $image;
    @list = shuffle(@list);
    foreach my $info (@list) {
        next unless ($info =~ /\.gif$/i);
        for my $count (0 .. 1) {
            my $new_name = ($count) ? "$name Fullscreen" : "$name Native";
			$image = $ANIM[$count];
			if ($count || $XX <= 320) {
				print_it($F,
					$new_name,
					'FF00FFFF',
				);
			} else {
				print_it($F,
					$new_name,
					'FF00FFFF',
				);
			}
			if (defined($image)) {
				$F->cls();
				my $fps   = 0;
				my $start = time;
				my $s     = time + $delay;

				while (time <= $s) {
					foreach my $frame (0 .. (scalar(@{$image}) - 1)) {
						if (time > $s * 2) {
							print_it($F, 'Your System is Too Slow To Complete The Animation', 'FF9999FF');
							sleep 2;
							last;
						}
						my $begin = time;
						$F->blit_write($image->[$frame]);

						my $Delay = (($image->[$frame]->{'tags'}->{'gif_delay'} * .01)) - (time - $begin);
						if ($Delay > 0) {
							sleep $Delay;
						}
					}
				}
			}
            last if ($XX <= 320);
        }
    }
}

sub mode_drawing {
	my $name = shift;
    my $mode = shift;
    if ($mode == MASK_MODE) {
        mask_drawing($name);
    } elsif ($mode == UNMASK_MODE) {
        unmask_drawing($name);
    } elsif ($mode == ALPHA_MODE) {
        alpha_drawing($name);
    } else {
        my @modes = qw( NORMAL XOR OR AND MASK UNMASK ALPHA ADD SUBTRACT MULTIPLY DIVIDE );
        print_it($F, "Testing $name");
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        my $image2;
        do {
            $image2 = $IMAGES[int(rand(scalar(@IMAGES)))];
        } until ($image2->{'image'} ne $image->{'image'});

        if ($mode == AND_MODE) {
            $F->set_b_color({ 'red' => 255, 'green' => 255, 'blue' => 255 });
            $F->cls();
        }

        $F->normal_mode();
        $F->blit_write($image);

        $F->{'DRAW_MODE'} = $mode;
        $F->blit_write($image2);

        my $size = int(($YY - $F->{'Y_CLIP'}) / 3);
        my $mid  = int($XX / 2);

        $F->set_color(
			{
				'red'   => 255,
				'green' => 0,
				'blue'  => 0,
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'      => $mid - ($size / 2),
				'y'      => $F->{'Y_CLIP'} + $size * 2,
				'radius' => $size,
				'filled' => 1,
			}
		);

        $F->set_color(
			{
				'red'   => 0,
				'green' => 255,
				'blue'  => 0,
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'      => $mid,
				'y'      => $F->{'Y_CLIP'} + $size,
				'radius' => $size,
				'filled' => 1,
			}
		);

        $F->set_color(
			{
				'red'   => 0,
				'green' => 0,
				'blue'  => 255,
				'alpha' => 255,
			}
		);
        $F->circle(
			{
				'x'      => $mid + ($size / 2),
				'y'      => $F->{'Y_CLIP'} + $size * 2,
				'radius' => $size,
				'filled' => 1,
			}
		);

        if ($mode == XOR_MODE) {
			sleep 1;
            $F->circle(
				{
					'x'      => $mid + ($size / 2),
					'y'      => $F->{'Y_CLIP'} + $size * 2,
					'radius' => $size,
					'filled' => 1,
				}
			);

            $F->set_color(
				{
					'red'   => 0,
					'green' => 255,
					'blue'  => 0,
					'alpha' => 255,
				}
			);
            $F->circle(
				{
					'x'      => $mid,
					'y'      => $F->{'Y_CLIP'} + $size,
					'radius' => $size,
					'filled' => 1,
				}
			);

            $F->set_color(
				{
					'red'   => 255,
					'green' => 0,
					'blue'  => 0,
					'alpha' => 255,
				}
			);
            $F->circle(
				{
					'x'      => $mid - ($size / 2),
					'y'      => $F->{'Y_CLIP'} + $size * 2,
					'radius' => $size,
					'filled' => 1,
				}
			);

            $F->blit_write($image2);

        } ## end if ($mode == XOR_MODE)
    } ## end else [ if ($mode == MASK_MODE)]
} ## end sub mode_drawing

sub alpha_drawing {
	my $name = shift;
    $F->attribute_reset();
	print_it($F, $name);
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    my $image2;
    do {
        $image2 = $IMAGES[int(rand(scalar(@IMAGES)))];
    } until ($image2->{'image'} ne $image->{'image'});
    my $size = length($image2->{'image'}) / $F->{'BYTES'};
    $image2->{'image'} &= pack('C4', 255, 255, 255, 0) x $size;
    $image2->{'image'} |= pack('C4', 0, 0, 0, 128) x $size;

    $F->normal_mode();
    $F->blit_write($image);

    $F->alpha_mode();
    $F->blit_write($image2);

    $F->set_color(
		{
			'red'   => 0,
			'green' => 255,
			'blue'  => 255,
			'alpha' => int(rand(128) + 128),
		}
	);
    $F->rbox(
		{
			'x'      => 0,
			'y'      => 0,
			'width'  => ($XX / 2),
			'height' => ($YY / 2),
			'filled' => 1,
		}
	);

    $F->set_color(
		{
			'red'   => 255,
			'green' => 0,
			'blue'  => 255,
			'alpha' => int(rand(128) + 128),
		}
	);
    $F->rbox(
		{
			'x'      => $XX / 4,
			'y'      => $YY / 4,
			'width'  => ($XX / 2),
			'height' => ($YY / 2),
			'filled' => 1,
		}
	);

    $F->set_color(
		{
			'red'   => 255,
			'green' => 255,
			'blue'  => 0,
			'alpha' => int(rand(128) + 128),
		}
	);
    $F->rbox(
		{
			'x'      => ($XX / 2),
			'y'      => ($YY / 2),
			'width'  => ($XX / 2),
			'height' => ($YY / 2),
			'filled' => 1,
		}
	);
} ## end sub alpha_drawing

sub mask_drawing {
	my $name = shift;
    $F->attribute_reset();
	print_it($F, $name);

    $F->set_b_color(
		{
			'red'   => 0,
			'green' => 0,
			'blue'  => 0,
			'alpha' => 0,
		}
	);
    my $h = int($YY - $F->{'Y_CLIP'});
    my $image1;
    my $image2 = $IMAGES[$BW];
    do {
        $image1 = $IMAGES[int(rand(scalar(@IMAGES)))];
    } until ($image2->{'image'} ne $image1->{'image'});
    $F->normal_mode();
    $F->blit_write($image1);
    $F->mask_mode();

    $F->blit_write($image2);
} ## end sub mask_drawing

sub unmask_drawing {
	my $name = shift;
    $F->attribute_reset();
	print_it($F, $name . ' (draw under)');

    $F->set_b_color(
		{
			'red'   => 0,
			'green' => 0,
			'blue'  => 0,
			'alpha' => 0,
		}
	);
    my $h = int($YY - $F->{'Y_CLIP'});
    my $image2;
    my $image1 = $IMAGES[$BW];
    do {
        $image2 = $IMAGES[int(rand(scalar(@IMAGES)))];
    } until ($image2->{'image'} ne $image1->{'image'});
    $F->normal_mode();
    $F->blit_write($image1);
    $F->unmask_mode();

    $F->blit_write($image2);
} ## end sub unmask_drawing

sub print_it {
    my $fb      = shift;
    my $message = shift;
    my $color   = shift || ($message =~ /Perl/) ? '00FF00FF' : 'FFFF00FF';
    my $bgcolor = shift || { 'red' => 0, 'green' => 0, 'blue' => 0, 'alpha' => 0 };
    my $noclear = shift || 0;

    $fb->normal_mode();

    $fb->set_b_color($bgcolor);
    $fb->cls() unless ($noclear);
	my $acc = $fb->acceleration();
	$fb->acceleration(SOFTWARE);
    unless ($XX <= 320) {

        #        $fb->or_mode();

        my $b = $fb->ttf_print(
            {
                'x'            => 5 * $xm,
                'y'            => max(18, 25 * $ym),
                'height'       => max(9,  20 * $ym),
                'wscale'       => 1.25,
                'color'        => $color,
                'text'         => uc($message),
                'bounding_box' => 1,
                'center'       => CENTER_X,
                'antialias'    => 0
            }
        );
        $fb->clip_set(
			{
				'x' => 0,
				'y' => 0,
				'xx' => $XX,
				'yy' => $b->{'pheight'} * .75,
			}
		);
        $fb->cls();
        $fb->ttf_print($b);
        $fb->clip_set(
			{
				'x'  => 0,
				'y'  => $b->{'pheight'} * .75,
				'xx' => $XX,
				'yy' => $YY,
			}
		);

        #        $center_y = (($YY - $b->{'pheight'}) / 2) + $b->{'pheight'};
        #        $fb->normal_mode();
    } else {
        print STDERR "$message\n";
    }
    $fb->_flush_screen();
	$fb->acceleration($acc);
} ## end sub print_it

# The data below is used for the Moire subroutine

__DATA__
4
9
6
5
1
2
8
3
7
4
9
6
5
1
2
8
3
7

__END__

=head1 NAME

Primitives Demonstration and Testing

=head1 DESCRIPTION

This script demonstrates the capabilities of the Graphics::Framebuffer module

=head1 SYNOPSIS

 perl primitives.pl [options]

=over 2

Examples:

=back

=over 4

 perl primitives.pl

 perl primitives.pl --dev=1 --x=640 --y=480

 perl primitives.pl --x=1280 --y=720 --pixel=2

 perl primitives.pl --small

=back

=head1 OPTIONS

=over 2

=item B<--help>

Print brief help instructions

=item B<--man>

Print the full manual page

=item B<--nosplash>

Turn off the splash screen

=item B<--dev>=C<device number>

By default, it uses "/dev/fb0", but you can tell it to use any framebuffer device number.  Only the number 0 - 31 is needed here.

=item B<--x>=C<width>

This tells the script to tell the Graphics::Framebuffer module to simulate a device of a specific width.  It will center it on the screen.

 "--x=800" would set the width to 800 pixels.

=item B<--y>=C<height>

This tells the script to tell the Graphics::Framebuffer module to simulate a device of a specific height.  It will center it on the screen.

 "--y=480" would set the height to 480 pixels.

=item B<--small>

This is a shortcut (and diagnostic tool) to set "x" and "y" to 320x200 respectively.  Use this if you are getting bus errors.  See the "TROUBLESHOOTING" file for using this setting to determine if GFB is incorrectly detecting screen parameters.

=item B<--pixel>=C<pixel size>

This tells the module to draw with larger pixels (larger means slower)

=item B<--noaccel>

Turns off C acceleration.  Uses only the Perl routines.

=item B<--delay>=seconds

Changes the amount of time given to each function

=item B<--func>="function name"

Instead of running all functions, just run one or more (separated by commas)

=item B<ignore-x-windows>

DANGEROUS TO USE!

This will turn off all checks for Wayland and X-Windows.  It will try to initialize a framebuffer anyway.

=back

=head1 NOTES

Place any other animated GIFs in the C<"examples/images/"> directory and it will include it in the testing

=head1 AUTHOR

Richard Kelsch <rich@rk-internet.com>

=head1 COPYRIGHT

Copyright 2003-2025 Richard Kelsch
All Rights Reserved

=head1 LICENSE

Perl Artistic License

This program must always be included as part of the Graphics::Framebuffer package.

=cut
