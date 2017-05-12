# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id: SDNP.pm 105 2009-05-18 10:52:03Z hasiotis $

package EAFDSS::SDNP;

=head1 NAME

EAFDSS::SDNP - EAFDSS Driver for Micrelec SDNP Devices

=head1 DESCRIPTION

Read EAFDSS on how to use the module. This module implements the part of the micrelec protocol
specific to the ethernet model.

=cut

use 5.006_000;
use strict;
use warnings;
use POSIX;

use Carp;
use Class::Base;
use Socket;
use IO::Socket::INET;

use base qw (EAFDSS::Micrelec );

our($VERSION) = '0.80';

my($clock_ticks);
if ( $^O =~ /MSWin32/ ) {
	$clock_ticks = 1000;
} else {
	$clock_ticks = POSIX::sysconf(&POSIX::_SC_CLK_TCK);
}


=head2 init

The constructor

=cut

sub init {
	my($class)  = shift @_;
	my($config) = @_;
	my($self)   = $class->SUPER::init(@_);

	$self->debug("Initializing");

	if (! exists $config->{PARAMS}) {
		return $self->error("No parameters have been given!");
	} else {
		$self->{IP}    = $config->{PARAMS};
		$self->{PORT}  = 24222;
	}

	$self->debug("  Socket Initialization to IP/hostname [%s]", $self->{IP});
	$self->{_SOCKET} = IO::Socket::INET->new(PeerPort => $self->{PORT}, Proto => 'udp', PeerAddr => $self->{IP});
	if (! defined $self->{_SOCKET}) {
		return undef;
	}

	$self->debug("  Setting timers");
	$self->_setTimer('_TSYNC', 0);
	$self->_setTimer('_T0', 0);
	$self->_setTimer('_T1', 0);

	$self->debug("  Setting frame counter to 1");
	$self->{_FSN}   = 1;


	my($reply, $deviceID) = $self->PROTO_ReadDeviceID();
	$self->debug("  Read device ID");
	if ( ($reply == 0) && ($deviceID ne $self->{SN}) ) {
		return $self->error("Serial Number not matching");
	}

	$self->debug("  Init OK");
	return $self;
}

=head2 SendRequest

The ethernet version of SendRequest command.

=cut

sub SendRequest {
	my($self)   = shift @_;
	my($opcode) = shift @_;
	my($opdata) = shift @_;
	my($data)   = shift @_;

	my(%reply) = ();

	# For at least 6 times do:
	my($busy_try, $state, $try);
	BUSY: for ($busy_try = 1; $busy_try <= 3; $busy_try++) {
		for ($try = 1; $try < 6; $try++) {
			my(%reply)  = ();
			$self->debug("    Send Request try #%d", $try);
			SYNC:
			# If state is UNSYNCHRONIZED or connection SYNC timer expired then:
			if ($self->_getTimer('_TSYNC') >= 0) {
				$self->debug("      Syncing with device");
				if ( $self->_sdnpSync() == 0) {
					$self->debug("        Sync Failed");
					$self->error(64+3);
					return %reply;
				}
			}

			SEND:
			# Send REQUEST(Connection's NextFSN) using 'RequestDataPacket';
			my($msg) = $self->_sdnpPacket($opcode, $opdata, $data);
			$self->_sdnpPrintFrame("      ----> [%s]", $msg);
			$self->{_SOCKET}->send($msg);

			# Set T0 timer to 800 milliseconds;
			$self->_setTimer('_T0', 0.800);
		
			# Do until T0 expires:
			while ($self->_getTimer('_T0') <= 0) {
				my($frame)  = undef;
	
				$self->{_SOCKET}->recv($frame, 512);
				if ($frame) {
					%reply = $self->_sdnpAnalyzeFrame($frame);
					$self->_sdnpPrintFrame("      <---- [%s]", $msg);
					$reply{'HOST'} = $self->{_SOCKET}->peerhost();
				} else {
					$reply{HOST} = -1;
				}

				# If a valid SDNP frame received then do
				if ($self->_sdnpFrameCheck(\%reply)) {
					# If received frame's FSN <> Request frame's FSN
					if ($self->{_FSN} != $reply{SN}) {
						$self->debug("        Bad FSN, Discarding\n");
						next;
					} else {
						# Test received frame's opcode;
						# Case RST:
						if ($reply{OPCODE} == 0x10) {
							# Set connection's state to UNSYNCHRONIZED;
							$self->_setTimer('_TSYNC', 0);
							goto SYNC;
						}
						# Case NAK:
						if ($reply{OPCODE} == 0x13) {
							goto SEND;
						}
						# Case REPLY:
						if ($reply{OPCODE} == 0x22) {
							# If received frame's data packet does not validate okay then:
							my($i, $checksum) = (0, 0xAA55);
							for ($i=0; $i < length($reply{DATA}); $i++) {
								$checksum += ord substr($reply{DATA}, $i, 1);
							}
							#$self->debug(  "        Checking Data checksum [%04X]", $checksum);
							if ($checksum != $reply{CHECKSUM}) {
								# Create and send NAK frame with FSN set to received FSN;
								my($msg) = $self->sdnpPacket(0x13, 0x00);
								$self->_sdnpPrintFrame("      ----> [%s]\n", $msg);
								$self->{_SOCKET}->send($msg);
								next;
							} else {
								if ( $reply{DATA} =~ /^0E/ ) {
									$self->debug("      Will retry because of busyness $busy_try");
									$state = "BUSY";
									sleep 2;
									next BUSY;
								} else {
									$self->debug("      Done Getting reply");

									# Renew connection's SYNC timer;
									$self->_setTimer('_TSYNC', 4);
	
									# Advance connection's NextFSN by one;
									$self->{_FSN}++;

									# Return request transmittion success;
									return %reply;
								}
							}
						}
						$self->debug(  "        Bad Frame, Discarding");
						next;
					}
				} else {
					$self->debug(  "        Bad Frame, Discarding");
				}
			}
		}
	}

	if ($state eq "BUSY") {
		$self->debug("      Too busy device... aborting");
		$reply{DATA}   = "0E/0/";
	}

	# Return request transmittion failure;
	return %reply;
}

