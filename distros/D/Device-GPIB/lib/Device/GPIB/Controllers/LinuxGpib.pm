# LinuxGpib.pm
# Device::GPIB interface to LinuxGpib devices such as Keysight 82357B and others
# Tested with linux-gpib-4.3.5/ on Ubuntu 22.10 with kernel 5.19.0-38-generic
#
# You must install and configure LinuxGpib device drivers etc plus the perl bindings as described
# in README in this directory.
#
# Test with:
#use strict;
#use Device::GPIB::Controllers::LinuxGpib;
#
# Args are board number (from /etc/gpib.conf, device GPIB primary address, device GPIB secondary address)
#my $d = Device::GPIB::Controllers::LinuxGpib->new(0);
#die "open failed" unless $d;
#$d->addr(11);
#while (1)
#{
#    $d->send("id?");
#    my $x = $d->read();
#    print "its $x\n";
#}
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Controllers::LinuxGpib;
use LinuxGpib;

use strict;

$Device::GPIB::Controllers::LinuxGpib::VERSION = '0.01';

sub new($$)
{
    my ($class, $board_index) = @_;

    my $self = {};
    bless $self, $class;

    $board_index = 0 unless defined $board_index;
    # "board_index, pad, sad, timo, eot, eos");
    # PAD defaults to 0
    # Sigh: HP3577A PLA command can take around 9 seconds, so need longer timeout than that
    $self->debug("LinuxGpib connecting to board_index $board_index");
    $self->{Device} = LinuxGpib::ibdev($board_index, 0, 0, LinuxGpib::T30s, 1, 0x0a);
    if ($self->{Device} < 0)
    {
	$self->warning("Could not create LinuxGpib device $board_index");
	return;
    }

    $self->{CurrentPad} = -1;
    $self->{CurrentSad} = -1;

    return $self;
}

sub isSerial($)
{
    return 0;
}

sub send($$)
{
    my ($self, $s) = @_;

    $self->debug("Sending: '$s'");
    return unless $self->{Device};
    my $ret = LinuxGpib::ibwrt($self->{Device}, $s, length($s));
    if ($ret ==  0x2100)
    {
	return 1;
    }
    else
    {
	$self->warning("Could not create LinuxGpib device $board_index");
	return;
    }

    $self->{CurrentPad} = -1;
    $self->{CurrentSad} = -1;

    return $self;
}

sub send($$)
{
    my ($self, $s) = @_;

    $self->debug("Sending: '$s'");
    return unless $self->{Device};
    my $ret = LinuxGpib::ibwrt($self->{Device}, $s, length($s));
    if ($ret ==  0x2100)
    {
	return 1;
    }
    else
    {
	$self->warning("LinuxGpib::ibwrt failed: $ret");
	return 0;
    }
}

sub read($)
{
    my ($self) = @_;

    my $data;
    my $ret = LinuxGpib::ibrd($self->{Device}, $data, 10000);
    $self->warning("LinuxGpib::ibrd failed: $ret") unless $ret == 0x2100;
    
    return $data;
}

sub warning($)
{
    my ($self, $s) = @_;

    print "WARNING: $s\n";
}

sub debug($)
{
    my ($self, $s) = @_;

    print "DEBUG: $s\n"
	if $Device::GPIB::Controller::debug;
}

sub sendTo($$$$)
{
    my ($self, $s, $pad, $sad) = @_;
    
    $self->addr($pad, $sad) if defined $pad;
    return $self->send($s);
}

sub addr($$$)
{
    my ($self, $pad, $sad) = @_;
    
    if (defined($pad))
    {
	if ($pad != $self->{CurrentPad})
	{
	    $self->debug("Set addresses $pad, $sad\n");
	    my $ret = LinuxGpib::ibpad($self->{Device}, $pad);
	    $self->warning("LinuxGpib::ibpad failed: $ret") unless $ret == 0x100;
	    $self->{CurrentPad} = $pad;
	    $self->{CurrentSad} = $sad;
	}
    }
    else
    {
	return 'Cant Get Addr From LinuxGpib';
    }
}

sub clr($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    my $ret = LinuxGpib::ibclr($self->{Device});
    $self->warning("LinuxGpib::ibclr failed: $ret") unless $ret == 0x100;
}

sub spoll($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    my $status;
    my $ret = LinuxGpib::ibrsp($self->{Device}, $status);
    $self->warning("LinuxGpib::ibrsp failed: $ret") unless $ret == 0x2100;
    return $status;
}

sub trg($@)
{
    my ($self, @addrs) = @_;

    my $cmd = '++trg';
    while (@addrs)
    {
	my $addr = shift(@addrs);
	$self->debug("trigger $addr");
	$self->addr($addr);
	my $ret = LinuxGpib::ibtrg($self->{Device});
	$self->warning("LinuxGpib::ibrsp failed: $ret") unless $ret == 0x2100;
    }
}
1;
