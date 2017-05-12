#perl

package HTML::WebMake::PerlLib::ThumbnailTag;

use POSIX qw(strftime);
use File::Spec;
use File::Basename;
use File::Copy;

use Image::Size;

*dbg = \&HTML::WebMake::Main::dbg;

sub handle_thumbnail_tag {
  my ($tagname, $attrs, $text, $self) = @_;

  my $name = $attrs->{name};

  # get the attributes
  my $bordercolor = $attrs->{bordercolor};
  $bordercolor ||= $self->{main}->fileless_subst
	      	('<thumbnail>', '${thumbnail.bordercolor?}');
  $bordercolor ||= 'black';

  my $borderwidth = $attrs->{borderwidth};
  $borderwidth ||= $self->{main}->fileless_subst
	      	('<thumbnail>', '${thumbnail.borderwidth?}');
  $borderwidth ||= 1;

  my $thumbsize = $attrs->{thumbsize};
  $thumbsize ||= $self->{main}->fileless_subst
	      	('<thumbnail>', '${thumbnail.thumbsize?}');
  $thumbsize ||= 100;

  my $format = $attrs->{format};
  $format ||= $self->{main}->fileless_subst
	      	('<thumbnail>', '${thumbnail.format?}');
  $format ||= 'jpg';

  $text = $attrs->{text};
  $text ||= '${thumbnail.template}';
  # don't expand it now, it'll try to expand fully, and we haven't
  # set the vars yet!

  # now delete the attrs we've parsed so we can use the $attrs
  # hash for the tag_attrs element of the templates.
  foreach my $key (qw(href text bordercolor borderwidth thumbsize)) {
    delete $attrs->{$key};
  }

  # parse the template and generate what we can...
  # find the file, first of all.
  my $file = $self->get_url ($name);
  my $origfile = $self->{main}->fileless_subst ('<thumbnail>', $file);
  my ($realfname, $relfname) =
  		$self->{main}->expand_relative_filename ($origfile);

  if (!defined $realfname) {
    warn "<thumbnail>: cannot find file \"$origfile\"\n";
    return;

    $realfname = $relfname = $file = $origfile;
    $self->set_content ('thumbnail.path', $origfile);
    $self->set_content ('thumbnail.href', $origfile);

  } else {
    $file = $realfname;
    $self->set_content ('thumbnail.path', $realfname);
    $self->set_content ('thumbnail.href', $relfname);
  }

  $self->set_content ('thumbnail.name', $name);
  $self->set_content ('thumbnail.filename', basename ($file));

  # add file details
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
     $atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
  if (!defined $size) {
    warn "<thumbnail>: cannot find file \"$file\"\n";
    $mode = $uid = $gid = $size = $atime = $mtime = $ctime = 0;
  }

  $self->set_content ('thumbnail.size', $size);
  $self->set_content ('thumbnail.size_in_k', int (($size+1023) / 1024));

  # the tag attributes
  {
    my $attstr = '';
    foreach my $key (keys %{$attrs}) {
      $attstr .= $key.'="'.$attrs->{$key}.'" ';
    }
    chop $attstr;
    $self->set_content ('thumbnail.tag_attrs', $attstr);
  }

  # now, generate a thumbnail appropriately.
  # get the sizes
  my ($thumbheight, $thumbwidth, $realheight, $realwidth) =
  				gen_thumbnail_size ($self, $file, $thumbsize);
  $self->set_content ('thumbnail.width', $thumbwidth);
  $self->set_content ('thumbnail.height', $thumbheight);
  $self->set_content ('thumbnail.full_width', $realwidth);
  $self->set_content ('thumbnail.full_height', $realheight);

  # and create the thumb file (if it's not already there & up to date)
  my $thumbfile = $realfname;
  $thumbfile =~ s/\.[^\.]+$/_thumb.$format/ig;
  generate_thumbnail ($self, $file, $thumbfile, $bordercolor,
  				$borderwidth, $thumbheight, $thumbwidth);

  # and set a usable URL for it (ie. the path relative to current file)
  my $thumbrelfname = $relfname;
  $thumbrelfname =~ s/\.[^\.]+$/_thumb.$format/ig;
  $self->set_content ('thumbnail.thumb_src', $thumbrelfname);

  # finally, expand the template and return it
  return $self->{main}->fileless_subst ('<thumbnail>', $text);
}

# ---------------------------------------------------------------------------

sub gen_thumbnail_size {
  my ($self, $file, $sz) = @_;

  # Figure out the new size for the thumbnail, preserving the
  # correct aspect ratio.  We do this ourselves (a) for efficiency
  # and (b) for portability (some tools can't do it)
  #
  my ($width, $height) = imgsize ($file);
  $height ||= 1; $width ||= 1;		# avoid div by zero errors

  my ($thumbheight, $thumbwidth);
  if ($height < $sz && $width < $sz) {
    $thumbheight = $height;		# already small enough
    $thumbwidth = $width;

  } elsif ($height > $width) {
    $thumbheight = $sz;
    $thumbwidth = int ($width * ($sz / $height));

  } else {
    $thumbwidth = $sz;
    $thumbheight = int ($height * ($sz / $width));
  }
  return ($thumbheight, $thumbwidth, $height, $width);
}

# ---------------------------------------------------------------------------

sub generate_thumbnail {
  my ($self, $file, $thumb, $bordercolor,
  		$borderwidth, $thumbheight, $thumbwidth) = @_;

  if (-f $thumb && -M $thumb < -M $file) {
    # thumbnail is newer than source file; keep it.
    return;
  }

  my $cmd = '';

  # else we need to {,re}generate it
  unlink ($thumb);
  warn ("webmake: thumbnailing image: $file\n");

  if (!-f $file) {
    warn "<thumbnail>: cannot find image file \"$file\"\n";
    return;
  }

  # convert $file into something we can use in shell commands!
  $file =~ s/\'/\'?\'/gs;	# this will still work tho'
  $file =~ s/\0/_/gs;		# for safety, this won't work

  my $tmpdir = $self->{main}->tmpdir();
  my $rand = int(rand(99999)) . '_' . $$;

  my $thumbbase = "thumbnail_tmp_${rand}.ppm";
  my $thumbtmp = "$tmpdir/$thumbbase";

  unlink ($thumbtmp);		# just in case

  # copy and convert to ppm so we can work on it
  $cmd = "convert \'$file\' \'$thumbtmp\'";
  system ($cmd); ($? >> 8 == 0) or goto failed;
  
  # Resize to the thumb size, and add a nice 1x1 border.
  #
  # ImageMagick is available as a windows port; re-using
  # these commands is prob. the best way to go. This is why I haven't
  # used any pipes etc.
  #
  # Note that the use of $thumbbase, instead of just $thumbtmp, is
  # due to a bug in ImageMagick when operating on files in ~/.webmake .
  #
  $cmd = "( cd \"$tmpdir\" ; mogrify ".
	"-geometry ${thumbwidth}x${thumbheight} ".
  	"-bordercolor '${bordercolor}' ".
  	"-border ${borderwidth}x${borderwidth} ".
	"\'$thumbbase\' )";

  system ($cmd); ($? >> 8 == 0) or goto failed;

  # now turn it into a low-quality JPEG (and copy it as well)
  $cmd = "convert -quality 50 \'$thumbtmp\' \'$thumb\'";
  system ($cmd); ($? >> 8 == 0) or goto failed;

  unlink ($thumbtmp);		# all done with this
  return;

failed:
  warn "Command failed: \"$cmd\"\n";
  unlink ($thumbtmp, $thumb);
}

1;
