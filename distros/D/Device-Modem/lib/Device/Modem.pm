# Device::Modem - a Perl class to interface generic modems (AT-compliant)
# Copyright (C) 2002-2020 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.

package Device::Modem;
our $VERSION = '1.59';
$VERSION = eval $VERSION;

BEGIN {

    if( index($^O, 'Win') >= 0 ) {   # MSWin32 (and not darwin, cygwin, ...)

        require Win32::SerialPort;
        Win32::SerialPort->import;

        # Import line status constants from Win32::SerialPort module
        *Device::Modem::MS_CTS_ON  = *Win32::SerialPort::MS_CTS_ON;
        *Device::Modem::MS_DSR_ON  = *Win32::SerialPort::MS_DSR_ON;
        *Device::Modem::MS_RING_ON = *Win32::SerialPort::MS_RING_ON;
        *Device::Modem::MS_RLSD_ON = *Win32::SerialPort::MS_RLSD_ON;

    } else {

        require Device::SerialPort;
        Device::SerialPort->import;

        # Import line status constants from Device::SerialPort module
        *Device::Modem::MS_CTS_ON = *Device::SerialPort::MS_CTS_ON;
        *Device::Modem::MS_DSR_ON = *Device::SerialPort::MS_DSR_ON;
        *Device::Modem::MS_RING_ON = *Device::SerialPort::MS_RING_ON;
        *Device::Modem::MS_RLSD_ON = *Device::SerialPort::MS_RLSD_ON;

    }
}

use strict;
use Carp ();

# Constants definition
use constant CTRL_Z => chr(26);
use constant CR => "\r";

# Connection defaults
$Device::Modem::DEFAULT_PORT = index($^O, 'Win') >= 0 ? 'COM1' : '/dev/modem';
$Device::Modem::DEFAULT_INIT_STRING = 'S7=45 S0=0 L1 V1 X4 &c1 E1 Q0';
$Device::Modem::BAUDRATE = 19200;
$Device::Modem::DATABITS = 8;
$Device::Modem::STOPBITS = 1;
$Device::Modem::HANDSHAKE= 'none';
$Device::Modem::PARITY   = 'none';
$Device::Modem::TIMEOUT  = 500;     # milliseconds
$Device::Modem::READCHARS= 130;
$Device::Modem::WAITCMD  = 200;     # milliseconds

# Setup text and numerical response codes
@Device::Modem::RESPONSE = ( 'OK', undef, 'RING', 'NO CARRIER', 'ERROR', undef, 'NO DIALTONE', 'BUSY' );
$Device::Modem::STD_RESPONSE = qr/^(OK|ERROR|COMMAND NOT SUPPORT)$/m;

#%Device::Modem::RESPONSE = (
#	'OK'   => 'Command executed without errors',
#	'RING' => 'Detected phone ring',
#	'NO CARRIER'  => 'Link not established or disconnected',
#	'ERROR'       => 'Invalid command or command line too long',
#	'NO DIALTONE' => 'No dial tone, dialing not possible or wrong mode',
#	'BUSY'        => 'Remote terminal busy'
#);

# object constructor (prepare only object)
sub new {
    my($proto,%aOpt) = @_;                  # Get reference to object
    # Options of object
    my $class = ref($proto) || $proto;      # Get reference to class

    $aOpt{'ostype'} = $^O;                  # Store OSTYPE in object
    $aOpt{'ostype'} = 'windoze' if index( $aOpt{'ostype'}, 'Win' ) >= 0;

    # Initialize flags array
    $aOpt{'flags'} = {};

    # Start as not connected
    $aOpt{'CONNECTED'} = 0;

    $aOpt{'port'} ||= $Device::Modem::DEFAULT_PORT;

    # Instance log object
    $aOpt{'log'} ||= 'file';

    # Force logging to file if this is windoze and user requested syslog mechanism
    $aOpt{'log'} = 'file' if( $aOpt{'ostype'} eq 'windoze' && $aOpt{'log'} =~ /syslog/i );
    $aOpt{'loglevel'} ||= 'warning';

    if( ! ref $aOpt{'log'} ) {
        my($method, @options) = split ',', delete $aOpt{'log'};
        my $logclass = 'Device/Modem/Log/'.ucfirst(lc $method).'.pm';
        my $package = 'Device::Modem::Log::'.ucfirst lc $method;
        eval { require $logclass; };
        unless($@) {
            $aOpt{'_log'} = $package->new( $class, @options );
        } else {
            print STDERR "Failed to require Log package: $@\n";
        }
    } else {

        # User passed an already instanced log object
        $aOpt{'_log'} = $aOpt{'log'};
    }

    if( ref $aOpt{'_log'} && $aOpt{'_log'}->can('loglevel') ) {
        $aOpt{'_log'}->loglevel($aOpt{'loglevel'});
    }

    bless \%aOpt, $class;                   # Instance $class object
}

sub attention {
    my $self = shift;
    $self->log->write('info', 'sending attention sequence...');

    # Send attention sequence
    $self->atsend('+++');

    # Wait for response
    $self->answer();
}

