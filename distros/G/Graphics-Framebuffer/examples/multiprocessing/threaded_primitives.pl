#!/usr/bin/env perl

##############################################################################
# This script shows you how each graphics primitive and operation works with #
# threads..  It has not been optimized on purpose, so you can see how each   #
# is written.                                                                #
##############################################################################

use strict;

use threads (
    'yield',
    'stringify',
    'stack_size' => 131076,
    'exit' => 'threads_only',
);
use threads::shared;
use Graphics::Framebuffer;
use List::Util qw(min max shuffle);
use Time::HiRes qw(sleep time alarm);
use Getopt::Long;
use Sys::CPU;

# use Data::Dumper::Simple;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

my $dev      = 0;
my $psize    = 1;
my $noaccel  = FALSE;
my $nosplash = FALSE;
our $ignore_x : shared = FALSE;
my $delay    = 3;
my $threads  = Sys::CPU::cpu_count();
$threads    -= 1 if ($threads > 1);

GetOptions(
    'dev=i'    => \$dev,
    'pixel=i'  => \$psize,
    'noaccel'  => \$noaccel,
    'nosplash' => \$nosplash,
    'delay=i'  => \$delay,
	'ignore-x-windows' => \$ignore_x,
);

$noaccel = ($noaccel) ? TRUE : FALSE;    # Only 1 or 0 please

my $images_path;
{
    foreach my $p ('images', '../images', 'examples/images') {
        if (-e "$p/RWBY_White.jpg") {
            $images_path = $p;
            last;
        }
    }
}

my $splash = ($nosplash) ? 0 : 2;
print "\n\nGathering images...\n";
$|=1;

opendir(my $DIR, $images_path);
chomp(my @files = readdir($DIR));
closedir($DIR);

our $RUNNING : shared = TRUE;
our @IMAGES;
our $STAMP = sprintf('%.1', time);

my $F = Graphics::Framebuffer->new('FB_DEVICE' => "/dev/fb$dev", 'SHOW_ERRORS' => 0, 'ACCELERATED' => !$noaccel, 'SPLASH' => 0, 'RESET' => FALSE, 'IGNORE_X_WINDOWS' => $ignore_x);

$SIG{'HUP'} = $SIG{'QUIT'} = $SIG{'INT'} = $SIG{'KILL'} = $SIG{'TERM'} = \&finish;

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
my $rpi      = ($F->{'fscreeninfo'}->{'id'} =~ /BCM270(8|9)/i) ? TRUE : FALSE;

$delay *= 3 if ($rpi);    # Raspberry PI is sloooooow.  Let's give extra time for each test
my $BW = 0;
if ($rpi) {
    print "Putting tennis balls on the walker, because this is a Raspberry PI (or equally slow clone)\n";
    sleep 3;
}

print_it($F, ' ', '00FFFFFF');
$F->{'SPLASH'} = $splash;
$F->splash($Graphics::Framebuffer::VERSION) unless ($nosplash);

my $DORKSMILE;

# Load each image in a thread.  Throttle the number of threads according to the $threads value
foreach my $file (@files) {
    next if ($file =~ /^\.+/ || $file =~ /Test|gif/i || -d "$images_path/$file");
    threads->create(
        \&load_image,
        "$images_path/$file",
        $F
    );
    # Throttle
    while (scalar(threads->list()) >= $threads) {
        foreach my $thd (threads->list(threads::joinable)) {
            my $image = $thd->join();
            push(@IMAGES, $image) if (defined($image));
            last unless($RUNNING);
        }
        threads->yield();
        sleep .01;
        last unless($RUNNING);
    }
    last unless($RUNNING);
}
# Join any remaining threads not joined by the throttle above
while (threads->list(threads::running)) {
    foreach my $tt (threads->list(threads::joinable)) {
        my $image = $tt->join();
        if (defined($image) && $RUNNING) {
            push(@IMAGES, $image);
            $F->vsync();
            $F->blit_write($image);
            $F->vsync();
        }
    }
    threads->yield();
    sleep .01;
}
foreach my $tt (threads->list(threads::joinable)) {
    my $image = $tt->join();
    if (defined($image)) {
        push(@IMAGES, $image);
        $F->vsync();
        $F->blit_write($image);
        $F->vsync();
    }
}
$F->graphics_mode();
$F->cls();

