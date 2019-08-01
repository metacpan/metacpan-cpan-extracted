package Device::GBA;
use strict;
use warnings;
use integer;
use Time::HiRes;
use Device::Chip::Adapter::BusPirate v0.15;
use File::stat;
use Term::ProgressBar;

# ABSTRACT: Perl Interface to the Gameboy Advance
our $VERSION = '0.004'; # VERSION

use Carp;

=pod

=encoding utf8

=head1 NAME

Device::GBA - Perl Interface to the Gameboy Advance

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Device::GBA;

    my $gba = Device::GBA->new(buspirate => '/dev/ttyUSB0') or die "No such device!\n";
    $gba->upload('helloworld.gba');

=head1 DESCRIPTION

The Nintendo Gameboy Advance can either boot from cartridge or over link cable. The latter is caled multiboot mode and is basically SPI and a homebrew encoding scheme. Unfortunately, the Bus Pirate doesn't have a 100k SPI mode, so we are using 125000 instead. If you encounter problems with booting, use the next lower speed (30000) as bitrate.
This utility allows uploading multiboot GBA images via L<Device::Chip::Adapter>s. Don't forget to pass C<-specs=gba_mb.specs> to devkitARM GCC if you want to link a multiboot image. The package's C<share/> subdirectory contains an L<example Makefile|https://github.com/athreef/Device-GBA/blob/master/share/testimg/Makefile> for cross-compilation. The wiring is as follows:

    GBA     Bus Pirate
    SO  --> MISO
    SI  <-- MOSI
    CLK <-- CLK
    GND --- GND

(Note to myself:) The cable I made looks like this:

                             ___________________
    .--------GND (white)----/      .-------._  |
    |  .-----SD (black)------------|SD (B) |_  |
    |  |  .--SO (yellow)---,      -|SC (R) |_--+-.
   _|__|__|_                \     -|GND (W)|_--' |
  / 6  4  2 \                \____-|SO (Y) |_    |
  \_5_ 3 _1_/                  ___-|SI (O) |_    |
    | \_/ '-- VDD (n/a)       /    '-------'     |
    |  '----- SI (orange) ---/                   |
    '-------- SC (red) --------------------------'


Note: This is still work in progress!

=head1 METHODS AND ARGUMENTS

=over 4

=item new()

Opens specified device and returns the corresponding object reference. Returns undef
if an attempt to open the device has failed. Accepts following parameters:

=over 4

=item B<adapter>

An instance of L<Device::Chip::Adapter> capable of SPI communication.

=item B<verbose>

if true, methods on this instance will narrate what they're doing. Default is C<0>.

=back

=cut

sub new {
    my $class = shift;
    my $self = {
        verbose => 0,
        bitrate   => '125000',
        @_
    };

    $self->{log} = $self->{verbose} ? sub { printf shift . "\n", @_ } : sub { };

    enter_spi($self);

    bless $self, $class;
    return $self;
}

sub enter_spi
{
   my $self = shift;
   return if defined $self->{spi};

   $self->{spi} = $self->{adapter}->make_protocol("SPI")->get;
   $self->{spi}->configure(mode => 3, max_bitrate => $self->{bitrate})->get;
}

=item upload

    $gba->upload($firmware_file)

Reads in I<$firmware_file> and uploads it to the Gameboy Advance.

=cut

