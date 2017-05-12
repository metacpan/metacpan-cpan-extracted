=head1 NAME

Image::Shoehorn::Gallery - generate "smart" HTML slideshows from a directory of image files.

=head1 SYNOPSIS

 use Image::Shoehorn::Gallery;

 Image::Shoehorn::Gallery->create({
   	 	                   source      => "~/my-images",
   	 	                   directory   => "/htdocs/images",
		                   url         => "http://mysite.com/images",
		                   static      => 1,
		                   scales      => [
				                   [ "thumb","75x50"  ],
                                                   [ "default", "50%" ],
				                   [ "small","25%"    ],
				                   [ "medium","50%"   ],
				                ],
                                   scale_if    => { x => 400 , y => 300 },
                                   iptc        => ["headline","caption/abstract"],
                                   set_lang    => "en-ca",
                                   set_styles  => {
                                                  image => [
                                                            {title=>"my css",href=>"/styles.css"},
                                                           ],
                                                 },
                                   set_index_images => { default => 1 },
    		                  });

=head1 DESCRIPTION

Image::Shoehorn::Gallery generates HTML slideshows from a directory of image files. But wait, there's more!

Image::Shoehorn uses I<XML::Filter::XML_Directory_2XHTML>, I<XML::SAX::Machines> and a small army of I<Image::*> packages allowing you to :

=over 4

=item *

Create one, or more, scaled versions of an image, and their associate HTML pages. Scaled version may also be defined but left to be created at a later date by I<Apache::Image::Shoehorn>.

