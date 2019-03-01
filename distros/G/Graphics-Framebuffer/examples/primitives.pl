#!/usr/bin/perl

##############################################################################
# This script shows you how each graphics primitive and operation works.  It #
# has not been optimized on purpose, so you can see how each is written.     #
##############################################################################

use strict;

use Graphics::Framebuffer;
use List::Util qw(min max shuffle);
use Time::HiRes qw(sleep time alarm);
use Getopt::Long;

# use Data::Dumper::Simple; $Data::Dumper::Sortkeys=1;

our $F;
our $FR;

my $new_x;
my $new_y;
my $dev      = 0;
my $psize    = 1;
my $noaccel  = 0;
my $nosplash = 0;
my $delay    = 5;

GetOptions(
    'x=i'      => \$new_x,
    'y=i'      => \$new_y,
    'dev=i'    => \$dev,
    'pixel=i'  => \$psize,
    'noaccel'  => \$noaccel,
    'nosplash' => \$nosplash,
    'delay=i'  => \$delay,
);

$noaccel = ($noaccel) ? 1 : 0;    # Only 1 or 0 please

my $images_path = (-e 'images/RWBY_White.jpg') ? 'images' : 'examples/images';

my $splash = ($nosplash) ? 0 : 2;
print "\n\nGathering images...\n";
$|=1;
opendir(my $DIR, $images_path);
chomp(my @files = readdir($DIR));
closedir($DIR);

our @IMAGES;
our @SMALL_IMAGES;
our $STAMP = sprintf('%.1', time);

if (defined($new_x)) {
    $F = Graphics::Framebuffer->new('FB_DEVICE' => "/dev/fb$dev", 'SHOW_ERRORS' => 0, 'SIMULATED_X' => $new_x, 'SIMULATED_Y' => $new_y, 'ACCELERATED' => !$noaccel, 'SPLASH' => 0, 'RESET' => TRUE);
} else {
    $F = Graphics::Framebuffer->new('FB_DEVICE' => "/dev/fb$dev", 'SHOW_ERRORS' => 0, 'ACCELERATED' => !$noaccel, 'SPLASH' => 0, 'RESET' => TRUE);
}
$SIG{'QUIT'} = $SIG{'INT'} = $SIG{'KILL'} = sub { exec('reset'); };

my $sinfo = $F->screen_dimensions();
$F->cls('OFF');

my $screen_width  = $sinfo->{'width'};
my $screen_height = $sinfo->{'height'};

# Everything is based on a 1920x1080 screen, but different resolutions
# are mathematically scaled.
my $xm       = $screen_width / 1920;
my $ym       = $screen_height / 1080;
my $XX       = $screen_width;
my $YY       = $screen_height;
my $center_x = $F->{'X_CLIP'} + ($F->{'W_CLIP'} / 2);
my $center_y = $F->{'Y_CLIP'} + ($F->{'H_CLIP'} / 2);
my $rpi      = ($FR->{'fscreeninfo'}->{'id'} =~ /BCM270(8|9)/i) ? TRUE : FALSE;

$delay *= 3 if ($rpi);    # Raspberry PI is sloooooow.  Let's give extra time for each test
my $BW = 0;
if ($rpi) {
    print "Putting tennis balls on the walker, because this is a Raspberry PI\n";
    sleep 3;
}
my $ALARM = ($rpi) ? 1 / 7.5 : 1 / 30;    # Set double buffering flip timeout.  Raspberry PI has less FPS
my $thread;

print_it($F, ' ', '00FFFFFF');
$F->{'SPLASH'} = $splash;
$F->splash($VERSION) unless ($nosplash);

my $benchmark;

my $DORKSMILE;

