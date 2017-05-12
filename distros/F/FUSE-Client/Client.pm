package FUSE::Client;

require 5;
use strict;

use vars qw($VERSION @ISA @EXPORT);

use IO::Socket;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '1.08';

sub new {
	my ($class,$params) = @_;
	my $self = {};
	bless $self,ref $class || $class;
	$self->{quiet} = ${$params}{Quiet};
	$self->{port} = ${$params}{Port} || 1024;
	$self->{sock} = 0;
	return $self;
}

sub connect {
	my ($self,$host) = @_;
	$self->{sock} = new IO::Socket::INET ( PeerAddr => $host, PeerPort => $self->{port}, Proto => 'tcp' );
	$self->{sock}->autoflush(1);
	die "Could not create socket: $!\n" unless $self->{sock};
}

sub disconnect {
	my ($self) = @_;
	close($self->{sock});
}

sub send {
	my ($self,$msg,$params) = @_;

	$msg = "$msg $params";
	my $msg_frm = sprintf("%04d%s",length($msg),$msg);

	print "sending $msg_frm\n" unless $self->{Quiet};

	syswrite($self->{sock}, $msg_frm, length($msg_frm));
}


1;
__END__

=head1 NAME

FUSE::Client - Perl-FUSE client

=head1 SYNOPSIS

  use FUSE::Client;
  $c = FUSE::Client->new({
      Port=>35008,
      Quiet=>1,
  });

  $c->connect();
  $c->send("COMMAND","parameter");
  $c->disconnect();

=head1 DESCRIPTION

The C<FUSE::Client> module will create a TCP FUSE client to test sending messages to a FUSE server.

The external interface to C<FUSE::Client> is:

=over 4

=item $c = FUSE::Client->new( [%options] );

The object constructor takes the following arguments in the options hash:

B<Quiet = 0|1>

Whether to be quiet. Default is to report all events to STDOUT (not 'Quiet').

B<Port = n>

The port for the client to connect to. Default is 1024.


=item $c->connect();

This method connects the client to the server.


=item $c->disconnect();

This method disconnects the client from the server.


=item $c->send( $command, $parameter );

Send a FUSE formatted command message to the server, with the specified parameter.

=back

=head1 AUTHOR

Cal Henderson, <cal@iamcal.com>

=cut
