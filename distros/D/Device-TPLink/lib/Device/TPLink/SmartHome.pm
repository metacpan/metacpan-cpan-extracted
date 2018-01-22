package Device::TPLink::SmartHome;

use 5.008003;
use Moose;
use Carp;
use JSON;

=head1 NAME

Device::TPLink::SmartHome - Base class for TPLink Smart Home devices

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has 'fwVer' => ( #"1.1.0 Build 160521 Rel.085826"
  is => 'rw',
  isa => 'Str',
);

has 'deviceName' => ( #"Wi-Fi Smart Light Switch"
  is => 'rw',
  isa => 'Str',
);

has 'status' => ( #1
  is => 'rw',
  isa => 'Bool',
);

has 'alias' => ( #"Downstairs Hall Light"
  is => 'rw',
  isa => 'Str',
);

has 'deviceType' => ( #"IOT.SMARTPLUGSWITCH"
  is => 'rw',
  isa => 'Str',
);

has 'appServerUrl' => ( #"https://use1-wap.tplinkcloud.com"
  is => 'rw',
  isa => 'Str',
);

has 'deviceModel' => ( #"HS200(US)"
  is => 'rw',
  isa => 'Str',
);

has 'deviceMac' => ( #"50C7BFDAA810"
  is => 'rw',
  isa => 'Str',
);

has 'role' => ( #0
  is => 'rw',
  isa => 'Int',
);

has 'isSameRegion' => ( #true
  is => 'rw',
#  isa => 'Str',
);

has 'hwId' => ( #"A0E3CC8F5C1166B27A16D56BE262A6D3"
  is => 'rw',
  isa => 'Str',
);

has 'fwId' => ( #"DB4F3246CD85AA59CAE738A63E7B9C34"
  is => 'rw',
  isa => 'Str',
);

has 'oemId' => ( #"4AFE44A41F868FD2340E6D1308D8551D"
  is => 'rw',
  isa => 'Str',
);

has 'deviceId' => ( #"80067C57DCE0C1677948ADA728421F6418BFC029"
  is => 'rw',
  isa => 'Str',
);

has 'deviceHwVer' => ( #"1.0"
  is => 'rw',
  isa => 'Str',
);


=head1 SYNOPSIS

You're probably in the wrong place. This module is extended by Device::TPLink::SmartHome::Kasa and Device::TPLink::SmartHome::Direct to communicate with smart home devices and issue commands.

=head1 SUBROUTINES/METHODS

=head2 on

Turns the device on.

=cut

sub on { # Turn on or off the light...
  my $requestData = { system => { set_relay_state => { state => 1 }}};
  return $requestData;
}

=head2 off

Turns the device off.
=cut

sub off {
  my $requestData = { system => { set_relay_state => { state => 0 }}};
  return $requestData;
}

=head2 getSystemInfo

Returns an object containing information about the current state of the device. TODO: Use returned info to populate device object.
=cut

sub getSystemInfo {# Get relay state?
  my $requestData = { system => { get_sysinfo => {}}};
  return $requestData;
}

=head2 reboot

Reboots the device with a 1 second delay.

=cut

sub reboot {
  my $requestData = { system => { reboot => { delay => 1 }}};
  return $requestData;
}

sub TO_JSON { return { %{ shift() } }; }



=head1 AUTHOR

Verlin Henderson, C<< <verlin at gmail.com> >>

=head1 BUGS / SUPPORT

To report any bugs or feature requests, please use the github issue tracker: L<https://github.com/verlin/Device-TPLink/issues>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Verlin Henderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Device::TPLink::SmartHome
