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

# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '6.01';
}

our $F;

my $new_x;
my $new_y;
my $dev      = 0;
my $psize    = 1;
my $noaccel  = FALSE;
my $nosplash = FALSE;
my $delay    = 3;
my $ignore_x = FALSE;
my $small    = FALSE;
my $show_func;

GetOptions(
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
);

$noaccel = ($noaccel) ? 1 : 0;    # Only 1 or 0 please
if ($small) {
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
our $STAMP = sprintf('%.1', time);

if (defined($new_x)) {
    $F = Graphics::Framebuffer->new('FB_DEVICE' => "/dev/fb$dev", 'SHOW_ERRORS' => 0, 'SIMULATED_X' => $new_x, 'SIMULATED_Y' => $new_y, 'ACCELERATED' => !$noaccel, 'SPLASH' => 0, 'RESET' => TRUE, 'IGNORE_X_WINDOWS' => $ignore_x);
} else {
    $F = Graphics::Framebuffer->new('FB_DEVICE' => "/dev/fb$dev", 'SHOW_ERRORS' => 0, 'ACCELERATED' => !$noaccel, 'SPLASH' => 0, 'RESET' => TRUE, 'IGNORE_X_WINDOWS' => $ignore_x);
}
$SIG{'QUIT'} = $SIG{'INT'} = $SIG{'KILL'} = $SIG{'HUP'} = $SIG{'TERM'} = sub { eval { $F->text_mode(); exec('reset'); }; };

my $sinfo = $F->screen_dimensions();
$F->cls('OFF');

my $screen_width  = $sinfo->{'width'};
my $screen_height = $sinfo->{'height'};

# Everything is based on a 1920x1080 screen, but different resolutions
# are mathematically scaled.
my $xm = $screen_width / 1920;
my $ym = $screen_height / 1080;

my $XX = $screen_width;
my $YY = $screen_height;

my $center_x = $F->{'X_CLIP'} + ($F->{'W_CLIP'} / 2);
my $center_y = $F->{'Y_CLIP'} + ($F->{'H_CLIP'} / 2);
my $rpi      = ($F->{'fscreeninfo'}->{'id'} =~ /BCM270(8|9)/i) ? TRUE : FALSE;

$delay *= 3 if ($rpi);    # Raspberry PI is sloooooow.  Let's give extra time for each test
my $BW = 0;
if ($rpi) {
    print "Putting tennis balls on the walker, because this is a Raspberry PI (or equally slow clone)\n";
    sleep 3;
}

my $thread;

print_it($F, ' ', '00FFFFFF');
$F->{'SPLASH'} = $splash;
$F->splash($Graphics::Framebuffer::VERSION) unless ($nosplash);


my $DORKSMILE;

foreach my $file (@files) {
    next if ($file =~ /^\.+/ || $file =~ /Test|gif/i || -d "$images_path/$file");
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

$F->cls();

##################################
my %func = (
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
    'Color Replace None-Clipped'        => sub { color_replace(shift, 0); },
    'Color Replace Clipped'             => sub { color_replace(shift, 1); },
    'Blitting'                          => sub { blitting(shift); },
    'Blit Move'                         => sub { blit_move(shift); },
    'Rotate'                            => sub { rotate(shift); },
    'Flipping'                          => sub { flipping(shift); },
    'Monochrome'                        => sub { monochrome(shift); },
    'XOR Mode Drawing'                  => sub { mode_drawing(1); },
    'OR Mode Drawing'                   => sub { mode_drawing(2); },
    'AND Mode Drawing'                  => sub { mode_drawing(3); },
    'MASK Mode Drawing'                 => sub { mode_drawing(4); },
    'UNMASK Mode Drawing'               => sub { mode_drawing(5); },
    'ALPHA Mode Drawing'                => sub { mode_drawing(6); },
    'ADD Mode Drawing'                  => sub { mode_drawing(7); },
    'SUBTRACT Mode Drawing'             => sub { mode_drawing(8); },
    'MULTIPLY Mode Drawing'             => sub { mode_drawing(9); },
    'DIVIDE Mode Drawing'               => sub { mode_drawing(10); },
    'Animated'                          => sub { animated(shift); },
);

my @order;
if (defined($show_func)) {
    @order = split(/,/, $show_func);
} else {
    @order = (
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
        'Color Replace None-Clipped',
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
        #       'MULTIPLY Mode Drawing',
        #       'DIVIDE Mode Drawing',
        'Animated',
    );
}

foreach my $name (@order) {
    if (exists($func{$name})) {
		unless ($name =~ /^(Color Mapping|ADD|SUBTRACT|Rotate TrueType Fonts|TrueType|Flipping)/) {
			$F->cls();
			$F->acceleration(PERL);
			$func{$name}->($name . ' -> Pure-Perl');
		}
		unless ($name =~ /^(Anti)/) {
			$F->cls();
			$F->acceleration(SOFTWARE);
			$func{$name}->($name . ' -> Accelerated');
		}
    }
}

##################################

$F->clip_reset();
$F->attribute_reset();
$F->text_mode();
$F->cls('ON');
undef($F);

exit(0);

sub color_mapping {
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

    sleep $delay;
}

sub plotting {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $x = int(rand($screen_width));
        my $y = int(rand($screen_height));
        $F->set_color({ 'alpha' => 255, 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->plot({ 'x' => $x, 'y' => $y, 'pixel_size' => $psize });
    }
}

sub lines {
    my $name = shift;
    my $aa   = shift;

	print_it($F, $name);
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->line({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'antialiased' => $aa, 'pixel_size' => $psize });
    }
} ## end sub lines

sub angle_lines {
    my $name = shift;
    my $aa   = shift;

	print_it($F, $name);

    my $s     = time + $delay;
    my $angle = 0;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->angle_line({ 'x' => $center_x, 'y' => $center_y, 'radius' => int($F->{'H_CLIP'} / 2), 'angle' => $angle, 'antialiased' => $aa, 'pixel_size' => $psize });
        $angle++;
        $angle -= 360 if ($angle >= 360);
    }
}

sub boxes {
    my $name = shift;
	print_it($F, $name);
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'pixel_size' => $psize });
    }
}

