package Graphics::SANE;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Graphics::SANE ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	SANE_STATUS_ACCESS_DENIED
	SANE_STATUS_CANCELLED
	SANE_STATUS_COVER_OPEN
	SANE_STATUS_DEVICE_BUSY
	SANE_STATUS_EOF
	SANE_STATUS_GOOD
	SANE_STATUS_INVAL
	SANE_STATUS_IO_ERROR
	SANE_STATUS_JAMMED
	SANE_STATUS_NO_DOCS
	SANE_STATUS_NO_MEM
	SANE_STATUS_UNSUPPORTED
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Graphics::SANE::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Graphics::SANE', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Graphics::SANE - Perl extension for the Sane scanner access library.

=head1 SYNOPSIS

  use Graphics::SANE;

  # initialize the Sane library
  $version_info = Graphics::SANE::init;

  # get a list of devices
  @devices = Graphics::SANE::device_list;

  # open a scanner
  $handle = Graphics::SANE::open($scanner_name);

  # retrieve the number of defined options
  $cnt = $handle->get_option_value(0);

  # get option descriptors and values, set new values
  for $i (1..$cnt-1) {
     $optdesc = $handle->get_option_descriptor($i);
     $value = $handle->get_option_value($i);
     $status = $handle->set_option_value($i,$newvalue);
  }

  # start scanning
  $handle->start;

  # get data format information
  $p = $handle->get_parameters;

  # read data and write to a file
  open $fh,">","filename";
  while ($b = $handle->read($p->{bytes_per_line})) {
     print $fh $b;
  }
  print $Graphics::SANE::errstr
      unless $Graphics::SANE::err == Graphics::SANE::SANE_STATUS_EOF;
  close $fh;

  # finish reading data
  $handle->cancel;

  # close the scanner
  $handle->close();

  # finish using the Sane library
  Graphics::SANE::exit;

=head1 DESCRIPTION

The Sane module provides access to the Sane scanner access library.

=head2 EXPORT

None by default.

=head2 Exportable constants

  SANE_STATUS_ACCESS_DENIED
  SANE_STATUS_CANCELLED
  SANE_STATUS_COVER_OPEN
  SANE_STATUS_DEVICE_BUSY
  SANE_STATUS_EOF
  SANE_STATUS_GOOD
  SANE_STATUS_INVAL
  SANE_STATUS_IO_ERROR
  SANE_STATUS_JAMMED
  SANE_STATUS_NO_DOCS
  SANE_STATUS_NO_MEM
  SANE_STATUS_UNSUPPORTED

=head1 methods

=head2 init

The C<init> routine initializes the Sane library and returns backend
version information.  It returns a hashref containing the attributes
"major", "minor", and "build".

=head2 exit

This routine frees up resources in the Sane library.

=head2 get_devices

Returns a list of hashrefs describing available scanner devices.  Each
hashref contains the attributes "name", "vendor", "model" and "type".
The "name" attribute can be passed to C<open> to access the device.

=head2 open("name")

Accepts a device name and returns a handle.  The handle is an object
blessed into the Graphics::SANE::Handle package.

=head1 Graphics::SANE::Handle methods

These methods are valid for Graphics::SANE::Handle objects.

=head2 get_option_description(index)

Accepts an option index and returns a descriptor for the option.  The
descriptor is a hashref containing the following attributes.

=over 4

=item index

The option's index.

=item name

The name of the option.  This may be blank.

=item title

The title of the option.  This can be used as a prompt or as a label for
a control in a graphical interface.

=item desc

A description for the option.

=item unit

Describes the unit for the option.  This is one of "none", "pixel",
"bit", "mm", "dpi", "percent", or "microsecond".

=item type

Describes the data type of the option.  This is one of "bool", "int",
"fixed", "string", "button", or "group".

=item size

The size of the option's value.

=item soft_select

A boolean indicating that the option is software selectable.

=item hard_select

A boolean indicating that the option is selectable by a hardware
control.

=item emulated

A boolean indicating that the backend emulates this setting.

=item automatic

A boolean indicating that the option has been set to automatic.

=item inactive

A boolean indicating that the option is inactive due to other
settings.

=item advanced

A boolean indicating that the item should be considered an advanced
control.

=item constraint

A string describing how the option's value is constrained.  May be
"none", "range", "word_list", or "string_list".

=item min

The minimum value of the control.  This attribute only appears if the
constraint is "range".

=item max

The maximum value of the control.  This attribute only appears if the
constraint is "range".

=item quant

The unit of increment between min and max.  This attribute only
appears if the constraint type is "range".

=item word_list

A list of valid numeric values for the option.  This attribute only
appears if the constraint is "word_list".

=item string_list

A list of valid string values for the option.  This attribute only
appears if the constraint is "string_list".

=back

=item get_option_value(index)

Accepts an index and returns the value for the option with that index.

=item set_option_value(index,value)

Accepts an index and a value.  Sets the value of the option with that
index.  The returned value will be a hashref containing three
booleans.  If "INEXACT" is true, it means the backend could not use
the supplied value exactly and an approximate value was used.  If
"RELOAD_OPTIONS" is true, some other options may have changed their
active states and should be requeried.  If "RELOAD_PARAMS" is true,
the values that would be returned by C<get_params> may have changed.

=item start

Begins the scan operation.

=item get_parameters

Returns a hashref containing information about the graphics image that
would be returned by the backend.  The hash contains the following
values:

=over 4

=item format

Describes the image format.  This will be one of "gray", "rgb", "red",
"green", or "blue".

=item last_frame

This will be set true if the current frame of data being read will be
the last.

=item lines

Returns the number of lines of graphics information in the image.

=item depth

Returns the bit depth of the image.

=item pixels_per_line

Returns the number of pixels in a line of image data.

=item bytes_per_line

Returns the number of bytes in a line of image data.

=back

=item read(int)

Accepts the number of bytes to read.  Reads up to the requested length
in bytes from the device and returns the data read.

=item cancel

Tells the backend that the application is finished reading data from
the device.

=item close

Closes the device.

=head1 ERRORS

All of the routines check the status returned by the Sane library
routine.  If the call is successful, the routine will return the
information described above or a true value.  If an error occurs, the
routine will store the status code in the package variable
C<$Graphics::SANE::err> and will store the string translation of the
code in C<$Graphics::SANE::errstr>.

=head1 SEE ALSO

Sane information is available at the Sane project's website
L<http://www.sane-project.org/>.

=head1 AUTHOR

Thomas Pfau, E<lt>pfau@nbpfaus.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Thomas Pfau

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
