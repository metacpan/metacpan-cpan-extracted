{

=head1 NAME

Image::Shoehorn - massage the dimensions and filetype of an image

=head1 SYNOPSIS

 use Image::Shoehorn;
 use Data::Dumper;

 my $image = Image::Shoehorn->new({
                                   tmpdir     => "/usr/tmp",
                                   cleanup    => \&my_cleanup
                                  }) || die Image::Shoehorn->last_error();

 my $imgs = $image->import({
                            source     => "/some/large/image.jpg",
                            max_height => 600,
                            valid      => [ "png" ],
                            convert    => 1,
                            scale      => { thumb => "x50", small => "50%" },
                            overwrite  => 1,
                           }) || die Image::Shoehorn->last_error();

 print &Dumper($imgs);

=head1 DESCRIPTION

Image::Shoehorn will massage the dimensions and filetype of an image,
optionally creating one or more "scaled" copies.

It uses Image::Magick to do the heavy lifting and provides a single
"import" objet method to hide a number of tasks from the user.

=head1 RATIONALE

Just before I decided to submit this package to the CPAN, I noticed that
Lee Goddard had just released Image::Magick::Thumbnail. Although there is
a certain amount of overlap, creating thumbnails is only a part of the 
functionality of Image::Shoehorn.

Image::Shoehorn is designed for taking a single image, optionally converting
its file type and resizing it, and then creating one or more "scaled" 
versions of the (modified) image.

One example would be a photo-gallery application where the gallery may define
(n) number of scaled versions. In a mod_perl context, if the scaled image had
not already been created, the application might create the requested image
for the request and then register a cleanup handler to create the remaining 
"scaled" versions. Additionally, scaled images may be defined as "25%", "x50", 
"200x" or "25x75" (Apache::Image::Shoehorn is next...)

=head1 SHOEHORN ?!

This package started life as Image::Import; designed to slurp and munge images 
into a database. It's not a very exciting name and, further, is a bit ambiguous. 

So, I started fishing around for a better name and for a while I was thinking 
about Image::Tailor - a module for taking in the "hem" of an image, of fussing 
and making an image fit properly.

When I asked the Dict servers for a definition of "tailor", it returned a 
WordNet entry containing the definition...

 make fit for a specific purpose [syn: {shoehorn}]

..and that was that.

=cut

package Image::Shoehorn;
use strict;

$Image::Shoehorn::VERSION = '1.42';

use File::Basename;

use Carp;
use Error;

# use Data::Dumper;

use Image::Magick 5.44;
use File::MMagic;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->last_error()

Returns the last error recorded by the object.

=cut

sub last_error {
  my $pkg = shift;
  my $e   = shift;
  
  if ($e) {
    my $caller = (caller(1))[3];
    Error::Simple->record("[$caller] $e.");
    return 1;
  }
  
  return Error->prior();
}

=head2 __PACKAGE__->dimensions_for_scale($x,$y,$scale)

=cut

sub dimensions_for_scale {
  my $pkg   = shift;
  my $x     = shift;
  my $y     = shift;
  my $scale = shift;

  if ($scale =~ /^(\d+)x(\d+)$/) {
    $x = $1;
    $y = $2;
  }
  
  elsif ($scale =~ /^(\d+)%$/) {
    $x = ($x/100) * $1;
    $y  = ($y/100) * $1;
  }
  
  elsif ($scale =~ /^(\d+)x$/) {
    ($x,$y) = __PACKAGE__->scaled_dimensions([$x,$y,$1,undef]);
  }
  
  elsif ($scale =~ /^x(\d+)$/) {
    ($x,$y) = __PACKAGE__->scaled_dimensions([$x,$y,undef,$1]);
  }
  
  else { 
    return ();
  }

  return (int($x),int($y));
}

=head2 __PACKAGE__->scaled_name([$source,$scale])

=cut

sub scaled_name {
  my $pkg  = shift;
  my $args = shift;

  my $scaled = &basename($args->[0]);

  my $id = ($args->[1]) ? "-$args->[1]" : "";

  $scaled =~ s/(.*)(\.[^\.]+)$/$1$id$2/;
  $scaled =~ s/%/percent/;

  return $scaled;
}

=head2 __PACKAGE__->converted_name([$source,$type])

=cut

sub converted_name {
  my $pkg  = shift;
  my $args = shift;

  if (! $args->[1]) { return $args->[0]; }

  my $converted = $args->[0];
  $converted    =~ s/^(.*)\.([^\.]+)$/$1\.$args->[1]/;

  return $converted;
}

=head2 __PACKAGE__->scaled_dimensions([$cur_x,$cur_y,$new_x,$new_y])

=cut

sub scaled_dimensions {
  my $pkg    = shift;
  my $width  = $_[0]->[0];
  my $height = $_[0]->[1];
  my $x      = $_[0]->[2] || $width;
  my $y      = $_[0]->[3] || $height;

  if (($width == $x) && ($height == $y)) {
    return ($x,$y);
  }

  #

  foreach ($width, $height, $x, $y) {
    if ($_ < 1) {
      carp "Dimension (width:$width, height:$height, x:$x, y:$y) less than one. ".
	   "Returning 0,0 to avoid possible divide by zero error.\n";

      return (0,0);
    }
  }

  #

  my $h_percentage = $y / $height;
  my $w_percentage = $x / $width;
  my $percentage   = 100;
  
  if (($x)  && ($y )) { $percentage = ($h_percentage <= $w_percentage) ? $h_percentage : $w_percentage; }
  if (($x)  && (!$y)) { $percentage = $w_percentage; }
  if ((!$x) && ($y )) { $percentage = $h_percentage; }
  
  $x = int($width  * $percentage);
  $y = int($height * $percentage);
  
  return ($x,$y);
}

=head2 $pkg = __PACKAGE__->new(\%args)

Object constructor. Valid arguments are :

=over 4

=item *

B<tmpdir>

String.

The path to a directory where your program has permissions to create new files. I<Required>

=item *

B<cleanup>

Code reference.

By default, any new images that are created, in the tmp directory, are deleted 
when a different image is imported or when the I<Image::Shoehorn::DESTROY> 
method is invoked.

You may optionally provide your own cleanup method which will be called in 
place.

Your method will be passed a hash reference where the keys are "source" and 
any other names you may define in the I<scale> parameter of the I<import> 
object method. Each key points to a hash reference whose keys are :

=over 4

=item *

I<path>

=item *

I<width>

=item *

I<height>

=item *

I<format>

=item *

I<type>

=back

Note that this method will only affect B<new> images. The original source file 
may be altered, if it is imported with the I<overwrite> parameter, but will 
not be deleted.

=back

Returns an object. Woot!

=cut

sub new {
    my $pkg = shift;

    my $self = {};
    bless $self,$pkg;

    if (! $self->init(@_)) {
      return undef;
    }

    return $self
}

sub init {
    my $self = shift;
    my $args = shift;

    if (! -d $args->{'tmpdir'} ) {
      $self->last_error("Unable to locate tmp dir");
      return 0;
    }

    if (($args->{'cleanup'}) && (ref($args->{'cleanup'}) ne "CODE")) {
      $self->last_error("Cleanup is not a code reference.");
      return 0;
    }

    if (! $self->_magick()) {
      $self->last_error("Unable to get Image::Magick : $!");
      return 0;
    }

    $self->{'__cleanup'} = $args->{'cleanup'};
    $self->{'__tmpdir'}  = $args->{'tmpdir'};
    return 1;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->import(\%args)

Valid arguments are :

=over 4

=item *

B<source>

String.

The path to the image you are trying to import. If ImageMagick can read it, 
you can import it. 

I<Required>

=item *

B<max_width>

Int.

The maximum width that the image you are importing may be. Height is scaled 
accordingly.

=item *

B<max_height>

Int. 

The maximum height that the image you are importing may be. Width is scaled 
accordingly.

=item *

B<scale>

Hash reference. 

One or more key-value pairs that define scaling dimensions for creating 
multiple instances of the current image. 

The key is a human readable label because humans are simple that way. The 
key may be anything you'd like B<except> "source" which is reserved for the 
image the object is munging.

The value for a given key is the dimension flag which may be represented as :

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

Note that images are scaled B<after> the original source file may have been 
resized according to the I<max_height>, I<max_width> flags and I<convert> 
flags.

Scaled images are created in the I<tmp_dir> defined in the object constructor.

=item *

B<valid>

Array reference. 

An list of valid file-types for which I<Image::Magick> has encoding support.

=item *

B<convert>

Boolean. 

If this value is true and the source does not a valid file-type, the method 
will create a temporary file attempt to convert it to one of the specified 
valid file-types. The method will try to convert in the order the valid 
file-types are specified, stopping on success.

=item *

B<cleanup>

Code reference.

Define a per instance cleanup function for an image. This functions exactly 
the same way that a cleanup function defined in the object constructor does, 
except that it is forgotten as soon as a new image is imported.

=item *

B<overwrite>

Boolean. 

Indicates whether or not to preserve the source file. By default, the package 
will B<not> perform munging on the source file itself and will instead create 
a new file in the I<tmp_dir> defined in the object constructor.

=back

Returns a hash reference with information for the source image -- note that 
this may or may not be the input document, but the newly converted/resized 
image created in you tmp directory -- and any scaled images you may have 
defined.

The keys of the hash are human readable names. The values are hash references 
whose keys are :

=over 4

=item *

I<path>

=item *

I<height>

=item *

I<width>

=item *

I<extension>

=item *

I<contenttype>

=item *

I<format>

=item *

I<type>

Deprecated in favour or I<extension>

=back

If there was an error, the method will return undef.

=cut

sub import {
    my $self = shift;
    my $args = shift;

    #

    if (! -e $args->{'source'}) {
      $self->last_error("Unknown file $args->{'source'}");
      return undef;
    }

    if (($args->{'cleanup'}) && (ref($args->{'cleanup'}) ne "CODE")) {
      $self->last_error("Cleanup is not a code reference.");
      return undef;
    }

    if (! $self->_magick()->Ping($args->{'source'})) {
      $self->last_error("Unable to ping $args->{'source'}: $!");
      return undef;
    }

    #

    if (($self->{'__source'}) && ($args->{'source'} ne $self->{'__source'})) {
      $self->_cleanup();
    }

    if ($args->{'cleanup'}) {
      $self->{'__instancecleanup'} = $args->{'cleanup'};
    }

    #

    $self->{'__source'} = $args->{'source'};
    $self->{'__dest'}   = $self->{'__source'};

    unless ($args->{'overwrite'}) {
      $self->{'__dest'} = "$self->{'__tmpdir'}/".&basename($args->{'source'});
    }

    #

    if (! $self->_process($args)) {
      return undef;
    }

    #

    my $validation = $self->_validate($args);

    if ((! $validation->[0]) && (! $validation->[1])) {
      return undef;
    }

    #

    if (! keys %{$args->{'scale'}}) {

      my $dest = ($args->{'overwrite'})? 
	__PACKAGE__->converted_name([$self->{'__images'}{'source'}{'path'},$validation->[1]]) :
	  "$self->{'__tmpdir'}/".&basename(__PACKAGE__->converted_name([$self->{'__images'}{'source'}{'path'},
									$validation->[1]]));

      my ($x,$y) = $self->_shoehorn({source => $self->{'__images'}{'source'}{'path'},
				     dest   => $dest,
				     type   => $validation->[1]});

      if (! $x) {
	return undef;
      }

      return {source=>$self->_ping($dest)};
    }

    #

    foreach my $name (keys %{$args->{'scale'}}) {

      next if ($name eq "source");

      if (! $self->_scale({
			   name  => $name,
			   scale => $args->{'scale'}->{$name},
			   type  => $validation->[1],
			  })) {
	return undef;
      }
    }

    map { shift; } @{$self->_magick()};
    return $self->{'__images'};
}

# =head2 $obj->_process(\%args)
#
# =cut

sub _process {
    my $self = shift;
    my $args = shift;

    $self->{'__images'}{'source'} = $self->_ping($self->{'__source'}) || return 0;

    #

    my $validation = $self->_validate($args);

    if ((! $validation->[0]) && (! $validation->[1])) {
      return 0;
    }

    #

    if ((! $args->{'max_height'}) && (! $args->{'max_width'})) {
      return 1;
    }

    #

    my $geometry = undef;
    my $newtype  = undef;

    #

    my ($x,$y) = __PACKAGE__->scaled_dimensions([
				     $self->{'__images'}{'source'}{'width'},
				     $self->{'__images'}{'source'}{'height'},
				     $args->{'max_width'},
				     $args->{'max_height'}
				    ]);

    unless (($x == $self->{'__images'}{'source'}{'width'}) &&
	    ($y == $self->{'__images'}{'source'}{'height'})) {

      $geometry = join("x",$x,$y);
    }

    #

    $newtype = $validation->[1];

    #

    if ((! $newtype) && (! $geometry)) {
      return 1;
    }

    if ($newtype) {
      $self->{'__dest'} =~ s/^(.*)\.($self->{'__images'}{'source'}{'type'})$/$1\.$newtype/;
    }

    #

    $self->_shoehorn({
		      geometry => $geometry,
		      type     => $newtype
		     });

    if (! $x) { return 0; }

    #

    if ($newtype) {
      $self->{'__images'}{'source'} = $self->_ping($self->{'__dest'});
    }

    else {
      $self->{'__images'}{'source'}{'height'} = $y;
      $self->{'__images'}{'source'}{'width'}  = $x;
    }

    return 1;
}

# =head2 $obj->_validate(\@valid)
#
# Returns an array ref containing a boolean (is valid type) and a possible 
# type for conversion
# 
# =cut

sub _validate {
  my $self = shift;
  my $args = shift;

  if (exists($self->{'__validation'})) { return $self->{'__validation'}; }

  unless (ref($args->{'valid'}) eq "ARRAY") {
    $self->{'__validation'} = [1];
    return $self->{'__validation'};
  }

  if (grep /^($self->{'__images'}{'source'}{'type'})$/,@{$args->{'valid'}}) {
    $self->{'__validation'} = [1];
    return $self->{'__validation'};
  }

  foreach my $type (@{$args->{'valid'}}) {
    my $encode = ($self->_magick()->QueryFormat(format=>$type))[4];

    if ($encode) { 
      $self->{'__validation'} = [1,$type];
      return $self->{'__validation'};
    }
  }

  $self->{'__validation'} = [0];
  return $self->{'__validation'};
}

# =head2 $obj->_scale($name,$scale)
#
# =cut

sub _scale {
  my $self = shift;
  my $args = shift;

  my $scaled = __PACKAGE__->scaled_name([$self->{'__dest'},
					 $args->{'name'}]);

  $scaled = "$self->{'__tmpdir'}/$scaled";

  if ($args->{'type'}) {
    $scaled = __PACKAGE__->converted_name([$scaled,$args->{'type'}]);
  }

  my ($width,$height) = __PACKAGE__->dimensions_for_scale(
							  $self->{'__images'}{'source'}->{'width'},
							  $self->{'__images'}{'source'}->{'height'},
							  $args->{'scale'},
							 );

  if ((! $width) || (! $height)) {
    $self->last_error("Unable to determine dimensions for '$args->{scale}'");
    return 0;
  }
  
  my ($x,$y) = $self->_shoehorn({
				 source   => $self->{'__images'}{'source'}{'path'},
				 dest     => $scaled,
				 geometry => join("x",$width,$height),
				 type     => $args->{'type'},
				});

  if (! $x) { return 0; }

  $self->{'__images'}{$args->{'name'}} = $self->_ping($scaled) || return 0;

  return 1
}

# =head2 $obj->_shoehorn(\%args)
#
# =cut

sub _shoehorn {
  my $self = shift;
  my $args = shift;
  
  $args->{'source'} ||= $self->{'__source'};
  $args->{'dest'}   ||= $self->{'__dest'};

#  my $caller = (caller(1))[3];
#  print STDERR "Shoehorn ($caller):\n".&Dumper($args);

  #

  $self->_read($args->{'source'}) || return 0;

  #

  if ($args->{'geometry'}) {

    if (my $err = $self->_magick()->Scale(geometry=>$args->{'geometry'})) {
      $self->last_error("Failed to scale $args->{'source'} : $err");
      return 0;
    }

  }

  #

  if ($args->{'type'}) {
    $args->{'dest'} = "$args->{'type'}:$args->{'dest'}";
  }

  if (my $err = $self->_magick()->[0]->Write($args->{'dest'})) { 
    $self->last_error("Failed to write '$args->{'dest'}' : $@");
    return 0;
  }

  #

  return ($self->_magick()->Get("width"),$self->_magick()->Get("height"));
}

# =head2 $obj->_read($file)
#
# =cut

sub _read {
  my $self = shift;

  if (my $err = $self->_magick()->Read($_[0]."[0]")) {
    $self->last_error("Failed to ping '$_[0]' : $err");
    return 0;
  }

  # Hack. There must be a better way...
  @{$self->{'__magick'}} = pop @{$self->{'__magick'}};
  return 1;
}

# =head2 $obj->_ping($file)
#
# =cut

sub _ping {
  my $self = shift;
  my $file = shift;

  $self->_read($file) || return 0;

  # Because $magick->Ping() is often unreliable
  # and fails to return height/width info. Dunno.

  $file =~ /^(.*)\.([^\.]+)$/;
  my $extension = $2;
  
  return {
	  width       => $self->_magick()->Get("width"),
	  height      => $self->_magick()->Get("height"),
	  path        => $file,
	  format      => $self->_magick()->Get("format"),
	  type        => $extension,
	  extension   => $extension,
          contenttype => $self->_mmagic()->checktype_filename($file),
	 };
}

# =head2 $obj->_cleanup()
#
# =cut

sub _cleanup {
  my $self = shift;

  delete $self->{'__validation'};

  if ($self->{'__images'}{'source'}{'path'} eq $self->{'__source'}) {
    delete $self->{'__images'}{'source'};
  }

  if (ref($self->{'__instancecleanup'}) eq "CODE") {
    my $result = &{ $self->{'__instancecleanup'} }($self->{'__images'});

    delete $self->{'__instancecleanup'};
    return $result;
  }

  if (ref($self->{'__cleanup'}) eq "CODE") {
    return &{ $self->{'__cleanup'} }($self->{'__images'});
  }

  foreach my $name (keys %{$self->{'__images'}}) {
    my $file = $self->{'__images'}->{$name}->{'path'};
    if (-f $file ) { unlink $file; }
  }

  return 1;
}

# =head2 $obj->_mmagic()
#
# Returns a File::MMagic object
#
# -cut

sub _mmagic {
    my $self = shift;

    if (ref($self->{'__mmagic'}) ne "File::MMagic") {
        $self->{'__mmagic'} = File::MMagic->new();
    }

    return $self->{'__mmagic'};
}

# =head2 $obj->_magick()
#
# =cut

sub _magick {
    my $self = shift;

    if (ref($self->{'__magick'}) ne "Image::Magick") {
	$self->{'__magick'} = Image::Magick->new();
    }

    return $self->{'__magick'};
}

# =head2 $obj->DESTROY()
#
# =cut

sub DESTROY {
  my $self = shift;
  $self->_cleanup();
  return 1;
}

=head1 VERSION

1.42

=head1 DATE

$Date: 2003/05/30 22:51:06 $

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over 4

=item *

Modify constructor to accept all the options defined in the I<import> 
method as defaults.

=item *

Modify I<import> to accept multiple files.

=item *

Modify I<import> to accept strings and filehandles.

=back

=head1 SEE ALSO

L<Image::Magick>

L<Image::Magick::Thumbnail>

=head1 LICENSE

Copyright (c) 2001-2003, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same
terms as Perl itself.

=cut

return 1;

}
