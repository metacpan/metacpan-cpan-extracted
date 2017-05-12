package GQRX::Remote;

use IO::Socket::INET;

use warnings;
use strict;

our $VERSION = '1.0.1';


sub new {
    my $class = shift();
    my %options = @_;
    my $self = {
        _connection => undef,  # IO::Socket connection to GQRX
        _last_error => undef,

        # Options definable on init:
        exit_on_error => 0 # When true, exit on any error
    };

    bless ($self, $class);

    foreach (keys %options) {
        $self->{$_} = $options{$_};
    }

    return ($self);
}


sub DESTROY {
    # Automatically disconnect when the object is destroyed
    my ($self) = @_;

    $self->disconnect();
}


sub _set_error {
    my ($self, $error) = @_;

    if ($self->{exit_on_error}) {
        die "GQRX::Remote: ERROR: $error\n";
    }

    $self->{_last_error} = $error;
}


sub error {
    my ($self) = @_;

    return ($self->{_last_error});
}


sub connect {
    my $self = shift();
    my (%option) = @_;
    my $connection;

    if ($self->{_connection}) { # Close any existent connection
        $self->disconnect();
    }

    $connection = new IO::Socket::INET(
        PeerHost => $option{host} || '127.0.0.1',
        PeerPort => $option{port} || 7356,
        Proto => 'tcp'
        );

    if (! $connection) {
        $self->_set_error("Failed to establish connection to gqrx: $@");
        return (undef);
    }

    $self->{_connection} = $connection;

    return (1);
}


sub disconnect {
    my ($self) = @_;

    if ($self->{_connection} && $self->{_connection}->connected()) {
        $self->{_connection}->send("c\n"); # Send the close command to the server
        $self->{_connection}->close();
    }

    $self->{_connection} = undef;
}


sub read_line {
    my ($self) = shift();
    my $buf;

    if (! $self->{_connection}->connected()) {
        $self->_set_error("Connection lost");
        return (undef);
    }

    $buf = $self->{_connection}->getline();

    if (! defined($buf)) {
	return (undef);
    }
    else {
	chomp($buf);
	return ($buf);
    }
}


sub command {
    my $self = shift();
    my $command = shift();
    my (%opt) = @_;
    my $buf;

    if (! $self->{_connection}) {
        $self->_set_error("Failed to send: Not connected");
        return (undef);
    }
    elsif (! $self->{_connection}->connected()) {
        $self->_set_error("Failed to send: Connection lost");
        return (undef);
    }

    $self->{_connection}->send($command . "\n");

    return ($self->read_line(%opt));
}


sub set_frequency {
    my ($self, $frequency) = @_;
    my $response = $self->command("F $frequency");

    if (! defined($response)) {
        return (undef);
    }
    elsif ($response ne 'RPRT 0') {
        $self->_set_error("Set frequency failed. Unexpected response: $response");
        return (undef);
    }

    return (1);
}


sub get_frequency {
    my ($self) = @_;

    return ($self->command("f"));
}


sub set_demodulator_mode {
    my ($self, $mode) = @_;
    my $response = $self->command("M $mode");

    if (! defined($response)) {
        return (undef);
    }
    elsif ($response ne 'RPRT 0') {
        $self->_set_error("Set demodulator mode failed. Unexpected response: $response");
        return (undef);
    }

    return (1);
}


sub get_demodulator_mode {
    my ($self) = @_;

    return ($self->command("m"));
}


sub get_signal_strength {
    my ($self) = @_;

    return ($self->command("l STRENGTH"));
}


sub get_squelch_threshold {
    my ($self) = @_;

    return ($self->command("l SQL"));
}


sub set_squelch_threshold {
    my ($self, $level) = @_;
    my $response = $self->command("L SQL $level");

    if (! defined($response)) {
        return (undef);
    }
    elsif ($response ne 'RPRT 0') {
        $self->_set_error("Set demodulator mode failed. Unexpected response: $response");
        return (undef);
    }

    return (1);
}


sub get_recorder_status {
    my ($self) = @_;

    return ($self->command("u RECORD"));
}


sub set_recorder_status {
    my ($self, $status) = @_;
    my $response = $self->command("U RECORD $status");


    if (! defined($response)) {
        return (undef);
    }
    elsif ($response ne 'RPRT 0') {
        $self->_set_error("Failed to set recorder state.  Unexpected response: $response");
        return (undef);
    }

    return (1);
}


sub start_recording {
    my ($self) = @_;
    my $response = $self->command("AOS");

    if (! defined($response)) {
        return (undef);
    }
    elsif ($response ne 'RPRT 0') {
        $self->_set_error("Failed to start recording.  Unexpected response: $response");
        return (undef);
    }

    return (1);
}


sub stop_recording {
    my ($self) = @_;
    my $response = $self->command("LOS");

    if (! defined($response)) {
        return (undef);
    }
    elsif ($response ne 'RPRT 0') {
        $self->_set_error("Failed to stop recording.  Unexpected response: $response");
        return (undef);
    }

    return (1);
}


1;


__END__

=head1 NAME

GQRX::Remote - Control Gqrx using the Remote Control protocol

