package GSM::SMS::Support::SerialPort;
use strict;

our $VERSION = '0.1';

use Log::Agent;

=head1 NAME

GSM::SMS::Support::SerialPort - A proxy for platform specific serial conenction

=head1 SYNOPSIS

  use GSM::SMS::Support::SerialPort;

  my $po = GSM::SMS::Support::SerialPort->new( $port );
  $po->baudrate( 9600 );
  ...

=head1 DESCRIPTION

Actually, this is a kind of a serial port factory - for the moment - as both
L<Win32::SerialPort> and L<Device::SerialPort> have almost the same interface.

=head1 METHODS

=over 4

=item B<new> - Return a SerialPort object

=cut

sub new {
	my($proto, @args) = @_;

	logdbg "debug", "$proto constructor called";

	my $os = $^O;
	unless ($os) {
		require Config;
		$os = $Config::Config{'osname'};
	}

	logdbg "debug", "We are running on $os";

	my $port_object = undef;
	if ($os =~ /^MSWin/) {
		$port_object = _create_serial_win32(@args);	
	} else {
		$port_object = _create_serial_unix(@args);
	}
	return $port_object;
}

=back

=head1 PRIVATE METHODS

=over 4

=item B<_create_serial_win32> - Create a Win32::SerialPort object

=cut

sub  _create_serial_win32 {
	my (@args) = @_;

	logdbg "debug", "Creating a Win32::SerialPort object";

	unless (eval "require Win32::SerialPort") {
		logdbg "debug", "Could not load Win32::SerialPort";
		die "Could not load Win32::SerialPort";
	}

	*{Win32::SerialPort::write_drain} = sub {};
    return Win32::SerialPort->new(@args);
	
}

=item B<_create_serial_unix> - Create a Device::SerialPort object

=cut

sub _create_serial_unix {
	my(@args) = @_;

	logdbg "debug", "Creating a Device::SerialPort";

	unless (eval "require Device::SerialPort") {
		logdbg "debug", "Could not load Device::SerialPort";
		die "Could not load Device::SerialPort";
	}

	return Device::SerialPort->new(@args);
}

=back

=cut

1;

__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=end