$benchmark->{'Image Load'} = time;
foreach my $file (@files) {
    next if ($file =~ /^\.+/ || $file =~ /Test|gif/ || -d "$images_path/$file");
    print_it($F, "Loading Images > $file", '00FFFFFF', undef, 1);
    my $image = $F->load_image(
        {
            'x'            => 1,
            'y'            => 1,
            'width'        => $XX,
            'height'       => $F->{'H_CLIP'},
            'file'         => "$images_path/$file",
            'convertalpha' => ($file =~ /wolf|Crescent/i) ? 1 : 0,
            'center'       => CENTER_XY,
        }
    );
    unless ($file =~ /Solid/i) {
        push(@IMAGES, $image) if (defined($image));
        $image = $F->load_image(
            {
                'x'            => 0,
                'y'            => 0,
                'width'        => $XX * .5,
                'height'       => $F->{'H_CLIP'} * .5,
                'file'         => "$images_path/$file",
                'convertalpha' => ($file =~ /wolf|Crescent/i) ? 1 : 0,
                'center'       => CENTER_XY,
            }
        );
        push(@SMALL_IMAGES, $image) if (defined($image));
        $BW = scalar(@IMAGES) - 1 if ($file =~ /wolf/i);
    } else {
        $DORKSMILE = $image;
    }

} ## end foreach my $file (@files)
$benchmark->{'Image Load'} = time - $benchmark->{'Image Load'};
$F->cls('OFF');
# if (0) { # This line only used for debugging
color_mapping();
plotting();
foreach my $flag (0 .. 1) {
    lines($flag);
    angle_lines($flag);
    polygons($flag);
}
boxes();
rounded_boxes();
circles();
ellipses();
arcs();
poly_arcs();
beziers();

filled_boxes();
filled_rounded_boxes();
filled_circles();
filled_ellipses();
filled_pies();
filled_polygons();

hatch_filled_boxes();
hatch_filled_rounded_boxes();
hatch_filled_circles();
hatch_filled_ellipses();
hatch_filled_pies();
hatch_filled_polygons();

foreach my $d (qw(vertical horizontal)) {
    gradient_boxes($d);
    gradient_rounded_boxes($d);
    gradient_circles($d);
    gradient_ellipses($d);
    gradient_pies($d);
    gradient_polygons($d);
} ## end foreach my $d (qw(vertical horizontal))

texture_filled_boxes();
texture_filled_rounded_boxes();
texture_filled_circles();
texture_filled_ellipses();
texture_filled_pies();
texture_filled_polygons();

flood_fill();

truetype_fonts();
truetype_printing();

# rotate_truetype_fonts();

foreach my $flag (0 .. 1) {
    color_replace($flag);
}

blitting();
blit_move();
rotate();

# flipping();
monochrome();

foreach my $m (1 .. 8) {    # We skip divide mode because it's stupid and I should never have added it
    if ($m == MASK_MODE) {
        mask_drawing();
    } elsif ($m == UNMASK_MODE) {
        unmask_drawing();
    } elsif ($m == ALPHA_MODE) {
        alpha_drawing();
    } else {
        mode_drawing($m);
    }
} ## end foreach my $m (1 .. 9)
animated();

$F->clip_reset();
$F->attribute_reset();
$F->cls('ON');
my $size = 0;
foreach my $count (1 .. 2) {
    foreach my $name (keys %{$benchmark}) {
        if ($count == 2) {
            if ($name =~ /flood/i) {
                print STDOUT sprintf('%' . $size . 's = %s', $name, $benchmark->{$name}), "\n";
            } elsif ($name =~ /Image Load/i) {
                print STDOUT sprintf('%' . $size . 's = %.02f seconds', $name, $benchmark->{$name}), "\n";
            } else {
                print STDOUT sprintf('%' . $size . 's = %.02f per second', $name, ($benchmark->{$name} / $delay)), "\n";
            }
        } else {
            $size = length($name) if (length($name) > $size);
        }
    } ## end foreach my $name (keys %{$benchmark...})
} ## end foreach my $count (1 .. 2)

exit(0);

sub color_mapping {

    print_it($F, 'Color Mapping Test -> Red-Green-Blue');
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
            'file'   => "$images_path/Test_Pattern.jpg"
        }
    );
    $F->blit_write($image);

    sleep $delay;
} ## end sub color_mapping

