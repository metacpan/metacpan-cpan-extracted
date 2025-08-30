package Graphics::Framebuffer;

## TEMP COPYRIGHT ##
#  Copyright 2017 - 2025 Richard Kelsch
## TEMPCOPYRIGHT ##

# Only POD is utf-8.
=encoding utf8

=head1 NAME

Graphics::Framebuffer - A Simple Framebuffer Graphics Library

=head1 SYNOPSIS

Direct drawing for 32/24/16 bit framebuffers (others would be supported if asked for)

 use Graphics::Framebuffer;

 our $fb = Graphics::Framebuffer->new();

Drawing is this simple

 $fb->cls('OFF'); # Clear screen and turn off the console cursor

 $fb->set_color({'red' => 255, 'green' => 255, 'blue' => 255, 'alpha' => 255});
 $fb->plot({'x' => 28, 'y' => 79,'pixel_size' => 1});
 $fb->drawto({'x' => 405,'y' => 681,'pixel_size' => 1});
 $fb->circle({'x' => 200, 'y' => 200, 'radius' => 100, 'filled' => 1});
 $fb->polygon({'coordinates' => [20,20,  53,3,  233,620], 'pixel_size' => 5});
 $fb->box({'x' => 95, 'y' => 100, 'xx' => 400, 'yy' => 600, 'filled' => 1});
 # ... and many many more

 $fb->cls('ON'); # Clear screen and turn on the console cursor

Methods requiring parameters require a hash (or anonymous hash) reference passed to the method (for speed).  All parameters have easy to understand english names, all lower case, to understand exactly what the method is doing.

=head1 DESCRIPTION

A (mostly) Perl graphics library for exclusive use in a Linux/FreeBSD/Unix console framebuffer environment.  It is written for simplicity, without the need for complex API's and drivers with "surfaces" and such.

Back in the old days, computers drew graphics this way, and it was simple and easy to do.  I was writing a console based media playing program, and was not satisfied with the limited abilities offered by the nCurses library, and I did not want the overhead of the X-Windows environment to get in the way.  My intention was to create a mobile media server.  In case you are wondering, that project has been quite successful, and I am still making improvements to it.  I may even include it in the "examples" directory on future versions.

There are places where Perl just won't cut it.  So I use the Imager library to take up the slack, or my own C code.  Imager is just used to load images,, save images, merge, rotate, and draw TrueType/Type1 text.  I am also incorporating compiled C to further assist with speed.  That is being implemented step by step, but "acceleration" will always be optional, and pure Perl routines always available for those systems without a C compiler or "Inline:C" available.

I cannot guarantee this will work on your video card, but I have successfully tested it on NVidia GeForce, AMD Radeon, Matrox, Raspberry PI, Odroid XU3/XU4, and VirtualBox displays.  However, you MUST remember, your video driver MUST be framebuffer based.  The proprietary Nvidia and AMD drivers (with DRM) will NOT work with this module. You must use the open source video drivers, such as Nouveau, to be able to use this library (with output to see).  Also, it is not going to work from within X-Windows, so don't even try it, it will either crash X, or make a mess on the screen.  This is a console only graphics library.

I I<highly recommend> that you use a 32/24 bit graphics mode instead of 16 bit.  Normally one might think that 16 bits are less and should be faster... WRONG.  This module uses the B<Imager> module to do complex tasks and this module only works in 32/24 bit modes.  This means in order to do things on a 16 bit framebuffer, GFB must run a conversion to 16 bit on EVERY complex operation, slowing things down.  Also, CPUs today hate 16 bit accessing and prefer 32 bit, hence faster.  If you have no choice but to use 16 bit mode, then now you know it can be slower.

NOTE:

If a framebuffer is not available, the module will go into emulation mode and open a pseudo-screen in the object's hash variable 'SCREEN'

You can write this to a file, whatever.  It defaults to a 640x480x32 RGB graphics 'buffer'.  However, you can change that by passing parameters to the 'new' method.

You will not be able to see the output directly when in emulation mode.  I mainly created this mode so that you could install this module (on systems without a framebuffer) and test code you may be writing to be used on other devices that have accessible framebuffer devices.  Nevertheless, I have learned that people use emulation mode as an offscreen drawing surface, and blit from one to the other.  Which is pretty clever.

Make sure you have read/write access to the framebuffer device.  Usually this just means adding your account to the "video" group (make sure you log out and log in again after doing that).  Alternately, you can just run your script as root.  Although I don't recommend it.

=head1 INSTALLATION

Read the file "installing/INSTALL" and follow its instructions.

When you install this module, please do it within a console, not a console window in X-Windows, but the actual Linux/FreeBSD console outside of X-Windows.

If you are in X-Windows, and don't know how to get to a console, then just hit CTRL-ALT-F1 (actually CTRL-ALT-F1 through CTRL-ALT-F6 works) and it should show you a console.  ALT-F7 or ALT-F8 will get you back to X-Windows.

=head1 OPERATIONAL THEORY

How many Perl modules actually tell you how they work?  Well, I will tell you how this one works.

The framebuffer is simply a special file that is mapped to the screen on Unix style systems like Linux or FreeBSD.  How the driver does this can be different.  Some may actually directly map the display memory to this file, and some install a second copy of the display to normal memory and copy it to the display on every vertical blank, usually with a fast DMA transfer.

This module maps that file to a string, and that ends up making the string exactly the same size as the physical display.  Plotting is simply a matter of calculating where in the string that pixel is and modifying it, via "substr" (never using "=" directly).  It's that simple.

Drawing lines etc. requires some algorithmic magic though, but they all call the plot routine to do their eventual magic.

Originally everything was done in Perl, and the module's speed was mostly acceptable, unless you had a really slow system.  It still can run in pure Perl, if you turn off the acceleration feature, although I do not recommend it, if you want speed.

=head1 SPECIAL VARIABLES

The following are hash keys to the main object variable.  For example, if you use the variable $fb as the object variable, then the following are $fb->{VARIABLE_NAME}.

NOTE:  Do NOT set these variables directly.  They are for internal use and reference only.  Use the approprate method to change settings.

=over 4

* B<FONTS>

List of system fonts

Contains a hash of every font found in the system in the format:

=back

=over 6

# 'FaceName' => {
#     'path' => 'Path To Font',
#     'font' => 'File Name of Font'
# },
# ...

=back

=over 4

* B<Imager-Has-TrueType>

If your installation of Imager has TrueType font capability, then this will be 1

* B<Imager-Has-Type1>

If your installation of Imager has Adobe Type 1 font capability, then this will be 1

* B<Imager-Has-Freetype2>

If your installation of Imager has the FreeType2 library rendering capability, then this will be 1

* B<Imager-Image-Types>

An anonymous array of supported image file types.

* B<HATCHES>

An anomyous array of hatch names for hatch fills.

This is also exported as @HATCHES

* B<X_CLIP>

The top left-hand corner X location of the clipping region

* B<Y_CLIP>

The top left-hand corner Y location of the clipping region

* B<XX_CLIP>

The bottom right-hand corner X location of the clipping region

* B<YY_CLIP>

The bottom right-hand corner Y location of the clipping region.

* B<CLIPPED>

If this is true, then the clipping region is smaller than the full screen

If false, then the clipping region is the screen dimensions.

* B<DRAW_MODE>

The current drawing mode.  This is a numeric value corresponding to the constants described in the method 'draw_mode'

* B<RAW_FOREGROUND_COLOR>

The current foreground color encoded as a string.

* B<RAW_BACKGROUND_COLOR>

The current background color encoded as a string.

* B<ACCELERATED>

Indicates if C code or hardware acceleration is being used.

=back

=over 6

=item B<Possible Values>

 0 = Perl code only
 1 = Some functions accelerated by compiled C code (Default)
 2 = All of #1 plus additional functions accelerated by hardware (currently not supported, and likely never will)

=back

Many of the parameters you pass to the "new" method are also special variables.

=cut

use strict;
no strict 'vars';    # We have to map a variable as the screen.  So strict is going to whine about what we do with it.

no warnings;         # We have to be as quiet as possible

=head1 CONSTANTS

The following constants can be used in the various methods.  Each method example will have the possible constants to use for that method.

The value of the constant is in parenthesis:

B<CONSTANT> (value)

Boolean constants

=over 8

* B<TRUE>  ( 1 )

* B<FALSE> ( 0 )

=back

Draw mode constants

=over 8

* B<NORMAL_MODE>   ( 0  )

* B<XOR_MODE>      ( 1  )

* B<OR_MODE>       ( 2  )

* B<AND_MODE>      ( 3  )

* B<MASK_MODE>     ( 4  )

* B<UNMASK_MODE>   ( 5  )

* B<ALPHA_MODE>    ( 6  )

* B<ADD_MODE>      ( 7  )

* B<SUBTRACT_MODE> ( 8  )

* B<MULTIPLY_MODE> ( 9  )

* B<DIVIDE_MODE>   ( 10 )

=back

Draw Arc constants

=over 8

* B<ARC>      ( 0 )

* B<PIE>      ( 1 )

* B<POLY_ARC> ( 2 )

=back

Virtual framebuffer color mode constants

=over 8

* B<RGB> ( 0 )

* B<RBG> ( 1 )

* B<BGR> ( 2 )

* B<BRG> ( 3 )

* B<GBR> ( 4 )

* B<GRB> ( 5 )

=back

Text rendering centering constants

=over 8

* B<CENTER_NONE> ( 0 )

* B<CENTER_X>    ( 1 )

* B<CENTER_Y>    ( 2 )

* B<CENTER_XY>   ( 3 )

=back

Acceleration method constants

=over 8

* B<PERL>     ( 0 )

* B<SOFTWARE> ( 1 )

* B<HARDWARE> ( 2 )

=back

=cut

use constant {
    TRUE  => 1,
    FALSE => 0,

    NORMAL_MODE   => 0,    #   Constants for DRAW_MODE
    XOR_MODE      => 1,
    OR_MODE       => 2,
    AND_MODE      => 3,
    MASK_MODE     => 4,
    UNMASK_MODE   => 5,
    ALPHA_MODE    => 6,
    ADD_MODE      => 7,
    SUBTRACT_MODE => 8,
    MULTIPLY_MODE => 9,
    DIVIDE_MODE   => 10,

    ARC      => 0,         #   Constants for "draw_arc" method
    PIE      => 1,
    POLY_ARC => 2,

    RGB => 0,              #   Constants for color mapping
    RBG => 1,
    BGR => 2,
    BRG => 3,
    GBR => 4,
    GRB => 5,

    CENTER_NONE => 0,      #   Constants for centering
    CENTER_X    => 1,
    CENTER_Y    => 2,
    CENTER_XY   => 3,
    CENTRE_NONE => 0,      #   Constants for centering (for British and Canadian folks)
    CENTRE_X    => 1,
    CENTRE_Y    => 2,
    CENTRE_XY   => 3,

    PERL     => 0,
    SOFTWARE => 1,
    HARDWARE => 2,

    ## Set up the Framebuffer driver "constants" defaults
    # Commands
    FBIOGET_VSCREENINFO => 0x4600,    # These come from "fb.h" in the kernel source
    FBIOPUT_VSCREENINFO => 0x4601,
    FBIOGET_FSCREENINFO => 0x4602,
    FBIOGETCMAP         => 0x4604,
    FBIOPUTCMAP         => 0x4605,
    FBIOPAN_DISPLAY     => 0x4606,
    FBIO_CURSOR         => 0x4608,
    FBIOGET_CON2FBMAP   => 0x460F,
    FBIOPUT_CON2FBMAP   => 0x4610,
    FBIOBLANK           => 0x4611,
    FBIOGET_VBLANK      => 0x4612,
    FBIOGET_GLYPH       => 0x4615,
    FBIOGET_HWCINFO     => 0x4616,
    FBIOPUT_MODEINFO    => 0x4617,
    FBIOGET_DISPINFO    => 0x4618,
    FBIO_WAITFORVSYNC   => 0x4620,
    VT_GETSTATE         => 0x5603,
    KDSETMODE           => 0x4B3A,
    KD_GRAPHICS         => 1,
    KD_TEXT             => 0,

    # FLAGS
	# I have never found a driver that actually uses these, else I would have used them
    FBINFO_HWACCEL_NONE      => 0x0000,    # These come from "fb.h" in the kernel source
    FBINFO_HWACCEL_COPYAREA  => 0x0100,
    FBINFO_HWACCEL_FILLRECT  => 0x0200,
    FBINFO_HWACCEL_IMAGEBLIT => 0x0400,
    FBINFO_HWACCEL_ROTATE    => 0x0800,
    FBINFO_HWACCEL_XPAN      => 0x1000,
    FBINFO_HWACCEL_YPAN      => 0x2000,
    FBINFO_HWACCEL_YWRAP     => 0x4000,

    pi => (4 * atan2(1,1)), # This gets rid of Math::Trig
};

## THREADS ##
use threads ('yield', 'stringify', 'stack_size' => 131076, 'exit' => 'threads_only');
use threads::shared;
##THREADS##

use POSIX ();
use POSIX qw(modf);
use Time::HiRes qw(sleep time);                                  # The time accuracy has to be milliseconds on many routines
use Math::Bezier;                                                # Bezier curve calculations done here.
use Math::Gradient qw( gradient array_gradient multi_gradient ); # Awesome gradient calculation module
use List::Util qw(min max);                                      # min and max are very handy!
use File::Map ':map';                                            # Absolutely necessary to map the screen to a string.
use Term::ReadKey;
use Imager;                                                      # This is used for TrueType font printing, image loading.
use Imager::Matrix2d;
use Imager::Fill;                                                # For hatch fills
use Imager::Fountain;                                            #
use Imager::Font::Wrap;
use Graphics::Framebuffer::Mouse;                                # The mouse handler
use Graphics::Framebuffer::Splash;                               # The splash code is here

Imager->preload; # The Imager documentation says to do this, but doesn't give much of an explanation why.  However, I assume it is to initialize global variables ahead of time so threads behave.

## This is for debugging, and should normally be commented out.
# use Data::Dumper::Simple;$Data::Dumper::Sortkeys=TRUE;$Data::Dumper::Purity=TRUE;

BEGIN {
    require Exporter;

    # set the version for version checking
    our $VERSION   = '## VERSION ##';
    our @ISA       = qw(Exporter);
    our @EXPORT_OK = qw(
      FBIOGET_VSCREENINFO
      FBIOPUT_VSCREENINFO
      FBIOGET_FSCREENINFO
      FBIOGETCMAP
      FBIOPUTCMAP
      FBIOPAN_DISPLAY
      FBIO_CURSOR
      FBIOGET_CON2FBMAP
      FBIOPUT_CON2FBMAP
      FBIOBLANK
      FBIOGET_VBLANK
      FBIOGET_GLYPH
      FBIOGET_HWCINFO
      FBIOPUT_MODEINFO
      FBIOGET_DISPINFO
      FBIO_WAITFORVSYNC
      VT_GETSTATE
      FBINFO_HWACCEL_NONE
      FBINFO_HWACCEL_COPYAREA
      FBINFO_HWACCEL_FILLRECT
      FBINFO_HWACCEL_IMAGEBLIT
      FBINFO_HWACCEL_ROTATE
      FBINFO_HWACCEL_XPAN
      FBINFO_HWACCEL_YPAN
      FBINFO_HWACCEL_YWRAP
      $VERSION
    );
    our @EXPORT = qw(
      TRUE
      FALSE
      NORMAL_MODE
      XOR_MODE
      OR_MODE
      AND_MODE
      MASK_MODE
      UNMASK_MODE
      ALPHA_MODE
      ADD_MODE
      SUBTRACT_MODE
      MULTIPLY_MODE
      DIVIDE_MODE
      ARC
      PIE
      POLY_ARC
      RGB
      RBG
      BGR
      BRG
      GBR
      GRB
      CENTER_NONE
      CENTER_X
      CENTER_Y
      CENTER_XY
      CENTRE_NONE
      CENTRE_X
      CENTRE_Y
      CENTRE_XY
      PERL
      SOFTWARE
      HARDWARE
      @HATCHES
      @COLORORDER
    );
}

sub DESTROY { # Always clean up after yourself before exiting
    my $self = shift;
    $self->text_mode();
    $self->_screen_close();
    unlink('/tmp/output.gif') if (-e '/tmp/output.gif');
    _reset() if ($self->{'RESET'});    # Exit by calling 'reset' first
	# Restore the original screen before run
	substr($self->{'SCREEN'},0,length($self->{'START_SCREEN'})) = $self->{'START_SCREEN'};
}

# use Inline 'info', 'noclean', 'noisy'; # Only needed for debugging

use Inline Config => warnings => 0;
use Inline C => <<'C_CODE','name' => 'Graphics::Framebuffer', 'VERSION' => $VERSION;
## C CODE ##
C_CODE

our @HATCHES    = Imager::Fill->hatches;
our @COLORORDER = (qw( RGB RBG BGR BRG GBR GRB ));

=head1 METHODS

X<acceleration>
X<active_console>
X<add_mode>
X<alpha_mode>
X<and_mode>
X<angle_line>
X<arc>
X<attribute_reset>
X<bezier>
X<blit_copy>
X<blit_move>
X<blit_read>
X<blit_transform>
X<blit_write>
X<box>
X<circle>
X<clear_screen>
X<clip_off>
X<clip_reset>
X<clip_rset>
X<clip_set>
X<cls>
X<divide_mode>
X<draw_arc>
X<draw_mode>
X<drawto>
X<ellipse>
X<fill>
X<filled_pie>
X<get_face_name>
X<get_font_list>
X<getpixel>
X<get_pixel>
X<graphics_mode>
X<hardware>
X<last_plot>
X<line>
X<load_image>
X<mask_mode>
X<monochrome>
X<multiply_mode>
X<new>
X<normal_mode>
X<or_mode>
X<perl>
X<pixel>
X<play_animation>
X<plot>
X<poly_arc>
X<polygon>
X<rbox>
X<rounded_box>
X<replace_color>
X<RGB565_to_RGB888>
X<RGB565_to_RGBA8888>
X<RGB888_to_RGB565>
X<RGB888_to_RGBA8888>
X<RGBA8888_to_RGB565>
X<RGBA8888_to_RGB888>
X<screen_dimensions>
X<screen_dump>
X<set_b_color>
X<setbcolor>
X<set_background_color>
X<setcolor>
X<set_color>
X<set_foreground_color>
X<setpixel>
X<set_pixel>
X<software>
X<subtract_mode>
X<text_mode>
X<ttf_paragraph>
X<ttf_print>
X<unmask_mode>
X<vsync>
X<wait_for_console>
X<which_console>
X<xor_mode>

With the exception of "new" and some other methods that only expect one parameter, the methods expect a single hash reference to be passed.  This may seem unusual, but it was chosen for speed, and speed is important in a Perl graphics module.

=cut