##################################
my %func = (
    'Color Mapping'                     => \&color_mapping,
    'Plotting'                          => \&plotting,
    'Lines'                             => sub { lines(0,@_); },
    'Angle Lines'                       => sub { angle_lines(0,@_); },
    'Polygons'                          => sub { polygons(0,@_); },
    'Antialiased Lines'                 => sub { lines(1,@_); },
    'Antialiased Angle Lines'           => sub { angle_lines(1,@_); },
    'Antialiased Polygons'              => sub { polygons(1,@_); },
    'Boxes'                             => \&boxes,
    'Rounded Boxes'                     => \&rounded_boxes,
    'Circles'                           => \&circles,
    'Ellipses'                          => \&ellipses,
    'Arcs'                              => \&arcs,
    'Poly Arcs'                         => \&poly_arcs,
    'Beziers'                           => \&beziers,
    'Filled Boxes'                      => \&filled_boxes,
    'Filled Rounded Boxes'              => \&filled_rounded_boxes,
    'Filled Circles'                    => \&filled_circles,
    'Filled Ellipses'                   => \&filled_ellipses,
    'Filled Pies'                       => \&filled_pies,
    'Filled Polygons'                   => \&filled_polygons,
    'Hatch Filled Boxes'                => \&hatch_filled_boxes,
    'Hatch Filled Rounded Boxes'        => \&hatch_filled_rounded_boxes,
    'Hatch Filled Circles'              => \&hatch_filled_circles,
    'Hatch Filled Ellipses'             => \&hatch_filled_ellipses,
    'Hatch Filled Pies'                 => \&hatch_filled_pies,
    'Hatch Filled Polygons'             => \&hatch_filled_polygons,
    'Vertical Gradient Boxes'           => sub { gradient_boxes('vertical',@_); },
    'Vertical Gradient Rounded Boxes'   => sub { gradient_rounded_boxes('vertical',@_); },
    'Vertical Gradient Circles'         => sub { gradient_circles('vertical',@_); },
    'Vertical Gradient Ellipses'        => sub { gradient_ellipses('vertical',@_); },
    'Vertical Gradient Pies'            => sub { gradient_pies('vertical',@_); },
    'Vertical Gradient Polygons'        => sub { gradient_polygons('vertical',@_); },
    'Horizontal Gradient Boxes'         => sub { gradient_boxes('horizontal',@_); },
    'Horizontal Gradient Rounded Boxes' => sub { gradient_rounded_boxes('horizontal',@_); },
    'Horizontal Gradient Circles'       => sub { gradient_circles('horizontal',@_); },
    'Horizontal Gradient Ellipses'      => sub { gradient_ellipses('horizontal',@_); },
    'Horizontal Gradient Pies'          => sub { gradient_pies('horizontal',@_); },
    'Horizontal Gradient Polygons'      => sub { gradient_polygons('horizontal',@_); },
    'Texture Filled Boxes'              => \&texture_filled_boxes,
    'Texture Filled Rounded Boxes'      => \&texture_filled_rounded_boxes,
    'Texture Filled Circles'            => \&texture_filled_circles,
    'Texture Filled Ellipses'           => \&texture_filled_ellipses,
    'Texture Filled Pies'               => \&texture_filled_pies,
    'Texture Filled Polygons'           => \&texture_filled_polygons,
    'Flood Fill'                        => \&flood_fill,
    'TrueType Fonts'                    => \&truetype_fonts,
    'TrueType Printing'                 => \&truetype_printing,
    'Rotate TrueType Fonts'             => \&rotate_truetype_fonts,
    'Color Replace None-Clipped'        => sub { color_replace(0,@_); },
    'Color Replace Clipped'             => sub { color_replace(1,@_); },
    'Blitting'                          => \&blitting,
    'Blit Move'                         => \&blit_move,
    'Rotate'                            => \&rotate,
    'Flipping'                          => \&flipping,
    'Monochrome'                        => \&monochrome,
    'XOR Mode Drawing'                  => sub { mode_drawing(1,@_); },
    'OR Mode Drawing'                   => sub { mode_drawing(2,@_); },
    'AND Mode Drawing'                  => sub { mode_drawing(3,@_); },
    'MASK Mode Drawing'                 => sub { mode_drawing(4,@_); },
    'UNMASK Mode Drawing'               => sub { mode_drawing(5,@_); },
    'ALPHA Mode Drawing'                => sub { mode_drawing(6,@_); },
    'ADD Mode Drawing'                  => sub { mode_drawing(7,@_); },
    'SUBTRACT Mode Drawing'             => sub { mode_drawing(8,@_); },
    'MULTIPLY Mode Drawing'             => sub { mode_drawing(9,@_); },
    'DIVIDE Mode Drawing'               => sub { mode_drawing(10,@_); },
    'Animated'                          => \&animated,
);