sub _sdnpQuery {
	my($self)  = shift @_;
	my($devices);

	$self->_sdnpSendQuery();

	# Set timer T0 to 500 milliseconds;
	$self->_setTimer('_T0', 0.500);
		
	# Do until T0 expires:
	while ($self->_getTimer('_T0') <= 0) {
		my(%reply)  = ();
		my($frame)  = undef;

		my($query_socket) = IO::Socket::INET->new(
			LocalPort => $self->{PORT} + 1,
			Proto => 'udp',
		);

		if (! defined $query_socket) {
			return undef;
		}

		$query_socket->recv($frame, 512);
		if ($frame) {
			%reply = $self->_sdnpAnalyzeFrame($frame);
			$self->_sdnpPrintFrame("        <---- [%s]", $frame);
			$reply{'HOST'} = $query_socket->peerhost();

			# If a valid frame received then:
			if ($self->_sdnpQueryFrameCheck(\%reply)) {
				#If frame type is ACTIVE then:
				if ($reply{OPCODE} == 0x01) {
					#If ACTIVE(FSN) = QUERY(FSN) then:
					if ($self->{_FSN} == $reply{SN}) {
						#Add IP address of sender to device list;
						$self->debug("        Found host on IP %s", $reply{'HOST'});
						$devices->{$reply{'HOST'}} = 1;
					}
				}
			}
		}
		close($query_socket);

		$self->_setTimer('_T1', 0.500);
		if ($self->_getTimer('_T1') >= 0) {
			$self->_sdnpSendQuery();
			$self->_setTimer('_T1', 0.500);
		}
	}

	$self->_setTimer('_TSYNC', 0);

	return (0, $devices);
}

sub _sdnpSendQuery {
	my($self)  = shift @_;

	$self->{_SOCKET} = IO::Socket::INET->new(
		LocalPort => $self->{PORT} + 1,
		PeerAddr => inet_ntoa(INADDR_BROADCAST),
		PeerPort => $self->{PORT},
		Proto => 'udp',
		Type => SOCK_DGRAM,
		Broadcast => 1,
	);

	if (! defined $self->{_SOCKET}) {
		return undef;
	}

	$self->{_FSN} = int(rand(32768) + 1);

	$self->debug(  "      Send Query Request" );
	my($msg) = $self->_sdnpPacket(0x00, 0x00);
	$self->_sdnpPrintFrame("        ----> [%s]", $msg);
	$self->{_SOCKET}->send($msg);
	
	close($self->{_SOCKET});
}

