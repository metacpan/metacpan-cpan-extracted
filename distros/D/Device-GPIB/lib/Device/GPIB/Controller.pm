# Controller.pm
# Wrapper for multiple controller interfaces

package Device::GPIB::Controller;
use Module::Load;
use strict;

$Device::GPIB::Controller::debug = 0;

sub new($$)
{
    my ($class, $port) = @_;

    if ($port =~ /^LinuxGpib:(\d*)/i)
    {
	my $board_index = int($1);
	load Device::GPIB::Controllers::LinuxGpib;
	return  Device::GPIB::Controllers::LinuxGpib->new($board_index);
    }
    elsif ($port =~ /^Prologix:(.+)/i)
    {
	load Device::GPIB::Controllers::Prologix;
	return  Device::GPIB::Controllers::Prologix->new($1);
    }
    elsif ($port =~ /^serial:(.+)/i)
    {
	load Device::GPIB::Controllers::Serial;
	return  Device::GPIB::Controllers::Serial->new($1);
    }
    else
    {
	# Historical default is Prologix serial port specification
	load Device::GPIB::Controllers::Prologix;
	return  Device::GPIB::Controllers::Prologix->new($port);
    }
}

1;