=head1 SYNOPSIS

    use GQRX::Remote;

    # Initialize a $remote and connect to the local server
    my $remote = GQRX::Remote->new();

    $remote->connect();

    # Set up some options
    $remote->set_demodulator_mode('AM');
    $remote->set_frequency(44000000);  # 44,000 kHz

    # Retrieve the signal strength
    my $strength = $remote->get_signal_strength();

=head1 DESCRIPTION

The GQRX::Remote module provides a Perl interface to the remote
control protocol of the Gqrx software defined radio program.  Using
this, programs can communicate with a Gqrx instance over a socket
connection.


=head1 INITIALIZATION

To begin using this module, create a remote object:

    my $remote = GQRX::Remote->new();

This object provides the interface for using and managing a connection
to Gqrx.

    my $remote = GQRX::Remote->new(exit_on_error => 1);

When C<exit_on_error> is enabled, any errors encountered are
considered fatal and will cause a C<die> to be executed.  This is
useful when writing simple scripts, where errors would cause the
execution to fail anyway.  It is for convenience and can save a
programmer a little time.  While this might make sense for some
scripts, applications generally should not use it, and instead perform
proper error checking and handling.


=head1 ERROR HANDLING

If the module is initialized with the C<exit_on_error> option, all
errors will results in a die() call with the error message.
Otherwise, calls that fail will return a value of C<undef> when a
failure occurs.

In these situations, the error message is retrievable by calling
C<< $remote->error() >>.  This returns a string containing the error
message.

    # Example handling of an error
    if (! defined $remote->get_signal_strength()) {
        print "get_signal_strength() failed with error: " . $remote->error();
    }


=head1 CONNECTING TO A SERVER

This module connects to a Gqrx instance at a defined IP address and
port.  By default, this is the C<localhost> (C<127.0.0.1>) and port
C<7356>.

    # Connect to 127.0.0.1:7356
    $remote->connect();

    # If the server isn't local and on the default port, these
    # may be overridden
    $remote->connect(host => '192.168.1.100', port => 4242);

After successfully connecting, a 1 will be returned.  In the case of a
failure, a C<0> will be returned, and an error will be set.  If
C<exit_on_error> is enabled, failures will exit, but otherwise they
should be captured and handled.


    if (! $remote->connect()) {
       # Connection failed
    }


=head1 BASIC USAGE

=head2 FREQUENCY

    # To get the frequency:
    $frequency = $remote->get_frequency();

    # To set the frequency:
    $remote->set_frequency(44000000); # 44,000 kHz

All frequency values are in hertz.

On success the C<set_frequency()> call returns 1.  On failure, either
call will return C<undef>.


=head2 DEMODULATOR MODE

    # To get the demodulator_mode:
    $demodulator_mode = $remote->get_demodulator_mode();

    # To set the demodulator_mode:
    $remote->set_demodulator_mode('WFM');

Any demodulator mode supported by Gqrx should work.  At the current
time this includes: AM, FM, WFM, WFM_ST, WFM_ST_OIRT, LSB, USB, CW,
CWL, CWU.

On success the C<set_demodulator_mode()> call returns 1.  On failure, either
call will return C<undef>.


=head2 SIGNAL STRENGTH

    # Retrieve the signal strength
    $remote->get_signal_strength();

On success, this returns the signal strength.  On failure, it will
return C<undef>.


=head2 SQUELCH THRESHOLD

    # To get the squelch_threshold:
    $squelch_threshold = $remote->get_squelch_threshold();

    # To set the squelch_threshold:
    $remote->set_squelch_threshold(-23.1);

On success the C<set_squelch_threshold()> call returns 1.  On failure,
either call will return C<undef>.


=head2 RECORDING

    # Start recording
    $remote->start_recording();

    # Stop recording
    $remote->stop_recording();

These calls can be used to automatically recording of audio in Gqrx.
On success they return 1, and on failure C<undef>.


=head2 RECORDER STATUS (experimental)

    $remote->set_recorder_status(1);
    $remote->set_recorder_status(0);
    $remote->get_recorder_status();

The API documentation lists the protocol for getting and setting
recorder status.  As of Gqrx 2.5.3 these requests always fail.  The
implementation has been included to provide for complete support of
the documented protocol.

Recording audio files can be still be achieved via the
C<start_recording()> and C<stop_recording()> calls.

On success C<set_recorder_status()> returns 1.  On failure, either
call will return C<undef>.


=head1 SEE ALSO

* GQRX::Remote on GitHub:

https://github.com/DougHaber/gqrx-remote

* Example script for collecting signal strength data: (included in distribution)

https://github.com/DougHaber/gqrx-remote/blob/master/example

* Gqrx:

http://gqrx.dk/

* Gqrx remote control protocol documentation:

http://gqrx.dk/doc/remote-control


=head1 AUTHOR

Original author & current maintainer: Doug Haber <dhaber@node99.net>


=head1 LICENSE

Either the Perl Artistic Licence
L<http://dev.perl.org/licenses/artistic.html> or the GPL
L<http://www.opensource.org/licenses/gpl-license.php>


=head1 COPYRIGHT

Copyright (c) 2016 Douglas Haber

All rights reserved. This is free software. You may distribute under
the terms of either the GNU General Public License or the Artistic
License.


=cut
