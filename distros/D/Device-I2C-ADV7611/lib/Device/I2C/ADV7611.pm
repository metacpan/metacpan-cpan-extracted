use strict;
use warnings;

package Device::I2C::ADV7611;

# PODNAME: Device::I2C::ADV7611
# ABSTRACT: I2C interface to ADV7611 using Device::I2C
#
# This file is part of Device-I2C-ADV7611
#
# This software is copyright (c) 2016 by Slava Volkov.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.11'; # VERSION

# Dependencies
use 5.010;
use Device::I2C;
use Fcntl;
use Carp;

use constant CTRL_IO   => 0x4c;
use constant CTRL_HDMI => 0x34;
use constant CTRL_DPLL => 0x3F;
use constant CTRL_CEC  => 0x40;
use constant CTRL_INFO => 0x3E;
use constant CTRL_KSV  => 0x32;
use constant CTRL_EDID => 0x36;
use constant CTRL_CP   => 0x22;

use Exporter qw(import);
our @EXPORT_OK = qw(CTRL_IO CTRL_HDMI CTRL_DPLL CTRL_CEC
  CTRL_INFO CTRL_KSV CTRL_EDID CTRL_CP );
our @ISA = qw(Device::I2C);

sub new {
    my $class = shift;
    @_ == 1
      or croak "usage: $class->new(DEVICENAME)";
    my $io = Device::I2C->new( $_[0], O_RDWR );
    if ( !$io ) {
        croak "Unable to open I2C Device File at $_[0]";
        return undef;
    }
    bless( $io, $class );
    $io;
}

sub resetDevice {
    `echo 0 > /proc/v2r_gpio/98`;
    `echo 1 > /proc/v2r_gpio/98`;
    `echo 0 > /proc/v2r_gpio/99`;
    `echo 1 > /proc/v2r_gpio/99`;
    `echo 0 > /proc/v2r_gpio/pwctr2`;
    sleep(1);
    `echo 1 > /proc/v2r_gpio/pwctr2`;
}

sub writeRegister {
    my ( $io, $addr, $register, $value ) = @_;
    $io->selectDevice($addr);
    $io->writeByteData( $register, $value );
}

sub readRegister {
    my ( $io, $addr, $register ) = @_;
    $io->selectDevice($addr);
    return $io->readByteData($register);
}

sub readRegister16 {
    my ( $io, $addr, $register ) = @_;
    $io->selectDevice($addr);
    my $res = $io->readByteData($register);
    $res <<= 8;
    return $res + $io->readByteData( $register + 1 );
}

sub writeIO {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_IO, $register, $value );
}

sub readIO {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_IO, $register );
}

sub readIO16 {
    my ( $io, $register ) = @_;
    $io->readRegister16( CTRL_IO, $register );
}

sub writeHDMI {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_HDMI, $register, $value );
}

sub readHDMI {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_HDMI, $register );
}

sub readHDMI16 {
    my ( $io, $register ) = @_;
    $io->readRegister16( CTRL_HDMI, $register );
}

sub writeDPLL {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_DPLL, $register, $value );
}

sub readDPLL {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_DPLL, $register );
}

sub writeCEC {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_CEC, $register, $value );
}

sub readCEC {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_CEC, $register );
}

sub writeINFO {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_INFO, $register, $value );
}

sub readINFO {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_INFO, $register );
}

sub writeKSV {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_KSV, $register, $value );
}

sub readKSV {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_KSV, $register );
}

sub writeEDID {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_EDID, $register, $value );
}

sub readEDID {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_EDID, $register );
}

sub writeCP {
    my ( $io, $register, $value ) = @_;
    $io->writeRegister( CTRL_CP, $register, $value );
}

sub readCP {
    my ( $io, $register ) = @_;
    $io->readRegister( CTRL_CP, $register );
}

sub readCP16 {
    my ( $io, $register ) = @_;
    $io->readRegister16( CTRL_CP, $register );
}

sub initAddressMaps {
    my ($io) = @_;

    $io->writeIO( 0xfd, CTRL_CP << 1 );
    $io->writeIO( 0xf9, CTRL_KSV << 1 );
    $io->writeIO( 0xfb, CTRL_HDMI << 1 );
    $io->writeIO( 0xfa, CTRL_EDID << 1 );
    $io->writeIO( 0xf8, CTRL_DPLL << 1 );
    $io->writeIO( 0xf4, CTRL_CEC << 1 );
    $io->writeIO( 0xf5, CTRL_INFO << 1 );
}