Associate HTML are always "baked", rather than "fried" (see also : http://www.aaronsw.com/weblog/000404 )

=item *

Read a user-defined list of IPTC and EXIF metadata fields from each image and include the data in the HTML pages.

=item *

Generate named indices and next/previous links by reading IPTC "headline" data.

=item *

Define one, or more, SAX filters to be applied to "index" and individual "image" documents before they are passed the final I<XML::SAX::Writer> filter for output.

The default look and feel of the gallery pages is pretty plain, but you could easily define a "foofy design" XSL stylesheet to be applied with the I<XML::Filter::XSLT> SAX filter:

 <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                 version = "1.0" >

  <xsl:template match = "/">
  <html>
   <xsl:copy-of select = "html/head" />
   <body>

    <!-- lots of foofy design stuff -->
    <xsl:copy-of select = "/html/body/*" />
    <!-- lots of foofy design stuff -->

   </body>
  </html>
  </xsl:template>

 </xsl:stylesheet>

=item *

Generates valid XHTML (strict) and CSS!

=back

=cut

use strict;
package Image::Shoehorn::Gallery;

$Image::Shoehorn::Gallery::VERSION = '0.22';

use Carp;
use Carp::Heavy;
use Digest::MD5 qw (md5_hex);

use DirHandle;

use File::Basename;
use File::Copy;
use File::Path;

use Image::Shoehorn;
use Image::Size qw (imgsize);

use IO::File;
use XML::SAX::Writer;
use XML::Filter::XML_Directory_2XHTML;
use XML::Directory::SAX;

use XML::SAX::Machines qw (Pipeline);
$XML::SAX::ParserPackage = "XML::SAX::Expat";

#

my $directory = undef;
my $source    = undef;
my $dest      = undef;

my $url       = undef;

my $static    = undef;
my $scales    = {};
my $scaleif   = {};

my $views     = [];
my $iptc      = [];
my $exif      = [];

my $maxdepth  = undef;
my $encoding  = undef;
my $lang      = undef;

my $styles    = {};
my $filters   = {};
my $images    = {};

my $verbose   = 0;
my $force     = 0;

my $conf      = undef;

#

my $cur_source = undef;
my $cur_dest   = undef;

my $visit         = 0;

=head1 PACKAGE METHODS

=head2 __PACKAGE__->create(\%args)

This is the magic spell that will create your galleries.

Valid arguments are :

=over 4

=item *

B<source>

String.

This is the path to the directory that you want to read images from.

=item *

B<destination>

String.

This is the path to directory that you want to write images, and HTML files, to. If undefined, then the value of I<source> will be used.

=item *

B<directory>

String. 

Deprecated in favour of I<source> and I<destination>. If present, it will be used as *both* the source and destination directories.

=item *

B<url>

String. 

The URL that maps to I<directory> on your webserver.

=item *

B<maxdepth>

Int.

The maximum number of sub directories to munge and render.

=item *

B<static>

Boolean.

Used in conjunction with the I<scales> option for generating scaled versions of an image and their URLs.

If false, or not defined, the package will assume that you have configured I<Apache::Image::Shoehorn> to generate scaled versions of an image.

If true, then the package will output image URLs that map to static images on the filesystem and ask I<Image::Shoehorn> to create the new files, or update existing ones.

Note, however, that the "thumb" (thumbnail) image will be generated regardless of whether or not you are using I<Apache::Image::Shoehorn>. This is actually a feature since you would peg your machine having to create all those thumbnails the first time you loaded an especially large index page.

=item *

B<scales>

Array reference containing one, or more, array referece.

Each of the child arrays should contain (2) elements :

=over 4

=item *

I<name>

A name like "small" or "medium". This name is used as part of the naming scheme for images that have been scaled and their associate HTML pages.

Names can be pretty much anything you'd like, with the exception of "thumb" and "default" which are discussed below.

=item *

I<scale>

These are required whether or not you are going to be generate static images. Even if you are going to render your images on the fly using I<Apache::Image::Shoehorn>, the HTML spec (hi Karl) mandates that you provide height and widgth attributes for your img elements. So...

Takes arguments in the same form as I<Image::Shoehorn> which are, briefly :

=over 4

=item *

B<n>%

=item *

B<n>xB<n>

=item *

xB<n>

=item *

B<n>x

=back

There are two special scale names :

=over 4

=item *

I<thumb>

You must define a thumb scale. It is used to generate thumbnails for the index page which are, in turn, used when generating the individual HTML pages for each image.

=item *

I<default>

I<This feature is only supported for images that are rendered statically :-(>.

Suppose your source images are very large and you would like to use a scaled version as the default image in your gallery. You may want to do this because you are concerned about people doing bad things with your high quality images or you don't want to pay the additional charges that your web-hosting service will charge you for all those 2-3 MB files. Or both.

The default image is the default view and its dimensions are what all other scales are keyed off of.

For example, your source image is 1200x840 and you define two scales (not including the 'thumb' scale.) The first is called 'small' and the second 'default'; both have a value of '50%'.

I<Note: the hooks for creating default images are smart about paying attention to the scaleif options, discussed below.>

Since you have defined a default image, it will be created in your source directory with the same basename as the source image itself. It will be half the size of the original, 600x420. The 'small' version will be created and will be half the size of the 'default' image, rather than the source, or 300x210.

B<Remember to use this feature carefully if your source and destination directories are the same.> You could easily overwrite all your source images with newer default "sources".

=back

=back

=item *

B<scaleif>

Hash reference.

Define height and width values that will be used to determine whether or not an image should actually be scaled. 

For example, it is unlikely that you will need to create a small version (say 25% the size of the original) if your source file is 100 by 150 pixels. You might - that's your business - but atleast this way you can opt out.

Images will only be scaled if their height or width is greater than the height and/or width listed in this argument.

You may define one or both of the following :

=over 4

=item *

I<x>

Int.

The minimum width that an image must have to be scaled.

=item *

I<y>

Int.

The minimum height that an image must have to be scaled.

=back

Note that although multiple image files may not be created, if the source image is smaller than the dimensions passed in this argument, their associate HTML files will be generated. Don't worry, they'll point to the same unscaled image. 

Think of it as the glass being half full.

=item *

B<iptc>

Array reference.

A list of IPTC fields to read from an image. Fields are presented in the order they are defined.

For a complete list of IPTC fields, please consult the L<Image::IPTCInfo>.

=item *

B<exif>

Array reference.

A list of EXIF fields to read from an image. Fields are presented in the order they are defined.

For a complete list of EXIF fields, please consult http://www.ba.wakwak.com/~tsuruzoh/Computer/Digicams/exif-e.html

=item *

B<set_lang>

String.

Set the language code for your HTML documents.

=item *

B<set_styles>

Hash reference. 

Used to override the default CSS for either and "index" page or an individual "image" page.

Valid hash keys are :

=over 4

=item *

B<index>

=item *

B<image>

=back

Where each key expects an array ref of hash refs whose keys are :

=over 4

=item *

I<href>

=item *

I<title>

Default is ""

=item *

I<rel>

Default is "stylesheet"

=item *

I<media> 

Default is "all".

=back

Styles will be added in the order that they are defined in the array ref.

The default CSS styles are outlined below.

=item *

B<set_filters>

Hash reference

Define one or more additional filters to be applied to either an "index" or individual "image" page.

Valid hash keys are :

=over 4

=item *

B<index>

=item *

B<image>

=back

Filters are applied last, before events are finally handed off to I<XML::SAX::Writer> and in the order that they are defined.

Example: 

 package MySAX;
 use base qw (XML::SAX::Base);

 sub start_element {
    my $self = shift;
    my $data = shift;

    $self->SUPER::start_element($data);

    if ($data->{Name} eq "body") {
       $self->SUPER::start_element({Name=>"h1"});
       $self->SUPER::characters({Data=>"hello world"});
       $self->SUPER::end_element({Name=>"h1"});
    }
 }

 package main;

 # The following will add <h1>hello world</h1>
 # at the top of all your 'image' pages. Woot!

 use Image::Shoehorn::Gallery;
 Image::Shoehorn::Gallery->create({
                                   # ...

                                   set_filters => { image => [ MySAX->new() ]},
                                  });

=item *

B<set_index_images>

Hash reference.

Define images to associate with files in a directory listing. Valid keys are :

=over 4

=item *

I<image>

Image to associate with a file whose media type is "image"

Default is to generate and include a thumbnail, as defined by the "thumb" scale option (see above.)

=item *

I<directory>

Image to associate with a directory.

=item *

I<file>

Image to associate with a file whose media type is not "image"

Example :

 # Use the default Apache icons

 my %images = (
	       directory => {
			     src    => "/icons/dir.gif",
			     height => "20",
			     width  => "20",
			     alt    => "ceci n'est pas un dossier",
			    },
	       file => {
			src    => "/icons/unknown.gif",
			height => "20",
			width  => "20",
			alt    => "ceci n'est pas un fichier",
		       },
	       );

 Image::Shoehorn::Gallery->create({
				   # ...
				   set_index_images => \%images,
				  });

=item *

I<default>

Boolean.

This is just a shortcut to use the default I<image> handler and the handlers for I<files> and I<directories> example described above. 

If you are not using Apache for your web server and/or have not aliased the Apache icons folder to /icons, it won't do you much good.

=back

Valid keys arguments are either :

=over 4

=item *

B<hash reference>

Containing key/value pairs for the following image attributes :

=over 4

=item *

I<src>

=item *

I<height>

=item *

I<width>

=item *

I<alt>

=back

=item *

B<code reference>

The code reference will be passed the absolute path of the current image and is expected to return a hash reference similar to the one described above.

=back

This is an I<XML::Filter::XML_Directory_2XHTML>-ism. Please consult docs for further details.

=item *

B<set_encoding>

String.

Default is "UTF-8"

=item *

B<force>

Int.

By default neither the scaled version of an image, nor the associate HTML files, will be created unless the source image has a more recent modification date. 

You can use this option to override this check.

If the value is greater than zero, HTML files will be regenerated.

If the value is greater than one, images and HTML files will be regenerated.

=item *

B<verbose>

Boolean.

=back

=cut

sub create {
  my $pkg = shift;
  my $args = shift;

  #

  %IPTC::iptc  = ();
  %IPTC::views = ();

  %EXIF::exif  = ();
  %EXIF::views = ();

  $source    = undef;
  $dest      = undef;

  $cur_source = undef;
  $cur_dest   = undef;

  $url       = undef;
  $static    = undef;

  $scales    = {};
  $scaleif   = {};

  $views     = [];
  $iptc      = [];
  $exif      = [];
  $conf      = undef;
  $maxdepth  = undef;

  $styles    = {index=>[],image=>[]};
  $filters   = {index=>[],image=>[]};
  $images    = {};

  $encoding  = undef;
  $lang      = undef;
  $verbose   = 0;
  $force     = 0;

  #

  if ($args->{conf}) {
    return &read_conf($conf);
  }

  #

  if ($args->{directory}) {
    $source = $args->{'directory'};
    $dest   = $args->{'directory'};
  }

  $source ||= $args->{source};

  if (! -d $source) {
    carp "Source ($source) is not a directory\n";
    return undef;
  }

  $dest ||= $args->{'destination'} || $source;

  #

  if (ref($args->{scales}) ne "ARRAY") {
    carp "Scales must be passes as an array reference of array references.\n";
    return 0;
  }

  #

  foreach ("iptc","exif") {
    if ((exists($args->{$_})) && (ref($args->{$_}) ne "ARRAY")) {
      carp "$_ must be passed as an array reference. Ignoring.\n";
    }
  }

  #

  foreach (@{$args->{scales}}) {
    if (ref($_) ne "ARRAY") {
      carp "Arguments for 'scales' must be passed as an array ref of array refs. Ignoring\n";
      next;
    }

    unless ($_->[0] =~ /^(thumb|default)$/) {
      push @{$views},$_->[0];
    }

    if ($_->[1]) { 
      $scales->{$_->[0]} = $_->[1];
    }
  }

  #

  if ($args->{scaleif}) {
    if (ref($args->{scaleif}) eq "HASH") {
      map { 
	$scaleif->{$_} = $args->{scaleif}->{$_} if (defined($args->{scaleif}->{$_})); 
      } qw (x y);

    } else {
      carp "Argument 'scaleif' must be passed as a hash reference. Ignoring.\n";
    }
  }

  #

  if ($args->{set_index_images}) {
    if (ref($args->{set_index_images}) eq "HASH") {

      if (exists($args->{set_index_images}->{default})) {
	$images->{default} = 1;
      }

      else {
	foreach ("image","file","directory") {
	  next unless (exists $args->{set_index_images}->{$_});

	  if (ref($args->{set_index_images}->{$_}) =~ /^(HASH|CODE)$/) {
	    $images->{$_} = $args->{set_index_images}->{$_};
	  }

	  else { 
	    carp "The $_ field must be passed as a hash ref or a code ref. Ignoring.\n"; 
	  }
	}
      }
    }

    else { 
      carp "Argument 'set_index_images' must be passed as hash reference. Ignoring.\n"; 
    }
  }

  #

  if ($args->{set_styles}) {
    if (ref($args->{set_styles}) eq "HASH") {

      foreach my $type ("image","index") {
	next if (! exists($args->{set_styles}->{$type}));

	if (ref($args->{set_styles}->{$type}) ne "ARRAY") {
	  carp "Styles for $type must be passed as an array ref. Ignoring.\n";
	  next;
	}

	$styles->{$type} = $args->{set_styles}->{$type};
      }
    }

    else { 
      carp "The argument 'set_styles' must be passed as a hash reference. Ignoring.\n"; 
    }
  }

  #

  if ($args->{set_filters}) {
    if (ref($args->{set_filters}) eq "HASH") {

      foreach my $type ("image","index") {
	next if (! exists($args->{set_filters}->{$type}));

	if (ref($args->{set_filters}->{$type}) ne "ARRAY") {
	  carp "Filters for $type must be passed as an array ref. Ignoring.\n";
	  next;
	}

	$filters->{$type} = $args->{set_filters}->{$type};
      }
    }

    else { 
      carp "You argument 'set_filters' must be passed as a hash reference. Ignoring.\n"; 
    }
  }

  #

  if (! $scales->{'thumb'}) {
    carp;
    return 0;
  }

  #

  if (defined($args->{'maxdepth'})) {
    $maxdepth = $args->{'maxdepth'};
  }

  #

  $url       = $args->{'url'};
  $static    = $args->{'static'};

  $iptc      = $args->{'iptc'} if ($args->{'iptc'});
  $exif      = $args->{'exif'} if ($args->{'exif'});

  $encoding  = $args->{'set_encoding'} if ($args->{'set_encoding'});
  $lang      = $args->{'set_lang'} if ($args->{'set_lang'});

  $verbose   = $args->{verbose};
  $force     = $args->{force};

  #

  &visit($source);
  &make_index($source);

  #

  return 1;
}

sub read_conf {
  carp "I don't know how to read conf files yet.\n";
  return 0;
}

sub visit {
  my $path = shift;

  print STDERR "Visiting $path\n"
    if ($verbose);

  $visit ++;

  if ((defined($maxdepth)) && ($visit > $maxdepth)) {
    return;
  }

  my $dh = DirHandle->new($path);

   foreach ($dh->read()) {
    next if $_ =~ /^\./;
    my $loc = "$path/$_";

    if (-d $loc) {
      if (&make_index($loc)) {
	&visit($loc);
      }
    }
  }

  $visit --;
}

sub make_index {
  my $path = shift;

  print STDERR "[make-index] Making $path\n"
    if ($verbose);

  $cur_source = $path;
  $cur_dest   = __PACKAGE__->source_to_dest($path);

  #

  my $src = __PACKAGE__->source_to_dest($path);

  print STDERR "Making '$cur_dest'..."
    if ($verbose);

  if ((! -d $cur_dest) && (! mkpath($cur_dest,0,0755))) {
    print STDERR "Failed to make '$cur_dest', $!\n";
    return 0;
  }

  print STDERR "ok\n"
    if ($verbose);

  #

  my $html = $cur_dest."/index.html";
  my $tmp  = $html.".tmp";

  #

  my $output  = IO::File->new(">$tmp");

  if (! $output) {
    carp "Failed to open '$tmp' for writing, $!\n";
    return 0;
  }

  #

  my $writer  = XML::SAX::Writer->new(Output=>$output);

  my $filters = __PACKAGE__->filters("index");

  my $machine = Pipeline(
			 "LocalSAX_FloatingThumbs",
			 "LocalSAX_Breadcrumbs",
			 ((scalar(@{$filters})) ? @{$filters} : ()),
			 $writer);

  #

  # This is broken, I know.
  # There appears to be some degree of funkiness going
  # on with the inheritance chain for 2XHTML that is 
  # preventing the SAX::Machine from getting the output
  # of 2XHTML and passing it on to $writer. I think, anyway.

  my $xhtml = XML::Filter::XML_Directory_2XHTML->new(Handler=>$machine);

  $xhtml->debug(0);

  if ($encoding) {
    $xhtml->set_encoding($encoding);
  }

  if ($lang) {
    $xhtml->set_lang($lang);
  }

  $xhtml->exclude_root(1);
  $xhtml->exclude(
		  starting => ["\\."],
		  ending   => ["html","tmp","~"],
		  matching => ["^(.*)-(".join("|","thumb",@{$views}).")\.([^\.]+)\$"],
		 );

  #

  my $css = __PACKAGE__->styles("index");

  if (scalar(@$css)) {
    $xhtml->set_styles($css);
  }

  else {
    $xhtml->set_style(\qq(
body {
  background-color: #ffffff;
  margin:0;
}

.breadcrumbs {
 display:block;
  background-color: #f5f5dc;
  padding:5px;
  margin-bottom:5px;
  border-bottom: solid thin;
}

.breadcrumbs-spacer {

}

.directory { margin:10px;float:left; padding: 5px;}

.file      { margin:10px;float:left;padding: 5px;}

.spacer { clear:both; }

.thumbnail { display:block;width:100px;float:left;}

.file ul   { float:left;}

));
  }

  #

  if ($images->{default}) {
    $xhtml->set_images({
			image     => \&define_thumbnail,
			directory => {
				      src    => "/icons/dir.gif",
				      height => "20",
				      width  => "20",
				      alt    => "directory",
				     },
			file => {
				 src    => "/icons/unknown.gif",
				 height => "20",
				 width  => "20",
				 alt    => "unknown file",
				}
		       });
  }

  else {
    my $args = { image => ($images->{'image'} || \&define_thumbnail) };

    foreach ("file","directory") {
      if ($images->{$_}) { $args->{$_} = $images->{$_} };
    }

    $xhtml->set_images($args);
  }

  #

  $xhtml->set_callbacks({
			 linktext  => \&format_linktext,
			 link      => sub { 
			   return (-d $_[0]) ?
			     __PACKAGE__->format_link($_[0]) : 
			       __PACKAGE__->page_for_image([__PACKAGE__->format_link($_[0])]); 
			 },
			});

  #

  $xhtml->set_handlers({file=>LocalSAX_Scaled->new(Handler=>$writer)});

  #

  my $directory = XML::Directory::SAX->new(Handler=>$xhtml);

  $directory->set_maxdepth(0);
  $directory->set_details(2);
  $directory->order_by("a");

  $directory->parse_dir($path);

  #

  $output->close();
  move $tmp,$html;

  #

  &make_slides($html);
  return 1;
}

sub make_slides {
  my $index = shift;

  if (! scalar(@{&LocalSAX_Scaled::files()})) {
    return 1;
  }

  foreach my $img (@{&LocalSAX_Scaled::files()}) {

    # This is a bug, not a feature
    next if ($img =~ /^(.*)\.html$/);

    print STDERR "[make-slide] image is '$img'\n"
      if ($verbose);

    my $sid = "ID".&md5_hex("/".&basename($img));

    foreach my $scale ("",@{$views}) {

      my $html = __PACKAGE__->source_to_dest(__PACKAGE__->page_for_image([$img,$scale]));

      #

      if (! $force) {
	(my $source = $img) =~ s/^(.*)-($scale)\.([^\.]+)$/$1\.$3/;

	unless ((stat($source))[9] > (stat($html))[9]) {
	  next;
	}
      }

      #

      my $output = IO::File->new(">$html");
      my $writer = XML::SAX::Writer->new(Output=>$output);

      my $xsl = MyXSLT->new();
      $xsl->set_stylesheet_string(STYLESHEET->data());

      # This is really what I'd like to do but
      # I can't get it to work :-(
      # open(STYLESHEET,"<&=STYLESHEET::DATA");
      # $xsl->set_stylesheet_fh(\*STYLESHEET);

      my $do_scale = __PACKAGE__->do_scale($img,$scales->{default});

      $xsl->set_stylesheet_parameters(
				      id      => $sid,
				      doscale => $do_scale,
				      scale   => $scale,
				      scales  => ($do_scale) ? join(",",@{&views()}) : "",
				      static  => ($static) ? (scalar(keys %$scales) > 1) ? 2 : $static : 0,
				     );

      my $filters = __PACKAGE__->filters("image");

      my $machine = Pipeline(
			     $xsl,
			     "LocalSAX_Image",
			     "LocalSAX_Breadcrumbs",
			     ((scalar(@{$filters})) ? @{$filters} : ()),
			     $writer,
			    );

      print STDERR "[make-slide] Making $html..."
	if ($verbose);

      eval { $machine->parse_uri($index); };

      if ($@) {
	carp "Ack! Failed to parse $index, $@\n";

	$output->close();
	next;
      }

      $output->close();

      print STDERR "OK\n"
	if ($verbose);
    }
  }

  return 1;
}

sub format_link {
  my $pkg  = shift;

  (my $link = $_[0]) =~ s/$source/$url/;
  return $link;
}

sub unformat_link {
  my $pkg = shift;

  (my $path = $_[0]) =~ s/$url/$source/;
  return $path;
}

sub page_for_image {
  my $pkg   = shift;

  my $suffix = ($_[0]->[1]) ? "-".$_[0]->[1].".html" : ".html";
  (my $output = $_[0]->[0]) =~ s/(.*)\.([^\.]+)$/$1$suffix/;

  return $output;
}

sub source_to_dest {
  my $pkg = shift;
  $_[0] =~ /^($source)(\/(.*))?$/;
  return $dest.$2;
}

sub define_thumbnail {
  my $path = shift;

  my ($x,$y);

  ($x,$y) = imgsize($path);
  ($x,$y) = Image::Shoehorn->scaled_dimensions([$x,$y,undef,50]);

  my $title = &basename($path);

  if (my $iptc = IPTC->get($path)) {
    $title = $iptc->Attribute("headline") || $iptc->Attribute("caption/abstract") || $title;
  }

  my $src = __PACKAGE__->format_link($path);

  if ($static) {
    $src =~ s/^(.*)\.([^\.]+)$/$1-thumb\.$2/;
  } else {
    $src .= "?scale=thumb";
  }

  return {
	  src    => $src,
	  height => $y,
	  width  => $x,
	  alt    => $title,
	 };
}

sub format_linktext {

  if (-d $_[0]) {
    return $_[1];
  }

  if (XML::Filter::XML_Directory_Pruner->mtype($_[0]) ne "image") {
    return $_[1];
  }

  if (my $iptc = IPTC->get($_[0])) {
    return $iptc->Attribute("headline");
  }

  return $_[1];
}

sub do_scale {
  my $pkg = shift;
  my $uri = shift;
  my $def = shift;

  if (! keys %$scaleif) {
    return 1;
  }

  my ($x,$y) = Image::Size::imgsize($uri);

  if ($def) {
    ($x,$y) = Image::Shoehorn->dimensions_for_scale($x,$y,$def);
  }

  if (defined($scaleif->{'x'}) && defined($scaleif->{'y'})) {
    if (($x <= $scaleif->{'x'}) && ($y <= $scaleif->{'y'})) {
      return 0;
    }
  }
  
  elsif (defined($scaleif->{'x'})) {
    if ($x <= $scaleif->{'x'}) {
      return 0;
    }
  }
  
  elsif (defined($scaleif->{'y'})) {
    if ($y <= $scaleif->{'y'}) {
      return 0;
    }
  }
  
  else { 
    return 1;
  }

  return 1;
}

sub source {
  return $source;
}

sub destination {
  return $dest;
}

sub url {
  return $url;
}

sub cur_source {
  return $cur_source;
}

sub cur_destination {
  return $cur_dest;
}

sub scales {
  return $scales;
}

sub views {
  return $views;
}

sub iptc {
    return $iptc;
}

sub exif {
    return $exif;
}

sub styles {
  return $styles->{$_[1]};
}

sub filters {
  return $filters->{$_[1]};
}

sub encoding {
  return $encoding;
}

sub lang {
  return $lang;
}

sub force {
  return $force;
}

sub verbose {
  return $verbose;
}

sub scale_if { 
  return $scaleif;
}

=head1 NAMING CONVENTIONS

Let's say you've got an image named :

 20020603-my-new-toy.jpg

You've defined two "views" to be generated : small and medium. The following files will be created :

 20020603-my-new-toy.html
 20020603-my-new-toy-thumb.jpg **
 20020603-my-new-toy-small.jpg *
 20020603-my-new-toy-small.html
 20020603-my-new-toy-medium.jpg *
 20020603-my-new-toy-medium.html

 *  If you are rendering scaled images on the fly, with I<Apache::Image::Shoehorn>, 
    these files not be created until such a time as they are actually viewed

 ** Thumbnails are always generated, regardless of the I<static> flag. As mentioned 
    earlier, this is a feature. If you have a directory with many images, you will peg
    your web server the first time you have to render all those images for the index
    listing.

The package uses I<XML::Filter::XML_Directory_2XHTML> which, a few steps up the inheritance tree, uses I<XML::Filter::XML_Directory_Pruner> to exclude certain specific files from the directory (index) listing. The exact rule set currently used it :

  $xhtml->exclude(
		  starting => ["\\."],
		  ending   => ["html","tmp","~"],
		  # e.g. ending with "-thumb.jpg","-small.jpg" or "-medium.jpg"
		  matching => ["^(.*)-(".join("|","thumb",@{$views}).")\.([^\.]+)\$"],
		 );

The plan is to, eventually, teach I<XML::Filter::XML_Directory_Pruner> to include and exclude widgets based on media type, at which point we could simply do :

 $xhtml->include( media => "image" );

But until then, it is recommended that you make sure your source images don't match the "matching" pattern describe above. Or if you just think I'm an idiot and have a better rule-set, send my a note and I'll probably include it.

=head1 CSS

The following CSS classes are defined for the HTML generated by the package. 

They are provided as a reference in case you want to specify your own CSS stylesheet.

=head2 "index" page

 body {
      background-color: #ffffff;
      margin:0;
 }

 .breadcrumbs {
               display:block;
               background-color: #f5f5dc;
               padding:5px;
               margin-bottom:5px;
               border-bottom: solid thin;
  }

 .breadcrumbs-spacer {}

 .directory { margin-bottom:5px;clear:left; padding: 5px;}

 .file      { margin-bottom:5px;clear:left;padding: 5px;}

 .thumbnail { display:block;width:100px;float:left;}

 .file ul   { float:left;}

=head2 "image" page


 body {
        background-color: #ffffff;
        margin:0;
      }

 .breadcrumbs {
   display:block;
   background-color: #f5f5dc;
   padding:5px;
   margin-bottom:5px;
   border-bottom: solid thin;
 }

 .breadcrumbs-spacer {}

 .directory {
   padding: 5px;
 }

 .file {
   padding: 5px;
 }

 .menu {
        margin-bottom:5px;
        padding:5px;
 }

 .menu-link-previous {
		padding-right : 10px;
 }

 .menu-link-previous img {
		margin-right:15px;
 }

 .menu-link-index {
		 font-weight:600;
 }

 .menu-link-next {
		padding-left : 10px;
 }

 .menu-link-next img {
		margin-left:15px;
 }

 .content {
        padding-top:20px;
      }

 .image { 
        position:absolute;
        top:auto;
        right:auto;
        left:170px;
        bottom:auto;
 }

 .meta { 
        min-width:150px;
        max-width:150px;
        margin:5px;
 }  

 .links {
        border: solid thin;
        margin-bottom: 5px;
 }

 .links span {
        display:block;
	padding:3px;
 }

 .iptc { 
        background-color : #fffff0;
        border-top: solid thin; 
        border-left: solid thin;
        border-right: solid thin;
        margin-bottom : 5px;
      }

 .iptc span { 
        display:block; 
        padding:3px;
        border-bottom:solid thin;
 }

 .iptc-field { 
        background-color : #f5f5dc;
        color:#a52a2a;
        border-bottom:solid thin #000;
        }

 .exif { 
        background-color : #f5f5dc;
        border-top: solid thin; 
        border-left: solid thin; 
        border-right: solid thin; 
        margin-bottom : 5px; 
        }

 .exif span { 
        display:block; 
        padding:3px;
        border-bottom:solid thin;
 }

 .exif-field { 
        color:#a52a2a;
        background-color:#cccc99;
        border-bottom:solid thin #000;
        }


=head1 VERSION

0.22

=head1 AUTHOR

Aaron Straup Cope 

=head1 DATE

September 02, 2002

=head1 TO DO

=over 4

=item *

Teach I<Apache::Image::Shoehorn> how to deal with 'default' images, as described above.

=item *

Add an "import_styles" method, to take advantage of @import hack for hiding CSS from old browsers. Might just add {import=>1} option to "set_styles".

=item *

Figure out why I keep getting errors when I try passing STYLESHEET::DATA (or copies of it) to the XSLT munger.

=item *

Set/get config options using closures.

=item *

Add hooks to read a conf file - this allow involves hacking I<Apache::Image::Shoehorn> so that it can also read the same conf file

=item *

Add hooks for generating slides from a "virtual" directory; specifically a list of disparate files.

=item *

Add hooks for supporting I<XML::Filter::Sort>

=item *

Consider I<interactive> option that would prompt user for IPTC data as files are being processed.

=item *

Design and implement nightmarish XPath to generate XSLT stylesheet from a user-defined template. I promised Karl I would do this for v 0.3 but we'll see...

=back

=head1 BACKGROUND

http://aaronland.net/weblog/archive/3940

http://aaronland.net/weblog/archive/4474

http://www.la-grange.net/2002/07/22.html

=head1 EXAMPLE

http://perl.aaronland.info/image/shoehorn/gallery/www/example/index.html

=head1 REQUIREMENTS

I<XML::Filter::XML_Directory_2XHTML>

I<XML::Filter::XSLT>

I<XML::SAX::Machines>

I<XML::SAX::Writer>

I<Image::Shoehorn>

I<Image::IPTCInfo>

I<Image::Info>

I<Digest::MD5>

=head1 BUGS

Undoubtedly. So far, it works for me.

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

package MyXSLT;
use base qw (XML::Filter::XSLT::LibXSLT);

sub set_stylesheet_parameters {
    my $self   = shift;
    my %params = @_;

    if (keys %params) {
	map { push @{$self->{'__params'}},&XML::LibXSLT::xpath_to_string($_=>$params{$_}) } keys %params;
    }
}

sub set_stylesheet_string {
  my $self = shift;
  $self->{Source}{String} = $_[0];
}

# No point until I figure out how
# to pass the filehandles :-(

#sub set_stylesheet_fh {
#  my $self = shift;
#  $self->{Source}{ByteStream} = $_[0];
#}

sub end_document {
    my $self = shift;

    my $dom = $self->XML::LibXML::SAX::Builder::end_document(@_);

    # This is so fucking stupid, but there are bugs
    # somewhere in all the magic that handles XHTML
    # and XSLT so...

    my $parser = XML::LibXML->new;
    $dom = $parser->parse_html_string($dom->toString());

    my $xslt       = XML::LibXSLT->new;
    my $stylesheet = $xslt->parse_stylesheet($self->{StylesheetDOM});

    my $results = $stylesheet->transform($dom,((ref($self->{'__params'}) eq "ARRAY") ? @{$self->{'__params'}} : ()));

    my $parser = XML::LibXML::SAX::Parser->new(%$self);
    $parser->generate($results);
}

package LocalSAX_Image;
use base qw (XML::SAX::Base);

use File::Basename;
use Image::Size qw (imgsize);
use Image::Info;

my $possible_views;

use constant DTD_HTML_ROOT     => "html";
use constant DTD_HTML_PUBLICID => "-//W3C//DTD XHTML 1.0 Strict//EN";
use constant DTD_HTML_SYSTEMID => "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

sub xml_decl {
  my $self = shift;
  $self->SUPER::xml_decl({
			  Version  => "1.0",
			  Encoding => (Image::Shoehorn::Gallery->encoding() || "UTF-8")
			 });

  # If you're wondering what is going on here,
  # see the note in the STYLESHEET package.

  $self->SUPER::start_dtd({Name=>DTD_HTML_ROOT,
			   PublicId=>DTD_HTML_PUBLICID,
			   SystemId=>DTD_HTML_SYSTEMID});
  $self->SUPER::end_dtd();
}

sub start_document {
  my $self = shift;

  $self->{'__styles'} = scalar(@{Image::Shoehorn::Gallery->styles("image")});
  $possible_views = join("|",@{Image::Shoehorn::Gallery->views()});

  $self->SUPER::start_document(@_);
}

sub start_element {
    my $self = shift;
    my $data = shift;

    $self->{'__last'} = $data->{Name};

    #

    if (($data->{Name} eq "html") && (Image::Shoehorn::Gallery->lang())) {

      $self->SUPER::start_prefix_mapping({Prefix=>"",NamespaceURI=>"http://www.w3.org/1999/xhtml"});

      $self->SUPER::start_element({Name=>"html",Attributes=>{
							     "{}lang" => {Name         => "lang",
									  Value        => Image::Shoehorn::Gallery->lang(),
									  Prefix       => "",
									  LocalName    => "lang",
									  NamespaceURI => "",
									 },
							     "{}xml:lang" => {
									      Name => "xml:lang",
									      Value => Image::Shoehorn::Gallery->lang(),
									      Prefix       => "xml",
									      LocalName    => "xml:lang",
									      NamespaceURI => "http://www.w3.org/1999/xhtml",
									    },
							    }});
      return 1;
    }

    if (($data->{Name} eq "style") && ($self->{'__styles'})){

      foreach my $style (@{Image::Shoehorn::Gallery->styles("image")}) {
	$self->SUPER::start_element({Name=>"link",Attributes=>{
							       "{}href"  => {Name=>"href",
									     Value=>$style->{'href'},
									     Prefix=>"",
									     LocalName=>"href",
									     NameSpaceURI=>""},
							       "{}type"  => {Name=>"type",
									     Value=>"text/css",
									     LocalName=>"type",
									     NameSpaceURI=>""},
							       "{}rel"   => {Name=>"rel",
									     Value=>($style->{'rel'} || "stylesheet"),
									     Prefix=>"",
									     LocalName=>"rel",
									     NameSpaceURI=>""},
							       "{}media" => {Name=>"media",
									     Value=>($style->{'media'} || "all"),
									     Prefix=>"",
									     LocalName=>"media",
									     NameSpaceURI=>""},
							       "{}title" => {Name=>"title",
									     Value=>($style->{'title'} || ""),
									     Prefix=>"",
									     LocalName=>"title",
									     NameSpaceURI=>""},
							      }});
	$self->SUPER::end_element({Name=>"link"});
      }

      return 1;
    }

    #

    if (($data->{Name} eq "img") && 
	($data->{Attributes}->{'{}id'}->{'Value'} eq "main")) {

      my $src = Image::Shoehorn::Gallery->unformat_link($data->{Attributes}->{'{}src'}->{'Value'});
      $src = Image::Shoehorn::Gallery->source_to_dest($src);

      my ($x,$y);

      #

      if ($src =~ /^(.*)\?scale=(.*)$/) {

	# This matters because we also need
	# to look up IPTC and EXIF data with
	# $src.

	$src = $1;

	# Call to imgsize needs to be memoized
	($x,$y) = Image::Shoehorn->dimensions_for_scale((imgsize($src))[0,1],Image::Shoehorn::Gallery->scales()->{$2});
      }

      else {
	($x,$y) = imgsize($src);
      }

      #

      my $alt = &basename($data->{Attributes}->{'{}src'}->{'Value'});
      if (my $iptc = IPTC->get($src)) {	$alt = $iptc->Attribute("caption/abstract") || $iptc->Attribute("headline") || $alt; }

      $data->{'Attributes'}->{'{}height'} = {
					     Name         => "height",
					     LocalName    => "height",
					     Prefix       => "",
					     NamespaceURI => "",
					     Value        => $y,
					    };
      $data->{'Attributes'}->{'{}width'} = {
					     Name         => "width",
					     LocalName    => "width",
					     Prefix       => "",
					     NamespaceURI => "",
					     Value        => $x,
					    };
      $data->{'Attributes'}->{'{}alt'} = {
					     Name         => "alt",
					     LocalName    => "alt",
					     Prefix       => "",
					     NamespaceURI => "",
					     Value        => $alt,
					    };

      $self->SUPER::start_element($data);

      $self->{'__src'} = $src;
      return 1;
    }

    if (($data->{Name} eq "div") && 
	($data->{Attributes}->{'{}class'}->{'Value'} eq "links")) {
      $self->{'__meta'} = 1;
    }

    $self->SUPER::start_element($data);
    return 1;
}

sub end_element {
  my $self = shift;
  my $data = shift;
  
  if (($data->{Name} eq "style") && ($self->{'__styles'})){
    return;
  }

  $self->SUPER::end_element($data);

  if ($self->{Name} eq "html") {
    $self->SUPER::end_prefix_mapping({Prefix=>""});
  }

  if (($data->{Name} eq "div") && (exists($self->{'__meta'}))) {
    $self->add_metadata();
    delete $self->{'__meta'};
  }

  return 1;
}

sub characters {
  my $self = shift;
  my $data = shift;

  if (($self->{'__last'} eq "style") && ($self->{'__styles'})){
    return;
  }

  $self->SUPER::characters($data);
}

sub add_metadata {
  my $self = shift;

  my $iptc_props = Image::Shoehorn::Gallery->iptc();
  my $exif_props = Image::Shoehorn::Gallery->exif();
  
  $self->{'__src'} =~ s/^(.*)-($possible_views)\.([^\.]+)$/$1\.$3/;
  
  if (scalar(@$iptc_props) > 0) {
    my $iptc = IPTC->get($self->{'__src'});

    if (($iptc) && (IPTC->test($self->{'__src'}))) {
      $self->SUPER::start_element({Name=>"div",Attributes => {
							      "{}class" => {
									    "Name"         => "class",
									    "LocalName"    => "class",
									    "Prefix"       => "",
									    "NamespaceURI" => "",
									    "Value"        => "iptc",
									   },
							     }});
      
      foreach my $prop (@{$iptc_props}) {
	$self->SUPER::start_element({Name=>"span",Attributes =>{
								"{}class" => {
									      "Name"         => "class",
									      "LocalName"    => "class",
									      "Prefix"       => "",
									      "NamespaceURI" => "",
									      "Value"        => "iptc-field",
									     },
							       }});
	$self->SUPER::characters({Data=>$prop});
	$self->SUPER::end_element({Name=>"span"});
	
	$self->SUPER::start_element({Name=>"span",Attributes =>{
								"{}class" => {
									      "Name"         => "class",
									      "LocalName"    => "class",
									      "Prefix"       => "",
									      "NamespaceURI" => "",
									      "Value"        => $prop,
									     },
							       }});
	$self->SUPER::characters({Data=>($iptc->Attribute($prop) || "-")});
	$self->SUPER::end_element({Name=>"span"});
      }
      
      $self->SUPER::end_element({Name=>"div"});
    }
  }
  
  #
  
  if (scalar(@$exif_props) > 0) {
    my $exif = EXIF->get($self->{'__src'});
    if (($exif) && (EXIF->test($self->{'__src'}))) {
      $self->SUPER::start_element({Name=>"div",Attributes => {
							      "{}class" => {
									    "Name"         => "class",
									    "LocalName"    => "class",
									    "Prefix"       => "",
									    "NamespaceURI" => "",
									    "Value"        => "exif",
									   },
							     }});
      
      foreach my $prop (@{$exif_props}) {
	$self->SUPER::start_element({Name=>"span",Attributes =>{
								"{}class" => {
									      "Name"         => "class",
									      "LocalName"    => "class",
									      "Prefix"       => "",
									      "NamespaceURI" => "",
									      "Value"        => "exif-field",
									     },
							       }});
	$self->SUPER::characters({Data=>$prop});
	$self->SUPER::end_element({Name=>"span"});
	
	$self->SUPER::start_element({Name=>"span",Attributes =>{
								"{}class" => {
									      "Name"         => "class",
									      "LocalName"    => "class",
									      "Prefix"       => "",
									      "NamespaceURI" => "",
									      "Value"        => $prop,
									     },
							       }});
	
	my $exif_value = $exif->{$prop} || "-";
	if (ref($exif_value) eq "ARRAY") {
	  $exif_value = join(",",@$exif_value);
	}
	
	$self->SUPER::characters({Data=>$exif_value});
	$self->SUPER::end_element({Name=>"span"});
      }
      
      $self->SUPER::end_element({Name=>"div"});
    }
  }
  
  delete $self->{'__src'};
  return 1;
}


package LocalSAX_FloatingThumbs;
use base qw (XML::SAX::Base);

sub start_element {
  my $self = shift;
  my $data = shift;

  $self->SUPER::start_element($data);

  if ($data->{Name} eq "body") {
    $self->_spacer();
  }
}

sub end_element {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} eq "body") {
    $self->_spacer();
  }

  $self->SUPER::end_element($data);
}

