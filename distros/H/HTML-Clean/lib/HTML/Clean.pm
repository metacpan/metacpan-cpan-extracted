package HTML::Clean;

use Carp;
use IO;
use Fcntl;
use strict;
require 5.004;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

# Items to export to callers namespace
@EXPORT = qw();

$VERSION = '0.8';

=head1 NAME

HTML::Clean - Cleans up HTML code for web browsers, not humans

=head1 SYNOPSIS

  use HTML::Clean;
  $h = new HTML::Clean($filename); # or..
  $h = new HTML::Clean($htmlcode);
 
  $h->compat();
  $h->strip();
  $data = $h->data();
  print $$data;

=head1 DESCRIPTION

The HTML::Clean module encapsulates a number of common techniques for
minimizing the size of HTML files.  You can typically save between
10% and 50% of the size of a HTML file using these methods.
It provides the following features:

=over 8

=item Remove unneeded whitespace (begining of line, etc)

=item Remove unneeded META elements.

=item Remove HTML comments (except for styles, javascript and SSI)

=item Replace tags with equivilant shorter tags (<strong> --> <b>)

=item etc.

=back

The entire proces is configurable, so you can pick and choose what you want
to clean.

=head1 THE HTML::Clean CLASS

=over 4

=cut


######################################################################

=head2 $h = new HTML::Clean($dataorfile, [$level]);

This creates a new HTML::Clean object.  A Prerequisite for all other
functions in this module.

The $dataorfile parameter supplies the input HTML, either a filename,
or a reference to a scalar value holding the HTML, for example:

  $h = new HTML::Clean("/htdocs/index.html");
  $html = "<strong>Hello!</strong>";
  $h = new HTML::Clean(\$html);

An optional 'level' parameter controls the level of optimization
performed.  Levels range from 1 to 9.  Level 1 includes only simple
fast optimizations.  Level 9 includes all optimizations.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  
  my $data = shift;
  my $level = shift;

  if ($self->initialize($data)) {
    # set the default level
    $level = 9 if (!$level);
    $self->level($level);
    return $self;
  } else {
    undef $self;
    return undef;
  }
}
  
	 
#
# Set up the data in the self hash..
#

=head2 $h->initialize($dataorfile)

This function allows you to reinitialize the HTML data used by the
current object.  This is useful if you are processing many files.  

$dataorfile has the same usage as the new method.

Return 0 for an error, 1 for success.

=cut

sub initialize {
  my($self, $data) = @_;
  $self->{'DATA'} = undef;

  # Not defined?  Just return true.  
  return(1) if (!$data); 

  # Check if it's a ref
  if (ref($data)) {
    $self->{DATA} = $data;
    return(1);
  }
  
  # Newline char, really an error, but just go with it..
  if ($data =~ /\n/) {
    $self->{'DATA'} = \$data;
  }
  
  # No newline?  Must be a filename
  if (-f $data) {
    my $storage;

    sysopen(IN, "$data", O_RDONLY) || return(0);
    while (<IN>) {
      $storage .= $_;
    }
    close(IN);
    $self->{'DATA'} = \$storage;
    return(1);
  }

  return(0);  # file not found?
}


=head2 $h->level([$level])

Get/set the optimization level.  $level is a number from 1 to 9.

=cut

sub level {
  my($self, $level) = @_;

  if (defined($level) && ($level > 0) && ($level < 10)) {
    $self->{'LEVEL'} = $level
  }
  return($self->{'LEVEL'});
}

=head2 $myref = $h->data()

Returns the current HTML data as a scalar reference.

=cut

sub data {
  my($self) = @_;

  return $self->{'DATA'};
}


# Junk HTML comments (INTERNAL)

