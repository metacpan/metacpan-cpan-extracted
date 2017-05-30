package Image::Sane;

use 5.008005;
use strict;
use warnings;
use Image::Sane::Device;
use Exporter ();
use base qw(Exporter);
use Exception::Class (
    'Image::Sane::Exception' => { alias => 'throw', fields => 'status' } );
use Readonly;
Readonly my $_1000 => 1000;

our %EXPORT_TAGS = (
    'all' => [
        qw(
          SANE_FALSE
          SANE_TRUE
          SANE_STATUS_GOOD
          SANE_STATUS_UNSUPPORTED
          SANE_STATUS_CANCELLED
          SANE_STATUS_DEVICE_BUSY
          SANE_STATUS_INVAL
          SANE_STATUS_EOF
          SANE_STATUS_JAMMED
          SANE_STATUS_NO_DOCS
          SANE_STATUS_COVER_OPEN
          SANE_STATUS_IO_ERROR
          SANE_STATUS_NO_MEM
          SANE_STATUS_ACCESS_DENIED
          SANE_TYPE_BOOL
          SANE_TYPE_INT
          SANE_TYPE_FIXED
          SANE_TYPE_STRING
          SANE_TYPE_BUTTON
          SANE_TYPE_GROUP
          SANE_UNIT_NONE
          SANE_UNIT_PIXEL
          SANE_UNIT_BIT
          SANE_UNIT_MM
          SANE_UNIT_DPI
          SANE_UNIT_PERCENT
          SANE_UNIT_MICROSECOND
          SANE_CAP_SOFT_SELECT
          SANE_CAP_HARD_SELECT
          SANE_CAP_SOFT_DETECT
          SANE_CAP_EMULATED
          SANE_CAP_AUTOMATIC
          SANE_CAP_INACTIVE
          SANE_CAP_ADVANCED
          SANE_CAP_ALWAYS_SETTABLE
          SANE_INFO_INEXACT
          SANE_INFO_RELOAD_OPTIONS
          SANE_INFO_RELOAD_PARAMS
          SANE_CONSTRAINT_NONE
          SANE_CONSTRAINT_RANGE
          SANE_CONSTRAINT_WORD_LIST
          SANE_CONSTRAINT_STRING_LIST
          SANE_FRAME_GRAY
          SANE_FRAME_RGB
          SANE_FRAME_RED
          SANE_FRAME_GREEN
          SANE_FRAME_BLUE
          SANE_NAME_NUM_OPTIONS
          SANE_NAME_PREVIEW
          SANE_NAME_GRAY_PREVIEW
          SANE_NAME_BIT_DEPTH
          SANE_NAME_SCAN_MODE
          SANE_NAME_SCAN_SPEED
          SANE_NAME_SCAN_SOURCE
          SANE_NAME_BACKTRACK
          SANE_NAME_SCAN_TL_X
          SANE_NAME_SCAN_TL_Y
          SANE_NAME_SCAN_BR_X
          SANE_NAME_SCAN_BR_Y
          SANE_NAME_SCAN_RESOLUTION
          SANE_NAME_SCAN_X_RESOLUTION
          SANE_NAME_SCAN_Y_RESOLUTION
          SANE_NAME_PAGE_WIDTH
          SANE_NAME_PAGE_HEIGHT
          SANE_NAME_CUSTOM_GAMMA
          SANE_NAME_GAMMA_VECTOR
          SANE_NAME_GAMMA_VECTOR_R
          SANE_NAME_GAMMA_VECTOR_G
          SANE_NAME_GAMMA_VECTOR_B
          SANE_NAME_BRIGHTNESS
          SANE_NAME_CONTRAST
          SANE_NAME_GRAIN_SIZE
          SANE_NAME_HALFTONE
          SANE_NAME_BLACK_LEVEL
          SANE_NAME_WHITE_LEVEL
          SANE_NAME_WHITE_LEVEL_R
          SANE_NAME_WHITE_LEVEL_G
          SANE_NAME_WHITE_LEVEL_B
          SANE_NAME_SHADOW
          SANE_NAME_SHADOW_R
          SANE_NAME_SHADOW_G
          SANE_NAME_SHADOW_B
          SANE_NAME_HIGHLIGHT
          SANE_NAME_HIGHLIGHT_R
          SANE_NAME_HIGHLIGHT_G
          SANE_NAME_HIGHLIGHT_B
          SANE_NAME_HUE
          SANE_NAME_SATURATION
          SANE_NAME_FILE
          SANE_NAME_HALFTONE_DIMENSION
          SANE_NAME_HALFTONE_PATTERN
          SANE_NAME_RESOLUTION_BIND
          SANE_NAME_NEGATIVE
          SANE_NAME_QUALITY_CAL
          SANE_NAME_DOR
          SANE_NAME_RGB_BIND
          SANE_NAME_THRESHOLD
          SANE_NAME_ANALOG_GAMMA
          SANE_NAME_ANALOG_GAMMA_R
          SANE_NAME_ANALOG_GAMMA_G
          SANE_NAME_ANALOG_GAMMA_B
          SANE_NAME_ANALOG_GAMMA_BIND
          SANE_NAME_WARMUP
          SANE_NAME_CAL_EXPOS_TIME
          SANE_NAME_CAL_EXPOS_TIME_R
          SANE_NAME_CAL_EXPOS_TIME_G
          SANE_NAME_CAL_EXPOS_TIME_B
          SANE_NAME_SCAN_EXPOS_TIME
          SANE_NAME_SCAN_EXPOS_TIME_R
          SANE_NAME_SCAN_EXPOS_TIME_G
          SANE_NAME_SCAN_EXPOS_TIME_B
          SANE_NAME_SELECT_EXPOSURE_TIME
          SANE_NAME_CAL_LAMP_DEN
          SANE_NAME_SCAN_LAMP_DEN
          SANE_NAME_SELECT_LAMP_DENSITY
          SANE_NAME_LAMP_OFF_AT_EXIT
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.10';
our $DEBUG   = 0;
my $vc;

use XSLoader;
XSLoader::load( 'Image::Sane', $VERSION );

sub _throw_error {
    my ($status) = @_;

    # I don't understand why using the alias gives a syntax error here
    if ($status) {
        Image::Sane::Exception->throw(
            error  => Image::Sane::strstatus($status),
            status => $status
        );
    }
    return;
}

sub init {
    my $class = shift;
    if ( not $vc ) {
        ( my $status, $vc ) = _init();
        _throw_error($status);
    }
    return 1;
}

sub get_version {
    my $class = shift;
    if ( not Image::Sane->init ) { return }
    return _get_version($vc);
}

sub get_version_scalar {
    my $class   = shift;
    my @version = Image::Sane->get_version();
    if ( not @version ) { return }
    return $version[0] + $version[1] / $_1000 + $version[2] / $_1000 * $_1000;
}

sub get_devices {
    my $class = shift;
    if ( not Image::Sane->init ) { return }
    my ( $status, @devices ) = _get_devices();
    _throw_error($status);
    return @devices;
}

END {
    _exit();
}

1;
__END__

=head1 NAME

Image::Sane - Perl extension for the SANE (Scanner Access Now Easy)
Project

=head1 VERSION

0.10

=head1 SYNOPSIS

  use Image::Sane;
  my @devices = Image::Sane->get_devices;
  my $device = Image::Sane::Device->open($devices[0]->{name});
  my $param = $device->get_parameters;
  $device->write_pnm_header($fh, $param);
  my ($data, $len) = $device->read ($param->{bytes_per_line});
  print $fh $data;

=head1 DESCRIPTION

These Perl bindings for the SANE (Scanner Access Now Easy) Project
allow you to access SANE-compatible scanners in a Perlish and
object-oriented way, freeing you from the casting and memory management in C,
yet remaining very close in spirit to original API.

Find out more about SANE at L<http://www.sane-project.org>.

=head1 SUBROUTINES/METHODS

=head2 Image::Sane->get_version

Returns an array with the SANE_VERSION_(MAJOR|MINOR|BUILD) versions:

  join('.', Image::Sane->get_version)

=head2 Image::Sane->get_version_scalar

Returns an scalar with the SANE_VERSION_(MAJOR|MINOR|BUILD) versions combined
as per the Perl version numbering, i.e. sane 1.0.19 gives 1.000019. This allows
simple version comparisons.

=head2 Image::Sane->get_devices

This function can be used to query the list of devices that are available.
If the function executes successfully,
it returns a array of hash references with the devices found.
The returned list is guaranteed to remain valid until
(a) another call to this function is performed or
(b) a call to sane_exit() is performed.
This function can be called repeatedly to detect when new devices become
available.

If argument local_only is true, only local devices are returned
(devices directly attached to the machine that SANE is running on).
If it is false, the device list includes all remote devices that are accessible
to the SANE library.

  try {
      @devices = Image::Sane->get_devices;
      print "Name: $devices[0]->{name}\n";
      print "Vendor: $devices[0]->{vendor}\n";
      print "Model: $devices[0]->{model}\n";
      print "Type: $devices[0]->{type}\n";
  }
  catch {
      print "Error getting devices:", $_->error, "\n";
  };

=head2 Image::Sane::Device->open

This function is used to establish a connection to a particular device.
The name of the device to be opened is passed in argument name.
If the call completes successfully, a Image::Sane::Device object is returned.
As a special case, specifying a zero-length string as the device requests
opening the first available device (if there is such a device).

  my $device = Image::Sane::Device->open($device_name);

=head2 Image::Sane::Device->get_option_descriptor

This function is used to access option descriptors.
The function returns a hash reference with the option descriptor for
option number n of the Image::Sane::Device object.
Option number 0 is guaranteed to be a valid option.
Its value is an integer that specifies the number of
options that are available for the Image::Sane::Device object (the count includes
option 0). If n is not a valid option index, the function croaks.

  try {
      $option = $device->get_option_descriptor($n);
      print "Name: $option->{name}\n";
      print "Name: $option->{title}\n";
      print "Name: $option->{desc}\n";
      print "Name: $option->{type}\n";
      print "Name: $option->{unit}\n";
      print "Name: $option->{cap}\n";
      print "Name: $option->{max_values}\n";
      print "Name: $option->{constraint_type}\n";
  }
  catch {
      print "Error getting option descriptor:", $_->error, "\n";
  };

The contents of the hash keys "name", "title", "desc", "type", "unit", "cap" and
"constraint_type"
are as per the C API description (L<http://www.sane-project.org/html>). There
is a further constraint key that either contains an array with the possible
option values, or a hash with keys "max", "min", and "quant".

The max_values key replaced the size key in the C API, and contains the maximum
number of values that the option may contain.

=head2 Image::Sane::Device->get_option

Returns the current value of the selected option.

  try {
      $value = $device->get_option($n);
      print "value: $value\n";
  }
  catch {
      print "Error getting option:", $_->error, "\n";
  };

For $option->{max_values} > 1, $value is a reference to an array.

=head2 Image::Sane::Device->set_auto

Commands the selected device to automatically select an appropriate value.
This mode remains effective until overridden by an explicit set_option request.

  $device->set_auto($n);

=head2 Image::Sane::Device->set_option

Sets the selected option, returning flags in $info, which are described in the
C API (L<http://www.sane-project.org/html>).

  $orig = $device->get_option($n);
  $info = $device->set_option($n, $value);
  if ($info & SANE_INFO_INEXACT) {
   $value = $device->get_option($n);
   print "rounded value of $opt->{name} from $orig to $value\n";
  }

For $option->{max_values} > 1, $value can be a reference to an array.

=head2 Image::Sane::Device->get_parameters

This function is used to obtain the current scan parameters.
The returned parameters are guaranteed to be accurate between the time
a scan has been started (Image::Sane::Device->start() has been called) and the
completion of that request. Outside of that window, the returned values
are best-effort estimates of what the parameters will be when
Image::Sane::Device->start() gets invoked. Calling this function before a scan
has actually started allows, for example, to get an estimate of how big
the scanned image will be.

  try {
      $param = $device->get_parameters;
      print "format $param->{format}\n";
      print "last_frame $param->{last_frame}\n";
      print "bytes_per_line $param->{bytes_per_line}\n";
      print "pixels_per_line $param->{pixels_per_line}\n";
      print "lines $param->{lines}\n";
      print "depth $param->{depth}\n";
  }
  catch {
      print "Error getting parameters:", $_->error, "\n";
  };

Please see the C documentation (L<http://www.sane-project.org/html>)
for details of the above values.

=head2 Image::Sane::Device->start

This function initiates acquisition of an image from the device specified.

  $device->start;

=head2 Image::Sane::Device->read

This function is used to read image data from the device specified.
The number of bytes returned in $buf is stored in $len.
A backend must set this to zero when an error is thrown.
if the call succeeds, the number of
bytes returned can be anywhere in the range from 0 to $maxlen bytes.

  $param = $device->get_parameters;
  $maxlen = $param->{bytes_per_line};
  ($buf, $len) = $test->read ($maxlen);

If this function is called when no data is available, one of two
things may happen, depending on the I/O mode that is in effect for the
device.

=over

=item 1. If the device is in blocking I/O mode (the default mode), the
call blocks until at least one data byte is available (or
until some error occurs).

=item 2. If the device is in non-blocking I/O mode, the call returns
immediately with $len set to zero. 

=back

The I/O mode of the device can be set via a call to
Image::Sane::Device->set_io_mode(). 

=head2 Image::Sane::Device->cancel

This function is used to immediately or as quickly as possible cancel
the currently pending operation of the device.

  $device->cancel;

This function can be called at any time (as long as $device is valid)
but usually affects long-running operations only (such as image is
acquisition). It is safe to call this function asynchronously
(e.g., from within a signal handler). It is important to note that
completion of this operation does not imply that the currently pending
operation has been cancelled. It only guarantees that cancellation
has been initiated. Cancellation completes only when the cancelled
call throws an exception (typically with a status value of SANE_STATUS_CANCELLED).
Since the SANE API does not require any other operations to be
re-entrant, this implies that a frontend must not call any other
operation until the cancelled operation has returned. 

=head2 Image::Sane::Device->set_io_mode

This function is used to set the I/O mode of the device. The I/O mode
can be either blocking or non-blocking. If argument $bool is
SANE_TRUE, the mode is set to non-blocking mode, otherwise it's set to
blocking mode. This function can be called only after a call to
Image::Sane::Device->start() has been performed.

  $device->set_io_mode ($bool);

By default, newly opened handles operate in blocking mode. A backend
may elect not to support non-blocking I/O mode. In such a case the
call throws an exception with the status value SANE_STATUS_UNSUPPORTED. Blocking I/O must
be supported by all backends, so calling this function with
SANE_FALSE is guaranteed to complete successfully.

=head2 Image::Sane::Device->get_select_fd

This function is used to obtain a (platform-specific) file-descriptor
for the device that is readable if and only if image data is available
(i.e., when a call to Image::Sane::Device->read() will return at least one
byte of data).

  $fd = $device->get_select_fd;

This function can be called only after a call to Image::Sane::Device->start()
has been performed and the returned file-descriptor is guaranteed to
remain valid for the duration of the current image acquisition (i.e.,
until Image::Sane::Device->cancel() or Image::Sane::Device->start() is called again
or until Image::Sane::Device->read() throws an exception with status SANE_STATUS_EOF).
Indeed, a backend must guarantee to close the returned select file
descriptor at the point when the next Image::Sane::Device->read() call would
throw an exception with SANE_STATUS_EOF. This is necessary to ensure the application
can detect when this condition occurs without actually having to call
Image::Sane::Device->read().

A backend may elect not to support this operation. In such a case,
the function throws an exception with status code SANE_STATUS_UNSUPPORTED.

Note that the only operation supported by the returned file-descriptor
is a host operating-system dependent test whether the file-descriptor
is readable (e.g., this test can be implemented using select() or
poll() under UNIX). If any other operation is performed on the file
descriptor, the behaviour of the backend becomes unpredictable.
Once the file-descriptor signals ``readable'' status, it will remain
in that state until a call to sane_read() is performed. Since many
input devices are very slow, support for this operation is strongly
encouraged as it permits an application to do other work while image
acquisition is in progress.

=head2 Image::Sane::Device->write_pnm_header

This function is a pure-Perl helper function to write a PNM header. It
will fetch the current image settings using Image::Sane::Device->get_parameters,
if they are not already provided, e.g.:

 $device->write_pnm_header($fh);

or

 $parm = $device->get_parameters;
 $device->write_pnm_header ($fh, $parm->{format}, 
                                 $parm->{pixels_per_line},
                                 $parm->{lines}, $parm->{depth});

=head1 DIAGNOSTICS

If the underlying SANE library returns a status value other than
SANE_STATUS_GOOD, an exception is thrown. It is therefore suggested that these
are caught using the Try::Tiny module. $_->status and $_->error can be used
within the catch{} clause to give the status code and its equivalent string.

=head1 CONFIGURATION AND ENVIRONMENT

This module does not require any special configuration or environment, beyond
that needed for Perl and SANE.

=head1 DEPENDENCIES

=over

=item Obviously, the SANE library is required, together with the backends for
the scanners to be used.

=item Exception::Class is used for throwing exceptions. It is suggested that
these are caught with Try::Tiny.

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

The SANE Standard Reference L<http://www.sane-project.org/html> is a handy
companion. The Perl bindings follow the C API very closely, and the C reference
documentation should be considered the canonical source.

=head1 AUTHOR

Jeffrey Ratcliffe, E<lt>jffry@posteo.netE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008--2017 by Jeffrey Ratcliffe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