sub new {
=head2 B<new>

This instantiates the framebuffer object

=over 4

 my $fb = Graphics::Framebuffer->new(parameter => value);

=back

=head3 PARAMETERS

=over 6

* B<FB_DEVICE>

Framebuffer device name.  If this is not defined, then it tries the following devices in the following order:

      *  /dev/fb0 - 31
      *  /dev/graphics/fb0 - 31

If none of these work, then the module goes into emulation mode.

You really only need to define this if there is more than one framebuffer device in your system, and you want a specific one (else it always chooses the first it finds).  If you have only one framebuffer device, then you likely do not need to define this.

Use "EMULATED" instead of an actual framebuffer device, and it will open a memory only or "emulated" framebuffer.  You can use this mode to have multiple "layers" for loading and manipulating images, but a single main framebuffer for displaying them.

* B<FOREGROUND>

Sets the default (global) foreground color for when 'attribute_reset' is called.  It is in the same format as "set_color" expects:

 { # This is the default value
   'red'   => 255,
   'green' => 255,
   'blue'  => 255,
   'alpha' => 255
 }

* Do not use this to change colors, as "set_color" is intended for that.  Use this to set the DEFAULT foreground color for when "attribute_reset" is called.

* B<BACKGROUND>

Sets the default (global) background color for when 'attribute_reset' is called.  It is in the same format as "set_b_color" expects:

 { # This is the default value
   'red'   => 0,
   'green' => 0,
   'blue'  => 0,
   'alpha' => 0
 }

* Do not use this to change background colors, as "set_b_color" is intended for that.  Use this to set the DEFAULT background color for when "attribute_reset" is called.

* B<SPLASH>

The splash screen is or is not displayed

A value other than zero turns on the splash screen, and the value is the wait time to show it (default 2 seconds)
A zero value turns it off

* B<IGNORE_X_WINDOWS>

Bypasses the X-Windows check and loads anyway (dangerous).
Set to 1 to disable X-Windows check. Default is 0.

* B<FONT_PATH>

Overrides the default font path for TrueType/Type1 fonts

If 'ttf_print' is not displaying any text, then this may need to be overridden.

* B<FONT_FACE>

Overrides the default font filename for TrueType/Type 1 fonts.

If 'ttf_print' is not displaying any text, then this may need to be overridden.

* B<SHOW_ERRORS>

Normally this module is completely silent and does not display errors or warnings (to the best of its ability).  This is to prevent corruption of the graphics.  However, you can enable error reporting by setting this to 1.

This is helpful for troubleshooting.

* B<DIAGNOSTICS>

If true, it shows images as they load, and displays benchmark informtion in the loading process.

* B<RESET> [0 or 1 (default)]

When the object is created, it automatically creates a simple signal handler for B<INT> and B<QUIT> to run B<exec('reset')> as a clean way of exiting your script and restoring the screen to defaults.

Also, when the object is destroyed, it is assumed you are exiting your script.  This causes Graphics::Framebuffer to execute "exec('reset')" as its method of exiting instead of having you use "exit".

You can disable this behavior by setting this to 0.

=back

=head3 EMULATION MODE OPTIONS

=over 6

The options here only apply to emulation mode.

Emulation mode can be used as a secondary off-screen drawing surface, if you are clever.

=back

=over 12

* B<FB_DEVICE> => 'EMULATED'

Sets this object to be in emulation mode.

Emulation mode special variables for "new" method:

* B<VXRES>

Width of the emulation framebuffer in pixels.  Default is 640.

* B<VYRES>

Height of the emulation framebuffer in pixels.  Default is 480.

* B<BITS>

Number of bits per pixel in the emulation framebuffer.  Default is 32.

* B<BYTES>

Number of bytes per pixel in the emulation framebuffer.  It's best to keep it BITS/8.  Default is 4.

* B<COLOR_ORDER>

Defines the colorspace for the graphics routines to draw in.  The possible (and only accepted) string values are:

    'RGB'  for Red-Green-Blue (the default)
    'RBG'  for Red-Blue-Green
    'GRB'  for Green-Red-Blue
    'GBR'  for Green-Blue-Red
    'BRG'  for Blue-Red-Green
    'BGR'  for Blue-Green-Red (Many video cards are this)

Why do many video cards use the BGR color order?  Simple, their GPUs operate with the high to low byte order for long words.  To the video card, it is RGB, but to a CPU that stores bytes in low to high byte order.

=back

=cut

    my $class = shift;

    # I would have liked to make this a lot more organized, but over the years it
    # kind of became this mess.  I could change it, but it likely would break any
    # code that directly uses values.
    my $this;
    $ENV{'PATH'} = '/usr/bin:/bin:/usr/local/bin'; # Testing doesn't work in taint mode unless this is here.
    my $FFMPEG;
    if (-e '/usr/bin/ffmpeg') {
        $FFMPEG = '/usr/bin/ffmpeg';
    } elsif (-e '/usr/local/bin/ffmpeg') {
        $FFMPEG = '/usr/local/bin/ffmpeg';
    }
    my $self = {
        'SCREEN'        => '',            # The all mighty framebuffer that is mapped to the real framebuffer later

        'RESET'         => TRUE,          # Default to use 'reset' on destroy
        'VERSION'       => $VERSION,      # Helps with debugging for people sending me dumps
        'HATCHES'       => [@HATCHES],    # Pull in hatches from Imager
        'FFMPEG'        => $FFMPEG,

        # Set up the user defined graphics primitives and attributes default values
        'Imager-Has-TrueType'  => $Imager::formats{'tt'}  || 0,
        'Imager-Has-Type1'     => $Imager::formats{'t1'}  || 0,
        'Imager-Has-Freetype2' => $Imager::formats{'ft2'} || 0,
        'Imager-Image-Types'   => [ map( {uc($_) } Imager->read_types()) ],

        'X'           => 0,                 # Last position plotted X
        'Y'           => 0,                 # Last position plotted Y
        'X_CLIP'      => 0,                 # Top left clip start X
        'Y_CLIP'      => 0,                 # Top left clip start Y
        'YY_CLIP'     => undef,             # Bottom right clip end X
        'XX_CLIP'     => undef,             # Bottom right clip end Y
        'CLIPPED'     => FALSE,             # Indicates if clipping is less than the full screen
        'IMAGER_FOREGROUND_COLOR' => undef, # Imager foreground color
        'IMAGER_BACKGROUND_COLOR' => undef, # Imager background color
        'RAW_FOREGROUND_COLOR'    => undef, # Global foreground color (Raw string)
        'RAW_BACKGROUND_COLOR'    => undef, # Global Background Color
        'DRAW_MODE'   => NORMAL_MODE,       # Drawing mode (Normal default)
        'DIAGNOSTICS' => FALSE,             # Determines if diagnostics are shown when images are loaded.
        'IGNORE_X_WINDOWS' => FALSE,        # Forces load inside X-Windows (dangerous)

        'SHOW_ERRORS' => FALSE,             # If on, it will output any errors in Imager or elsewhere, else all errors are squelched

        'FOREGROUND' => {                   # Default foreground for "attribute_reset" method
            'red'   => 255,
            'green' => 255,
            'blue'  => 255,
            'alpha' => 255
        },
        'BACKGROUND' => {                   # Default background for "attribute_reset" method
            'red'   => 0,
            'green' => 0,
            'blue'  => 0,
            'alpha' => 0
        },

        'FONT_PATH' => '/usr/share/fonts/truetype/freefont',    # Default fonts path
        'FONT_FACE' => 'FreeSans.ttf',                          # Default font face

        'SPLASH' => 2,                                          # Time in seconds to show the splash screen

        'WAIT_FOR_CONSOLE' => FALSE,
        'THIS_CONSOLE'     => 1,
        'CONSOLE'          => 1,

        'NORMAL_MODE'   => NORMAL_MODE,     #   Constants for DRAW_MODE
        'XOR_MODE'      => XOR_MODE,
        'OR_MODE'       => OR_MODE,
        'AND_MODE'      => AND_MODE,
        'MASK_MODE'     => MASK_MODE,
        'UNMASK_MODE'   => UNMASK_MODE,
        'ALPHA_MODE'    => ALPHA_MODE,
        'ADD_MODE'      => ADD_MODE,
        'SUBTRACT_MODE' => SUBTRACT_MODE,
        'MULTIPLY_MODE' => MULTIPLY_MODE,
        'DIVIDE_MODE'   => DIVIDE_MODE,

        'ARC'      => ARC,            #   Constants for "draw_arc" method
        'PIE'      => PIE,
        'POLY_ARC' => POLY_ARC,

        'RGB' => RGB,                 #   Constants for color mapping
        'RBG' => RBG,                 #   Constants for color mapping
        'BGR' => BGR,                 #   Constants for color mapping
        'BRG' => BRG,                 #   Constants for color mapping
        'GBR' => GBR,                 #   Constants for color mapping
        'GRB' => GRB,                 #   Constants for color mapping

        'CENTER_NONE' => CENTER_NONE, #   Constants for centering
        'CENTER_X'    => CENTER_X,    #   Constants for centering
        'CENTER_Y'    => CENTER_Y,    #   Constants for centering
        'CENTER_XY'   => CENTER_XY,   #   Constants for centering
        'CENTRE_NONE' => CENTRE_NONE, #   Constants for centering
        'CENTRE_X'    => CENTRE_X,    #   Constants for centering
        'CENTRE_Y'    => CENTRE_Y,    #   Constants for centering
        'CENTRE_XY'   => CENTRE_XY,   #   Constants for centering
        ####################################################################

        'KD_GRAPHICS'         => 1,
        'KD_TEXT'             => 0,

        # I=32.64,L=32,S=16,C=8,A=string
        # Structure Definitions
        'vt_stat'             => 'SSS',    # v_active, v_signal, v_state
        'FBioget_vscreeninfo' => 'L' .     # 32 bits for xres
          'L' .                            # 32 bits for yres
          'L' .                            # 32 bits for xres_virtual
          'L' .                            # 32 bits for yres_vortual
          'L' .                            # 32 bits for xoffset
          'L' .                            # 32 bits for yoffset
          'L' .                            # 32 bits for bits per pixel
          'L' .                            # 32 bits for grayscale (0=color)
          'L' .                            # 32 bits for red bit offset
          'L' .                            # 32 bits for red bit length
          'L' .                            # 32 bits for red msb_right (!0 msb is right)
          'L' .                            # 32 bits for green bit offset
          'L' .                            # 32 bits for green bit length
          'L' .                            # 32 bits for green msb_right (!0 msb is right)
          'L' .                            # 32 bits for blue bit offset
          'L' .                            # 32 bits for blue bit length
          'L' .                            # 32 bits for blue msb_right (!0 msb is right)
          'L' .                            # 32 bits for alpha bit offset
          'L' .                            # 32 bits for alpha bit length
          'L' .                            # 32 bits for alpha msb_right (!0 msb is right)
          'L' .                            # 32 bits for nonstd (!0 non standard pixel format)
          'L' .                            # 32 bits for activate
          'L' .                            # 32 bits for height in mm
          'L' .                            # 32 bits for width in mm
          'L' .                            # 32 bits for accel_flags (obsolete)
          'L' .                            # 32 bits for pixclock
          'L' .                            # 32 bits for left margin
          'L' .                            # 32 bits for right margin
          'L' .                            # 32 bits for upper margin
          'L' .                            # 32 bits for lower margin
          'L' .                            # 32 bits for hsync length
          'L' .                            # 32 bits for vsync length
          'L' .                            # 32 bits for sync
          'L' .                            # 32 bits for vmode
          'L' .                            # 32 bits for rotate (angle we rotate counter clockwise)
          'L' .                            # 32 bits for colorspace
          'L4',                            # 32 bits x 4 reserved

        'FBioget_fscreeninfo' => 'A16' .   # 16 bytes for ID name
          'I' .                            # 32/64 bits unsigned address
          'L' .                            # 32 bits for smem_len
          'L' .                            # 32 bits for type
          'L' .                            # 32 bits for type_aux (interleave)
          'L' .                            # 32 bits for visual
          'S' .                            # 16 bits for xpanstep
          'S' .                            # 16 bits for ypanstep
          'S1' .                           # 16 bits for ywrapstep (extra 16 bits added on if system is 8 byte aligned)
          'L' .                            # 32 bits for line length in bytes
          'I' .                            # 32/64 bits for mmio_start
          'L' .                            # 32 bits for mmio_len
          'L' .                            # 32 bits for accel
          'S' .                            # 16 bits for capabilities
          'S2',                            # 16 bits x 2 reserved

        # Default values
        'GARBAGE'     => FALSE,    # Load extra unneeded FB info if true
        'VXRES'       => 640,      # Virtual X resolution
        'VYRES'       => 480,      # Virtual Y resolution
        'BITS'        => 32,       # Bits per pixel
        'BYTES'       => 4,        # Bytes per pixel
        'XOFFSET'     => 0,        # Visible screen X offset
        'YOFFSET'     => 0,        # Visible screen Y offset
        'FB_DEVICE'   => undef,    # Framebuffer device name (defined later)
        'COLOR_ORDER' => 'RGB',    # Default color Order.  Redefined later to be an integer
        'ACCELERATED' => SOFTWARE, # Use accelerated graphics
                                   #   0 = PERL     = Pure Perl
                                   #   1 = SOFTWARE = C Accelerated (but still software)
                                   #   2 = HARDWARE = C & Hardware accelerated.
        'FBIO_WAITFORVSYNC'   => 0x4620,
        'VT_GETSTATE'         => 0x5603,
        'KDSETMODE'           => 0x4B3A,
        'FBIOGET_VSCREENINFO' => 0x4600,    # These come from "fb.h" in the kernel source
        'FBIOGET_FSCREENINFO' => 0x4602,
        @_                         # Pull in the overrides
    };
    if ($self->{'GARBAGE'}) {
        my $garbage = {

            'PIXEL_TYPES'  => [
                'Packed Pixels',
                'Planes',
                'Interleaved Planes',
                'Text',
                'VGA Planes',
            ],
            'PIXEL_TYPES_AUX' => {
                'Packed Pixels' => [
                    '',
                ],
                'Planes' => [
                    '',
                ],
                'Interleaved Planes' => [
                    '',
                ],
                'Text' => [
                    'MDA',
                    'CGA',
                    'S3 MMIO',
                    'MGA Step 16',
                    'MGA Step 8',
                    'SVGA Group',
                    'SVGA Mask',
                    'SVGA Step 2',
                    'SVGA Step 4',
                    'SVGA Step 8',
                    'SVGA Step 16',
                    'SVGA Last',
                ],
                'VGA Planes' => [
                    'VGA 4',
                    'CFB 4',
                    'CFB 8',
                ],
            },
            'VISUAL_TYPES' => [
                'Mono 01',
                'Mono 10',
                'True Color',
                'Pseudo Color',
                'Direct Color',
                'Static Pseudo Color',
            ],
            'ACCEL_TYPES' => [
                'NONE',
                'Atari Blitter',
                'Amiga Blitter',
                'S3 Trio64',
                'NCR 77C32BLT',
                'S3 Virge',
                'ATI Mach 64 GX',
                'ATI DEC TGA',
                'ATI Mach 64 CT',
                'ATI Mach 64 VT',
                'ATI Mach 64 GT',
                'Sun Creator',
                'Sun CG Six',
                'Sun Leo',
                'IWS Twin Turbo',
                '3D Labs Permedia2',
                'Matrox MGA 2064W',
                'Matrox MGA 1064SG',
                'Matrox MGA 2164W',
                'Matrox MGA 2164W AGP',
                'Matrox MGA G100',
                'Matrox MGA G200',
                'Sun CG14',
                'Sun BW Two',
                'Sun CG Three',
                'Sun TCX',
                'Matrox MGA G400',
                'NV3',
                'NV4',
                'NV5',
                'CT 6555x',
                '3DFx Banshee',
                'ATI Rage 128',
                'IGS Cyber 2000',
                'IGS Cyber 2010',
                'IGS Cyber 5000',
                'SIS Glamour',
                '3D Labs Permedia',
                'ATI Radeon',
                'i810',
                'NV 10',
                'NV 20',
                'NV 30',
                'NV 40',
                'XGI Volari V',
                'XGI Volari Z',
                'OMAP i610',
                'Trident TGUI',
                'Trident 3D Image',
                'Trident Blade 3D',
                'Trident Blade XP',
                'Cirrus Alpine',
                'Neomagic NM2070',
                'Neomagic NM2090',
                'Neomagic NM2093',
                'Neomagic NM2097',
                'Neomagic NM2160',
                'Neomagic NM2200',
                'Neomagic NM2230',
                'Neomagic NM2360',
                'Neomagic NM2380',
                'PXA3XX', # 99
                '','','','','','','','','','','','','','','','','','','','','','','','','','','','',
                'Savage 4',
                'Savage 3D',
                'Savage 3D MV',
                'Savage 2000',
                'Savage MX MV',
                'Savage MX',
                'Savage IX MV',
                'Savage IX',
                'Pro Savage PM',
                'Pro Savage KM',
                'S3 Twister P',
                'S3 Twister K',
                'Super Savage',
                'Pro Savage DDR',
                'Pro Savage DDRX',
            ],
            # Unfortunately, these are not IOCTLs.  Gee, that would be nice if they were.  Not Used
            'FBinfo_hwaccel_fillrect'  => 'L6',      # dx(32),dy(32),width(32),height(32),color(32),rop(32)?
            'FBinfo_hwaccel_copyarea'  => 'L6',      # dx(32),dy(32),width(32),height(32),sx(32),sy(32)
            'FBinfo_hwaccel_fillrect'  => 'L6',      # dx(32),dy(32),width(32),height(32),color(32),rop(32)
            'FBinfo_hwaccel_imageblit' => 'L6CL',    # dx(32),dy(32),width(32),height(32),fg_color(32),bg_color(32),depth(8),image pointer(32),color map pointer(32)
                                                     # COLOR MAP:
                                                     #   start(32),length(32),red(16),green(16),blue(16),alpha(16)
            # FLAGS
            'FBINFO_HWACCEL_NONE'      => 0x0000,    # These come from "fb.h" in the kernel source.  Not Used
            'FBINFO_HWACCEL_COPYAREA'  => 0x0100,
            'FBINFO_HWACCEL_FILLRECT'  => 0x0200,
            'FBINFO_HWACCEL_IMAGEBLIT' => 0x0400,
            'FBINFO_HWACCEL_ROTATE'    => 0x0800,
            'FBINFO_HWACCEL_XPAN'      => 0x1000,
            'FBINFO_HWACCEL_YPAN'      => 0x2000,
            'FBINFO_HWACCEL_YWRAP'     => 0x4000,

            ## Set up the Framebuffer driver "constants" defaults
            # Commands
            'FBIOPUT_VSCREENINFO' => 0x4601,
            'FBIOGETCMAP'         => 0x4604,
            'FBIOPUTCMAP'         => 0x4605,
            'FBIOPAN_DISPLAY'     => 0x4606,
            'FBIO_CURSOR'         => 0x4608,
            'FBIOGET_CON2FBMAP'   => 0x460F,
            'FBIOPUT_CON2FBMAP'   => 0x4610,
            'FBIOBLANK'           => 0x4611,
            'FBIOGET_VBLANK'      => 0x4612,
            'FBIOGET_GLYPH'       => 0x4615,
            'FBIOGET_HWCINFO'     => 0x4616,
            'FBIOPUT_MODEINFO'    => 0x4617,
            'FBIOGET_DISPINFO'    => 0x4618,
        };
        $self = { %{$self},%{$garbage} };
    }
    unless (defined($self->{'FB_DEVICE'})) {     # We scan for all 32 possible devices at both possible locations
        foreach my $dev (0 .. 31) {
            foreach my $prefix (qw(/dev/fb /dev/fb/ /dev/graphics/fb)) {
                if (-e "$prefix$dev") {
                    $self->{'FB_DEVICE'} = "$prefix$dev";
                    last;
                }
            }
            last if (defined($self->{'FB_DEVICE'}));
        }
    }
    $self->{'CONSOLE'} = 1;
    eval {
        $self->{'CONSOLE'}      = _slurp('/sys/class/tty/tty0/active');
        $self->{'CONSOLE'}     =~ s/\D+//gs;
        $self->{'CONSOLE'}     += 0;
        $self->{'THIS_CONSOLE'} = $self->{'CONSOLE'};
    };
    my $has_X = FALSE;
    $has_X = TRUE if (defined($ENV{'DISPLAY'}) && $self->{'IGNORE_X_WINDOWS'} == FALSE);
    if ( (! $has_X) && defined($self->{'FB_DEVICE'}) && (-e $self->{'FB_DEVICE'}) && open($self->{'FB'}, '+<', $self->{'FB_DEVICE'})) {    # Can we open the framebuffer device??
        binmode($self->{'FB'});                                                                                                                            # We have to be in binary mode first
        $|++;
        if ($self->{'ACCELERATED'}) {
            (
                $self->{'fscreeninfo'}->{'id'},
                $self->{'fscreeninfo'}->{'smem_start'},
                $self->{'fscreeninfo'}->{'smem_len'},
                $self->{'fscreeninfo'}->{'type'},
                $self->{'fscreeninfo'}->{'type_aux'},
                $self->{'fscreeninfo'}->{'visual'},
                $self->{'fscreeninfo'}->{'xpanstep'},
                $self->{'fscreeninfo'}->{'ypanstep'},
                $self->{'fscreeninfo'}->{'ywrapstep'},
                $self->{'fscreeninfo'}->{'line_length'},
                $self->{'fscreeninfo'}->{'mmio_start'},
                $self->{'fscreeninfo'}->{'mmio_len'},
                $self->{'fscreeninfo'}->{'accel'},

                $self->{'vscreeninfo'}->{'xres'},
                $self->{'vscreeninfo'}->{'yres'},
                $self->{'vscreeninfo'}->{'xres_virtual'},
                $self->{'vscreeninfo'}->{'yres_virtual'},
                $self->{'vscreeninfo'}->{'xoffset'},
                $self->{'vscreeninfo'}->{'yoffset'},
                $self->{'vscreeninfo'}->{'bits_per_pixel'},
                $self->{'vscreeninfo'}->{'grayscale'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'msb_right'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'msb_right'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'msb_right'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'length'},
                $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'msb_right'},
                $self->{'vscreeninfo'}->{'nonstd'},
                $self->{'vscreeninfo'}->{'activate'},
                $self->{'vscreeninfo'}->{'height'},
                $self->{'vscreeninfo'}->{'width'},
                $self->{'vscreeninfo'}->{'accel_flags'},
                $self->{'vscreeninfo'}->{'pixclock'},
                $self->{'vscreeninfo'}->{'left_margin'},
                $self->{'vscreeninfo'}->{'right_margin'},
                $self->{'vscreeninfo'}->{'upper_margin'},
                $self->{'vscreeninfo'}->{'lower_margin'},
                $self->{'vscreeninfo'}->{'hsync_len'},
                $self->{'vscreeninfo'}->{'vsync_len'},
                $self->{'vscreeninfo'}->{'sync'},
                $self->{'vscreeninfo'}->{'vmode'},
                $self->{'vscreeninfo'}->{'rotate'},
            ) = (c_get_screen_info($self->{'FB_DEVICE'}));
        } else { # Fallback if not accelerated.  Do it the old way
            # Make the IOCTL call to get info on the virtual (viewable) screen (Sometimes different than physical)
            (
                $self->{'vscreeninfo'}->{'xres'},                                # (32)
                $self->{'vscreeninfo'}->{'yres'},                                # (32)
                $self->{'vscreeninfo'}->{'xres_virtual'},                        # (32)
                $self->{'vscreeninfo'}->{'yres_virtual'},                        # (32)
                $self->{'vscreeninfo'}->{'xoffset'},                             # (32)
                $self->{'vscreeninfo'}->{'yoffset'},                             # (32)
                $self->{'vscreeninfo'}->{'bits_per_pixel'},                      # (32)
                $self->{'vscreeninfo'}->{'grayscale'},                           # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'},      # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'},      # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'msb_right'},   # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'},    # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'},    # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'msb_right'}, # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'},     # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'},     # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'msb_right'},  # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'},    # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'length'},    # (32)
                $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'msb_right'}, # (32)
                $self->{'vscreeninfo'}->{'nonstd'},                              # (32)
                $self->{'vscreeninfo'}->{'activate'},                            # (32)
                $self->{'vscreeninfo'}->{'height'},                              # (32)
                $self->{'vscreeninfo'}->{'width'},                               # (32)
                $self->{'vscreeninfo'}->{'accel_flags'},                         # (32)
                $self->{'vscreeninfo'}->{'pixclock'},                            # (32)
                $self->{'vscreeninfo'}->{'left_margin'},                         # (32)
                $self->{'vscreeninfo'}->{'right_margin'},                        # (32)
                $self->{'vscreeninfo'}->{'upper_margin'},                        # (32)
                $self->{'vscreeninfo'}->{'lower_margin'},                        # (32)
                $self->{'vscreeninfo'}->{'hsync_len'},                           # (32)
                $self->{'vscreeninfo'}->{'vsync_len'},                           # (32)
                $self->{'vscreeninfo'}->{'sync'},                                # (32)
                $self->{'vscreeninfo'}->{'vmode'},                               # (32)
                $self->{'vscreeninfo'}->{'rotate'},                              # (32)
                $self->{'vscreeninfo'}->{'colorspace'},                          # (32)
                @{ $self->{'vscreeninfo'}->{'reserved_fb_vir'} }                 # (32) x 4
            ) = _get_ioctl(FBIOGET_VSCREENINFO, $self->{'FBioget_vscreeninfo'}, $self->{'FB'});
            # Make the IOCTL call to get info on the physical screen
            my $extra = 1;
            do { # A hacked way to do this, but it seems to work
                my $typedef = '' . $self->{'FBioget_fscreeninfo'};
                if ($extra > 1) { # It turns out it was byte alignment issues, not driver weirdness
                    if ($extra == 2) {
                        $typedef =~ s/S1/S$extra/;
                    } elsif ($extra == 3) {
                        $typedef =~ s/S1/L/;
                    } elsif ($extra == 4) {
                        $typedef =~ s/S1/I/;
                    }
                    (
                        $self->{'fscreeninfo'}->{'id'},                   # (8) x 16
                        $self->{'fscreeninfo'}->{'smem_start'},           # LONG
                        $self->{'fscreeninfo'}->{'smem_len'},             # (32)
                        $self->{'fscreeninfo'}->{'type'},                 # (32)
                        $self->{'fscreeninfo'}->{'type_aux'},             # (32)
                        $self->{'fscreeninfo'}->{'visual'},               # (32)
                        $self->{'fscreeninfo'}->{'xpanstep'},             # (16)
                        $self->{'fscreeninfo'}->{'ypanstep'},             # (16)
                        $self->{'fscreeninfo'}->{'ywrapstep'},            # (16)
                        $self->{'fscreeninfo'}->{'filler'},               # (16) - Just a filler
                        $self->{'fscreeninfo'}->{'line_length'},          # (32)
                        $self->{'fscreeninfo'}->{'mmio_start'},           # LONG
                        $self->{'fscreeninfo'}->{'mmio_len'},             # (32)
                        $self->{'fscreeninfo'}->{'accel'},                # (32)
                        $self->{'fscreeninfo'}->{'capailities'},          # (16)
                        @{ $self->{'fscreeninfo'}->{'reserved_fb_phys'} } # (16) x 2
                    ) = _get_ioctl(FBIOGET_FSCREENINFO, $typedef, $self->{'FB'});
            } else {
                (
                    $self->{'fscreeninfo'}->{'id'},                   # (8) x 16
                    $self->{'fscreeninfo'}->{'smem_start'},           # LONG
                    $self->{'fscreeninfo'}->{'smem_len'},             # (32)
                    $self->{'fscreeninfo'}->{'type'},                 # (32)
                    $self->{'fscreeninfo'}->{'type_aux'},             # (32)
                    $self->{'fscreeninfo'}->{'visual'},               # (32)
                    $self->{'fscreeninfo'}->{'xpanstep'},             # (16)
                    $self->{'fscreeninfo'}->{'ypanstep'},             # (16)
                    $self->{'fscreeninfo'}->{'ywrapstep'},            # (16)
                    $self->{'fscreeninfo'}->{'line_length'},          # (32)
                    $self->{'fscreeninfo'}->{'mmio_start'},           # LONG
                    $self->{'fscreeninfo'}->{'mmio_len'},             # (32)
                    $self->{'fscreeninfo'}->{'accel'},                # (32)
                    $self->{'fscreeninfo'}->{'capailities'},          # (16)
                    @{ $self->{'fscreeninfo'}->{'reserved_fb_phys'} } # (16) x 2
                ) = _get_ioctl(FBIOGET_FSCREENINFO, $typedef, $self->{'FB'});
            }

            $extra++;
            } until (($self->{'fscreeninfo'}->{'line_length'} < $self->{'fscreeninfo'}->{'smem_len'} && $self->{'fscreeninfo'}->{'line_length'} > 0) || $extra > 4);
        }
        $self->{'fscreeninfo'}->{'id'} =~ s/[\x00-\x1F,\x7F-\xFF]//gs;
        if ($self->{'fscreeninfo'}->{'id'} eq '') {
            chomp(my $model = `cat /proc/device-tree/model`);
            $model =~ s/[\x00-\x1F,\x7F-\xFF]//gs;
            if ($model ne '') {
                $self->{'fscreeninfo'}->{'id'} = $model;
            } else {
                $self->{'fscreeninfo'}->{'id'} = $self->{'FB_DEVICE'};
            }
        }

        $self->{'GPU'}            = $self->{'fscreeninfo'}->{'id'};             # The name of the GPU or video driver
        $self->{'VXRES'}          = $self->{'vscreeninfo'}->{'xres_virtual'};   # The virtual width of the screen
        $self->{'VYRES'}          = $self->{'vscreeninfo'}->{'yres_virtual'};   # The virtual height of the screen
        $self->{'XRES'}           = $self->{'vscreeninfo'}->{'xres'};           # The physical width of the screen
        $self->{'YRES'}           = $self->{'vscreeninfo'}->{'yres'};           # The physical height of the screen
        $self->{'XOFFSET'}        = $self->{'vscreeninfo'}->{'xoffset'} || 0;   # The horizontal offset of the screen from the beginning of the virtual screen
        $self->{'YOFFSET'}        = $self->{'vscreeninfo'}->{'yoffset'} || 0;   # The vertical offset of the screen from the beginning of the virtual screen
        $self->{'BITS'}           = $self->{'vscreeninfo'}->{'bits_per_pixel'}; # The bits per pixel of the screen
        $self->{'BYTES'}          = $self->{'BITS'} / 8;                        # The number of bytes per pixel
        $self->{'BYTES_PER_LINE'} = $self->{'fscreeninfo'}->{'line_length'};    # The length of a single scan line in bytes
        $self->{'PIXELS'}                    = (($self->{'XOFFSET'} + $self->{'VXRES'}) * ($self->{'YOFFSET'} + $self->{'VYRES'}));
        $self->{'SIZE'}                      = $self->{'PIXELS'} * $self->{'BYTES'};
        $self->{'fscreeninfo'}->{'smem_len'} = $self->{'BYTES_PER_LINE'} * $self->{'VYRES'} if (!defined($self->{'fscreeninfo'}->{'smem_len'}) || $self->{'fscreeninfo'}->{'smem_len'} <= 0);

        $self->{'fscreeninfo'}->{'type'}     = $self->{'PIXEL_TYPES'}->[$self->{'fscreeninfo'}->{'type'}];
        $self->{'fscreeninfo'}->{'type_aux'} = $self->{'PIXEL_TYPES_AUX'}->{$self->{'fscreeninfo'}->{'type'}}->[$self->{'fscreeninfo'}->{'type_aux'}];
        $self->{'fscreeninfo'}->{'visual'}   = $self->{'VISUAL_TYPES'}->[$self->{'fscreeninfo'}->{'visual'}];
        $self->{'fscreeninfo'}->{'accel'}    = $self->{'ACCEL_TYPES'}->[$self->{'fscreeninfo'}->{'accel'}];

        if ($self->{'BITS'} == 32 && $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'length'} == 0) {
            # The video driver doesn't use the alpha channel, but we do, so force it.
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'length'} = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        }
        ## For debugging only
        # print Dumper($self,\%Config),"\n"; exit;

        # Only useful for debugging and for troubleshooting the module for specific display resolutions
        if (defined($self->{'SIMULATED_X'})) {
            my $w = $self->{'XRES'};
            $self->{'XRES'}     = $self->{'SIMULATED_X'};
            $self->{'XOFFSET'} += ($w - $self->{'SIMULATED_X'}) / 2;
        }
        if (defined($self->{'SIMULATED_Y'})) {
            my $h = $self->{'YRES'};
            $self->{'YRES'}     = $self->{'SIMULATED_Y'};
            $self->{'YOFFSET'} += ($h - $self->{'SIMULATED_Y'}) / 2;
        }
        bless($self, $class);
        $self->_color_order();                                # Automatically determine color mode
        $self->attribute_reset();

        # Now that everything is set up, let's map the framebuffer to SCREEN

        eval { # We use the more stable File::Map now
            $self->{'SCREEN_ADDRESS'} = map_handle(
                $self->{'SCREEN'},
                $self->{'FB'},
                '+<',
                0,
                $self->{'fscreeninfo'}->{'smem_len'},
            );
        };
        if ($@) {
            print STDERR qq{
OUCH!  Graphics::Framebuffer cannot memory map the framebuffer!

This is usually caused by one or more of the following:

  *  Your account does not have proper permission to access the framebuffer
     device.

     This usually requires adding the "video" group to your account.  This is
     usually accomplished via the following command (replace "username" with
     your actual username):

\tsudo usermod -a -G video username

  *  You could be attempting to run this inside X-Windows/Wayland, which
	 doesn't work.  You MUST run your script outside of X-Windows from the
     system Console.  If you are inside X-Windows/Wayland, and you do not know
     how to get to your console, just hit CTRL-ALT-F5 to access one of the
     consoles.  This has no windows or mouse functionality.  It is command
     line only (similar to old DOS).

     To get back into X-Windows/Wayland, you just hit ALT-F1 (or ALT-F8 or
	 ALT-F7 on some systems).  Linux can have many consoles, which are
     usually mapped F1 to F9.  One of them is set aside for X-Windows/Wayland.

Actual error reported:\n\n$@\n};
            sleep ($self->{'RESET'}) ? 10 : 1;
            exit(1);
        }
    } elsif (exists($ENV{'DISPLAY'}) && (-e $self->{'FB_DEVICE'})) {
        print STDERR qq{
OUCH!  Graphics::Framebuffer cannot memory map the framebuffer!

You are attempting to run this inside X-Windows/Wayland, which doesn't work.
You MUST run your script outside of X-Windows from the system Console.  If
you are inside X-Windows/Wayland, and you do not know how to get to your
console, just hit CTRL-ALT-F5 to access one of the consoles.  This has no
windows or mouse functionality.  It is command line only (similar to old
DOS).

To get back into X-Windows/Wayland, you just hit ALT-F1 (or ALT-F7 or ALT-F8
on some systems).  Linux can have many consoles, which are usually mapped F1
to F9.  One of them is set aside for X-Windows/Wayland.
};
        sleep ($self->{'RESET'}) ? 10 : 1;
        exit(1);
    } else { # Go into emulation mode if no actual framebuffer available
        $self->{'FB_DEVICE'}   = 'EMULATED';
        $self->{'SPLASH'}      = FALSE;
        $self->{'RESET'}       = FALSE;
        $self->{'ERROR'}       = 'Framebuffer Device Not Found! Emulation mode.  EXPERIMENTAL!!';
        $self->{'COLOR_ORDER'} = $self->{ uc($self->{'COLOR_ORDER'}) };    # Translate the color order

        $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'}      = 8;
        $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'msb_right'}   = 0;
        $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'}    = 8;
        $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'msb_right'} = 0;
        $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'}     = 8;
        $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'msb_right'}  = 0;
        $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'length'}    = 8;
        $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'msb_right'} = 0;

        if ($self->{'COLOR_ORDER'} == BGR) {
            $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}   = 16;
            $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'} = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}  = 0;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        } elsif ($self->{'COLOR_ORDER'} == RGB) {
            $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}   = 0;
            $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'} = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}  = 16;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        } elsif ($self->{'COLOR_ORDER'} == BRG) {
            $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}   = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'} = 16;
            $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}  = 0;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        } elsif ($self->{'COLOR_ORDER'} == RBG) {
            $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}   = 0;
            $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'} = 16;
            $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}  = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        } elsif ($self->{'COLOR_ORDER'} == GRB) {
            $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}   = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'} = 0;
            $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}  = 16;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        } elsif ($self->{'COLOR_ORDER'} == GBR) {
            $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}   = 16;
            $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'} = 0;
            $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}  = 8;
            $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'} = 24;
        }

        # Set the resolution.  Either the defaults, or whatever the user passed in.

        $self->{'SCREEN'}                    = chr(0) x ($self->{'VXRES'} * $self->{'VYRES'} * $self->{'BYTES'}); # This is the fake framebuffer
        $self->{'XRES'}                      = $self->{'VXRES'};                                                  # Virtual and physical are the same
        $self->{'YRES'}                      = $self->{'VYRES'};
        $self->{'XOFFSET'}                   = 0;
        $self->{'YOFFSET'}                   = 0;
        $self->{'PIXELS'}                    = (($self->{'XOFFSET'} + $self->{'VXRES'}) * ($self->{'YOFFSET'} + $self->{'VYRES'}));
        $self->{'SIZE'}                      = $self->{'PIXELS'} * $self->{'BYTES'};
        $self->{'fscreeninfo'}->{'id'}       = 'Virtual Framebuffer';
        $self->{'GPU'}                       = $self->{'fscreeninfo'}->{'id'};
        $self->{'fscreeninfo'}->{'smem_len'} = $self->{'BYTES'} * ($self->{'VXRES'} * $self->{'VYRES'}) if (!defined($self->{'fscreeninfo'}->{'smem_len'}) || $self->{'fscreeninfo'}->{'smem_len'} <= 0);
        $self->{'BYTES_PER_LINE'}            = int($self->{'fscreeninfo'}->{'smem_len'} / $self->{'VYRES'});

        bless($self, $class);
    }
    $self->{'MIN_BYTES'} = max(3,$self->{'BYTES'});
    $self->{'X_FACTOR'} = 3840 / $self->{'XRES'};
    $self->{'Y_FACTOR'} = 2160 / $self->{'YRES'};
    if ($self->{'RESET'}) {
        $SIG{'QUIT'} = $SIG{'INT'} = $SIG{'KILL'} = \&_reset;
    }
    $self->_gather_fonts('/usr/share/fonts');
    # Loop and find the default font.  One of these should work for Debian and Redhat variants.
    foreach my $font (qw(FreeSans Ubuntu-R Arial Oxygen-Sans Garuda LiberationSans-Regular Loma Helvetica)) {
        if (exists($self->{'FONTS'}->{$font})) {
            $self->{'FONT_PATH'} = $self->{'FONTS'}->{$font}->{'path'};
            $self->{'FONT_FACE'} = $self->{'FONTS'}->{$font}->{'font'};
            last;
        }
    }
    $self->_flush_screen();
    unless($self->{'RESET'}) {
		$self->{'START_SCREEN'} = ''. $self->{'SCREEN'}; # Force Perl to copy the string, not the reference
	}
    chomp($self->{'this_tty'} = `tty`);
    if ($self->{'SPLASH'} > 0) {
        $self->splash($VERSION);
        sleep $self->{'SPLASH'};
    }
    $self->attribute_reset();
    if (wantarray) { # For the temporarily supported (but no longer) double buffering mode
        return ($self, $self); # For those that coded for double buffering
    }
    return ($self);
}

sub _reset {
    system('reset');
}

sub _fix_mapping { # File::Map SHOULD make this obsolete
    # Fixes the mapping if Perl garbage collects (naughty Perl)
    my $self = shift;
    unmap($self->{'SCREEN'}); # Unmap missing on some File::Maps
    unless (defined($self->{'FB'})) {
        eval { close($self->{'FB'}); };
        open($self->{'FB'}, '+<', $self->{'FB_DEVICE'});
        binmode($self->{'FB'});
        $self->_flush_screen();
    }
    $self->{'MAP_ATTEMPTS'}++;
    # We don't eval, because it worked originally
    $self->{'SCREEN_ADDRESS'} = map_handle($self->{'SCREEN'}, $self->{'FB'}, '+<', 0, $self->{'fscreeninfo'}->{'smem_len'});
}

sub _color_order {
    # Determine the color order the video card uses
    my $self = shift;

    my $ro = $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'};
    my $go = $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'};
    my $bo = $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'};

    if ($ro < $go && $go < $bo) {
        $self->{'COLOR_ORDER'} = RGB;
    } elsif ($bo < $go && $go < $ro) {
        $self->{'COLOR_ORDER'} = BGR;
    } elsif ($go < $ro && $ro < $bo) {
        $self->{'COLOR_ORDER'} = GRB;
    } elsif ($go < $bo && $bo < $ro) {
        $self->{'COLOR_ORDER'} = GBR;
    } elsif ($bo < $ro && $ro < $go) {
        $self->{'COLOR_ORDER'} = BRG;
    } elsif ($ro < $bo && $bo < $go) {
        $self->{'COLOR_ORDER'} = RBG;
    } else {
        # UNKNOWN - default to RGB
        $self->{'COLOR_ORDER'} = RGB;
    }
}

sub _screen_close {
    my $self = shift;
    unless (defined($self->{'ERROR'})) {    # Only do it if not in emulation mode
        unmap($self->{'SCREEN'}) if (defined($self->{'SCREEN'})); # unmap had issues with File::Map.
        close($self->{'FB'})     if (defined($self->{'FB'}));
        delete($self->{'FB'});              # We leave no remnants
    }
    delete($self->{'SCREEN'});
}

sub text_mode {
=head2 text_mode

Sets the TTY into text mode, where text can interfere with the display

=cut

    my $self = shift;
    c_text_mode($self->{'this_tty'});
}

sub graphics_mode {
=head2 graphics_mode

Sets the TTY in exclusive graphics mode, where text and cursor cannot interfere with the display.  Please remember, you must call text_mode before exiting, else your console will not show any text!

=cut

    my $self = shift;
    c_graphics_mode($self->{'this_tty'});
}

sub screen_dimensions {
=head2 screen_dimensions

When called in an array/list context:

Returns the size and nature of the framebuffer in X,Y pixel values.

It also returns the bits per pixel.

=over 4

 my ($width,$height,$bits_per_pixel) = $fb->screen_dimensions();

=back

When called in a scalar context, it returns a hash reference:

=over 4

 {
     'width'          => pixel width of physical screen,
     'height'         => pixel height of physical screen,
     'bits_per_pixel' => bits per pixel (16, 24, or 32),
     'bytes_per_line' => Number of bytes per scan line,
     'top_clip'       => top edge of clipping rectangle (Y),
     'left_clip'      => left edge of clipping rectangle (X),
     'bottom_clip'    => bottom edge of clipping rectangle (YY),
     'right_clip'     => right edge of clipping rectangle (XX),
     'width_clip'     => width of clipping rectangle,
     'height_clip'    => height of clipping rectangle,
     'color_order'    => RGB, BGR, etc,
 }

=back

=cut

    my $self = shift;
    if (wantarray) {
        return ($self->{'XRES'}, $self->{'YRES'}, $self->{'BITS'});
    } else {
        return (
            {
                'width'          => $self->{'XRES'},
                'height'         => $self->{'YRES'},
                'bits_per_pixel' => $self->{'BITS'},
                'bytes_per_line' => $self->{'BYTES_PER_LINE'},
                'top_clip'       => $self->{'Y_CLIP'},
                'left_clip'      => $self->{'X_CLIP'},
                'bottom_clip'    => $self->{'YY_CLIP'},
                'right_clip'     => $self->{'XX_CLIP'},
                'clip_width'     => $self->{'W_CLIP'},
                'clip_height'    => $self->{'H_CLIP'},
                'color_order'    => $COLORORDER[$self->{'COLOR_ORDER'}],
            }
        );
    }
}

# Splash is now pulled in via "Graphics::Framebuffer::Splash"

=head2 splash

Displays the Splash screen.  It automatically scales and positions to the clipping region.

This is automatically displayed when this module is initialized, and the variable 'SPLASH' is true (which is the default).

=over 4

 $fb->splash();

=back
=cut

sub get_font_list {
=head2 get_font_list

Returns an anonymous hash containing the font face names as keys and another anonymous hash assigned as the values for each key. This second hash contains the path to the font and the font's file name.

=over 4

 'face name' => {
      'path' => 'path to font',
      'font' => 'file name of font'
 },
 ... The rest of the system fonts here

=back

You may also pass in a face name and it will return that face's information:

=over 4

 my $font_info = $fb->get_font_list('DejaVuSerif');

=back

Would return something like:

=over 4

 {
     'font' => 'dejavuserif.ttf',
     'path' => '/usr/share/fonts/truetype/'
 }

=back

When passing a name, it will return a hash reference (if only one match), or an array reference of hashes of fonts matching that name.  Passing in "Arial" would return the font information for "Arial Black", "Arial Narrow", and "Arial Rounded" (if they are installed on your system).

=cut

    my $self     = shift;
    my ($filter) = @_;

    my $fonts;
    if ($filter) {
        foreach my $font (sort(keys %{ $self->{'FONTS'} })) {
            if ($font =~ /$filter/i) {
                push(@{$fonts}, $self->{'FONTS'}->{$font});
            }
        }
        if (defined($fonts) && scalar(@{$fonts}) == 1) {
            return ($fonts->[0]);
        } else {
            return ($fonts);
        }
    }
    return ($self->{'FONTS'});
}

sub draw_mode {
=head2 draw_mode

Sets or returns the drawing mode, depending on how it is called.

=over 4

 my $draw_mode = $fb->draw_mode(); # Returns the current
                                   # Drawing mode.

 # Modes explained.  These settings are global

                                   # When you draw it...

 $fb->draw_mode(NORMAL_MODE);      # Replaces the screen pixel
                                   # with the new pixel. Imager
                                   # assisted drawing (acceleration)
                                   # only works in this mode.

 $fb->draw_mode(XOR_MODE);         # Does a bitwise XOR with
                                   # the new pixel and screen
                                   # pixel.

 $fb->draw_mode(OR_MODE);          # Does a bitwise OR with
                                   # the new pixel and screen
                                   # pixel.

 $fb->draw_mode(AND_MODE);         # Does a bitwise AND with
                                   # the new pixel and screen
                                   # pixel.

 $fb->draw_mode(MASK_MODE);        # If pixels in the source
                                   # are equal to the global
                                   # background color, then they
                                   # are not drawn (transparent).

 $fb->draw_mode(UNMASK_MODE);      # Draws the new pixel on
                                   # screen areas only equal to
                                   # the background color.

 $fb->draw_mode(ALPHA_MODE);       # Draws the new pixel on the screen
                                   # using the alpha channel value as
                                   # a transparency value.  This means
                                   # the new pixel will not be
                                   # opague.

 $fb->draw_mode(ADD_MODE);         # Draws the new pixel on the screen
                                   # by mathematically adding its pixel
                                   # value to the existing pixel value

 $fb->draw_mode(SUBTRACT_MODE);    # Draws the new pixel on the screen
                                   # by mathematically subtracting the
                                   # the new pixel value from the existing
                                   # value

 $fb->draw_mode(MULTIPLY_MODE);    # Draws the new pixel on the screen
                                   # by mathematically multiplying it with
                                   # the existing pixel value (usually not
                                   # too useful, but here for completeness)

 $fb->draw_mode(DIVIDE_MODE);      # Draws the new pixel on the screen
                                   # by mathematically dividing it with the
                                   # existing pixel value (usually not too
                                   # useful, but here for completeness)

=back
=cut

    my $self = shift;
    if (@_) {
        my $mode = int(shift);
        # If not a valid value, then it defaults to normal mode
        $self->{'DRAW_MODE'} = ($mode <= 10 && $mode >= 0) ? $mode : NORMAL_MODE;
    } else {
        return ($self->{'DRAW_MODE'});
    }
}

sub normal_mode {
=head2 normal_mode

This is an alias to draw_mode(NORMAL_MODE)

=over 4

 $fb->normal_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(NORMAL_MODE);
}

sub xor_mode {
=head2 xor_mode

This is an alias to draw_mode(XOR_MODE)

=over 4

 $fb->xor_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(XOR_MODE);
}

sub or_mode {
=head2 or_mode

This is an alias to draw_mode(OR_MODE)

=over 4

 $fb->or_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(OR_MODE);
}

sub alpha_mode {
=head2 alpha_mode

This is an alias to draw_mode(ALPHA_MODE)

=over 4

 $fb->alpha_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(ALPHA_MODE);
}

sub and_mode {
=head2 and_mode

This is an alias to draw_mode(AND_MODE)

=over 4

 $fb->and_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(AND_MODE);
}

sub mask_mode {
=head2 mask_mode

This is an alias to draw_mode(MASK_MODE)

=over 4

 $fb->mask_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(MASK_MODE);
}

sub unmask_mode {
=head2 unmask_mode

This is an alias to draw_mode(UNMASK_MODE)

=over 4

 $fb->unmask_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(UNMASK_MODE);
}

sub add_mode {
=head2 add_mode

This is an alias to draw_mode(ADD_MODE)

=over 4

 $fb->add_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(ADD_MODE);
}

sub subtract_mode {
=head2 subtract_mode

This is an alias to draw_mode(SUBTRACT_MODE)

=over 4

 $fb->subtract_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(SUBTRACT_MODE);
}

sub multiply_mode {
=head2 multiply_mode

This is an alias to draw_mode(MULTIPLY_MODE)

=over 4

 $fb->multiply_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(MULTIPLY_MODE);
}

sub divide_mode {
=head2 divide_mode

This is an alias to draw_mode(DIVIDE_MODE)

=over 4

 $fb->divide_mode();

=back

=cut

    my $self = shift;
    $self->draw_mode(DIVIDE_MODE);
}

sub clear_screen {
=head2 clear_screen

Fills the entire screen with the background color

You can add an optional parameter to turn the console cursor on or off too.

=over 4

 $fb->clear_screen();      # Leave cursor as is.
 $fb->clear_screen('OFF'); # Turn cursor OFF (Does nothing with emulated framebuffer mode).
 $fb->clear_screen('ON');  # Turn cursor ON (Does nothing with emulated framebuffer mode).

=back

=cut

    # Fills the entire screen with the background color fast #
    my $self   = shift;
    my $cursor = shift || '';

    unless($self->{'DEVICE'} eq 'EMULATED') { # We only do this stuff to real framebuffers
        if ($cursor =~ /off/i) {
            system('clear && tput civis');
        } elsif ($cursor =~ /on/i) {
            system('tput cnorm && clear');
        }
        select(STDOUT);
        $|++;
    }
    if ($self->{'CLIPPED'}) {
        my $w = $self->{'W_CLIP'};
        my $h = $self->{'H_CLIP'};
        $self->blit_write({ 'x' => $self->{'X_CLIP'}, 'y' => $self->{'Y_CLIP'}, 'width' => $w, 'height' => $h, 'image' => $self->{'RAW_BACKGROUND_COLOR'} x ($w * $h) }, 0);
    } else {
        substr($self->{'SCREEN'}, 0) = $self->{'RAW_BACKGROUND_COLOR'} x ($self->{'fscreeninfo'}->{'smem_len'} / $self->{'BYTES'});
    }
    $self->_flush_screen();
}

