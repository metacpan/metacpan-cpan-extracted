use strict;
use warnings;

package Device::LPS331AP;

# PODNAME: Device::LPS331AP
# ABSTRACT: I2C interface to LPS331AP Thermometer and Barometer using Device::SMBus
#
# This file is part of Device-LPS331AP
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.006'; # VERSION

# Dependencies
use 5.010;
use Moose;
use POSIX;

use Device::Altimeter::LPS331AP;


has 'I2CBusDevicePath' => ( is => 'ro', );


has Altimeter => (
    is         => 'ro',
    isa        => 'Device::Altimeter::LPS331AP',
    lazy_build => 1,
);

sub _build_Altimeter {
    my ($self) = @_;
    my $obj =
      Device::Altimeter::LPS331AP->new(
        I2CBusDevicePath => $self->I2CBusDevicePath );
    return $obj;
}

1;

__END__

=pod

=head1 NAME

Device::LPS331AP - I2C interface to LPS331AP Thermometer and Barometer using Device::SMBus



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Device-LPS331AP"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Device-LPS331AP.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Device-LPS331AP%200.006"><img src="https://badgedepot.code301.com/badge/cpantesters/Device-LPS331AP/0.006" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Device-LPS331AP-0.006"><img src="https://badgedepot.code301.com/badge/kwalitee/Device-LPS331AP/0.006" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 I2CBusDevicePath

this is the device file path for your I2CBus that the LPS331AP is connected on e.g. /dev/i2c-1
This must be provided during object creation.

=head2 Altimeter

    $self->Altimeter->enable();
    $self->Altimeter->getReading();

This is a object of L<Device::Altimeter::LPS331AP>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-device-lps331ap/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-device-lps331ap>

  git clone git://github.com/shantanubhadoria/perl-device-lps331ap.git

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