sub filled_boxes {
    my $name = shift;
	print_it($F, $name);
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'filled' => 1 });
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
        $F->set_color({ 'alpha' => 255, 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'alpha' => 255, 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'pixel_size' => $psize });
    }
}

sub filled_rounded_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'filled' => 1 });
    }
}

sub hatch_filled_rounded_boxes {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'pixel_size' => $psize });
    }
}

sub filled_circles {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'filled' => 1 });
    }
}

sub hatch_filled_circles {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
    }
    $F->attribute_reset();
}

sub gradient_circles {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {

        #        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my $x     = int(rand($XX));
        my $r     = int(rand($center_y) + 10);
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->arc({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'pixel_size' => $psize });
    }
}

sub poly_arcs {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->poly_arc({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'pixel_size' => $psize });
    }
}

sub filled_pies {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->filled_pie({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360) });
    }
}

sub hatch_filled_pies {
    my $name = shift;
	print_it($F, $name);

    my $s = time + ($delay * 2);
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->filled_pie({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
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
        my $r     = int(rand($center_y) + 10);
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
        my $r     = int(rand($center_y) + 10);

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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'pixel_size' => $psize });
    }
}

sub filled_ellipses {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)), 'alpha' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'filled' => 1 });
    }
}

sub hatch_filled_ellipses {
    my $name = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
    }
    $F->attribute_reset();
}

sub gradient_ellipses {
    my $name      = shift;
    my $direction = shift;
	print_it($F, $name);

    my $s = time + $delay;
    while (time < $s) {
        my $rh    = int(rand($center_y) + 10);
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
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
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my @coords = ();
        foreach my $c (1 .. int(rand(20))) {
            push(@coords, int(rand($XX)), int(rand($YY)));
        }
        $F->bezier({ 'coordinates' => \@coords, 'points' => 100, 'pixel_size' => $psize });
    }
}