sub cls {
=head2 cls

This is an alias to 'clear_screen'

=cut

    my $self = shift;
    $self->clear_screen(@_);
}

sub attribute_reset {
=head2 attribute_reset

Resets the plot point at 0,0.  Resets clipping to the current screen size.  Resets the global color to whatever 'FOREGROUND' is set to, and the global background color to whatever 'BACKGROUND' is set to, and resets the drawing mode to NORMAL.

=over 4

 $fb->attribute_reset();

=back

=cut

    my $self = shift;

    $self->{'X'} = 0;
    $self->{'Y'} = 0;
    $self->set_color({ %{ $self->{'FOREGROUND'} } });
    $self->{'DRAW_MODE'} = NORMAL_MODE;
    $self->set_b_color({ %{ $self->{'BACKGROUND'} } });
    $self->clip_reset;
}

sub plot {
=head2 plot

Set a single pixel in the set foreground color at position x,y with the given pixel size (or default).  Clipping applies.

With 'pixel_size', if a positive number greater than 1, is drawn with square pixels.  If it's a negative number, then it's drawn with round pixels.  Square pixels are much faster.

=over 4

 $fb->plot(
     {
         'x'          => 20,
         'y'          => 30,
         'pixel_size' => 3
     }
 );

=back

=cut

    my $self   = shift;
    my $params = shift;

    my $x    = int($params->{'x'} || 0);            # Ignore decimals
    my $y    = int($params->{'y'} || 0);
    my $size = int($params->{'pixel_size'} || 1);
    my $c;
	my $index;
	my $bytes = $self->{'BYTES'};
	my $color_alpha = $self->{'COLOR_ALPHA'};
    if (abs($size) > 1) {
        if ($size < -1) {
            $size = abs($size);
            $self->circle({ 'x' => $x, 'y' => $y, 'radius' => ($size / 2), 'filled' => 1, 'pixel_size' => 1 });
        } else {
            $self->rbox({ 'x' => $x - ($width / 2), 'y' => $y - ($height / 2), 'width' => $size, 'height' => $size, 'filled' => TRUE, 'pixel_size' => 1 });
        }
    } elsif ($self->{'ACCELERATED'}) {
        c_plot(
            $self->{'SCREEN'},
            $x, $y,
            $self->{'X_CLIP'},  $self->{'Y_CLIP'}, $self->{'XX_CLIP'}, $self->{'YY_CLIP'},
            $self->{'INT_RAW_FOREGROUND_COLOR'},
            $self->{'INT_RAW_BACKGROUND_COLOR'},
            $color_alpha,
            $self->{'DRAW_MODE'},
            $bytes,
            $self->{'BITS'},
            $self->{'BYTES_PER_LINE'},
            $self->{'XOFFSET'}, $self->{'YOFFSET'},
        );
    } else {
		my $raw_foreground_color = $self->{'RAW_FOREGROUND_COLOR'};
		my $raw_background_color = $self->{'RAW_BACKGROUND_COLOR'};
		my $draw_mode            = $self->{'DRAW_MODE'};
        # Only plot if the pixel is within the clipping region
        unless (($x > $self->{'XX_CLIP'}) || ($y > $self->{'YY_CLIP'}) || ($x < $self->{'X_CLIP'}) || ($y < $self->{'Y_CLIP'})) {
            # The 'history' is a 'draw_arc' optimization and beautifier for xor mode.  It only draws pixels not in
            # the history buffer.
            unless (exists($self->{'history'}) && defined($self->{'history'}->{$y}->{$x})) {
                $index = ($self->{'BYTES_PER_LINE'} * ($y + $self->{'YOFFSET'})) + (($self->{'XOFFSET'} + $x) * $bytes);
                if ($index >= 0 && $index <= ($self->{'fscreeninfo'}->{'smem_len'} - $bytes)) {
                        $c = substr($self->{'SCREEN'}, $index, $self->{'BYTES'}) || chr(0) x $bytes;
                        if ($draw_mode == NORMAL_MODE) {
                            $c  = $raw_foreground_color;
                        } elsif ($draw_mode == XOR_MODE) {
                            $c ^= $raw_foreground_color;
                        } elsif ($draw_mode == OR_MODE) {
                            $c |= $raw_foreground_color;
                        } elsif ($draw_mode == ALPHA_MODE) {
                            my $back  = $self->get_pixel({ 'x' => $x, 'y' => $y });
                            my $saved = { 'main' => $raw_foreground_color };
                            foreach my $color (qw( red green blue )) {
                                $saved->{$color} = $self->{ 'COLOR_' . uc($color) };
                                $back->{$color}  = ($self->{ 'COLOR_' . uc($color) } * $color_alpha) + ($back->{$color} * (1 - $color_alpha));
                            }
                            $back->{'alpha'} = min(255, $color_alpha + $back->{'alpha'});
                            $self->set_color($back);
                            $c = $raw_foreground_color;
                            $raw_foreground_color = $saved->{'main'};
                            foreach my $color (qw( red green blue )) {
                                $self->{ 'COLOR_' . uc($color) } = $saved->{$color};
                            }
                        } elsif ($draw_mode == AND_MODE) {
                            $c &= $raw_foreground_color;
                        } elsif ($draw_mode == ADD_MODE) {
                            $c += $raw_foreground_color;
                        } elsif ($draw_mode == SUBTRACT_MODE) {
                            $c -= $raw_foreground_color;
                        } elsif ($draw_mode == MULTIPLY_MODE) {
                            $c *= $raw_foreground_color;
                        } elsif ($draw_mode == DIVIDE_MODE) {
                            $c /= $raw_foreground_color;
                        } elsif ($draw_mode == MASK_MODE) {
                            if ($self->{'BITS'} == 32) {
                                $c = $raw_foreground_color if (substr($raw_foreground_color, 0, 3) ne substr($raw_background_color, 0, 3));
                            } else {
                                $c = $raw_foreground_color if ($raw_foreground_color ne $raw_background_color);
                            }
                        } elsif ($draw_mode == UNMASK_MODE) {
                            my $pixel = $self->pixel({ 'x' => $x, 'y' => $y });
                            my $raw   = $pixel->{'raw'};
                            if ($self->{'BITS'} == 32) {
                                $c = $raw_foreground_color if (substr($raw, 0, 3) eq substr($raw_background_color, 0, 3));
                            } else {
                                $c = $raw_foreground_color if ($raw eq $raw_background_color);
                            }
                        }
                        substr($self->{'SCREEN'}, $index, $bytes) = $c;
                    my $error = $@;
                    warn __LINE__ . " $error" if ($error && $self->{'SHOW_ERRORS'});
                    $self->_fix_mapping() if ($error);
                }
                $self->{'history'}->{$y}->{$x} = 1 if (exists($self->{'history'}));
            }
        }
    }

    $self->{'X'} = $x;
    $self->{'Y'} = $y;
}

sub setpixel {
=head2 setpixel

An alias to plot.

=cut

    my $self = shift;
    $self->plot(shift);
}

sub set_pixel {
=head2 set_pixel

An alias to plot.

=cut

    my $self = shift;
    $self->plot(shift);
}

sub pixel {
=head2 pixel

Returns the color of the pixel at coordinate x,y, if it lies within the clipping region.  It returns undefined if outside of the clipping region.

=over 4

 my $pixel = $fb->pixel({'x' => 20,'y' => 25});

$pixel is a hash reference in the form:

 {
    'red'   => integer value, # 0 - 255
    'green' => integer value, # 0 - 255
    'blue'  => integer value, # 0 - 255
    'alpha' => integer value, # 0 - 255
    'hex'   => hexadecimal string of the values from 00000000 to FFFFFFFF
    'raw'   => 16/24/32bit encoded string (depending on screen mode)
 }

=back
=cut

    my $self   = shift;
    my $params = shift;

    my $x     = int($params->{'x'});
    my $y     = int($params->{'y'});
    my $bytes = $self->{'BYTES'};

    # Values outside of the clipping area return undefined.
    unless (($x > $self->{'XX_CLIP'}) || ($y > $self->{'YY_CLIP'}) || ($x < $self->{'X_CLIP'}) || ($y < $self->{'Y_CLIP'})) {
        my ($R, $G, $B);
        my $index = ($self->{'BYTES_PER_LINE'} * ($y + $self->{'YOFFSET'})) + (($self->{'XOFFSET'} + $x) * $bytes);
        my $color = substr($self->{'SCREEN'}, $index, $bytes);

        return($color) if (exists($params->{'raw'})); # Bypass the mess below if floodfill is using this

        my $color_order = $self->{'COLOR_ORDER'};
        my $A           = $self->{'COLOR_ALPHA'};
        if ($self->{'BITS'} == 32) {
            if ($color_order == BGR) {
                ($B, $G, $R, $A) = unpack("C$bytes", $color);
            } elsif ($color_order == BRG) {
                ($B, $R, $G, $A) = unpack("C$bytes", $color);
            } elsif ($color_order == RGB) {
                ($R, $G, $B, $A) = unpack("C$bytes", $color);
            } elsif ($color_order == RBG) {
                ($R, $B, $G, $A) = unpack("C$bytes", $color);
            } elsif ($color_order == GRB) {
                ($G, $R, $B, $A) = unpack("C$bytes", $color);
            } elsif ($color_order == GBR) {
                ($G, $B, $R, $A) = unpack("C$bytes", $color);
            }
        } elsif ($self->{'BITS'} == 24) {
            if ($color_order == BGR) {
                ($B, $G, $R) = unpack("C$bytes", $color);
            } elsif ($color_order == BRG) {
                ($B, $R, $G) = unpack("C$bytes", $color);
            } elsif ($color_order == RGB) {
                ($R, $G, $B) = unpack("C$bytes", $color);
            } elsif ($color_order == RBG) {
                ($R, $B, $G) = unpack("C$bytes", $color);
            } elsif ($color_order == GRB) {
                ($G, $R, $B) = unpack("C$bytes", $color);
            } elsif ($color_order == GBR) {
                ($G, $B, $R) = unpack("C$bytes", $color);
            }
        } elsif ($self->{'BITS'} == 16) {
            my $C = unpack('S', $color);

            $B = ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'}  < 6) ? ($C >> ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}))  & 31 : ($C >> ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}))  & 63;
            $G = ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'} < 6) ? ($C >> ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'})) & 31 : ($C >> ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'})) & 63;
            $R = ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'}   < 6) ? ($C >> ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}))   & 31 : ($C >> ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}))   & 63;
            $R = $R << (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'});
            $G = $G << (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'});
            $B = $B << (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'});
        }
        return ({ 'red' => $R, 'green' => $G, 'blue' => $B, 'alpha' => $A, 'raw' => $color, 'hex' => sprintf('%02x%02x%02x%02x',$R,$G,$B,$A) });
    }
    return (undef);
}

sub getpixel {
=head2 getpixel

Alias for 'pixel'.

=cut

    my $self = shift;
    return ($self->pixel(shift));
}

sub get_pixel {
=head2 get_pixel

Alias for 'pixel'.

=cut

    my $self = shift;
    return ($self->pixel(shift));
}

sub last_plot {
=head2 last_plot

Returns the last plotted position

=over 4

 my $last_plot = $fb->last_plot();

This returns an anonymous hash reference in the form:

 {
     'x' => x position,
     'y' => y position
 }

=back

Or, if you want a simple array returned:

=over 4

 my ($x,$y) = $fb->last_plot();

This returns the position as a two element array:

 ( x position, y position )

=back

=cut

    my $self = shift;
    if (wantarray) {
        return ($self->{'X'}, $self->{'Y'});
    }
    return ({ 'x' => $self->{'X'}, 'y' => $self->{'Y'} });
}

sub line {
=head2 line

Draws a line, in the foreground color, from point x,y to point xx,yy.  Clipping applies.

=over 4

 $fb->line({
    'x'           => 50,
    'y'           => 60,
    'xx'          => 100,
    'yy'          => 332
    'pixel_size'  => 1,
    'antialiased' => TRUE
 });

=back

=cut

    my $self   = shift;
    my $params = shift;

    $self->plot($params);
    $params->{'x'} = $params->{'xx'};
    $params->{'y'} = $params->{'yy'};
    $self->drawto($params);
}

sub angle_line {
=head2 angle_line

Draws a line, in the global foreground color, from point x,y at an angle of 'angle', of length 'radius'.  Clipping applies.

=over 4

 $fb->angle_line({
    'x'           => 50,
    'y'           => 60,
    'radius'      => 50,
    'angle'       => 30.3, # Compass coordinates (0-360)
    'pixel_size'  => 3,
    'antialiased' => FALSE
 });

=back

* This is not affected by the Acceleration setting

=cut

    my $self   = shift;
    my $params = shift;

    my ($dp_cos, $dp_sin);
    my $index = int($params->{'angle'} * 100);

    if (defined($self->{'dp_cache'}->[$index])) {
        ($dp_cos, $dp_sin) = (@{ $self->{'dp_cache'}->[$index] });
    } else {
        my $dp             = ($params->{'angle'} * pi) / 180;
        ($dp_cos, $dp_sin) = (cos($dp), sin($dp));
        $self->{'dp_cache'}->[$index]  = [$dp_cos, $dp_sin];
    }
    $params->{'xx'} = int($params->{'x'} - ($params->{'radius'} * $dp_sin));
    $params->{'yy'} = int($params->{'y'} - ($params->{'radius'} * $dp_cos));
    $self->line($params);
}

sub drawto {
=head2 drawto

Draws a line, in the foreground color, from the last plotted position to the position x,y.  Clipping applies.

=over 4

 $fb->drawto({
    'x'           => 50,
    'y'           => 60,
    'pixel_size'  => 2,
    'antialiased' => TRUE
 });

=back

* Antialiased lines are not accelerated

=cut

    ##########################################################################
    # For Perl, Perfectly horizontal line drawing is optimized by using the  #
    # BLIT functions.  This assists greatly with drawing filled objects.  In #
    # fact, it's hundreds of times faster!                                   #
    ##########################################################################
    my $self   = shift;
    my $params = shift;

    my $x_end = int($params->{'x'});
    my $y_end = int($params->{'y'});
    my $size  = int($params->{'pixel_size'} || 1);

    my $start_x     = $self->{'X'};
    my $start_y     = $self->{'Y'};
    my $antialiased = $params->{'antialiased'} || 0;
    $size = $params->{'pixel_size'} = 1 if ($antialiased);
    my $XX          = $x_end;
    my $YY          = $y_end;
	my $x_clip      = $self->{'X_CLIP'};
	my $y_clip      = $self->{'Y_CLIP'};
	my $xx_clip     = $self->{'XX_CLIP'};
	my $yy_clip     = $self->{'YY_CLIP'};

    if ($self->{'ACCELERATED'} && $size == 1 && !$antialiased) {
        c_line(
            $self->{'SCREEN'},
            $start_x, $start_y, $x_end, $y_end,
            $x_clip,  $y_clip, $xx_clip, $yy_clip,
            $self->{'INT_RAW_FOREGROUND_COLOR'},
            $self->{'INT_RAW_BACKGROUND_COLOR'},
            $self->{'COLOR_ALPHA'},
            $self->{'DRAW_MODE'},
            $self->{'BYTES'},
            $self->{'BITS'},
            $self->{'BYTES_PER_LINE'},
            $self->{'XOFFSET'}, $self->{'YOFFSET'},
            # $antialiased,
        );
    } else {
        my $width;
		my $height;
		my $raw_foreground_color = $self->{'RAW_FOREGROUND_COLOR'};

        # Determines if the coordinates sent were right-side-up or up-side-down.
        if ($start_x > $x_end) {
            $width = $start_x - $x_end;
        } else {
            $width = $x_end - $start_x;
        }
        if ($start_y > $y_end) {
            $height = $start_y - $y_end;
        } else {
            $height = $y_end - $start_y;
        }

        # We need only plot if start and end are the same
        if (($x_end == $start_x) && ($y_end == $start_y)) {
            $self->plot({ 'x' => $x_end, 'y' => $y_end, 'pixel_size' => $size });

            # Else, let's get to drawing
        } elsif ($x_end == $start_x) {    # Draw a perfectly verticle line
            if ($start_y > $y_end) {      # Draw direction is UP
                foreach my $y ($y_end .. $start_y) {
                    $self->plot({ 'x' => $start_x, 'y' => $y, 'pixel_size' => $size });
                }
            } else {                      # Draw direction is DOWN
                foreach my $y ($start_y .. $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $y, 'pixel_size' => $size });
                }
            }
        } elsif ($y_end == $start_y) {    # Draw a perfectly horizontal line (fast)
            $x_end   = max($x_clip, min($x_end, $xx_clip));
            $start_x = max($x_clip, min($start_x, $xx_clip));
            $width   = abs($x_end - $start_x);
            if ($size == 1) {
                if ($start_x > $x_end) {
                    $self->blit_write({ 'x' => $x_end, 'y' => $y_end, 'width' => $width, 'height' => 1, 'image' => $raw_foreground_color x $width });    # Blitting a horizontal line is much faster!
                } else {
                    $self->blit_write({ 'x' => $start_x, 'y' => $start_y, 'width' => $width, 'height' => 1, 'image' => $raw_foreground_color x $width });    # Blitting a horizontal line is much faster!
                }
            } else {
                if ($start_x > $x_end) {
                    $self->blit_write({ 'x' => $x_end, 'y' => ($y_end - ($size / 2)), 'width' => $width, 'height' => $size, 'image' => $raw_foreground_color x ($width * $size) });    # Blitting a horizontal line is much faster!
                } else {
                    $self->blit_write({ 'x' => $start_x, 'y' => ($y_end - ($size / 2)), 'width' => $width, 'height' => $size, 'image' => $raw_foreground_color x ($width * $size) });    # Blitting a horizontal line is much faster!
                }
            }
        } elsif ($antialiased) {
            $self->_draw_line_antialiased($start_x, $start_y, $x_end, $y_end);
        } elsif ($width > $height) {    # Wider than it is high
            my $factor = $height / $width;
            if (($start_x < $x_end) && ($start_y < $y_end)) {    # Draw UP and to the RIGHT
                while ($start_x < $x_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_y += $factor;
                    $start_x++;
                }
            } elsif (($start_x > $x_end) && ($start_y < $y_end)) {    # Draw UP and to the LEFT
                while ($start_x > $x_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_y += $factor;
                    $start_x--;
                }
            } elsif (($start_x < $x_end) && ($start_y > $y_end)) {    # Draw DOWN and to the RIGHT
                while ($start_x < $x_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_y -= $factor;
                    $start_x++;
                }
            } elsif (($start_x > $x_end) && ($start_y > $y_end)) {    # Draw DOWN and to the LEFT
                while ($start_x > $x_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_y -= $factor;
                    $start_x--;
                }
            }
        } elsif ($width < $height) {    # Higher than it is wide
            my $factor = $width / $height;
            if (($start_x < $x_end) && ($start_y < $y_end)) {    # Draw UP and to the RIGHT
                while ($start_y < $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x += $factor;
                    $start_y++;
                }
            } elsif (($start_x > $x_end) && ($start_y < $y_end)) {    # Draw UP and to the LEFT
                while ($start_y < $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x -= $factor;
                    $start_y++;
                }
            } elsif (($start_x < $x_end) && ($start_y > $y_end)) {    # Draw DOWN and to the RIGHT
                while ($start_y > $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x += $factor;
                    $start_y--;
                }
            } elsif (($start_x > $x_end) && ($start_y > $y_end)) {    # Draw DOWN and to the LEFT
                while ($start_y > $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x -= $factor;
                    $start_y--;
                }
            }
        } else {    # $width == $height
            if (($start_x < $x_end) && ($start_y < $y_end)) {    # Draw UP and to the RIGHT
                while ($start_y < $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x++;
                    $start_y++;
                }
            } elsif (($start_x > $x_end) && ($start_y < $y_end)) {    # Draw UP and to the LEFT
                while ($start_y < $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x--;
                    $start_y++;
                }
            } elsif (($start_x < $x_end) && ($start_y > $y_end)) {    # Draw DOWN and to the RIGHT
                while ($start_y > $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x++;
                    $start_y--;
                }
            } elsif (($start_x > $x_end) && ($start_y > $y_end)) {    # Draw DOWN and to the LEFT
                while ($start_y > $y_end) {
                    $self->plot({ 'x' => $start_x, 'y' => $start_y, 'pixel_size' => $size });
                    $start_x--;
                    $start_y--;
                }
            }

        }
    }
    $self->{'X'} = $XX;
    $self->{'Y'} = $YY;
}

sub _flush_screen {
    # Since the framebuffer is mappeed as a string device, Perl buffers the output, and this must be flushed.
    my $self = shift;
    unless ($self->{'DEVICE'} eq 'EMULATED') {
        select(STDERR);
        $|++;
    }
    select($self->{'FB'});
    $|++;
}

sub _adj_plot {
    # Part of antialiased drawing
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    my $c    = shift;
    my $s    = shift;

    $self->set_color({ 'red' => $s->{'red'} * $c, 'green' => $s->{'green'} * $c, 'blue' => $s->{'blue'} * $c });
    $self->plot({ 'x' => $x, 'y' => $y });
}

sub _draw_line_antialiased {
    my $self = shift;
    my $x0   = shift;
    my $y0   = shift;
    my $x1   = shift;
    my $y1   = shift;

    my $saved = { %{ $self->{'SET_RAW_FOREGROUND_COLOR'} } };

    my $plot  = \&_adj_plot;

    if (abs($y1 - $y0) > abs($x1 - $x0)) {
        $plot                = sub { _adj_plot(@_[0, 2, 1, 3, 4]) };
        ($x0, $y0, $x1, $y1) = ($y0, $x0, $y1, $x1);
    }

    if ($x0 > $x1) {
        ($x0, $x1, $y0, $y1) = ($x1, $x0, $y1, $y0);
    }

    my $dx       = $x1 - $x0;
    my $dy       = $y1 - $y0;
    my $gradient = $dy / $dx;

    my @xends;
    my $intery;

    # handle the endpoints
    foreach my $xy ([$x0, $y0], [$x1, $y1]) {
        my ($x, $y) = @{$xy};
        my $xend    = int($x + 0.5);                   # POSIX::lround($x);
        my $yend    = $y + $gradient * ($xend - $x);
        my $xgap    = _rfpart($x + 0.5);

        my $x_pixel = $xend;
        my $y_pixel = int($yend);
        push(@xends, $x_pixel);

        $plot->($self, $x_pixel, $y_pixel,     _rfpart($yend) * $xgap, $saved);
        $plot->($self, $x_pixel, $y_pixel + 1, _fpart($yend) * $xgap,  $saved);
        next if (defined($intery));

        # first y-intersection for the main loop
        $intery = $yend + $gradient;
    }

    # main loop

    foreach my $x ($xends[0] + 1 .. $xends[1] - 1) {
        $plot->($self, $x, int($intery),     _rfpart($intery), $saved);
        $plot->($self, $x, int($intery) + 1, _fpart($intery),  $saved);
        $intery += $gradient;
    }
    $self->set_color($saved);
}

sub bezier {
=head2 bezier

Draws a Bezier curve, based on a list of control points.

=over 4

 $fb->bezier(
     {
         'coordinates' => [
             x0,y0,
             x1,y1,
             ...              # As many as needed
         ],
         'points'     => 100, # Number of total points plotted for curve
                              # The higher the number, the smoother the curve.
         'pixel_size' => 2,   # optional
         'closed'     => 1,   # optional, close it and make it a full shape.
         'filled'     => 1    # Results may vary, optional
         'gradient' => {
              'direction' => 'horizontal', # or vertical
              'colors'    => { # 2 to any number of transitions allowed
                  'red'   => [255,255,0], # Red to yellow to cyan
                  'green' => [0,255,255],
                  'blue'  => [0,0,255]
              }
          }
     }
 );

=back

* This is not affected by the Acceleration setting

=cut

    my $self   = shift;
    my $params = shift;

    my $size        = $params->{'pixel_size'} || 1;
    my $closed      = $params->{'closed'}     || 0;
    my $filled      = $params->{'filled'}     || 0;

    push(@{ $params->{'coordinates'} }, $params->{'coordinates'}->[0], $params->{'coordinates'}->[1]) if ($closed);

    my $bezier = Math::Bezier->new($params->{'coordinates'});
    my @coords = $bezier->curve($params->{'points'} || (scalar(@{ $params->{'coordinates'} }) / 2));
    if ($closed) {
        $params->{'coordinates'} = \@coords;
        $self->polygon($params);
    } else {
        $self->plot({ 'x' => shift(@coords), 'y' => shift(@coords), 'pixel_size' => $size });
        while (scalar(@coords)) {
            $self->drawto({ 'x' => shift(@coords), 'y' => shift(@coords), 'pixel_size' => $size });
        }
    }
}

sub cubic_bezier { # obsolete
=head2 cubic_bezier

DISCONTINUED, use 'bezier' instead (now just an alias to 'bezier')

=cut

    my $self = shift;
    $self->bezier(shift);
}

sub draw_arc {
=head2 draw_arc

Draws an arc/pie/poly arc of a circle at point x,y.

=over 4

 x             = x of center of circle
 y             = y of center of circle
 radius        = radius of circle

 start_degrees = starting point, in degrees, of arc

 end_degrees   = ending point, in degrees, of arc

 granularity   = This is used for accuracy in drawing
                 the arc.  The smaller the number, the
                 more accurate the arc is drawn, but it
                 is also slower.  Values between 0.1
                 and 0.01 are usually good.  Valid values
                 are any positive floating point number
                 down to 0.0001.  Anything smaller than
                 that is just silly.

 mode          = Specifies the drawing mode.
                  0 > arc only
                  1 > Filled pie section
                      Can have gradients, textures, and hatches
                  2 > Poly arc.  Draws a line from x,y to the
                      beginning and ending arc position.

 $fb->draw_arc({
    'x'             => 100,
    'y'             => 100,
    'radius'        => 100,
    'start_degrees' => -40, # Compass coordinates
    'end_degrees'   => 80,
    'granularity   => .05,
    'mode'          => 2    # The object hash has 'ARC', 'PIE',
                            # and 'POLY_ARC' as a means of filling
                            # this value.
 });

=back

* Only PIE is affected by the acceleration setting.

=cut

    # This isn't exactly the fastest routine out there, hence the "granularity" parameter, but it is pretty neat.  Drawing lines between points smooths and compensates for high granularity settings.
    my $self   = shift;
    my $params = shift;

    my $x             = int($params->{'x'});
    my $y             = int($params->{'y'});
    my $radius        = int($params->{'radius'} || 1);
    $radius           = max($radius, 1);
    my $start_degrees = $params->{'start_degrees'} || 0;
    my $end_degrees   = $params->{'end_degrees'}   || 360;
    my $granularity   = $params->{'granularity'}   || .1;

    my $mode  = int($params->{'mode'}       || 0);
    my $size  = int($params->{'pixel_size'} || 1);
    my $bytes = $self->{'BYTES'};
	my $min_bytes = $self->{'MIN_BYTES'};

    $start_degrees -= 90;
    $end_degrees   -= 90;
    $start_degrees += 360 if ($start_degrees < 0);
    $end_degrees   += 360 if ($end_degrees < 0);

    unless ($self->{'ACCELERATED'} && $mode == PIE) {    # ($mode == PIE || $mode == ARC)) {
        my ($sx, $sy, $degrees, $ox, $oy) = (0, 0, 1, 1, 1);
        my @coords;

        my $plotted = FALSE;
        $degrees = $start_degrees;
        my ($dp_cos, $dp_sin);
        if ($start_degrees > $end_degrees) {
            do {
                my $index = int($degrees * 100);
                if (defined($self->{'dp_cache'}->[$index])) {
                    ($dp_cos, $dp_sin) = (@{ $self->{'dp_cache'}->[$index] });
                } else {
                    my $dp             = ($degrees * pi) / 180;
                    ($dp_cos, $dp_sin) = (cos($dp), sin($dp));
                    $self->{'dp_cache'}->[$index]  = [$dp_cos, $dp_sin];
                }
                $sx = int($x - ($radius * $dp_sin));
                $sy = int($y - ($radius * $dp_cos));
                if (($sx <=> $ox) || ($sy <=> $oy)) {
                    if ($mode == ARC) {    # Ordinary arc
                        if ($plotted) {    # Fills in the gaps better this way
                            $self->drawto({ 'x' => $sx, 'y' => $sy, 'pixel_size' => $size });
                        } else {
                            $self->plot({ 'x' => $sx, 'y' => $sy, 'pixel_size' => $size });
                            $plotted = TRUE;
                        }
                    } else {
                        if ($degrees == $start_degrees) {
                            push(@coords, $x, $y, $sx, $sy);
                        } else {
                            push(@coords, $sx, $sy);
                        }
                    }
                    $ox = $sx;
                    $oy = $sy;
                }
                $degrees += $granularity;
            } until ($degrees >= 360);
            $degrees = 0;
        }
        $plotted = FALSE;
        do {
            my $index = int($degrees * 100);
            if (defined($self->{'dp_cache'}->[$index])) {
                ($dp_cos, $dp_sin) = (@{ $self->{'dp_cache'}->[$index] });
            } else {
                my $dp = ($degrees * pi) / 180;
                ($dp_cos, $dp_sin) = (cos($dp), sin($dp));
                $self->{'dp_cache'}->[$index]  = [$dp_cos, $dp_sin];
            }
            $sx = int($x - ($radius * $dp_sin));
            $sy = int($y - ($radius * $dp_cos));
            if (($sx <=> $ox) || ($sy <=> $oy)) {
                if ($mode == ARC) {    # Ordinary arc
                    if ($plotted) {    # Fills in the gaps better this way
                        $self->drawto({ 'x' => $sx, 'y' => $sy, 'pixel_size' => $size });
                    } else {
                        $self->plot({ 'x' => $sx, 'y' => $sy, 'pixel_size' => $size });
                        $plotted = TRUE;
                    }
                } else {    # Filled pie arc
                    if ($degrees == $start_degrees) {
                        push(@coords, $x, $y, $sx, $sy);
                    } else {
                        push(@coords, $sx, $sy);
                    }
                }
                $ox = $sx;
                $oy = $sy;
            }
            $degrees += $granularity;
        } until ($degrees >= $end_degrees);
        if ($mode != ARC) {
            $params->{'filled'}      = ($mode == PIE) ? TRUE : FALSE;
            $params->{'coordinates'} = \@coords;
            $self->polygon($params);
        }
        ($self->{'X'}, $self->{'Y'}) = ($sx, $sy);

    } else {
        my $w = ($radius * 2);
        my $pattern;
        my $saved = {
            'x'      => $x - $radius,
            'y'      => $y - $radius,
            'width'  => $w,
            'height' => $w,
            'image'  => '',
        };
        my $draw_mode;
        my $image;
        my $fill;

        eval { # Imager can crash.
            my $img = Imager->new(
                'xsize'             => $w,
                'ysize'             => $w,
                'raw_datachannels'  => $min_bytes,
                'raw_storechannels' => $min_bytes,
                'channels'          => $min_bytes,
                'raw_interleave'    => 0,
            );
            unless ($self->{'DRAW_MODE'}) {
                if ($self->{'ACCELERATED'}) {
                    $draw_mode           = $self->{'DRAW_MODE'};
                    $self->{'DRAW_MODE'} = MASK_MODE;
                } else {
                    $saved            = $self->blit_read($saved);
                    $saved->{'image'} = $self->_convert_16_to_24($saved->{'image'}, RGB) if ($self->{'BITS'} == 16);
                    $img->read(
                        'xsize'             => $w,
                        'ysize'             => $w,
                        'raw_datachannels'  => $min_bytes,
                        'raw_storechannels' => $min_bytes,
                        'channels'          => $min_bytes,
                        'raw_interleave'    => 0,
                        'data'              => $saved->{'image'},
                        'type'              => 'raw',
                        'allow_incomplete'  => 1
                    );
                }
            }
            my %p = (
                'x'      => $radius,
                'y'      => $radius,
                'd1'     => $start_degrees,
                'd2'     => $end_degrees,
                'r'      => $radius,
                'filled' => TRUE,
                'color'  => $self->{'IMAGER_FOREGROUND_COLOR'},
            );
            if (exists($params->{'hatch'})) {
                $fill = Imager::Fill->new(
                    'hatch' => $params->{'hatch'} || 'dots16',
                    'fg'    => $self->{'IMAGER_FOREGROUND_COLOR'},
                    'bg'    => $self->{'IMAGER_BACKGROUND_COLOR'}
                );
                $p{'fill'} = $fill;
            } elsif (exists($params->{'texture'})) {
                $pattern = $self->_generate_fill($w, $w, undef, $params->{'texture'});
                $pattern = $self->_convert_16_to_24($pattern, RGB) if ($self->{'BITS'} == 16);
                $image   = Imager->new(
                    'xsize'             => $w,
                    'ysize'             => $w,
                    'raw_datachannels'  => $min_bytes,
                    'raw_storechannels' => $min_bytes,
                    'raw_interleave'    => 0,
                );
                $image->read(
                    'xsize'             => $w,
                    'ysize'             => $w,
                    'raw_datachannels'  => $min_bytes,
                    'raw_storechannels' => $min_bytes,
                    'raw_interleave'    => 0,
                    'data'              => $pattern,
                    'type'              => 'raw',
                    'allow_incomplete'  => 1
                );
                $p{'fill'}->{'image'} = $image;
            } elsif (exists($params->{'gradient'})) {
                if (exists($params->{'gradient'}->{'colors'})) {
                    $pattern = $self->_generate_fill($w, $w, $params->{'gradient'}->{'colors'}, $params->{'gradient'}->{'direction'} || 'vertical');
                } else {
                    $pattern = $self->_generate_fill(
                        $w, $w,
                        {
                            'red'   => [$params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'}],
                            'green' => [$params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}],
                            'blue'  => [$params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'}],
                            'alpha' => (exists($params->{'gradient'}->{'start'}->{'alpha'})) ? [$params->{'gradient'}->{'start'}->{'alpha'},$params->{'gradient'}->{'end'}->{'alpha'}] : [$self->{'COLOR_ALPHA'},$self->{'COLOR_ALPHA'}],
                        },
                        $params->{'gradient'}->{'direction'} || 'vertical'
                    );
                }
                $pattern = $self->_convert_16_to_24($pattern, RGB) if ($self->{'BITS'} == 16);
                $image = Imager->new(
                    'xsize'             => $w,
                    'ysize'             => $w,
                    'raw_datachannels'  => $min_bytes,
                    'raw_storechannels' => $min_bytes,
                    'raw_interleave'    => 0,
                );
                $image->read(
                    'xsize'             => $w,
                    'ysize'             => $w,
                    'raw_datachannels'  => $min_bytes,
                    'raw_storechannels' => $min_bytes,
                    'raw_interleave'    => 0,
                    'data'              => $pattern,
                    'type'              => 'raw',
                    'allow_incomplete'  => 1
                );
                $p{'fill'}->{'image'} = $image;
            }
            $img->arc(%p);
            $img->write(
                'type'          => 'raw',
                'datachannels'  => $min_bytes,
                'storechannels' => $min_bytes,
                'interleave'    => 0,
                'data'          => \$saved->{'image'},
            );
            $saved->{'image'} = $self->_convert_24_to_16($saved->{'image'}, RGB) if ($self->{'BITS'} == 16);
        };
        warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});
        $self->blit_write($saved);
        $self->{'DRAW_MODE'} = $draw_mode if (defined($draw_mode));
    }
}

