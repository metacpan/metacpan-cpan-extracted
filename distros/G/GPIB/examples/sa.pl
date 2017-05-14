
use Tk;
use GPIB::hp3585a;
use GD;

$GDbug = ($^O =~ /Win32/) ? 1 : 0;      # Work around little bug in GD on win32

# Jeff Mock
# 1859 Scott St.
# San Francisco, CA 94115
#
# jeff@mock.com
# (c) 1999

#
#  Simple script to use Tk and GD to do a graphical display of
#  an HP3585A spectrum analyser.  This doesn't do proper error
#  check, it's just an example to show how GD, Tk, and GPIB can
#  be used together write interactive instrument control apps 
#  that run on Linux on NT.
#


#
# Generate a new image and change the canvas on the screen
# Reschedules itself if $running is true.
#
sub newImage {
    # background
    $im->filledRectangle(0, 0, $width-1, $height-1, $black);

    # Vertical grid lines
    for($i=0; $i<$width; $i += ($width-1)/10.0) {
        $im->line($i, 0, $i, $height-1, $grid);
    }

    # Horizontal grid lines
    for($i=0; $i<$height; $i += ($height * 1000.0/1024.0)/10.0) {
        $im->line(0, $height-1-$i, $width-1, $height-1-$i, $grid);
    }

    # Get data from device
    @items = $g->getCaption;
    @vals =  $g->getDisplay;

    # Get marker list and fixup data for display
    @markers = ();
    for ($i=1; $i<@vals; $i++) {
        push (@markers, $i) if ($vals[$i] & 0x400);
        $vals[$i] = 1023 - ($vals[$i] & 0x3ff);
    }

    # Text 
    for($i=0; $i<5; $i++) {
        # Left side
        $im->string(gdLargeFont, 10, 16 + 16*$i,    
                $items[$i*2], $white);
        # Right side
        $im->string(gdLargeFont,$width-10-8*length($items[$i*2+1]), 16 + 16*$i, 
                $items[$i*2+1], $white);
    }

    # Trace
    for($i=1; $i<1000; $i++) {
        $im->line($i * $width / 1000.0, $vals[$i] * $height / 1024.0,
                ($i+1) * $width / 1000.0, $vals[$i+1] * $height / 1024.0, $red);
    }

    # Markers
    for (@markers) {
        $im->arc($_ * $width / 1000.0, $vals[$_] * $height / 1024.0,
                10.0, 10.0, 0, 360, $white);
    }

    $foo = $im->gif;        # Foo has GIF image data

    if ($GDbug) {
        open FD, ">t.gif";
        binmode(FD);
        print FD $foo;
        close FD;
        $ph = $mw->Photo(   -format => "gif", -file => "t.gif");
    } else {
        $ph = $mw->Photo(   -format => "gif", -data => $foo);
    }

    $can->createImage(0, 0, -anchor => "nw", -image => $ph);
    $mw->after(1000, \&newImage) if $running;
}

sub but0_push {
    print "But0\n";
    $running = 1;
    newImage();
    print "But0 done.\n";
}

sub but1_push {
    print "But1\n";
    newImage() unless $running;
    $running = 0;
    print "But1 done\n";
}

# Size of image, original data is 1001 wide, 1024 tall
$width = 501;
$height = 512;
$running = 0;

$g = GPIB::hp3585a->new("HP3585A");

$im = new GD::Image($width, $height);
# allocate some colors
$white = $im->colorAllocate(255,255,255);
$black = $im->colorAllocate(0,0,0);
$grid = $im->colorAllocate(80,80,80);
$red = $im->colorAllocate(255,0,0);
$blue = $im->colorAllocate(0,0,255);
$green = $im->colorAllocate(0,255,0);

$mw = MainWindow->new;

$but[0] = $mw->Button(-text => "Repeat", -command => \&but0_push);
$but[1] = $mw->Button(-text => "Single/Stop", -command => \&but1_push);

$can = $mw->Canvas(     -height => $height,
                        -width  => $width,
    );

$but[0]->pack;
$but[1]->pack;
$can->pack;
newImage();

MainLoop;