my @order : shared = (
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
#    'Flood Fill',
    'TrueType Fonts',
    'TrueType Printing',
#    'Rotate TrueType Fonts',
#    'Color Replace None-Clipped',
#    'Color Replace Clipped',
    'Blitting',
#    'Blit Move',
    'Rotate',
    'Flipping',
    'Monochrome',
#    'XOR Mode Drawing',
#    'OR Mode Drawing',
#    'AND Mode Drawing',
#    'MASK Mode Drawing',
#    'UNMASK Mode Drawing',
#    'ALPHA Mode Drawing',
#    'ADD Mode Drawing',
#    'SUBTRACT Mode Drawing',
#    'MULTIPLY Mode Drawing',
#    'DIVIDE Mode Drawing',
    'Animated',
);

if ($RUNNING) {
    my @th;
    foreach my $thr (0 .. $threads) {
        $th[$thr] = threads->create(\&run_thread,$thr,$dev);
    }
    while($RUNNING) {
        threads->yield();
        sleep .01;
    }
    while (threads->list()) {
        foreach my $t (threads->list(threads::joinable)) {
            $t->join();
        }
        threads->yield();
        sleep .01;
    }
}

##################################

$F->clip_reset();
$F->attribute_reset();
$F->cls('ON');


exit(0);

sub finish {
    alarm 0;
    $RUNNING = FALSE;
    threads->yield();
    $F->text_mode();
    $F->cls('ON');
    {
        lock(@order);
        @order = ();
    }
    $SIG{'ALRM'} = sub {
        exec('reset');
    };
    alarm 20;
    print STDERR "\n\nSHUTTING DOWN...\n\n";
} ## end sub finish

sub load_image {
    my $file = shift;
    my $F    = shift;

    local $SIG{'ALRM'} = local $SIG{'INT'} = local $SIG{'QUIT'} = local $SIG{'KILL'} = local $SIG{'TERM'} = local $SIG{'HUP'} = undef;

    print_it($F,"Loading Image > $file", '00FFFFFF', undef, 1);

    my $image = $F->load_image(
        {
            'x'            => 0,
            'y'            => 0,
            'width'        => $XX,
            'height'       => $F->{'H_CLIP'},
            'file'         => "$file",
            'convertalpha' => ($file =~ /wolf|Crescent/i) ? 1 : 0,
            'center'       => CENTER_XY,
        }
    );
    print_it($F,"Image loaded > $file", 'FFFF00FF', undef, 1);
    return($image);
}

