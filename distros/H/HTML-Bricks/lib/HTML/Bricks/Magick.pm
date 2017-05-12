package HTML::Bricks::Magick;

use strict;
use Apache::Constants qw(:common);
use Apache::File ();
use File::Basename qw(fileparse);
use DirHandle ();

our $VERSION = '0.02';

my %LegalArguments = map { $_ => 1 } 
qw (adjoin background bordercolor colormap colorspace
    colors compress density dispose delay dither
    display font format iterations interlace
    loop magick mattecolor monochrome page pointsize
    preview_type quality scene subimage subrange
    size tile texture treedepth undercolor);

my %LegalFilters = map { $_ => 1 } 
qw(AddNoise Blur Border Charcoal Chop
   Contrast Crop Colorize Comment CycleColormap
   Despeckle Draw Edge Emboss Enhance Equalize Flip Flop
   Frame Gamma Implode Label Layer Magnify Map Minify
   Modulate Negate Normalize OilPaint Opaque Quantize
   Raise ReduceNoise Resize Rotate Sample Scale Segment Shade
   Sharpen Shear Solarize Spread Swirl Texture Transparent
   Threshold Trim Wave Zoom);

sub handler {
    use Image::Magick;

    my $r = shift;

    return DECLINED unless $r->filename =~ /.*\.[jJ][pP][eE]?[gG]/;

    # get the name of the requested file
    my $file = $r->filename;

    # If the file exists and there are no transformation arguments
    # just decline the transaction.  It will be handled as usual.
    return DECLINED unless $r->args || $r->path_info || !-r $r->finfo;
    
    my $source;
    my ($base, $directory, $extension) = fileparse($file, '\.\w+');
    if (-r $r->finfo) { # file exists, so it becomes the source
  	$source = $file;
    } 
    else {              # file doesn't exist, so we search for it
  	return DECLINED unless -r $directory;
  	$source = find_image($r, $directory, $base);
    }
    
    unless ($source) {
  	$r->log_error("Couldn't find an image for $file");
  	return NOT_FOUND;
    }
  
    # Get args and construct our cached URI

    my $args = $r->args;
    my $cached = $r->document_root .  '/.magick_cache' . $r->uri . '?' . $args;

    # If the filtered image is already cached on the server, and the mtimes
    # match (indicating that the file hasn't been updated since the cached 
    # copy was created (see the bottom of this sub)) send the cached copy.

    my $mtime_source = ${@{[stat($source)]}}[9];

    #
    # but first check for clients polling to see if the file's been modified
    #

    if ($r->header_only) {

      if (-e $cached) {
        my $mtime_cached = ${@{[stat($cached)]}}[9];
        if ($mtime_cached == $mtime_source) {
          $r->update_mtime($mtime_cached);
          $r->set_last_modified;
        }
      }
      $r->send_http_header;
      return OK;
    }

    if (-e $cached) {
        my $mtime_cached = ${@{[stat($cached)]}}[9];
        if ($mtime_cached == $mtime_source) {
          my $fh = Apache::gensym();
          open ($fh, $cached) || return NOT_FOUND;
          $r->send_fd($fh);
          close($fh);
          return OK;
	} 
    }
   
    # Read the image
    my $q = Image::Magick->new;
    my $err = $q->Read($source);

    # Conversion arguments and image filter operations are kept in 
    # the query string.

    my %arguments;
    my @filters = split("&",$args);

    foreach (@filters) {
        my @fields = split(':', $_);
	my $filter = ucfirst shift @fields;
	next unless $LegalFilters{$filter};

        foreach (@fields) {
          my @arg = split('=',$_);
          $arguments{$arg[0]} = $arg[1];
        }
	$err ||= $q->$filter(%arguments);    # apply filters one at a time
    }

    # Remove invalid arguments before the conversion
    foreach (keys %arguments) { 	
	delete $arguments{$_} unless $LegalArguments{$_};
    }

    my ($tmpnam, $fh) = Apache::File->tmpfile;
    
    # Write out the modified image
    open(STDOUT, ">&=" . fileno($fh));
    $extension =~ s/^\.//;
    $err ||= $q->Write('filename' => "\U$extension\L:-", %arguments);
    if ($err) {
  	unlink $tmpnam;
  	$r->log_error($err);
  	return SERVER_ERROR;
    }
    close $fh;
    
    # At this point the conversion is all done!
    # reopen for reading
    $fh = Apache::File->new($tmpnam);
    unless ($fh) {
  	$r->log_error("Couldn't open $tmpnam: $!");
  	return SERVER_ERROR;
    }
    
    # send the file
    $r->send_fd($fh);
    
    # create the directory to put the cached file if it doesn't exist

    my $dir = substr($cached,0,rindex($cached,"/"));    

    if (! -e $dir) {
      # see if we can create the directory

      my $dir = $r->document_root . "/.magick_cache";
      my @path = split("/",$r->uri);

      foreach(@path) {
        mkdir $dir;
        $dir .= "/$_";
      } 
    }

    # save the file to the cache, set the mtime and return
 
    use File::Copy;
    move($tmpnam,$cached);
    utime(time,$mtime_source,$cached);

    return OK;
}

sub find_image {
    my ($r, $directory, $base) = @_;
    my $dh = DirHandle->new($directory) or return;

    my $source;
    for my $entry ($dh->read) {
  	my $candidate = fileparse($entry, '\.\w+');
  	if ($base eq $candidate) {
  	    # determine whether this is an image file
	    $source = join '', $directory, $entry;
  	    my $subr = $r->lookup_file($source);
  	    last if $subr->content_type =~ m:^image/:;
	    $source = "";
  	}
    }
    $dh->close;
    return $source;
}

1;
__END__
