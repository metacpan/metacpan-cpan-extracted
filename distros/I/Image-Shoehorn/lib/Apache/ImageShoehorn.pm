{

=head1 NAME

Apache::ImageShoehorn - mod_perl wrapper for Image::Shoehorn

=head1 SYNOPSIS

  <Directory /path/to/some/directory/with/images>
   SetHandler	perl-script
   PerlHandler	Apache::ImageShoehorn

   PerlSetVar   ScaledDir       /path/to/some/dir

   PerlSetVar	SetScaleSmall	25%
   PerlSetVar	SetScaleMedium	50%
   PerlSetVar	SetScaleLarge	75%
   PerlSetVar	SetScaleThumb	x50

   PerlSetVar   SetValid        png
   PerlSetVar   Convert         On

   PerlSetVar   ScaleAllOnCleanup  Off

   <FilesMatch "\.html$">
    # Do something with HTML files here
   </FilesMatch>
  </Directory>

  # This image would actually be converted and
  # sent to the browser as a PNG file. Woot!

  http://www.foo.com/images/bar.jpg?scale=medium

=head1 DESCRIPTION

Apache mod_perl wrapper for Image::Shoehorn.

=head1 CONFIG DIRECTIVES

=over

=item *

ScaledDir          I<string>

A path on the filesystem where the handler will save images that have been scaled

Remember, this directory needs to be writable by whatever user is running the http daemon.

=item *

SetScaleI<Name>    I<string>

Define the names and dimensions of scaled images. I<name> will be converted to lower-case and compared with the I<scale> CGI query parameter. If no matching config directive is located, the handler will return DECLINED.

If there are multiple SetScale directives then they will be processed, if necessary, during the handler's cleanup stage.

If a scaled image already exists, it will not be rescaled until the lastmodified time for the source file is greater than that of the scaled version.

Valid dimensions are identical as those listed in I<Image::Shoehorn>.

=item *

SetValid       I<string>

Define one or more file types that are considered valid for sending to the browser, notwithstanding any issues of scaling, "as-is".

=item *

Convert        I<(On|Off)>

If an image fails a validity test, then the image will be be converted using the first type defined by the I<SetValid> configs that the package (read: Image::Magick) can understand.

=item *

ScaleAllOnCleanup   I<(On|Off)>

Toggle setting for scaling all size definitions for an image during the cleanup phase of a request. Default is "On".

=back

This package does not support all of the options available to the I<Image::Shoehorn> constructor. They will likely be added in later releases. The current list of unsupported configuration options is :

=over

=item *

I<max_height>

=item *

I<max_width>

=item *

I<overwrite>

=back

=cut

package Apache::ImageShoehorn;
use strict;

$Apache::ImageShoehorn::VERSION = '0.9.2';

use Apache;
use Apache::Constants qw (:common);
use Apache::File;
use Apache::Log;

use Image::Shoehorn 1.2;

my %TYPES   = ();
my @FORMATS = ();

sub handler {
    my $apache = shift;

    # First we make sure that we are dealing
    # with a file we can understand.

    unless (&_valid_type($apache)) {
      return DECLINED;
    }

    # Check to see if need to deal with
    # validation and conversion.

    my $valid   = 1;
    my $convert = 0;

    if ($apache->dir_config("SetValid")) {
      my $ctype = $apache->content_type();
      my @valid = $apache->dir_config->get("SetValid");

      $valid = grep /^($ctype)$/,@valid;

      if (! $valid) {
	$convert = $apache->dir_config("Convert") =~ /^(on)$/i;
      }
    }

    if ((! $valid) && (! $convert)) {
      return NOT_FOUND;
    }

    # Pull in some query parameters for optional scaling.

    my %params = ($apache->method() eq "POST") ? $apache->content() : $apache->args();
    my $sname  = $params{"scale"};

    if (! $sname) {
      return DECLINED;
    }

    # If we're neither scaling nor converting an
    # image, our work here is done. These are not
    # the droids we are looking for.

    my $scale = $apache->dir_config("SetScale".(ucfirst $sname));

    if (($sname) && (! $scale)) { 
      return NOT_FOUND;
    }

    # What is the name of the file we're dealing with?

    my $source    = $apache->filename();
    my $converted = undef;

    # Sooner or later, we're going to need this 
    #  we'll define it now.

    my $shoehorn = undef;

    # The source file does not have a valid type 
    # so we need to set up some details for converting
    # it.

    if ($convert) {

      $shoehorn = &_shoehorn($apache)
	|| return &_shoeless($apache);

      # Can Image::Shoehorn deal with making
      # this into that?

      my $validation = $shoehorn->_validate({valid=>[$apache->dir_config->get("SetValid")]});

      # No.

      if (! $validation->[0]) {
	$apache->log()->error("Failed validation.");
	return SERVER_ERROR;
      }

      # Define the filename for the converted image.

      $converted = Image::Shoehorn->converted_name([$source,$validation->[1]]);
    }

    # We add some additional information to the path name
    # largely to try and idiot-proof things for humans.

    my $scaled = &_scalepath($apache,[($converted || $source),$sname]);

    # When was the source file last modified?

    my $mtime = (stat($source))[9];

    # If the source file hasn't been modified 
    # and the scale file already exists (okay, so
    # the function name is a bit of a misnomer)
    # then our work is done and we can send the 
    # scale file.

    if (! &_modified([$mtime,$scaled])) {

      if ($convert) { $source = $converted; }

      unless ($apache->dir_config("ScaleAllOnCleanup") =~ /off/i) {
	$apache->register_cleanup(sub { &_scaleall($apache,undef,$source,$mtime); });
      }

      return &_send($apache,{path=>$scaled});
    }

    # If we haven't had to deal with converting files 
    # then we still need to instantiate an Image::Shoehorn
    # object

    $shoehorn ||= &_shoehorn($apache)
      || return &_shoeless($apache);

    # Now we finally get around to scaling the image

    my ($imgs,$err) = &_scale($apache,$shoehorn,$source,$sname,$scale);

    # Something went wrong.

    if (! $imgs) {
      $apache->log()->error("Unable to scale '$source' : $err");
      return SERVER_ERROR;
    }

    # Fly away!

    unless ($apache->dir_config("ScaleAllOnCleanup") =~ /off/i) {
      $apache->register_cleanup(sub { &_scaleall($apache,$shoehorn,$imgs->{'source'}->{'path'},$mtime); });
    }

    # Note the $sname || "source" conditional.
    # If we're sending the actual source file,
    # we should never gotten this far anyway so
    # we're going to assume that the only reason
    # is because we need to convert the image,
    # scale the image or both. If we need to scale
    # the image then, all we can fetch the new file
    # via $sname. If we have converted the image
    # unscaled, then it will have been assigned the 
    # magic 'source' title because the mod_perl wrapper
    # doesn't pay any attention (yet, anyway) to the 
    # 'overwrite' attribute in the Image::Shoehorn 
    # constructor.

    return &_send($apache,$imgs->{($sname || "source")});
}

sub _shoehorn {
  my $apache = shift;
  return Image::Shoehorn->new({
			       tmpdir  => $apache->dir_config("ScaledDir"),
			       cleanup => sub {},
			      });
}

sub _shoeless {
  my $apache = shift;

  $apache->log()->error("Unable to create Image::Shoehorn object :".
			Image::Shoehorn->last_error());

  return SERVER_ERROR;
}

sub _send {
  my $apache = shift;
  my $image  = shift;

  my $fh = Apache::File->new($image->{'path'});

  if (! $fh) {
    $apache->log()->error("Unable to create filehandle, $!");
    return SERVER_ERROR;
  }

  $apache->content_type($apache->content_type());
  $apache->send_http_header();
  $apache->send_fd($fh);
  
  return OK;
}

sub _scale {
  my $apache   = shift;
  my $shoehorn = shift;
  my $source   = shift;
  my $name     = shift;
  my $scale    = shift;

  my $imgs = $shoehorn->import({
				source  => $source,
				scale   => (($name) && ($scale)) ? { $name => $scale } : {},
				convert => $apache->dir_config("Convert"),
				valid   => (($apache->dir_config("SetValid")) ? 
					    [ $apache->dir_config->get("SetValid") ] : undef),
			       }) || return (0,Image::Shoehorn->last_error());

  return ($imgs,undef);
}

sub _scaleall {
  my $apache   = shift;
  my $shoehorn = shift;
  my $source   = shift;
  my $mtime    = shift;

  my %scales = ();

  foreach my $var (keys %{$apache->dir_config()}) {
    $var =~ /^SetScale(.*)/;
    next unless $1;
    
    my $name   = lc($1);
    my $scaled = &_scalepath($apache,[$source,$name]);

    next unless (&_modified([$mtime,$scaled]));
    $scales{$name} = $apache->dir_config($var);
  }

  if (keys %scales) {

    if (ref($shoehorn) ne "Image::Shoehorn") {
      $shoehorn = &_shoehorn($apache);
    }
    
    if (! $shoehorn) {
      $apache->log()->error(Image::Shoehorn->last_error());
      return 0;
    }
    
    if (! $shoehorn->import({
			     source  => $source,
			     scale   => \%scales,
			     convert => $apache->dir_config("Convert"),
			     valid   => (($apache->dir_config("SetValid")) ? 
					 [ $apache->dir_config->get("SetValid") ] : undef),
			    })) {

      $apache->log()->error("Failed to import ".Image::Shoehorn->last_error());
      return 0;
    }
  }

  return 1;
}

sub _valid_type {
  my $apache = shift;

  $apache->content_type() =~ /^(.*)\/(.*)$/;

  if (! $2) { return 0; }

  if (exists($TYPES{$apache->location()}->{$2})) {
    return $TYPES{$apache->location()}->{$2};
  }

  if (! @FORMATS) {
    @FORMATS = Image::Magick->QueryFormat();
  }
  
  $TYPES{$apache->location()}->{$2} = grep(/^($2)$/,@FORMATS);
  return $TYPES{$apache->location()}->{$2};
}

sub _scalepath {
  my $apache = shift;

  my $scaled = Image::Shoehorn->scaled_name($_[0]);
  $scaled    = $apache->dir_config("ScaledDir")."/$scaled";

  return $scaled;
}

sub _modified {
  my $args = shift;

  # $args->[0] - the mtime for the source file
  # $args->[1] - the path for the scale file

  if (! -f $args->[1]) { return 1; }

  if ($args->[0] > (stat($args->[1]))[9]) {
    return 1;
  }

  return 0;
}

=head1 VERSION

0.9.2

=head1 DATE

July 07, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO 

L<Image::Shoehorn>

=head1 LICENSE

Copyright (c) 2002 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