sub dial {
    my($self, $number, $timeout, $mode) = @_;
    my $ok = 0;

    # Default timeout in seconds
    $timeout ||= 30;

    # Default is data calls
    if (! defined $mode) {
        $mode = 'DATA';
    }
    # Numbers with ';' mean voice calls
    elsif ($mode =~ m{VOICE}i || $number =~ m{;}) {
        $mode = 'VOICE';
    }
    # Invalid input, or explicit 'DATA' call
    else {
        $mode = 'DATA';
    }

    # Check if we have already dialed some number...
    if ($self->flag('CARRIER')) {
        $self->log->write( 'warning', 'line is already connected, ignoring dial()' );
        return;
    }

    # Check if no number supplied
    if (! defined $number) {
        #
        # XXX Here we could enable ATDL command (dial last number)
        #
        $self->log->write( 'warning', 'cannot dial without a number!' );
        return;
    }

    # Remove all non number chars plus some others allowed
    # Thanks to Pierre Hilson for the `#' (UMTS)
    # and to Marek Jaros for the `;' (voice calls)
    $number =~ s{[^0-9,\(\)\*\-#;\sp]}{}g;

    my $suffix = '';
    if ($mode eq 'VOICE') {
        $self->log->write('info', 'trying to make a voice call');
        $suffix = ';';
    }

    # Dial number and wait for response
    if( length $number == 1 ) {
        $self->log->write('info', 'dialing address book number ['.$number.']' );

        $self->atsend( 'ATDS' . $number . $suffix . CR );
    } else {
        $self->log->write('info', 'dialing number ['.$number.']' );
        $self->atsend( 'ATDT' . $number . $suffix . CR );
    }

    # XXX Check response times here (timeout!)
    my $ans = $self->answer( qr/[A-Z]/, $timeout * 1000 );

    if( (index($ans,'CONNECT') > -1) || (index($ans,'RING') > -1) ) {
        $ok = 1;
    }

    # Turn on/off `CARRIER' flag
    $self->flag('CARRIER', $ok);

    $self->log->write('info', 'dialing result = '.$ok);
    return wantarray ? ($ok, $ans) : $ok;
}

# Enable/disable local echo of commands (enabling echo can cause everything else to fail, I think)
sub echo {
    my($self, $lEnable) = @_;

    $self->log->write( 'info', ( $lEnable ? 'enabling' : 'disabling' ) . ' echo' );
    $self->atsend( ($lEnable ? 'ATE1' : 'ATE0') . CR );

    $self->answer($Device::Modem::STD_RESPONSE);
}

# Terminate current call (XXX not tested)
sub hangup {
    my $self = shift;

    $self->log->write('info', 'hanging up...');
    $self->atsend( 'ATH0' . CR );
    my $ok = $self->answer($Device::Modem::STD_RESPONSE);
    unless ($ok) {
      $self->attention();
      $self->atsend( 'ATH0' . CR );
      $self->answer($Device::Modem::STD_RESPONSE, 5000);
    }
    $self->_reset_flags();
}

# Checks if modem is enabled (for now, it works ok for modem OFF/ON case)
sub is_active {
    my $self = shift;
    my $lOk;

    $self->log->write('info', 'testing modem activity on port ' . ($self->options->{'port'} || '') );

    # Modem is active if already connected to a line
    if( $self->flag('CARRIER') ) {

        $self->log->write('info', 'carrier is '.$self->flag('CARRIER').', modem is connected, it should be active');
        $lOk = 1;

    } else {

        # XXX Old mode to test modem ...
        # Try sending an echo enable|disable command
        #$self->attention();
        #$self->verbose(0);
        #$lOk = $self->verbose(1);

        # If DSR signal is on, modem is active
        my %sig = $self->status();
        $lOk = $sig{DSR};
        undef %sig;

        # If we have no success, try to reset
        if( ! $lOk ) {
            $self->log->write('warning', 'modem not responding... trying to reset');
            $lOk = $self->reset();
        }

    }

    $self->log->write('info', 'modem reset result = '.$lOk);

    return $lOk;
}

# Take modem off hook, prepare to dial
sub offhook {
    my $self = shift;

    $self->log->write('info', 'taking off hook');
    $self->atsend( 'ATH1' . CR );

    $self->flag('OFFHOOK', 1);

    return 1;
}

# Get/Set S* registers value:  S_register( number [, new_value] )
# returns undef on failure ( zero is a good value )
sub S_register {
    my $self = shift;
    my $register = shift;
    my $value = 0;

    return unless $register;

    my $ok;

    # If `new_value' supplied, we want to update value of this register
    if( @_ ) {

        my $new_value = shift;
        $new_value =~ s|\D||g;
        $self->log->write('info', 'storing value ['.$new_value.'] into register S'.$register);
        $self->atsend( sprintf( 'AT S%02d=%d' . CR, $register, $new_value ) );

        $value = ( index( $self->answer(), 'OK' ) != -1 ) ? $new_value : undef;

    } else {

        $self->atsend( sprintf( 'AT S%d?' . CR, $register ) );
        ($ok, $value) = $self->parse_answer();

        if( index($ok, 'OK') != -1 ) {
            $self->log->write('info', 'value of S'.$register.' register seems to be ['.$value.']');
        } else {
            $value = undef;
            $self->log->write('err', 'error reading value of S'.$register.' register');
        }

    }

    # Return updated value of register
    $self->log->write('info', 'S'.$register.' = '.$value);

    return $value;
}

# Repeat the last commands (this comes gratis with `A/' at-command)
sub repeat {
    my $self = shift;

    $self->log->write('info', 'repeating last command' );
    $self->atsend( 'A/' . CR );

    $self->answer();
}

# Complete modem reset
sub reset {
    my $self = shift;

    $self->log->write('warning', 'resetting modem on '.$self->{'port'} );
    $self->hangup();
    my $result = $self->send_init_string();
    $self->_reset_flags();
    return $result;
}

# Return an hash with the status of main modem signals
sub status {
    my $self = shift;
    $self->log->write('info', 'getting modem line status on '.$self->{'port'});

    # This also relies on Device::SerialPort
    my $status = $self->port->modemlines();

 # See top of module for these constants, exported by (Win32|Device)::SerialPort
    my %signal = (
        CTS  => $status & Device::Modem::MS_CTS_ON,
        DSR  => $status & Device::Modem::MS_DSR_ON,
        RING => $status & Device::Modem::MS_RING_ON,
        RLSD => $status & Device::Modem::MS_RLSD_ON
      );

    $self->log->write('info', 'modem on '.$self->{'port'}.' status is ['.$status.']');
    $self->log->write('info', "CTS=$signal{CTS} DSR=$signal{DSR} RING=$signal{RING} RLSD=$signal{RLSD}");

    return %signal;
}

# Of little use here, but nice to have it
# restore_factory_settings( profile )
# profile can be 0 or 1
sub restore_factory_settings {
    my $self = shift;
    my $profile = shift;
    $profile = 0 unless defined $profile;

    $self->log->write('warning', 'restoring factory settings '.$profile.' on '.$self->{'port'} );
    $self->atsend( 'AT&F'.$profile . CR);

    $self->answer($Device::Modem::STD_RESPONSE);
}

# Store telephone number in modem's internal address book, to dial later
# store_number( position, number )
sub store_number {
    my( $self, $position, $number ) = @_;
    my $ok = 0;

    # Check parameters
    unless( defined($position) && $number ) {
        $self->log->write('warning', 'store_number() called with wrong parameters');
        return $ok;
    }

    $self->log->write('info', 'storing number ['.$number.'] into memory ['.$position.']');

    # Remove all non-numerical chars from position and number
    $position =~ s/\D//g;
    $number   =~ s/[^0-9,]//g;

    $self->atsend( sprintf( 'AT &Z%d=%s' . CR, $position, $number ) );

    if( index( $self->answer(), 'OK' ) != -1 ) {
        $self->log->write('info', 'stored number ['.$number.'] into memory ['.$position.']');
        $ok = 1;
    } else {
        $self->log->write('warning', 'error storing number ['.$number.'] into memory ['.$position.']');
        $ok = 0;
    }

    return $ok;
}

# Enable/disable verbose response messages against numerical response messages
# XXX I need to manage also numerical values...
sub verbose {
    my($self, $lEnable) = @_;

    $self->log->write( 'info', ( $lEnable ? 'enabling' : 'disabling' ) . ' verbose messages' );
    $self->atsend( ($lEnable ? 'ATQ0V1' : 'ATQ0V0') . CR );

    $self->answer($Device::Modem::STD_RESPONSE);
}

sub wait {
    my( $self, $msec ) = @_;

    $self->log->write('debug', 'waiting for '.$msec.' msecs');

# Perhaps Time::HiRes here is not so useful, since I tested `select()' system call also on Windows
    select( undef, undef, undef, $msec / 1000 );
    return 1;

}

# Set a named flag. Flags are now: OFFHOOK, CARRIER
sub flag {
    my $self = shift;
    my $cFlag = uc shift;

    $self->{'_flags'}->{$cFlag} = shift() if @_;

    $self->{'_flags'}->{$cFlag};
}

# reset internal flags that tell the status of modem (XXX to be extended)
sub _reset_flags {
    my $self = shift();

    map { $self->flag($_, 0) }
      'OFFHOOK', 'CARRIER';
}

# initialize modem with some basic commands (XXX &C0)
# send_init_string( [my_init_string] )
# my_init_string goes without 'AT' prefix
sub send_init_string {
    my($self, $cInit) = @_;
    $cInit = $self->options->{'init_string'} unless defined $cInit;
    # If no Init string then do nothing!
    if ($cInit) {
      $self->attention();
      $self->atsend('AT '.$cInit. CR );
      return $self->answer($Device::Modem::STD_RESPONSE);
    }
}

# returns log object reference or nothing if it is not defined
sub log {
    my $me = shift;
    if( ref $me->{'_log'} ) {
        return $me->{'_log'};
    } else {
        return {};
    }
}

# instances (Device|Win32)::SerialPort object and initializes communications
sub connect {
    my $me = shift();

    my %aOpt = ();
    if( @_ ) {
        %aOpt = @_;
    }

    my $lOk = 0;

    # Set default values if missing
    $aOpt{'baudrate'} ||= $Device::Modem::BAUDRATE;
    $aOpt{'databits'} ||= $Device::Modem::DATABITS;
    $aOpt{'parity'}   ||= $Device::Modem::PARITY;
    $aOpt{'stopbits'} ||= $Device::Modem::STOPBITS;
    $aOpt{'handshake'}||= $Device::Modem::HANDSHAKE;
    $aOpt{'max_reset_iter'} ||= 0;

    # Store communication options in object
    $me->{'_comm_options'} = \%aOpt;

    # Connect on serial (use different mod for win32)
    if( $me->ostype eq 'windoze' ) {
        $me->port( Win32::SerialPort->new($me->{'port'}) );
    } else {
        $me->port( Device::SerialPort->new($me->{'port'}) );
    }

    # Check connection
    unless( ref $me->port ) {
        $me->log->write( 'err', '*FAILED* connect on '.$me->{'port'} );
        return $lOk;
    }

    # Set communication options
    my $oPort = $me->port;
    $oPort -> baudrate ( $me->options->{'baudrate'}  );
    $oPort -> databits ( $me->options->{'databits'}  );
    $oPort -> stopbits ( $me->options->{'stopbits'}  );
    $oPort -> parity   ( $me->options->{'parity'}    );
    $oPort -> handshake( $me->options->{'handshake'} );

    # Non configurable options
    $oPort -> buffers         ( 10000, 10000 );
    $oPort -> read_const_time ( 20 );           # was 500
    $oPort -> read_char_time  ( 0 );

    # read_interval() seems to be unsupported on Device::SerialPort,
    # while allowed on Win32::SerialPort...
    if( $oPort->can('read_interval') )
    {
        $oPort->read_interval( 20 );
    }

    $oPort -> are_match ( 'OK' );
    $oPort -> lookclear;

    unless ( $oPort -> write_settings ) {
        $me->log->write('err', '*FAILED* write_settings on '.$me->{'port'} );
        return $lOk;
    }
    $oPort -> purge_all;

    # Get the modems attention
    # Send multiple reset commands looking for a sensible response.
    # A small number of modems need time to settle down and start responding to the serial port
    my $iter = 0;
    my $ok = 0;
    my $blank = 0;
    while ( ($iter < $aOpt{'max_reset_iter'}) && ($ok < 2) && ($blank < 3) ) {
        $me->atsend('AT E0'. CR );
        my $rslt = $me->answer($Device::Modem::STD_RESPONSE, 1500);
#        print "Res: $rslt \r\n";
        $iter+=1;
        if ($rslt && $rslt =~ /^OK/) {
            $ok+=1;
        } else {
            $ok=0;
        }
        if (!$rslt) {
            $blank++;
        } else {
            $blank=0;
        }
    }
    if ($aOpt{'max_reset_iter'}) {
        $me->log->write('debug', "DEBUG CONNECT: $iter : $ok : $blank\n"); # DEBUG
    }
    $me-> log -> write('info', 'sending init string...' );

    # Set default initialization string if none supplied
    my $init_string = defined $me->options->{'init_string'}
        ? $me->options->{'init_string'}
        : $Device::Modem::DEFAULT_INIT_STRING;

    my $init_response = $me->send_init_string($init_string) || '';
    $me-> log -> write('debug', "init response: $init_response\n"); # DEBUG
    $me-> _reset_flags();

    # Disable local echo
    $me-> echo(0);

    $me-> log -> write('info', 'Ok connected' );
    $me-> {'CONNECTED'} = 1;

}

# $^O is stored into object
sub ostype {
    my $self = shift;
    $self->{'ostype'};
}

# returns Device::SerialPort reference to hash options
sub options {
    my $self = shift();
    @_ ? $self->{'_comm_options'} = shift()
      : $self->{'_comm_options'};
}

# returns Device::SerialPort object handle
sub port {
    my $self = shift;

    if (@_) {
        return ($self->{'_comm_object'} = shift);
    }

    my $port_obj = $self->{'_comm_object'};

    # Maybe the port was disconnected?
    if (defined $self->{'CONNECTED'} &&
        $self->{'CONNECTED'} == 1 &&                # We were connected
        (! defined $port_obj || ! $port_obj)) {     # Now we aren't anymore

        # Avoid recursion on ourselves
        $self->{'CONNECTED'} = 0;

        # Try to reconnect if possible
        my $connect_options = $self->options;

        # No connect options probably because we didn't ever connect
        if (! $connect_options) {
            Carp::croak("Not connected");
        }

        $self->connect(%{ $connect_options });
        $port_obj = $self->{'_comm_object'};
    }

    # Still not connected? bail out
    if (! defined $port_obj || ! $port_obj) {
        Carp::croak("Not connected");
    }

    return $port_obj;
}

# disconnect serial port
sub disconnect {
    my $me = shift;
    $me->port->close();
    $me->log->write('info', 'Disconnected from '.$me->{'port'} );
}

# Send AT command to device on serial port (command must include CR for now)
sub atsend {
    my( $me, $msg ) = @_;
    my $cnt = 0;

    # Write message on port
    $me->port->purge_all();
    $cnt = $me->port->write($msg);

    my $lbuf=length($msg);
    my $ret;

    while ($cnt < $lbuf)
    {
       $ret = $me->port->write(substr($msg, $cnt));
       $me->write_drain();
       last unless defined $ret;
       $cnt += $ret;
    }

    $me->log->write('debug', 'atsend: wrote '.$cnt.'/'.length($msg).' chars');

    # If wrote all chars of `msg', we are successful
    return $cnt == length $msg;
}

# Call write_drain() if platform allows to (no call for Win32)
sub write_drain
{
    my $me = shift;

    # No write_drain() call for win32 systems
    return if $me->ostype eq 'windoze';

    # No write_drain() if no port object available
    my $port = $me->port;
    return unless $port;

    return $port->write_drain();
}

# answer() takes strings from the device until a pattern
# is encountered or a timeout happens.
sub _answer {
    my $me = shift;
    my($expect, $timeout) = @_;
    $expect = $Device::Modem::STD_RESPONSE if (! defined($expect));
    $timeout = $Device::Modem::TIMEOUT if (! defined($timeout));

    # If we expect something, we must first match against serial input
    my $done = (defined $expect and $expect ne '');

    $me->log->write('debug', 'answer: expecting ['.($expect||'').']'.($timeout ? ' or '.($timeout/1000).' seconds timeout' : '' ) );

    # Main read cycle
    my $cycles = 0;
    my $idle_cycles = 0;
    my $answer;
    my $start_time = time();
    my $end_time   = 0;

    # If timeout was defined, check max time (timeout is in milliseconds)
    $me->log->write('debug', 'answer: timeout value is '.($timeout||'undef'));

    if( defined $timeout && $timeout > 0 ) {
        $end_time = $start_time + ($timeout / 1000);
        $end_time++ if $end_time == $start_time;
        $me->log->write( debug => 'answer: end time set to '.$end_time );
    }

    do {
        my ($what, $howmany);
        $what = $me->port->read(1) . $me->port->input;
        $howmany = length($what);

        # Timeout count incremented only on empty readings
        if( defined $what && $howmany > 0 ) {

            # Add received chars to answer string
            $answer .= $what;

            # Check if buffer matches "expect string"
            if( defined $expect ) {
                my $copy = $answer;
                $copy =~ s/\r(\n)?/\n/g; # Convert line endings from "\r" or "\r\n" to "\n"
                $done = ( defined $copy && $copy =~ $expect ) ? 1 : 0;
                $me->log->write( debug => 'answer: matched expect: '.$expect ) if ($done);
            }

        # Check if we reached max time for timeout (only if end_time is defined)
        } elsif( $end_time > 0 ) {

            $done = (time >= $end_time) ? 1 : 0;

            # Read last chars in read queue
            if( $done )
            {
                $me->log->write('info', 'reached timeout max wait without response');
            }

        # Else we have done
        } else {

            $done = 1;
        }

        $me->log->write('debug', 'done='.$done.' end='.$end_time.' now='.time().' start='.$start_time );

    } while (not $done);

    $me->log->write('info', 'answer: read ['.($answer||'').']' );

    # Flush receive and trasmit buffers
    $me->port->purge_all;

    return $answer;

}

sub answer {

    my $me = shift();
    my $answer = $me->_answer(@_);

    # Trim result of beginning and ending CR+LF (XXX)
    if( defined $answer ) {
        $answer =~ s/^[\r\n]+//;
        $answer =~ s/[\r\n]+$//;
    }

    $me->log->write('info', 'answer: `'.($answer||'').'\'' );

    return $answer;
}

# parse_answer() cleans out answer() result as response code +
# useful information (useful in informative commands, for example
# Gsm command AT+CGMI)
sub parse_answer {
    my $me = shift;

    my $buff = $me->answer( @_ );

    # Separate response code from information
    if( defined $buff && $buff ne '' ) {

        my @buff = split /[\r\n]+/o, $buff;

        # Remove all empty lines before/after response
        shift @buff while $buff[0]  =~ /^[\r\n]+/o;
        pop   @buff while $buff[-1] =~ /^[\r\n]+/o;

        # Extract responde code
        $buff = join( CR, @buff );
        my $code = pop @buff;

        return
            wantarray
            ? ($code, @buff)
            : $buff;

    } else {

        return '';

    }

}

1;

=head1 NAME

Device::Modem - Perl extension to talk to modem devices connected via serial port

=head1 WARNING

This is B<BETA> software, so use it at your own risk,
and without B<ANY> warranty! Have fun.

=head1 SYNOPSIS

  use Device::Modem;

  my $modem = Device::Modem->new( port => '/dev/ttyS1' );

  if( $modem->connect( baudrate => 9600 ) ) {
      print "connected!\n";
  } else {
      print "sorry, no connection with serial port!\n";
  }

  $modem->attention();          # send `attention' sequence (+++)

  ($ok, $answer) = $modem->dial('02270469012');  # dial phone number
  $ok = $modem->dial(3);        # 1-digit parameter = dial number stored in memory 3

  $modem->echo(1);              # enable local echo (0 to disable)

  $modem->offhook();            # Take off hook (ready to dial)
  $modem->hangup();             # returns modem answer

  $modem->is_active();          # Tests whether modem device is active or not
                                # So far it works for modem OFF/ modem ON condition

  $modem->reset();              # hangup + attention + restore setting 0 (Z0)

  $modem->restore_factory_settings();  # Handle with care!
  $modem->restore_factory_settings(1); # Same with preset profile 1 (can be 0 or 1)

  $modem->send_init_string();   # Send initialization string
                                # Now this is fixed to 'AT H0 Z S7=45 S0=0 Q0 V1 E0 &C0 X4'

  # Get/Set value of S1 register
  my $S1 = $modem->S_register(1);
  my $S1 = $modem->S_register(1, 55); # Don't do that if you definitely don't know!

  # Get status of managed signals (CTS, DSR, RLSD, RING)
  my %signal = $modem->status();
  if( $signal{DSR} ) { print "Data Set Ready signal active!\n"; }

  # Stores this number in modem memory number 3
  $modem->store_number(3, '01005552817');

  $modem->repeat();             # Repeat last command

  $modem->verbose(1);           # Normal text responses (0=numeric codes)

  # Some raw AT commands
  $modem->atsend( 'ATH0' );
  print $modem->answer();

  $modem->atsend( 'ATDT01234567' . Device::Modem::CR );
  print $modem->answer();


=head1 DESCRIPTION

C<Device::Modem> class implements basic B<AT (Hayes) compliant> device abstraction.
It can be inherited by sub classes (as C<Device::Gsm>), which are based on serial connections.


=head2 Things C<Device::Modem> can do

=over 4

=item *

connect to a modem on your serial port

=item *

test if the modem is alive and working

=item *

dial a number and connect to a remote modem

=item *

work with registers and settings of the modem

=item *

issue standard or arbitrary C<AT> commands, getting results from modem

=back

=head2 Things C<Device::Modem> can't do yet

=over 4

=item *

Transfer a file to a remote modem

=item *

Control a terminal-like (or a PPP) connection. This should really not
be very hard to do anyway.

=item *

Many others...

=back

=head2 Things it will never be able to do

=over 4

=item *

Coffee :-)

=back


=head2 Examples

In the `examples' directory, there are some scripts that should work without big problems,
that you can take as (yea) examples:

=over 4

=item `examples/active.pl'

Tests if modem is alive

=item `examples/caller-id.pl'

Waits for an incoming call and displays date, time and phone number of the caller.
Normally this is available everywhere, but you should check your local phone line
and settings.

=item `examples/dial.pl'

Dials a phone number and display result of call

=item `examples/shell.pl'

(Very) poor man's minicom/hyperterminal utility

=item `examples/xmodem.pl'

First attempt at a test script to receive a file via xmodem protocol.
Please be warned that this thing does not have a chance to work. It's
only a (very low priority) work in progress...

If you want to help out, be welcome!


=back

=head1 METHODS

=head2 answer()

One of the most used methods, waits for an answer from the device. It waits until
$timeout (seconds) is reached (but don't rely on this time to be very correct) or until an
expected string is encountered. Example:

	$answer = $modem->answer( [$expect [, $timeout]] )

Returns C<$answer> that is the string received from modem stripped of all
B<Carriage Return> and B<Line Feed> chars B<only> at the beginning and at the end of the
string. No in-between B<CR+LF> are stripped.

Note that if you need the raw answer from the modem, you can use the _answer() (note
that underscore char before answer) method, which does not strip anything from the response,
so you get the real modem answer string.

Parameters:

=over 4

=item *

C<$expect> - Can be a regexp compiled with C<qr> or a simple substring. Input coming from the
modem is matched against this parameter. If input matches, result is returned.

=item *

C<$timeout> - Expressed in milliseconds. After that time, answer returns result also if nothing
has been received. Example: C<10000>. Default: C<$Device::Modem::TIMEOUT>, currently 500 ms.

=back



=head2 atsend()

Sends a raw C<AT> command to the device connected. Note that this method is most used
internally, but can be also used to send your own custom commands. Example:

	$ok = $modem->atsend( $msg )

The only parameter is C<$msg>, that is the raw AT command to be sent to
modem expressed as string. You must include the C<AT> prefix and final
B<Carriage Return> and/or B<Line Feed> manually. There is the special constant
C<CR> that can be used to include such a char sequence into the at command.

Returns C<$ok> flag that is true if all characters are sent successfully, false
otherwise.

Example:

	# Enable verbose messages
	$modem->atsend( 'AT V1' . Device::Modem::CR );

	# The same as:
	$modem->verbose(1);


=head2 attention()

This command sends an B<attention> sequence to modem. This allows modem
to pass in B<command state> and accept B<AT> commands. Example:

	$ok = $modem->attention()

=head2 connect()

Connects C<Device::Modem> object to the specified serial port.
There are options (the same options that C<Device::SerialPort> has) to control
the parameters associated to serial link. Example:

	$ok = $modem->connect( [%options] )

List of allowed options follows:

=over 4

=item C<baudrate>

Controls the speed of serial communications. The default is B<19200> baud, that should
be supported by all modern modems. However, here you can supply a custom value.
Common speed values: 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600,
115200.
This parameter is handled directly by C<Device::SerialPort> object.

=item C<databits>

This tells how many bits your data word is composed of.
Default (and most common setting) is C<8>.
This parameter is handled directly by C<Device::SerialPort> object.

=item C<handshake>

Sets the handshake (or flow control) method for the serial port.
By default it is C<none>, but can be either C<rts> (hardware flow control)
or C<xoff> (software flow control). These flow control modes may or may not
work depending on your modem device or software.

=item C<init_string>

Custom initialization string can be supplied instead of the built-in one, that is the
following: C<H0 Z S7=45 S0=0 Q0 V1 E0 &C0 X4>, that is taken shamelessly from
C<minicom> utility, I think.

=item C<parity>

Controls how parity bit is generated and checked.
Can be B<even>, B<odd> or B<none>. Default is B<none>.
This parameter is handled directly by C<Device::SerialPort> object.

=item C<stopbits>

Tells how many bits are used to identify the end of a data word.
Default (and most common usage) is C<1>.
This parameter is handled directly by C<Device::SerialPort> object.

=back



=head2 dial()

Dials a telephone number. Can perform both voice and data calls.

Usage:

	$ok = $modem->dial($number);
    $ok = $modem->dial($number, $timeout);
    $ok = $modem->dial($number, $timeout, $mode);

Takes the modem off hook, dials the specified number and returns
modem answer.

Regarding voice calls, you B<will not> be able to send your voice through.
You probably have to connect an analog microphone, and just speak.
Or use a GSM phone. For voice calls, a simple C<;> is appended to the
number to be dialed.

If the number to dial is 1 digit only, extracts the number from the address book, provided your device has one. See C<store_number()>.

Examples:

	# Simple usage. Timeout and mode are optional.
    $ok = $mode->dial('123456789');

	# List context: allows to get at exact modem answer
	# like `CONNECT 19200/...', `BUSY', `NO CARRIER', ...
    # Also, 30 seconds timeout
	($ok, $answer) = $modem->dial('123456789', 30);

If called in B<scalar context>, returns only success of connection.
If modem answer contains the C<CONNECT> string, C<dial()> returns
successful state, otherwise a false value is returned.

If called in B<list context>, returns the same C<$ok> flag, but also the
exact modem answer to the dial operation in the C<$answer> scalar.
C<$answer> typically can contain strings like:

=over 4

=item C<CONNECT 19200>

=item C<NO CARRIER>

=item C<BUSY>

=back

and so on ... all standard modem answers to a dial command.

Parameters are:

=over 4

=item C<$number>

B<mandatory>, this is the phone number to dial.
If C<$number> is only 1 digit, it is interpreted as:
B<dial number in my address book position C<$number>>.

So if your code is:

	$modem->dial( 2, 10 );

This means: dial number in the modem internal address book
(see C<store_number> for a way to read/write address book)
in position number B<2> and wait for a timeout of B<10> seconds.

=item C<$timeout>

B<optional>, default is B<30 seconds>.

Timeout expressed in seconds to wait for the remote device
to answer. Please do not expect an B<exact> wait for the number of
seconds you specified.

=item C<$mode>

B<optional>, default is C<DATA>, as string.
Allows to specify the type of call. Can be either:

=over 4

=item C<DATA> (default)

To perform a B<data call>.

=item C<VOICE>

To perform a B<voice call>, if your device supports it.
No attempt to verify whether your device can do that will be made.

=back

=back

=head2 disconnect()

Disconnects C<Device::Modem> object from serial port. This method calls underlying
C<disconnect()> of C<Device::SerialPort> object.
Example:

	$modem->disconnect();

=head2 echo()

Enables or disables local echo of commands. This is managed automatically by C<Device::Modem>
object. Normally you should not need to worry about this. Usage:

	$ok = $modem->echo( $enable )

=head2 hangup()

Does what it is supposed to do. Hang up the phone thus terminating any active call.
Usage:

	$ok = $modem->hangup();

=head2 is_active()

Can be used to check if there is a modem attached to your computer.
If modem is alive and responding (on serial link, not to a remote call),
C<is_active()> returns true (1), otherwise returns false (0).

Test of modem activity is done through DSR (Data Set Ready) signal. If
this signal is in off state, modem is probably turned off, or not working.
From my tests I've found that DSR stays in "on" state after more or less
one second I turn off my modem, so know you know that.

Example:

	if( $modem->is_active() ) {
		# Ok!
	} else {
		# Modem turned off?
	}

=head2 log()

Simple accessor to log object instanced at object creation time.
Used internally. If you want to know the gory details, see C<Device::Modem::Log::*> objects.
You can also see the B<examples> for how to log something without knowing
all the gory details.

Hint:
	$modem->log->write('warning', 'ok, my log message here');

=head2 new()

C<Device::Modem> constructor. This takes several options. A basic example:

	my $modem = Device::Modem->new( port => '/dev/ttyS0' );

if under Linux or some kind of unix machine, or

	my $modem = Device::Modem->new( port => 'COM1' );

if you are using a Win32 machine.

This builds the C<Device::Modem> object with all the default parameters.
This should be fairly usable if you want to connect to a real modem.
Note that I'm testing it with a B<3Com US Robotics 56K Message> modem
at B<19200> baud and works ok.

List of allowed options:

=over 4

=item *

C<port> - serial port to connect to. On Unix, can be also a convenient link as
F</dev/modem> (the default value). For Win32, C<COM1,2,3,4> can be used.

=item *

C<log> - this specifies the method and eventually the filename for logging.
Logging process with C<Device::Modem> is controlled by B<log plugins>, stored under
F<Device/Modem/Log/> folder. At present, there are two main plugins: C<Syslog> and C<File>.
C<Syslog> does not work with Win32 machines.
When using C<File> plug-in, all log information will be written to a default filename
if you don't specify one yourself. The default is F<%WINBOOTDIR%\temp\modem.log> on
Win32 and F</var/log/modem.log> on Unix.

Also there is the possibility to pass a B<custom log object>, if this object
provides the following C<write()> call:

	$log_object->write( $loglevel, $logmessage )

You can simply pass this object (already instanced) as the C<log> property.

Examples:

	# For Win32, default is to log in "%WINBOOTDIR%/temp/modem.log" file
	my $modem = Device::Modem->new( port => 'COM1' );

	# Unix, custom logfile
	my $modem = Device::Modem->new( port => '/dev/ttyS0', log => 'file,/home/neo/matrix.log' )

	# With custom log object
	my $modem = Device::modem->new( port => '/dev/ttyS0', log => My::LogObj->new() );

=item *

C<loglevel> - default logging level. One of (order of decrescent verbosity): C<debug>,
C<verbose>, C<notice>, C<info>, C<warning>, C<err>, C<crit>, C<alert>, C<emerg>.

=back


=head2 offhook()

Takes the modem "off hook", ready to dial. Normally you don't need to use this.
Also C<dial()> goes automatically off hook before dialing.



=head2 parse_answer()

This method works like C<answer()>, it accepts the same parameters, but it
does not return the raw modem answer. Instead, it returns the answer string
stripped of all B<CR>/B<LF> characters at the beginning B<and> at the end.

C<parse_answer()> is meant as an easy way of extracting result code
(C<OK>, C<ERROR>, ...) and information strings that can be sent by modem
in response to specific commands. Example:

	> AT xSHOW_MODELx<CR>
	US Robotics 56K Message
	OK
	>

In this example, C<OK> is the result and C<US Robotics 56K Message> is the
informational message.

In fact, another difference with C<answer()> is in the return value(s).
Here are some examples:

	$modem->atsend( '?my_at_command?' );
	$answer = $modem->parse_answer();

where C<$answer> is the complete response string, or:

	($result, @lines) = $modem->parse_answer();

where C<$result> is the C<OK> or C<ERROR> final message and C<@lines> is
the array of information messages (one or more lines). For the I<model> example,
C<$result> would hold "C<OK>" and C<@lines> would consist of only 1 line with
the string "C<US Robotics 56K Message>".


=head2 port()

Used internally. Accesses the C<Device::SerialPort> underlying object. If you need to
experiment or do low-level serial calls, you may want to access this. Please report
any usage of this kind, because probably (?) it is possible to include it in a higher
level method.

As of 1.52, C<port()> will automatically try to reconnect if it detects
a bogus underlying port object. It will reconnect with the same options used
when C<connect()>ing the first time.

If no connection has taken place yet, then B<no attempt to automatically reconnect>
will be attempted.

=head2 repeat()

Repeats the last C<AT> command issued.
Usage:

	$ok = $modem->repeat()


=head2 reset()

Tries in any possible way to reset the modem to the starting state, hanging up all
active calls, resending the initialization string and preparing to receive C<AT>
commands.



=head2 restore_factory_settings()

Restores the modem default factory settings. There are normally two main "profiles",
two different memories for all modem settings, so you can load profile 0 and profile 1,
that can be different depending on your modem manufacturer.

Usage:

	$ok = $modem->restore_factory_settings( [$profile] )

If no C<$profile> is supplied, C<0> is assumed as default value.

Check on your modem hardware manual for the meaning of these B<profiles>.



=head2 S_register()

Gets or sets an B<S register> value. These are some internal modem registers that
hold important information that controls all modem behaviour. If you don't know
what you are doing, don't use this method. Usage:

	$value = $modem->S_register( $reg_number [, $new_value] );

C<$reg_number> ranges from 0 to 99 (sure?).
If no C<$new_value> is supplied, return value is the current register value.
If a C<$new_value> is supplied (you want to set the register value), return value
is the new value or C<undef> if there was an error setting the new value.

<!-- Qui &egrave; spiegata da cani -->

Examples:

	# Get value of S7 register
	$modem->S_register(7);

	# Set value of S0 register to 0
	$modem->S_register(0, 0);


=head2 send_init_string()

Sends the initialization string to the connected modem. Usage:

	$ok = $modem->send_init_string( [$init_string] );

If you specified an C<init_string> as an option to C<new()> object constructor,
that is taken by default to initialize the modem.
Else you can specify C<$init_string> parameter to use your own custom initialization
string. Be careful!

=head2 status()

Returns status of main modem signals as managed by C<Device::SerialPort> (or C<Win32::SerialPort>) objects.
The signals reported are:

=over 4

=item CTS

Clear to send

=item DSR

Data set ready

=item RING

Active if modem is ringing

=item RLSD

??? Released line ???

=back

Return value of C<status()> call is a hash, where each key is a signal name and
each value is > 0 if signal is active, 0 otherwise.
Usage:

	...
	my %sig = $modem->status();
	for ('CTS','DSR','RING','RLSD') {
		print "Signal $_ is ", ($sig{$_} > 0 ? 'on' : 'off'), "\n";
	}

=head2 store_number()

Store telephone number in modem internal address book, to be dialed later (see C<dial()> method).
Usage:

	$ok = $modem->store_number( $position, $number )

where C<$position> is the address book memory slot to store phone number (usually from 0 to 9),
and C<$number> is the number to be stored in the slot.
Return value is true if operation was successful, false otherwise.

=head2 verbose()

Enables or disables verbose messages. This is managed automatically by C<Device::Modem>
object. Normally you should not need to worry about this. Usage:

	$ok = $modem->verbose( $enable )

=head2 wait()

Waits (yea) for a given amount of time (in milliseconds). Usage:

	$modem->wait( [$msecs] )

Wait is implemented via C<select> system call.
Don't know if this is really a problem on some platforms.

=head2 write_drain()

Only a simple wrapper around C<Device::SerialPort::write_drain> method.
Disabled for Win32 platform, that doesn't have that.


=head1 REQUIRES

=over 4

=item Device::SerialPort (Win32::SerialPort for Win32 machines)

=back

=head1 EXPORT

None



=head1 TO-DO

=over 4

=item AutoScan

An AT command script with all interesting commands is run
when `autoscan' is invoked, creating a `profile' of the
current device, with list of supported commands, and database
of brand/model-specific commands

=item Serial speed auto-detect

Now if you connect to a different baud rate than that of your modem,
probably you will get no response at all. It would be nice if C<Device::Modem>
could auto-detect the speed to correctly connect at your modem.

=item File transfers

It would be nice to implement C<[xyz]modem> like transfers between
two C<Device::Modem> objects connected with two modems.

=back


=head1 FAQ

There is a minimal FAQ document for this module online at
L<http://www.streppone.it/cosimo/work/perl/CPAN/Device-Modem/FAQ.html>

=head1 SUPPORT

Please feel free to contact me at my e-mail address L<cosimo@cpan.org>
for any information, to resolve problems you can encounter with this module
or for any kind of commercial support you may need.

=head1 AUTHOR

Cosimo Streppone, L<cosimo@cpan.org>

=head1 COPYRIGHT

(C) 2002-2014 Cosimo Streppone, L<cosimo@cpan.org>

This library is free software; you can only redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Device::SerialPort,
Win32::SerialPort,
Device::Gsm,
perl

=cut

# vim: set ts=4 sw=4 tw=120 nowrap nu
