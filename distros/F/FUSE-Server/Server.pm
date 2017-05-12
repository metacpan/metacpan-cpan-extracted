package FUSE::Server;

require 5;
use strict;

use vars qw($VERSION @ISA @EXPORT);

use IO::Socket;
use IO::Select;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '1.19';

my $nextid = 0;

sub new {
	my ($class,$params) = @_;
	my $self = {};
	bless $self,ref $class || $class;
	$self->{quiet} = ${$params}{Quiet};
	$self->{port} = ${$params}{Port} || 1024;
	$self->{maxc} = ${$params}{MaxClients} || SOMAXCONN;
	$self->{max_msglen} = 1024;
	$self->{server_sock} = 0;
	$self->{sel} = 0;
	$self->{users} = {};
	return $self;
}

sub bind {
	my ($self) = @_;

	$self->{server_sock} = IO::Socket::INET->new(Proto=>"tcp", LocalPort=>$self->{port}, Listen=>$self->{maxc}, Reuse=>1);
	$self->{sel} = IO::Select->new($self->{server_sock});

	return $self->{server_sock}->sockhost();
}

sub start {
	my ($self) = @_;

	while (my @ready = $self->{sel}->can_read) {

		foreach my $client (@ready) {

			if ($client == $self->{server_sock}) {

				my $add = $client->accept;
				$add->blocking(0);
				$self->{sel}->add($add);
				$self->newsession($add);
			}else{

				my ($in,$msg,$nread,$nsafe);

				do {
					$nread = sysread($client, $in, 1024);
					$msg .= $in;
					$nsafe = 0;
					if (defined($nread)){
						$nsafe = $nread;
					}
				} while ($nsafe == 1024);

				if (defined($nread)) {
					if ($nread == 0){
						$self->{sel}->remove($client);
						$self->endsession($client);
						close($client);
					}
				}

				if (defined($msg)){
					if ($msg){
						$self->incoming($client, $msg);
					}
				}
			}
		}
	}
}

sub stop{
	my ($self) = @_;

	close($self->{server_sock});
}

sub addCallback{
	my ($self,$msg,$coderef) = @_;
	$self->{callbacks}{$msg} = $coderef;
}

sub defaultCallback{
	my ($self,$coderef) = @_;
	$self->{def_callback} = $coderef;
}

sub send{
	my ($self,$uid,$msg,$params) = @_;

	for (keys %{$self->{users}}){
		if ($self->{users}{$_}{id} == $uid){
			my $sock = $self->{users}{$_}{sock};
			print $sock "# $msg\cM";
			print $sock "$params\cM";
			print $sock "##\cM\cJ";
			last;
		}
	}
}

sub sendAll{
	my ($self,$msg,$params) = @_;
	for (keys %{$self->{users}}){
		$self->send($self->{users}{$_}{id},$msg,$params);
	}
}


##########

sub newsession {
	my ($self,$sock) = @_;
	$nextid++;
	$self->{users}{$sock}{sock} = $sock;
	$self->{users}{$sock}{host} = $sock->peerhost;
	$self->{users}{$sock}{id} = $nextid;
	$self->{users}{$sock}{buffer} = '';

	unless ($self->{quiet}){
		print "new connection: ";
		print $self->{users}{$sock}{id};
		print " (";
		print $self->{users}{$sock}{host};
		print ")\n";
	}

	$self->packet($sock, 'client_start', '');
}

sub endsession {
	my ($self,$sock) = @_;

	unless ($self->{quiet}){
		print "connection closed: ";
		print $self->{users}{$sock}{id};
		print "\n";
	}

	$self->packet($sock, 'client_stop', '');

	delete $self->{users}{$sock};
}

