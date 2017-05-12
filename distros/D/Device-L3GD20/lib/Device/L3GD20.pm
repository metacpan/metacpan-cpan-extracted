use strict;
use warnings;

package Device::L3GD20;

# PODNAME: Device::L3GD20
# ABSTRACT: I2C interface to L3GD20 3 axis GyroScope using Device::SMBus
#
# This file is part of Device-L3GD20
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.010'; # VERSION

# Dependencies
use 5.010;
use Moose;
use POSIX;

use Device::Gyroscope::L3GD20;


has 'I2CBusDevicePath' => ( is => 'ro', );


has Gyroscope => (
    is         => 'ro',
    isa        => 'Device::Gyroscope::L3GD20',
    lazy_build => 1,
);

sub _build_Gyroscope {
    my ($self) = @_;
    my $obj =
      Device::Gyroscope::L3GD20->new(
        I2CBusDevicePath => $self->I2CBusDevicePath, );
    return $obj;
}

1;

__END__

=pod

=head1 NAME

Device::L3GD20 - I2C interface to L3GD20 3 axis GyroScope using Device::SMBus



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Device-L3GD20"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Device-L3GD20.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Device-L3GD20%200.010"><img src="https://badgedepot.code301.com/badge/cpantesters/Device-L3GD20/0.010" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Device-L3GD20-0.010"><img src="https://badgedepot.code301.com/badge/kwalitee/Device-L3GD20/0.010" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 I2CBusDevicePath

this is the device file path for your I2CBus that the L3GD20 is connected on e.g. /dev/i2c-1
This must be provided during object creation.

=head2 Gyroscope

    $self->Gyroscope->enable();
    $self->Gyroscope->getReading();

This is a object of L<Device::Gyroscope::L3GD20>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-device-l3gd20/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-device-l3gd20>

  git clone git://github.com/shantanubhadoria/perl-device-l3gd20.git

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