sub _sdnpSync {
	my($self)  = shift @_;

	# Set connection state to UNSYNCHRONIZED;
	$self->_setTimer('_TSYNC', 0);
	
	# For at least 6 times do:
	my($try);
	for ($try = 1; $try < 6; $try++) {
		$self->debug(  "      Send Sync Request try #%d", $try);

		# Set timer T0 to 500 milliseconds;
		$self->_setTimer('_T0', 0.500);
		
		# Select a random initial FSN (IFSN); 
		$self->{_FSN} = int(rand(32768) + 1);

		# Send SYNC(IFSN) frame to connection IP address;
		my($msg) = $self->_sdnpPacket(0x11, 0x00);
		$self->_sdnpPrintFrame("        ----> [%s]", $msg);
		$self->{_SOCKET}->send($msg);

		# Do until T0 expires:
		while ($self->_getTimer('_T0') <= 0) {
			my(%reply)  = ();
			my($frame)  = undef;

			$self->{_SOCKET}->recv($frame, 512);
			if ($frame) {
				%reply = $self->_sdnpAnalyzeFrame($frame);
				$self->_sdnpPrintFrame("        <---- [%s]", $frame);
				$reply{'HOST'} = $self->{_SOCKET}->peerhost();
			} else {
				$reply{HOST} = -1;
			}

			# If a valid frame received then:
			if ($self->_sdnpFrameCheck(\%reply)) {
				# If frame type is ACK
				if ($reply{OPCODE} == 0x12) {
					# If ACK(FSN) = IFSN then:
					if ($self->{_FSN} == $reply{SN}) {
						# Set connection NextFSN = IFSN + 1;
						$self->{_FSN}++;

						# Set connection SYNC timer to 4 seconds;
						$self->_setTimer('_TSYNC', 4);

						# Reset T0 timer
						$self->_setTimer('_T0', 0);

						# Return sync success;
						return 1;
					} 
				} else {
					$self->debug(  "   SYNC NOT ACKed!");
				}
			}
		}
	}

	return 0;
}

sub _sdnpQueryFrameCheck {
	my($self)   = shift @_;
	my($frame)  = shift @_;

	$self->debug(  "    Checking Query Frame");

	# Check if size of UDP frame < size of SDNP header then: 
	$self->debug(  "        Checking frame size [%d]", length($frame->{RAW}));
	if (length($frame->{RAW}) < 12) {
		return 0;
	}

	# Check if size of UDP frame > 512 then:
	if (length($frame) > 512) {
		return 0;
	}

	# Check if SDNP header checksum does not validate okay then:
	my($i, $checksum) = (0, 0xAA55);
	for ($i=0; $i < 10 ; $i++) {
		$checksum += ord substr($frame->{RAW}, $i, 1);
	}
	$self->debug(  "        Checking frame header checksum [%04X]", $checksum);
	if ($checksum != $frame->{HEADER_CHECKSUM}) {
		return 0;
	}

	# Check if UDP frame size <> SDNP header data length +  SDNP header size then:
	$self->debug(  "        Checking UDP frame size [%d]", length($frame->{RAW}));
	if (length($frame->{RAW}) != 12 + $frame->{LENGTH}) {
		return 0;
	}

	# Check if frame id in SDNP header <> SDNP device protocol id then:
	$self->debug(  "        Checking frame id [%04X]", $frame->{ID});
	if ($frame->{ID} != 0x7A2D) {
		return 0;
	}

	# Return success;
	return 1;
}

sub _sdnpFrameCheck {
	my($self)   = shift @_;
	my($frame)  = shift @_;

	#$self->debug(  "    Checking Frame");

	# Check sender ip
	my($ip) = inet_ntoa(inet_aton($self->{IP})); 
	#$self->debug(  "        Comparing [%s][%s]", $frame->{HOST}, $ip);
	if ($frame->{HOST} ne $ip) {
		return 0;
	}

	# Check if size of UDP frame < size of SDNP header then: 
	#$self->debug(  "        Checking frame size [%d]", length($frame->{RAW}));
	if (length($frame->{RAW}) < 12) {
		return 0;
	}

	# Check if size of UDP frame > 512 then:
	if (length($frame) > 512) {
		return 0;
	}

	# Check if SDNP header checksum does not validate okay then:
	my($i, $checksum) = (0, 0xAA55);
	for ($i=0; $i < 10 ; $i++) {
		$checksum += ord substr($frame->{RAW}, $i, 1);
	}
	#$self->debug(  "        Checking frame header checksum [%04X]", $checksum);
	if ($checksum != $frame->{HEADER_CHECKSUM}) {
		return 0;
	}

	# Check if UDP frame size <> SDNP header data length +  SDNP header size then:
	#$self->debug(  "        Checking UDP frame size [%d]", length($frame->{RAW}));
	if (length($frame->{RAW}) != 12 + $frame->{LENGTH}) {
		return 0;
	}

	# Check if frame id in SDNP header <> SDNP device protocol id then:
	#$self->debug(  "        Checking frame id [%04X]", $frame->{ID});
	if ($frame->{ID} != 0x7A2D) {
		return 0;
	}

	# Return success;
	return 1;
}