sub _spacer {
  my $self = shift;
  $self->SUPER::start_element({Name=>"div",Attributes=>{
							"{}class" => {
								      Name         => "class",
								      LocalName    => "class",
								      Prefix       => "",
								      NamespaceURI => "",
								      Value        => "spacer",
								     }
						       }});
  $self->SUPER::characters({Data=>" "});
  $self->SUPER::end_element({Name=>"div"});
  return 1;
}

package LocalSAX_Breadcrumbs;
use base qw (XML::SAX::Base);

use File::Basename;

sub start_element {
  my $self = shift;
  my $data = shift;

  $self->SUPER::start_element($data);

  if ($data->{Name} ne "body") {
    return 1;
  }

  my $cur = Image::Shoehorn::Gallery->cur_destination();

  if ($cur eq Image::Shoehorn::Gallery->destination()) {
    return 1;
  }

  $cur = &dirname($cur);

  my $dest = Image::Shoehorn::Gallery->destination();

  $cur =~ s/^($dest)(.*)/$2/;

  my ($parts,$count) = Breadcrumbs->get($cur);

  $self->SUPER::start_element({Name=>"span",Attributes=>{
							"{}class" => {
								      Name         => "class",
								      LocalName    => "class",
								      Prefix       => "",
								      NamespaceURI => "",
								      Value        => "breadcrumbs",
								     }
						       }});
  
  $self->SUPER::characters({Data=>" "});

  #

  for (my $i = 0; $i < $count; $i++) {
    $self->SUPER::start_element({Name=>"a",Attributes=>{
							"{}href" => {
								     Name=>"href",
								     LocalName=>"href",
								     Prefix=>"",
								     NamespaceURI=>"",
								     Value=>Image::Shoehorn::Gallery->url().join("/",@{$parts}[0..$i]),
								    },
						       }});
    $self->SUPER::characters({Data=>($parts->[$i] || "top")});
    $self->SUPER::end_element({Name=>"a"});
    
    unless ($i +1 == $count) {
      $self->SUPER::start_element({Name=>"span",Attributes=>{
							    "{}class" => {
									  Name         => "class",
									  LocalName    => "class",
									  Prefix       => "",
									  NamespaceURI => "",
									  Value        => "breadcrumbs-spacer",
								     },
							     }});
      
      $self->SUPER::characters({Data=>" || "});
      $self->SUPER::end_element({Name=>"span"});
    }

    # print STDERR "$i [$count] $parts->[$i] ... ".Image::Shoehorn::Gallery->url().join("/",@{$parts}[0..$i])."\n";
  }

  $self->SUPER::end_element({Name=>"span"});
  return 1;
}

