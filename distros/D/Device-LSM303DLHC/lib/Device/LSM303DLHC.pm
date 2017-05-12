use strict;
use warnings;

package Device::LSM303DLHC;

# PODNAME: Device::LSM303DLHC
# ABSTRACT: I2C interface to LSM303DLHC 3 axis magnetometer(compass) and accelerometer using Device::SMBus
#
# This file is part of Device-LSM303DLHC
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.014'; # VERSION

# Dependencies
use 5.010;
use Moose;
use POSIX;

use Device::SMBus;
use Device::Magnetometer::LSM303DLHC;
use Device::Accelerometer::LSM303DLHC;


has 'I2CBusDevicePath' => (
    is       => 'ro',
    required => 1,
);


has Magnetometer => (
    is         => 'ro',
    isa        => 'Device::Magnetometer::LSM303DLHC',
    lazy_build => 1,
);

sub _build_Magnetometer {
    my ($self) = @_;
    my $obj =
      Device::Magnetometer::LSM303DLHC->new(
        I2CBusDevicePath => $self->I2CBusDevicePath );
    return $obj;
}


has Accelerometer => (
    is         => 'ro',
    isa        => 'Device::Accelerometer::LSM303DLHC',
    lazy_build => 1,
);

sub _build_Accelerometer {
    my ($self) = @_;
    my $obj =
      Device::Accelerometer::LSM303DLHC->new(
        I2CBusDevicePath => $self->I2CBusDevicePath );
    return $obj;
}

1;

__END__

=pod

=head1 NAME

Device::LSM303DLHC - I2C interface to LSM303DLHC 3 axis magnetometer(compass) and accelerometer using Device::SMBus



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Device-LSM303DLHC"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Device-LSM303DLHC.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Device-LSM303DLHC%200.014"><img src="https://badgedepot.code301.com/badge/cpantesters/Device-LSM303DLHC/0.014" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Device-LSM303DLHC-0.014"><img src="https://badgedepot.code301.com/badge/kwalitee/Device-LSM303DLHC/0.014" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.014

=head1 ATTRIBUTES

=head2 I2CBusDevicePath

this is the device file path for your I2CBus that the LSM303DLHC is connected on e.g. /dev/i2c-1
This must be provided during object creation.

=head2 Magnetometer

    $self->Magnetometer->enable();
    $self->Magnetometer->getReading();

This is a object of L<Device::Magnetometer::LSM303DLHC>

=head2 Accelerometer 

    $self->Accelerometer->enable();
    $self->Accelerometer->getReading();

This is a object of L<Device::Accelerometer::LSM303DLHC>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-device-lsm303dlhc/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-device-lsm303dlhc>

  git clone git://github.com/shantanubhadoria/perl-device-lsm303dlhc.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 CONTRIBUTOR

=for stopwords Shantanu

Shantanu <shantanu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