sub _sdnpPacket {
	my($self)   = shift @_;

	my($i);

	my($frame_id) = 0xE18F;
	my($frame_sn) = $self->{_FSN};
	my($opcode)   = shift @_;
	my($opdata)   = shift @_; 
	my($data)     = shift @_; 
	my($length)   = 0x0000;
	my($checksum) = 0xAA55;
	my($header)   = 0xAA55;

	if ($data) {
		$length = length($data); 
		for ($i=0; $i < length($data); $i++) {
			$checksum += ord substr($data, $i, 1);
		}
	} else {
		$data = "";
	}

	my($retValue) = pack("SSCCSS", $frame_id, $frame_sn, $opcode, $opdata, $length, $checksum);
	for ($i=0; $i < length($retValue); $i++) {
		$header += ord substr($retValue, $i, 1);
	}

	return pack("SSCCSSS", $frame_id, $frame_sn, $opcode, $opdata, $length, $checksum, $header) . $data;
}

sub _sdnpPrintFrame {
	my($self)   = shift @_;
	my($format) = shift @_;
	my($msg)    = shift @_;

	my($i, $tmpString);
	for ($i=0; $i < 11; $i++) {
		$tmpString .= sprintf("%02X::", ord substr($msg, $i, 1));
	}
	$tmpString .= sprintf("%02X", ord substr($msg, length($msg) - 1, 1));
	$self->debug($format, $tmpString);

	my(%frame) = $self->_sdnpAnalyzeFrame($msg);
	#$self->debug("\t\t  ID..................[%04X]", $frame{ID});
	#$self->debug("\t\t  SN..................[%04X]", $frame{SN});
	#$self->debug("\t\t  OPCODE..............[  %02X]", $frame{OPCODE});
	#$self->debug("\t\t  OPDATA..............[  %02X]", $frame{OPDATA});
	#$self->debug("\t\t  LENGTH..............[%04X]", $frame{LENGTH});
	#$self->debug("\t\t  CHECKSUM............[%04X]", $frame{CHECKSUM});
	#$self->debug("\t\t  HEADER_CHECKSUM.....[%04X]", $frame{HEADER_CHECKSUM});
	#$self->debug("\t\t  DATA................[%s]", $frame{DATA});

	return; 
}

sub _sdnpAnalyzeFrame {
	my($self) = shift @_;
	my($msg)  = shift @_;

	my(%retValue) = ();

	$retValue{RAW} = $msg;
	$retValue{ID} = unpack("S", substr($msg,  0, 2));
	$retValue{SN} = unpack("S", substr($msg,  2, 2));
	$retValue{OPCODE} = unpack("C", substr($msg,  4, 1)); 
	$retValue{OPDATA} = unpack("C", substr($msg,  5, 1));
	$retValue{LENGTH} = unpack("S", substr($msg,  6, 2));
	$retValue{CHECKSUM} = unpack("S", substr($msg,  8, 2));
	$retValue{HEADER_CHECKSUM} = unpack("S", substr($msg,  10, 2));
	$retValue{DATA} = substr($msg, 12);

	return %retValue; 
}

sub _setTimer {
	my($self) = shift @_;
	my($t)    = shift @_;
	my($msec) = shift @_;

	my($realtime, $user, $system, $cuser, $csystem) = POSIX::times();

	$self->{$t}->{START}    = $realtime/$clock_ticks;
	$self->{$t}->{DURATION} = $msec; 
}

sub _getTimer {
	my($self) = shift @_;
	my($t)    = shift @_;

	my($realtime, $user, $system, $cuser, $csystem) = POSIX::times();

	#$self->debug("      TIMER[%s]: %4.4f - %4.4f", $t, $realtime/$clock_ticks - $self->{$t}->{START}, $self->{$t}->{DURATION});

	return $realtime/$clock_ticks - $self->{$t}->{START} - $self->{$t}->{DURATION};
}

# Preloaded methods go here.

1;
__END__


=head1 VERSION

This is version 0.80.

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
