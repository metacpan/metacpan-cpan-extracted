use strict;
use warnings;

package Device::PCA9685;

# PODNAME: Device::PCA9685
# ABSTRACT: I2C interface to PCA9685 16 channel 12 bit PWM Generator
#
# This file is part of Device-PCA9685
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.004'; # VERSION

# Dependencies
use 5.010;
use Moose;
use POSIX;

use Device::PWMGenerator::PCA9685;


has 'I2CBusDevicePath' => ( is => 'ro', );


has PWMGenerator => (
    is         => 'ro',
    isa        => 'Device::PWMGenerator::PCA9685',
    lazy_build => 1,
);

sub _build_PWMGenerator {
    my ($self) = @_;
    my $obj = Device::PWMGenerator::PCA9685->new(
        I2CBusDevicePath => $self->I2CBusDevicePath,
        frequency        => 400,
        debug            => 0,
    );
    return $obj;
}

1;

__END__

=pod

=head1 NAME

Device::PCA9685 - I2C interface to PCA9685 16 channel 12 bit PWM Generator



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Device-PCA9685"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Device-PCA9685.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Device-PCA9685%200.004"><img src="https://badgedepot.code301.com/badge/cpantesters/Device-PCA9685/0.004" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Device-PCA9685-0.004"><img src="https://badgedepot.code301.com/badge/kwalitee/Device-PCA9685/0.004" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.004

=head1 SYNOPSIS

     use Device::PWMGenerator::PCA9685;
 
     my $dev = Device::PWMGenerator::PCA9685->new(
         I2CBusDevicePath => '/dev/i2c-1', # this would be '//dev/i2c-dev-0 for Model A Pi
         debug            => 1,
         frequency        => 400, #Hz
     );
     $dev->enable();
     $dev->setChannelPWM(4,0,$dutycycle); # Duty cycle values between 0 and 4096 channel 4

=head1 DESCRIPTION

This module provides a Object oriented interface to Adafruit 16 channel 12 bit
PWM Generator(PCA9685). Before you use this module make sure you follow install
Prerequisites for L<Device::SMBus>

=head1 ATTRIBUTES

=head2 I2CBusDevicePath

this is the device file path for your I2CBus that the PCA9685 is connected on e.g. /dev/i2c-1
This must be provided during object creation.

=head2 PWMGenerator 

    $self->PWMGenerator->enable();
    $self->PWMGenerator->setChannelPWM($channel,$pulseOnPoint,$pulseOffPoint);

The PCA9685 offers a 12 bit resolution which means across a duty cycle you may set and unset the PWM at 4096 different point. 
Range of values for $pulseOnPoint and $pulseOffPoint is 0 to 4095
Range of values of $channel is 0 to 15

This is a object of L<Device::PWMGenerator::PCA9685>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-device-pca9685/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-device-pca9685>

  git clone git://github.com/shantanubhadoria/perl-device-pca9685.git

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