sub writeEDIDTable {
    my ( $io, @edid ) = @_;
    my $err;

    $io->writeKSV( 0x40, 0x81 );    # Disable HDCP 1.1
    $io->writeKSV( 0x74, 0x00 );    # disable internal EDID

    my $count = @edid;
    printf( "Write edid data %d bytes\n", $count );

    for ( my $i = 0 ; $i < $count ; $i++ ) {

        #printf("EDID %x, %x\n", $i, $edid[$i]);
        $err = $io->writeEDID( $i, $edid[$i] );
        if ( $err < 0 ) {
            printf("fail to write edid data\n");
            return;

            # ADV761x calculates the checksums and enables I2C access
            # to internal EDID ram from DDC port.
        }
    }

    $io->writeKSV( 0x74, 0x01 );    # enable internal EDID
    $io->writeIO( 0x15, 0xBE );
}

# check line state
sub noPower {
    my ($io) = @_;
    return $io->readIO(0x0c) & 0x24;
}

sub checkCable {
    my ($io) = @_;
    return $io->readIO(0x6f) & 0x01;
}

sub isHDMI {
    my ($io) = @_;
    return $io->readHDMI(0x05) & 0x80;
}

sub isDERegenFilterLocked {
    my ($io) = @_;
    return $io->readHDMI(0x07) & 0x20;
}

sub isVertFilterLocked {
    my ($io) = @_;
    return $io->readHDMI(0x07) & 0x80;
}

sub isFiltersLocked {
    my ($io) = @_;
    return $io->isDERegenFilterLocked() && $io->isVertFilterLocked();
}

sub isLockSTDI {
    my ($io) = @_;
    return $io->readCP(0xb1) & 0x80;
}

sub isTMDS {
    my ($io) = @_;
    return $io->readIO(0x6a) & 0x10;
}

sub isLockTMDS {
    my ($io) = @_;
    return $io->readIO(0x6a) & 0x43 == 0x43;
}

sub isInterlaced {
    my ($io) = @_;
    return $io->readIO(0x12) & 0x10;
}

sub isSignal {
    my ($io) = @_;
    my $res;
    $res = !$io->noPower();
    $res &&= $io->isLockSTDI();
    $res &&= $io->isTMDS();
    $res &&= $io->isLockTMDS();
}

sub isFreeRun {
    my ($io) = @_;
    return $io->readCP(0xff) & 0x10;
}

# HDMI signal params
sub getTotalWidth {
    my ($io) = @_;
    return $io->readHDMI16(0x1e) & 0x3fff;
}

sub getWidth {
    my ($io) = @_;
    return $io->readHDMI16(0x07) & 0x1fff;
}

sub getTotalHeight0 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x26) & 0x3fff ) / 2;
}

sub getTotalHeight1 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x28) & 0x3fff ) / 2;
}

sub getHeight0 {
    my ($io) = @_;
    return $io->readHDMI16(0x09) & 0x1fff;
}

sub getHeight1 {
    my ($io) = @_;
    return $io->readHDMI16(0x0b) & 0x1fff;
}

sub getHFrontPorch {
    my ($io) = @_;
    return $io->readHDMI16(0x20) & 0x1fff;
}

sub getHSync {
    my ($io) = @_;
    return $io->readHDMI16(0x22) & 0x1fff;
}

sub getHBackPorch {
    my ($io) = @_;
    return $io->readHDMI16(0x24) & 0x1fff;
}

sub getVFrontPorch0 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x2a) & 0x3fff ) / 2;
}

sub getVFrontPorch1 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x2c) & 0x3fff ) / 2;
}

sub getVSync0 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x2e) & 0x3fff ) / 2;
}

sub getVSync1 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x30) & 0x3fff ) / 2;
}

sub getVBackPorch0 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x32) & 0x3fff ) / 2;
}

sub getVBackPorch1 {
    my ($io) = @_;
    return ( $io->readHDMI16(0x34) & 0x3fff ) / 2;
}

sub getFPS1000 {
    my ($io) = @_;
    my $fps = $io->readCP16(0xb8) & 0x1fff;
    return 28636360 / 256 / $fps * 1000;
}

sub getTMDSFreq {
    my ($io) = @_;
    my $freq = $io->readHDMI16(0x51);
    my $frac = ( $freq & 0x7f ) / 128;
    return ( $freq >> 7 ) + $frac;
}

1;

__END__

=pod

=head1 NAME

Device::I2C::ADV7611 - I2C interface to ADV7611 using Device::I2C



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Device-I2C-ADV7611"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Device-I2C-ADV7611.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Device-I2C-ADV7611%200.11"><img src="https://badgedepot.code301.com/badge/cpantesters/Device-I2C-ADV7611/0.11" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Device-I2C-ADV7611-0.11"><img src="https://badgedepot.code301.com/badge/kwalitee/Device-I2C-ADV7611/0.11" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.11

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/sv99/perl-device-i2c-adv7611/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sv99/perl-device-i2c-adv7611>

  git clone git://github.com/sv99/perl-device-i2c-adv7611.git

=head1 AUTHOR

Slava Volkov <sv99@inbox.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Slava Volkov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