sub plotting {
    $benchmark->{'Plotting'} = 0;
    print_it($F, 'Plotting Test');

    my $s = time + $delay;
    while (time < $s) {
        my $x = int(rand($screen_width));
        my $y = int(rand($screen_height));
        $F->set_color({ 'alpha' => 255, 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->plot({ 'x' => $x, 'y' => $y, 'pixel_size' => $psize });
        $benchmark->{'Plotting'}++;
    } ## end while (time < $s)
} ## end sub plotting

sub lines {
    my $aa = shift;

    if ($aa) {
        print_it($F, 'Antialiased Line Test');
        $benchmark->{'Antialiased Lines'} = 0;
    } else {
        print_it($F, 'Line Test');
        $benchmark->{'Lines'} = 0;
    }
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->line({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'antialiased' => $aa, 'pixel_size' => $psize });
        if ($aa) {
            $benchmark->{'Antialiased Lines'}++;
        } else {
            $benchmark->{'Lines'}++;
        }
    } ## end while (time < $s)
} ## end sub lines

sub angle_lines {
    my $aa = shift;

    if ($aa) {
        print_it($F, 'Antialiased Angle Line Test');
        $benchmark->{'Antialiased Angle Lines'} = 0;
    } else {
        print_it($F, 'Angle Line Test');
        $benchmark->{'Angle Lines'} = 0;
    }

    my $s     = time + $delay;
    my $angle = 0;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->angle_line({ 'x' => $center_x, 'y' => $center_y, 'radius' => int($F->{'H_CLIP'} / 2), 'angle' => $angle, 'antialiased' => $aa, 'pixel_size' => $psize });
        $angle += 7;
        $angle -= 360 if ($angle >= 360);
        if ($aa) {
            $benchmark->{'Antialiased Angle Lines'}++;
        } else {
            $benchmark->{'Angle Lines'}++;
        }
    } ## end while (time < $s)
} ## end sub angle_lines

sub boxes {

    print_it($F, 'Box Test');
    $benchmark->{'Boxes'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'pixel_size' => $psize });

        $benchmark->{'Boxes'}++;
    } ## end while (time < $s)
} ## end sub boxes

sub filled_boxes {
    print_it($F, 'Filled Box Test');
    $benchmark->{'Filled Boxes'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'filled' => 1 });

        $F->vsync();
        $benchmark->{'Filled Boxes'}++;
    } ## end while (time < $s)
} ## end sub filled_boxes

sub gradient_boxes {
    my $direction = shift;
    print_it($F, ucfirst($direction) . ' Gradient Box Test');
    $benchmark->{ 'Gradient Boxes ' . ucfirst($direction) } = 0;
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

        $benchmark->{ 'Gradient Boxes ' . ucfirst($direction) }++;
    } ## end while (time < $s)
} ## end sub gradient_boxes

sub hatch_filled_boxes {
    print_it($F, 'Hatch Filled Box Test');
    $benchmark->{'Hatch Filled Boxes'} = 0;
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

        $benchmark->{'Hatch Filled Boxes'}++;
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_boxes

sub texture_filled_boxes {
    print_it($F, 'Texture Filled Box Test');
    $benchmark->{'Texture Filled Boxes'} = 0;
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

        $benchmark->{'Texture Filled Boxes'}++;
    } ## end while (time < $s)
} ## end sub texture_filled_boxes

sub rounded_boxes {
    print_it($F, 'Rounded Box Test');
    $benchmark->{'Rounded Boxes'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'pixel_size' => $psize });

        $benchmark->{'Rounded Boxes'}++;
    } ## end while (time < $s)
} ## end sub rounded_boxes

sub filled_rounded_boxes {
    print_it($F, 'Filled Rounded Box Test');
    $benchmark->{'Filled Rounded Boxes'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'filled' => 1 });

        $benchmark->{'Filled Rounded Boxes'}++;
    } ## end while (time < $s)
} ## end sub filled_rounded_boxes

sub hatch_filled_rounded_boxes {
    print_it($F, 'Hatch Filled Rounded Box Test');
    $benchmark->{'Hatch Filled Rounded Boxes'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });

        $benchmark->{'Hatch Filled Rounded Boxes'}++;
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_rounded_boxes

sub gradient_rounded_boxes {
    my $direction = shift;
    print_it($F, ucfirst($direction) . ' Gradient Rounded Box Test');
    $benchmark->{ 'Gradient Filled Rounded Boxes ' . ucfirst($direction) } = 0;
    my $s = time + $delay;
    while (time < $s) {

        #        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
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

        $benchmark->{ 'Gradient Filled Rounded Boxes ' . ucfirst($direction) }++;
    } ## end while (time < $s)
} ## end sub gradient_rounded_boxes

sub texture_filled_rounded_boxes {
    print_it($F, 'Texture Filled Rounded Box Test');
    $benchmark->{'Texture Filled Rounded Boxes'} = 0;
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

        $benchmark->{'Texture Filled Rounded Boxes'}++;
    } ## end while (time < $s)
} ## end sub texture_filled_rounded_boxes

sub circles {
    print_it($F, 'Circle Test');
    $benchmark->{'Circles'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'pixel_size' => $psize });

        $benchmark->{'Circles'}++;
    } ## end while (time < $s)
} ## end sub circles