sub run_thread {
    my $thread = shift;
    my $dev    = shift;

    my $F = Graphics::Framebuffer->new('FB_DEVICE' => "/dev/fb$dev", 'SHOW_ERRORS' => 0, 'ACCELERATED' => !$noaccel, 'SPLASH' => 0, 'RESET' => FALSE);

    local $SIG{'ALRM'} = local $SIG{'INT'} = local $SIG{'QUIT'} = local $SIG{'KILL'} = local $SIG{'TERM'} = local $SIG{'HUP'} = undef;

    while (scalar(@order) && $RUNNING) {
        $|=1;
        my $name;
        {
            lock(@order);
            $name = shift(@order);
        }
        $func{$name}->($F);
    }
}

sub color_mapping {
    my $F = shift;

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
    sleep $delay / 2 if ($RUNNING);
    return unless($RUNNING);

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
    sleep $delay / 2 if (! $rpi && $RUNNING);
    return unless($RUNNING);

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
    $F->blit_write($image) if ($RUNNING);

    sleep $delay if ($RUNNING);
} ## end sub color_mapping

sub plotting {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        my $x = int(rand($screen_width));
        my $y = int(rand($screen_height));
        $F->set_color({ 'alpha' => 255, 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->plot({ 'x' => $x, 'y' => $y, 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub plotting

sub lines {
    my $aa = shift;
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->line({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'antialiased' => $aa, 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub lines

sub angle_lines {
    my $aa = shift;
    my $F = shift;

    my $s     = time + $delay;
    my $angle = 0;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->angle_line({ 'x' => $center_x, 'y' => $center_y, 'radius' => int($F->{'H_CLIP'} / 2), 'angle' => $angle, 'antialiased' => $aa, 'pixel_size' => $psize });
        $angle ++;
        $angle -= 360 if ($angle >= 360);
        threads->yield();
    } ## end while (time < $s)
} ## end sub angle_lines

sub boxes {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub boxes

sub filled_boxes {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'filled' => 1 });

        threads->yield();
        $F->vsync();
    } ## end while (time < $s)
} ## end sub filled_boxes

sub gradient_boxes {
    my $direction = shift;
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub gradient_boxes

sub hatch_filled_boxes {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_boxes

sub texture_filled_boxes {
    my $F = shift;

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub texture_filled_boxes

sub rounded_boxes {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub rounded_boxes

sub filled_rounded_boxes {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'filled' => 1 });
        threads->yield();
    } ## end while (time < $s)
} ## end sub filled_rounded_boxes

sub hatch_filled_rounded_boxes {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->box({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xx' => int(rand($XX)), 'yy' => int(rand($YY)), 'radius' => 4 + rand($XX / 16), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
        threads->yield();
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_rounded_boxes

sub gradient_rounded_boxes {
    my $direction = shift;
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub gradient_rounded_boxes

sub texture_filled_rounded_boxes {
    my $F = shift;

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub texture_filled_rounded_boxes

sub circles {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub circles

sub filled_circles {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'filled' => 1 });
        threads->yield();
    } ## end while (time < $s)
} ## end sub filled_circles

sub hatch_filled_circles {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
        threads->yield();
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_circles

sub gradient_circles {
    my $direction = shift;
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub gradient_circles

sub texture_filled_circles {
    my $F = shift;

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub texture_filled_circles

sub arcs {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->arc({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub arcs

sub poly_arcs {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->poly_arc({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub poly_arcs

sub filled_pies {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->filled_pie({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360) });
        threads->yield();
    } ## end while (time < $s)
} ## end sub filled_pies

sub hatch_filled_pies {
    my $F = shift;

    my $s = time + ($delay * 2);
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->filled_pie({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'radius' => rand($center_y), 'start_degrees' => rand(360), 'end_degrees' => rand(360), 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
        threads->yield();
    } ## end while (time < $s)
    $F->attribute_reset();
} ## end sub hatch_filled_pies

sub gradient_pies {
    my $direction = shift;
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub gradient_pies

sub texture_filled_pies {
    my $F = shift;

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;

    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s)
} ## end sub texture_filled_pies

sub ellipses {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s)
} ## end sub ellipses

sub filled_ellipses {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)), 'alpha' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'filled' => 1 });
        threads->yield();
    } ## end while (time < $s)
} ## end sub filled_ellipses

sub hatch_filled_ellipses {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->set_b_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->ellipse({ 'x' => int(rand($XX)), 'y' => int(rand($YY)), 'xradius' => rand($center_x), 'yradius' => rand($center_y), 'filled' => 1, 'hatch' => $HATCHES[int(rand(scalar(@HATCHES)))] });
        threads->yield();
    } ## end while (time < $s && $RUNNING)
    $F->attribute_reset();
} ## end sub hatch_filled_ellipses

sub gradient_ellipses {
    my $direction = shift;
    my $thread    = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub gradient_ellipses

sub texture_filled_ellipses {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub texture_filled_ellipses

sub polygons {
    my $aa = shift;
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub polygons

sub filled_polygons {
    my $F = shift;

    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub filled_polygons

sub hatch_filled_polygons {
    my $F = shift;

    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
    $F->attribute_reset();
} ## end sub hatch_filled_polygons

sub gradient_polygons {
    my $direction = shift;
    my $F = shift;

    $F->mask_mode() if ($F->acceleration());
    my $s = time + $delay;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub gradient_polygons

sub texture_filled_polygons {
    my $F = shift;

    $F->mask_mode() if ($F->acceleration());

    my $s = ($F->{'BITS'} == 16) ? time + $delay * 3 : time + $delay * 2;
    while (time < $s && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub texture_filled_polygons

sub beziers {
    my $F = shift;

    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        my @coords = ();
        foreach my $c (1 .. int(rand(20))) {
            push(@coords, int(rand($XX)), int(rand($YY)));
        }
        $F->bezier({ 'coordinates' => \@coords, 'points' => 100, 'pixel_size' => $psize });
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub beziers

sub truetype_fonts {
    my $F = shift;

    my @fonts = (keys %{ $F->{'FONTS'} });
    my $g     = time + $delay;
    while (time < $g && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $g)
} ## end sub truetype_fonts

sub truetype_printing {
    my $F = shift;

    $F->ttf_paragraph(
        {
            'x'       => 0,
            'y'       => 30,
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 400,
            'justify' => 'justified',
            'size'    => int($YY/75),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );
    return unless($RUNNING);

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
            'text'    => 'The quick brown fox jumps over the lazy dog.  ' x 200,
            'justify' => 'justified',
            'size'    => int($YY/33),
            'color'   => sprintf('%02x%02x%02x%02x', int(rand(256)), int(rand(256)), int(rand(256)), 255),
        }
    );
    $F->clip_reset();
    sleep $delay if ($RUNNING);
}

sub rotate_truetype_fonts {
    my $F = shift;

    my $g     = time + $delay * 3;
    my $angle = 0;
    my $x     = $XX / 2;
    my $y     = $YY / 2;
    my $h     = ($YY <= 240 || $F->{'BITS'} == 16) ? 12 * $ym : 60 * $ym;
    my $ws    = 1;
    while (time < $g && $RUNNING) {
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
        threads->yield();
    } ## end while (time < $g)
} ## end sub rotate_truetype_fonts

sub flood_fill {
    my $F = shift;

    $F->clip_reset();
    if ($XX > 255) { # && !$rpi) {
        my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->polygon({ 'coordinates' => [220 * $xm, 190 * $ym, 1520 * $xm, 80 * $xm, 1160 * $xm, $YY, 960 * $xm, 540 * $ym, 760 * $xm, 780 * $ym] });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->polygon({ 'coordinates' => [1270 * $xm, 570 * $ym, 970 * $xm, 170 * $ym, 600 * $xm, 500 * $ym] });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->circle({ 'x' => 500 * $xm, 'y' => 320 * $ym, 'radius' => 100 * $xm });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        return unless($RUNNING);
        $F->fill({ 'x' => int(350 * $xm), 'y' => int(250 * $ym), 'texture' => $image });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        return unless($RUNNING);
        $F->fill({ 'x' => 960 * $xm, 'y' => 440 * $ym });
    } else {
        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        $F->polygon({ 'coordinates' => [$center_x, 3, 3, $YY - 3, $center_x, $center_y, $XX - 3, $YY - 4] });

        $F->set_color({ 'red' => int(rand(256)), 'green' => int(rand(256)), 'blue' => int(rand(256)) });
        return unless($RUNNING);
        $F->fill({ 'x' => 3, 'y' => 3 });
    } ## end else [ if ($XX > 255 && !$rpi)]

    return unless($RUNNING);
    sleep $delay if ($F->acceleration());
} ## end sub flood_fill

sub color_replace {
    my $clipped = shift;
    my $F = shift;

    my $x = $F->{'XRES'} / 4;
    my $y = $F->{'YRES'} / 4;

    $F->attribute_reset();
    $F->blit_write($DORKSMILE);
    $F->clip_set({ 'x' => $x, 'y' => $y, 'xx' => $x * 3, 'yy' => $y * 3 }) if ($clipped);
    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        my $pixel = $F->pixel({'x' => $XX / 2, 'y' => $YY / 2});

        my $r = $pixel->{'red'};
        my $g = $pixel->{'green'};
        my $b = $pixel->{'blue'};
        my $a = $pixel->{'alpha'};
        my $R = int(rand(256));
        my $G = int(rand(256));
        my $B = int(rand(256));
        my $A = 255;

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
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub color_replace

sub blitting {
    my $F = shift;

    my $s = time + $delay;
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    return unless($RUNNING);
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale' => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );
    while (time < $s && $RUNNING) {

        $image->{'x'} = abs(rand($XX - $image->{'width'}));
        $image->{'y'} = $F->{'Y_CLIP'} + abs(rand(($YY - $F->{'Y_CLIP'}) - $image->{'height'}));
        $F->blit_write($image);
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub blitting

sub blit_move {
    my $F = shift;

    $F->attribute_reset();
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    return unless($RUNNING);
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale' => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );
    my $x = 20;
    my $y = 20;
    $image->{'x'} = $x;
    $image->{'y'} = $y;
    $F->blit_write($image);
    my $w = $image->{'width'};
    my $h = $image->{'height'};
    my $s = time + $delay;
    while (time < $s && $RUNNING) {
        $image = $F->blit_move({ %{$image}, 'x_dest' => abs($x), 'y_dest' => abs($y) });
        $x++;
        $y++;
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub blit_move

sub rotate {
    my $F = shift;

    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale' => {
                'x'      => 0,
                'y'      => 0,
                'width'  => $XX * .5,
                'height' => $F->{'H_CLIP'} * .5,
            }
        }
    );
    foreach my $p (0 .. 1) {
        my $angle = 0;

        my $st = 'Counter-Clockwise Rotate Test ';
        unless ($p) {
            $st .= 'Using Standard Quality Setting';
        } else {
            $st .= 'Using High Quality Setting';
        }

        my $s     = time + $delay;
        my $count = 0;

        while ((time < $s || $count < 6) && $RUNNING) {
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

            $angle += 3;
            $angle = 0 if ($angle >= 360);
            $count++;
            threads->yield();
        } ## end while (time < $s || $count...)

        $angle = 0;
        $st    = 'Clockwise Rotate Test ';
        unless ($p) {
            $st .= 'Using Standard Quality Setting';
        } else {
            $st .= 'Using High Quality Setting';
        }

        $s     = time + $delay;
        $count = 0;
        while ((time < $s || $count < 6) && $RUNNING) {
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

            $angle -= 3;
            $angle = 0 if ($angle <= -360);
            $count++;

            threads->yield();
        } ## end while (time < $s || $count...)
        last if ($F->{'BITS'} == 16);
    } ## end foreach my $p (0 .. 1)

} ## end sub rotate

sub flipping {
    my $F = shift;
    my $r     = rand(scalar(@IMAGES));
    my $image = $IMAGES[$r];
    $image->{'image'}          = "$IMAGES[$r]->{'image'}";

    my $s    = time + $delay * 2;
    my $zoom = time + $delay;
    while (time < $s && $RUNNING) {
        foreach my $dir (qw(normal horizontal vertical both)) {
            # print_it($F, "Testing Image Flip $dir");
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
            } ## end else

            sleep .3;
        } ## end foreach my $dir (qw(normal horizontal vertical both))
        threads->yield();
    } ## end while (time < $s && $RUNNING)
} ## end sub flipping

sub monochrome {
    my $F = shift;
    my $image = $IMAGES[int(rand(scalar(@IMAGES)))];
    $image = $F->blit_transform(
        {
            'blit_data' => $image,
            'scale' => {
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

    while (time < $s && $RUNNING) {
        $mono->{'x'} = abs(rand($XX - $mono->{'width'}));
        $mono->{'y'} = $F->{'Y_CLIP'} + abs(rand(($YY - $F->{'Y_CLIP'}) - $mono->{'height'}));
        $F->blit_write($mono);
        threads->yield();
    }
    sleep  $delay;
} ## end sub monochrome

sub animated {
    my $F = shift;
    $F->{'DIAGNOSTICS'} = 1;

    opendir(my $DIR, $images_path);
    chomp(my @list = readdir($DIR));
    closedir($DIR);
    my $image;
    @list = shuffle(@list);
    foreach my $info (@list) {
        next unless ($info =~ /\.gif$/i);
        for my $count (0 .. 1) {

            if ($count || $XX <= 320) {
                # print_it($F, "Loading Animated Image '$info' Scaled to Full Screen", 'FFFF00FF', { 'red' => 0, 'green' => 0, 'blue' => 255, 'alpha' => 255 });
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
                # print_it($F, "Loading Animated Image '$info' Native Size", 'FFFF00FF', { 'red' => 0, 'green' => 0, 'blue' => 255, 'alpha' => 255 });
                print STDERR "\n";
                $image = $F->load_image(
                    {
                        'file'   => "$images_path/$info",
                        'center' => CENTER_XY
                    }
                );
            } ## end else [ if ($count || $XX <= 320)]

            foreach my $bench (0 .. 1) {
                if (defined($image)) {
                    $F->cls();
                    my $fps   = 0;
                    my $start = time;
                    my $s     = time + $delay;

                    while (time <= $s) {
                        foreach my $frame (0 .. (scalar(@{$image}) - 1)) {
                            if (time > $s * 2) {
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
                                print STDERR chr(27) . '[0;0H', sprintf('%.03f FPS', (1 / $end) * $fps);
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
    my $F = shift;
    if ($mode == MASK_MODE) {
        mask_drawing($F);
    } elsif ($mode == UNMASK_MODE) {
        unmask_drawing($F);
    } elsif ($mode == ALPHA_MODE) {
        alpha_drawing($F);
    } else {
        my @modes = qw( NORMAL XOR OR AND MASK UNMASK ALPHA ADD SUBTRACT MULTIPLY DIVIDE );
        # print_it($F, 'Testing "' . $modes[$mode] . '" Drawing Mode');
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
    }
} ## end sub mode_drawing

sub alpha_drawing {
    my $F = shift;
    $F->attribute_reset();
    # print_it($F, 'Testing Alpha Drawing Mode');
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
    my $F = shift;
    $F->attribute_reset();
    # print_it($F, 'Testing MASK Drawing Mode');

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
    my $F = shift;
    $F->attribute_reset();
    # print_it($F, 'Testing UNMASK Drawing Mode');

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

 perl threaded_primitives.pl [--dev=device number] [--x=X emulated resolution] [--y=Y emulated resolution] [--pixel=pixel size] [--noaccel]

=over 2

Examples:

=back

=over 4

 perl primitives.pl --dev=1

 perl primitives.pl --pixel=2

=back

=head1 OPTIONS

=over 2

=item B<--dev>=C<device number>

By default, it uses "/dev/fb0", but you can tell it to use any framebuffer device number.  Only the number 0 - 31 is needed here.

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