sub truetype_fonts {
    my $name = shift;
	print_it($F, $name);

    my @fonts = (keys %{ $F->{'FONTS'} });
    my $g     = time + $delay;
    while (time < $g) {
        my $x    = int(rand(600 * $xm));
        my $y    = int(rand(1080 * $ym));
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
            'y'       => 30,
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 400,
            'justify' => 'justified',
            'size'    => int($YY / 75),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );

    sleep $delay;
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
    sleep $delay;
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
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->polygon({ 'coordinates' => [220 * $xm, 190 * $ym, 1520 * $xm, 80 * $xm, 1160 * $xm, $YY, 960 * $xm, 540 * $ym, 760 * $xm, 780 * $ym] });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->polygon({ 'coordinates' => [1270 * $xm, 570 * $ym, 970 * $xm, 170 * $ym, 600 * $xm, 500 * $ym] });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => 500 * $xm, 'y' => 320 * $ym, 'radius' => 100 * $xm });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });

        $F->fill({ 'x' => int(350 * $xm), 'y' => int(250 * $ym), 'texture' => $image });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->fill({ 'x' => 960 * $xm, 'y' => 440 * $ym });
    } else {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->polygon({ 'coordinates' => [$center_x, 3, 3, $YY - 3, $center_x, $center_y, $XX - 3, $YY - 4] });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->fill({ 'x' => 3, 'y' => 3 });
    }
    sleep $delay if ($F->acceleration());
}

sub color_replace {
    my $name    = shift;
    my $clipped = shift;
	print_it($F, $name);

    my $x = $F->{'XRES'} / 4;
    my $y = $F->{'YRES'} / 4;

    $F->attribute_reset();
    $F->blit_write($DORKSMILE);
    $F->clip_set({ 'x' => $x, 'y' => $y, 'xx' => $x * 3, 'yy' => $y * 3 }) if ($clipped);
    my $s = time + $delay;
    while (time < $s) {
        my $pixel = $F->pixel({ 'x' => $XX / 2, 'y' => $YY / 2 });
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
                    'alpha' => $a
                },
                'new' => {
                    'red'   => $R,
                    'green' => $G,
                    'blue'  => $B,
                    'alpha' => $A
                }
            }
        );
    }
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
    my $y = 0;
    $image->{'x'} = $x;
    $image->{'y'} = $y;
    $F->blit_write($image);
    my $s = time + $delay;

    while (time < $s) {
        $image = $F->blit_move({ %{$image}, 'x_dest' => abs($x), 'y_dest' => int(abs($y)) });
        $x++;
        $y = $y + .5;
		sleep .016666666667;
#        $F->vsync();
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
#            $F->vsync();
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
    sleep $delay;
}