sub _commentcheck($) {
  my($comment) = @_;

  $_ = $comment;
  
  # Server side include
  return($comment) if (m,^<!--\#,si);

  # ITU Hack..  preserve some frontpage components
  return($comment) if (m,^<!-- %,si);
  return($comment) if (m,bot="(SaveResults|Search|ConfirmationField)",si);

  # Javascript
  return($comment) if (m,//.*-->$,si);
  return($comment) if (m,navigator\.app(name|version),si);

  # Stylesheet
  return($comment) if (m,[A-z0-9]+\:[A-z0-9]+\s*\{.*\},si);
  return('');
}


# Remove javascript comments (INTERNAL)

sub _jscomments {
  my($js) = @_;

  $js =~ s,\n\s*//.*?\n,\n,sig;
  $js =~ s,\s+//.*?\n,\n,sig;

  # insure javascript is hidden
  
  if ($js =~ m,<!--,) {
     $js =~ s,</script>,// -->\n</script>,si;
  }
  return($js);
}

# Clean up other javascript stuff..

sub _javascript {
  my($js) = @_;

  # remove excess whitespace at the beginning and end of lines
  $js =~ s,\s*\n+\s*,\n,sig;
  
  # braces/semicolon at end of line, join next line
  $js =~ s,([;{}])\n,$1,sig;

  # What else is safe to do?

  return($js);
}

# replace #000000 -> black, etc..
# Does the browser render faster with RGB?  You would think so..

sub _defcolorcheck ($) {
  my($c) = @_;

  $c =~ s/\#000000/black/;
  $c =~ s/\#c0c0c0/silver/i;
  $c =~ s/\#808080/gray/;
  $c =~ s/\#ffffff/white/i;
  $c =~ s/\#800000/maroon/;
  $c =~ s/\#ff0000/red/i;
  $c =~ s/\#800080/purple/;
  $c =~ s/\#ff00ff/fuchsia/i;
  $c =~ s/\#ff00ff/fuchsia/i;
  $c =~ s/\#008000/green/;
  $c =~ s/\#00ff00/lime/i;
  $c =~ s/\#808000/olive/;
  $c =~ s/\#ffff00/yellow/i;
  $c =~ s/\#000080/navy/;
  $c =~ s/\#0000ff/blue/i;
  $c =~ s/\#008080/teal/i;
  $c =~ s/\#00ffff/aqua/i;
  return($c);
}

# For replacing entities with numerics 
use vars qw/ %_ENTITIES/;
%_ENTITIES =  (
   'Agrave' => 192,
   'Aacute' => 193,
   'Acirc' => 194,
   'Atilde' => 195,
   'Auml' => 196,
   'Aring' => 197,
   'AElig' => 198,
   'Ccedil' => 199,
   'Egrave' => 200,
   'Eacute' => 201,
   'Ecirc' => 202,
   'Euml' => 203,
   'Igrave' => 204,
   'Iacute' => 205,
   'Icirc' => 206,
   'Iuml' => 207,
   'ETH' => 208,
   'Ntilde' => 209,
   'Ograve' => 210,
   'Oacute' => 211,
   'Ocirc' => 212,
   'Otilde' => 213,
   'Ouml' => 214,
   'Oslash' => 216,
   'Ugrave' => 217,
   'Uacute' => 218,
   'Ucirc' => 219,
   'Uuml' => 220,
   'Yacute' => 221,
   'THORN' => 222,
   'szlig' => 223,
   'agrave' => 224,
   'aacute' => 225,
   'acirc' => 226,
   'atilde' => 227,
   'auml' => 228,
   'aring' => 229,
   'aelig' => 230,
   'ccedil' => 231,
   'egrave' => 232,
   'eacute' => 233,
   'ecirc' => 234,
   'euml' => 235,
   'igrave' => 236,
   'iacute' => 237,
   'icirc' => 238,
   'iuml' => 239,
   'eth' => 240,
   'ntilde' => 241,
   'ograve' => 242,
   'oacute' => 243,
   'ocirc' => 244,
   'otilde' => 245,
   'ouml' => 246,
   'oslash' => 248,
   'ugrave' => 249,
   'uacute' => 250,
   'ucirc' => 251,
   'uuml' => 252,
   'yacute' => 253,
   'thorn' => 254,
   'yuml' => 255
);

=head2 strip(\%options);

Removes excess space from HTML

You can control the optimizations used by specifying them in the
%options hash reference.

The following options are recognized:

=over 8

=item boolean values (0 or 1 values)

  whitespace    Remove excess whitespace
  shortertags   <strong> -> <b>, etc..
  blink         No blink tags.
  contenttype   Remove default contenttype.
  comments      Remove excess comments.
  entities      &quot; -> ", etc.
  dequote       remove quotes from tag parameters where possible.
  defcolor      recode colors in shorter form. (#ffffff -> white, etc.)
  javascript    remove excess spaces and newlines in javascript code.
  htmldefaults  remove default values for some html tags
  lowercasetags translate all HTML tags to lowercase

=item parameterized values

  meta        Takes a space separated list of meta tags to remove, 
              default "GENERATOR FORMATTER"

  emptytags   Takes a space separated list of tags to remove when there is no
              content between the start and end tag, like this: <b></b>. 
              The default is 'b i font center'

=back

=cut

use vars qw/
	  $do_whitespace 
	  $do_shortertags  
	  $do_meta       
	  $do_blink 
	  $do_contenttype 
	  $do_comments 
	  $do_entities 
	  $do_dequote
          $do_defcolor
          $do_emptytags
          $do_javascript
          $do_htmldefaults
          $do_lowercasetags
          $do_defbaseurl
  /; 

$do_whitespace  = 1;
$do_shortertags = 1;
$do_meta        = "generator formatter";
$do_blink       = 1;
$do_contenttype = 1;
$do_comments    = 1;
$do_entities    = 1;
$do_dequote     = 1;
$do_defcolor    = 1;
$do_emptytags   = 'b i font center';
$do_javascript  = 1;
$do_htmldefaults  = 1;
$do_lowercasetags = 1;
$do_defbaseurl  = '';

sub strip {
  my($self, $options) = @_;

  my $h = $self->{'DATA'};
  my $level = $self->{'LEVEL'};

  # Select a set of options based on $level, and then modify based on 
  # user supplied options.

  _level_defaults($level);

  if(defined($options)) {
    no strict 'refs';
    for (keys(%$options)) {
      ${"do_" . lc($_)} = $options->{$_} if defined ${"do_" . lc($_)};
    }
  }

  if ($do_shortertags) {
    $$h =~ s,<strong>,<b>,sgi;
    $$h =~ s,</strong>,</b>,sgi;
    $$h =~ s,<em>,<i>,sgi;
    $$h =~ s,</em>,</i>,sgi;
  }

  if ($do_whitespace) {
    $$h =~ s,[\r\n]+,\n,sg; # Carriage/LF -> LF
    $$h =~ s,\s+\n,\n,sg;   # empty line
    $$h =~ s,\n\s+<,\n<,sg; # space before tag
    $$h =~ s,\n\s+,\n ,sg;  # other spaces

    $$h =~ s,>\n\s*<,><,sg; # LF/spaces between tags..

    # Remove excess spaces within tags.. note, we could parse out the elements
    # and rewrite for excess spaces between elements.  perhaps next version.
    # removed due to problems with > and < in tag elements..
    #$$h =~ s,\s+>,>,sg;
    #$$h =~ s,<\s+,<,sg;
    # do this again later..
  }

  if ($do_entities) {
    $$h =~ s,&quot;,\",sg;
    # Simplify long entity names if using default charset...
    $$h =~ m,charset=([^\"]+)\",;
    if (!defined($1) || ($1 eq 'iso-8859-1')) {
      $$h =~ s,&([A-z]+);,($_ENTITIES{$1}) ? chr($_ENTITIES{$1}) : $&,sige;
    }
  }

  if ($do_meta) {
    foreach my $m (split(/\s+/, $do_meta)) {
      $$h =~ s,<meta name="$m"[^>]*?>,,sig;
    }
  }
  if ($do_contenttype) {
    # Don't need this, since it is the default for most web servers
    # Also gets rid of 'blinking pages' in older versions of netscape.
    $$h =~ s,<meta http-equiv="Content-Type".*?content="text/html;.*?charset=iso-8859-1">,,sig;
  }

  if ($do_defcolor) {
    $$h =~ s,(<[^<]+?color=['"]?\#[0-9A-Fa-f]+["']?),_defcolorcheck($&),sige;
  }
  if ($do_comments) {
    # don't strip server side includes..
    # try not to get javascript, or styles...
    $$h =~ s,<!--.*?-->,_commentcheck($&),sige;

    # Remove javascript comments
    $$h =~ s,<script[^>]*(java|ecma)script[^>]*>.*?</script>,_jscomments($&),sige;
  }

  if ($do_javascript) {
    #
    $$h =~ s,<script[^>]*(java|ecma)script[^>]*>.*?</script>,_javascript($&),sige;
  }

  if ($do_blink) {
    $$h =~ s,<BLINK>,,sgi;
    $$h =~ s,</BLINK>,,sgi;
  }

  if ($do_dequote) {
    while ($$h =~ s,<([A-z]+ [A-z]+=)(['"])([A-z0-9]+)\2(\s*?[^>]*?>),<$1$3$4,sig)
      {
	# Remove alphanumeric quotes.  Note, breaks DTD..
	;
      }
  }
  # remove <b></b>, etc..
  if ($do_emptytags) {
     my $pat = $do_emptytags;
     $pat =~ s/\s+/|/g;

     while ($$h =~ s,<($pat)(\s+[^>]*?)?>\s*</\1>,,siog){}

  }
  if ($do_htmldefaults) {
     # Tables
     # seems to break things..
     #$$h =~ s,(<table[^>]*)\s+border=0([^>]*>),$1$2,sig;
     $$h =~ s,(<td[^>]*)\s+rowspan=1([^>]*>),$1$2,sig;
     $$h =~ s,(<td[^>]*)\s+colspan=1([^>]*>),$1$2,sig;

     #

     # P, TABLE tags are default left aligned..
     # lynx is inconsistent in this manner though..

     $$h =~ s,<(P|table|td)( [^>]*)align=\"?left\"?([^>]*)>,<$1$2$3>,sig;

     # OL start=1
     $$h =~ s,(<OL [^>]*)start=\"?1\"?([^>]*>),$1$2,sig;

     # FORM
     $$h =~ s,(<form [^>]*)method=\"?get\"?([^>]*>),$1$2,sig;
     $$h =~ s,(<form [^>]*)enctype=\"application/x-www-form-urlencoded\"([^>]*>),$1$2,sig;

     # hr
     $$h =~ s,(<hr [^>]*)align=\"?center\"?([^>]*>),$1$2,sig;
     $$h =~ s,(<hr [^>]*)width=\"?100%\"?([^>]*>),$1$2,sig;

     # URLs
     $$h =~ s,(href|src)(=\"?http://[^/:]+):80/,$1$2/,sig;
  }

  if ($do_whitespace) {
    # remove space within tags <center  > becomes <center>
    $$h =~ s,\s+>,>,sg;
    $$h =~ s,<\s+,<,sg;
    # join lines with a space at the beginning/end of the line
    # and a line that begins with a tag
    $$h =~ s,>\n ,> ,sig;
    $$h =~ s, \n<, <,sig;
  }

  if ($do_lowercasetags) {
    # translate tags to lowercase to (hopefully) improve compressability..

    # simple tags <H1>, </H1> etc.
    $$h =~ s,(<[/]?[a-zA-Z][a-zA-Z0-9_-]*\s*>),\L$1\E,sg;

    # the rest..
    $$h =~ s/(<[a-zA-Z][a-zA-Z0-9_-]*)(\s+.*?>)/_lowercasetag($1,$2)/sge;
  }
}

sub _lowercasetag {
  my($prefix, $body) = @_;
  $prefix =~ s/^(.+)$/\L$1\E/;
  $body =~ s/(\s+[a-zA-Z][a-zA-Z0-9_-]*)(\s*=\s*[^"\s]+|\s*=\s*"[^"]*"|>|\s)/\L$1\E$2/sg;
  return $prefix.$body;
}

# set options based on the level provided.. INTERNAL

sub _level_defaults($) {
  my ($level) = @_;

  $do_whitespace  = 1; # always do this...

  # level 2
  $do_shortertags = ($level > 1) ? 1 : 0;
  $do_meta        = ($level > 1) ? "generator formatter" : "";
  $do_contenttype = ($level > 1) ? 1 : 0;

  # level 3
  $do_entities    = ($level > 2) ? 1 : 0;
  $do_blink       = ($level > 2) ? 1 : 0;

  # level 4
  $do_comments    = ($level > 3) ? 1 : 0;
  $do_dequote     = ($level > 3) ? 1 : 0;
  $do_defcolor    = ($level > 3) ? 1 : 0;
  $do_emptytags   = ($level > 3) ? 'b i font center' : 0; 
  $do_javascript  = ($level > 3) ? 1 : 0;
  $do_htmldefaults = ($level > 3) ? 1 : 0; 
  $do_lowercasetags = ($level > 3) ? 1 : 0; 

  # higher levels reserved for more intensive optimizations.
}

######################################################################

=head2 compat()

This function improves the cross-platform compatibility of your HTML.
Currently checks for the following problems:

=over 8

=item Insuring all IMG tags have ALT elements.

=item Use of Arial, Futura, or Verdana as a font face.

=item Positioning the <TITLE> tag immediately after the <head> tag.

=back

=cut

sub compat {
  my($self, $level, $options) = @_;

  my $h = $self->{'DATA'};

  $$h =~ s/face="arial"/face="arial,helvetica,sansserif"/sgi;
  $$h =~ s/face="(verdana|futura)"/face="$1,arial,helvetica,sansserif"/sgi;

  # insure that <title> tag is directly after the <head> tag
  # Some search engines only search the first N chars. (PLweb for instance..)

  if ($$h =~ s,<title>(.*)</title>,,si) {
    my $title = $1;
    $$h =~ s,<head>,<head><title>$title</title>,si;
  }

  # Look for IMG without ALT tags.
  $$h =~ s/(<img[^>]+>)/_imgalt($1)/segi;
}

sub _imgalt {
  my($tag) = @_;

  $tag =~ s/>/ alt="">/ if ($tag !~ /alt=/i);
  return($tag);
}  

=head2 defrontpage();

This function converts pages created with Microsoft Frontpage to
something a Unix server will understand a bit better.  This function
currently does the following:

=over 8

=item Converts Frontpage 'hit counters' into a unix specific format.

=item Removes some frontpage specific html comments

=back

=cut


sub defrontpage {
  my($self) = @_;

  my $h = $self->{'DATA'};

  while ($$h =~ s,<img\sSRC="[\./]*_vti_bin/fpcount.exe(/.*/).Page=(.*?)\|.*?\s(.*?)>,<img src="/counter?link=$1$2" $3>,xis) {
      print "Converted a Hitcounter.. $1, $2, $3\n";
  }
  $$h =~ s,<!--(mstheme|msthemeseparator|msnavigation)-->,,sgx;
}
=back

=head1 SEE ALSO

=head2 Modules

FrontPage::Web, FrontPage::File

=head2 Web Sites

=over 6

=item Distribution Site - http://people.itu.int/~lindner/

=back 

=head1 AUTHORS

Paul Lindner for the International Telecommunication Union (ITU)

=head1 COPYRIGHT

The HTML::Strip module is Copyright (c) 1998,99 by the ITU, Geneva Switzerland.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

1;
__END__