sub arc {
=head2 arc

Draws an arc of a circle at point x,y.  This is an alias to draw_arc above, but no mode parameter needed.

=over 4

 x             = x of center of circle

 y             = y of center of circle

 radius        = radius of circle

 start_degrees = starting point, in degrees, of arc

 end_degrees   = ending point, in degrees, of arc

 granularity   = This is used for accuracy in drawing
                 the arc.  The smaller the number, the
                 more accurate the arc is drawn, but it
                 is also slower.  Values between 0.1
                 and 0.01 are usually good.  Valid values
                 are any positive floating point number
                 down to 0.0001.

 $fb->arc({
    'x'             => 100,
    'y'             => 100,
    'radius'        => 100,
    'start_degrees' => -40,
    'end_degrees'   => 80,
    'granularity    => .05,
 });

=back

* This is not affected by the Acceleration setting

=cut

    my $self   = shift;
    my $params = shift;

    $params->{'mode'} = ARC;
    $self->draw_arc($params);
}

sub filled_pie {
=head2 filled_pie

Draws a filled pie wedge at point x,y.  This is an alias to draw_arc above, but no mode parameter needed.

=over 4

 x             = x of center of circle

 y             = y of center of circle

 radius        = radius of circle

 start_degrees = starting point, in degrees, of arc

 end_degrees   = ending point, in degrees, of arc

 granularity   = This is used for accuracy in drawing
                 the arc.  The smaller the number, the
                 more accurate the arc is drawn, but it
                 is also slower.  Values between 0.1
                 and 0.01 are usually good.  Valid values
                 are any positive floating point number
                 down to 0.0001.

 $fb->filled_pie({
    'x'             => 100,
    'y'             => 100,
    'radius'        => 100,
    'start_degrees' => -40,
    'end_degrees'   => 80,
    'granularity'   => .05,
    'gradient' => {  # optional
        'direction' => 'horizontal', # or vertical
        'colors'    => { # 2 to any number of transitions allowed
            'red'   => [255,255,0], # Red to yellow to cyan
            'green' => [0,255,255],
            'blue'  => [0,0,255],
            'alpha' => [255,255,255],
        }
    },
    'texture'  => { # Same as what blit_read or load_image returns
       'width'  => 320,
        'height' => 240,
        'image'  => $raw_image_data
    },
    'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                # the names of all the hatches
 });

=back

* This is affected by the Acceleration setting

=cut

    my $self   = shift;
    my $params = shift;

    $params->{'mode'} = PIE;
    $self->draw_arc($params);
}

sub poly_arc {
=head2 poly_arc

Draws a poly arc of a circle at point x,y.  This is an alias to draw_arc above, but no mode parameter needed.

=over 4

 x             = x of center of circle

 y             = y of center of circle

 radius        = radius of circle

 start_degrees = starting point, in degrees, of arc

 end_degrees   = ending point, in degrees, of arc

 granularity   = This is used for accuracy in drawing
                 the arc.  The smaller the number, the
                 more accurate the arc is drawn, but it
                 is also slower.  Values between 0.1
                 and 0.01 are usually good.  Valid values
                 are any positive floating point number
                 down to 0.0001.

 $fb->poly_arc({
    'x'             => 100,
    'y'             => 100,
    'radius'        => 100,
    'start_degrees' => -40,
    'end_degrees'   => 80,
    'granularity'   => .05,
 });

=back

* This is not affected by the Acceleration setting

=cut

    my $self   = shift;
    my $params = shift;

    $params->{'mode'} = POLY_ARC;
    $self->draw_arc($params);
}

sub ellipse {
=head2 ellipse

Draw an ellipse at center position x,y with XRadius, YRadius.  Either a filled ellipse or outline is drawn based on the value of $filled.  The optional factor value varies from the default 1 to change the look and nature of the output.

=over 4

 $fb->ellipse({
    'x'          => 200, # Horizontal center
    'y'          => 250, # Vertical center
    'xradius'    => 50,
    'yradius'    => 100,
    'factor'     => 1, # Anything other than 1 has funkiness
    'pixel_size' => 4, # optional
    'filled'     => 1, # optional

    ## Only one of the following may be used

    'gradient'   => {  # optional, but 'filled' must be set
        'direction' => 'horizontal', # or vertical
        'colors'    => { # 2 to any number of transitions allowed
            'red'   => [255,255,0], # Red to yellow to cyan
            'green' => [0,255,255],
            'blue'  => [0,0,255],
            'alpha' => [255,255,255],
        }
    }
    'texture'    => {  # Same format blit_read or load_image uses.
        'width'   => 320,
        'height'  => 240,
        'image'   => $raw_image_data
    },
    'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                # the names of all the hatches
 });

=back

* This is not affected by the Acceleration setting

=cut

    # The routine even works properly for XOR mode when filled ellipses are drawn as well.  This was solved by drawing only if the X or Y position changed.
    my $self   = shift;
    my $params = shift;

    my $cx      = int($params->{'x'});
    my $cy      = int($params->{'y'});
    my $XRadius = int($params->{'xradius'} || 1);
    my $YRadius = int($params->{'yradius'} || 1);

    $XRadius = 1 if ($XRadius < 1);
    $YRadius = 1 if ($YRadius < 1);

    my $filled = int($params->{'filled'}     || 0);
    my $fact   = $params->{'factor'}         || 1;
    my $size   = int($params->{'pixel_size'} || 1);
    $size      = 1 if ($filled);

    my ($old_cyy, $old_cy_y) = (0, 0);
    if ($fact == 0) {    # We don't allow zero values for this
        $fact = 1;
    }
    my $xsq          = $XRadius * $XRadius;
    my $ysq          = $YRadius * $YRadius;
    my $TwoASquare   = (2 * $xsq) * $fact;
    my $TwoBSquare   = (2 * $ysq) * $fact;
    my $x            = $XRadius;
    my $y            = 0;
    my $XChange      = $ysq * (1 - (2 * $XRadius));
    my $YChange      = $xsq;
    my $EllipseError = 0;
    my $StoppingX    = $TwoBSquare * $XRadius;
    my $StoppingY    = 0;
    my $history_on   = (exists($self->{'history'})) ? TRUE : FALSE;

    # The history prevents double drawing
    $self->{'history'} = {} unless ($history_on || !$filled || $size > 1);
    my ($red, $green, $blue, $pattern, $plen, @rc, @gc, @bc);
    my $gradient  = FALSE;
    my $saved     = $self->{'RAW_FOREGROUND_COLOR'};
    my $xdiameter = $XRadius * 2;
    my $ydiameter = $YRadius * 2;
    my $bytes     = $self->{'BYTES'};
	my $color_alpha = $self->{'COLOR_ALPHA'};
    if (exists($params->{'gradient'})) {
        if ($params->{'gradient'}->{'direction'} !~ /vertical/i) {
            if (exists($params->{'gradient'}->{'colors'})) {
                $pattern = $self->_generate_fill($xdiameter, $ydiameter, $params->{'gradient'}->{'colors'}, 'horizontal');
            } else {
                $pattern = $self->_generate_fill(
                    $xdiameter,
                    $ydiameter,
                    {
                        'red'   => [$params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'}],
                        'green' => [$params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}],
                        'blue'  => [$params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'}],
                        'alpha' => (exists($params->{'gradient'}->{'start'}->{'alpha'})) ? [$params->{'gradient'}->{'start'}->{'alpha'},$params->{'gradient'}->{'end'}->{'alpha'}] : [$color_alpha,$color_alpha],
                    },
                    'horizontal'
                );
            }
            $plen     = length($pattern);
            $gradient = 2;
        } else {
            my $ydiameter = $YRadius * 2;
            if (exists($params->{'gradient'}->{'colors'})) {
                @rc = multi_gradient($ydiameter, @{ $params->{'gradient'}->{'colors'}->{'red'} });
                @gc = multi_gradient($ydiameter, @{ $params->{'gradient'}->{'colors'}->{'green'} });
                @bc = multi_gradient($ydiameter, @{ $params->{'gradient'}->{'colors'}->{'blue'} });
                if (exists($params->{'gradient'}->{'colors'}->{'alpha'})) {
                    @ac = multi_gradient($ydiameter, @{ $params->{'gradient'}->{'colors'}->{'alpha'} });
                } else {
                    @ac = map {$_ = $color_alpha} (1..(scalar(@bc)));
                }
            } else {
                @rc = gradient($params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'},   $ydiameter);
                @gc = gradient($params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}, $ydiameter);
                @bc = gradient($params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'},  $ydiameter);
                if (exists($params->{'gradient'}->{'start'}->{'alpha'})) {
                    @ac = gradient($params->{'gradient'}->{'start'}->{'alpha'}, $params->{'gradient'}->{'end'}->{'alpha'}, $ydiameter);
                } else {
                    @ac = map {$_ = $color_alpha} (1..2);
                }
            }
            $gradient = 1;
        }
    } elsif (exists($params->{'texture'})) {
        $pattern  = $self->_generate_fill($xdiameter, $ydiameter, undef, $params->{'texture'});
        $gradient = 2;
    } elsif (exists($params->{'hatch'})) {
        $pattern  = $self->_generate_fill($xdiameter, $ydiameter, undef, $params->{'hatch'});
        $gradient = 2;
    }

    my $left = $cx - $XRadius;
    while ($StoppingX >= $StoppingY) {
        my $cxx  = int($cx + $x);
        my $cx_x = int($cx - $x);
        my $cyy  = int($cy + $y);
        my $cy_y = int($cy - $y);
        my $rpy  = $YRadius + $y;
        my $rmy  = $YRadius - $y;

        if ($filled) {
            if ($cyy <=> $old_cyy) {
                if ($gradient == 2) {
                    my $wd = max($cx_x, $cxx) - min($cxx, $cx_x);
                    $self->blit_write({ 'x' => min($cxx, $cx_x), 'y' => $cyy, 'width' => $wd, 'height' => 1, 'image' => substr($pattern, $bytes * (min($cxx, $cx_x) - $left) + ($rpy * ($xdiameter * $bytes)), $bytes * ($wd)) });
                } else {
                    if ($gradient) {
                        $self->set_color({ 'red' => $rc[$rpy], 'green' => $gc[$rpy], 'blue' => $bc[$rpy] });
                    }
                    $self->line({ 'x' => $cxx, 'y' => $cyy, 'xx' => $cx_x, 'yy' => $cyy });
                }
                $old_cyy = $cyy;
            }
            if (($cy_y <=> $old_cy_y) && ($cyy <=> $cy_y)) {
                if ($gradient == 2) {
                    my $wd = max($cx_x, $cxx) - min($cxx, $cx_x);
                    $self->blit_write({ 'x' => min($cxx, $cx_x), 'y' => $cy_y, 'width' => $wd, 'height' => 1, 'image' => substr($pattern, $bytes * (min($cxx, $cx_x) - $left) + ($rmy * ($xdiameter * $bytes)), $bytes * ($wd)) });
                } else {
                    if ($gradient) {
                        $self->set_color({ 'red' => $rc[$rmy], 'green' => $gc[$rmy], 'blue' => $bc[$rmy] });
                    }
                    $self->line({ 'x' => $cx_x, 'y' => $cy_y, 'xx' => $cxx, 'yy' => $cy_y });
                }
                $old_cy_y = $cy_y;
            }
        } else {
            $self->plot({ 'x' => $cxx,  'y' => $cyy,  'pixel_size' => $size });
            $self->plot({ 'x' => $cx_x, 'y' => $cyy,  'pixel_size' => $size });
            $self->plot({ 'x' => $cx_x, 'y' => $cy_y, 'pixel_size' => $size }) if (int($cyy) <=> int($cy_y));
            $self->plot({ 'x' => $cxx,  'y' => $cy_y, 'pixel_size' => $size }) if (int($cyy) <=> int($cy_y));
        }
        $y++;
        $StoppingY    += $TwoASquare;
        $EllipseError += $YChange;
        $YChange      += $TwoASquare;
        if ((($EllipseError * 2) + $XChange) > 0) {
            $x--;
            $StoppingX    -= $TwoBSquare;
            $EllipseError += $XChange;
            $XChange      += $TwoBSquare;
        }
    }
    $x            = 0;
    $y            = $YRadius;
    $XChange      = $ysq;
    $YChange      = $xsq * (1 - 2 * $YRadius);
    $EllipseError = 0;
    $StoppingX    = 0;
    $StoppingY    = $TwoASquare * $YRadius;

    while ($StoppingX <= $StoppingY) {
        my $cxx  = int($cx + $x);
        my $cx_x = int($cx - $x);
        my $cyy  = int($cy + $y);
        my $cy_y = int($cy - $y);
        my $rpy  = $YRadius + $y;
        my $rmy  = $YRadius - $y;
        if ($filled) {
            if ($cyy <=> $old_cyy) {
                if ($gradient == 2) {
                    my $wd = max($cx_x, $cxx) - min($cxx, $cx_x);
                    $self->blit_write({ 'x' => min($cxx, $cx_x), 'y' => $cyy, 'width' => $wd, 'height' => 1, 'image' => substr($pattern, $bytes * (min($cxx, $cx_x) - $left) + ($rpy * ($xdiameter * $bytes)), $bytes * ($wd)) });
                } else {
                    if ($gradient) {
                        $self->set_color({ 'red' => $rc[$rpy], 'green' => $gc[$rpy], 'blue' => $bc[$rpy] });
                    }
                    $self->line({ 'x' => $cxx, 'y' => $cyy, 'xx' => $cx_x, 'yy' => $cyy });
                }
                $old_cyy = $cyy;
            }
            if (($cy_y <=> $old_cy_y) && ($cyy <=> $cy_y)) {
                if ($gradient == 2) {
                    my $wd = max($cx_x, $cxx) - min($cxx, $cx_x);
                    $self->blit_write({ 'x' => min($cxx, $cx_x), 'y' => $cy_y, 'width' => $wd, 'height' => 1, 'image' => substr($pattern, $bytes * (min($cxx, $cx_x) - $left) + ($rmy * ($xdiameter * $bytes)), $bytes * ($wd)) });
                } else {
                    if ($gradient) {
                        $self->set_color({ 'red' => $rc[$rmy], 'green' => $gc[$rmy], 'blue' => $bc[$rmy] });
                    }
                    $self->line({ 'x' => $cx_x, 'y' => $cy_y, 'xx' => $cxx, 'yy' => $cy_y });
                }
                $old_cy_y = $cy_y;
            }
        } else {
            $self->plot({ 'x' => $cxx,  'y' => $cyy,  'pixel_size' => $size });
            $self->plot({ 'x' => $cx_x, 'y' => $cyy,  'pixel_size' => $size }) if (int($cxx) <=> int($cx_x));
            $self->plot({ 'x' => $cx_x, 'y' => $cy_y, 'pixel_size' => $size }) if (int($cxx) <=> int($cx_x));
            $self->plot({ 'x' => $cxx,  'y' => $cy_y, 'pixel_size' => $size });
        }
        $x++;
        $StoppingX    += $TwoBSquare;
        $EllipseError += $XChange;
        $XChange      += $TwoBSquare;
        if ((($EllipseError * 2) + $YChange) > 0) {
            $y--;
            $StoppingY    -= $TwoASquare;
            $EllipseError += $YChange;
            $YChange      += $TwoASquare;
        }
    }
    delete($self->{'history'}) if (exists($self->{'history'}) && !$history_on);
    $self->{'RAW_FOREGROUND_COLOR'} = $saved;
}

sub circle {
=head2 circle

Draws a circle at point x,y, with radius 'radius'.  It can be an outline, solid filled, or gradient filled.  Outlined circles can have any pixel size.

=over 4

 $fb->circle({
    'x'        => 300, # Horizontal center
    'y'        => 300, # Vertical center
    'radius'   => 100,
    'filled'   => 1, # optional
    'gradient' => {  # optional
        'direction' => 'horizontal', # or vertical
        'colors'    => { # 2 to any number of transitions allowed
            'red'   => [255,255,0], # Red to yellow to cyan
            'green' => [0,255,255],
            'blue'  => [0,0,255],
            'alpha' => [255,255,255],
        }
    },
    'texture'  => { # Same as what blit_read or load_image returns
        'width'  => 320,
        'height' => 240,
        'image'  => $raw_image_data
    },
    'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                # the names of all the hatches
 });

=back

* This is affected by the Acceleration setting

=cut

# This also doubles as the rounded box routine.

    my $self   = shift;
    my $params = shift;

    my $x0            = int($params->{'x'});
    my $y0            = int($params->{'y'});
    my $x1            = int($params->{'xx'})    || $x0;
    my $y1            = int($params->{'yy'})    || $y0;
    my $bx            = int($params->{'bx'})    || 0;
    my $by            = int($params->{'by'})    || 0;
    my $bxx           = int($params->{'bxx'})   || 1;
    my $byy           = int($params->{'byy'})   || 1;
    my $r             = int($params->{'radius'});
    my $filled        = $params->{'filled'}     || FALSE;
    my $gradient      = (defined($params->{'gradient'})) ? TRUE : FALSE;
    my $size          = $params->{'pixel_size'} || 1;
    my $start         = $y0 - $r;
    my $x             = $r;
    my $y             = 0;
    my $decisionOver2 = 1 - $x;
    my (@rc, @gc, @bc, @ac);

    ($x0, $x1) = ($x1, $x0) if ($x0 > $x1);
    ($y0, $y1) = ($y1, $y0) if ($y0 > $y1);
    my $_x     = $x0 - $r;
    my $_xx    = $x1 + $r;
    my $_y     = $y0 - $r;
    my $_yy    = $y1 + $r;
    my $xstart = $_x;

    my @coords;
    my $saved = $self->{'RAW_FOREGROUND_COLOR'};
    my $W     = $r * 2;
    my $count = $W + abs($y1 - $y0);
    my $pattern;
    my $wdth  = $_xx - $_x;
    my $hgth  = $_yy - $_y;
    my $bytes = $self->{'BYTES'};
    my $plen  = $wdth * $bytes;
    $self->{'history'} = {};

    if ($gradient) {
        $W = $bxx - $bx unless ($x0 == $x1 && $y0 == $y1);
        if (exists($params->{'gradient'}->{'colors'})) {
            $pattern = $self->_generate_fill($wdth, $hgth, $params->{'gradient'}->{'colors'}, $params->{'gradient'}->{'direction'});
        } else {
            $pattern = $self->_generate_fill(
                $wdth, $hgth,
                {
                    'red'   => [$params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'}],
                    'green' => [$params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}],
                    'blue'  => [$params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'}],
                    'alpha' => (exists($params->{'gradient'}->{'start'}->{'alpha'})) ? [$params->{'gradient'}->{'start'}->{'alpha'},$params->{'gradient'}->{'end'}->{'alpha'}] : [$self->{'COLOR_ALPHA'},$self->{'COLOR_ALPHA'}],
                },
                $params->{'gradient'}->{'direction'}
            );
        }
        $plen     = $wdth * $bytes;
        $gradient = 2;
    } elsif (exists($params->{'texture'})) {
        $pattern  = $self->_generate_fill($wdth, $hgth, undef, $params->{'texture'});
        $gradient = 2;
    } elsif (exists($params->{'hatch'})) {
        $pattern  = $self->_generate_fill($wdth, $hgth, undef, $params->{'hatch'});
        $gradient = 2;
    }
    my ($ymy, $lymy, $ymx, $lymx, $ypy, $lypy, $ypx, $lypx, $xmy, $xmx, $xpy, $xpx);
    while ($x >= ($y - 1)) {
        $ymy = $y0 - $y;    # Top
        $ymx = $y0 - $x;
        $ypy = $y1 + $y;    # Bottom
        $ypx = $y1 + $x;
        $xmy = $x0 - $y;    # Left
        $xmx = $x0 - $x;
        $xpy = $x1 + $y;    # Right
        $xpx = $x1 + $x;

        if ($filled) {
            my $ymy_i = $ymy - $start;
            my $ymx_i = $ymx - $start;
            my $ypy_i = $ypy - $start;
            my $ypx_i = $ypx - $start;

            if ($gradient == 2) {
                my $fxmy = $xmy;
                my $fxmx = $xmx;
                my $fxpy = $xpy;
                my $fxpx = $xpx;

                # Top
                my $fwd = $fxpx - $fxmx;
                my $wd  = $xpx - $xmx;
                if ($ymy != $lymy && $ymy != $lymx && $ymy != $lypx && $ymy != $lypy) {
                    ($params->{'x'}, $params->{'y'}, $params->{'width'}, $params->{'height'}, $params->{'image'}) = ($fxmx, $ymy, $fwd, 1, substr($pattern, (($plen - ($bytes * $wd)) / 2) + ($ymy_i * $plen), $fwd * $bytes));
                    $self->blit_write($params);
                }

                $fwd = $fxpy - $fxmy;
                $wd  = $xpy - $xmy;
                if ($ymx != $lymx && $ymx != $lymy && $ymx != $lypx && $ymx != $lypy) {
                    ($params->{'x'}, $params->{'y'}, $params->{'width'}, $params->{'height'}, $params->{'image'}) = ($fxmy, $ymx, $fwd, 1, substr($pattern, (($plen - ($bytes * $wd)) / 2) + ($ymx_i * $plen), $fwd * $bytes));
                    $self->blit_write($params);
                }

                # Bottom
                $fwd = $fxpx - $fxmx;
                $wd  = $xpx - $xmx;
                if ($ypy != $lypy && $ypy != $lypx && $ypy != $lymy && $ypy != $lymx) {
                    ($params->{'x'}, $params->{'y'}, $params->{'width'}, $params->{'height'}, $params->{'image'}) = ($fxmx, $ypy, $fwd, 1, substr($pattern, (($plen - ($bytes * $wd)) / 2) + ($ypy_i * $plen), $fwd * $bytes));
                    $self->blit_write($params);
                }

                $fwd = $fxpy - $fxmy;
                $wd  = $xpy - $xmy;
                if ($ypx != $lypx && $ypx != $lypy && $ypx != $lymx && $ypx != $lymy) {
                    ($params->{'x'}, $params->{'y'}, $params->{'width'}, $params->{'height'}, $params->{'image'}) = ($fxmy, $ypx, $fwd, 1, substr($pattern, (($plen - ($bytes * $wd)) / 2) + ($ypx_i * $plen), $fwd * $bytes));
                    $self->blit_write($params);
                }
            } elsif ($gradient) {
                # Top
                if ($ymy != $lymy && $ymy != $lymx && $ymy != $lypx && $ymy != $lypy) {
                    $self->set_color({ 'red' => $rc[$ymy_i], 'green' => $gc[$ymy_i], 'blue' => $bc[$ymy_i] });
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmx, $ymy, $xpx, $ymy);
                    $self->line($params);
                }
                if ($ymx != $lymx && $ymx != $lymy && $ymx != $lypx && $ymx != $lypy) {
                    $self->set_color({ 'red' => $rc[$ymx_i], 'green' => $gc[$ymx_i], 'blue' => $bc[$ymx_i] });
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmy, $ymx, $xpy, $ymx);
                    $self->line($params);
                }

                # Bottom
                if ($ypy != $lypy && $ypy != $lypx && $ypy != $lymy && $ypy != $lymx) {
                    $self->set_color({ 'red' => $rc[$ypy_i], 'green' => $gc[$ypy_i], 'blue' => $bc[$ypy_i] });
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmx, $ypy, $xpx, $ypy);
                    $self->line($params);
                }
                if ($ypx != $lypx && $ypx != $lypy && $ypx != $lymx && $ypx != $lymy) {
                    $self->set_color({ 'red' => $rc[$ypx_i], 'green' => $gc[$ypx_i], 'blue' => $bc[$ypx_i] });
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmy, $ypx, $xpy, $ypx);
                    $self->line($params);
                }
            } else {
                # Top
                if ($ymy != $lymy && $ymy != $lymx && $ymy != $lypx && $ymy != $lypy) {
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmx, $ymy, $xpx, $ymy);
                    $self->line($params);
                }
                if ($ymx != $lymx && $ymx != $lymy && $ymx != $lypx && $ymx != $lypy) {
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmy, $ymx, $xpy, $ymx);
                    $self->line($params);
                }

                # Bottom
                if ($ypy != $lypy && $ypy != $lypx && $ypy != $lymy && $ypy != $lymx) {
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmx, $ypy, $xpx, $ypy);
                    $self->line($params);
                }
                if ($ypx != $lypx && $ypx != $lypy && $ypx != $lymx && $ypx != $lymy) {
                    ($params->{'x'}, $params->{'y'}, $params->{'xx'}, $params->{'yy'}) = ($xmy, $ypx, $xpy, $ypx);
                    $self->line($params);
                }
            }
            $lymy = $ymy;
            $lymx = $ymx;
            $lypy = $ypy;
            $lypx = $ypx;
        } else {
            # Top left
            ($params->{'x'}, $params->{'y'}) = ($xmx, $ymy);
            $self->plot($params);
            ($params->{'x'}, $params->{'y'}) = ($xmy, $ymx);
            $self->plot($params);

            # Top right
            ($params->{'x'}, $params->{'y'}) = ($xpx, $ymy);
            $self->plot($params);
            ($params->{'x'}, $params->{'y'}) = ($xpy, $ymx);
            $self->plot($params);

            # Bottom right
            ($params->{'x'}, $params->{'y'}) = ($xpx, $ypy);
            $self->plot($params);
            ($params->{'x'}, $params->{'y'}) = ($xpy, $ypx);
            $self->plot($params);

            # Bottom left
            ($params->{'x'}, $params->{'y'}) = ($xmx, $ypy);
            $self->plot($params);
            ($params->{'x'}, $params->{'y'}) = ($xmy, $ypx);
            $self->plot($params);

            $lymy = $ymy;
            $lymx = $ymx;
            $lypy = $ypy;
            $lypx = $ypx;
        }
        $y++;
        if ($decisionOver2 <= 0) {
            $decisionOver2 += 2 * $y + 1;
        } else {
            $x--;
            $decisionOver2 += 2 * ($y - $x) + 1;
        }
    }
    unless ($x0 == $x1 && $y0 == $y1) {
        if ($filled) {
            if ($gradient == 2) {
                my $x      = $_x;
                my $y      = $y0;
                my $width  = $wdth;
                my $height = $y1 - $y0;
                my $index  = ($y0 - $start) * $plen;
                my $sz     = $plen * $height;
                $self->blit_write({ 'x' => $x, 'y' => $y, 'width' => $width, 'height' => $height, 'image' => substr($pattern, $index, $sz) }) if ($height && $width);
            } elsif ($gradient) {
                foreach my $v ($y0 .. $y1) {
                    my $offset = $v - $start;
                    $self->set_color({ 'red' => $rc[$offset], 'green' => $gc[$offset], 'blue' => $bc[$offset] });
                    $self->line({ 'x' => $_x, 'y' => $v, 'xx' => $_xx, 'yy' => $v, 'pixel_size' => 1 });
                }
            } else {
                $self->{'RAW_FOREGROUND_COLOR'} = $saved;
                $self->box({ 'x' => $_x, 'y' => $y0, 'xx' => $_xx, 'yy' => $y1, 'filled' => 1 });
            }
        } else {
            # top
            $self->line({ 'x' => $x0, 'y' => $_y, 'xx' => $x1, 'yy' => $_y, 'pixel_size' => $size });

            # right
            $self->line({ 'x' => $_xx, 'y' => $y0, 'xx' => $_xx, 'yy' => $y1, 'pixel_size' => $size });

            # bottom
            $self->line({ 'x' => $x0, 'y' => $_yy, 'xx' => $x1, 'yy' => $_yy, 'pixel_size' => $size });

            # left
            $self->line({ 'x' => $_x, 'y' => $y0, 'xx' => $_x, 'yy' => $y1, 'pixel_size' => $size });
        }
    }
    $self->{'RAW_FOREGROUND_COLOR'} = $saved;
    delete($self->{'history'});
}

sub _fpart {
    return ((POSIX::modf(shift))[0]);
}

sub _rfpart {
    return (1 - _fpart(shift));
}

sub polygon {
=head2 polygon

Creates a polygon drawn in the foreground color value.  The parameter 'coordinates' is a reference to an array of x,y values.  The last x,y combination is connected automatically with the first to close the polygon.  All x,y values are absolute, not relative.

It is up to you to make sure the coordinates are "sane".  Weird things can result from twisted or complex filled polygons.

=over 4

 $fb->polygon({
    'coordinates' => [
        5,5,
        23,34,
        70,7
    ],
    'pixel_size'  => 1, # optional
    'antialiased' => 1, # optional only for non-filled
    'filled'      => 1, # optional

    ## Only one of the following, "filled" must be set

    'gradient'    => {  # optional
        'direction' => 'horizontal', # or vertical
        'colors'    => { # 2 to any number of transitions allowed
            'red'   => [255,255,0], # Red to yellow to cyan
            'green' => [0,255,255],
            'blue'  => [0,0,255],
            'alpha' => [255,255,255],
        }
    },
    'texture'     => { # Same as what blit_read or load_image returns
        'width'  => 320,
        'height' => 240,
        'image'  => $raw_image_data
    },
    'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                # the names of all the hatches
 });

=back

* Filled polygons are affected by the acceleration setting.

=cut

    my $self   = shift;
    my $params = shift;

    my $size       = int($params->{'pixel_size'} || 1);
    my $aa         = $params->{'antialiased'} || 0;
    $size = $params->{'pixel_size'} = 1 if ($aa);
    my $history_on = (exists($self->{'history'})) ? TRUE : FALSE;

    if ($params->{'filled'}) {
        $self->_fill_polygon($params);
    } else {
        $self->{'history'} = {} unless ($history_on);
        my @coords = @{ $params->{'coordinates'} };
        my ($xx, $yy) = (int(shift(@coords)), int(shift(@coords)));
        $self->plot({ 'x' => $xx, 'y' => $yy, 'pixel_size' => $size });
        while (scalar(@coords)) {
            my ($x, $y) = (int(shift(@coords)), int(shift(@coords)));
            $self->drawto({ 'x' => $x, 'y' => $y, 'pixel_size' => $size, 'antialiased' => $aa });
        }
        $self->drawto({ 'x' => $xx, 'y' => $yy, 'pixel_size' => $size, 'antialiased' => $aa });
        $self->plot({ 'x' => $xx, 'y' => $yy, 'pixel_size' => $size }) if ($self->{'DRAW_MODE'} == 1);
        delete($self->{'history'}) unless ($history_on);
    }
}

sub _point_in_polygon {
    # Does point x,y fall inside the polygon described in coordinates?  Not yet used.
    my $self   = shift;
    my $params = shift;

    my $poly_corners = (scalar(@{ $params->{'coordinates'} }) / 2);
    my ($x, $y)      = (int($params->{'x'}), int($params->{'y'}));
    my $j            = $poly_corners - 1;
    my $odd_nodes    = FALSE;

    for (my $i = 0; $i < $poly_corners; $i += 2) {
        my ($ip, $jp) = ($i + 1, $j + 1);
        if (($params->{'coordinates'}->[$ip] < $y && $params->{'coordinates'}->[$jp] >= $y || $params->{'coordinates'}->[$jp] < $y && $params->{'coordinates'}->[$ip] >= $y) && ($params->{'coordinates'}->[$i] <= $x || $params->{'coordinates'}->[$j] <= $x)) {
            $odd_nodes ^= ($params->{'coordinates'}->[$i] + ($y - $params->{'coordinates'}->[$ip]) / ($params->{'coordinates'}->[$jp] - $params->{'coordinates'}->[$ip]) * ($params->{'coordinates'}->[$j] - $params->{'coordinates'}->[$i]) < $x);
        }
        $j = $i;
    }
    return ($odd_nodes);
}

sub _fill_polygon {
    my $self   = shift;
    my $params = shift;
    my $bytes  = $self->{'BYTES'};
	my $min_bytes = $self->{'MIN_BYTES'};

    my $points = [];
    my $left   = 0;
    my $right  = 0;
    my $top    = 0;
    my $bottom = 0;
    my $fill;
    while (scalar(@{ $params->{'coordinates'} })) {
        my $x   = int(shift(@{ $params->{'coordinates'} })) - $self->{'X_CLIP'};    # Compensate for the smaller area in Imager
        my $y   = int(shift(@{ $params->{'coordinates'} })) - $self->{'Y_CLIP'};
        $left   = min($left, $x);
        $right  = max($right, $x);
        $top    = min($top, $y);
        $bottom = max($bottom, $y);
        push(@{$points}, [$x, $y]);
    }
    my $width  = abs($right - $left);
    my $height = abs($bottom - $top);
    my $pattern;
    if (exists($params->{'gradient'})) {
        $params->{'gradient'}->{'direction'} ||= 'vertical';
        if (exists($params->{'gradient'}->{'colors'})) {
            $pattern = $self->_generate_fill($width, $height, $params->{'gradient'}->{'colors'}, $params->{'gradient'}->{'direction'});
        } else {
            $pattern = $self->_generate_fill(
                $width, $height,
                {
                    'red'   => [$params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'}],
                    'green' => [$params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}],
                    'blue'  => [$params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'}],
                    'alpha' => (exists($params->{'gradient'}->{'start'}->{'alpha'})) ? [$params->{'gradient'}->{'start'}->{'alpha'},$params->{'gradient'}->{'end'}->{'alpha'}] : [$self->{'COLOR_ALPHA'},$self->{'COLOR_ALPHA'}],
                },
                $params->{'gradient'}->{'direction'}
            );
        }
    } elsif (exists($params->{'texture'})) {
        $pattern = $self->_generate_fill($width, $height, undef, $params->{'texture'});
#    } elsif (exists($params->{'hatch'})) {
#        $pattern = $self->_generate_fill($width, $height, undef, $params->{'hatch'});
    }
    my $saved = { 'x' => $left, 'y' => $top, 'width' => $width, 'height' => $height };
    my $saved_mode = $self->{'DRAW_MODE'};
    unless ($self->{'DRAW_MODE'}) {
        if ($self->{'ACCELERATED'}) {
            $self->{'DRAW_MODE'} = MASK_MODE;
        } else {
            $saved            = $self->blit_read($saved);
            $saved->{'image'} = $self->_convert_16_to_24($saved->{'image'}, RGB) if ($self->{'BITS'} == 16);
        }
    }
    my $img;
    my $pimg;
    eval {
        $img = Imager->new(
            'xsize'             => $width,
            'ysize'             => $height,
            'raw_datachannels'  => $min_bytes,
            'raw_storechannels' => $min_bytes,
            'channels'          => $min_bytes,
        );
        if (exists($saved->{'image'}) && defined($saved->{'image'})) {
            $img->read(
                'xsize'             => $width,
                'ysize'             => $height,
                'raw_datachannels'  => $min_bytes,
                'raw_storechannels' => $min_bytes,
                'channels'          => $min_bytes,
                'raw_interleave'    => 0,
                'data'              => $saved->{'image'},
                'type'              => 'raw',
                'allow_incomplete'  => 1
            );
        }
        if (defined($pattern)) {
            $pattern = $self->_convert_16_to_24($pattern, RGB) if ($self->{'BITS'} == 16);
            $pimg    = Imager->new();
            $pimg->read(
                'xsize'             => $width,
                'ysize'             => $height,
                'raw_datachannels'  => $min_bytes,
                'raw_storechannels' => $min_bytes,
                'raw_interleave'    => 0,
                'channels'          => $min_bytes,
                'data'              => $pattern,
                'type'              => 'raw',
                'allow_incomplete'  => 1
            );
            $fill = Imager::Fill->new('image' => $pimg);
        } elsif (exists($params->{'hatch'}) && defined($params->{'hatch'})) {
            $fill = Imager::Fill->new(
                'hatch' => $params->{'hatch'} || 'dots16',
                'fg'    => $self->{'IMAGER_FOREGROUND_COLOR'},
                'bg'    => $self->{'IMAGER_BACKGROUND_COLOR'}
            );
        } else {
            $fill = Imager::Fill->new('solid' => $self->{'IMAGER_FOREGROUND_COLOR'});
        }
        $img->polygon(
            'points' => $points,
            'color'  => $self->{'IMAGER_FOREGROUND_COLOR'},
            'aa'     => $params->{'antialiased'} || 0,
            'filled' => TRUE,
            'fill'   => $fill,
        );
        $img->write(
            'type'          => 'raw',
            'datachannels'  => $min_bytes,
            'storechannels' => $min_bytes,
            'interleave'    => 0,
            'data'          => \$saved->{'image'},
        );
        $saved->{'image'} = $self->_convert_24_to_16($saved->{'image'}, RGB) if ($self->{'BITS'} == 16);
    };
    warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});
    $self->blit_write($saved);
    $self->{'DRAW_MODE'} = $saved_mode;
}