sub animated {
    my $name = shift;
	print_it($F, $name . ' -> Loading...');
	$F->{'DIAGNOSTICS'} = TRUE;

    opendir(my $DIR, $images_path);
    chomp(my @list = readdir($DIR));
    closedir($DIR);
    my $image;
    @list = shuffle(@list);
    foreach my $info (@list) {
        next unless ($info =~ /\.gif$/i);
        for my $count (0 .. 1) {
            my $new_name = ($count) ? "$name Fullscreen" : "$name Native";
            if ($count || $XX <= 320) {
                print_it($F, "Loading Animated Image '$info' Scaled to Full Screen", 'FFFF00FF', { 'red' => 0, 'green' => 0, 'blue' => 255, 'alpha' => 255 });
                print STDERR "\n";
                $image = $F->load_image(
                    {
                        'width'  => $XX,
                        'height' => $YY - $F->{'Y_CLIP'},
                        'file'   => "$images_path/$info",
                        'center' => CENTER_XY
                    }
                );
            } else {
                print_it($F, "Loading Animated Image '$info' Native Size", 'FFFF00FF', { 'red' => 0, 'green' => 0, 'blue' => 255, 'alpha' => 255 });
                print STDERR "\n";
                $image = $F->load_image(
                    {
                        'file'   => "$images_path/$info",
                        'center' => CENTER_XY
                    }
                );
            }
			my $bench = 0;
#            foreach my $bench (0 .. 1) {
                if ($count || $XX <= 320) {
                    print_it($F,
						$bench ? "Loading Animated Image of '$info' Fullscreen" : $new_name, # "Playing Animated Image of '$info' Fullscreen",
						$bench ? '0066FFFF' : 'FF00FFFF',
						$bench ? { 'red' => 0, 'green' => 64, 'blue' => 0, 'alpha' => 255 } : undef);
                } else {
                    print_it($F,
						$bench ? "Loading Animated Image of '$info' Native Size" : $new_name, # "Playing Animated Image of '$info' Native Size",
						$bench ? '0066FFFF' : 'FF00FFFF',
						$bench ? { 'red' => 0, 'green' => 64, 'blue' => 0, 'alpha' => 255 } : undef);
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

                            my $delay = (($image->[$frame]->{'tags'}->{'gif_delay'} * .01)) - (time - $begin);
                            if ($delay > 0 && !$bench) {
                                sleep $delay;
                            }
                        }
                    }
                }
#            }
            last if ($XX <= 320);
        }
    }
}

