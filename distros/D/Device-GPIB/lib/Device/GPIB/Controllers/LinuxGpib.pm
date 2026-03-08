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

# These ibsta bits are not in the module constants :-(
use constant DCAS  => 0x1;
use constant DTAS  => 0x2;
use constant LACS  => 0x4;
use constant TACS  => 0x8;
use constant ATN   => 0x10;
use constant CIC   => 0x20;
use constant REM   => 0x40;
use constant LOK   => 0x80;
use constant CMPL  => 0x100;
use constant EVENT => 0x200;
use constant SPOLL => 0x400;
use constant RQS   => 0x800;
use constant SRQI  => 0x1000;
use constant END   => 0x2000;
use constant TIMO  => 0x4000;
use constant ERR   => 0x8000;
    
$Device::GPIB::Controllers::LinuxGpib::VERSION = '0.01';

# Sigh, now need to specify something other than 0 when opening a controller 
my $default_pad = 7;

# $board can be a board index or an alphanumeric board name from /etc/gpib.conf
sub new($$)
{
    my ($class, $board) = @_;

    my $self = {};
    bless $self, $class;

    $board = 0 unless defined $board;
    if ($board =~ /[a-zA-Z]/)
    {
	# If the board name contains alphanumeric, it is taken to be a
	# interface name from /etc/gpib, whose configuration is per that file
	$self->{Device} = LinuxGpib::ibfind($board);
	if ($self->{Device} < 0)
	{
	    $self->warning("Could not create LinuxGpib interface named $board");
	    return;
	}
	$self->debug("Found interface '$board': $self->{Device}\n");
    }
    else
    {
	# Otherwise its taken to be a board index, with config that we will pass as arguments
	# Sigh: HP3577A PLA command can take around 9 seconds, so need longer timeout than that
	$self->debug("LinuxGpib connecting to board_index $board");
	# Sigh, need to actually specify a PAD here, even if we will change it soon.
	# "board_index, pad, sad, timo, eot, eos");
	$self->{Device} = LinuxGpib::ibdev($board, $default_pad, 0, LinuxGpib::T30s, 1, 0x0a);
	if ($self->{Device} < 0)
	{
	    $self->warning("Could not create LinuxGpib device $board");
	    return;
	}
	$self->debug("Found interface '$board': $self->{Device}\n");
    }

    return unless $self->actAsController();

    $self->addr($default_pad);
#    $self->{CurrentPad} = $default_pad;
    $self->{CurrentSad} = -1;

    return $self;
}

sub actAsController()
{
    my ($self) = @_;

    my $ret = LinuxGpib::ibeot($self->{Device}, 1);

    return $ret == CMPL; # CMPL
}

sub actAsDevice()
{
    my ($self) = @_;

    my $ret = LinuxGpib::ibeot($self->{Device}, 1);

    return $ret == CMPL; # CMPL
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
    if ($ret == (END | CMPL))
    {
	return 1;
    }
    else
    {
	my $iberr = LinuxGpib::ThreadIberr;
	my $ibcnt = LinuxGpib::ThreadIbcnt; # errno if write fails
	$self->warning("LinuxGpib::ibwrt failed: $ret IBERR: $iberr, IBCNT: $ibcnt");
	return 0;
    }
}

sub read_to_eol($)
{
    my ($self) = @_;
    return $self->read();
}

sub read($)
{
    my ($self) = @_;

    my $data;
    # Reads until: EOI asserted by talker, timeout, EOS char, clear command, interface clear
    my $ret = LinuxGpib::ibrd($self->{Device}, $data, 10000);
    $self->warning("LinuxGpib::ibrd failed: $ret") unless $ret == (END | CMPL);
    
    return $data;
}

sub warning($)
{
    my ($self, $s) = @_;

    Device::GPIB::Controller::warning($s);
}

sub debug($)
{
    my ($self, $s) = @_;

    Device::GPIB::Controller::debug($s);
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
	    $self->warning("LinuxGpib::ibpad failed: $ret") unless $ret == CMPL;
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
    $self->warning("LinuxGpib::ibclr failed: $ret") unless $ret == CMPL;
}

sub spoll($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    my $status;
    my $ret = LinuxGpib::ibrsp($self->{Device}, $status);
    $self->warning("LinuxGpib::ibrsp failed: $ret") unless $ret == (END | CMPL);
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
	$self->warning("LinuxGpib::ibrsp failed: $ret") unless $ret == (END | CMPL);
    }
}

# Prologix needs this. We dont.
sub eot_enable($$)
{
    my ($self, $val) = @_;

}
1;
