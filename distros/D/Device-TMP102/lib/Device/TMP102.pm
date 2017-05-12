use strict;
use warnings;

package Device::TMP102;

our $VERSION = '0.0.8'; # VERSION

use Moose;
use POSIX;

use Device::Temperature::TMP102;


has 'I2CBusDevicePath' => ( is => 'ro', );


has Temperature => (
    is         => 'ro',
    isa        => 'Device::Temperature::TMP102',
    lazy_build => 1,
);

sub _build_Temperature {
    my ($self) = @_;
    my $obj = Device::Temperature::TMP102->new(
        I2CBusDevicePath => $self->I2CBusDevicePath,
        debug            => 0,
    );
    return $obj;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Device::TMP102 - I2C interface to TMP102 temperature sensor

=head1 DESCRIPTION

See L<Device::Temperature::TMP102> for more information.

=head1 VERSION

=head1 ATTRIBUTES

=head2 I2CBusDevicePath

this is the device file path for your I2CBus that the TMP102 is connected on e.g. /dev/i2c-1
This must be provided during object creation.

=head2 Temperature

    $self->Temperature->getTemp();

This is a object of L<Device::Temperature::TMP102>

=head1 LICENSE

This software is Copyright (c) 2014 by Alex White.

This is free software, licensed under:

  The (three-clause) BSD License

The BSD License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

  * Neither the name of Alex White nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