sub _generate_fill {
    my $self   = shift;
    my $width  = shift;
    my $height = shift;
    my $colors = shift;
    my $type   = shift;

    my $gradient = '';
    my $bytes    = $self->{'BYTES'};
	my $min_bytes = $self->{'MIN_BYTES'};
    if (ref($type) eq 'HASH') {    # texture
        if ($type->{'width'} != $width || $type->{'height'} != $height) {
            my $new = $self->blit_transform(
                {
                    'blit_data' => $type,
                      'scale'     => {
                          'scale_type' => 'nonprop',
                          'x'          => 0,
                          'y'          => 0,
                          'width'      => $width,
                          'height'     => $height
                      }
                }
            );
            $gradient = $new->{'image'};
        } else {
            $gradient = $type->{'image'};
        }
    } elsif ($type =~ /vertical|horizontal/i) {
        my $r_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'};
        my $g_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'};
        my $b_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'};
        my $a_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'};

        my $r_length = $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'};
        my $g_length = $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'};
        my $b_length = $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'};
        my $a_length = $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'length'};

        my $count = ($type =~ /horizontal/i) ? $width : $height;
        my (@red,@green,@blue,@alpha);
        @red   = @{ $colors->{'red'} };
        @green = @{ $colors->{'green'} };
        @blue  = @{ $colors->{'blue'} };
        if ($self->{'BITS'} == 32) {
            unless (exists($colors->{'alpha'})) {
                @alpha = map {$_ = $self->{'COLOR_ALPHA'}} (1..$count);
            } else {
                @alpha = @{ $colors->{'alpha'} };
            }
        }
        my @rc  = multi_gradient($count, @red);
        my @gc  = multi_gradient($count, @green);
        my @bc  = multi_gradient($count, @blue);
        my @ac  = multi_gradient($count, @alpha) if ($self->{'BITS'} == 32);
        if ($type =~ /horizontal/i) {    # Gradient
            my $end = $width - 1;
            foreach my $gcc (0 .. $end) {
                if ($self->{'BITS'} == 32) {
                    $gradient .= pack('L', (
                        ($rc[$gcc] << $r_offset) |
                        ($gc[$gcc] << $g_offset) |
                        ($bc[$gcc] << $b_offset) |
                        ($ac[$gcc] << $a_offset)
                    ));
                } elsif ($self->{'BITS'} == 24) {
                    $gradient .= pack('L', (
                        ($rc[$gcc] << $r_offset) |
                        ($gc[$gcc] << $g_offset) |
                        ($bc[$gcc] << $b_offset)
                    ));
                } elsif ($self->{'BITS'} == 16) {
                    $gradient .= pack('S', (
                        (($rc[$gcc] >> 3) << $r_offset) |
                        (($gc[$gcc] >> 2) << $g_offset) |
                        (($bc[$gcc] >> 3) << $b_offset)
                    ));
                }
            }
            $gradient = $gradient x $height;
        } elsif ($type =~ /vertical/i) {    # gradient
            my $end = $height - 1;
            foreach my $gcc (0 .. $end) {
                if ($self->{'BITS'} == 32) {
                    $gradient .= pack('L', (
                        ($rc[$gcc] << $r_offset) |
                        ($gc[$gcc] << $g_offset) |
                        ($bc[$gcc] << $b_offset) |
                        ($ac[$gcc] << $a_offset)
                    )) x $width;
                } elsif ($self->{'BITS'} == 24) {
                    $gradient .= pack('L', (
                        ($rc[$gcc] << $r_offset) |
                        ($gc[$gcc] << $g_offset) |
                        ($bc[$gcc] << $b_offset)
                    )) x $width;
                } elsif ($self->{'BITS'} == 16) {
                    $gradient .= pack('S', (
                        (($rc[$gcc] >> 3) << $r_offset) |
                        (($gc[$gcc] >> 2) << $g_offset) |
                        (($bc[$gcc] >> 3) << $b_offset)
                    )) x $width;
                }
            }
        }
    } else {
        if ($width && $height) {
            my $img;
            eval {
                $img = Imager->new(
                    'xsize'    => $width,
                    'ysize'    => $height,
                    'channels' => $min_bytes,
                );

                # Hatch types:
                #
                # Checkerboards               -> check1x1, check2x2, check4x4
                # Vertical Lines              -> vline1, vline2, vline4
                # Horizontal Lines            -> hline1, hline2, hline4
                # 45 deg Lines                -> slash1, slash2
                # -45 deg Lines               -> slosh1, slosh2
                # Vertical & Horizontal Lines -> grid1, grid2, grid4
                # Dots                        -> dots1, dots4, dots16
                # Stipples                    -> stipple, stipple2
                # Weave                       -> weave
                # Crosshatch                  -> cross1, cross2
                # Lozenge Tiles               -> vlozenge, hlozenge
                # Scales                      -> scalesdown, scalesup, scalesleft, scalesright
                # L Shaped Tiles              -> tile_L

                my $fill = Imager::Fill->new(
                    'hatch' => $type || 'dots16',
                    'fg'    => $self->{'IMAGER_FOREGROUND_COLOR'},
                    'bg'    => $self->{'IMAGER_BACKGROUND_COLOR'}
                );
                $img->box('fill' => $fill);
                $img->write(
                    'type'          => 'raw',
                    'datachannels'  => $min_bytes,
                    'storechannels' => $min_bytes,
                    'interleave'    => 0,
                    'data'          => \$gradient
                );
            };
            warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});
            $gradient = $self->_convert_24_to_16($gradient, RGB) if ($self->{'BITS'} == 16);
        }
    }
    return ($gradient);
}

sub box {
=head2 box

Draws a box from point x,y to point xx,yy, either as an outline, if 'filled' is 0, or as a filled block, if 'filled' is 1.  You may also add a gradient or texture.

=over 4

 $fb->box({
    'x'          => 20,
    'y'          => 50,
    'xx'         => 70,
    'yy'         => 100,
    'radius'     => 0, # if rounded, optional
    'pixel_size' => 1, # optional
    'filled'     => 1, # optional

    ## Only one of the following, "filled" must be set

    'gradient'    => {  # optional
        'direction' => 'horizontal', # or vertical
        'colors'    => { # 2 to any number of transitions allowed, and all colors must have the same number of transitions
            'red'   => [255,255,0], # Red to yellow to cyan
            'green' => [0,255,255],
            'blue'  => [0,0,255],
            'alpha' => [255,255,255], # Yes, even alpha transparency can vary
        }
    },
    'texture'     => { # Same as what blit_read or load_image returns
        'width'  => 320,
        'height' => 240,
        'image'  => $raw_image_data
    },
    'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                # the names of all the hatches
 });

=back

=cut

    my $self   = shift;
    my $params = shift;

    my $x      = int($params->{'x'});
    my $y      = int($params->{'y'});
    my $xx     = int($params->{'xx'});
    my $yy     = int($params->{'yy'});
    my $filled = int($params->{'filled'})     || 0;
    my $size   = int($params->{'pixel_size'}) || 1;
    my $radius = int($params->{'radius'})     || 0;
    $size      = 1 if ($filled);
    my ($count, $data, $w, $h);

    # This puts $x,$y,$xx,$yy in their correct order if backwards.
    # $x must always be less than $xx
    # $y must always be less than $yy
    if ($x > $xx) {
        ($x, $xx) = ($xx, $x);
    }
    if ($y > $yy) {
        ($y, $yy) = ($yy, $y);
    }
    my $width  = $xx - $y;
    my $height = $yy - $y;
    my $vc     = $height / 2;
    my $hc     = $width / 2;
    if ($radius) {
        # Keep the radius sane
        $radius = $hc if ($hc < $radius);
        $radius = $vc if ($vc < $radius);

        my $p          = $params;
        $p->{'radius'} = $radius;
        $p->{'x'}      = ($x + $radius);
        $p->{'y'}      = ($y + $radius);
        $p->{'xx'}     = ($xx - $radius);
        $p->{'yy'}     = ($yy - $radius);
        $p->{'bx'}     = $x;
        $p->{'by'}     = $y;
        $p->{'bxx'}    = $xx;
        $p->{'byy'}    = $yy;
        $self->circle($p);    # Yep, circle
    } elsif ($filled) {
        my $X = $xx;
        my $Y = $yy;
        $x    = max($self->{'X_CLIP'}, min($self->{'XX_CLIP'}, $x));
        $y    = max($self->{'Y_CLIP'}, min($self->{'YY_CLIP'}, $y));
        $xx   = max($self->{'X_CLIP'}, min($self->{'XX_CLIP'}, $xx));
        $yy   = max($self->{'Y_CLIP'}, min($self->{'YY_CLIP'}, $yy));
        $w    = abs($xx - $x);
        $h    = abs($yy - $y);
        my $pattern;

        if (exists($params->{'gradient'})) {
            if (exists($params->{'gradient'}->{'colors'})) {
                $pattern = $self->_generate_fill($w, $h, $params->{'gradient'}->{'colors'}, $params->{'gradient'}->{'direction'});
            } else {
                $pattern = $self->_generate_fill(
                    $w, $h,
                    {
                        'red'   => [$params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'}],
                        'green' => [$params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}],
                        'blue'  => [$params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'}],
                        'alpha' => (exists($params->{'gradient'}->{'start'}->{'alpha'})) ? [$params->{'gradient'}->{'start'}->{'alpha'},$params->{'gradient'}->{'end'}->{'alpha'}] : [$self->{'COLOR_ALPHA'},$self->{'COLOR_ALPHA'}],
                    },
                    $params->{'gradient'}->{'direction'},
                );
            }
        } elsif (exists($params->{'texture'})) {
            $pattern = $self->_generate_fill($w, $h, undef, $params->{'texture'});
        } elsif (exists($params->{'hatch'})) {
            $pattern = $self->_generate_fill($w, $h, undef, $params->{'hatch'});
        } else {
            $pattern = $self->{'RAW_FOREGROUND_COLOR'} x ($w * $h);
        }
        $self->blit_write({ 'x' => $x, 'y' => $y, 'width' => $w, 'height' => $h, 'image' => $pattern });
        $self->{'X'} = $X;
        $self->{'Y'} = $Y;
    } else {
        $self->polygon({ 'coordinates' => [$x, $y, $xx, $y, $xx, $yy, $x, $yy], 'pixel_size' => $size });
    }
}

sub rbox {
=head2 rbox

Draws a box at point x,y with the width 'width' and height 'height'.  It draws a frame if 'filled' is 0 or a filled box if 'filled' is 1. 'pixel_size' only applies if 'filled' is 0.  Filled boxes draw faster than frames. Gradients or textures are also allowed.

=over 4

 $fb->rbox({
    'x'          => 100,
    'y'          => 100,
    'width'      => 200,
    'height'     => 150,
    'radius'     => 0, # if rounded, optional
    'pixel_size' => 2, # optional
    'filled'     => 0, # optional

    ## Only one of the following, "filled" must be set

    'gradient'    => {  # optional
        'direction' => 'horizontal', # or vertical
        'colors'    => { # 2 to any number of transitions allowed
            'red'   => [255,255,0], # Red to yellow to cyan
            'green' => [0,255,255],
            'blue'  => [0,0,255],
            'alpha' => [255,255,255],
        }
    },
    'texture'     => { # Same as what blit_read or load_image returns
        'width'  => 320,
        'height' => 240,
        'image'  => $raw_image_data
    },
    'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                # the names of all the hatches
 });

=back

=cut

    my $self   = shift;
    my $params = shift;

    $params->{'xx'} = $params->{'x'} + $params->{'width'};
    $params->{'yy'} = $params->{'y'} + $params->{'height'};
    $self->box($params);
}

sub rounded_box {
=head2 rounded_box

This is an alias to rbox

=cut

    my $self = shift;
    $self->rbox(shift);
}

sub set_color {
=head2 set_color

Sets the drawing color in red, green, and blue, absolute 8 bit values.

Even if you are in 16 bit color mode, use 8 bit values.  They will be automatically scaled.

=over 4

 $fb->set_color({
    'red'   => 255,
    'green' => 255,
    'blue'  => 0,
    'alpha' => 255
 });

=back
=cut

    my $self   = shift;
    my $params = shift;
    my $name   = shift || 'RAW_FOREGROUND_COLOR';

    my $bytes       = $self->{'BYTES'};
    my $R           = int($params->{'red'})   & 255; # Color forced to fit within 0-255 value
    my $G           = int($params->{'green'}) & 255;
    my $B           = int($params->{'blue'})  & 255;
    my $def_alpha   = ($name eq 'RAW_FOREGROUND_COLOR') ? 255 : 0;
    my $A           = int($params->{'alpha'} || $def_alpha) & 255;
    my $color_order = $self->{'COLOR_ORDER'};

    map { $self->{ $name . '_' . uc($_) } = $params->{$_} } (keys %{$params});
    $params->{'red'}   = $R;
    $params->{'green'} = $G;
    $params->{'blue'}  = $B;
    $params->{'alpha'} = $A;
    my $r_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'};
    my $g_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'};
    my $b_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'};
    my $a_offset = $self->{'vscreeninfo'}->{'bitfields'}->{'alpha'}->{'offset'};
    $self->{'COLOR_ALPHA'}   = $A;
    if ($self->{'BITS'} >= 24) {
        $self->{$name} = pack('L',(
            ($R << $r_offset) |
            ($G << $g_offset) |
            ($B << $b_offset) |
            ($A << $a_offset)
        ));
        $self->{$name} = substr($self->{$name},0,3) if ($self->{'BITS'} == 24);
        $self->{"INT_$name"} = unpack('L', $self->{$name});
    } elsif ($self->{'BITS'} == 16) {
        my $r = $R >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'});
        my $g = $G >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'});
        my $b = $B >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'});
        $self->{$name} = pack('S', ($r << $r_offset) | ($g << $g_offset) | ($b << $b_offset));

        $self->{"INT_$name"} = unpack('S', $self->{$name});
    }

    $self->{"SET_$name"} = $params;
    # This swapping is only for Imager
    if ($color_order == BGR) {
        ($B, $G, $R) = ($R,$G,$B);
    } elsif ($color_order == BRG) {
        ($B, $R, $G) = ($R,$G,$B);
    } elsif ($color_order == RBG) {
        ($R, $B, $G) = ($R,$G,$B);
    } elsif ($color_order == GRB) {
        ($G, $R, $B) = ($R,$G,$B);
    } elsif ($color_order == GBR) {
        ($G, $B, $R) = ($R,$G,$B);
    }
    if ($name eq 'RAW_FOREGROUND_COLOR') {
        $self->{'IMAGER_FOREGROUND_COLOR'}  = ($self->{'BITS'} == 32) ? Imager::Color->new($R, $G, $B, $A) : Imager::Color->new($R, $G, $B);
    } else {
        $self->{'IMAGER_BACKGROUND_COLOR'} = ($self->{'BITS'} == 32) ? Imager::Color->new($R, $G, $B, $A) : Imager::Color->new($R, $G, $B);
    }
}

sub setcolor {
=head2 setcolor

This is an alias to 'set_color'

=cut

    my $self = shift;
    $self->set_color(shift);
}

sub set_foreground_color {
=head2 set_foreground_color

This is an alias to 'set_color'

=cut

    my $self = shift;
    $self->set_color(shift);
}

sub set_b_color {
=head2 set_b_color

Sets the background color in red, green, and blue values.

The same rules as set_color apply.

=over 4

 $fb->set_b_color({
    'red'   => 0,
    'green' => 0,
    'blue'  => 255,
    'alpha' => 255
 });

=back
=cut

    my $self = shift;
    $self->set_color(shift, 'RAW_BACKGROUND_COLOR');
}

sub setbcolor {
=head2 setbcolor

This is an alias to 'set_b_color'

=cut

    my $self = shift;
    $self->set_color(shift, 'RAW_BACKGROUND_COLOR');
}

sub set_background_color {
=head2 set_background_color

This is an alias to 'set_b_color'

=cut

    my $self = shift;
    $self->set_color(shift, 'RAW_BACKGROUND_COLOR');
}

sub fill {
=head2 fill

Does a flood fill starting at point x,y.  It samples the color at that point and determines that color to be the "background" color, and proceeds to fill in, with the current foreground color, until the "background" color is replaced with the new color.

NOTE:  The accelerated version of this routine may (and it is a small may) have issues.  If you find any issues, then temporarily turn off C-acceleration when calling this method.

=over 4

 $fb->fill({'x' => 334, 'y' => 23});

=back

* This one is greatly affected by the acceleration setting, and likely the one that may give the most trouble.  I have found on some systems Imager just doesn't do what it is asked to, but on others it works fine.  Go figure.  Some of you are getting your entire screen filled and know you are placing the X,Y coordinate correctly, then disabling acceleration before calling this should fix it.  Don't forget to re-enable acceleration when done.

=cut

    my $self   = shift;
    my $params = shift;

    my $x = int($params->{'x'});
    my $y = int($params->{'y'});

    my $pixel = $self->pixel(
		{
			'x' => $x,
			'y' => $y,
		}
	);
    my $bytes    = $self->{'BYTES'};
	my $tc_bytes = $self->{'MIN_BYTES'};
	my $x_clip   = $self->{'X_CLIP'};
	my $xx_clip  = $self->{'XX_CLIP'};
	my $y_clip   = $self->{'Y_CLIP'};
	my $yy_clip  = $self->{'YY_CLIP'};

    return if ($back eq $self->{'RAW_FOREGROUND_COLOR'});
    unless ($self->{'ACCELERATED'}) {
		# This doesn't over-use the system stack.  While flood fill algorithms are famous being a stack memory hog, this one goes easy on it.
        my $background = $pixel->{'raw'};
        my @visited    = (); # Used to be an associative array, which was slower
        my @queue      = ();

        push(@queue, [$x, $y]);

        while (scalar(@queue)) {
            my $pointref = shift(@queue);
            ($x, $y)     = @{$pointref};
            next if (
				($x < $x_clip) ||
				($x > $xx_clip) ||
				($y < $y_clip) ||
				($y > $yy_clip)
			);
            unless (defined($visited[$x][$y])) {
                $pixel = $self->pixel(
					{
						'x'   => $x,
						'y'   => $y,
						'raw' => TRUE,
					}
				);
                if ($pixel eq $background) {
                    $self->plot(
						{
							'x' => $x,
							'y' => $y,
						}
					);
                    $visited[$x][$y]++;
                    push(@queue, [$x + 1, $y]);
                    push(@queue, [$x - 1, $y]);
                    push(@queue, [$x,     $y + 1]);
                    push(@queue, [$x,     $y - 1]);
                }
            }
        }
    } else {
        my $width  = int($self->{'W_CLIP'});
        my $height = int($self->{'H_CLIP'});
        my $pattern;
        if (exists($params->{'gradient'})) {
            $params->{'gradient'}->{'direction'} ||= 'vertical';
            if (exists($params->{'gradient'}->{'colors'})) {
                $pattern = $self->_generate_fill($width, $height, $params->{'gradient'}->{'colors'}, $params->{'gradient'}->{'direction'});
            } else {
                $pattern = $self->_generate_fill(
                    $width, $height,
                    {
                        'red'   => [$params->{'gradient'}->{'start'}->{'red'},   $params->{'gradient'}->{'end'}->{'red'}],
                        'green' => [$params->{'gradient'}->{'start'}->{'green'}, $params->{'gradient'}->{'end'}->{'green'}],
                        'blue'  => [$params->{'gradient'}->{'start'}->{'blue'},  $params->{'gradient'}->{'end'}->{'blue'}],
                        'alpha' => (exists($params->{'gradient'}->{'start'}->{'alpha'})) ? [$params->{'gradient'}->{'start'}->{'alpha'},$params->{'gradient'}->{'end'}->{'alpha'}] : [$self->{'COLOR_ALPHA'},$self->{'COLOR_ALPHA'}],
                    },
                    $params->{'gradient'}->{'direction'}
                );
            }
        } elsif (exists($params->{'texture'})) {
            $pattern = $self->_generate_fill($width, $height, undef, $params->{'texture'});
        } elsif (exists($params->{'hatch'})) {
            $pattern = $self->_generate_fill($width, $height, undef, $params->{'hatch'});
        }

        my $saved = $self->blit_read(
            {
                'x'      => $x_clip,
                'y'      => $y_clip,
                'width'  => $width,
                'height' => $height,
            }
        );
        if ($self->{'BITS'} == 16) {
            $saved->{'image'} = $self->_convert_16_to_24($saved->{'image'}, RGB);
            $pattern = $self->_convert_16_to_24($pattern, RGB) if (defined($pattern));
        }
        eval {
            my $img = Imager->new(
                'xsize'             => $width,
                'ysize'             => $height,
                'raw_datachannels'  => $tc_bytes,
                'raw_storechannels' => $tc_bytes,
                'channels'          => $tc_bytes,
            );

            #            unless ($self->{'DRAW_MODE'}) {
            $img->read(
                'xsize'             => $width,
                'ysize'             => $height,
                'raw_datachannels'  => $tc_bytes,
                'raw_storechannels' => $tc_bytes,
                'channels'          => $tc_bytes,
                'raw_interleave'    => 0,
                'data'              => $saved->{'image'},
                'type'              => 'raw',
                'allow_incomplete'  => 1
            );

            my $fill;
            if (defined($pattern)) {
                my $pimg = Imager->new();
                $pimg->read(
                    'xsize'             => $width,
                    'ysize'             => $height,
                    'raw_datachannels'  => $tc_bytes,
                    'raw_storechannels' => $tc_bytes,
                    'raw_interleave'    => 0,
                    'channels'          => $tc_bytes,
                    'data'              => $pattern,
                    'type'              => 'raw',
                    'allow_incomplete'  => 1
                );
                $img->flood_fill(
                    'x'     => $x - $x_clip,
                    'y'     => $y - $y_clip,
                    'color' => $self->{'IMAGER_FOREGROUND_COLOR'},
                    'fill'  => { 'image' => $pimg }
                );
            } else {
                $img->flood_fill(
                    'x'     => $x - $x_clip,
                    'y'     => $y - $y_clip,
                    'color' => $self->{'IMAGER_FOREGROUND_COLOR'},
                );
            }
            $img->write(
                'type'          => 'raw',
                'datachannels'  => $tc_bytes,
                'storechannels' => $tc_bytes,
                'interleave'    => 0,
                'data'          => \$saved->{'image'},
            );
            $saved->{'image'} = $self->_convert_24_to_16($saved->{'image'}, RGB) if ($self->{'BITS'} == 16);
        };
        warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});

        $self->blit_write($saved);
    }
}