package LocalSAX_Scaled;
use base qw (XML::SAX::Base);

use Image::Shoehorn;
use Image::Size qw (imgsize);

my $files = [];

sub files { return $files; }

sub new {
  my $pkg = shift;
  my $self = {};

  bless $self,$pkg;

  $files = [];
  return $self->SUPER::new(@_);
}

sub parse_uri {
  my $self = shift;
  my $uri  = shift;

  if (! -f $uri) {
    return;
  }

  push @$files,$uri;

  print STDERR "[parse-uri] Adding $uri\n"
    if (Image::Shoehorn::Gallery->verbose());

  #

  my $scales  = Image::Shoehorn::Gallery->scales();
  my $default = $scales->{default};

  my $scale   = Image::Shoehorn::Gallery->do_scale($uri,$default);

  #

  my %to_scale = ();

  foreach my $sname (keys %{$scales}) {

    # unless ($sname =~ /^(thumb)$/) {
    unless ($sname  eq "thumb") {
      if (! $scale) {
	next;
      }
    }

    if (! $scales->{$sname}) {
      next;
    }

    my $sfile = join("/",Image::Shoehorn::Gallery->cur_destination(),Image::Shoehorn->scaled_name([$uri,$sname]));

    
    if ($sfile =~ /^(.*)(-default)(\.[^\.]+)$/) {
      $sfile = $1.$3;
    }
    
#    print STDERR "COMPARING '$uri' w/ '$sfile' \n";
#    print STDERR (stat($uri))[9]." ... ".(stat($sfile))[9]."\n";

    if (Image::Shoehorn::Gallery->force() >= 2) {
      $to_scale{$sname} = $scales->{$sname};
    }

    elsif ((stat($uri))[9] > (stat($sfile))[9]) {
      $to_scale{$sname} = $scales->{$sname};
    }

    else {}

  }

  #

  if (((! $scale) && (! $default)) ||
      (Image::Shoehorn::Gallery->destination() ne Image::Shoehorn::Gallery->source())) {

    my $copy = Image::Shoehorn::Gallery->source_to_dest($uri);

    unless ($copy eq $uri) {
      require File::Copy;
      &File::Copy::copy ($uri,$copy);
    }
  }

  #

  if (keys %to_scale) {
    if ($default) {

      # print STDERR "ORIGINAL ".join(",",(imgsize($uri))[0,1])."\n";
      my ($dx,$dy) = Image::Shoehorn->dimensions_for_scale((imgsize($uri))[0,1],$default);

      # print STDERR "$uri $dx, $dy\n";
      foreach (keys %to_scale) {
	next if ($_ =~ /^(thumb|default)$/);

	my ($nx,$ny) = Image::Shoehorn->dimensions_for_scale($dx,$dy,$to_scale{$_});
	# print STDERR "N $nx, $ny\n";
	$to_scale{$_} = join("x",$nx,$ny);
      }

      # use Data::Dumper;
      # die &Dumper(\%to_scale);
    }

    #

    # We do this because otherwise the image
    # scaling widgets start gobbling up all the 
    # available swap space and eventually the OS
    # kills the program :-(

    my $cmd = "/usr/local/bin/perl -e \'use Image::Shoehorn;";

    $cmd   .= "my \$image = Image::Shoehorn->new({";
    $cmd   .= "tmpdir  => \"".Image::Shoehorn::Gallery->cur_destination()."\",cleanup => sub {";

    # subroutine to rename 'default' :
    $cmd   .= "my \$imgs = shift; return unless \$imgs->{default};";
    $cmd   .= "(my \$new = \$imgs->{default}->{path}) =~ s/(.*)-default\\.([^\\.]+)\$/\$1\\.\$2/;";
    $cmd   .= "rename \$imgs->{default}->{path},\$new";
    $cmd   .= " || warn $!;";
    # end subroutine

    $cmd   .= "},}) ";
    $cmd   .= "|| die Image::Shoehorn->last_error();";
    $cmd   .= "print STDERR \"Scaling $uri...\"; ";
    $cmd   .= "\$image->import({";
    $cmd   .= "source => \"$uri\",";
    $cmd   .= "scale => {";
    map { $cmd .= "\"$_\" => \"$to_scale{$_}\","; } keys %to_scale;
    $cmd   .= "}}) || die Image::Shoehorn->last_error();";
    $cmd   .= "print STDERR \"OK\\n\";";
    $cmd   .= "'";

    print STDERR $cmd,"\n"
      if (Image::Shoehorn::Gallery->verbose() > 1);

    system($cmd);
  }

  #

  return unless ($scale);

  #

  $self->SUPER::start_element({Name=>"ul"});

  foreach my $scale (@{Image::Shoehorn::Gallery->views}) {

    my $path = Image::Shoehorn::Gallery->page_for_image([Image::Shoehorn::Gallery->format_link($uri),$scale]);

    $self->SUPER::start_element({Name=>"li"});
    $self->SUPER::start_element({Name=>"a",Attributes=>{
							'{}href' => {
								     Name         => "href",
								     LocalName    => "href",
								     Prefix       => "",
								     NamespaceURI => "",
								     Value        => $path,
								    },
						       }});
    $self->SUPER::characters({Data=>$scale});
    $self->SUPER::end_element({Name=>"a"});
    $self->SUPER::end_element({Name=>"li"});
  }

  $self->SUPER::end_element({Name=>"ul"});
  return;
}

