package Device::HID::XS;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

# ABSTRACT: XS Wrapper around HIDAPI
# VERSION


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::HID::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    hid_init
    hid_exit
    hid_enumerate
    hid_free_enumeration
    hid_open
    hid_open_path
    hid_write
    hid_read_timeout
    hid_read
    hid_set_nonblocking
    hid_send_feature_report
    hid_get_feature_report
    hid_close
    hid_get_manufacturer_string
    hid_get_product_string
    hid_get_serial_number_string
    hid_get_indexed_string
    hid_error
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    hid_init
    hid_exit
    hid_enumerate
    hid_free_enumeration
    hid_open
    hid_open_path
    hid_write
    hid_read_timeout
    hid_read
    hid_set_nonblocking
    hid_send_feature_report
    hid_get_feature_report
    hid_close
    hid_get_manufacturer_string
    hid_get_product_string
    hid_get_serial_number_string
    hid_get_indexed_string
    hid_error
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Device::HID::XS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::HID::XS - XS Wrapper around HIDAPI

=head1 SYNOPSIS

  use Device::HID::XS qw(:all);

=head1 DESCRIPTION

See L<Device::HID> for a Perlish wrapper.

=head2 EXPORT

None by default.

=head2 Exportable constants

None.

=head2 Exportable functions

  hid_init
  hid_exit
  hid_enumerate
  hid_free_enumeration
  hid_open
  hid_open_path
  hid_write
  hid_read_timeout
  hid_read
  hid_set_nonblocking
  hid_send_feature_report
  hid_get_feature_report
  hid_close
  hid_get_manufacturer_string
  hid_get_product_string
  hid_get_serial_number_string
  hid_get_indexed_string
  hid_error

=head1 SEE ALSO

L<Alien::HIDAPI>

L<Device::HID>

=head1 AUTHOR

Ahmad Fatoum, E<lt>ahmad@a3f.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