sub upload {
    my $self = shift;
    my $firmware = shift;

    open my $fh, "<:raw", $firmware or croak "Can't open file `$firmware': $!\n";
    $self->log(".....Opening GBA file readonly");

    my $fsize = stat($firmware)->size;
    $fsize = ($fsize+0x0f)&0xfffffff0;

    if($fsize > 256 * 1024)
    {
        croak ("Err: Max file size 256kB");
    }

    my $fcnt;

    $self->log(".....GBA file length 0x%08x", $fsize);
    $self->log("BusPirate(mstr) GBA(slave) ");

    $self->enter_spi;

    $self->spi_handshake(0x00006202, 0x72026202, "Looking for GBA");

    $self->spi_readwrite(0x00006202, "Found GBA");
    $self->spi_readwrite(0x00006102, "Recognition OK");

    my $progress = Term::ProgressBar->new({
            name   => 'Upload',
            count  => $fsize,
            ETA    => 'linear',
            silent => not $self->{verbose}
    });
    my $oldlog = $self->{log};
    $self->{log} = sub { $progress->message(sprintf shift, @_) } if $self->{verbose};

    local $/ = \2;
    for($fcnt = 0; $fcnt < 192; $progress->update($fcnt += 2)) {
        $self->spi_readwrite(unpack 'S<', <$fh>);
    }

    $self->spi_readwrite(0x00006200, "Transfer of header data complete");
    $self->spi_readwrite(0x00006202, "Exchange master/slave info again");

    $self->spi_readwrite(0x000063d1, "Send palette data");

    my $r = $self->spi_readwrite(0x000063d1, "Send palette data, receive 0x73hh****");

    my $m = (($r & 0x00ff0000) >>  8) + 0xffff00d1;
    my $h = (($r & 0x00ff0000) >> 16) + 0xf;

    $r = $self->spi_readwrite(((($r >> 16) + 0xf) & 0xff) | 0x00006400, "Send handshake data");
    $r = $self->spi_readwrite(($fsize - 0x190) / 4, "Send length info, receive seed 0x**cc****");

    my $f = ((($r & 0x00ff0000) >> 8) + $h) | 0xffff0000;
    my $c = 0x0000c387;

    local $/ = \4;
    for (; $fcnt < $fsize; $progress->update($fcnt += 4)) {
        my $chunk = <$fh> // '';
        $chunk .= "\0" x (4 - length $chunk);
        my $w = unpack('L<', $chunk);
        $c = crc($w, $c);
        $m = ((0x6f646573 * $m) & 0xFFFFFFFF) + 1;
        my $data = $w ^ ((~(0x02000000 + $fcnt)) + 1) ^ $m ^ 0x43202f2f;
        $self->spi_readwrite($data);
    }

    $self->{log} = $oldlog;

    $c = crc($f, $c);

    $self->spi_handshake(0x00000065, 0x00750065, "\nWait for GBA to respond with CRC");

    $self->spi_readwrite(0x00000066, "GBA ready with CRC");
    $self->spi_readwrite($c,         "Let's exchange CRC!");

    $self->log("CRC ...hope they match!");
    $self->log("MultiBoot done");
}

=item spi_readwrite

    $miso = $gba->spi_readwrite($mosi)

reads and writes 32 bit from the SPI bus.

=cut

sub spi_readwrite {
    my $self = shift;
    my ($w, $msg) = @_;
    $self->enter_spi;
    my $r = unpack 'L>', $self->{spi}->readwrite(pack 'L>', shift)->get;
    $self->log("0x%08x 0x%08x  ; %s", $r , $w, $msg) if defined $msg;
    return $r;
}

sub spi_handshake {
    my $self = shift;
    my ($w, $expected, $msg) = @_;
    $self->log("%s 0x%08x", $msg, $expected) if defined $msg;

    while ($self->spi_readwrite($w) != $expected) {
        sleep 0.01;
    }
}


=item crc

    $c = Device::GBA::crc($w, [$c = 0x0000c387])

Calculates CRC for word C<$w> and CRC C<$c> according to the algrithm used by the GBA multiboot protocol.

=cut

sub crc
{
    my $w = shift;
    my $c = shift // 0x0000c387;
    for (my $bit = 0; $bit < 32; $bit++) {
        if(($c ^ $w) & 0x01) {
            $c = ($c >> 1) ^ 0x0000c37b;
        } else {
            $c = $c >> 1;
        }

        $w = $w >> 1;
    }

    return $c;
}

sub log { my $log = shift->{'log'}; goto $log }


1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Device-GBA>

=head1 SEE ALSO

L<gba> -- The command line utility

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

Based on The uploader written by Ken Kaarvik.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2.0 or later.

=cut
