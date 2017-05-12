package Linux::Svgalib;

use strict;
use warnings;

use Carp;

require Exporter;
require DynaLoader;

use base 'Exporter';
use base 'DynaLoader';


our %EXPORT_TAGS = ( 'all' => [ qw(
	ACCELFLAG_DRAWHLINELIST
	ACCELFLAG_DRAWLINE
	ACCELFLAG_FILLBOX
	ACCELFLAG_POLYFILLMODE
	ACCELFLAG_POLYHLINE
	ACCELFLAG_POLYLINE
	ACCELFLAG_PUTBITMAP
	ACCELFLAG_PUTIMAGE
	ACCELFLAG_SCREENCOPY
	ACCELFLAG_SCREENCOPYBITMAP
	ACCELFLAG_SCREENCOPYMONO
	ACCELFLAG_SETBGCOLOR
	ACCELFLAG_SETFGCOLOR
	ACCELFLAG_SETMODE
	ACCELFLAG_SETOFFSET
	ACCELFLAG_SETRASTEROP
	ACCELFLAG_SETTRANSPARENCY
	ACCELFLAG_SYNC
	ACCEL_DRAWHLINELIST
	ACCEL_DRAWLINE
	ACCEL_END
	ACCEL_FILLBOX
	ACCEL_POLYFILLMODE
	ACCEL_POLYHLINE
	ACCEL_POLYLINE
	ACCEL_PUTBITMAP
	ACCEL_PUTIMAGE
	ACCEL_SCREENCOPY
	ACCEL_SCREENCOPYBITMAP
	ACCEL_SCREENCOPYMONO
	ACCEL_SETBGCOLOR
	ACCEL_SETFGCOLOR
	ACCEL_SETMODE
	ACCEL_SETOFFSET
	ACCEL_SETRASTEROP
	ACCEL_SETTRANSPARENCY
	ACCEL_START
	ACCEL_SYNC
	ALI
	APM
	ARK
	ATI
	BANSHEE
	BLITS_IN_BACKGROUND
	BLITS_SYNC
	CAPABLE_LINEAR
	CHIPS
	CIRRUS
	DISABLE_BITMAP_TRANSPARENCY
	DISABLE_TRANSPARENCY_COLOR
	EGA
	ENABLE_BITMAP_TRANSPARENCY
	ENABLE_TRANSPARENCY_COLOR
	ET3000
	ET4000
	ET6000
	EXT_INFO_AVAILABLE
	G1024x768x16
	G1024x768x16M
	G1024x768x16M32
	G1024x768x256
	G1024x768x32K
	G1024x768x64K
	G1072x600x16M
	G1072x600x16M32
	G1072x600x256
	G1072x600x32K
	G1072x600x64K
	G1152x864x16
	G1152x864x16M
	G1152x864x16M32
	G1152x864x256
	G1152x864x32K
	G1152x864x64K
	G1280x1024x16
	G1280x1024x16M
	G1280x1024x16M32
	G1280x1024x256
	G1280x1024x32K
	G1280x1024x64K
	G1280x720x16M
	G1280x720x16M32
	G1280x720x256
	G1280x720x32K
	G1280x720x64K
	G1360x768x16M
	G1360x768x16M32
	G1360x768x256
	G1360x768x32K
	G1360x768x64K
	G1600x1200x16
	G1600x1200x16M
	G1600x1200x16M32
	G1600x1200x256
	G1600x1200x32K
	G1600x1200x64K
	G1800x1012x16M
	G1800x1012x16M32
	G1800x1012x256
	G1800x1012x32K
	G1800x1012x64K
	G1920x1080x16M
	G1920x1080x16M32
	G1920x1080x256
	G1920x1080x32K
	G1920x1080x64K
	G1920x1440x16M
	G1920x1440x16M32
	G1920x1440x256
	G1920x1440x32K
	G1920x1440x64K
	G2048x1152x16M
	G2048x1152x16M32
	G2048x1152x256
	G2048x1152x32K
	G2048x1152x64K
	G2048x1536x16M
	G2048x1536x16M32
	G2048x1536x256
	G2048x1536x32K
	G2048x1536x64K
	G320x200x16
	G320x200x16M
	G320x200x16M32
	G320x200x256
	G320x200x32K
	G320x200x64K
	G320x240x16M
	G320x240x16M32
	G320x240x256
	G320x240x256V
	G320x240x32K
	G320x240x64K
	G320x400x16M
	G320x400x16M32
	G320x400x256
	G320x400x256V
	G320x400x32K
	G320x400x64K
	G320x480x16M
	G320x480x16M32
	G320x480x256
	G320x480x32K
	G320x480x64K
	G360x480x256
	G400x300x16M
	G400x300x16M32
	G400x300x256
	G400x300x32K
	G400x300x64K
	G400x600x16M
	G400x600x16M32
	G400x600x256
	G400x600x32K
	G400x600x64K
	G512x384x16M
	G512x384x16M32
	G512x384x256
	G512x384x32K
	G512x384x64K
	G512x480x16M
	G512x480x16M32
	G512x480x256
	G512x480x32K
	G512x480x64K
	G640x200x16
	G640x350x16
	G640x400x16M
	G640x400x16M32
	G640x400x256
	G640x400x32K
	G640x400x64K
	G640x480x16
	G640x480x16M
	G640x480x16M32
	G640x480x2
	G640x480x256
	G640x480x32K
	G640x480x64K
	G720x348x2
	G720x540x16M
	G720x540x16M32
	G720x540x256
	G720x540x32K
	G720x540x64K
	G800x600x16
	G800x600x16M
	G800x600x16M32
	G800x600x256
	G800x600x32K
	G800x600x64K
	G848x480x16M
	G848x480x16M32
	G848x480x256
	G848x480x32K
	G848x480x64K
	G960x720x16M
	G960x720x16M32
	G960x720x256
	G960x720x32K
	G960x720x64K
	GVGA6400
	HAVE_BITBLIT
	HAVE_BLITWAIT
	HAVE_EXT_SET
	HAVE_FILLBLIT
	HAVE_HLINELISTBLIT
	HAVE_IMAGEBLIT
	HAVE_RWPAGE
	IS_DYNAMICMODE
	IS_INTERLACED
	IS_LINEAR
	IS_MODEX
	MACH32
	MACH64
	MON1024_43I
	MON1024_60
	MON1024_70
	MON1024_72
	MON640_60
	MON800_56
	MON800_60
	MX
	NV3
	OAK
	PARADISE
	RAGE
	RGB_MISORDERED
	ROP_AND
	ROP_COPY
	ROP_INVERT
	ROP_OR
	ROP_XOR
	S3
	TEXT
	TVGA8900
	UNDEFINED
	VESA
	VGA
	VGA_AVAIL_ACCEL
	VGA_AVAIL_FLAGS
	VGA_AVAIL_ROP
	VGA_AVAIL_ROPMODES
	VGA_AVAIL_SET
	VGA_AVAIL_TRANSMODES
	VGA_AVAIL_TRANSPARENCY
	VGA_CLUT8
	VGA_COMEFROMBACK
	VGA_EXT_AVAILABLE
	VGA_EXT_CLEAR
	VGA_EXT_FONT_SIZE
	VGA_EXT_PAGE_OFFSET
	VGA_EXT_RESET
	VGA_EXT_SET
	VGA_GOTOBACK
	VGA_KEYEVENT
	VGA_MOUSEEVENT
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	ACCELFLAG_DRAWHLINELIST
	ACCELFLAG_DRAWLINE
	ACCELFLAG_FILLBOX
	ACCELFLAG_POLYFILLMODE
	ACCELFLAG_POLYHLINE
	ACCELFLAG_POLYLINE
	ACCELFLAG_PUTBITMAP
	ACCELFLAG_PUTIMAGE
	ACCELFLAG_SCREENCOPY
	ACCELFLAG_SCREENCOPYBITMAP
	ACCELFLAG_SCREENCOPYMONO
	ACCELFLAG_SETBGCOLOR
	ACCELFLAG_SETFGCOLOR
	ACCELFLAG_SETMODE
	ACCELFLAG_SETOFFSET
	ACCELFLAG_SETRASTEROP
	ACCELFLAG_SETTRANSPARENCY
	ACCELFLAG_SYNC
	ACCEL_DRAWHLINELIST
	ACCEL_DRAWLINE
	ACCEL_END
	ACCEL_FILLBOX
	ACCEL_POLYFILLMODE
	ACCEL_POLYHLINE
	ACCEL_POLYLINE
	ACCEL_PUTBITMAP
	ACCEL_PUTIMAGE
	ACCEL_SCREENCOPY
	ACCEL_SCREENCOPYBITMAP
	ACCEL_SCREENCOPYMONO
	ACCEL_SETBGCOLOR
	ACCEL_SETFGCOLOR
	ACCEL_SETMODE
	ACCEL_SETOFFSET
	ACCEL_SETRASTEROP
	ACCEL_SETTRANSPARENCY
	ACCEL_START
	ACCEL_SYNC
	ALI
	APM
	ARK
	ATI
	BANSHEE
	BLITS_IN_BACKGROUND
	BLITS_SYNC
	CAPABLE_LINEAR
	CHIPS
	CIRRUS
	DISABLE_BITMAP_TRANSPARENCY
	DISABLE_TRANSPARENCY_COLOR
	EGA
	ENABLE_BITMAP_TRANSPARENCY
	ENABLE_TRANSPARENCY_COLOR
	ET3000
	ET4000
	ET6000
	EXT_INFO_AVAILABLE
	G1024x768x16
	G1024x768x16M
	G1024x768x16M32
	G1024x768x256
	G1024x768x32K
	G1024x768x64K
	G1072x600x16M
	G1072x600x16M32
	G1072x600x256
	G1072x600x32K
	G1072x600x64K
	G1152x864x16
	G1152x864x16M
	G1152x864x16M32
	G1152x864x256
	G1152x864x32K
	G1152x864x64K
	G1280x1024x16
	G1280x1024x16M
	G1280x1024x16M32
	G1280x1024x256
	G1280x1024x32K
	G1280x1024x64K
	G1280x720x16M
	G1280x720x16M32
	G1280x720x256
	G1280x720x32K
	G1280x720x64K
	G1360x768x16M
	G1360x768x16M32
	G1360x768x256
	G1360x768x32K
	G1360x768x64K
	G1600x1200x16
	G1600x1200x16M
	G1600x1200x16M32
	G1600x1200x256
	G1600x1200x32K
	G1600x1200x64K
	G1800x1012x16M
	G1800x1012x16M32
	G1800x1012x256
	G1800x1012x32K
	G1800x1012x64K
	G1920x1080x16M
	G1920x1080x16M32
	G1920x1080x256
	G1920x1080x32K
	G1920x1080x64K
	G1920x1440x16M
	G1920x1440x16M32
	G1920x1440x256
	G1920x1440x32K
	G1920x1440x64K
	G2048x1152x16M
	G2048x1152x16M32
	G2048x1152x256
	G2048x1152x32K
	G2048x1152x64K
	G2048x1536x16M
	G2048x1536x16M32
	G2048x1536x256
	G2048x1536x32K
	G2048x1536x64K
	G320x200x16
	G320x200x16M
	G320x200x16M32
	G320x200x256
	G320x200x32K
	G320x200x64K
	G320x240x16M
	G320x240x16M32
	G320x240x256
	G320x240x256V
	G320x240x32K
	G320x240x64K
	G320x400x16M
	G320x400x16M32
	G320x400x256
	G320x400x256V
	G320x400x32K
	G320x400x64K
	G320x480x16M
	G320x480x16M32
	G320x480x256
	G320x480x32K
	G320x480x64K
	G360x480x256
	G400x300x16M
	G400x300x16M32
	G400x300x256
	G400x300x32K
	G400x300x64K
	G400x600x16M
	G400x600x16M32
	G400x600x256
	G400x600x32K
	G400x600x64K
	G512x384x16M
	G512x384x16M32
	G512x384x256
	G512x384x32K
	G512x384x64K
	G512x480x16M
	G512x480x16M32
	G512x480x256
	G512x480x32K
	G512x480x64K
	G640x200x16
	G640x350x16
	G640x400x16M
	G640x400x16M32
	G640x400x256
	G640x400x32K
	G640x400x64K
	G640x480x16
	G640x480x16M
	G640x480x16M32
	G640x480x2
	G640x480x256
	G640x480x32K
	G640x480x64K
	G720x348x2
	G720x540x16M
	G720x540x16M32
	G720x540x256
	G720x540x32K
	G720x540x64K
	G800x600x16
	G800x600x16M
	G800x600x16M32
	G800x600x256
	G800x600x32K
	G800x600x64K
	G848x480x16M
	G848x480x16M32
	G848x480x256
	G848x480x32K
	G848x480x64K
	G960x720x16M
	G960x720x16M32
	G960x720x256
	G960x720x32K
	G960x720x64K
	GLASTMODE
	GVGA6400
	HAVE_BITBLIT
	HAVE_BLITWAIT
	HAVE_EXT_SET
	HAVE_FILLBLIT
	HAVE_HLINELISTBLIT
	HAVE_IMAGEBLIT
	HAVE_RWPAGE
	IS_DYNAMICMODE
	IS_INTERLACED
	IS_LINEAR
	IS_MODEX
	MACH32
	MACH64
	MON1024_43I
	MON1024_60
	MON1024_70
	MON1024_72
	MON640_60
	MON800_56
	MON800_60
	MX
	NV3
	OAK
	PARADISE
	RAGE
	RGB_MISORDERED
	ROP_AND
	ROP_COPY
	ROP_INVERT
	ROP_OR
	ROP_XOR
	S3
	TEXT
	TVGA8900
	UNDEFINED
	VESA
	VGA
	VGA_AVAIL_ACCEL
	VGA_AVAIL_FLAGS
	VGA_AVAIL_ROP
	VGA_AVAIL_ROPMODES
	VGA_AVAIL_SET
	VGA_AVAIL_TRANSMODES
	VGA_AVAIL_TRANSPARENCY
	VGA_CLUT8
	VGA_COMEFROMBACK
	VGA_EXT_AVAILABLE
	VGA_EXT_CLEAR
	VGA_EXT_FONT_SIZE
	VGA_EXT_PAGE_OFFSET
	VGA_EXT_RESET
	VGA_EXT_SET
	VGA_GOTOBACK
	VGA_KEYEVENT
	VGA_MOUSEEVENT
	__GLASTMODE
);

our $VERSION = '1.3';

sub new
{
   my ( $proto, $args ) = @_;

   my $class = ref($proto) || $proto;

   my $self = {};

   bless $self, $class;

   return $self;
}

our $AUTOLOAD;

sub AUTOLOAD 
{

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) 
    {
       croak "Your vendor has not defined Linux::Svgalib macro $constname";
    }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

1;

bootstrap Linux::Svgalib $VERSION;

package Linux::Svgalib::Modeinfo;

use strict;
use warnings;

use Carp;

our $AUTOLOAD;

sub AUTOLOAD
{
  my ( $self ) = @_;

  (my $methname = $AUTOLOAD) =~ s/.*:://;

  no strict 'refs';

  if ( exists $self->{$methname} )
  {
    *{$AUTOLOAD} = sub 
                   {
                      my ( $self ) = @_;
                      return $self->{$methname};
                   };
  }
  else
  {
      croak "method $methname not defined";
  } 

  &{$AUTOLOAD};
}

1;
__END__

=head1 NAME

Linux::Svgalib - Object Oriented Perl interface to the svgalib graphics library

=head1 SYNOPSIS

  use Linux::Svgalib;

  my $svga = Linux::Svgalib->new();

  $svga->init();

  $svga->setmode(G640x480x16);

  ...

  $svga->setmode(TEXT);

=head1 DESCRIPTION

This module provides an Interface to a subset of the functions provided
by the svgalib graphics library.  Those methods that are supported are
largely the graphics drawing primitives and rudimentary keyboard I/O.
Specifically the graphics accelerator and blit functions are not exposed
because they are rather difficult to implement a Perl interface for.

The normal course of a program using this module is create the object and
then to call the init() method straight away, after that setmode() can be
used to change to the appropriate graphics mode and the graphics methods
can be used to draw to the screen.  A program will almost always call
setmode(TEXT) before execution completes in order to restore the
virtual console to the state it was in before the mode was changed.

A program that fails at runtime may leave the virtual console in an
unusable state - the program can make arrangements to call setmode(TEXT)
in a $SIG{__DIE__} handler or END block or the textmode utility described
in the svgalib documentation can be used.

In nearly all circumstances programs using Linux::Svgalib will need to be
run with superuser privileges in  order to initialise svgalib - this can
be done by making the program setuid where that is supported or by using
a program such as 'sudo'.  It is strongly recommened that you switch
Taint checking on with the '-T' switch to perl when running as root, you
should read the perlsec manpage to learn more about this.

=head2 METHODS

=over 4

=item new

The constructor of the class.  Returns an object suitable for calling
the remaining methods on.

=item init 

Initializes the svgalib library - this is always required before
any graphics operations are performed.

=item addmode $width, $height, $num_colors, $offset, $bytesperpixel 

Adds a mode to the list of modes, with the
given parameters. The function returns the mode number. If such a mode
already exists on the list, its number is returned, and no mode is added.

Adding a mode to the list is not enough in order to use it. There must
also be a timing line that fits that mode. This can be added either as a
modeline in the config file, or with the functions addtiming

=item addtiming $pixelClock, $HDisplay, $HSyncStart, $HSyncEnd,
                $HTotal, $VDisplay, $VSyncStart, $VSyncEnd, $VTotal, $flags

Adds the given line of mode timing to the table of user timings, as if
the line is in the config file. For a description of the parameter's
meaning, see libvga.config(5)

=item changetiming $pixelClock, $HDisplay, $HSyncStart, $HSyncEnd, $HTotal, 
                   $VDisplay, $VSyncStart, $VSyncEnd, $VTotal, $flags)

Changes the value of the current timing
parameters by the given values. No checks are made to see if the new
timing are within monitor or card specs. See svidtune(6) for an exam­
ple of using this.  See also getcurrenttiming(3)

=item clear 

Clears the screen and sets all visible pixels to 0 (which is usually
black). This is automatically done by the setmode method.

=item disabledriverreport 

Usually svgalib prints the name of the hardware detected or forced to
the screen during startup. This and other informational messages are
suppressed when this method is called.


=item drawline $x1, $y1, $x2, $y2

Draws a line from the point ($x1, $y1) to the point ($x2, $y2) on the
screen. If you exchange start and end of the line you should not expect
the exactly identical set of pixel be covered by the line.

The colour of the pixels drawn is determined by that which was last set by
setcolor or setrgbcolor.

=item drawpixel $x, $y

Sets a pixel at the point ( $x, $y) to the colour as determined by the
last call to setcolor() or setrgbcolor().  For drawing a large number
of pixels at one time you might want to consider drawscanline() or
drawscansegment().


=item drawscanline $line , $colours

Draws a horizontal line over the whole screen in the line with y coordinate $line.  $colours is a reference to an array containing a colour value for each
pixel in the line.  The pixel width of the screen should by determined before
populating the array (using for instance getxdim() ) as the behaviour of
undefined pixels in the array is undefined. If only a partial scan line is
to be drawn that drawscansegment  should be used.

=item drawscansegment $colours, $x,  $y;

Draws a horizontal line of pixelsof the length of the array that $colours 
is a reference to starting at position ($x, $y). $colours is a reference
to an array of integers indicating the colours of the pixels in the line
drawn.

=item getch 

Waits for a key press just like getchar(3) would.  For a non blocking check
for a keypress use getkey(3).

=item getcolors

Returns the number of colours available.

=item getydim

Returns the vertical size in pixels of the screen.

=item getxdim

Returns the horizontal size in pixels of the screen.

=item getcurrentchipset 
Returns a number representing the current SVGA
chipset which was autodetected or forced. See setchipset(3).

=item getcurrentmode 

Returns the current video mode.

=item getcurrenttiming 

Returns a list that describes the current timing parameters:

         ($pixelClock,
          $HSyncStart, 
          $HSyncEnd, 
          $HTotal, 
          $VDisplay, 
          $VSyncStart, 
          $VSyncEnd, 
          $VTotal,
          $flags)

This list is suiutable to pass to changetiming() or addtiming() as parameters.

=item getdefaultmode 

Returns the default graphics mode number from the SVGALIB_DEFAULT_MODE
environment variable or an untrue value if undefined. The environment
variable can either contain a mode number or a symbolic mode name.

=item getkey 

Reads a character from the keyboard without waiting; returns false if
no key pressed and the ASCII value otherwise.

=item getmodeinfo 

Returns an object of the type Linux::Svgalib::Modeinfo which has the
following methods that provide information about the current mode: 

=over 2

=item width

The width of the screen in pixels

=item height

The height of the screen in pixels

=item bytesperpixel

The number of bytes required to store pixel information.

=item colors

The number of colours available for simulataneous display in this mode.

=item linewidth

Logical scanline width in bytes.  This might not be very useful.

=back

If the given mode is out of range, undef is
returned. When getmodeinfo() returns details about a
certain mode, you must check if it is currently available with hasmode (3).

=item getmodename $mode

Will return a string representing the mode.
Depending on mode it consist of a capital G followed
by the amount of x pixels, followed by a lower case x, followed by the
amount of y pixels, followed by a lower case x. Finally the number
of different colors is appended. Here the shortcuts 32K,64K,16M,
and 16M4 are used for 32768, 65536, and 16777216 are used.  If the
mode does not exist then the empty string will be returned.

=item getmodenumber $name

The reverse of the above method - parses $name
and tries to find a videomode corresponding on it. $name is parsed
case insensitive and should be either an integer string just giving
a mode number or consist of a capital G followed by the amount of
x pixels, followed by a lower case x, fol­ lowed by the amount of y
pixels, followed by a lower case x. Finally the number of different
colors is appended. Here the shortcuts 32K,64K,16M, and 16M4 are
used for 32768, 65536, and 16777216 are used. The last refers also
to 16777216 which are store in 4 bytes (highest address byte unused)
for easier screen access.  For unsupported values or the string
"PROMPT" the value ­1 is returned. Also a irritating error message is
printed to stdout. This is used during parsing the SVGALIB_DEFAULT_MODE
environment variable. Probably it should not be used for anything else.


=item getmonitortype 

This returns the monitor type configered in /etc/vga/libvga.config. 
The return value is one of the constants:


=over 2

=item MON640_60 MON800_56 MON1024_43I

31.5 KHz (standard VGA): does 640x480 in 60Hz vsync.  35.1 KHz (old
SVGA): does 800x600 in 56Hz vsync.  35.5 KHz (low­end SVGA, 8514):
does 1024x768 in 43Hz vsync interlaced.

=item MON800_60 MON1024_60

37.9 KHz (SVGA): does 800x600 in 60Hz vsync.  48.3 KHz (SVGA
non­interlaced): does 1024x768 in 60Hz vsync, non­interlaced.

=item MON1024_70 MON1024_72

56.0 KHz (SVGA high frequency): does 1024x768 in 70Hz vsync. does 1024x768
in 72Hz vsync or even better.

=over

=item getpalette $index

Gets the colour from the palette with the index $index and returns a
three element list relating to the red, green and blue components
of that colour.  The return values from this method are probably only
sensible if the graphics modes supports 16 or 256 colours.

=item getpixel $x, $y 

Returns the colour palette index of the pixel at the point ( $x, $y ).

=item getscansegment $x, $y, $length

returns a list describing the scan segment starting at the point ($x, $y)
and of length $length -  each element of the list represents a single
pixel in the selected scan line.

=item hasmode $mode

Returns a true value if support for graphics mode $mode is available.

=item lastmodenumber 

Returns the last video mode number available.

=item lockvc 

Disables virtual console switching.

=item oktowrite 

Indicates whether the program is in the console currently visible on 
the screen.  The method is deprecated in the svgalib documentation as
a means of determining whether it is safe to write to the VGA memory
but as you cant do that here it is fine.


=item screenoff

Some SVGA chip sets will allow the turning off video signal generation
and this may improve SVGA operation performance.  This is almost
certainly going to be unsightly and confusing to the user however.

=item screenon 

Turn the generation of video signal back on after the use of the above
method.

=item setcolor  $colour

Set the current colour for drawing operations ( drawpixel(), drawline()) to 
$colour. You should only use setcolor() in 256 or less colour modes. 
For the other modes you must use setrgbcolor() instead. 

=item setmode $mode

This method selects the video mode $mode and clears
the screen (if it was a graphics mode). 

$mode should be greater than 1 and less than or equal to lastmodenumber().

A true value will be returned on success, false otherwise.

=item setpalette $index, $red, $green, $blue

Sets the pallette referred to by $index to the colour described by
$red, $green, $blue.  This operation is only meaningful in modes
with 256 or less colours.


=item unlockvc 

Unlocks virtual console switching after a previous call to lockvc.

=item white

Returns the palette index of 'white' in the current graphics mode.
The actual colour in the palette may not appear to be white if it
has been altered with setpalette().

=back

=head2 EXPORT

.

=head2 Exported constants

  ALI
  APM
  ARK
  ATI
  BANSHEE
  CHIPS
  CIRRUS
  EGA
  ET3000
  ET4000
  ET6000

Graphics modes :

  G1024x768x16
  G1024x768x16M
  G1024x768x16M32
  G1024x768x256
  G1024x768x32K
  G1024x768x64K
  G1072x600x16M
  G1072x600x16M32
  G1072x600x256
  G1072x600x32K
  G1072x600x64K
  G1152x864x16
  G1152x864x16M
  G1152x864x16M32
  G1152x864x256
  G1152x864x32K
  G1152x864x64K
  G1280x1024x16
  G1280x1024x16M
  G1280x1024x16M32
  G1280x1024x256
  G1280x1024x32K
  G1280x1024x64K
  G1280x720x16M
  G1280x720x16M32
  G1280x720x256
  G1280x720x32K
  G1280x720x64K
  G1360x768x16M
  G1360x768x16M32
  G1360x768x256
  G1360x768x32K
  G1360x768x64K
  G1600x1200x16
  G1600x1200x16M
  G1600x1200x16M32
  G1600x1200x256
  G1600x1200x32K
  G1600x1200x64K
  G1800x1012x16M
  G1800x1012x16M32
  G1800x1012x256
  G1800x1012x32K
  G1800x1012x64K
  G1920x1080x16M
  G1920x1080x16M32
  G1920x1080x256
  G1920x1080x32K
  G1920x1080x64K
  G1920x1440x16M
  G1920x1440x16M32
  G1920x1440x256
  G1920x1440x32K
  G1920x1440x64K
  G2048x1152x16M
  G2048x1152x16M32
  G2048x1152x256
  G2048x1152x32K
  G2048x1152x64K
  G2048x1536x16M
  G2048x1536x16M32
  G2048x1536x256
  G2048x1536x32K
  G2048x1536x64K
  G320x200x16
  G320x200x16M
  G320x200x16M32
  G320x200x256
  G320x200x32K
  G320x200x64K
  G320x240x16M
  G320x240x16M32
  G320x240x256
  G320x240x256V
  G320x240x32K
  G320x240x64K
  G320x400x16M
  G320x400x16M32
  G320x400x256
  G320x400x256V
  G320x400x32K
  G320x400x64K
  G320x480x16M
  G320x480x16M32
  G320x480x256
  G320x480x32K
  G320x480x64K
  G360x480x256
  G400x300x16M
  G400x300x16M32
  G400x300x256
  G400x300x32K
  G400x300x64K
  G400x600x16M
  G400x600x16M32
  G400x600x256
  G400x600x32K
  G400x600x64K
  G512x384x16M
  G512x384x16M32
  G512x384x256
  G512x384x32K
  G512x384x64K
  G512x480x16M
  G512x480x16M32
  G512x480x256
  G512x480x32K
  G512x480x64K
  G640x200x16
  G640x350x16
  G640x400x16M
  G640x400x16M32
  G640x400x256
  G640x400x32K
  G640x400x64K
  G640x480x16
  G640x480x16M
  G640x480x16M32
  G640x480x2
  G640x480x256
  G640x480x32K
  G640x480x64K
  G720x348x2
  G720x540x16M
  G720x540x16M32
  G720x540x256
  G720x540x32K
  G720x540x64K
  G800x600x16
  G800x600x16M
  G800x600x16M32
  G800x600x256
  G800x600x32K
  G800x600x64K
  G848x480x16M
  G848x480x16M32
  G848x480x256
  G848x480x32K
  G848x480x64K
  G960x720x16M
  G960x720x16M32
  G960x720x256
  G960x720x32K
  G960x720x64K
  TEXT

  MACH32
  MACH64
  MON1024_43I
  MON1024_60
  MON1024_70
  MON1024_72
  MON640_60
  MON800_56
  MON800_60
  MX
  NV3
  OAK
  PARADISE
  RAGE
  RGB_MISORDERED
  ROP_AND
  ROP_COPY
  ROP_INVERT
  ROP_OR
  ROP_XOR
  S3
  TVGA8900
  UNDEFINED
  VESA
  VGA

=head1 AUTHOR

Jonathan Stowe , E<lt>jns@gellyfish.co.ukE<gt>

=head1 SEE ALSO

L<perl>. L<svgalib>

=cut