sub filled_circles {
    print_it($F, 'Filled Circle Test');
    $benchmark->{'Filled Circles'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'filled' => 1 });

        $benchmark->{'Filled Circles'}++;
    } ## end while (time < $s)
} ## end sub filled_circles

sub hatch_filled_circles {
    print_it($F, 'Hatch Filled Circle Test');
    $benchmark->{'Hatch Filled Circles'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });

        $benchmark->{'Hatch Filled Circles'}++;
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_circles

sub gradient_circles {
    my $direction = shift;
    print_it($F, ucfirst($direction) . ' Gradient Circle Test');
    $benchmark->{ 'Gradient Filled Circles ' . ucfirst($direction) } = 0;
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

        $benchmark->{ 'Gradient Filled Circles ' . ucfirst($direction) }++;
    } ## end while (time < $s)
} ## end sub gradient_circles

sub texture_filled_circles {
    print_it($F, 'Texture Filled Circle Test');
    $benchmark->{'Texture Filled Circles'} = 0;
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

        $benchmark->{'Texture Filled Circles'}++;
    } ## end while (time < $s)
} ## end sub texture_filled_circles

sub arcs {
    print_it($F, 'Arc Test');
    $benchmark->{'Arcs'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->arc({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'pixel_size' => $psize });

        $benchmark->{'Arcs'}++;
    } ## end while (time < $s)
} ## end sub arcs

sub poly_arcs {
    print_it($F, 'Poly Arc Test');
    $benchmark->{'Poly Arcs'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->poly_arc({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'pixel_size' => $psize });

        $benchmark->{'Poly Arcs'}++;
    } ## end while (time < $s)
} ## end sub poly_arcs

sub filled_pies {
    print_it($F, 'Filled Pie Test');
    $benchmark->{'Filled Pies'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->filled_pie({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360) });

        $benchmark->{'Filled Pies'}++;
    } ## end while (time < $s)
} ## end sub filled_pies

sub hatch_filled_pies {
    print_it($F, 'Hatch Filled Pie Test');
    $benchmark->{'Hatch Filled Pies'} = 0;
    my $s = time + ($delay * 2);
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->filled_pie({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });

        $benchmark->{'Hatch Filled Pies'}++;
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_pies

sub gradient_pies {
    my $direction = shift;
    print_it($F, ucfirst($direction) . ' Gradient Filled Pie Test');
    $benchmark->{ 'Gradient Filled Pies ' . ucfirst($direction) } = 0;
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

        $benchmark->{ 'Gradient Filled Pies ' . ucfirst($direction) }++;
    } ## end while (time < $s)
} ## end sub gradient_pies

sub texture_filled_pies {
    print_it($F, 'Texture Filled Pie Test');
    $benchmark->{'Texture Filled Pies'} = 0;
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

        $benchmark->{'Texture Filled Pies'}++;
    } ## end while (time < $s)
} ## end sub texture_filled_pies

sub ellipses {
    print_it($F, 'Ellipse Test');
    $benchmark->{'Ellipses'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'pixel_size' => $psize });

        $benchmark->{'Ellipses'}++;
    } ## end while (time < $s)
} ## end sub ellipses

sub filled_ellipses {
    print_it($F, 'Filled Ellipse Test');
    $benchmark->{'Filled Ellipses'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)), 'alpha' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'filled' => 1 });

        $benchmark->{'Filled Ellipses'}++;
    } ## end while (time < $s)
} ## end sub filled_ellipses

sub hatch_filled_ellipses {
    print_it($F, 'Hatch Filled Ellipse Test');
    $benchmark->{'Hatch Filled Ellipses'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });

        $benchmark->{'Hatch Filled Ellipses'}++;
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_ellipses

sub gradient_ellipses {
    my $direction = shift;
    print_it($F, ucfirst($direction) . ' Gradient Ellipse Test');
    $benchmark->{ 'Gradient Filled Ellipses ' . ucfirst($direction) } = 0;
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

        $benchmark->{ 'Gradient Filled Ellipses ' . ucfirst($direction) }++;
    } ## end while (time < $s)
} ## end sub gradient_ellipses

sub texture_filled_ellipses {
    print_it($F, 'Texture Filled Ellipse Test');
    $benchmark->{'Texture Filled Ellipses'} = 0;
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

        $benchmark->{'Texture Filled Ellipses'}++;
    } ## end while (time < $s)
} ## end sub texture_filled_ellipses