sub incoming{
	my ($self,$sock,$data) = @_;

	my $id = $self->{users}{$sock}{id};
	$self->{users}{$sock}{buffer} .= $data;

	my $ok = 1;
	my $buffer = $self->{users}{$sock}{buffer};
	while ($ok){
		$ok = 0;
		if (length($buffer) > 4){
			my $size = substr($buffer,0,4);
			$size =~ s/[^0-9]//g;
			$size += 0;
			if (length($buffer) >= 4 + $size){
				my $packet = substr($buffer,4,$size);
				my $a = index($packet,' ');
				my $msg = substr($packet,0,$a);
				my $param = substr($packet,$a+1);
				$self->packet($sock,$msg,$param);
				$buffer = substr($buffer,4+$size);
				$ok=1;
			}
		}
	}
	$self->{users}{$sock}{buffer} = $buffer;
}

sub packet {
	my ($self,$sock,$msg,$params) = @_;

	my $uid = $self->{users}{$sock}{id};

	unless($self->{quiet}){
		print "packet sent to $uid: $msg\n";
	}

	if ($self->{callbacks}{$msg}){
		&{$self->{callbacks}{$msg}}($uid,$msg,$params);
	}else{
		if ($self->{def_callback}){
			&{$self->{def_callback}}($uid,$msg,$params);
		}
	}
}


1;
__END__

=head1 NAME

FUSE::Server - Perl-FUSE server

=head1 SYNOPSIS

  use FUSE::Server;
  my $s = FUSE::Server->new({
      Port=>35008,
      MaxClients=>5000,
      Quiet=>1,
  });

  my $status = $s->bind();
  print "Server started: $status";

  $s->addCallback('BROADCASTALL',\&msg_broadcast);

  $s->addCallback('client_start',\&msg_client_start);

  $s->defaultCallback(\&unknown_command);

  $SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub{$s->stop();};

  $s->start();

  sub msg_broadcast{
      my ($userid,$msg,$params) = @_;
      my @a = split /\//,$params;
      $s->sendAll($a[1],$a[2]);
  }

  sub msg_client_start{
      my ($userid,$msg,$params) = @_;
      $s->send($userid,'SECRET_KEY','123 456 789');
  }

  sub unknown_command{
      my ($userid,$msg,$params) = @_;
      print "Unknown command $msg\n";
  }


=head1 DESCRIPTION

The C<FUSE::Server> module will create a TCP FUSE server and dispatch messages to registered event handlers.

The external interface to C<FUSE::Server> is:

=over 4

=item $s = FUSE::Server->new( [%options] );

The object constructor takes the following arguments in the options hash:

B<Quiet = 0|1>

Whether to be quiet. Default is to report all events to STDOUT (not 'Quiet').

B<Port = n>

The port for the server to listen on. Default is 1024.

B<MaxClients = n>

Maximum incoming connections to allow. Default is SOMAXCONN.


=item $s->bind();

This method starts the server listening on it's port and returns the IP which it is listening on.


=item $s->addCallback( $message, $coderef );

This method registers the referenced subroutine as a handler for the specified message. When the server receives that message from the client, it checks it's handler hash and dispatches the decoded message to the sub. The sub should handle the following arguments:

C<( $userid, $msg, $params )>

$userid contains the internal connection id for the client session. You can use this id to associate logins with clients. The $msg parameter contains the message the client sent. This allows one routine to handle more than one message. Messages from clients are typically uppercase, with lowercase messages being reserved for internal server events, such as client connect/disconnect. The available internal messages are:

B<client_start>

This message is sent when a client first connects. It is typically used to issue a I<SECRET_KEY> message to the client.

B<client_stop>

This message is sent when a client disconnects.


=item $s->defaultCallback( $coderef );

For all messages without an assigned handler, the default handler (if set) is sent the message. If you'd like to handle all messages internally, then setup C<defaultCallback> without setting up any normal C<addCallback>'s.


=item $s->stop();

This method shuts down the server gracefully. Since the C<start> method loops forever, the C<stop> method is generally set up to run on a signal.


=item $s->start();

This method invokes the server's internal message pump. This loop can only be broken by a signal.

=item $s->send( $userid, $message, $params );

This method sends a message to a single client.

=item $s->sendAll( $message, $params );

This method broadcasts a message to all clients.

=back

=head1 AUTHOR

Cal Henderson, <cal@iamcal.com>

=cut