sub replace_color {
=head2 replace_color

This replaces one color with another inside the clipping region.  Sort of like a fill without boundary checking.

=over 4

 $fb->replace_color({
    'old' => { # Changed as of 5.56
        'red'   => 23,
        'green' => 48,
        'blue'  => 98
    },
    'new' => {
        'red'   => 255,
        'green' => 255,
        'blue'  => 0
    }
 });

 $fb->replace_color({
    'old' => {
        'raw' => "raw encoded string of color",
    },
    'new' => {
        'raw' => "raw encoded string of color",
    }
 });

 # Encoded color strings are 4 bytes wide for 32 bit, 3 bytes for 24 bit and 2 bytes for 16 bit color.

=back

* This is not affected by the Acceleration setting, and is just as fast in 16 bit as it is in 24 and 32 bit modes.  Which means, very fast.

=cut

    my $self   = shift;
    my $params = shift;

    my $old_r = int($params->{'old'}->{'red'})   || 0;
    my $old_g = int($params->{'old'}->{'green'}) || 0;
    my $old_b = int($params->{'old'}->{'blue'})  || 0;
    my $old_a = (exists($params->{'old'}->{'alpha'})) ? int($params->{'old'}->{'alpha'}) : undef;
    my $new_r = int($params->{'new'}->{'red'})   || 0;
    my $new_g = int($params->{'new'}->{'green'}) || 0;
    my $new_b = int($params->{'new'}->{'blue'})  || 0;
    my $new_a = int($params->{'new'}->{'alpha'}) || $self->{'COLOR_ALPHA'};

    my $color_order      = $self->{'COLOR_ORDER'};
    my ($sx, $start)     = (0, 0);
    $self->set_color(
		{
			'red'   => $new_r,
			'green' => $new_g,
			'blue'  => $new_b,
		}
	);
    my $old_mode         = $self->{'DRAW_MODE'};
    $self->{'DRAW_MODE'} = NORMAL_MODE;

    my ($old, $new);
	unless (exists($params->{'old'}->{'raw'}) && exists($params->{'new'}->{'raw'})) {
		if ($self->{'BITS'} == 32) {
			if ($color_order == BGR) {
				$old = (defined($old_a)) ? chr($old_b) . chr($old_g) . chr($old_r) . chr($old_a) : chr($old_b) . chr($old_g) . chr($old_r);
				$new = chr($new_b) . chr($new_g) . chr($new_r) . chr($new_a);
			} elsif ($color_order == BRG) {
				$old = (defined($old_a)) ? chr($old_b) . chr($old_r) . chr($old_g) . chr($old_a) : chr($old_b) . chr($old_r) . chr($old_g);
				$new = chr($new_b) . chr($new_r) . chr($new_g) . chr($new_a);
			} elsif ($color_order == RGB) {
				$old = (defined($old_a)) ? chr($old_r) . chr($old_g) . chr($old_b) . chr($old_a) : chr($old_r) . chr($old_g) . chr($old_b);
				$new = chr($new_r) . chr($new_g) . chr($new_b) . chr($new_a);
			} elsif ($color_order == RBG) {
				$old = (defined($old_a)) ? chr($old_r) . chr($old_b) . chr($old_g) . chr($old_a) : chr($old_r) . chr($old_b) . chr($old_g);
				$new = chr($new_r) . chr($new_b) . chr($new_g) . chr($new_a);
			} elsif ($color_order == GRB) {
				$old = (defined($old_a)) ? chr($old_g) . chr($old_r) . chr($old_b) . chr($old_a) : chr($old_g) . chr($old_r) . chr($old_b);
				$new = chr($new_g) . chr($new_r) . chr($new_b) . chr($new_a);
			} elsif ($color_order == GBR) {
				$old = (defined($old_a)) ? chr($old_g) . chr($old_b) . chr($old_r) . chr($old_a) : chr($old_g) . chr($old_b) . chr($old_r);
				$new = chr($new_g) . chr($new_b) . chr($new_r) . chr($new_a);
			}
		} elsif ($self->{'BITS'} == 24) {
			if ($color_order == BGR) {
				$old = chr($old_b) . chr($old_g) . chr($old_r);
				$new = chr($new_b) . chr($new_g) . chr($new_r);
			} elsif ($color_order == BRG) {
				$old = chr($old_b) . chr($old_r) . chr($old_g);
				$new = chr($new_b) . chr($new_r) . chr($new_g);
			} elsif ($color_order == RGB) {
				$old = chr($old_r) . chr($old_g) . chr($old_b);
				$new = chr($new_r) . chr($new_g) . chr($new_b);
			} elsif ($color_order == RBG) {
				$old = chr($old_r) . chr($old_b) . chr($old_g);
				$new = chr($new_r) . chr($new_b) . chr($new_g);
			} elsif ($color_order == GRB) {
				$old = chr($old_g) . chr($old_r) . chr($old_b);
				$new = chr($new_g) . chr($new_r) . chr($new_b);
			} elsif ($color_order == GBR) {
				$old = chr($old_g) . chr($old_b) . chr($old_r);
				$new = chr($new_g) . chr($new_b) . chr($new_r);
			}
		} elsif ($self->{'BITS'} == 16) {
			$old_b = $old_b >> (8 - ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'}));
			$old_g = $old_g >> (8 - ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'}));
			$old_r = $old_r >> (8 - ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'}));
			$new_b = $new_b >> (8 - ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'}));
			$new_g = $new_g >> (8 - ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'}));
			$new_r = $new_r >> (8 - ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'}));
			$old = pack('S',
				(
					($old_b << $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}) |
					($old_g << $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'}) |
					($old_r << $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'})
				)
			);
			$new = pack('S',
				(
					($new_b << $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}) |
					($new_g << $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'}) |
					($new_r << $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'})
				)
			);
		}
	} else {
		$old = $params->{'old'}->{'raw'};
		$new = $params->{'new'}->{'raw'};
	}
	if ($self->{'CLIPPED'}) {
		my $save = $self->blit_read(
			{
				'x'      => $self->{'X_CLIP'},
				'y'      => $self->{'Y_CLIP'},
				'width'  => $self->{'W_CLIP'},
				'height' => $self->{'H_CLIP'},
			}
		);
		if ($self->{'BITS'} == 32 && length($old) == 3) {
			$save->{'image'} =~ s/\Q$old\E./$new/sg;
		} else {
			$save->{'image'} =~ s/\Q$old\E/$new/sg;
		}
		$self->blit_write($save);
	} else {
		if ($self->{'BITS'} == 32 && length($old) == 3) {
			$self->{'SCREEN'} =~ s/\Q$old\E./$new/sg;
		} else {
			$self->{'SCREEN'} =~ s/\Q$old\E/$new/sg;
		}
	}
    $self->{'DRAW_MODE'} = $old_mode;
}

sub blit_copy {
=head2 blit_copy

Copies a square portion of screen graphic data from x,y,w,h to x_dest,y_dest.  It copies in the current drawing mode.

=over 4

 $fb->blit_copy({
    'x'      => 20,
    'y'      => 20,
    'width'  => 30,
    'height' => 30,
    'x_dest' => 200,
    'y_dest' => 200
 });

=back

=cut

    my $self   = shift;
    my $params = shift;

    $self->blit_write({	%{ $self->blit_read({'x' => int($params->{'x'}),'y' => int($params->{'y'}),'width' => int($params->{'width'}),'height' => int($params->{'height'})})}, 'x' => int($params->{'x_dest'}), 'y' => int($params->{'y_dest'}) });
}

sub blit_move {
=head2 blit_move

Moves a square portion of screen graphic data from x,y,w,h to x_dest,y_dest.  It moves in the current drawing mode.  It differs from "blit_copy" in that it removes the graphic from the original location (via XOR).

It also returns the data moved like "blit_read"

=over 4

 $fb->blit_move({
    'x'      => 20,
    'y'      => 20,
    'width'  => 30,
    'height' => 30,
    'x_dest' => 200,
    'y_dest' => 200,
    'image'  => $raw_image_data, # This is optional, but can speed things up
 });

=back

=cut

    my $self   = shift;
    my $params = shift;

    my $old_mode = $self->{'DRAW_MODE'};
    my $image    = (exists($params->{'image'})) ?
        $params
        :
        $self->blit_read({ 'x' => int($params->{'x'}), 'y' => int($params->{'y'}), 'width' => int($params->{'width'}), 'height' => int($params->{'height'}) });
    $self->xor_mode();
    $self->blit_write($image);
    $self->{'DRAW_MODE'} = $old_mode;
    $image->{'x'}        = int($params->{'x_dest'});
    $image->{'y'}        = int($params->{'y_dest'});
    $self->vsync();
    $self->blit_write($image);
    delete($image->{'x_dest'});
    delete($image->{'y_dest'});
    return($image);
}

sub play_animation {
=head2 play_animation

Plays an animation sequence loaded from "load_image"

=over 4

 my $animation = $fb->load_image(
     {
         'file'            => 'filename.gif',
         'center'          => CENTER_XY,
     }
 );

 $fb->play_animation($animation,$rate_multiplier);

=back

The animation is played at the speed described by the file's metadata multiplied by "rate_multiplier".

You need to enclose this in a loop if you wish it to play more than once.

The animation will stop if "Q" is pressed

=cut

    my $self  = shift;
    my $image = shift;
    my $rate  = shift || 1;

	ReadMode 4;
    foreach my $frame (0 .. (scalar(@{$image}) - 1)) {
        my $begin = time;
        $self->blit_write($image->[$frame]);

        my $delay = (($image->[$frame]->{'tags'}->{'gif_delay'} * .01) * $rate) - (time - $begin);
        if ($delay > 0) {
            sleep $delay;
        }
		my $key = uc(ReadKey(-1));
		last if ($key eq 'Q');
    }
	ReadMode 0;
}

sub acceleration {
=head2 acceleration

Enables/Disables all Imager or C language acceleration.

GFB uses the Imager library to do some drawing.  In some cases, these may not function as they should on some systems.  This method allows you to toggle this acceleration on or off.

When acceleration is off, the underlying (slower) Perl algorithms are used.  It is advisable to leave acceleration on for those methods which it functions correctly, and only shut it off when calling the problem ones.

When called without parameters, it returns the current setting.

=over 4

 $fb->acceleration(HARDWARE); # Turn hardware acceleration ON, along with some C acceleration (HARDWARE IS NOT YET IMPLEMENTED!)

 $fb->acceleration(SOFTWARE); # Turn C (software) acceleration ON

 $fb->acceleration(PERL);     # Turn acceleration OFF, using Perl

 my $accel = $fb->acceleration(); # Get current acceleration state.  0 = PERL, 1 = SOFTWARE, 2 = HARDWARE (not yet implemented)

 my $accel = $fb->acceleration('english'); # Get current acceleration state in an english string.
                                           # "PERL"     = PERL     = 0
                                           # "SOFTWARE" = SOFTWARE = 1
                                           # "HARDWARE" = HARDWARE = 2

=back

* The "Mask" and "Unmask" drawing modes are greatly affected by acceleration, as well as 16 bit conversions in image loading and ttf_print(ing).

=cut

    my $self = shift;
    if (scalar(@_)) {
        my $set = shift;
        if ($set =~ /^\d+$/ && $set >= PERL && $set <= HARDWARE) {
            $set = SOFTWARE if ($set > SOFTWARE); # HARDWARE is not implemented and setting defaults to SOFTWARE
            $self->{'ACCELERATED'} = $set;
        } elsif ($set =~ /english|string/i) {
            foreach my $name (qw( PERL SOFTWARE HARDWARE )) {
                if ($self->{'ACCELERATED'} == $self->{$name}) {
                    return($name);
                }
            }
        }
    }
    return ($self->{'ACCELERATED'});
}

sub perl {
=head2 perl

This is an alias to "acceleration(PERL)"

=cut

    my $self = shift;
    $self->acceleration(PERL);
}

sub software {
=head2 software

This is an alias to "acceleration(SOFTWARE)"

=cut

    my $self = shift;
    $self->acceleration(SOFTWARE);
}

sub hardware {
=head2 hardware

This is an alias to "acceleration(HARDWARE)"

=cut

    my $self = shift;
    $self->acceleration(HARDWARE);
}

sub blit_read {
=head2 blit_read

Reads in a square portion of screen data at x,y,width,height, and returns a hash reference with information about the block, including the raw data as a string, ready to be used with 'blit_write'.

Passing no parameters automatically grabs the clipping region (the whole screen if clipping is off).

=over 4

 my $blit_data = $fb->blit_read({
    'x'      => 30,
    'y'      => 50,
    'width'  => 100,
    'height' => 100
 });

=back

Returns:

=over 4

 {
     'x'      => original X position,
     'y'      => original Y position,
     'width'  => width,
     'height' => height,
     'image'  => string of image data for the block
 }

=back

All you have to do is change X and Y, and just pass it to "blit_write" and it will paste it there.

=cut

    my $self   = shift;
    my $params = shift;    # $self->_blit_adjust_for_clipping(shift);

    my $x              = int($params->{'x'} || $self->{'X_CLIP'});
    my $y              = int($params->{'y'} || $self->{'Y_CLIP'});
    my $clipw          = $self->{'W_CLIP'};
    my $cliph          = $self->{'H_CLIP'};
    my $w              = int($params->{'width'}  || $clipw);
    my $h              = int($params->{'height'} || $cliph);
    my $buf;

    $x = 0 if ($x < 0);
    $y = 0 if ($y < 0);
    $w = $self->{'XX_CLIP'} - $x if ($w > ($clipw));
    $h = $self->{'YY_CLIP'} - $y if ($h > ($cliph));

    my $W    = $w * $self->{'BYTES'};
    my $scrn = '';
    if ($h > 1 && $self->{'ACCELERATED'} == SOFTWARE) {
        $scrn = chr(0) x ($W * $h);
        c_blit_read(
            $self->{'SCREEN'},
            $self->{'XRES'}, $self->{'YRES'},
            $self->{'BYTES_PER_LINE'},
            $self->{'XOFFSET'}, $self->{'YOFFSET'},
            $scrn,
            $x, $y, $w, $h,
            $self->{'BYTES'},
            $draw_mode,
            $self->{'COLOR_ALPHA'},
            $self->{'RAW_BACKGROUND_COLOR'},
            $self->{'X_CLIP'}, $self->{'Y_CLIP'}, $self->{'XX_CLIP'}, $self->{'YY_CLIP'}
        );
    } else {
        my $yend = $y + $h;
        my $XX   = ($self->{'XOFFSET'} + $x) * $self->{'BYTES'};
        foreach my $line ($y .. ($yend - 1)) {
            my $index = ($self->{'BYTES_PER_LINE'} * ($line + $self->{'YOFFSET'})) + $XX;
            $scrn .= substr($self->{'SCREEN'}, $index, $W);
        }
    }
    return ({ 'x' => $x, 'y' => $y, 'width' => $w, 'height' => $h, 'image' => $scrn });
}

sub blit_write {
=head2 blit_write

Writes a previously read block of screen data at x,y,width,height.

It takes a hash reference.  It draws in the current drawing mode.

=over 4

 $fb->blit_write({
    'x'      => 0,
    'y'      => 0,
    'width'  => 100,
    'height' => 100,
    'image'  => $blit_data
 });

=back

=cut

    my $self    = shift;
    my $pparams = shift;
    return unless(defined($pparams));

    my $params = $self->_blit_adjust_for_clipping($pparams);
    return unless (defined($params));

    my $x = int($params->{'x'}      || 0);
    my $y = int($params->{'y'}      || 0);
    my $w = int($params->{'width'}  || 1);
    my $h = int($params->{'height'} || 1);

    my $draw_mode = $self->{'DRAW_MODE'};
    my $bytes     = $self->{'BYTES'};
	my $bits      = $self->{'BITS'};
	my $raw_background_color = $self->{'RAW_BACKGROUND_COLOR'};

    return unless (defined($params->{'image'}) && $params->{'image'} ne '' && $h && $w);

    if ($self->{'ACCELERATED'} == SOFTWARE) { # && $h > 1) {
        c_blit_write(
            $self->{'SCREEN'},
            $self->{'XRES'}, $self->{'YRES'},
            $self->{'BYTES_PER_LINE'},
            $self->{'XOFFSET'}, $self->{'YOFFSET'},
            $params->{'image'},
            $x, $y, $w, $h,
            $bytes,
			$bits,
            $draw_mode,
            $self->{'COLOR_ALPHA'},
            $self->{'RAW_BACKGROUND_COLOR'},
            $self->{'X_CLIP'}, $self->{'Y_CLIP'}, $self->{'XX_CLIP'}, $self->{'YY_CLIP'}
        );
    } else {
        my $scrn = $params->{'image'};
        my $max  = $self->{'fscreeninfo'}->{'smem_len'} - $bytes;
        my $scan = $w * $bytes;
        my $yend = $y + $h;

        #    my $WW = $scan * $h;
        my $WW  = int((length($scrn) / $h));
        my $X_X = ($x + $self->{'XOFFSET'}) * $bytes;
        my ($index, $data, $px, $line, $idx, $px4, $buf, $ipx);

        $idx   = 0;
        $y    += $self->{'YOFFSET'};
        $yend += $self->{'YOFFSET'};

        eval {
            foreach $line ($y .. ($yend - 1)) {
                $index = ($self->{'BYTES_PER_LINE'} * $line) + $X_X;
                if ($index >= 0 && $index <= $max && $idx >= 0 && $idx <= (length($scrn) - $bytes)) {
                    if ($draw_mode == NORMAL_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan)  = substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == XOR_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) ^= substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == OR_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) |= substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == ADD_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) += substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == SUBTRACT_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) -= substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == MULTIPLY_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) *= substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == DIVIDE_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) /= substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == ALPHA_MODE) {
                        foreach $px (0 .. ($w - 1)) {
                            $px4  = $px * $bytes;
                            $ipx  = $index + $px4;
                            $data = substr($self->{'SCREEN'}, $ipx, $bytes) || chr(0) x $bytes;
                            if ($self->{'BITS'} == 32) {
                                my ($r, $g, $b, $a) = unpack("C$bytes", $data);
                                my ($R, $G, $B, $A) = unpack("C$bytes", substr($scrn, ($idx + $px4), $bytes));
                                my $invA            = (255 - $A);
                                $r                  = int(($R * $A) + ($r * $invA)) >> 8;
                                $g                  = int(($G * $A) + ($g * $invA)) >> 8;
                                $b                  = int(($B * $A) + ($b * $invA)) >> 8;

                                my $c = pack("C$bytes", $r, $g, $b, $A);
                                if (substr($scrn, ($idx + $px4), $bytes) ne $c) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = $c;
                                }
                            } elsif ($self->{'BITS'} == 24) {
                                my ($r, $g, $b) = unpack("C$bytes", $data);
                                my ($R, $G, $B) = unpack("C$bytes", substr($scrn, ($idx + $px4), $bytes));
                                my $A           = $self->{'COLOR_ALPHA'};
                                my $invA        = (255 - $A);
                                $r              = int(($R * $A) + ($r * $invA)) >> 8;
                                $g              = int(($G * $A) + ($g * $invA)) >> 8;
                                $b              = int(($B * $A) + ($b * $invA)) >> 8;
                                my $c           = pack('C3', $r, $g, $b);

                                if (substr($scrn, ($idx + $px4), $bytes) ne $c) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = $c;
                                }
                            } elsif ($self->{'BITS'} == 16) {
                                my $big         = $self->RGB565_to_RGB888({ 'color' => $data });
                                my ($r, $g, $b) = unpack('C3', $big->{'color'});
                                $big            = $self->RGB565_to_RGB888({ 'color' => substr($scrn, ($idx + $px4, $bytes)) });
                                my ($R, $G, $B) = unpack('C3', $big->{'color'});
                                my $A           = $self->{'COLOR_ALPHA'};
                                my $invA        = (255 - $A);
                                $r              = int(($R * $A) + ($r * $invA)) >> 8;
                                $g              = int(($G * $A) + ($g * $invA)) >> 8;
                                $b              = int(($B * $A) + ($b * $invA)) >> 8;
                                my $c           = $self->RGB888_to_RGB565({ 'color' => pack('C3', $r, $g, $b) });
                                $c              = $c->{'color'};

                                if (substr($scrn, ($idx + $px4), $bytes) ne $c) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = $c;
                                }
                            }
                        }
                    } elsif ($draw_mode == AND_MODE) {
                        substr($self->{'SCREEN'}, $index, $scan) &= substr($scrn, $idx, $scan);
                    } elsif ($draw_mode == MASK_MODE) {
                        foreach $px (0 .. ($w - 1)) {
                            $px4  = $px * $bytes;
                            $ipx  = $index + $px4;
                            $data = substr($self->{'SCREEN'}, $ipx, $bytes) || chr(0) x $bytes;
                            if ($self->{'BITS'} == 32) {
                                if (substr($scrn, ($idx + $px4), 3) ne substr($raw_background_color, 0, 3)) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = substr($scrn, ($idx + $px4), $bytes);
                                }
                            } elsif ($self->{'BITS'} == 24) {
                                if (substr($scrn, ($idx + $px4), 3) ne $raw_background_color) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = substr($scrn, ($idx + $px4), $bytes);
                                }
                            } elsif ($self->{'BITS'} == 16) {
                                if (substr($scrn, ($idx + $px4), 2) ne $raw_background_color) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = substr($scrn, ($idx + $px4), $bytes);
                                }
                            }
                        }
                    } elsif ($draw_mode == UNMASK_MODE) {
                        foreach $px (0 .. ($w - 1)) {
                            $px4  = $px * $bytes;
                            $ipx  = $index + $px4;
                            $data = substr($self->{'SCREEN'}, $ipx, $bytes);
                            if ($self->{'BITS'} == 32) {
                                if (substr($self->{'SCREEN'}, $ipx, 3) eq substr($raw_background_color, 0, 3)) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = substr($scrn, ($idx + $px4), $bytes);
                                }
                            } elsif ($self->{'BITS'} == 24) {
                                if (substr($self->{'SCREEN'}, $ipx, 3) eq $raw_background_color) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = substr($scrn, ($idx + $px4), $bytes);
                                }
                            } elsif ($self->{'BITS'} == 16) {
                                if (substr($self->{'SCREEN'}, $ipx, 2) eq $raw_background_color) {
                                    substr($self->{'SCREEN'}, $ipx, $bytes) = substr($scrn, ($idx + $px4), $bytes);
                                }
                            }
                        }
                    }
                    $idx += $WW;
                }
            }
        };
        if ($@) {
            warn __LINE__ . " $@" if ($self->{'SHOW_ERRORS'});
            $self->_fix_mapping();
        }
    }
}

sub _blit_adjust_for_clipping {
    # Chops up the blit image to stay within the clipping (and screen) boundaries
    # This prevents nasty crashes
    my $self    = shift;
    my $pparams = shift;

    my $bytes  = $self->{'BYTES'};
    my $yclip  = $self->{'Y_CLIP'};
    my $xclip  = $self->{'X_CLIP'};
    my $yyclip = $self->{'YY_CLIP'};
    my $xxclip = $self->{'XX_CLIP'};
    my $params;

    # Make a copy so the original isn't modified.
    %{$params} = %{$pparams};

    # First fix the vertical errors
    my $XX = $params->{'x'} + $params->{'width'};
    my $YY = $params->{'y'} + $params->{'height'};
    return (undef) if ($YY < $yclip || $params->{'height'} < 1 || $XX < $xclip || $params->{'x'} > $xxclip);
    if ($params->{'y'} < $yclip) {    # Top
        $params->{'image'}   = substr($params->{'image'}, ($yclip - $params->{'y'}) * ($params->{'width'} * $bytes));
        $params->{'height'} -= ($yclip - $params->{'y'});
        $params->{'y'}       = $yclip;
    }
    $YY = $params->{'y'} + $params->{'height'};
    return (undef) if ($params->{'height'} < 1);
    if ($YY > $yyclip) {              # Bottom
        $params->{'image'}  = substr($params->{'image'}, 0, ($yyclip - $params->{'y'}) * ($params->{'width'} * $bytes));
        $params->{'height'} = $yyclip - $params->{'y'};
    }

    # Now we fix the horizontal errors
    if ($params->{'x'} < $xclip) {    # Left
        my $line  = $params->{'width'} * $bytes;
        my $index = ($xclip - $params->{'x'}) * $bytes;
        my $w     = $params->{'width'} - ($xclip - $params->{'x'});
        my $new   = '';
        foreach my $yl (0 .. ($params->{'height'} - 1)) {
            $new .= substr($params->{'image'}, ($line * $yl) + $index, $w * $bytes);
        }
        $params->{'image'} = $new;
        $params->{'width'} = $w;
        $params->{'x'}     = $xclip;
    }
    $XX = $params->{'x'} + $params->{'width'};
    if ($XX > $xxclip) {    # Right
        my $line = $params->{'width'} * $bytes;
        my $new  = '';
        my $w    = $xxclip - $params->{'x'};
        foreach my $yl (0 .. ($params->{'height'} - 1)) {
            $new .= substr($params->{'image'}, $line * $yl, $w * $bytes);
        }
        $params->{'image'} = $new;
        $params->{'width'} = $w;
    }

    my $size = ($params->{'width'} * $params->{'height'}) * $bytes;
    if (length($params->{'image'}) < $size) {
        $params->{'image'} .= chr(0) x ($size - length($params->{'image'}));
    } elsif (length($params->{'image'}) > $size) {
        $params->{'image'} = substr($params->{'image'}, 0, $size);
    }
    return ($params);
}

sub blit_transform {
=head2 blit_transform

This performs transformations on your blit objects.

You can only have one of "rotate", "scale", "merge", "flip", or make "monochrome".  You may use only one transformation per call.

=over 8

* B<blit_data> (mandatory)

Used by all transformations.  It's the image data to process, in the format that "blit_write" uses.  See the example below.

* B<flip>

Flips the image either "horizontally, "vertically, or "both"

* B<merge>

Merges one image on top of the other.  "blit_data" is the top image, and "dest_blit_data" is the background image.  This takes into account alpha data values for each pixel (if in 32 bit mode).

This is very usefull in 32 bit mode due to its alpha channel capabilities.

* B<rotate>

Rotates the "blit_data" image an arbitrary degree.  Positive degree values are counterclockwise and negative degree values are clockwise.

Two types of rotate methods are available, an extrememly fast, but visually slightly less appealing method, and a slower, but looks better, method.  Seriously though, the fast method looks pretty darn good anyway.  I recommend "fast".

* B<scale>

Scales the image to "width" x "height".  This is the same as how scale works in "load_image".  The "type" value tells it how to scale (see the example).

=back

=over 4

 $fb->blit_transform(
     {
         # blit_data is mandatory
         'blit_data' => { # Same as what blit_read or load_image returns
             'x'      => 0, # This is relative to the dimensions of "dest_blit_data" for "merge"
             'y'      => 0, # ^^
             'width'  => 300,
             'height' => 200,
             'image'  => $image_data
         },

         'merge'  => {
             'dest_blit_data' => { # MUST have same or greater dimensions as 'blit_data'
                 'x'      => 0,
                 'y'      => 0,
                 'width'  => 300,
                 'height' => 200,
                 'image'  => $image_data
             }
         },

         'rotate' => {
             'degrees' => 45, # 0-360 degrees. Negative numbers rotate clockwise.
             'quality' => 'high', # "high" or "fast" are your choices, with "fast" being the default
         },

         'flip' => 'horizontal', # or "vertical" or "both"

         'scale'  => {
             'x'          => 0,
             'y'          => 0,
             'width'      => 500,
             'height'     => 300,
             'scale_type' => 'min' #  'min'     = The smaller of the two
                                   #              sizes are used (default)
                                   #  'max'     = The larger of the two
                                   #              sizes are used
                                   #  'nonprop' = Non-proportional sizing
                                   #              The image is scaled to
                                   #              width x height exactly.
         },

         'monochrome' => TRUE      # Makes the image data monochrome
     }
 );

=back

It returns the transformed image in the same format the other BLIT methods use.  Note, the width and height may be changed!  So always use the returned data as the correct new data.

=over 4

 {
     'x'      => 0,     # copied from "blit_data"
     'y'      => 0,     # copied from "blit_data"
     'width'  => 100,   # width of transformed image data
     'height' => 100,   # height of transformed image data
     'image'  => $image # image data
 }

=back

* Rotate and Flip are affected by the acceleration setting.

=cut

    my $self   = shift;
    my $params = shift;

    my $width  = $params->{'blit_data'}->{'width'};
    my $height = $params->{'blit_data'}->{'height'};
    my $bytes  = $self->{'BYTES'};
	my $min_bytes = max(3,$bytes);
	my $bits   = $self->{'BITS'};
    my $bline  = $width * $bytes;
    my $image  = $params->{'blit_data'}->{'image'};
    my $xclip  = $self->{'X_CLIP'};
    my $yclip  = $self->{'Y_CLIP'};
    my $data;

    if (exists($params->{'merge'})) {
        $image = $self->_convert_16_to_24($image, RGB) if ($self->{'BITS'} == 16);
        eval {
            my $img = Imager->new();
            $img->read(
                'xsize'             => $width,
                'ysize'             => $height,
                'raw_datachannels'  => $min_bytes,
                'raw_storechannels' => $min_bytes,
                'raw_interleave'    => FALSE,
                'data'              => $image,
                'type'              => 'raw',
                'allow_incomplete'  => TRUE
            );
            my $dest = Imager->new();
            $dest->read(
                'xsize'             => $params->{'merge'}->{'dest_blit_data'}->{'width'},
                'ysize'             => $params->{'merge'}->{'dest_blit_data'}->{'height'},
                'raw_datachannels'  => $min_bytes,
                'raw_storechannels' => $min_bytes,
                'raw_interleave'    => FALSE,
                'data'              => $params->{'merge'}->{'dest_blit_data'}->{'image'},
                'type'              => 'raw',
                'allow_incomplete'  => TRUE
            );
            $dest->compose(
                'src' => $img,
                'tx'  => $params->{'blit_data'}->{'x'},
                'ty'  => $params->{'blit_data'}->{'y'},
            );
            $width  = $dest->getwidth();
            $height = $dest->getheight();
            $dest->write(
                'type'          => 'raw',
                'datachannels'  => $min_bytes,
                'storechannels' => $min_bytes,
                'interleave'    => FALSE,
                'data'          => \$data
            );
        };
        warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});

        $data = $self->_convert_24_to_16($data, RGB) if ($self->{'BITS'} == 16);
        return (
            {
                'x'      => $params->{'merge'}->{'dest_blit_data'}->{'x'},
                'y'      => $params->{'merge'}->{'dest_blit_data'}->{'y'},
                'width'  => $width,
                'height' => $height,
                'image'  => $data
            }
        );
    }
    if (exists($params->{'flip'})) {
        my $image = "$params->{'blit_data'}->{'image'}";
        my $new   = '';
        if ($self->{'ACCELERATED'}) {
            $new = "$image";
            if (lc($params->{'flip'}) eq 'vertical') {
                c_flip_vertical($new, $width, $height, $bytes);
            } elsif (lc($params->{'flip'}) eq 'horizontal') {
                c_flip_horizontal($new, $width, $height, $bytes);
            } elsif (lc($params->{'flip'}) eq 'both') {
                c_flip_both($new, $width, $height, $bytes);
            }
        } else {
            if (lc($params->{'flip'}) eq 'vertical') {
                for (my $y = ($height - 1); $y >= 0; $y--) {
                    $new .= substr($image, ($y * $bline), $bline);
                }
            } elsif (lc($params->{'flip'}) eq 'horizontal') {
                foreach my $y (0 .. ($height - 1)) {
                    for (my $x = ($width - 1); $x >= 0; $x--) {
                        $new .= substr($image, (($x * $bytes) + ($y * $bline)), $bytes);
                    }
                }
            } else {
                $new = "$image";
            }
        }
        return (
            {
                'x'      => $params->{'blit_data'}->{'x'},
                'y'      => $params->{'blit_data'}->{'y'},
                'width'  => $width,
                'height' => $height,
                'image'  => $new
            }
        );
    } elsif (exists($params->{'rotate'})) {
        my $degrees = $params->{'rotate'}->{'degrees'};
        while (abs($degrees) > 360) {    # normalize
            if ($degrees > 360) {
                $degrees -= 360;
            } else {
                $degrees += 360;
            }
        }
        return ($params->{'blit_data'}) if (abs($degrees) == 360 || $degrees == 0);    # 0 and 360 are not a rotation
        unless ($params->{'rotate'}->{'quality'} eq 'high' || $self->{'ACCELERATED'} == PERL) {
            if (abs($degrees) == 180) {
                my $new = "$image";
                c_flip_both($new, $width, $height, $bytes);
                return (
                    {
                        'x'      => $params->{'blit_data'}->{'x'},
                        'y'      => $params->{'blit_data'}->{'y'},
                        'width'  => $width,
                        'height' => $height,
                        'image'  => $new
                    }
                );
            } else {
                my $wh = int(sqrt($width**2 + $height**2) + .5);

                # Try to define as much as possible before the loop to optimize
                $data = $self->{'RAW_BACKGROUND_COLOR'} x (($wh**2) * $bytes);

                c_rotate($image, $data, $width, $height, $wh, $degrees, $bytes, $bits);
                return (
                    {
                        'x'      => $params->{'blit_data'}->{'x'},
                        'y'      => $params->{'blit_data'}->{'y'},
                        'width'  => $wh,
                        'height' => $wh,
                        'image'  => $data
                    }
                );
            }
        } else {
            eval {
                my $img = Imager->new();
                $image = $self->_convert_16_to_24($image, RGB) if ($self->{'BITS'} == 16);
                $img->read(
                    'xsize'             => $width,
                    'ysize'             => $height,
                    'raw_storechannels' => $min_bytes,
                    'raw_datachannels'  => $min_bytes,
                    'raw_interleave'    => FALSE,
                    'data'              => $image,
                    'type'              => 'raw',
                    'allow_incomplete'  => TRUE
                );
                my $rotated;
                if (abs($degrees) == 90 || abs($degrees) == 180 || abs($degrees) == 270) {
                    $rotated = $img->rotate('right' => 0 - $degrees, 'back' => $self->{'IMAGER_BACKGROUND_COLOR'});
                } else {
                    $rotated = $img->rotate('degrees' => 0 - $degrees, 'back' => $self->{'IMAGER_BACKGROUND_COLOR'});
                }
                $width  = $rotated->getwidth();
                $height = $rotated->getheight();
                $img    = $rotated;
                $img->write(
                    'type'          => 'raw',
                    'storechannels' => $min_bytes,
                    'interleave'    => FALSE,
                    'data'          => \$data
                );
                $data = $self->_convert_24_to_16($data, RGB) if ($self->{'BITS'} == 16);
            };
            warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});
        }
        return (
            {
                'x'      => $params->{'blit_data'}->{'x'},
                'y'      => $params->{'blit_data'}->{'y'},
                'width'  => $width,
                'height' => $height,
                'image'  => $data
            }
        );
    } elsif (exists($params->{'scale'})) {
        $image = $self->_convert_16_to_24($image, $self->{'COLOR_ORDER'}) if ($self->{'BITS'} == 16);

        eval {
            my $img = Imager->new();
            $img->read(
                'xsize'             => $width,
                'ysize'             => $height,
                'raw_storechannels' => $min_bytes,
                'raw_datachannels'  => $min_bytes,
                'raw_interleave'    => FALSE,
                'data'              => $image,
                'type'              => 'raw',
                'allow_incomplete'  => TRUE
            );

            $img = $img->convert('preset' => 'addalpha') if ($self->{'BITS'} == 32);
            my %scale = (
                'xpixels' => $params->{'scale'}->{'width'},
                'ypixels' => $params->{'scale'}->{'height'},
                'type'    => $params->{'scale'}->{'scale_type'} || 'min'
            );
            my ($xs, $ys);

            ($xs, $ys, $width, $height) = $img->scale_calculate(%scale);
            my $scaledimg = $img->scale(%scale);
            $scaledimg->write(
                'type'          => 'raw',
                'storechannels' => $min_bytes,
                'interleave'    => FALSE,
                'data'          => \$data
            );
        };
        warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});
        $data = $self->_convert_24_to_16($data, $self->{'COLOR_ORDER'}) if ($self->{'BITS'} == 16);
        return (
            {
                'x'      => $params->{'blit_data'}->{'x'},
                'y'      => $params->{'blit_data'}->{'y'},
                'width'  => $width,
                'height' => $height,
                'image'  => $data
            }
        );
    } elsif (exists($params->{'monochrome'})) {
        return ($self->monochrome({ 'image' => $params->{'blit_data'}, 'bits' => $self->{'BITS'} }));
    } elsif (exists($params->{'center'})) {
        my $XX = $self->{'W_CLIP'};
        my $YY = $self->{'H_CLIP'};
        my ($x, $y) = ($params->{'blit_data'}->{'x'}, $params->{'blit_data'}->{'y'});
        if ($params->{'center'} == CENTER_X || $params->{'center'} == CENTER_XY) {
            $x = $xclip + int(($XX - $width) / 2);
        }
        if ($params->{'center'} == CENTER_Y || $params->{'center'} == CENTER_XY) {
            $y = $self->{'Y_CLIP'} + int(($YY - $height) / 2);
        }
        return (
            {
                'x'      => $x,
                'y'      => $y,
                'width'  => $width,
                'height' => $height,
                'image'  => $params->{'blit_data'}->{'image'}
            }
        );

    }
}

sub clip_reset {
=head2 clip_reset

Turns off clipping, and resets the clipping values to the full size of the screen.

=over 4

 $fb->clip_reset();

=back
=cut

    # Clipping is not really turned off.  It's just set to the screen borders.  To turn off clipping for real is asking for crashes.
    my $self = shift;

    $self->{'X_CLIP'}  = 0;
    $self->{'Y_CLIP'}  = 0;
    $self->{'XX_CLIP'} = ($self->{'XRES'} - 1);
    $self->{'YY_CLIP'} = ($self->{'YRES'} - 1);
    $self->{'W_CLIP'}  = $self->{'XRES'};
    $self->{'H_CLIP'}  = $self->{'YRES'};
    $self->{'CLIPPED'} = FALSE;                                    ## This is merely a flag to see if a clipping
    ## region is defined under the screen dimensions.
}

sub clip_off {
=head2 clip_off

This is an alias to 'clip_reset'

=cut

    my $self = shift;
    $self->clip_reset();
}

sub clip_set {
=head2 clip_set

Sets the clipping rectangle starting at the top left point x,y and ending at bottom right point xx,yy.

=over 4

 $fb->clip_set({
    'x'  => 10,
    'y'  => 10,
    'xx' => 300,
    'yy' => 300
 });

=back
=cut

    my $self   = shift;
    my $params = shift;

    $self->{'X_CLIP'}  = abs(int($params->{'x'}));
    $self->{'Y_CLIP'}  = abs(int($params->{'y'}));
    $self->{'XX_CLIP'} = abs(int($params->{'xx'}));
    $self->{'YY_CLIP'} = abs(int($params->{'yy'}));

    $self->{'X_CLIP'}  = ($self->{'XRES'} - 2) if ($self->{'X_CLIP'} > ($self->{'XRES'} - 1));
    $self->{'Y_CLIP'}  = ($self->{'YRES'} - 2) if ($self->{'Y_CLIP'} > ($self->{'YRES'} - 1));
    $self->{'XX_CLIP'} = ($self->{'XRES'} - 1) if ($self->{'XX_CLIP'} >= $self->{'XRES'});
    $self->{'YY_CLIP'} = ($self->{'YRES'} - 1) if ($self->{'YY_CLIP'} >= $self->{'YRES'});
    $self->{'W_CLIP'}  = $self->{'XX_CLIP'} - $self->{'X_CLIP'};
    $self->{'H_CLIP'}  = $self->{'YY_CLIP'} - $self->{'Y_CLIP'};
    $self->{'CLIPPED'} = TRUE;
}

sub clip_rset {
=head2 clip_rset

Sets the clipping rectangle to point x,y,width,height

=over 4

 $fb->clip_rset({
    'x'      => 10,
    'y'      => 10,
    'width'  => 600,
    'height' => 400
 });

=back
=cut

    my $self   = shift;
    my $params = shift;

    $params->{'xx'} = $params->{'x'} + $params->{'width'};
    $params->{'yy'} = $params->{'y'} + $params->{'height'};

    $self->clip_set($params);
}

sub monochrome {
=head2 monochrome

Removes all color information from an image, and leaves everything in greyscale.

It applies the following formula to calculate greyscale:

 grey_color = (red * 0.2126) + (green * 0.7155) + (blue * 0.0722)

=over 4

 Expects two parameters, 'image' and 'bits'.  The parameter 'image' is a string containing the image data.  The parameter 'bits' is how many bits per pixel make up the image.  Valid values are 16, 24, and 32 only.

 $fb->monochrome({
     'image' => "image data",
     'bits'  => 32
 });

 It returns 'image' back, but now in greyscale (still the same RGB format though).

 {
     'image' => "monochrome image data"
 }

=back

* You should normally use "blit_transform", but this is a more raw way of affecting the data

=cut

	##########################################################################
	# This applies a well known set of blending constants to create a        #
	# monochrome representation of a color image                             #
	#                                                                        #
	# Multiply each color by the constant, then add them together to get the #
	# final monochrome value.                                                #
	#                                                                        #
	# NEWRED     = RED   * 0.2126                                            #
	# NEWGREEN   = GREEN * 0.7115                                            #
	# NEWBLUE    = BLUE  * 0.0722                                            #
	# MONOCHROME = NEWRED + NEWGREEN + NEWBLUE                               #
	##########################################################################

    my $self   = shift;
    my $params = shift;

    my ($r, $g, $b);

    my ($ro, $go, $bo) = ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'}, $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'}, $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'});
    my ($rl, $gl, $bl) = ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'}, $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'}, $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'});

    my $color_order = $self->{'COLOR_ORDER'};
    my $size        = length($params->{'image'});

    my $inc;
    if ($params->{'bits'} == 32) {
        $inc = 4;
    } elsif ($params->{'bits'} == 24) {
        $inc = 3;
    } elsif ($params->{'bits'} == 16) {
        $inc = 2;
    } else {    # Only 32, 24, or 16 bits allowed
        $inc = 1;
    }
    if ($self->{'ACCELERATED'}) {
        c_monochrome($params->{'image'}, $size, $color_order, $inc, $params->{'bits'});
        return ($params->{'image'});
    } else {
        for (my $byte = 0; $byte < length($params->{'image'}); $byte += $inc) {
            if ($inc == 2) {
                my $rgb565 = unpack('S', substr($params->{'image'}, $byte, $inc));
                if ($color_order == RGB) {
                    $r = $rgb565 & 31;
                    $g = (($rgb565 >> 5)  & 63) / 2;    # Normalize green
                    $b = ($rgb565  >> 11) & 31;
                } elsif ($color_order == BGR) {
                    $b = $rgb565 & 31;
                    $g = (($rgb565 >> 5) & 63) / 2;     # Normalize green
                    $r = ($rgb565 >> 11) & 31;
                }
                my $mono = int(0.2126 * $r + 0.7155 * $g + 0.0722 * $b);
                substr($params->{'image'}, $byte, $inc) = pack('S', ($go ? ($mono * 2) << $go : ($mono * 2)) | ($ro ? $mono << $ro : $mono) | ($bo ? $mono << $bo : $mono));
            } else {
                if ($color_order == BGR) {
                    ($b, $g, $r) = unpack('C3', substr($params->{'image'}, $byte, 3));
                } elsif ($color_order == BRG) {
                    ($b, $r, $g) = unpack('C3', substr($params->{'image'}, $byte, 3));
                } elsif ($color_order == RGB) {
                    ($r, $g, $b) = unpack('C3', substr($params->{'image'}, $byte, 3));
                } elsif ($color_order == RBG) {
                    ($r, $b, $g) = unpack('C3', substr($params->{'image'}, $byte, 3));
                } elsif ($color_order == GRB) {
                    ($g, $r, $b) = unpack('C3', substr($params->{'image'}, $byte, 3));
                } elsif ($color_order == GBR) {
                    ($g, $b, $r) = unpack('C3', substr($params->{'image'}, $byte, 3));
                }
                my $mono = int(0.2126 * $r + 0.7155 * $g + 0.0722 * $b);
                substr($params->{'image'}, $byte, 3) = pack('C3', $mono, $mono, $mono);
            }
        }
    }
    return ($params->{'image'});
}