sub polygons {
    my $aa = shift;
    if ($aa) {
        print_it($F, 'Antialiased Polygon Test');
        $benchmark->{'Antialiased Polygons'} = 0;
    } else {
        print_it($F, 'Polygon Test');
        $benchmark->{'Polygons'} = 0;
    }

    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my $points = 3;
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

        if ($aa) {
            $benchmark->{'Antialiased Polygons'}++;
        } else {
            $benchmark->{'Polygons'}++;
        }
    } ## end while (time < $s)
} ## end sub polygons

sub filled_polygons {
    print_it($F, 'Filled Polygon Test');
    $benchmark->{'Filled Polygons'} = 0;
    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my $points = 3;
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

        $benchmark->{'Filled Polygons'}++;
    } ## end while (time < $s)
} ## end sub filled_polygons

sub hatch_filled_polygons {
    print_it($F, 'Hatch Filled Polygon Test');
    $benchmark->{'Hatch Filled Polygons'} = 0;
    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my $points = 3;
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

        $benchmark->{'Hatch Filled Polygons'}++;
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_polygons

sub gradient_polygons {
    my $direction = shift;
    print_it($F, ucfirst($direction) . ' Gradient Polygon Test');
    $benchmark->{ 'Gradient Polygons ' . ucfirst($direction) } = 0;
    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s) {
        my $count  = int(rand(10)) + 2;
        my @red    = map { $_ = int(rand(256)) } (1 .. $count);
        my @green  = map { $_ = int(rand(256)) } (1 .. $count);
        my @blue   = map { $_ = int(rand(256)) } (1 .. $count);
        my $points = 3;
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

        $benchmark->{ 'Gradient Polygons ' . ucfirst($direction) }++;
    } ## end while (time < $s)
} ## end sub gradient_polygons

sub texture_filled_polygons {
    print_it($F, 'Texture Filled Polygon Test');
    $benchmark->{'Texture Filled Polygons'} = 0;
    $F->mask_mode() if ($F->acceleration());

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s) {
        my $image  = $IMAGES[int(rand(scalar(@IMAGES)))];
        my $points = 3;
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

        $benchmark->{'Texture Filled Polygons'}++;
    } ## end while (time < $s)
} ## end sub texture_filled_polygons

sub beziers {
    print_it($F, 'Testing Bezier Curves');
    $benchmark->{'Bezier Curves'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my @coords = ();
        foreach my $c (1 .. int(rand(20))) {
            push(@coords, int(rand($XX)), int(rand($YY)));
        }
        $F->bezier({ 'coordinates' => \@coords, 'points' => 100, 'pixel_size' => $psize });

        $benchmark->{'Bezier Curves'}++;
    } ## end while (time < $s)
} ## end sub beziers

sub truetype_fonts {
    print_it($F, 'Testing TrueType Font Rendering (random height/width)');
    $benchmark->{'TrueType Fonts'} = 0;
    my @fonts = (keys %{ $F->{'FONTS'} });
    my $g     = time + $delay;
    while (time < $g) {
        my $x    = int(rand(600 * $xm));
        my $y    = int(rand(1080 * $ym));
        my $h    = ($YY <= 240 || $F->{'BITS'} == 16) ? (6 + rand(60)) : (8 + int(rand(300 * $ym)));
        my $ws   = ($XX <= 320 || $F->{'BITS'} == 16) ? rand(2) : rand(4);
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

        $benchmark->{'TrueType Fonts'}++;
    } ## end while (time < $g)
} ## end sub truetype_fonts