package IPTC;
use Image::IPTCInfo;

my %iptc  = ();
my %views = ();

sub get {
  my $pkg  = shift;
  my $path = shift;

  if (exists $iptc{$path}) {
    return $iptc{$path};
  }

  $iptc{$path} = Image::IPTCInfo->new($path);

  if (! ref($iptc{$path})) {
    $iptc{$path} = undef;
  }

  return $iptc{$path};
}

sub test {
  my $pkg = shift;
  my $path = shift;

  if (exists($views{$path})) {
    return $views{$path};
  }

  if (! $iptc{$path}) {
    return 0;
  }

  foreach my $view (@{Image::Shoehorn::Gallery->iptc()}) {
    if ($iptc{$path}->Attribute($view)) {
      $views{$path} = 1;
      return 1;
    }
  }

  $views{$path} = 0;
  return 0;
}

package EXIF;
use Image::Info qw (image_info);

my %exif  = ();
my %views = ();

sub get {
  my $pkg  = shift;
  my $path = shift;

  if (exists $exif{$path}) {
    return $exif{$path};
  }

  $exif{$path} = image_info($path);

  if ($exif{'error'}) {
    $exif{$path} = undef;
  }

  return $exif{$path};
}

sub test {
  my $pkg  = shift;
  my $path = shift;

  if (exists($views{$path})) {
    return $views{$path};
  }

  foreach my $view (@{Image::Shoehorn::Gallery->exif()}) {
    if ($exif{$path}->{$view}) {
      $views{$path} = 1;
      return 1;
    }
  }

  $views{$path} = 0;
  return 0;
}

