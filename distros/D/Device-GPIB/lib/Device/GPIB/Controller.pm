# Controller.pm
# Wrapper for multiple controller interfaces

package Device::GPIB::Controller;
use Module::Load;
use strict;

$Device::GPIB::Controller::debug = 0;

sub new($$)
{
    my ($class, $port) = @_;

    if ($port =~ /^LinuxGpib:(.*)/i)
    {
	# Argument can be a board_index (integer) or an alphanumeric
	# board or device name from /etc/gpif.conf
	# You can specify a device name so we act as a GPIB device, eg for the device.pl script
	load Device::GPIB::Controllers::LinuxGpib;
	return  Device::GPIB::Controllers::LinuxGpib->new($1);
    }
    elsif ($port =~ /^Prologix:(.+)/i || $port =~ /^AR488:(.+)/i )
    {
	# Argument can be [port[:baud[:databits[:parity[:stopbits[:handshake]]]]]
	load Device::GPIB::Controllers::Prologix;
	return  Device::GPIB::Controllers::Prologix->new($1);
    }
    elsif ($port =~ /^serial:(.+)/i)
    {
	# Argument can be [port[:baud[:databits[:parity[:stopbits[:handshake]]]]]
	load Device::GPIB::Controllers::Serial;
	return  Device::GPIB::Controllers::Serial->new($1);
    }
    else
    {
	# Historical default is Prologix serial port specification
	# Argument can be [port[:baud[:databits[:parity[:stopbits[:handshake]]]]]
	load Device::GPIB::Controllers::Prologix;
	return  Device::GPIB::Controllers::Prologix->new($port);
    }
}

# Generalised error reporting routines

sub error($)
{
    my ($s) = @_;

    print "ERROR: $s\n";
}

sub warning($)
{
    my ($s) = @_;

    print "WARNING: $s\n";
}

sub enableDebug($)
{
    my ($enable) = @_;
    $Device::GPIB::debug = $enable
}

sub debug($)
{
    my ($s) = @_;

    print "DEBUG: $s\n" if $Device::GPIB::debug;
}


1;
