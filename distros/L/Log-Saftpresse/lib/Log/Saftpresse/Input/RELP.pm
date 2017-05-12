package Log::Saftpresse::Input::RELP;

use Moose;

use Log::Saftpresse::Log4perl;

# ABSTRACT: RELP server input plugin for saftpresse
our $VERSION = '1.6'; # VERSION


extends 'Log::Saftpresse::Input::Server';

use Log::Saftpresse::Input::RELP::Frame;
use Log::Saftpresse::Input::RELP::RSP;
use Time::Piece;

sub handle_data {
	my ( $self, $conn ) = @_;
	my @events;
	while( defined( my $frame = $self->_read_frame($conn) ) ) {
		if( $frame->command eq 'open' ) {
			$self->cmd_open( $conn, $frame );
		} elsif( $frame->command eq 'close' ) {
			$self->cmd_close( $conn, $frame );
		} elsif( $frame->command eq 'syslog' ) {
			my $data = $self->cmd_syslog( $conn, $frame );
			if( defined $data ) {
				push( @events, { message => $data } );
			}
		}
	}
	return @events;
}

sub cmd_open {
	my ( $self, $conn, $frame ) = @_;
	my $resp;

  $log->debug('client announced: '.$frame->data);

	if( $frame->data =~ /^relp_version=0/ ) {
		$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
			$frame,
			command => 'rsp',
			data => Log::Saftpresse::Input::RELP::RSP->new(
				code => 200,
				message => 'OK',
				data => "relp_version=0\nrelp_software=saftpresse\ncommands=open,close,syslog",
			)->as_string,
		);
	} else {
		$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
			$frame,
			command => 'rsp',
			data => Log::Saftpresse::Input::RELP::RSP->new(
				code => 500,
				message => 'unsupported protocol version',
			)->as_string,
		);
    $log->error('client uses unsupported RELP protocol version');
	}

	$conn->print( $resp->as_string );

	return;
}

sub cmd_close {
	my ( $self, $conn, $frame ) = @_;
	my $resp;

  $log->info('peer '.$conn->peerhost.':'.$conn->peerport.' intialized connection shutdown');
	$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
		$frame,
		command => 'rsp',
		data => Log::Saftpresse::Input::RELP::RSP->new(
			code => 200,
			message => 'OK',
		)->as_string,
	);
	$conn->print( $resp->as_string );
	$self->shutdown_connection( $conn );

	return;
}

sub cmd_syslog {
	my ( $self, $conn, $frame ) = @_;
	my $resp;

	$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
		$frame,
		command => 'rsp',
		data => Log::Saftpresse::Input::RELP::RSP->new(
			code => 200,
			message => 'OK',
		)->as_string,
	);
	$conn->print( $resp->as_string );

	return $frame->data;
}

sub _read_frame {
	my ( $self, $conn ) = @_;
	my $frame;
	
	$frame = Log::Saftpresse::Input::RELP::Frame->new_from_fh($conn);

	return( $frame );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::RELP - RELP server input plugin for saftpresse

=head1 VERSION

version 1.6

=head1 Description

This plugin is a network input implementing the RELP protocol.

RELP is the Reliable Event Logging Protocol:

http://www.rsyslog.com/doc/relp.html

=head2 Synopsis

To send events from rsyslog to saftpresse configure rsyslog:

  $ModLoad omrelp
  *.* :omrelp:localhost:20514;RSYSLOG_ForwardFormat

You should also configure a queue to avoid loosing of events when
saftpresse is not running. For more information read:

http://www.rsyslog.com/doc/rsyslog_reliable_forwarding.html

In saftpresse configuration:

  # relp network server
  <Input rsyslog-input>
    module = "RELP"
    proto = "tcp"
    port = 20514
    listen = "127.0.0.1"
  </Input>
  
  # decode syslog format
  <Plugin syslog>
    module = "Syslog"
  </Plugin>

=head1 Input Format

This plugin will output an event for each recieved line with only the field

=over

=item message

The line recieved.

=back

Use a plugin to decode the content of the line.

For example the Syslog plugin could be used to decode the syslog line format.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