package Breadcrumbs;

my %crumbs = ();
my %count  = ();

sub get {
  my $pkg = shift;

  if (! $_[0]) {
    return ([],1);
  }

  if (exists $crumbs{$_[0]}) {
    return ($crumbs{$_[0]},$count{$_[0]});
  }

  @{$crumbs{$_[0]}} = split("/",$_[0]);
  $count{$_[0]}     = scalar(@{$crumbs{$_[0]}});

  return ($crumbs{$_[0]},$count{$_[0]});
}

package STYLESHEET;
my $data = undef;

sub data {
  if ($data) { return $data; }
  while (<DATA>) { $data .= $_;  }
  return $data;
}

return 1;

# NOTE : we are not setting the public and system doctypes here
# because they cause even more weirdness with XML::LibXML and it's
# seeming inability to deal with XHTML files. I really don't get
# what's going on so we play a little game and set them event the 
# xml_decl event in the LocalSAX_Image filter is called next. Gah!

# NOTE ALSO : that this is also where we happen to set the encoding

__DATA__
<?xml version="1.0" encoding='iso-8859-1'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version = "1.0" >

<xsl:output method = "xml" 
            indent = "yes" />

<xsl:param name = "id" />
<xsl:param name = "scales" />
<xsl:param name = "scale" />
<xsl:param name = "doscale" />
<xsl:param name = "static" />