sub mode_drawing {
    my $mode = shift;
    if ($mode == MASK_MODE) {
        mask_drawing();
    } elsif ($mode == UNMASK_MODE) {
        unmask_drawing();
    } elsif ($mode == ALPHA_MODE) {
        alpha_drawing();
    } else {
        my @modes = qw( NORMAL XOR OR AND MASK UNMASK ALPHA ADD SUBTRACT MULTIPLY DIVIDE );
        print_it($F, "Testing $modes[$mode] Drawing Mode");
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

        sleep 1;

        $F->{'DRAW_MODE'} = $mode;
        $F->blit_write($image2);

        my $size = int(($YY - $F->{'Y_CLIP'}) / 3);
        my $mid  = int($XX / 2);

        $F->set_color({ 'red' => 255, 'green' => 0, 'blue' => 0 });
        $F->circle({ 'x' => $mid - ($size / 2), 'y' => $F->{'Y_CLIP'} + $size * 2, 'radius' => $size, 'filled' => 1 });

        $F->set_color({ 'red' => 0, 'green' => 255, 'blue' => 0 });
        $F->circle({ 'x' => $mid, 'y' => $F->{'Y_CLIP'} + $size, 'radius' => $size, 'filled' => 1 });

        $F->set_color({ 'red' => 0, 'green' => 0, 'blue' => 255 });
        $F->circle({ 'x' => $mid + ($size / 2), 'y' => $F->{'Y_CLIP'} + $size * 2, 'radius' => $size, 'filled' => 1 });

        if ($mode == XOR_MODE) {
            sleep 1;
            $F->circle({ 'x' => $mid + ($size / 2), 'y' => $F->{'Y_CLIP'} + $size * 2, 'radius' => $size, 'filled' => 1 });

            $F->set_color({ 'red' => 0, 'green' => 255, 'blue' => 0 });
            $F->circle({ 'x' => $mid, 'y' => $F->{'Y_CLIP'} + $size, 'radius' => $size, 'filled' => 1 });

            $F->set_color({ 'red' => 255, 'green' => 0, 'blue' => 0 });
            $F->circle({ 'x' => $mid - ($size / 2), 'y' => $F->{'Y_CLIP'} + $size * 2, 'radius' => $size, 'filled' => 1 });

            $F->blit_write($image2);

        } ## end if ($mode == XOR_MODE)
        sleep $delay;
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

    sleep 2;

    $F->alpha_mode();
    $F->blit_write($image2);

    sleep 2;

    $F->set_color({ 'red' => 0, 'green' => 255, 'blue' => 255, 'alpha' => int(rand(256)) });
    $F->rbox({ 'x' => 0, 'y' => 0, 'width' => ($XX / 2), 'height' => ($YY / 2), 'filled' => 1 });

    $F->set_color({ 'red' => 255, 'green' => 0, 'blue' => 255, 'alpha' => int(rand(256)) });
    $F->rbox({ 'x' => $XX / 4, 'y' => $YY / 4, 'width' => ($XX / 2), 'height' => ($YY / 2), 'filled' => 1 });

    $F->set_color({ 'red' => 255, 'green' => 255, 'blue' => 0, 'alpha' => int(rand(256)) });
    $F->rbox({ 'x' => ($XX / 2), 'y' => ($YY / 2), 'width' => ($XX / 2), 'height' => ($YY / 2), 'filled' => 1 });

    sleep $delay;
} ## end sub alpha_drawing

sub mask_drawing {
	my $name = shift;
    $F->attribute_reset();
	print_it($F, $name);

    $F->set_b_color({ 'red' => 0, 'green' => 0, 'blue' => 0, 'alpha' => 0 });
    my $h = int($YY - $F->{'Y_CLIP'});
    my $image1;
    my $image2 = $IMAGES[$BW];
    do {
        $image1 = $IMAGES[int(rand(scalar(@IMAGES)))];
    } until ($image2->{'image'} ne $image1->{'image'});
    $F->normal_mode();
    $F->blit_write($image1);
    $F->mask_mode();

    sleep .3;
    $F->blit_write($image2);

    sleep $delay;
} ## end sub mask_drawing

sub unmask_drawing {
	my $name = shift;
    $F->attribute_reset();
	print_it($F, $name . ' (draw under)');

    $F->set_b_color({ 'red' => 0, 'green' => 0, 'blue' => 0, 'alpha' => 0 });
    my $h = int($YY - $F->{'Y_CLIP'});
    my $image2;
    my $image1 = $IMAGES[$BW];
    do {
        $image2 = $IMAGES[int(rand(scalar(@IMAGES)))];
    } until ($image2->{'image'} ne $image1->{'image'});
    $F->normal_mode();
    $F->blit_write($image1);
    $F->unmask_mode();

    sleep .3;
    $F->blit_write($image2);

    sleep $delay;
} ## end sub unmask_drawing

sub print_it {
    my $fb      = shift;
    my $message = shift;
    my $color   = shift || 'FFFF00FF';
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
        $fb->clip_set({ 'x' => 0, 'y' => 0, 'yy' => $b->{'pheight'} * .75, 'xx' => $XX });
        $fb->cls();
        $fb->ttf_print($b);
        $fb->clip_set({ 'x' => 0, 'y' => $b->{'pheight'} * .75, 'xx' => $XX, 'yy' => $YY });

        #        $center_y = (($YY - $b->{'pheight'}) / 2) + $b->{'pheight'};
        #        $fb->normal_mode();
    } else {
        print STDERR "$message\n";
    }
    $fb->_flush_screen();
	$fb->acceleration($acc);
} ## end sub print_it

__END__

=head1 NAME

Primitives Demonstration and Testing

=head1 DESCRIPTION

This script demonstrates the capabilities of the Graphics::Framebuffer module

=head1 SYNOPSIS

 perl primitives.pl [--dev=device number] [--x=X emulated resolution] [--y=Y emulated resolution] [--pixel=pixel size] [--noaccel]

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

=back

=head1 NOTES

Any benchmarking numbers are written to STDERR.  Animations have benchmarking.

Place any other animated GIFs in the C<"examples/images/"> directory and it will include it in the testing

=head1 AUTHOR

Richard Kelsch <rich@rk-internet.com>

=head1 COPYRIGHT

Copyright 2003-2025 Richard Kelsch
All Rights Reserved

=head1 LICENSE

GNU Public License Version 3.0

* See the "LICENSE" file in the distribution for this license.

This program must always be included as part of the Graphics::Framebuffer package.