sub ttf_print {
=head2 ttf_print

Prints TrueType text on the screen at point x,y in the rectangle width,height, using the color 'color', and the face 'face' (using the Imager library as its engine).

Note, 'y' is the baseline position, not the top left of the bounding box.  This is a change from before!!!

This is best called twice, first in bounding box mode, and then in normal mode.

Bounding box mode gets the actual values needed to display the text.

If draw mode is "normal", then mask mode is automatically used for best output.

=over 4

 my $bounding_box = $fb->ttf_print({
     'x'            => 20,
     'y'            => 100, # baseline position
     'height'       => 16,
     'wscale'       => 1,   # Scales the width.  1 is normal
     'color'        => 'FFFF00FF', # Hex value of color 00-FF (RRGGBBAA)
     'text'         => 'Hello World!',
     'font_path'    => '/usr/share/fonts/truetype', # Optional
     'face'         => 'Arial.ttf',                 # Optional
     'bounding_box' => TRUE,
     'center'       => CENTER_X,
     'antialias'    => TRUE
 });

 $fb->ttf_print($bounding_box);

=back

Here's a shortcut:

=over 4

 $fb->ttf_print(
     $fb->ttf_print({
         'x'            => 20,
         'y'            => 100, # baseline position
         'height'       => 16,
         'color'        => 'FFFF00FF', # RRGGBBAA
         'text'         => 'Hello World!',
         'font_path'    => '/usr/share/fonts/truetype', # Optional
         'face'         => 'Arial.ttf',                 # Optional
         'bounding_box' => TRUE,
         'rotate'       => 45,    # optonal
         'center'       => CENTER_X,
         'antialias'    => 1,
         'shadow'       => shadow size
     })
 );

=back

Failures of this method are usually due to it not being able to find the font.  Make sure you have the right path and name.

=cut

    ##############################################################################
    # Yes, this is a "hack".                                                     #
    # -------------------------------------------------------------------------- #
    # This uses the 'Imager' package.  It allocates a temporary screen buffer    #
    # and prints to it, then this buffer is dumped to the screen at the x,y      #
    # coordinates given.  Since no decent True Type packages or libraries are    #
    # available for Perl, this turned out to be the best and easiest solution.   #
    ##############################################################################

    my $self   = shift;
    my $params = shift;

    return ($params) unless (defined($params));

    my $TTF_x       = int($params->{'x'})       || 0;
    my $TTF_y       = int($params->{'y'})       || 0;
    my $TTF_pw      = int($params->{'pwidth'})  || 6;
    my $TTF_ph      = int($params->{'pheight'}) || 6;
    my $TTF_h       = int($params->{'height'})  || 6;
    my $text        = $params->{'text'}         || ' ';
    my $face        = $params->{'face'}         || $self->{'FONT_FACE'};
    my $box_mode    = $params->{'bounding_box'} || FALSE;
    my $center_mode = $params->{'center'}       || 0;
    my $font_path   = $params->{'font_path'}    || $self->{'FONT_PATH'};
    my $aa          = $params->{'antialias'}    || FALSE;
    my $P_color     = $params->{'color'} if (exists($params->{'color'}));
    my $sizew       = $TTF_h;
    $sizew *= $params->{'wscale'} if (exists($params->{'wscale'}) && defined($params->{'wscale'}));
    my $pfont = "$font_path/$face";

    $pfont =~ s#/+#/#g;    # Get rid of doubled up slashes

    my $color_order = $self->{'COLOR_ORDER'};
    my $bytes       = $self->{'BYTES'};
	my $min_bytes   = $self->{'MIN_BYTES'};
    my ($data, $shadow_font, $neg_width, $global_descent, $pos_width, $global_ascent, $descent, $ascent, $advance_width, $right_bearing);    # = ('','',0,0,0,0,0,0,0,0);

    if (defined($P_color)) {
        $P_color .= 'FF' if (length($P_color) < 8);                                                                                          # Add opague alpha if it is not defined
        my ($red, $green, $blue, $alpha) = (substr($P_color, 0, 2), substr($P_color, 2, 2), substr($P_color, 4, 2), substr($P_color, 6, 2));
        if ($color_order == BGR) {
            $P_color = $blue . $green . $red . $alpha;
        } elsif ($color_order == BRG) {
            $P_color = $blue . $red . $green . $alpha;
        } elsif ($color_order == RBG) {
            $P_color = $red . $blue . $green . $alpha;
        } elsif ($color_order == GRB) {
            $P_color = $green . $red . $blue . $alpha;
        } elsif ($color_order == GBR) {
            $P_color = $green . $blue . $red . $alpha;
        }
    } else {
        $P_color = $self->{'IMAGER_FOREGROUND_COLOR'};
    }

    my $font = Imager::Font->new(
        'file'  => $pfont,
        'color' => $P_color,
        'size'  => $TTF_h,
		'aa'    => $aa,
    );
    unless (defined($font)) {
        warn __LINE__ . " Can't initialize Imager::Font!\n", Imager->errstr() if ($self->{'SHOW_ERRORS'});
        return (undef);
    }
    if (defined($params->{'rotate'}) && abs($params->{'rotate'}) > 0 && abs($params->{'rotate'} < 360)) {
        my $matrix;
        eval {
            $matrix = Imager::Matrix2d->rotate('degrees' => $params->{'rotate'});
            $font->transform('matrix' => $matrix);
            my $bbox = $font->bounding_box('string' => $text, 'canon' => 1, 'size' => $TTF_h, 'sizew' => $sizew);
            my ($left, $miny, $right, $maxy) = _transformed_bounds($bbox, $matrix);
            my ($top, $bottom) = (-$maxy, -$miny);
            ($TTF_pw, $TTF_ph) = ($right - $left, $bottom - $top);
            $params->{'pwidth'}  = $TTF_pw;
            $params->{'pheight'} = $TTF_ph;
        };
        warn __LINE__ . " $@\n", Imager->errstr() if ($@ && $self->{'SHOW_ERRORS'});
    } else {
        eval { ($neg_width, $global_descent, $pos_width, $global_ascent, $descent, $ascent, $advance_width, $right_bearing) = $font->bounding_box('string' => $text, 'canon' => 1, 'size' => $TTF_h, 'sizew' => $sizew); };
        if ($@) {
            warn __LINE__ . " $@\n", Imager->errstr() if ($self->{'SHOW_ERRORS'});
            return (undef);
        }
        $params->{'pwidth'}  = $advance_width;
        $params->{'pheight'} = abs($global_ascent) + abs($global_descent) + 12;    # int($TTF_h + $global_ascent + abs($global_descent));
        $TTF_pw              = abs($advance_width);
    }
    if ($center_mode == CENTER_XY) {
        $TTF_x = int(($self->{'W_CLIP'} - $TTF_pw) / 2) + $self->{'X_CLIP'};
        $TTF_y = int(($self->{'H_CLIP'} - $TTF_ph) / 2) + abs($global_ascent);
    } elsif ($center_mode == CENTER_X) {
        $TTF_x = int(($self->{'W_CLIP'} - $TTF_pw) / 2) + $self->{'X_CLIP'};
    } elsif ($center_mode == CENTER_Y) {
        $TTF_y = int(($self->{'H_CLIP'} - $TTF_ph) / 2) + abs($global_ascent);
    }
    $params->{'bounding_box'} = FALSE;
    if ($box_mode) {
        $params->{'x'} = $TTF_x;
        $params->{'y'} = $TTF_y;
        return ($params);
    }
    my $img;
    my $image;
    my $draw_mode;
    if ($TTF_pw <= 0 || $TTF_ph <= 0) {
        warn __LINE__ . " Calculated size of font width/height is less than or equal to zero!  Cannot render font." if ($self->{'SHOW_ERRORS'});
        return (undef);
    }
    eval {
        $img = Imager->new(
            'xsize'    => $TTF_pw,
            'ysize'    => $TTF_ph,
            'channels' => max(3, $bytes)
        );
        unless ($self->{'DRAW_MODE'}) {
            if ($self->{'ACCELERATED'} && !$aa) {
                $draw_mode = $self->{'DRAW_MODE'};
                $self->{'DRAW_MODE'} = MASK_MODE;
            } else {
                my $ty = $TTF_y - abs($global_ascent);
                $ty = 0 if ($ty < 0);
                $image = $self->blit_read({ 'x' => $TTF_x, 'y' => $ty, 'width' => $TTF_pw, 'height' => $TTF_ph });
                $image->{'image'} = $self->_convert_16_to_24($image->{'image'}, RGB) if ($self->{'BITS'} == 16);
                $img->read(
                    'data'              => $image->{'image'},
                    'type'              => 'raw',
                    'raw_datachannels'  => $min_bytes,
                    'raw_storechannels' => $min_bytes,
                    'raw_interleave'    => FALSE,
                    'xsize'             => $TTF_pw,
                    'ysize'             => $TTF_ph
                );
            }
        }
        $img->string(
            'font'  => $font,
            'text'  => $text,
            'x'     => 0,
            'y'     => abs($ascent),
            'size'  => $TTF_h,
            'sizew' => $sizew,
            'color' => $P_color,
            'aa'    => $aa,
        );
        $img->write(
            'type'          => 'raw',
            'storechannels' => $min_bytes,    # Must be at least 24 bit
            'interleave'    => FALSE,
            'data'          => \$data
        );
    };
    if ($@) {
        warn __LINE__ . " ERROR $@\n", Imager->errstr() . "\n$TTF_pw,$TTF_ph" if ($self->{'SHOW_ERRORS'});
        return (undef);
    }
    $data = $self->_convert_24_to_16($data, RGB) if ($self->{'BITS'} == 16);
    $self->blit_write({ 'x' => $TTF_x, 'y' => ($TTF_y - abs($global_ascent)), 'width' => $TTF_pw, 'height' => $TTF_ph, 'image' => $data });
    $self->{'DRAW_MODE'} = $draw_mode if (defined($draw_mode));
    return ($params);
}

sub ttf_paragraph {
=head2 ttf_paragraph

Very similar to an ordinary Perl "print", but uses TTF fonts instead.  It will automatically wrap text like a terminal.

This uses no bounding boxes, and is only needed to be called once.  It uses a very simple wrapping model.

It uses the clipping rectangle.  All text will be fit and wrapped within the clipping rectangle.

Text is started at "x" and wrapped to "x" for each line, no indentation.

* This does I<NOT> scroll text.  It merely truncates what doesn't fit.  It returns where in the text string it last printed before truncation.  It's also quite slow.

=over 4

 $fb->ttf_paragraph(
     {
         'text'      => 'String to print',

         'x'         => 0,                  # Where to start printing
         'y'         => 20,                 #

         'size'      => 12,                 # Optional Font size, default is 16

         'color'     => 'FFFF00FF',         # RRGGBBAA

         'justify'   => 'justified'         # Optional justification, default
                                            # is "left".  Posible values are:
                                            #  "left", "right", "center", and
                                            #  "justified"

         'line_spacing' => 5,               # This adjusts the default line
                                            # spacing by positive or negative
                                            # amounts.  The default is 0.

         'face'      => 'Ariel',            # Optional, overrides the default

         'font_path' => '/usr/share/fonts', # Optional, else uses the default
     }
 );

=back

=cut

    my $self   = shift;
    my $params = shift;

    return ($params) unless (defined($params));

    my $TTF_x     = int($params->{'x'})            || 0;
    my $TTF_y     = int($params->{'y'})            || 0;
    my $TTF_size  = int($params->{'size'})         || 16;
    my $text      = $params->{'text'}              || ' ';
    my $face      = $params->{'face'}              || $self->{'FONT_FACE'};
    my $justify   = $params->{'justify'}           || 'left';
    $justify =~ s/centre/center/; # Wacky Brits and Canadians
    my $linegap   = int($params->{'line_spacing'}) || 0;
    my $font_path = $params->{'font_path'}         || $self->{'FONT_PATH'};
    my $P_color   = $params->{'color'} if (exists($params->{'color'}));
    my $pfont     = "$font_path/$face";

    $TTF_x  -= $self->{'X_CLIP'};
    $TTF_y  -= $self->{'Y_CLIP'};
    $justify = lc($justify);
    $justify =~ s/justified/fill/;
    $pfont   =~ s#/+#/#g;    # Get rid of doubled up slashes

    my $color_order = $self->{'COLOR_ORDER'};
    my $bytes       = $self->{'BYTES'};
	my $min_bytes   = $self->{'MIN_BYTES'};
    my $data;

    if (defined($P_color)) {
        $P_color .= 'FF' if (length($P_color) < 8);                                                                                          # Add opague alpha if it is not defined
        my ($red, $green, $blue, $alpha) = (substr($P_color, 0, 2), substr($P_color, 2, 2), substr($P_color, 4, 2), substr($P_color, 6, 2));
        if ($color_order == BGR) {
            $P_color = $blue . $green . $red . $alpha;
        } elsif ($color_order == BRG) {
            $P_color = $blue . $red . $green . $alpha;
        } elsif ($color_order == RBG) {
            $P_color = $red . $blue . $green . $alpha;
        } elsif ($color_order == GRB) {
            $P_color = $green . $red . $blue . $alpha;
        } elsif ($color_order == GBR) {
            $P_color = $green . $blue . $red . $alpha;
        }
    } else {
        $P_color = $self->{'IMAGER_FOREGROUND_COLOR'};
    }

    my $font = Imager::Font->new(
        'file'  => $pfont,
        'color' => $P_color,
    );
    unless (defined($font)) {
        warn __LINE__ . " Can't initialize Imager::Font!\n", Imager->errstr() if ($self->{'SHOW_ERRORS'});
        return (undef);
    }
    my $img;
    my $image;
    my $draw_mode;
    my $savepos;
    eval {
        $img = Imager->new(
            'xsize'    => $self->{'W_CLIP'},
            'ysize'    => $self->{'H_CLIP'},
            'channels' => max(3, $bytes)
        );
        unless ($self->{'DRAW_MODE'}) { # If normal mode, then don't bother
            if ($self->{'ACCELERATED'}) {
                $draw_mode           = $self->{'DRAW_MODE'};
                $self->{'DRAW_MODE'} = MASK_MODE;
            } else {
                $image = $self->blit_read({ 'x' => $self->{'X_CLIP'}, 'y' => $self->{'Y_CLIP'}, 'width' => $self->{'W_CLIP'}, 'height' => $self->{'H_CLIP'}});
                $image->{'image'} = $self->_convert_16_to_24($image->{'image'}, RGB) if ($self->{'BITS'} == 16);
                $img->read(
                    'data'              => $image->{'image'},
                    'type'              => 'raw',
                    'raw_datachannels'  => $min_bytes,
                    'raw_storechannels' => $min_bytes,
                    'raw_interleave'    => FALSE,
                    'xsize'             => $self->{'W_CLIP'},
                    'ysize'             => $self->{'H_CLIP'},
                );
            }
        }
        Imager::Font::Wrap->wrap_text(
            'x'       => $TTF_x,
            'y'       => $TTF_y,
            'size'    => $TTF_size,
            'string'  => $text,
            'font'    => $font,
            'image'   => $img,
            'justify' => $justify,
            'linegap' => $linegap,
            'savepos' => \$savepos,
        );
        $img->write(
            'type'          => 'raw',
            'storechannels' => $min_bytes,    # Must be at least 24 bit
            'interleave'    => FALSE,
            'data'          => \$data
        );
    };
    if ($@) {
        warn __LINE__ . " ERROR $@\n", Imager->errstr() if ($self->{'SHOW_ERRORS'});
        return (undef);
    }
    $data = $self->_convert_24_to_16($data, RGB) if ($self->{'BITS'} == 16);
    $self->blit_write({ 'x' => $self->{'X_CLIP'}, 'y' => $self->{'Y_CLIP'}, 'width' => $self->{'W_CLIP'}, 'height' => $self->{'H_CLIP'}, 'image' => $data });
    $self->{'DRAW_MODE'} = $draw_mode if (defined($draw_mode));
    return ($savepos);
}

sub _gather_fonts {
    # Gather in and find all the fonts
    my $self = shift;
    my $path = shift;

    opendir(my $DIR, $path);
    chomp(my @dir = readdir($DIR));
    closedir($DIR);

    foreach my $file (@dir) {
        next if ($file =~ /^\./);
        if (-d "$path/$file") {
            $self->_gather_fonts("$path/$file");
        } elsif (-f "$path/$file" && -s "$path/$file") { # Makes sure font is non-zero length
            if ($file =~ /\.ttf$/i && ($self->{'Imager-Has-TrueType'} || $self->{'Imager-Has-Freetype2'})) {
                my $face = $self->get_face_name({ 'font_path' => $path, 'face' => $file });
                $self->{'FONTS'}->{$face} = { 'path' => $path, 'font' => $file };
            } elsif ($file =~ /\.afb$/i && $self->{'Imager-Has-Type1'}) {
                my $face = $self->get_face_name({ 'font_path' => $path, 'face' => $file });
                $self->{'FONTS'}->{$face} = { 'path' => $path, 'font' => $file };
            }
        }
    }
}

sub get_face_name {
=head2 get_face_name

Returns the TrueType face name based on the parameters passed.

 my $face_name = $fb->get_face_name({
     'font_path' => '/usr/share/fonts/TrueType/',
     'face'      => 'FontFileName.ttf'
 });

=cut

    my $self   = shift;
    my $params = shift;

    my $file = $params->{'font_path'} . '/' . $params->{'face'};
    my $face = Imager::Font->new('file' => $file);
    if ($face->can('face_name')) {
        my $face_name = $face->face_name();
        if ($face_name eq '') {
            $face_name = $params->{'face'};
            $face_name =~ s/\.(ttf|pfb)$//i;
        }
        return ($face_name);
    }
    return ($file);
}

sub load_image {
=head2 load_image

Loads an image at point x,y[,width,height].  To display it, pass it to blit_write.

If you give centering options, the position to display the image is part of what is returned, and is ready for blitting.

If 'width' and/or 'height' is given, the image is resized.  Note, resizing is CPU intensive.  Nevertheless, this is done by the Imager library (compiled C) so it is relatively fast.

=over 4

 $fb->blit_write(
     $fb->load_image(
         {
             'x'          => 0,    # Optional (only applies if
                                   # CENTER_X or CENTER_XY is not
                                   # used)

             'y'          => 0,    # Optional (only applies if
                                   # CENTER_Y or CENTER_XY is not
                                   # used)

             'width'      => 1920, # Optional. Resizes to this maximum
                                   # width.  It fits the image to this
                                   # size.

             'height'     => 1080, # Optional. Resizes to this maximum
                                   # height.  It fits the image to this
                                   # size

             'scale_type' => 'min',# Optional. Sets the type of scaling
                                   #
                                   #  'min'     = The smaller of the two
                                   #              sizes are used (default)
                                   #  'max'     = The larger of the two
                                   #              sizes are used
                                   #  'nonprop' = Non-proportional sizing
                                   #              The image is scaled to
                                   #              width x height exactly.

             'autolevels' => FALSE,# Optional.  It does a color
                                   # correction. Sometimes this
                                   # works well, and sometimes it
                                   # looks quite ugly.  It depends
                                   # on the image

             'center'     => CENTER_XY, # Optional
                                   # Three centering options are available
                                   #  CENTER_X  = center horizontally
                                   #  CENTER_Y  = center vertically
                                   #  CENTER_XY = center horizontally and
                                   #              vertically.  Placing it
                                   #              right in the middle of
                                   #              the screen.

             'file'       => 'RWBY_Faces.png', # Usually needs full path

             'convertalpha' => TRUE, # Converts the color matching the global
                                   # background color to have the same alpha
                                   # channel value as the global background,
                                   # which is beneficial for using 'merge'
                                   # in 'blit_transform'.

             'preserve_transparency' => FALSE,
                                   # Preserve the transparency of GIFs for
                                   # use with "mask_mode" playback.
                                   # This can allow for slightly faster
                                   # playback of animated GIFs on systems
                                   # using the acceration features of this
                                   # module.  However, not all animated
                                   # GIFs look right when this is done.
                                   # the safest setting is to not use this,
                                   # and playback using normal_mode.

              'fpsmax' => 10,
                                   # If the file is a video file, it will be
                                   # converted to a GIF file.  This value
                                   # determines the maximum number of frames
                                   # per second allowed in the conversion.
                                   # Note, the higher the number, the slower
                                   # the conversion process.  This only works
                                   # if "ffmpeg" is installed.
         }
     )
 );

=back

If a single image is loaded, it returns a reference to an anonymous hash, of the format:

=over 4

 {
      'x'           => horizontal position calculated (or passed through),
      'y'           => vertical position calculated (or passed through),
      'width'       => Width of the image,
      'height'      => Height of the image,
      'tags'        => The tags of the image (hashref)
      'image'       => [raw image data]
 }

=back

If the image has multiple frames, then a reference to an array of hashes is returned:

=over 4

 # NOTE:  X and Y positions can change frame to frame, so use them for each frame!
 #        Also, X and Y are based upon what was originally passed through, else they
 #        reference 0,0 (but only if you didn't give an X,Y value initially).

 # ALSO:  The tags may also specify offsets, and they will be taken into account.

 [
     { # Frame 1
         'x'           => horizontal position calculated (or passed through),
         'y'           => vertical position calculated (or passed through),
         'width'       => Width of the image,
         'height'      => Height of the image,
         'tags'        => The tags of the image (hashref)
         'image'       => [raw image data]
     },
     { # Frame 2 (and so on)
         'x'           => horizontal position calculated (or passed through),
         'y'           => vertical position calculated (or passed through),
         'width'       => Width of the image,
         'height'      => Height of the image,
         'tags'        => The tags of the image (hashref)
         'image'       => [raw image data]
     }
 ]

=back

=cut

    my $self   = shift;
    my $params = shift;

    my @odata;
    my @Img;
    my ($x, $y, $xs, $ys, $w, $h, $last_img, $bench_scale, $bench_rotate, $bench_convert);
    my $bench_start    = time;
    my $bench_total    = $bench_start;
    my $bench_subtotal = $bench_start;
    my $bench_load     = $bench_start;
    my $color_order    = $self->{'COLOR_ORDER'};
	my $bytes          = $self->{'BYTES'};
	my $min_bytes      = $self->{'MIN_BYTES'};
    my $hold;
    if (defined($self->{'FFMPEG'}) && $params->{'file'} =~ /\.(mkv|mp4|avi|mpeg4|webp)$/i) { # This uses ffmpeg to convert a movie to a temporary GIF and then plays it
		my $quiet = ($self->{'SHOW_ERRORS'}) ? 'verbose' : 'quiet';
		my $fpsmax = (defined($params->{'fpsmax'})) ? $params->{'fpsmax'} : 10;
        warn "ffmpeg -i $params->{'file'} -y -fpsmax $fpsmax -loop 0 -loglevel $quiet '/tmp/output.gif'" if ($self->{'SHOW_ERRORS'});
        system($self->{'FFMPEG'},'-i',$params->{'file'},'-y', '-fpsmax',$fpsmax, '-loop','0','-loglevel',$quiet,'/tmp/output.gif');
		warn "Finished converting $params->{'file'}" if ($self->{'SHOW_ERRORS'});
        $hold = $params->{'file'};
        $params->{'file'} = '/tmp/output.gif';
    }
    if ($params->{'file'} =~ /\.(gif|png|apng)$/i) {
        eval {
            @Img = Imager->read_multi(
                'file'             => $params->{'file'},
                'allow_incomplete' => TRUE,
                'raw_datachannels' => $min_bytes, # One of these is bound to work
                'datachannels'     => $min_bytes,
            );
        };
        warn __LINE__ . " $@" if ($@ && $self->{'SHOW_ERRORS'});
    } else {
        eval {
            push(@Img,Imager->new(
                'file'             => $params->{'file'},
                'interleave'       => FALSE,
                'allow_incomplete' => TRUE,
                'datachannels'     => $min_bytes, # One of these is bound to work.
                'raw_datachannels' => $min_bytes,
            ));
        };
        warn __LINE__ . " $@" if ($@ && $self->{'SHOW_ERRORS'});
    }
    $bench_load = sprintf('%.03f', time - $bench_load);
    unless (defined($Img[0])) {
        warn __LINE__ . " I can't get Imager to set up an image buffer $params->{'file'}!  Check your Imager installation.\n", Imager->errstr() if ($self->{'SHOW_ERRORS'});
    } else {
        foreach my $img (@Img) {
            next unless (defined($img));
            $bench_subtotal = time;
            my %tags = map(@$_, $img->tags());
            # Must loop and layer the frames on top of each other to get full frames.
            unless (exists($params->{'gif_left'})) {
                if (defined($last_img)) {
                    $last_img->compose(
                        'src' => $img,
                        'tx'  => $tags{'gif_left'},
                        'ty'  => $tags{'gif_top'},
                    );
                    $img = $last_img;
                }
                $last_img = $img->copy() unless (defined($last_img));
            }
            $bench_rotate = time;
            if (exists($tags{'exif_orientation'})) {
                my $orientation = $tags{'exif_orientation'};
                if (defined($orientation) && $orientation) {    # Automatically rotate the image to correct
                    if ($orientation == 3) {                    # 180 (It's upside down)
                        $img = $img->rotate('degrees' => 180);
                    } elsif ($orientation == 6) {               # -90 (It's on its left side)
                        $img = $img->rotate('degrees' => 90);
                    } elsif ($orientation == 8) {               # 90 (It's on its right size)
                        $img = $img->rotate('degrees' => -90);
                    }
                }
            }
            $bench_rotate = sprintf('%.03f', time - $bench_rotate);

            # Sometimes it works great, sometimes it looks uuuuuugly
            $img->filter('type' => 'autolevels') if ($params->{'autolevels'});

            $bench_scale = time;
            my %scale;
            $w = int($img->getwidth());
            $h = int($img->getheight());
            my $channels = $img->getchannels();
            if ($channels == 1) { # Monochrome
                $img      = $img->convert('preset' => 'rgb');
                $channels = $img->getchannels();
            }
            my $bits = $img->bits();

            # Scale the image, if asked to
            if ($params->{'file'} =~ /\.(gif|png)$/i && ! exists($params->{'width'}) && ! exists($params->{'height'})) {
                ($params->{'width'}, $params->{'height'}) = ($w, $h);
            }
            $params->{'width'}  = min($self->{'XRES'}, int($params->{'width'}  || $w));
            $params->{'height'} = min($self->{'YRES'}, int($params->{'height'} || $h));
            if (defined($xs)) {
                $scale{'xscalefactor'} = $xs;
                $scale{'yscalefactor'} = $ys;
                $scale{'type'}         = $params->{'scale_type'} || 'min';
                $img                   = $img->scale(%scale);
            } else {
                $scale{'xpixels'}  = int($params->{'width'});
                $scale{'ypixels'}  = int($params->{'height'});
                $scale{'type'}     = $params->{'scale_type'} || 'min';
                ($xs, $ys, $w, $h) = $img->scale_calculate(%scale);
                $img               = $img->scale(%scale);
            }
            $w             = int($img->getwidth());
            $h             = int($img->getheight());
            $bench_scale   = sprintf('%.03f', time - $bench_scale);
            my $data       = '';
            $bench_convert = time;

            # Remap colors
            if ($color_order == BGR) {
                $img = $img->convert('matrix' => [[0, 0, 1, 0], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]]);
            } elsif ($color_order == BRG) {
                $img = $img->convert('matrix' => [[0, 0, 1, 0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]);
            } elsif ($color_order == RBG) {
                $img = $img->convert('matrix' => [[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]);
            } elsif ($color_order == GRB) {
                $img = $img->convert('matrix' => [[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]);
            } elsif ($color_order == GBR) {
                $img = $img->convert('matrix' => [[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 0], [0, 0, 0, 1]]);
            }
            if ($self->{'BITS'} == 32) {
                $img = $img->convert('preset' => 'addalpha') if ($channels == 3);
                $img->write(
                    'type'              => 'raw',
                    'interleave'        => FALSE,
                    'raw_datachannels'  => 4,
                    'raw_storechannels' => 4,
                    'datachannels'      => 4,
                    'storechannels'     => 4,
                    'data'              => \$data
                );
                if ($params->{'convertalpha'}) {
                    my $oback = substr($self->{'RAW_BACKGROUND_COLOR'}, 0, 3);
                    my $nback = $self->{'RAW_BACKGROUND_COLOR'};
                    $data =~ s/$oback./$nback/g;
                }
            } elsif ($self->{'BITS'} == 24 ) {
                $img = $img->convert('preset' => 'noalpha') if ($channels == 4);
                $img->write(
                    'type'              => 'raw',
                    'interleave'        => FALSE,
                    'raw_datachannels'  => 3,
                    'raw_storechannels' => 3,
                    'datachannels'      => 3,
                    'storechannels'     => 3,
                    'data'              => \$data
                );
            } else {    # 16 bit
                $channels = $img->getchannels();
                $img      = $img->convert('preset' => 'noalpha') if ($channels == 4);
                # $img = $img->to_rgb16(); # Maybe use this for speed?
                $img->write(
                    'type'              => 'raw',
                    'interleave'        => FALSE,
                    'raw_datachannels'  => 3,
                    'raw_storechannels' => 3,
                    'datachannels'      => 3,
                    'storechannels'     => 3,
                    'data'              => \$data
                );
                $data = $self->_convert_24_to_16($data, RGB);
            }

            if (exists($params->{'center'})) {    # Only accepted values are processed
                if ($params->{'center'} == CENTER_X) {
                    $x = ($w < $self->{'W_CLIP'}) ? int(($self->{'W_CLIP'} - $w) / 2) + $self->{'X_CLIP'} : $self->{'X_CLIP'};
                } elsif ($params->{'center'} == CENTER_Y) {
                    $y = ($h < $self->{'H_CLIP'}) ? int(($self->{'H_CLIP'} - $h) / 2) + $self->{'Y_CLIP'} : $self->{'Y_CLIP'};
                } elsif ($params->{'center'} == CENTER_XY) {
                    $x = ($w < $self->{'W_CLIP'}) ? int(($self->{'W_CLIP'} - $w) / 2) + $self->{'X_CLIP'} : $self->{'X_CLIP'};
                    $y = ($h < $self->{'H_CLIP'}) ? int(($self->{'H_CLIP'} - $h) / 2) + $self->{'Y_CLIP'} : $self->{'Y_CLIP'};
                }
            } elsif (defined($params->{'x'}) && defined($params->{'y'})) {
                $x = int($params->{'x'});
                $y = int($params->{'y'});
            } else {
                if ($w < $self->{'W_CLIP'}) {
                    $x = int(($self->{'W_CLIP'} - $w) / 2) + $self->{'X_CLIP'};
                    $y = 0;
                } elsif ($h < $self->{'H_CLIP'}) {
                    $x = 0;
                    $y = int(($self->{'H_CLIP'} - $h) / 2) + $self->{'Y_CLIP'};
                } else {
                    $x = 0;
                    $y = 0;
                }
            }
            $bench_convert  = sprintf('%.03f', time - $bench_convert);
            $bench_total    = sprintf('%.03f', time - $bench_start);
            $bench_subtotal = sprintf('%.03f', time - $bench_subtotal);
            my $temp_image  = {
                'x'         => $x,
                'y'         => $y,
                'width'     => $w,
                'height'    => $h,
                'image'     => $data,
                'tags'      => \%tags,
                'benchmark' => {
                    'load'      => $bench_load,
                    'rotate'    => $bench_rotate,
                    'scale'     => $bench_scale,
                    'convert'   => $bench_convert,
                    'sub-total' => $bench_subtotal,
                    'total'     => $bench_total
                }
            };
            push(@odata,$temp_image);
            if ($self->{'DIAGNOSTICS'}) {
                my $saved = $self->{'DRAW_MODE'};
                $self->mask_mode() if ($self->{'ACCELERATED'});
                $self->blit_write($odata[-1]);
                print STDERR "LOAD: $bench_load, ROTATE: $bench_rotate, SCALE: $bench_scale, CONVERT: $bench_convert, IMGTIME: $bench_subtotal, TOTAL: $bench_total  \r";
                $self->{'DRAW_MODE'} = $saved;
            }
        }
        if (-e '/tmp/output.gif') { # Deletes the temporary GIF file if it exists
            unlink('/tmp/output.gif');
            $params->{'file'} = $hold;
        }

        if (scalar(@odata) > 1) { # Animation
            return (    # return it in a form the blit routines can dig
                \@odata
            );
        } else { # Single image
            return (    # return it in a form the blit routines can dig
                pop(@odata)
            );
        }
    }
    return (undef); # Ouch
}

sub screen_dump {
=head2 screen_dump

Dumps the screen to a file given in 'file' in the format given in 'format'

Formats can be (they are case-insensitive):

=over 8

=item * B<JPEG>

The most widely used format.  This is a "lossy" format.  The default quality setting is 75%, but it can be overriden with the "quality" parameter.

=item * B<GIF>

The CompuServe "Graphics Interchange Format".  A very old and outdated format made specifically for VGA graphics modes, but still widely used.  It only allows up to 256 "indexed" colors, so quality is very lacking.  The "dither" paramter determines how colors are translated from 24 bit truecolor to 8 bit indexed.

=item * B<PNG>

The Portable Network Graphics format.  Widely used, very high quality.

=item * B<PNM>

The Portable aNy Map format.  These are typically "PPM" files.  Not widely used.

=item * B<TGA>

The Targa image format.  This is a high-color, lossless format, typically used in photography

=item * B<TIFF>

The Tagged Image File Format.  Sort of an older version of PNG (but not the same, just similar in capability).  Sometimes used in FAX formats.

=back

 $fb->screen_dump(
     {
         'file'   => '/path/filename', # name of file to be written
         'format' => 'jpeg',           # jpeg, gif, png, pnm, tga, or tiff

         # for JPEG formats only
         'quality' => 75,              # quality of the JPEG file 1-100% (the
                                       # higher the number, the better the
                                       # quality, but the larger the file)

         # for GIF formats only
         'dither'  => 'floyd',         # Can be "floyd", "jarvis" or "stucki"
     }
 );

=cut

    my $self   = shift;
    my $params = shift;

    my $filename         = $params->{'file'} || 'screendump.jpg';
    my $bytes            = $self->{'BYTES'};
	my $min_bytes        = $self->{'MIN_BYTES'};
    my ($width, $height) = ($self->{'XRES'}, $self->{'YRES'});
    my $scrn             = $self->blit_read({ 'x' => 0, 'y' => 0, 'width' => $width, 'height' => $height });

    $scrn->{'image'} = $self->_convert_16_to_24($scrn->{'image'}, $self->{'COLOR_MODE'}) if ($self->{'BITS'} == 16);

    my $type = lc($params->{'format'} || 'jpeg');
    $type    =~ s/jpg/jpeg/;
    my $img  = Imager::new();
    $img->read(
        'xsize'             => $scrn->{'width'},
        'ysize'             => $scrn->{'height'},
        'raw_datachannels'  => $min_bytes,
        'raw_storechannels' => $min_bytes,
        'raw_interleave'    => FALSE,
        'data'              => $scrn->{'image'},
        'type'              => 'raw',
        'allow_incomplete'  => TRUE
    );
    my %p = (
        'type' => $type || 'raw',
        'datachannels'  => $min_bytes,
        'storechannels' => $min_bytes,
        'interleave'    => FALSE,
        'file'          => $filename
    );

    if ($type eq 'jpeg') {
        $p{'jpegquality'}  = $params->{'quality'} if (exists($params->{'quality'}));
        $p{'jpegoptimize'} = TRUE;
    } elsif ($type eq 'gif') {
        $p{'translate'} = 'errdiff';
        $p{'errdiff'}   = lc($params->{'dither'} || 'floyd');
    }
    $img->write(%p);
}

### Bitmap conversion routines ###

sub _convert_16_to_24 {
    # Convert 16 bit bitmap to 24 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;

    my $size = length($img);
    my $new_img = '';
    if ($self->{'ACCELERATED'}) {
        $new_img = chr(0) x (int(($size / 2) * 3) + 3);
        c_convert_16_24($img, $size, $new_img, $color_order);
    } else {
        my $black24 = chr(0)   x 3;
        my $black16 = chr(0)   x 2;
        my $white24 = chr(255) x 3;
        my $white16 = chr(255) x 2;
        my $idx     = 0;
        while ($idx < $size) {
            my $color = substr($img, $idx, 2);

            # Black and white can be optimized
            if ($color eq $black16) {
                $new_img .= $black24;
            } elsif ($color eq $white16) {
                $new_img .= $white24;
            } else {
                $color = $self->RGB565_to_RGB888({ 'color' => $color, 'color_order' => $color_order });
                $new_img .= $color->{'color'};
            }
            $idx += 2;
        }
    }
    return ($new_img);
}

sub _convert_8_to_32 {
    # Convert 8 bit bitmap to 32 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;
    my $pallette    = shift; # Reference to an array of 256 pallette entries

    my $size = length($img);
    my $new_img = '';
    my $idx = 0;
    while ($idx < $size) {
        my $color = $self->RGB888_to_RGB8888({'color' => $pallette->[unpack('C',substr($img,$idx,1))]});
        $new_img .= $color->{'color'};
        $idx++;
    }
    return($new_img);
}

sub _convert_8_to_24 {
    # Convert 8 bit bitmap to 24 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;
    my $pallette    = shift; # Reference to an array of 256 pallette entries

    my $size = length($img);
    my $new_img = '';
    my $idx = 0;
    while ($idx < $size) {
        my $color = $pallette->[unpack('C',substr($img,$idx,1))];
        $new_img .= $color;
        $idx++;
    }
    return($new_img);
}

sub _convert_8_to_16 {
    # Convert 8 bit bitmap to 16 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;
    my $pallette    = shift; # Reference to an array of 256 pallette entries

    my $size = length($img);
    my $new_img = '';
    my $idx = 0;
    while ($idx < $size) {
        my $color = $self->RGB888_to_RGB565({'color' => $pallette->[unpack('C',substr($img,$idx,1))]});
        $new_img .= $color->{'color'};
        $idx++;
    }
    return($new_img);
}

sub _convert_16_to_32 {
    # Convert 16 bit bitmap to 32 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;

    my $size = length($img);
    my $new_img = '';
    if ($self->{'ACCELERATED'}) {
        $new_img = chr(0) x (int($size * 2) + 4);
        c_convert_16_32($img, $size, $new_img, $color_order);
    } else {
        my $black32 = chr(0)   x 4;
        my $black16 = chr(0)   x 2;
        my $white32 = chr(255) x 4;
        my $white16 = chr(255) x 2;
        my $idx     = 0;
        while ($idx < $size) {
            my $color = substr($img, $idx, 2);

            # Black and white can be optimized
            if ($color eq $black16) {
                $new_img .= $black32;
            } elsif ($color eq $white16) {
                $new_img .= $white32;
            } else {
                $color = $self->RGB565_to_RGBA8888({ 'color' => $color, 'color_order' => $color_order });
                $new_img .= $color->{'color'};
            }
            $idx += 2;
        }
    }
    return ($new_img);
}

sub _convert_24_to_16 {
    # Convert 24 bit bitmap to 16 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;

    my $size    = length($img);
    my $new_img = '';
    if ($self->{'ACCELERATED'}) {
        $new_img = chr(0) x (int(($size / 3) * 2) + 2);
        c_convert_24_16($img, $size, $new_img, $color_order);
    } else {
        my $black24 = chr(0) x 3;
        my $black16 = chr(0) x 2;
        my $white24 = chr(255) x 3;
        my $white16 = chr(255) x 2;

        my $idx = 0;
        while ($idx < $size) {
            my $color = substr($img, $idx, 3);

            # Black and white can be optimized
            if ($color eq $black24) {
                $new_img .= $black16;
            } elsif ($color eq $white24) {
                $new_img .= $white16;
            } else {
                $color = $self->RGB888_to_RGB565({ 'color' => $color, 'color_order' => $color_order });
                $new_img .= $color->{'color'};
            }
            $idx += 3;
        }
    }
    return ($new_img);
}

sub _convert_32_to_16 {
    # Convert 32 bit bitmap to a 16 bit bitmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;

    my $size    = length($img);
    my $new_img = '';
    if ($self->{'ACCELERATED'}) {
        $new_img = chr(0) x (int($size / 2) + 2);
        c_convert_32_16($img, $size, $new_img, $color_order);
    } else {
        my $black32 = chr(0) x 4;
        my $black16 = chr(0) x 2;
        my $white32 = chr(255) x 4;
        my $white16 = chr(255) x 2;

        my $idx = 0;
        while ($idx < $size) {
            my $color = substr($img, $idx, 4);

            # Black and white can be optimized
            if ($color eq $black32) {
                $new_img .= $black16;
            } elsif ($color eq $white32) {
                $new_img .= $white16;
            } else {
                $color = $self->RGBA8888_to_RGB565({ 'color' => $color, 'color_order' => $color_order });
                $new_img .= $color->{'color'};
            }
            $idx += 4;
        }
    }
    return ($new_img);
}

sub _convert_32_to_24 {
    # Convert a 32 bit bitmap to a 24 bit bitmap.
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;

    my $size    = length($img);
    my $new_img = '';
    if ($self->{'ACCELERATED'}) {
        $new_img = chr(0) x (int(($size / 4) * 3) + 3);
        c_convert_32_24($img, $size, $new_img, $color_order);
    } else {
        my $black32 = chr(0) x 4;
        my $black24 = chr(0) x 3;
        my $white32 = chr(255) x 4;
        my $white24 = chr(255) x 3;

        my $idx = 0;
        while ($idx < $size) {
            my $color = substr($img, $idx, 4);

            # Black and white can be optimized
            if ($color eq $black32) {
                $new_img .= $black24;
            } elsif ($color eq $white32) {
                $new_img .= $white24;
            } else {
                $color = $self->RGBA8888_to_RGB888({ 'color' => $color, 'color_order' => $color_order });
                $new_img .= $color->{'color'};
            }
            $idx += 4;
        }
    }
    return ($new_img);
}

sub _convert_24_to_32 {
    # Convert a 24 bit bitmap to a 32 bit bipmap
    my $self        = shift;
    my $img         = shift;
    my $color_order = shift;

    my $size    = length($img);
    my $new_img = '';
    if ($self->{'ACCELERATED'}) {
        $new_img = chr(0) x (int(($size / 3) * 4) + 4);
        c_convert_24_32($img, $size, $new_img, $color_order);
    } else {
        my $black32 = chr(0) x 4;
        my $black24 = chr(0) x 3;
        my $white32 = chr(255) x 4;
        my $white24 = chr(255) x 3;

        my $idx = 0;
        while ($idx < $size) {
            my $color = substr($img, $idx, 4);

            # Black and white can be optimized
            if ($color eq $black24) {
                $new_img .= $black32;
            } elsif ($color eq $white24) {
                $new_img .= $white32;
            } else {
                $color = $self->RGB888_to_RGBA8888({ 'color' => $color, 'color_order' => $color_order });
                $new_img .= $color->{'color'};
            }
            $idx += 3;
        }
    }
    return ($new_img);
}

sub RGB565_to_RGB888 {
=head2 RGB565_to_RGB888

Convert a 16 bit color value to a 24 bit color value.  This requires the color to be a two byte packed string.

 my $color24 = $fb->RGB565_to_RGB888(
     {
         'color' => $color16
     }
 );

=cut

    my $self   = shift;
    my $params = shift;

    my $rgb565 = unpack('S', $params->{'color'});
    my ($r, $g, $b);
    my $color_order = $params->{'color_order'};
    if ($color_order == RGB) {
        $r = $rgb565 & 31;
        $g = ($rgb565 >> 5) & 63;
        $b = ($rgb565 >> 11) & 31;
    } elsif ($color_order == BGR) {
        $b = $rgb565 & 31;
        $g = ($rgb565 >> 5) & 63;
        $r = ($rgb565 >> 11) & 31;
    } elsif ($color_order == BRG) {
        $b = $rgb565 & 31;
        $r = ($rgb565 >> 5) & 63;
        $g = ($rgb565 >> 11) & 31;
    } elsif ($color_order == RBG) {
        $r = $rgb565 & 31;
        $b = ($rgb565 >> 5) & 63;
        $g = ($rgb565 >> 11) & 31;
    } elsif ($color_order == GRB) {
        $g = $rgb565 & 31;
        $r = ($rgb565 >> 5) & 63;
        $b = ($rgb565 >> 11) & 31;
    } elsif ($color_order == GBR) {
        $g = $rgb565 & 31;
        $b = ($rgb565 >> 5) & 63;
        $r = ($rgb565 >> 11) & 31;
    }
    $r = int($r * 527 + 23) >> 6;
    $g = int($g * 259 + 33) >> 6;
    $b = int($b * 527 + 23) >> 6;

    my $color;
    if ($color_order == BGR) {
        ($r, $g, $b) = ($b, $g, $r);
    } elsif ($color_order == BRG) {
        ($r, $g, $b) = ($b, $r, $g);
#    } elsif ($color_order == RGB) { # Redundant, but here for clarity
    } elsif ($color_order == RBG) {
        ($r, $g, $b) = ($r, $b, $g);
    } elsif ($color_order == GRB) {
        ($r, $g, $b) = ($g, $r, $b);
    } elsif ($color_order == GBR) {
        ($r, $g, $b) = ($g, $b, $r);
    }
    $color = pack('CCC', $r, $g, $b);
    return ({ 'color' => $color });
}

sub RGB565_to_RGBA8888 {
=head2 RGB565_to_RGB8888

Convert a 16 bit color value to a 32 bit color value.  This requires the color to be a two byte packed string.  The alpha value is either a value passed in or the default 255.

 my $color32 = $fb->RGB565_to_RGB8888(
     {
         'color' => $color16, # Required
         'alpha' => 128       # Optional
     }
 );

=cut

    my $self   = shift;
    my $params = shift;

    my $rgb565 = unpack('S', $params->{'color'});
    my $a = $params->{'alpha'} || 255;
    my $color_order = $self->{'COLOR_ORDER'};
    my ($r, $g, $b);
    if ($color_order == RGB) {
        $r = $rgb565 & 31;
        $g = ($rgb565 >> 5) & 63;
        $b = ($rgb565 >> 11) & 31;
    } elsif ($color_order == BGR) {
        $b = $rgb565 & 31;
        $g = ($rgb565 >> 5) & 63;
        $r = ($rgb565 >> 11) & 31;
    } elsif ($color_order == BRG) {
        $b = $rgb565 & 31;
        $r = ($rgb565 >> 5) & 63;
        $g = ($rgb565 >> 11) & 31;
    } elsif ($color_order == RBG) {
        $r = $rgb565 & 31;
        $b = ($rgb565 >> 5) & 63;
        $g = ($rgb565 >> 11) & 31;
    } elsif ($color_order == GRB) {
        $g = $rgb565 & 31;
        $r = ($rgb565 >> 5) & 63;
        $b = ($rgb565 >> 11) & 31;
    } elsif ($color_order == GBR) {
        $g = $rgb565 & 31;
        $b = ($rgb565 >> 5) & 63;
        $r = ($rgb565 >> 11) & 31;
    }
    $r = int($r * 527 + 23) >> 6;
    $g = int($g * 259 + 33) >> 6;
    $b = int($b * 527 + 23) >> 6;

    my $color;
    if ($color_order == BGR) {
        ($r, $g, $b) = ($b, $g, $r);
#    } elsif ($color_order == RGB) { # Redundant
    } elsif ($color_order == BRG) {
        ($r, $g, $b) = ($b, $r, $g);
    } elsif ($color_order == RBG) {
        ($r, $g, $b) = ($r, $b, $g);
    } elsif ($color_order == GRB) {
        ($r, $g, $b) = ($g, $r, $b);
    } elsif ($color_order == GBR) {
        ($r, $g, $b) = ($g, $b, $r);
    }
    $color = pack('CCCC', $r, $g, $b, $a);
    return ({ 'color' => $color });
}

sub RGB888_to_RGB565 {
=head2 RGB888_to_RGB565

Convert 24 bit color value to a 16 bit color value.  This requires a three byte packed string.

 my $color16 = $fb->RGB888_to_RGB565(
     {
         'color' => $color24
     }
 );

This simply does a bitshift, nothing more.

=cut

    my $self   = shift;
    my $params = shift;

    my $big_data       = $params->{'color'};
    my $in_color_order = defined($params->{'color_order'}) ? $params->{'color_order'} : $self->{'COLOR_ORDER'};
    my $color_order    = $self->{'COLOR_ORDER'};

    my $n_data;
    if ($big_data ne '') {
        my $pixel_data = substr($big_data, 0, 3);
        my ($r, $g, $b);
        if ($in_color_order == BGR) {
            ($b, $g, $r) = unpack('C3', $pixel_data);
        } elsif ($in_color_order == RGB) {
            ($r, $g, $b) = unpack('C3', $pixel_data);
        } elsif ($in_color_order == BRG) {
            ($b, $r, $g) = unpack('C3', $pixel_data);
        } elsif ($in_color_order == RBG) {
            ($r, $b, $g) = unpack('C3', $pixel_data);
        } elsif ($in_color_order == GRB) {
            ($g, $r, $b) = unpack('C3', $pixel_data);
        } elsif ($in_color_order == GBR) {
            ($g, $b, $r) = unpack('C3', $pixel_data);
        }
        $r = $r >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'});
        $g = $g >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'});
        $b = $b >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'});
        my $color =
          ($r << ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'})) |
          ($g << ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'})) |
          ($b << ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}));
        $n_data = pack('S', $color);
    }
    return ({ 'color' => $n_data });
}

sub RGBA8888_to_RGB565 {
=head2 RGBA8888_to_RGB565

Convert 32 bit color value to a 16 bit color value.  This requires a four byte packed string.

 my $color16 = $fb->RGB8888_to_RGB565(
     {
         'color' => $color32,
     }
 );

This simply does a bitshift, nothing more

=cut

    my $self   = shift;
    my $params = shift;

    my $big_data       = $params->{'color'};
    my $in_color_order = defined($params->{'color_order'}) ? $params->{'color_order'} : $self->{'COLOR_ORDER'};
    my $color_order    = $self->{'COLOR_ORDER'};

    my $n_data;
    while ($big_data ne '') {
        my $pixel_data = substr($big_data, 0, 4);
        $big_data = substr($big_data, 4);
        my ($r, $g, $b, $a);
        if ($in_color_order == BGR) {
            ($b, $g, $r, $a) = unpack('C4', $pixel_data);
        } elsif ($in_color_order == RGB) {
            ($r, $g, $b, $a) = unpack('C4', $pixel_data);
        } elsif ($in_color_order == BRG) {
            ($b, $r, $g, $a) = unpack('C4', $pixel_data);
        } elsif ($in_color_order == RBG) {
            ($r, $b, $g, $a) = unpack('C4', $pixel_data);
        } elsif ($in_color_order == GRB) {
            ($g, $r, $b, $a) = unpack('C4', $pixel_data);
        } elsif ($in_color_order == GBR) {
            ($g, $b, $r, $a) = unpack('C4', $pixel_data);
        }

        # Alpha is tossed
        $r = $r >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'length'});
        $g = $g >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'length'});
        $b = $b >> (8 - $self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'length'});

        my $color =
          ($r << ($self->{'vscreeninfo'}->{'bitfields'}->{'red'}->{'offset'})) |
          ($g << ($self->{'vscreeninfo'}->{'bitfields'}->{'green'}->{'offset'})) |
          ($b << ($self->{'vscreeninfo'}->{'bitfields'}->{'blue'}->{'offset'}));
        $n_data .= pack('S', $color);
    }
    return ({ 'color' => $n_data });
}

