#!/usr/bin/perl
package Graphics::ColorPicker;

use strict;
#use diagnostics;

use lib qw(./blib/lib);
use vars qw($VERSION $msie_frame $colwidth $leftwidth $force_msie $obfuscate $server_only $use_mdown $image);
use AutoLoader 'AUTOLOAD';

$VERSION = do { my @r = (q$Revision: 0.17 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

################################################
# set some things, should not need to be changed
################################################

# NOTE: set var c24flip in sub picker for the initial dark or light palette

  $server_only	= 0;	# overides $obfuscate, $force_msie, $use_mdown, $p_gen::jsl
# normally set to one for external client based xy resolution
  $obfuscate	= 1;	# overides force_msie, and frames(parameter)
			# forces jslib to be loaded by copyright page
#### THIS SHOULD ALWAYS BE SET TO ONE !!!
# the new xy resolution methods work for all clients
  $use_mdown	= 1;	# use new onMouseDown routines, overides client side $force_msie
  $force_msie	= 0;	# normally 0 set 1 to use msie stuff in netscape for debug

  $colwidth	= 85;	# width of columns, right side is 2X this
  $leftwidth	= 450;	# color picker width

  $image	= 1;	# starting picker image, 0=dark, 1=light

################################################

  my $greyimg	= 'grey.jpg';
  my $darkimg	= 'darkb409.jpg';
  my $liteimg	= 'liteb409.jpg';
  my $size	= 409;
  my $button	= 38;

################################################

  $_ = $colwidth << 1;
  $msie_frame = '<html><body bgcolor=white><table border=0 width=' . $_ . '><tr><td align=center><font color=blue><font size=5>ColorPicker</font><font size=-4><br>&copy; 2002-'. ((localtime())[5] + 1900). ' Michael Robinton<br><font color=red>loading, please wait</font></font></font></td></tr></table></body>';

  if ($server_only) {
    $obfuscate	= 0;
    $force_msie	= 1;
    $use_mdown	= 0;
  }
  $force_msie = 0 if ($use_mdown);

# helper
# return useable (force_msie, use_mdown)
#
sub _force_mdown {
# only needed for Gecko
  unless ($server_only) {
    return (0,1) if $ENV{HTTP_USER_AGENT} =~ /GECKO/i;
  }
  return ($force_msie,$use_mdown);
}

=head1 NAME

  Graphics::ColorPicker : A perl module for WYSIWYG web 
  applications that allow selection of HEX color numbers

=head1 SYNOPSIS

  use Graphics::ColorPicker;
    or
  require  Graphics::ColorPicker;

  make_page($path_to_images);
  send_page(\$html_txt,$type);
  $time_string = http_date($time);
  $name = script_name;
  $butabref = buttontext([optional array ref])
  $html_text=frames($websafe);
  $html_text = msie_frame;
  $html_text=picker($darkimg,$liteimg,$size,$bsize,greyimg);
  $html_text=no_picker;
  $html_text=cp216_ds($clrdot,$border,$square)
  $javascript_text = jslib;
  $html=make_buttons(\%look_n_feel,$url,$active,\@buttons,$xtra);
  $html_text=pluck($color);
  $html_text=hex_update($hex_color);

=head1 SAMPLE WEBSITE - 24 million color picker

=head2 L<http://www.bizsystems.net/downloads/graphics/demo2.html>

=head2 L<http://www.bizsystems.net/downloads/graphics/demo.html>

=head1 DESCRIPTION

This module generates a set of palettes to select a HEX or DECIMAL color
number via a web browser. B<make_page()> can be called by C<javascript> from
your web page and will set the HEX value in a variable in the calling page
and scope. The selector page can be created for 24 million or web safe
colors only.

  <script language=javascript1.1>
  var colorhex = '';
  var w;
  function pop() {
    if (document.forms.color.what.checked){w=180;}else{w=630;}
    var colorwin = open("","colorpicker",
    "width=" + w + ",height=440,status=no,directories=no," +
    "location=no,menubar=no,scrollbars=no,toolbar=no");
    if (colorwin.opener == null) newin.opener = self;  
    colorwin.document.close();
    colorwin.focus();
    return true;
  }
  </script>
  <body>
  <form name="color" onSubmit="return(pop());"
   action="p_gen.cgi" target="colorpicker">   
  <input type=text name=hex size=10><br>
  <input type=checkbox name=what value=wo> web safe colors only<br>
  <input type=submit value="Pop Picker Window">
  </form>

  See B<examples/demo.html> and B<scripts/p_gen.cgi>
  Read INSTALL

NOTE: as of version 0.13 ColorPicker can be used in a captive frame to
dynamically update color values in the DOM.

  See B<examples/demo2.html>, 
      B<examples/colorbar.html> and
      B<scripts/p_gen2.cgi>

=over 4

=item make_page($path_to_images);

  Generate Color Picker Pages

  This is the only routine that really needs to be called
  externally. You could roll your own from the following
  calls for a special purpose, but it's really not necessary.

  i.e. Graphics::ColorPicker::make_page('./');

  will generate the picker pages as required

=cut

sub make_page {
  my ($dir) = @_;
  my ($x,$y,$html,$scale,$type);

  if (	$ENV{QUERY_STRING} =~ /what=picker/) {		# color picker page
	$html = &picker($dir.$darkimg,$dir.$liteimg,$size,$button,$dir.$greyimg);
  }
  elsif ($ENV{QUERY_STRING} =~ /what=no_picker/) {	# blank minimum color picker page
	$html = &no_picker;
  }
  elsif ($ENV{QUERY_STRING} =~ /what=digits/) {		# digits page
	 $html = &cp216_ds($dir.'cleardot.gif');
  }
# accomodate dumb browsers that don't understand all of javascript1.1
# or use server base XY resolution
  elsif ($ENV{QUERY_STRING} =~ /what=(msie)/) {
	 $html = &msie_frame;
  }

# need for MSIE workaround, mostly browser side update
# preferred method
  elsif ($ENV{QUERY_STRING} =~ /what=(color)/ ||
	 $ENV{QUERY_STRING} =~ /what=(grey)/) {
	 $html = &pluck($1,$size,$button);
  }

  elsif ($ENV{QUERY_STRING} =~ /what=init/) {
	 $_ = ($ENV{QUERY_STRING} =~ /hex=[\#]*([0-9a-fA-F]{6})/) ? $1 : '000000';
	 $html = &hex_update($_);
  }
  elsif ($ENV{QUERY_STRING} =~ /what=jslib/) {
	 $html = &jslib;
	 $type = 'application/x-javascript';
  }
  elsif ($ENV{QUERY_STRING} =~ /what=wo/) {	# frames for web safe colors only
	 $html = &frames(1);
  }
  else {	# call frames for browser based xy resolution, 24 megacolors
	 $html = &frames(0);
  }
  &send_page(\$html,$type);
}
=item send_page(\$html_txt,$type);

  Sends a page of html text to browser.
  Uses Apache mod_perl if available

  input:   \$html text,
	   $type,	# text/html, text/plain, etc...

=cut

#################################################
# send a page to the browser, use mod_perl if available
#
# input:	pointer to text, content-type [optional]
# sends:	text to server
#
#		default content type = text/html
#		if not specified
#
sub send_page {
  my ($hp,$type) = @_;
  $type = 'text/html' unless $type;
  my $size = length($$hp);
  my $now = time;
  my $r;
  eval { require Apache;
    $r = Apache->request;
  };
  unless ($@) {		# unless error, it's Apache
    $r->status(200);
    $r->content_type($type);
    $r->header_out("Content-length","$size");
    $r->header_out("Last-modified",http_date($now));
    $r->header_out("Expires",http_date($now));
    $r->send_http_header;
    $r->print ($$hp);
    return 200;		# HTTP_OK

  } else {		# sigh... no mod_perl

    print q
|Content-type: |, $type, q|
Content-length: |, $size, q|
Last-modified: |, http_date($now), q|
Connection: close
Expires: |, http_date($now), qq|

|, $$hp
  }
} 

=item $time_string = http_date($time);

  Returns time string in HTTP date format, same as...

  Apache::Util::ht_time(time, "%a, %d %b %Y %T %Z",1));

  i.e. Sat, 13 Apr 2002 17:36:42 GMT

=cut

sub http_date {
  my($time) = @_;
  my($sec,$min,$hr,$mday,$mon,$yr,$wday) = gmtime($time);
  return
    (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday] . ', ' .                   # "%a, "
    sprintf("%02d ",$mday) .                                            # "%d "
    (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon] . ' ' . # "%b "
    ($yr + 1900) . ' ' .						# "%Y "
    sprintf("%02d:%02d:%02d ",$hr,$min,$sec) .                          # "%T "
    'GMT';                                                              # "%Z"
}

=item $name = script_name;

  Returns the subroutine name of the calling 
  script external to this library

=cut

###############################################
#	MUST NOT BE AUTOLOADED
###############################################
# return the name of the script that called this library
#
# input:	none
# returns:	script name
#
sub script_name {
  for (my $i=1;$i<4;$i++) {	# find script name, fail after a few tries
    @_ = split('/',(caller($i))[1]);
    my $rv = pop @_;
    return $rv unless __FILE__ =~ /$rv$/;
  }
}

=item $but_table_ref = buttontext([optional ref]);

  Always return and optionally set the contents of cp216_ds button text.

    input:	optional reference to button table array
    returns:	reference to button table array

  Default contents:

  my $butable = [
    'Submit'   => 'javascript:void(0);" OnMouseDown="doSubmit();return false;',
    '','',
    'Restore'  => 'javascript:void(0);" OnClick="doRestore();return false;',
    '','',
    'Close'    => 'javascript:void (0);" OnClick="parent.close();return false;',
  ];

=cut

# use on click as workaround for buggy Opera browser.
my $_butab = [
#	'Submit'	=> 'javascript:void doSubmit();',
	'Submit'	=> 'javascript:void(0);" OnMouseDown="doSubmit();return false;',
	'','',
#	'Restore'	=> 'javascript:void doRestore();',
	'Restore'	=> 'javascript:void(0);" OnClick="doRestore();return false;',
	'','',
	'Close'		=> 'javascript:void (0);" OnClick="parent.close();return false;',
];

sub buttontext {
  if (@_) {
    $_butab = $_[0];	# set new button table values
  }
  $_butab;		# always return the reference
}

# define autoload subroutines

sub frames;
sub msie_frame;
sub picker;
sub no_picker;
sub cp216_ds;
sub jslib;
sub j2s;
sub make_buttons;
sub pluck;
sub env_dumb_browser;
sub hex_update;
sub DESTROY {};

1;
__END__

=item $html_text=frames($websafe);

  Returns the frame text for top window.

  input:  true = 24 million colors
	  false = web safe colors only

  return:  html text for page

=cut

################################################
# return new frames page
#
# input:	false = 24 million colors, true = web safe
# returns:	top window html frames text
#
sub frames {
  my ($websafe) = @_;
  my $jsl = ($server_only) ? '' : '&jsl=1';
  my $hex = ($ENV{QUERY_STRING} =~ /hex=[\#]*([0-9a-fA-F]{6})/)
	? "?what=init&hex=$1" : '?what=init';

  my $head = q|<html>
<head>
<title>Color Picker - www.bizsystems.com</title>
<script language=javascript>
var uno = '';
var doce = '';
var blim;
var mv;
var px;
var py;
var pict;
var sf;
var out = 1;
function isOK() {
  if ((eval(out) < 1.2) | . '||' . q| (navigator.userAgent.indexOf('Opera') != -1)) {
    alert('Sorry, unsupported or flakey browser');
  }
}
</script>
<script language=javascript1.2>
  out = 1.2 // have javascript 1.2 or better|;

  $head .= q|
colorpluck = function(){pluckXY();if(px>blim&&py>blim){return(window._digits.flipc24m());}px-=mv;py=mv-py;scale();var g=Math.abs(px/2);var r=py+g;if(r<0)r=0;py=-py;var b=py-g;if(b<0)b=0;if(px<0){g=b-px;}else{g=b;b=g+px;}out = window._digits;out.rgb[0] = parseInt(r);out.rgb[1] = parseInt(g);out.rgb[2] = parseInt(b);if(window._picker.c24flip!=0){out.rgb[0] = 255 - out.rgb[0];out.rgb[1] = 255 - out.rgb[1];out.rgb[2] = 255 - out.rgb[2];}out.setrgb();out.sethex();}
greypluck = function(){pluckXY();py=255-py;out = window._digits;out.rgb[0] = py;out.rgb[1] = py;out.rgb[2] = py;out.setrgb();out.sethex();}
pluckXY = function(){var xy=window._data.document.location.search;var qloc=xy.lastIndexOf('?')+1;var cloc=xy.lastIndexOf(',');px=xy.substring(qloc,cloc);py=xy.substring(cloc+1,xy.length);}  
scale = function(){px*=sf;py*=sf;}|
	if $obfuscate;

$head .= q|
  if(typeof parent.registerpicker == 'function') parent.registerpicker(self);
</script>
|;

  my ($fmie,$umd) = &_force_mdown;
  my $gen_name = script_name;
  $_ = ( $obfuscate || $fmie || &env_dumb_browser )
	? $gen_name . '?what=msie'
	: 'javascript:\"' . $msie_frame . '\"';

  $head .= q|
<script language=javascript1.2 src=|. &script_name . q|?what=jslib></script>|
	if $jsl && ! $obfuscate;

  my $what = 'picker';
  if ( $websafe ) {
    $what = 'no_picker';
    $leftwidth = 0;
  }
  my $sc = 'no';	# scrolling -- normally no, yes for debug
  return $head . q|
</head>
<script language=javascript>
if (out == 1.2) {
  document.writeln('<frameset cols="| . $leftwidth . q|,*" border=0 onLoad="isOK();window._digits.init();">\n' +
                   '  <frame name=_picker scrolling=| . $sc . q| marginheight=0 marginwidth=0 src=|. $gen_name . q|?what=|. $what . $jsl . q|>' +
                   '  <frameset rows="0,85,*" border=0>' +
                   "  <frame name=_data scrolling=| . $sc . q| marginheight=0 marginwidth=0 src='|. $gen_name . $hex . q|'>" +
                   "  <frame name=_sample scrolling=| . $sc . q| marginheight=0 marginwidth=0 src='|. $_ . q|'>" +
                   '  <frame name=_digits scrolling=| . $sc . q| marginheight=0 marginwidth=0 src=|. $gen_name . q|?what=digits|. $jsl . q|>' +
                   '  </frameset>' +
                   '</frameset>');
} else {
  document.writeln('<body bgcolor="#ffffcc"><center><font size=6 color=red>THIS APPLICATION REQUIRES A<BR>JAVASCRIPT 1.2 COMPLIANT BROWSER</FONT></center></body>');
}
</script>
<noscript>
<body bgcolor="#ffffff"><center><font size=6 color=red>YOU MUST ACTIVATE JAVASCRIPT 1.2<BR>OR BETTER TO USE THIS APPLICATION</FONT></center></body>
</noscript>
</html>
|;
}

=item $html_text = msie_frame;

  Return the text for the copyright notice
  (sample frame) for browsers that can't do
  "javascript:xxx()" from within a frame 
  like brain dead MSIE browsers.

=cut

################################################
# return MSIE frame contents
# only used by brain dead MSIE that does not 
# recognize javascript1.2 stuff in frames, sigh....
#
# input:	none
# returns:	html text for sample frame
#
sub msie_frame {
  return $msie_frame
	unless $obfuscate;

  my $jsl = &jslib;
  &j2s(\$jsl);
  my $n = '';
  foreach (0..200) {
    $n .="\n";		# bunch of endlines
  }
  return q|<!-- Copyright 2002, Michael Robinton, michael@bizsystems.com -->
| . $msie_frame . $n .q|
<script language=javascript1.2>
  var strg = '|. $jsl . q|';
  var fs = new Array('%t','\n','%p','\r','%r','@','%c','\"','%s','$','%v','\'','%a','\\\','%j','%');
  for(var i=0;i<fs.length;i+=2) {
    var beg = 0;
    var cur = 0;
    var end = strg.length;
    var ofst = fs[i].length;
    var a = '';
    replace:
    while ( cur < end ) {
      beg = cur;
      cur = strg.indexOf(fs[i],beg);
      if ( cur < 0) {
        a += strg.substring(beg,end);
        break;
      } else {
        a += strg.substring(beg,cur) + fs[i+1];
        cur += ofst;
      }
    }
    strg = a;
  }
  with(parent) {
    out = strg + "\nout = " + out + ";\n";
  }
</script></html>|;
}

=item $html_text=picker($darkimg,$liteimg,$size,$bsize,greyimg);

  Return frame text for color picker

  input:   $darkimg, # path to dark image
	   $liteimg, # path to light image
	   $size,    # pixel size of image
	   $bsize,   # button pixel size
	   $greyimg  # path to grey image

  returns: html text

=cut

#################################################
# return color picker page
#
# input:	darkimage,	# dark image path/file
#		liteimage,	# lite image path/file
#		$size,		# image size (pixels)
#		$bsize,		# button size (pixels)
#		greyimage	# grey stripe path/file
#
# returns:	html text for color picker page
#
sub picker {
  my ($drkimg,$litimg,$size,$bsize,$gryimg) = @_;
  my $cx = 10;			# offset of color image
  my $cy = 10;
  my $gx = 430;			# offset of grey image
  my $gy = 90;
  my $gen_name = script_name;
  my $img = $image ? $litimg : $drkimg;
  my ($fmie,$umd) = &_force_mdown;
  my $head = q|<html>
<head>
<style type="text/css">
  #cpi {position:absolute; top:| . $cy . q|; left:| . $cx . q|;}
  #gpi {position:absolute; top:| . $gy . q|; left:| . $gx . q|;}
</style>
<script language=javascript1.2>
dcache = new Image();
dcache.src = "| . $drkimg . q|";
lcache = new Image();
lcache.src = "| . $litimg . q|";
var c24flip = | . $image . q|;
var stimg = "| . $_ . q|";
var pict;
parent.mv = |. ($_ = $size >> 1) . q|;
parent.blim = |. ($size - $bsize) . q|;
parent.sf = |. (228 / $_) . q|;
function msie_wa(e,type) {
  var uri = '| . $gen_name . 
  q|' + '?what=' + type + '&scale=' + pict.plot.width + '&flip=' + c24flip;
  pict.links[0].href = uri;
  return true;
}|;

  $head .= q|
function getxy(e,cx,cy) {
  var x;
  var y;
  if (e.which == 1 | .'||'. q| e.button == 1) {
    if (e.clientX) {
      x = e.clientX; y = e.clientY;
    } else {
      x = e.pageX; y = e.pageY;
    }
    x -= cx;
    y -= cy;
    if (x < 0) { x = 0;}
    if (y < 0) { y = 0;}
    parent.px = x;
    parent.py = y;
    return true;
  }
  return false;
}
function cpxy(e) {
  if (getxy(e,| .$cx.','.$cy. q|)) { parent.colorpluck(true);}
  return false;
}
function gpxy(e) {
  if (getxy(e,0,| .$gy. q|)) { parent.greypluck(true);}
  return false;
}|
	if $umd;

$head .= q|
var isID = 0;
var isAll = 0;
var isLayers = 0;
function loaded() {
  if ( pict ) { return false;}
  if (document.getElementsById) { isID = 1; }
  if (document.layers) { isLayers = 1; }
  if (document.all) { isAll = 1; }
  if(navigator.appName.indexOf('Netscape') != -1) {
    document.captureEvents=(Event.MOUSEOVER);
  }
  if (isLayers) {
    pict = document.layers['cpi'].document;
  } else if (isID) {
    pict = document.getElementById('cpi').document;
  } else if (isAll) {
    pict = document.all['cpi'].document;
  } else {
    pict = document;
  }
}
</script>
</head>
|;

  my ($cref,$gref);
  if ($umd) {
    $cref = q|"javascript:void('');//" onMouseDown="return(cpxy(event));"|;
    $gref = q|"javascript:void('');//" onMouseDown="return(gpxy(event));"|; 
  }
  elsif ($fmie || &env_dumb_browser || $ENV{QUERY_STRING} !~ /jsl=1/i) {
    $cref = q|"javascript:void('');//" onMouseDown="return(msie_wa(event,'color'));"|;
    $gref = $gen_name . q|?what=grey|;
  } else {
    $cref = q|'javascript:"<html><body onload=parent.colorpluck()></body></html>"//'|;
    $gref = q|'javascript:"<html><body onload=parent.greypluck()></body></html>"//'|;
  }

  my $c24m = q|
<div ID=cpi><a target=_data
href=| . $cref . q|
><img name="plot" src="| . $img . q|" width=|. $size .q| height=|. $size .q| alt="" border=0 ismap></a></div>
|;

  my $cgrey = q|
<div ID=gpi><a target=_data
href=| . $gref . q|
><img src="|. $gryimg. q|" width=10 height=256 alt="" border=1 ismap></a></div>
|;

  return $head . q|<body bgcolor="#ffffff" onLoad="loaded();">
<table cellspacing=0 cellpadding=0 border=0 width=100%>
<tr>
  <td colspan=2><font size=1>&nbsp;</font></td></tr>
<tr align=center valign=middle>
  <td>|. $c24m . q|</td>
  <td>|. $cgrey . q|</td></tr>
</table>
</body>
</html>
|;
} # end picker page

=item $html_text=no_picker;

  Returns minimum contents for a blank 24 million
  color page when only "Web Only" colors are called

=cut

sub no_picker {
  return q
|<html>
<head>
<script language=javascript>
var c24flip = 0;
</script>
</head>
<body>
This frame is empty
</body>
</head>
|;
}

=item $html_text=cp216_ds($clrdot,$border,$square)

  Returns 216 color & digits page

  input:   clrdot, # path to clear dot image
	   border, # border of color square
	   square, # square size

  returns: html text

=cut

################################################
# return 216 color page and digits
#
# input:   clear dot image,
#	   border 	[default 0]
#	   square size	[default 9]
# returns: html text for 216 color page & digits
#
sub cp216_ds {
  my ($clrimg,$border,$size) = @_;
  $clrimg =~ m|([^/]+)$|;
  my $updimg = $` . 'updown.gif';
  $border = 0 unless $border;
  $size = 9 unless $size;
  $size -= $border;
  
  my $head .= q|<html>
<head>
<script language="javascript1.2">
rgb = new Array(3);
color = new Array('RED','GREEN','BLUE');
clr = new Array('r','g','b');
hexd = new Array(0,1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F');
icache = new Image();
icache.src = "| . $clrimg . q|";
var hex;
function init() {
  if (parent.doce == '') return false;
  if (parent.uno == '') parent.uno = parent.doce;
  self.document.forms.rgb.hex.value = parent.doce;
  self.hexclk();
  return true;
}
function doSubmit() {
  if (parent.opener == null) {
    alert("You can NOT Submit,\nwindow has no opener.\nUse Close to exit.");
    return true; // have to return something
  }
  parent.opener.colorhex = hex;
  parent.close();
  return true;
}
function doRestore() {
  parent.doce = parent.uno;
  init();
  return true;
}
function flipc24m() {
  with (parent._picker) {
    if (c24flip == 0) {
      pict.plot.src = lcache.src;
      c24flip = 1;
    } else {
      pict.plot.src = dcache.src;
      c24flip = 0;
    }
  }
  return false;
}
function update() {
  parent.doce = hex;
  var me = parent._sample.document;
  var t = '<font color=';
  var whitefont = t + 'white>';
  var hexfont = t + '"#' + hex + '">';
  var blackfont = t + 'black>';
  t = '<td width=|. ($colwidth-15) . q| id="';
  var td_bgblack = t + 'dark">';
  var td_bghex = t + 'clrd">';
  var td_bgwhite = t + 'lite">';
  var end = '</font></td>';
  me.write('<html><head>'+"\n");
  me.writeln('<style type="text/css">')
  me.writeln('  #dark{background-color: black;font-family: VERDANA,ARIAL,HELVETICA,SAN-SERIF;font-size: 16px !important;font-weight: bold;}');
  me.writeln('  #lite{background-color: white;font-family: VERDANA,ARIAL,HELVETICA,SAN-SERIF;font-size: 16px !important;font-weight: bold;}');
  me.writeln('  #clrd{background-color: #' + hex + ';font-family: VERDANA,ARIAL,HELVETICA,SAN-SERIF;font-size: 16px !important;font-weight: bold;}');
  me.writeln('</style>');
  me.writeln('</head>');
  me.writeln('<body bgcolor="#ffffff"><table cellspacing=5 cellpadding=5 border=0>');
  me.writeln('<tr align=center valign=middle>');
    me.writeln(td_bgwhite + hexfont + hex + end);
    me.writeln(td_bghex + whitefont + hex + end + '</tr>');
  me.writeln('<tr align=center valign=middle>');
    me.writeln(td_bgblack + hexfont + hex + end);
    me.writeln(td_bghex + blackfont + hex + end + '</tr>');
  me.writeln('</table></body></html>');
  me.close();
  if (typeof top.update_hook == 'function')
    top.update_hook(self);
  return true;
}
ishex = new RegExp("^([a-zA-Z0-9]{2})([a-zA-Z0-9]{2})([a-zA-Z0-9]{2})$");
function ckhex(s) {
  if ( s.match(ishex) ) {
    rgb[0] = parseInt(s.slice(0,2), 16); // r
    rgb[1] = parseInt(s.slice(2,4), 16); // g
    rgb[2] = parseInt(s.slice(4,6), 16); // b
    return true;
  } else {
    alert(s + "\nmust be 6 RGB elements\nhexadecimal a-zA-Z0-9" );
    document.forms.rgb.hex.value = "";
    return false;
  }
}
function setrgb() {
  document.forms.rgb.r.value = rgb[0]; // r
  document.forms.rgb.g.value = rgb[1]; // g
  document.forms.rgb.b.value = rgb[2]; // b
}
function hexclk() {
  var s = document.forms.rgb.hex.value;
  if ( ckhex(s) ) { 
    hex = s;
    setrgb();
    update();
  }
}
function newco(i,c) {
  var newcolor = document.forms.rgb[clr[c]];
  var n = newcolor.value;
  if (n == '') return false;
  if (isNaN(n)) {
    alert(color[c] + ' is not a number');
    newcolor.value = "";
    return false;
  }
  if ( n < 0 | . '||' . q| n > 255 ) {
    alert(color[c] + " out of range\nmust be 0-255");
    newcolor.value = "";
    return false;
  }
  n = Number(n) + Number(i);
  if ( n < 0 ) n = 0;
  if ( n > 255 ) n = 255;
  if ( rgb[c] != n ) {
    rgb[c] = n;
    newcolor.value = n;
    sethex();
  }
  return false; // always!
}
function sethex() {
  if (isNaN(rgb[0]) | .'||'. q| isNaN(rgb[1]) | .'||'. q|isNaN(rgb[2])) return false;
  hex = "" + tohex(rgb[0]) + tohex(rgb[1]) + tohex(rgb[2]);
  document.forms.rgb.hex.value = hex;
  update();
}
function tohex(n) {
  var h = "" + hexd[n>>4] + hexd[n%16];
  return h;
}
function clrupd() {
  document.forms.rgb.r.blur();
  document.forms.rgb.g.blur();
  document.forms.rgb.b.blur();
  document.forms.rgb.hex.blur();
  return true;
}
function clk216(r,g,b) {
  hex = "" + r + g + b;
  document.forms.rgb.hex.value = "" + hex;
  rgb[0] = eval('0x' + r);
  rgb[1] = eval('0x' + g);
  rgb[2] = eval('0x' + b);
  setrgb();
  update();
  return false;
}
function populate(n) {
  for (var i=0; i < n; i++) {
    var I = 'X' + i;
    document[I].src = icache.src;
  }
  return true;
}
</script>
<style>
A.NU { 
  color: #ffffcc;
  background: transparent;
  font-family: VERDANA,ARIAL,HELVETICA,SAN-SERIF;
  font-size: 12px !important;
  font-weight: bold;
  text-decoration: none;
}
#txt {
  font-family: VERDANA,ARIAL,HELVETICA,SAN-SERIF;
  font-size: 10px !important;  
}
</style>
</head>
|;

#####################################

  my $num = 0;

  my $digitbox = q|
<MAP name="RED">
<AREA OnClick="return(newco(1,0));"
shape=rect
coords=0,0,16,7
href="+1"
OnMouseOver="return(clrupd());">
<AREA OnClick="return(newco(-1,0));"
shape=rect
coords=0,8,16,16
href="-1"
OnMouseOver="return(clrupd());">
</map>

<MAP name=GREEN>
<AREA OnClick="return(newco(1,1));"
shape=rect
coords=0,0,16,7
href="+1"
OnMouseOver="return(clrupd());">
<AREA OnClick="return(newco(-1,1));"
shape=rect
coords=0,8,16,16
href="-1"
OnMouseOver="return(clrupd());">
</map>

<MAP name=BLUE>
<AREA OnClick="return(newco(1,2));"
shape=rect
coords=0,0,16,7
href="+1"
OnMouseOver="return(clrupd());">
<AREA OnClick="return(newco(-1,2));"
shape=rect
coords=0,8,16,16
href="-1"
OnMouseOver="return(clrupd());">
</map>

<form name=rgb action="javascript:void('');" method=post>
<table cellspacing=0 cellpadding=0 border=0>
<tr><td colspan=3 id="txt">web colors</td></tr>
<tr>
<td>
<a href="" OnClick="return false;" OnMouseOver="return(clrupd());"><img name=X|. $num++ . q| width=10 height=180 alt="" border=0></a></td>
<td>

<table cellspacing=1 cellpadding=0 border=0>
<tr><td colspan=2>
<a href="" OnClick="return false;" OnMouseOver="return(clrupd());"><img name=X|. $num++ . q| width=60 height=10 alt="" border=0></a></td></tr>
<tr align=center>
  <td id="txt"><font color=red>RED</font><br>
  <input type=text name=r size=3 OnChange="newco(0,0);"></td>
  <td id="txt">&nbsp;<br><img src="| . $updimg . q|" width=16 height=16 border=1 alt="" usemap="#RED"></td></tr>
<tr align=center>
  <td id="txt"><font color=green>GREEN</font><br>
  <input type=text name=g size=3 OnChange="newco(0,1);"></td>
  <td id="txt">&nbsp;<br><img src="| . $updimg . q|" width=16 height=16 border=1 alt="" usemap="#GREEN"></td></tr>
<tr align=center>
  <td id="txt"><font color=blue>BLUE</font><br>
  <input type=text name=b size=3 OnChange="newco(0,2);"></td>
  <td id="txt">&nbsp;<br><img src="| . $updimg . q|" width=16 height=16 border=1 alt="" usemap="#BLUE"></td></tr>
<tr align=center><td colspan=2 id="txt">hex color<br>
  <input type=text name=hex size=6 OnChange="hexclk();"></td></tr>
<tr><td colspan=2>
<a href="" OnClick="return false;" OnMouseOver="return(clrupd());"><img name=X|. $num++ . q| width=60 height=10 alt="" border=0></a></td></tr>
</table>

</td>
<td>
<a href="" OnClick="return false;" OnMouseOver="return(clrupd());"><img name=X|. $num++ . q| width=10 height=180 alt="" border=0></a></td>
</tr>
</table>
</form>
|;

##########################################

  my $colortab = q|
<table cellpadding=0 cellspacing=0 border=1>
<tr><td><table cellpadding=0 cellspacing=0 border=|. $border . q|>
<tr>
|;

  my @forward = ('00','33','66','99','CC','FF');
  my @reverse = reverse @forward;

  my $c = 0;
  my ($r,$g,$b);
  my $line = sub {
    my ($r,$g,$b,$n) = @_;
    return qq|  <td bgcolor="#$r$g$b"><a OnClick="return(clk216('$r','$g','$b'));" href="$r$g$b"><img name=X|.
	$n . qq| height=$size width=$size alt="$r$g$b" border=0></a></td>\n|;
  };

  foreach $b (@forward) {
    foreach $g (@forward) {
      foreach $r (@reverse) {
#	next if $separate && $r eq $b && $r eq $g;
	if ( ++$c > 6 ) {
	  $colortab .= qq|</tr>\n<tr>\n|;
	  $c = 1;
	}
	$colortab .= &$line($r,$g,$b,$num++);
      }
    }
  }
#unless ( $separate ) {
  $colortab .= "</tr>\n</tr>\n";
  foreach (@reverse) {
    $colortab .= &$line($_,$_,$_,$num++)
  }
#}
  $colortab .= q|</tr>
</table>
</td></tr>
</table>
|;

  my $butable = buttontext();
  return $head . q|<body bgcolor="#ffffff" OnLoad="populate(| . $num . q|);">
<table cellspacing=0 cellpadding=0 border=0>
<tr align=center valign=middle>
  <td width=|. $colwidth . q|>|. $colortab . q|</td>
  <td width=|. $colwidth . q|>|. $digitbox .
&make_buttons('#0000cc',60,$butable) . qq|
<font id="txt">$VERSION</font>
</td></tr>
</table>
</body>
</html>
|;
}

=item $javascript_text = jslib;

  Return contents of javascript library

  input: none

=cut

################################################
# javascript xy resolver library
#
# input:	none
# return:	library text
#
sub jslib {
  return '' if ($obfuscate && (caller(1))[3] !~ /::msie_frame/);
  return q|
// copyright 2002
// Michael A. Robinton, michael@bizsystems.com
var r;
var g;
var b;
colorpluck = function() {
  pluckXY(arguments[0]);
  if ( px > blim && py > blim ) return(window._digits.flipc24m());
  px -= mv;
  py = mv - py;
  r = color_R(px,py);
  if (r > 255) return true; // have to return something
  if (color_GB(px,py)) return true; // ditto
  if (window._picker.c24flip != 0) {
    r = 255 - r;
    g = 255 - g;
    b = 255 - b;
  }
  setcolor(r,g,b);
  return true;
}
var con = 2.236067977;
color_R = function(x,y) {
  if (x < 0) x = -x;
   r = y + (x/2);
  if (r < 0) return 0;
  r = (con * r * sf) + 1;
  r >>= 1;
  if (r == 256) return 255;
  return r;
}
color_GB = function(x,y) {
  y = -y * sf;
  x *= sf;
  b = y + x/2;
  g = y - x/2;
  if (b < 0) b = 0;
  if (g < 0) g = 0;
  if (x < 0) {
    g = b - x;
  } else {
    b = g + x;
  }
  b = (con*b + 1) >>1;
  g = (con*g + 1) >>1;
  if (g > 256) return g;
  if (b > 256) return b;
  if (g > 255) g = 255;
  if (b > 255) b = 255;
  return 0;
}
greypluck = function() {
  pluckXY(arguments[0]);
  if (py > 255) py = 255;
  py = 255 - py;
  setcolor(py,py,py);
  return true;
}
pluckXY = function(skip) {
  if ( ! skip ) {
    var xy = window._data.document.location.search;
    var qloc = xy.lastIndexOf('?') + 1;
    var cloc = xy.lastIndexOf(',');
    px = bound(xy.substring(qloc,cloc));
    py = bound(xy.substring(cloc+1,xy.length));
  }
}
bound = function(n) {
  n = 0 + n;
  if (isNaN(n)) return 0;
  if (n < 0) n = 0;
  return n;
}
setcolor = function(r,g,b) {
  with (window._digits) {
  rgb[0] = r;
  rgb[1] = g;
  rgb[2] = b;
  setrgb();  
  sethex();
  }
  return true;
}
|;
}

#########################################
# replace problematic characters in js lib
#
sub j2s {
  my ($tp) = @_;
#  sub operation
  $$tp =~  s/%/%j/g;
  $$tp =~ s/\\/%a/g;
  $$tp =~  s/'/%v/g;
  $$tp =~ s/\$/%s/g;
  $$tp =~  s/"/%c/g;
  $$tp =~ s/\@/%r/g;
#  $$tp =~  s//%i/g;
  $$tp =~ s/\r/%p/g;
  $$tp =~ s/\n/%t/g;
  1;
}

=item $html=make_buttons(\%look_n_feel,$url,$active,\@buttons,$xtra);

  Called internally

  Return the html text for a button bar

  input:  button_color, width, \@buttons

  @buttons is a list of the form = (
        # text        command 
        'BUTT1' => 'command1',
        'BUTT2' => 'command2',
        ''      => '',		# empty
  );
        If the button text is false,
        a spacer is inserted in the button bar

  returns:      html for button bar


  NOTE:         class NU must be defined
  example:
                <style>
                A.NU { 
                  color: red; // #ff0000
                  background: transparent;
                  font-family: VERDANA,ARIAL,HELVETICA,SAN-SERIF;
		  font-size:  12px !important;
                  font-weight: bold;
                  text-decoration: none;
                }
                </style>

=cut

sub make_buttons {
  my ($bc,$width,$but) = @_;
  my $butbar = qq|<table cellspacing=0 cellpadding=0 border=0 width=$width>
<tr align=center>
|;
  for (my $i=0; $i<= $#{$but}; $i+=2) {
    if ($but->[$i+1]) {
      $butbar .= q|<td><table cellspacing=0 cellpadding=2 border=2 width=100%><tr><td align=center bgcolor="| .
      $bc . qq|"><a class=NU href="$but->[$i+1]">$but->[$i]</a></td></tr></table></td>|;
    }
    else {
      $butbar .= q|<td><font size=1>&nbsp;</font></td>|;
    }
    $butbar .= qq|</tr>\n<tr align=center>\n|;
  }
  $butbar .= qq|</table>\n|;
}
 
=item $html_text=pluck($color, ...);

  Return x,y coordinates for browsers that
  do not recognize "javascript:xxx" from
  within frames like braindead MSIE

  input:  color,	'grey' or 'color'
	  ...server_update args (if used);

=cut

################################################
# return xy plucker page, generally only used by MSIE
#
# input:	start of subroutine name
#		i.e. 'color', 'grey'
#		colorpluck or greypluck
# returns:	html text with x,y stuff from 'ismap'
#
sub pluck {
  if ($server_only) {
    require Graphics::CPickServer;
    goto &Graphics::CPickServer::server_update;
  }
  my ($subhead) = @_;
  return q|<html>
<head>
<script language=javascript1.2>
parent.doce = '';
</script>
</head>
<body bgcolor="#ffffff" Onload="parent.|. $subhead . q|pluck();">
</body>
</html>
|;
}

=item $html_text=hex_update($hex_color);

  Return the command and color number
  to the 'data' frame to force an update
  of the 'sample' frame and 'digits'

  input: hex color	# i.e. 6699CC

=cut

################################################
# return hex update page to server
# used for init and by grey_update and rgb_update
# though it can be used directly if fed the parameters
#
# input:	hex number
# returns:	html text
#
sub hex_update {
  my ($hex) = @_;
  $_ = $hex;
  $hex = '000000' unless $hex =~ /^[a-fA-F0-9]{6}$/;
  return q|<html>
<head>
<!-- |.$_.q| -->
<script language=javascript1.2>
parent.doce = "" + "|. $hex . q|";
</script>
</head>
<body bgcolor="#ffffff" onLoad="if (parent.uno != '') parent._digits.init();">
</body>
</html>
|;
}

=item $rv = env_dumb_browser;

  Return true if $ENV{HTTP_USER_AGENT}
  contains a dumb browser

=back

=cut

sub env_dumb_browser {
  return 1 if $ENV{HTTP_USER_AGENT} =~ /MSIE/i;
#  return 1 if $ENV{HTTP_USER_AGENT} =~ /GECKO/i;
  return 0;
}

=head1 EXPORT

  None by default.

=head1 AUTHOR
   
Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT and LICENSE

  Copyright 2002 - 2008 Michael Robinton, BizSystems.

This module is free software; you can redistribute it and/or modify it
under the terms of either:

  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,
  
  or

  b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=cut

1;

