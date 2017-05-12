#
# this is an example of various ways to include inline image data in your
# gtk2-perl programs.
#    -- muppet, 29 nov 03
#

use Gtk2 -init;

#
# This is the text of a regular XPM file, reformatted to be valid Perl syntax.
# Note in particular the use of single quotes instead of double quotes; this
# makes sure that Perl doesn't treat the embedded $ and @ characters as
# special.
#
my @question_xpm = (
'32 32 17 1',
' 	c None',
'.	c #030303',
'+	c #1A1A1A',
'@	c #4A4A4A',
'#	c #616161',
'$	c #939393',
'%	c #AAAAAA',
'&	c #D2D2D2',
'*	c #DCDCDC',
'=	c #E2E2E2',
'-	c #E6E6E6',
';	c #EDEDED',
'>	c #343434',
',	c #AEAEAE',
'x	c #7B7B7B',
')	c #C5C5C5',
'!	c #F3F3F3',
'                                ',
'                                ',
'                                ',
'            )&&&&)),            ',
'          )=*=--=-=;*&          ',
'         )*-;;!;;!;;;**         ',
'        )=;!)x@>+>#)!;!*        ',
'       &*!;#.>x%%x..>&!!&       ',
'       =;!@.$!!;;!=+.+;;=&      ',
'      );!%..;!;--;!$..x!;&      ',
'      *;;#..&!-&*;!&..>!;&      ',
'      &=;#..x!=&*;!&..>!;&      ',
'      )*;*@>&;&)=;!$..@!;&      ',
'       &*;;;;=&=;!!+..,!;*      ',
'        &--***=;!*@..#!;=       ',
'         )&)&=;!$..+x!;=&       ',
'           %&;!#.@%;!!=&        ',
'           &&;$.x!!;;-*         ',
'           &-!#.!!;=&)          ',
'           )-!@@;;*)            ',
'           )*;x$;-)             ',
'           &;!!!;;*             ',
'          &*!&@@);=&            ',
'          *=;@..@;=)            ',
'          *-;@..>!;*            ',
'          )-;)>>&-*&            ',
'           )=!!;;=)             ',
'            &=-;=)              ',
'             )**)               ',
'                                ',
'                                ',
'                                ');

$pixbuf_from_xpm_data = Gtk2::Gdk::Pixbuf->new_from_xpm_data (@question_xpm);


#
# here we create a Pixbuf from raw rgba image data created on the fly.
# beware that this isn't the most efficient thing to do; if you have
# heavy bit-banging to do, you may be more interested in writing some
# xs code to get direct access to the pixel data in C.
#

my ($width, $height) = (64, 64);
my $data = pack "C*", map { ($_, $_/2, 64, $_) } map { ($_) x $width } (0..($height-1));

$pixbuf_from_raw_data = Gtk2::Gdk::Pixbuf->new_from_data
		($data,      # the data.  this will be copied.
		'rgb',       # only currently supported colorspace
		1,           # true, because we do have alpha channel data
		8,           # gdk-pixbuf currently allows only 8-bit samples
		$width,      # width in pixels
		$height,     # height in pixels
		$width * 4); # rowstride -- we have RGBA data, so it's four
		             # bytes per pixel.


#
# Gtk+ ships with a utility program called gdk-pixbuf-csource, which turns
# any image understood by gdk-pixbuf into a C data structure that can be
# parsed by gdk_pixbuf_new_from_inline().  here's an example of that output:
#
#----
#/* GdkPixbuf RGBA C-Source image dump */
#
#static const guint8 my_pixbuf[] = 
#{ ""
#  /* Pixbuf magic (0x47646b50) */
#  "GdkP"
#  /* length: header (24) + pixel_data (64) */
#  "\0\0\0X"
#  /* pixdata_type (0x1010002) */
#  "\1\1\0\2"
#  /* rowstride (16) */
#  "\0\0\0\20"
#  /* width (4) */
#  "\0\0\0\4"
#  /* height (4) */
#  "\0\0\0\4"
#  /* pixel_data: */
#  "\377\0\0\377\377\0\0\377\0\0\0\0\0\0\377\377\377\0\0\377\0\0\0\0\0\0"
#  "\377\377\0\0\377\377\0\0\0\0\0\0\377\377\0\0\377\377\377\0\0\377\0\0"
#  "\377\377\0\0\377\377\377\0\0\377\377\0\0\377"};
#----
#
# obviously, this C syntax is not valid Perl.  you can mangle that into Perl
# code and create the proper binary string using pack, as shown below, but
# in my experience, it's more trouble than it's worth.  Since the data is in
# a Perl scalar which will be garbage-collected, the image data must always
# be copied, so you lose the ability to use static image data.  Also, the
# direct output from that tool is not useful. [FIXME perhaps we should make
# a tool dedicated to gtk2-perl?]
#

my $my_pixbuf = pack "a4a4a4a4a4a4a64",
  "GdkP",      # Pixbuf magic (0x47646b50)
  "\0\0\0X",   # length: header (24) + pixel_data (64)
  "\1\1\0\2",  # pixdata_type (0x1010002)
  "\0\0\0\20", # rowstride (16)
  "\0\0\0\4",  # width (4)
  "\0\0\0\4",  # height (4)
  # pixel_data:
  "\377\0\0\377\377\0\0\377\0\0\0\0\0\0\377\377\377\0\0\377\0\0\0\0\0\0"
 ."\377\377\0\0\377\377\0\0\0\0\0\0\377\377\0\0\377\377\377\0\0\377\0\0"
 ."\377\377\0\0\377\377\377\0\0\377\377\0\0\377";

$pixbuf_from_inline = Gtk2::Gdk::Pixbuf->new_from_inline ($my_pixbuf);



$dlg = Gtk2::Dialog->new;
$hbox = Gtk2::HBox->new (1, 6);
$dlg->vbox->add ($hbox);
$frame = Gtk2::Frame->new ('xpm data');
$frame->add (Gtk2::Image->new_from_pixbuf ($pixbuf_from_xpm_data));
$hbox->add ($frame);
$frame = Gtk2::Frame->new ('raw data');
$frame->add (Gtk2::Image->new_from_pixbuf ($pixbuf_from_raw_data));
$hbox->add ($frame);
$frame = Gtk2::Frame->new ('inline data');
$frame->add (Gtk2::Image->new_from_pixbuf ($pixbuf_from_inline));
$hbox->add ($frame);
$dlg->add_button ('gtk-close' => 'close');
$dlg->show_all;
$dlg->run;