sub RGB888_to_RGBA8888 {
=head2 RGB888_to_RGBA8888

Convert 24 bit color value to a 32 bit color value.  This requires a three byte packed string.  The alpha value is either a value passed in or the default 255.

 my $color32 = $fb->RGB888_to_RGBA8888(
     {
         'color' => $color24,
         'alpha' => 64
     }
 );

This just simply adds an alpha value.  No actual color conversion is done.

=cut

    my $self   = shift;
    my $params = shift;

    my $alpha    = (exists($params->{'alpha'})) ? $params->{'alpha'} : 255;
    my $big_data = $params->{'color'};
    my $bsize    = length($big_data);
    my $n_data   = chr($alpha) x (($bsize / 3) * 4);
    my $index    = 0;
    for (my $count = 0; $count < $bsize; $count += 3) {
        substr($n_data, $index, 3) = substr($big_data, $count + 2, 1) . substr($big_data, $count + 1, 1) . substr($big_data, $count, 1);
        $index += 4;
    }
    return ({ 'color' => $n_data });
}

sub RGBA8888_to_RGB888 {
=head2 RGBA8888_to_RGB888

Convert 32 bit color value to a 24 bit color value.  This requires a four byte packed string.

 my $color24 = $fb->RGBA8888_to_RGB888(
     {
         'color' => $color32
     }
 );

This just removes the alpha value.  No color conversion is actually done.

=cut

    my $self   = shift;
    my $params = shift;

    my $big_data = $params->{'color'};
    my $bsize    = length($big_data);
    my $n_data   = chr(255) x (($bsize / 4) * 3);
    my $index    = 0;
    for (my $count = 0; $count < $bsize; $count += 4) {
        substr($n_data, $index, 3) = substr($big_data, $count + 2, 1) . substr($big_data, $count + 1, 1) . substr($big_data, $count, 1);
        $index += 3;
    }
    return ({ 'color' => $n_data });
}

sub vsync {
=head2 vsync

Waits for vertical sync

Waits for the vertical blank before returning

* Not all framebuffer drivers have this capability and ignore this call.  Results may vary, as this cannot be emulated.  The only way to know is to just test it.

=cut

    my $self = shift;
    _set_ioctl(FBIO_WAITFORVSYNC, 'I', $self->{'FB'}, 0);
}

sub which_console {
=head2 which_console

Returns the active console and the expected console

 my ($active_console, $expected_console) = $fb->which_console();

=cut

    my $self = shift;
    chomp($self->{'THIS_CONSOLE'} = _slurp('/sys/class/tty/tty0/active'));
    $self->{'THIS_CONSOLE'} =~ s/\D+//gs;
    $self->{'THIS_CONSOLE'} += 0; # Force numeric
    return ($self->{'THIS_CONSOLE'}, $self->{'CONSOLE'});
}

sub active_console {
=head2 active_console

Indicates if the current console is the expected console.  It returns true or false.

 if ($self->active_console()) {
      # Do something
 }

=cut

    my $self = shift;
    my ($current, $original) = $self->which_console();
    if ($current == $original) {
        return (TRUE);
    }
    return (FALSE);
}

sub wait_for_console {
=head2 wait_for_console

Blocks actions until the expected console is active.  The expected console is determined at the time the module is initialized.

Due to speed considerations, YOU must do use this to do blocking, if desired.  If you expect to be changing active consoles, then you will need to use this.  However, if you do not plan to do ever change consoles when running this module, then don't use this feature, as your results will be faster.

If a TRUE or FALSE is passed to this, then you can enable or disable blocking for subsequent calls.

=cut

    my $self = shift;
    if (scalar(@_)) {
        $self->{'WAIT_FOR_CONSOLE'} = (shift =~ /^(true|on|1|enable)$/i) ? TRUE : FALSE;
    } else {
        while ($self->{'WAIT_FOR_CONSOLE'} && !$self->active_console()) {
            sleep .1;
        }
    }
}

## These are pulled in via the Mouse module

=head2 initialize_mouse

Turns on/off the mouse handler.

Note:  This uses Perl's "alarm" feature.  If you want to use threads, then don't use this to turn on the mouse.

# $fb->initialize_mouse(1);  # Turn on the mouse handler

or

# $fb->initialize_mouse(0);  # Turn off the mouse handler

=head2 poll_mouse

The mouse handler.  The "initialize_mouse" routine sets this as the "alarm" routine to handle mouse events.

An alarm handler just works, but can possibly block if used as ... an alarm handler.

I suggest running it in a thread instead, using your own code.

=head2 get_mouse

Returns the mouse coordinates.

Return as an array:

 my ($mouseb, $mousex, $mousey) =  $fb->get_mouse();

Return as a hash reference:

 my $mouse = $fb->get_mouse();

Returns

  {
      'button' => button value, # Button state according to bits
                                #  Bit 0 = Left
                                #  Bit 1 = Right
                                # Other bits according to driver
      'x'      => Mouse X coordinate,
      'y'      => Mouse Y coordinate,
  }

=head2 set_mouse

Sets the mouse position

 $fb->set_mouse(
            {
                'x' => 0,
                'y' => 0,
            }
 );

* NOTE:  Mouse support is very primitive and will not be further developed, as the framebuffer is not exactly mouse-friendly.

=cut

##############################################################################
####################### NON-METHODS, FLAT SUBROUTINES ########################
##############################################################################
sub _transformed_bounds {
    my $bbox   = shift;
    my $matrix = shift;

    my $bounds;
    foreach my $point ([$bbox->start_offset, $bbox->ascent], [$bbox->start_offset, $bbox->descent], [$bbox->end_offset, $bbox->ascent], [$bbox->end_offset, $bbox->descent]) {
        $bounds = _add_bound($bounds, _transform_point(@{$point}, $matrix));
    }
    return (@{$bounds});
}

sub _add_bound {
    my $bounds = shift;
    my $x      = shift;
    my $y      = shift;

    $bounds or return ([$x, $y, $x, $y]);

    $x < $bounds->[0] and $bounds->[0] = $x;
    $y < $bounds->[1] and $bounds->[1] = $y;
    $x > $bounds->[2] and $bounds->[2] = $x;
    $y > $bounds->[3] and $bounds->[3] = $y;

    return ($bounds);
}

sub _transform_point {
    my $x      = shift;
    my $y      = shift;
    my $matrix = shift;

    return ($x * $matrix->[0] + $y * $matrix->[1] + $matrix->[2], $x * $matrix->[3] + $y * $matrix->[4] + $matrix->[5]);
}

sub _get_ioctl {
    ##########################################################
    ##                    GET IOCTL INFO                    ##
    ##########################################################
    # 'sys/ioctl.ph' is flakey.  Not used at the moment.     #
    ##########################################################
    # Used to return an array specific to the ioctl function #
    ##########################################################

    # This really needs to be moved over to the C routines, as the structure really is hard to parse for different processor long types
    # ... aaaaand ... I did
    my $command = shift;
    my $format  = shift;
    my $fb      = shift;
    my $data    = '';
    my @array;
    eval {
        if (defined($fb)) {
            ioctl($fb, $command, $data);
        } else {
            ioctl(STDOUT, $command, $data);
        }
    };
    @array = unpack($format, $data);
    return (@array);
}

sub _set_ioctl {
    ##########################################################
    ##                    SET IOCTL INFO                    ##
    ##########################################################
    # Used to call or set ioctl specific functions           #
    ##########################################################
    my $command = shift;
    my $format  = shift;
    my $fb      = shift;
    my @array   = @_;

    my $data = pack($format, @array);
    eval { return (ioctl($fb, $command, $data)); };
}

sub _slurp { # Just used for /proc
    my $file = shift;
    my $buffer = '';
    eval {
        open(my $sl,'<',$file);
        read($sl,$buffer,10);
        close($sl);
        $buffer = chomp($buffer);
    };
    return($buffer);
}

1;

__END__

=head1 USAGE HINTS

=head2 GRADIENTS

Gradients can have any number (actually 2 or greater) of color key points (transitions).  Vertical gradients cannot have more key points than the object is high.  Horizontal gradients cannot have more key points that the object is wide.  Just keep your gradients "sane" and things will go just fine.

Make sure the number of color key points matches for each primary color (red, green, and blue);

=head2 PERL OPTIMIZATION

This module is highly CPU dependent.  So the more optimized your Perl installation is, the faster it will run.

=head2 THREADS

The module (using the 'threads' module) canNOT have separate threads calling the same object.  You WILL crash. However, you can instantiate an object for each thread to use on the same framebuffer, and it will work just fine.

See the "examples/multiprocessing" directory for "threads_primitives.pl" as an example of a threading script that uses this module.

=head2 FORKS

For unthreaded Perl, Install the modules B<forks> and B<forks::shared> and you will have the same features as B<threads> and B<threads::shared> (and perhaps better performance for unthreaded perls).

=head2 MCE

Mario Roy has tested B<Graphics::Framebuffer> with various methods to use the B<MCE> modules for multiprocessing, and creating a single shared library.  See the "README" file for more.  I highly recommend this for multiprocessing, as it should save on memory.

=head2 BLITTING

Use "blit_read" and "blit_write" to save portions of the screen instead of redrawing everything.  It will speed up response tremendously.

=head2 SPRITES

Someone asked me about sprites.  Well, that's what blitting is for.  You'll have to do your own collision detection.  Use B<MASK_MODE> and B<UNMASK_MODE> for drawing, and B<XOR_MODE> for removing.

Most framebuffer drivers do not have access to GPU features.  It's just a memory map of the framebuffer.

Listen folks, this library does everything in software, so your results will vary depending on CPU speed and screen resolution, as well as blit resolution.

=head2 HORIZONTAL "MAGIC"

Horizontal lines and filled boxes draw very fast, even in Perl mode, seriously.  Learn to exploit them.

=head2 PIXEL SIZE

Pixel sizes over 1 utilize a filled "box" or "circle" (negative numbers for circle) to do the drawing.  This is why the larger the "pixel", the slower the draw.

=head2 MULTIPLE "HEADS" (monitors)

As long as each framebuffer for each display is accessible, you can open an instance of the module for each framebuffer and access each screen.

=head2 MAKING WINDOWS

So, you want to be able to manage some sort of windows...

You just instantiate a new instance of the module per "Window" and give it its own clipping region.  This region is your drawing space for your window.

It is up to you to actually decorate (draw) the windows.

Nothing is preventing you from writing your own window handler, although I recommend just using X-Windows (and a different module) for that anyway.

=head2 RUNNING IN MICROSOFT WINDOWS

It doesn't work natively, (other than in emulation mode) and likely never will.  However...

You can run Linux inside VirtualBox and it works fine.  Put it in full screen mode, and voila, it's "running in Windows" in an indirect kinda-sorta way.  Make sure you install the VirtualBox extensions, as it has the correct video driver for framebuffer access.  It's as close as you'll ever get to get it running in MS Windows.  Seriously...

This isn't a design choice, nor preference, nor some anti-Windows ego trip.  It's simply because of the fact MS Windows does not allow file mapping of the display, nor variable memory mapping of the display (that I know of), both are the techniques this module uses to achieve its magic.  DirectX is more like OpenGL in how it works, and thus defeats the purpose of this module.  You're better off with SDL instead, if you want to draw in MS Windows from Perl.

* However, if someone knows how to access the framebuffer (or simulate one) in MS Windows, and be able to do it reasonably from within Perl, then send me instructions on how to do it, and I'll do my best to get it to work.

=head1 TROUBLESHOOTING

Ok, you've installed the module, but can't seem to get it to work properly.  Here  are some things you can try:

** make sure you turn on the B<SHOW_ERRORS> parameter when calling B<new> to create the object.  This helps with troubleshooting (but turn it back off for normal use).

=over 4

=item B< You Have To Run From The Console >

A console window doesn't count as "the console".  You cannot use this module from within X-Windows.  It won't work, and likely will only go into emulation mode if you do, or maybe crash, or even corrupt your X-Windows screen.

If you want to run your program within X-Windows, then you have the wrong module.  Use SDL, QT, or GTK or something similar.

You MUST have a framebuffer based video driver for this to work.  The device ("/dev/fb0" for example) must exist.

If it does exist, but is not "/dev/fb0", then you can define it in the B<new> method with the B<FB_DEVICE> parameter, although the module is pretty good at finding it automatically.

* It may be possible to get a framebuffer device with a proprietary driver by forcing Grub to go into a VESA VGA mode for the console (worked for me with NVidia).

=item B< It's Crashing >

Ok, segfaults suck.  Believe me, I had plenty in the early days of writing this module.  There is hope for you.

This is almost always caused by the module incorrectly calculating the framebuffer memory size, and it's guessing too large or small a memory footprint, and the system doesn't like it.

Try running the "primitives.pl" in the "examples" directory in the following way (assuming your screen is larger than 640x480):

   perl examples/primitives.pl --x=640 --y=480

This forces the module to pretend it is rendering for a smaller resolution (by placing this screen in the middle of the actual one).  If it works fine, then try changing the "x" value back to your screen's actual width, but still make the "y" value slightly smaller.  Keep decreasing this "y" value until it works.

If you get this behavior, then it is a bug, and the author needs to be notified, although as of version 6.06 this should no longer be an issue.

=item B< It Only Partially Renders >

Yeah this can look weird.  This is likely because there's some buffering going on.  The module attempts to turn it off, but if, for some reason, it is buffering anyway, try adding the following to points in your code where displaying a full render is necessary:

 $fb->_flush_screen();

This should force a full screen flush, but only use this if you really need it.

Why?  You see, the framebuffer is actually a file.  Therefore, file operations must be used to access it.  File operations are buffered.  Therefore buffers need to be flushed instead of cached for the framebuffer device.  This module actually maps this file to a variable and even more weirdness results.  Normally turning off buffering in Perl is easy, but on rare occasions it can be stubborn.  Therefore, this command was made to force it to flush, if it isn't already.

=item B< It Just Plain Isn't Working >

Well, either your system doesn't have a framebuffer driver, or perhaps the module is getting confusing data back from it and can't properly initialize (see the previous items).

First, make sure your system has a framebuffer by seeing if F</dev/fb0> (actually "fb" then any number) exists.  If you don't see any "fb0" - "fb31" files inside "/dev" (or "/dev/fb/"), then you don't have a framebuffer driver running.  You need to fix that first.  Sometimes you have to manually load the driver with "modprobe -a drivername" (replacing "drivername" with the actual driver name).

Second, you did the above, but still nothing.  You need to check permissions.  The account you are running this under needs to have permission to use the screen.  This typically means being a member of the "B<video>" group.  Let's say the account is called "username", and you want to give it permission.  In a Linux (Debian/Ubuntu/Mint/RedHat/Fedora) environment you would use this to add "username" (your account name) to the "video" group:

   sudo usermod -a -G video username

Once that is run (changing "username" to whatever your username is), log out, then log back in, and it should work.

=item B< The Text Cursor Is Messing Things Up >

It is?  Well then turn it off.  Use the $fb->cls('OFF') method to do it.  Use $fb->cls('ON') to turn it back on.

If your script exits without turning the cursor back on, then it will still be off.  To get your cursor back, just type the command "reset" (and make sure you turn it back on before your code exits, so it doesn't do that).

* UPDATE:  The new default behavior is to do this for you via the B<RESET> parameter when creating the object.  See the B<new> method documentation above for more information.

=item B< TrueType Printing isn't working >

This is likely caused by the Imager library either being unable to locate the font file, or when it was compiled, it couldn't find the FreeType development libraries, and was thus compiled without TrueType text support.

See the INSTALLATION instructions (above) on getting Imager properly compiled.  If you have a package based Perl installation, then installing the Imager (usually "libimager-perl") package will always work.  If you already installed Imager via CPAN, then you should uninstall it via CPAN, then go install the package version, in that order.  You may also install "libfreetype6-dev" and then re-install Imager via CPAN with a forced install.  If you don't want the package version but still want the CPAN version, then still uninstall what is there, then go an make sure the TrueType and FreeType development libraries are installed on your system, along with PNG, JPEG, and GIF development libraries.  Now you can go to CPAN and install Imager.

=item B< It's Too Slow >

Ok, it does say a PERL graphics library in the description, if I am not mistaken.  This means Perl is doing most of the work.  This also means it is only as fast as your system and its CPU, as it does not use your GPU at all.

First, check to make sure the C acceleration routines are compiling properly.  Call the "acceleration" method without parameters.  It SHOULD return 1 and not 0 if C is properly compiling.  If it's not, then you need to make sure "Inline::C" is properly installed in your Perl environment.  I<THIS WILL BE THE BIGGEST HELP TO YOU, IF YOU GET THIS SOLVED FIRST>.

Second, (and this is very advanced) you could try recompiling Perl with optimizations specific to your hardware.  That can help, but this is very advanced and you should know what you are doing before attempting this.  Keep in mind that if you do this, then ALL of the modules installed via your distribution packager won't work, and will have to be reinstalled via CPAN for the new perl.  Try using B<perlbrew> to do this simply for you.

You can also try simplifying your drawing to exploit the speed of horizontal lines.  Horizonal line drawing is incredibly fast, even for very slow systems.

Only use pixel sizes of 1.  Anything larger requires a box to be drawn at the pixel size you asked for.  Pixel sizes of 1 only use plot to draw, (so no boxes) so it is much faster.

Try using 'polygon' to draw complex shapes instead of a series of plot or line commands.

Does your device have more than one core?  Well, how about using threads (or MCE)?  Just make sure you do it according to the examples in the "examples" directory.  Yes, I know this can be too advanced for the average coder, but the option is there.

Plain and simple, your device just may be too slow for some CPU intensive operations, specifically anything involving animated images and heaviy blitting.  If you must use images, then make sure they are already the right size for your needs.  Don't force the module to resize them when loading, as this takes CPU time (and memory).

=item B< Ask For Help >

If none of these ideas work, then send me an email, and I may be able to get it functioning for you.  Please run the F<dump.pl> script inside the "examples" directory inside this module's package:

   perl dump.pl

Please include the dump file it creates (dump.log) B<as a file attachment> to your email.  Please do I<not> include it inline as part of the message text.

Also, please include a copy of your code (or at least the portion of it where you initialize this module and are having issues), AND explain to me your hardware and OS it is running under.

Screen shots and photos are also helpful.

KNOW THIS:  I want to get it working on your system, and I will do everything I can to help you get it working, but there may be some conditions where that may not be possible.  It's very rare (and I haven't seen it yet), but possible.

I am not one of those arrogant ogres that spout "RTFM" every time someone asks for help (although it helps if you do read the manual).  I actually will help you.  Please be patient, as I do have other responsibilities that may delay a response, but a response will come.

** Making the subject of your email "B<PERL GFB HELP>" is most helpful for me, and likely will get your email seen sooner.

=back

=head1 AUTHOR

## EMAIL ##

=head1 COPYRIGHT

Copyright © 2003-## YEAR ## Richard Kelsch, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the GNU software license.

=head1 LICENSE

GNU Public License Version 3

A copy of this license is included in the 'LICENSE' file in this distribution.

=head1 VERSION

Version ## VERSION ## (## VERSION DATE ##)

=head1 THANKS

My thanks go out to those using this module and submitting helpful patches and suggestions for improvement, as well as those who asked for help.  Your requests for help actually gave me ideas.

Thank you Mario Roy for showing how to use MCE to multiprocess instead of threads.  Very handy.  Look for the "get_mce_demos" in the "examples" directory.  NOTE: I do not support MCE bug issues.

=head1 TELL ME ABOUT YOUR PROJECT

I'd love to know if you are using this library in your project.  So send me an email, with pictures and/or a URL (if you have one) showing what it is.  If you have a YouTube video, then that would be cool to see too.

If project has a specific need that the module does not support (or support easy), then suggest a feature to me.

=head1 YOUTUBE

There is a YouTube channel with demonstrations of the module's capabilities.  Eventually it will have examples of output from a variety of different types of hardware.

L<YouTube Graphics::Framebuffer Channel|https://www.youtube.com/@richardkelsch3640>

=head1 GITHUB

=over 4

L<GitHub Graphics::Framebuffer|https://github.com/richcsst/Graphics-Framebuffer>

Clone

 git clone https://github.com/richcsst/Graphics-Framebuffer.git

=back

=cut