sub truetype_printing {
    print_it($F,'Testing TrueType Font Word Wrapping');
    $benchmark->{'TrueType Wrapping'} = time;
    $F->ttf_paragraph(
        {
            'x'       => 0,
            'y'       => 30,
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 150,
            'justify' => 'justified',
            'size'    => int($YY/75),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );
    $benchmark->{'TrueType Wrapping'} = time - $benchmark->{'TrueType Wrapping'};
    sleep $delay;
    $F->clip_set(
        {
            'x'       => $XX / 4,
            'y'       => $YY / 3,
            'xx'      => (3 * ($XX /4)),
            'yy'      => (2 * ($YY / 3)),
        }
    );
    $F->ttf_paragraph(
        {
            'x'       => $XX / 4,
            'y'       => ($YY / 4) + 30,
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 20,
            'justify' => 'justified',
            'size'    => int($YY/75),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );
    $F->clip_reset();
    sleep $delay;
}

sub rotate_truetype_fonts {
    print_it($F, 'Testing TrueType Font Rotation Rendering');
    $benchmark->{'TrueType Fonts Rotated'} = 0;
    my $g     = time + $delay * 3;
    my $angle = 0;
    my $x     = $XX / 2;
    my $y     = $YY / 2;
    my $h     = ($YY <= 240 || $F->{'BITS'} == 16) ? 12 * $ym : 60 * $ym;
    my $ws    = 1;
    while (time < $g) {
        my $b = $F->ttf_print(
            {
                'x'      => $x - $h,
                'y'      => $y - $h,
                'height' => $h,
                'wscale' => $ws,
                'color'  => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
                'text'   => "$angle degrees",
                'rotate' => $angle,

                #                'font_path'    => $F->{'FONTS'}->{$font}->{'path'},
                #                'face'         => $F->{'FONTS'}->{$font}->{'font'},
                'bounding_box' => 1,
                'center'       => CENTER_XY,
            }
        );
        if (defined($b)) {
            $F->cls();
            $F->ttf_print($b);
        }
        $angle++;
        $angle = 0 if ($angle >= 360);

        $benchmark->{'TrueType Fonts Rotated'}++;
    } ## end while (time < $g)
} ## end sub rotate_truetype_fonts

sub flood_fill {
    print_it($F, 'Testing flood fill');
    $F->clip_reset();
    $benchmark->{'Flood Fill'} = time;
    if ($XX > 255) { # && !$rpi) {
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
    } ## end else [ if ($XX > 255 && !$rpi)]
    $benchmark->{'Flood Fill'} = sprintf('%.02f Seconds', (time - $benchmark->{'Flood Fill'}));
    sleep $delay if ($F->acceleration());
} ## end sub flood_fill

sub color_replace {
    my $clipped = shift;
    if ($clipped) {
        print_it($F, 'Testing Color Replace (clipping on)');
        $benchmark->{'Color Replace'} = 0;
    } else {
        print_it($F, 'Testing Color Replace (clipping off)');
        $benchmark->{'Color Replace Clipping'} = 0;
    }

    my $x = $F->{'XRES'} / 4;
    my $y = $F->{'YRES'} / 4;

    $F->blit_write($DORKSMILE);
    $F->clip_set({ 'x' => $x, 'y' => $y, 'xx' => $x * 3, 'yy' => $y * 3 }) if ($clipped);
    my $r = 193;
    my $g = 177;
    my $b = 164;
    my $s = time + $delay;
    while (time < $s) {
        my $R = int(rand(256));
        my $G = int(rand(256));
        my $B = int(rand(256));
        $F->replace_color(
            {
                'old' => {
                    'red'   => $r,
                    'green' => $g,
                    'blue'  => $b
                },
                'new' => {
                    'red'   => $R,
                    'green' => $G,
                    'blue'  => $B
                }
            }
        );
        ($r, $g, $b) = ($R, $G, $B);

        if ($clipped) {
            $benchmark->{'Color Replace Clipping'}++;
        } else {
            $benchmark->{'Color Replace'}++;
        }
    } ## end while (time < $s)
} ## end sub color_replace

sub blitting {
    print_it($F, 'Testing Image blitting');
    $benchmark->{'Image Blitting'} = 0;
    my $s = time + $delay;
    while (time < $s) {
        my $image = $SMALL_IMAGES[int(rand(scalar(@IMAGES)))];

        $image->{'x'} = abs(rand($XX - $image->{'width'}));
        $image->{'y'} = $F->{'Y_CLIP'} + abs(rand(($YY - $F->{'Y_CLIP'}) - $image->{'height'}));
        $F->blit_write($image);

        $benchmark->{'Image Blitting'}++;
    } ## end while (time < $s)
} ## end sub blitting

sub blit_move {
    print_it($F, 'Testing Image Moving');
    $benchmark->{'Image Moving'} = 0;
    $F->attribute_reset();
    my $image = $SMALL_IMAGES[int(rand(scalar(@IMAGES)))];
    $F->blit_write({ %{$image}, 'x' => 10, 'y' => 10 });
    my $x = 10;
    my $y = 10;
    my $w = $image->{'width'};
    my $h = $image->{'height'};
    my $s = time + $delay;
    while (time < $s) {
        $F->blit_move({ 'x' => abs($x), 'y' => abs($y), 'width' => $w, 'height' => $h, 'x_dest' => abs($x) + 4, 'y_dest' => abs($y) + 2 });
        $x += 4;
        $y += 2;

        $benchmark->{'Image Moving'}++;
    } ## end while (time < $s)
} ## end sub blit_move

sub rotate {
    print_it($F, 'Scaling image for Rotate Test', 'FFFF00FF');

    my $image = { %{ $SMALL_IMAGES[int(rand(scalar(@IMAGES)))] } };
    foreach my $p (0 .. 1) {
        my $angle = 0;

        my $st = 'Counter-Clockwise Rotate Test ';
        unless ($p) {
            $st .= 'Using Standard Quality Setting';
            $benchmark->{'Counter Clockwise Rotate Image Standard'} = 0;
        } else {
            $st .= 'Using High Quality Setting';
            $benchmark->{'Counter Clockwise Rotate Image High Quality'} = 0;
        }
        print_it($F, $st);
        my $s     = time + $delay;
        my $count = 0;

        while (time < $s || $count < 6) {
            my $rot = $F->blit_transform(
                {
                    'rotate' => {
                        'degrees' => $angle,
                        'quality' => ($p) ? 'high' : 'quick',
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

            unless ($p) {
                $benchmark->{'Counter Clockwise Rotate Image Standard'}++;
            } else {
                $benchmark->{'Counter Clockwise Rotate Image High Quality'}++;
            }
            $angle += 3;
            $angle = 0 if ($angle >= 360);
            $count++;
        } ## end while (time < $s || $count...)

        $angle = 0;
        $st    = 'Clockwise Rotate Test ';
        unless ($p) {
            $st .= 'Using Standard Quality Setting';
            $benchmark->{'Clockwise Rotate Image Standard'} = 0;
        } else {
            $st .= 'Using High Quality Setting';
            $benchmark->{'Clockwise Rotate Image High Quality'} = 0;
        }
        print_it($F, $st);
        $s     = time + $delay;
        $count = 0;
        while (time < $s || $count < 6) {
            my $rot = $F->blit_transform(
                {
                    'rotate' => {
                        'degrees' => $angle,
                        'quality' => ($p) ? 'high' : 'quick',
                    },
                    'blit_data' => $image,
                    'perl_only' => $p
                }
            );
            $rot = $F->blit_transform(
                {
                    'center'    => CENTER_XY,
                    'blit_data' => $rot,
                }
            );

            $F->blit_write($rot);

            unless ($p) {
                $benchmark->{'Clockwise Rotate Image Standard'}++;
            } else {
                $benchmark->{'Clockwise Rotate Image High Quality'}++;
            }
            $angle -= 3;
            $angle = 0 if ($angle <= -360);
            $count++;

        } ## end while (time < $s || $count...)
        last if ($F->{'BITS'} == 16);
    } ## end foreach my $p (0 .. 1)

} ## end sub rotate

sub flipping {
    my $r     = rand(scalar(@IMAGES));
    my $image = $IMAGES[$r];
    $image->{'image'}          = "$IMAGES[$r]->{'image'}";
    $benchmark->{'Image Flip'} = 0;
    my $s    = time + $delay * 2;
    my $zoom = time + $delay;
    while (time < $s) {
        foreach my $dir (qw(normal horizontal vertical both)) {
            print_it($F, "Testing Image Flip $dir");
            unless ($dir eq 'normal') {
                my $rot = $F->blit_transform(
                    {
                        'flip'      => $dir,
                        'blit_data' => $image
                    }
                );
                $rot->{'image'} = "$rot->{'image'}";
                $rot->{'x'}     = abs(($XX - $rot->{'width'}) / 2);
                $rot->{'y'}     = abs((($YY - $F->{'Y_CLIP'}) - $rot->{'height'}) / 2);
                $F->blit_write($rot);
            } else {
                $r                = rand(scalar(@IMAGES));
                $image            = $IMAGES[$r];
                $image->{'image'} = "$IMAGES[$r]->{'image'}";
                $F->blit_write($image);
            } ## end else

            $benchmark->{'Image Flip'}++;
            sleep .3;
        } ## end foreach my $dir (qw(normal horizontal vertical both))
    } ## end while (time < $s)
} ## end sub flipping

sub monochrome {
    my $image = $SMALL_IMAGES[int(rand(scalar(@IMAGES)))];

    print_it($F, 'Testing Monochrome Image blitting');
    $benchmark->{'Monochrome Image Blitting'} = 0;
    my $mono = { %{$image} };
    $mono->{'image'} = $F->monochrome({ 'image' => $image->{'image'}, 'bits' => $F->{'BITS'} });
    my $s = time + $delay;

    while (time < $s) {
        $mono->{'x'} = abs(rand($XX - $mono->{'width'}));
        $mono->{'y'} = $F->{'Y_CLIP'} + abs(rand(($YY - $F->{'Y_CLIP'}) - $mono->{'height'}));
        $F->blit_write($mono);

        $benchmark->{'Monochrome Image Blitting'}++;
    } ## end while (time < $s)
} ## end sub monochrome

sub animated {
    $F->{'DIAGNOSTICS'} = 1;
    print_it($F, 'Testing Animated Images.  Loading...', 'FFFF00FF');

    opendir(my $DIR, $images_path);
    chomp(my @list = readdir($DIR));
    closedir($DIR);
    my $image;
    @list = shuffle(@list);
    foreach my $info (@list) {
        next unless ($info =~ /\.gif$/i);
        for my $count (0 .. 1) {

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
            } ## end else [ if ($count || $XX <= 320)]

            foreach my $bench (0 .. 1) {
                if ($count || $XX <= 320) {
                    print_it($F, $bench ? "Benchmarking Animated Image of '$info' Fullscreen" : "Playing Animated Image of '$info' Fullscreen", $bench ? '0066FFFF' : 'FF00FFFF', $bench ? { 'red' => 0, 'green' => 64, 'blue' => 0, 'alpha' => 255 } : undef);
                } else {
                    print_it($F, $bench ? "Benchmarking Animated Image of '$info' Native Size" : "Playing Animated Image of '$info' Native Size", $bench ? '0066FFFF' : 'FF00FFFF', $bench ? { 'red' => 0, 'green' => 64, 'blue' => 0, 'alpha' => 255 } : undef);
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
                            $fps++;
                            my $end = time - $start;
                            if ($end >= 1 && $bench) {
                                print STDERR "\r", sprintf('%.03f FPS', (1 / $end) * $fps);
                                $|     = 1;
                                $fps   = 0;
                                $start = time;
                            } ## end if ($end >= 1 && $bench)
                        } ## end foreach my $frame (0 .. (scalar...))
                    } ## end while (time <= $s)
                } ## end if (defined($image))
            } ## end foreach my $bench (0 .. 1)
            last if ($XX <= 320);
        } ## end for my $count (0 .. 1)
    } ## end foreach my $info (@list)
} ## end sub animated

sub mode_drawing {
    my $mode  = shift;
    my @modes = qw( NORMAL XOR OR AND MASK UNMASK ALPHA ADD SUBTRACT MULTIPLY DIVIDE );
    print_it($F, 'Testing "' . $modes[$mode] . '" Drawing Mode');
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
} ## end sub mode_drawing

sub alpha_drawing {

    $F->attribute_reset();
    print_it($F, 'Testing Alpha Drawing Mode');
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

    $F->attribute_reset();
    print_it($F, 'Testing MASK Drawing Mode');

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

    print_it($F, 'Testing UNMASK Drawing Mode');

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

    #    $fb->clip_reset();
    $fb->set_b_color($bgcolor);
    $fb->cls() unless ($noclear);
    unless ($XX <= 320) {

        #        $fb->or_mode();

        my $b = $fb->ttf_print(
            {
                'x'            => 5 * $xm,
                'y'            => max(18, 25 * $ym),
                'height'       => max(9, 20 * $ym),
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

 perl primitives.pl --dev=1 --x=640 --y=480

 perl primitives.pl --x=1280 --y=720 --pixel=2

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

=item B<--pixel>=C<pixel size>

This tells the module to draw with larger pixels (larger means slower)

=item B<--noaccel>

Turns off C acceleration.  Uses only the Perl routines.

=back

=head1 NOTES

Any benchmarking numbers are written to STDERR.  Animations have benchmarking.

Place any other animated GIFs in the C<"examples/images/"> directory and it will include it in the testing

=head1 AUTHOR

Richard Kelsch <rich@rk-internet.com>

=head1 COPYRIGHT

Copyright 2003-2019 Richard Kelsch
All Rights Reserved

=head1 LICENSE

GNU Public License Version 3.0

* See the "LICENSE" file in the distribution for this license.

This program must always be included as part of the Graphics::Framebuffer package.