<!-- ======================================================================
     ====================================================================== -->

 <xsl:variable name = "has_id">
  <xsl:choose>
   <xsl:when test = "/html/body/div[@id=$id]">1</xsl:when>
   <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

   <xsl:variable name = "image">
    <xsl:value-of select = "/html/body/div[@id=$id]/div[@class='thumbnail']/img/@src" />
   </xsl:variable>

    <xsl:variable name  = "prev">
     <xsl:value-of select = "/html/body/div[@id=$id]/preceding-sibling::*[1][name()='div']/a/@href" />
    </xsl:variable>

    <xsl:variable name  = "next">
     <xsl:value-of select = "/html/body/div[@id=$id]/following-sibling::*[1][name()='div']/a/@href" />
    </xsl:variable>

    <xsl:variable name = "last" select = "count(/html/body/div[@class='file' or @class = 'directory'])" />

    <xsl:variable name = "prev_title">
     <xsl:choose>
      <xsl:when test = "$prev != ''">
       <xsl:value-of select = "/html/body/div[@id=$id]/preceding-sibling::*[1][@class='file' or @class = 'directory']/a" />
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select = "/html/body/div[@class='file' or @class = 'directory'][$last]/a" />
      </xsl:otherwise>
     </xsl:choose>
    </xsl:variable>

      <xsl:variable name = "prev_href">
       <xsl:choose>
        <xsl:when test = "$prev != ''">
         <xsl:value-of select = "$prev" />
        </xsl:when>
        <xsl:otherwise>
         <xsl:value-of select = "/html/body/div[@class='file' or @class = 'directory'][$last]/a/@href" />
        </xsl:otherwise>
       </xsl:choose>
      </xsl:variable>

      <xsl:variable name = "prev_href_scaled">
       <xsl:choose>
        <xsl:when test = "substring-before($prev_href,'.html')">
         <xsl:value-of select = "substring-before($prev_href,'.html')" /><xsl:if test = "$scale != ''">-<xsl:value-of select = "$scale" /></xsl:if>.html
        </xsl:when>
        <xsl:otherwise>
         <xsl:value-of select = "$prev_href" />
        </xsl:otherwise>
       </xsl:choose>
     </xsl:variable>

     <xsl:variable name = "next_title">
      <xsl:choose>
       <xsl:when test = "$next != ''">
        <xsl:value-of select = "/html/body/div[@id=$id]/following-sibling::*[1][@class='file' or @class = 'directory']/a" />
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select = "/html/body/div[@class='file' or @class = 'directory'][1]/a" />
       </xsl:otherwise>
      </xsl:choose>
     </xsl:variable>

     <xsl:variable name = "next_href">
      <xsl:choose>
       <xsl:when test = "$next != ''">
        <xsl:value-of select = "$next" />
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select = "/html/body/div[@class = 'file' or @class = 'directory'][1]/a/@href" />
       </xsl:otherwise>
      </xsl:choose>
     </xsl:variable>

  <xsl:variable name = "next_href_scaled">
   <xsl:choose>
    <xsl:when test = "substring-before($next_href,'.html')">
     <xsl:value-of select = "substring-before($next_href,'.html')" /><xsl:if test = "$scale != ''">-<xsl:value-of select = "$scale" /></xsl:if>.html
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select = "$next_href" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template match="/">
  <html>
   <head>
     <title>
      <xsl:call-template name = "PageTitle" />
      <xsl:if test = "number($has_id) > 0"> || <xsl:call-template name = "ImageTitle" /></xsl:if>
    </title>
    <style type = "text/css">
      <![CDATA[ <!--
.foo {}

body {
  background-color: #ffffff;
  margin:0;
}

.breadcrumbs {
 display:block;
  background-color: #f5f5dc;
  padding:5px;
  margin-bottom:5px;
  border-bottom: solid thin;
}

.breadcrumbs-space {
  background-color: orange;
}

.directory {
 padding: 5px;
}

.file {
 padding: 5px;
}

.menu {
        margin-bottom:5px;
        padding:5px;
}

.menu-link-previous {
		padding-right : 10px;
}

.menu-link-previous img {
		margin-right:15px;
}

.menu-link-index {
		 font-weight:600;
}

.menu-link-next {
		padding-left : 10px;
}

.menu-link-next img {
		margin-left:15px;
}

.content {
        padding-top:20px;
      }

.image { 
        position:absolute;
        top:auto;
        right:auto;
        left:170px;
        bottom:auto;
}

.meta { 
        min-width:150px;
        max-width:150px;
        margin:5px;
}  
     
.links {
        border: solid thin;
        margin-bottom: 5px;
}

.links span {
        display:block;
	padding:3px;
}

.iptc { 
        background-color : #fffff0;
        border-top: solid thin; 
        border-left: solid thin;
        border-right: solid thin;
        margin-bottom : 5px;
      }

.iptc span { 
        display:block; 
        padding:3px;
        border-bottom:solid thin;
}

.iptc-field { 
        background-color : #f5f5dc;
        color:#a52a2a;
        border-bottom:solid thin #000;
        }

.exif { 
        background-color : #f5f5dc;
        border-top: solid thin; 
        border-left: solid thin; 
        border-right: solid thin; 
        margin-bottom : 5px; 
        }

.exif span { 
        display:block; 
        padding:3px;
        border-bottom:solid thin;
}

.exif-field { 
        color:#a52a2a;
        background-color:#cccc99;
        border-bottom:solid thin #000;
        }


      --> ]]>
    </style>
    <!-- start,top,next,prev -->
    <link>
     <xsl:attribute name = "rel">start</xsl:attribute>
     <xsl:attribute name = "title">
      <xsl:value-of select = "/html/body/div[@class='file' or 'directory'][1]/a" />
      <!--<xsl:value-of select = "/html/body/div[@class='file' or 'directory'][position()=1]/a" />-->
     </xsl:attribute>
     <xsl:attribute name = "href">
      <xsl:value-of select = "/html/body/div[@class='file' or 'directory'][1]/a/@href" />
      <!--<xsl:value-of select = "/html/body/div[@class='file' or 'directory'][position()=1]/a/@href" />-->
     </xsl:attribute>
    </link>
    <link>
     <xsl:attribute name = "rel">contents</xsl:attribute>
     <xsl:attribute name = "title">Index</xsl:attribute>
     <!-- This is a bit lazy and opens up the possibility
          for mistakes so it should be revisited. -->
     <xsl:attribute name = "href">./index.html</xsl:attribute>
    </link>
    <link>
     <xsl:attribute name = "rel">prev</xsl:attribute>
     <xsl:attribute name = "title"><xsl:value-of select = "$prev_title" /></xsl:attribute>
     <xsl:attribute name = "href"><xsl:value-of select = "$prev_href_scaled" /></xsl:attribute>  
    </link>
    <link>
     <xsl:attribute name = "rel">next</xsl:attribute>
     <xsl:attribute name = "title"><xsl:value-of select = "$next_title" /></xsl:attribute>
     <xsl:attribute name = "href"><xsl:value-of select = "$next_href_scaled" /></xsl:attribute>  
    </link>
   </head>
   <body>
    <xsl:call-template name = "Body" />
   </body>
  </html>
 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "Body">
  <div>
   <xsl:attribute name = "class">menu</xsl:attribute>
   <xsl:call-template name = "Menu" />
  </div>

  <div>
   <xsl:attribute name = "class">content</xsl:attribute>
   <xsl:call-template name = "Image" />
  </div>

 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "Image">

   <div>
    <xsl:attribute name = "class">image</xsl:attribute>

    <!-- If you're getting all freaked out because there are no
         height or width attributes, don't worry. The SAX handler 
         will deal with them. -->

    <img>
     <xsl:attribute name = "id">main</xsl:attribute>
     <xsl:attribute name = "src">

      <xsl:choose>

        <!-- If $static == 1 then the thumbnail is static
             If $static == 2 then all the images are static -->

       <xsl:when test = "number($static) > 1">

         <!-- perhaps a better way to do this is :
              substring-before @href,".html" + 
              substring-after $src,"." 
              basically, the issue is how to determine
              the extension for the image.-->

        <xsl:value-of select = "substring-before($image,'-thumb.')" /><xsl:if test = "number($doscale) > 0"><xsl:if test = "$scale != ''">-<xsl:value-of select = "$scale" /></xsl:if></xsl:if>.<xsl:value-of select = "substring-after($image,'-thumb.')" />
       </xsl:when>

       <xsl:when test = "number($static) > 0">
        <xsl:value-of select = "substring-before($image,'-thumb.')" />.<xsl:value-of select = "substring-after($image,'-thumb.')" /><xsl:if test = "$scale != ''">?scale=<xsl:value-of select = "$scale" /></xsl:if>
       </xsl:when>

       <xsl:otherwise>
        <xsl:value-of select = "substring-before($image,'?scale=')" /><xsl:if test = "$scale != ''">?scale=<xsl:value-of select = "$scale" /></xsl:if>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:attribute>
    </img>
   </div>

   <div>
    <xsl:attribute name = "class">meta</xsl:attribute>

    <xsl:if test = "number($doscale) > 0">
     <div>
      <xsl:attribute name = "class">links</xsl:attribute>
      <xsl:call-template name = "Links">
       <xsl:with-param name = "this_page" select = "/html/body/div[@id=$id]/a/@href"/>
       <xsl:with-param name = "current_scale" select = "$scale"/>
      </xsl:call-template>
     </div>
    </xsl:if>

   </div>
 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "Menu">

    <!-- -->

    <span>
     <xsl:attribute name = "class">menu-link-previous</xsl:attribute>

     <xsl:choose>
      <xsl:when test = "$prev != ''">
       <xsl:copy-of select = "/html/body/div[@id=$id]/preceding-sibling::*[1]/div[@class='thumbnail']/*" />
      </xsl:when>
      <xsl:otherwise>
       <xsl:copy-of select = "/html/body/div[@class='file' or @class = 'directory'][$last]/div[@class='thumbnail']/*" />
      </xsl:otherwise>
     </xsl:choose>

     <a>
      <xsl:attribute name = "href"><xsl:value-of select = "$prev_href_scaled" /></xsl:attribute>

      <xsl:attribute name = "title">
       <xsl:value-of select = "$prev_title" />
      </xsl:attribute>
 
      <xsl:value-of select = "$prev_title" />
     </a>

     </span>


  <!-- -->

  <span>
   <xsl:attribute name = "class">menu-link-index</xsl:attribute>
   <a>
    <xsl:attribute name = "href">index.html</xsl:attribute>      
    <xsl:call-template name = "PageTitle"/>
   </a>
  </span>

  <!-- -->

    <span>
     <xsl:attribute name = "class">menu-link-next</xsl:attribute>

     <a>
      <xsl:attribute name = "href"><xsl:value-of select = "$next_href_scaled" /></xsl:attribute>

      <xsl:attribute name = "title">
       <xsl:value-of select = "$next_title" />
      </xsl:attribute>
 
      <xsl:value-of select = "$next_title" />
     </a>

     <xsl:choose>
      <xsl:when test = "$next != ''">
       <xsl:copy-of select = "/html/body/div[@id=$id]/following-sibling::*[1]/div[@class='thumbnail']/*" />
      </xsl:when>
      <xsl:otherwise>
       <xsl:copy-of select = "/html/body/div[@class='file' or @class = 'directory'][1]/div[@class='thumbnail']/*" />
      </xsl:otherwise>
     </xsl:choose>

    </span>

 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "PageTitle">
  <xsl:value-of select = "/html/head/title" />   
 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "ImageTitle">
  <xsl:value-of select = "/html/body/div[@id=$id]/a" />   
 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "Links">
  <xsl:param name = "this_page" />
  <xsl:param name = "current_scale" />

  <xsl:if test = "$current_scale != ''">
   <span>
   <xsl:attribute name = "class">linkitem</xsl:attribute>
   <a>
    <xsl:attribute name = "href">
     <xsl:value-of select = "$this_page"/>
    </xsl:attribute>
    original
   </a>
   </span>
  </xsl:if>

  <xsl:call-template name = "_Links">
   <xsl:with-param name = "str" select = "$scales" />  
   <xsl:with-param name = "this_page" select = "$this_page" />
   <xsl:with-param name = "current_scale" select = "$current_scale" />
  </xsl:call-template>

 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "_Links">
  <xsl:param name = "str" />
  <xsl:param name = "this_page" />
  <xsl:param name = "current_scale" />

   <xsl:choose>
    <xsl:when test="contains($str,',')">
     <xsl:variable name = "this_scale" select = "substring-before($str,',')" />
     <xsl:variable name = "that_scale" select = "substring-after($str,',')" />

     <xsl:if test = "$this_scale != $current_scale">
      <xsl:call-template name = "Scale">
       <xsl:with-param name = "this_page" select = "$this_page" />
       <xsl:with-param name = "this_scale" select = "substring-before($str,',')" />
      </xsl:call-template>
     </xsl:if>

     <xsl:call-template name = "_Links">
      <xsl:with-param name="str" select="substring-after($str,',')"/>
      <xsl:with-param name = "this_page" select = "$this_page" />
      <xsl:with-param name = "current_scale" select = "$current_scale" />
     </xsl:call-template>

    </xsl:when>
    <xsl:otherwise>

     <xsl:if test = "$str != $current_scale">
      <xsl:call-template name = "Scale">
       <xsl:with-param name = "this_page" select = "$this_page" />
       <xsl:with-param name = "this_scale" select = "$str" />
      </xsl:call-template>
     </xsl:if>

    </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

<!-- ======================================================================
     ====================================================================== -->

 <xsl:template name = "Scale">
  <xsl:param name = "this_page" />
  <xsl:param name = "this_scale" />
  <span>
  <xsl:attribute name = "class">linkitem</xsl:attribute>
  <a>
   <xsl:attribute name = "href">
    <xsl:value-of select = "substring-before($this_page,'.html')"/>-<xsl:value-of select = "$this_scale" />.html
   </xsl:attribute>
   <xsl:value-of select = "$this_scale"/>
  </a>
  </span>
 </xsl:template>

<!-- ======================================================================
     $Date: 2002/08/05 14:54:50 $
     ====================================================================== -->

</xsl:stylesheet>

