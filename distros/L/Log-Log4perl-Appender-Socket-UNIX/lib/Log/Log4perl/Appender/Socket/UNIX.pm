##################################################
package Log::Log4perl::Appender::Socket::UNIX;
##################################################

our @ISA = qw(Log::Log4perl::Appender);

use warnings;
use strict;

use IO::Handle;
use Socket;

our $VERSION = "1.04";

##################################################
sub new {
##################################################
	my($class, @options) = @_;

	my $self = {
		name		=> "unknown name",
		Socket		=> "/var/tmp/$$.sock",
		@options,
	};

	bless $self, $class;

	$self->{socket_addr} = sockaddr_un($self->{Socket}); 
	socket(my $logsocket, PF_UNIX, SOCK_DGRAM, 0);
	$logsocket->blocking(0);
	$self->{socket_ref} = $logsocket;

	return $self;
}
	
##################################################
sub log {
##################################################
	my($self, %params) = @_;

	send($self->{socket_ref}, $params{message}, 0, $self->{socket_addr});
	return 1;
}

##################################################
sub DESTROY {
##################################################
	my($self) = @_;

	undef $self->{socket_ref};
}

1;

__END__

=head1 NAME

Log::Log4perl::Appender::Socket::UNIX- Log to a Unix Domain Socket

=head1 SYNOPSIS

	use Log::Log4perl::Appender::Socket::UNIX;

	my $appender = Log::Log4perl::Appender::Socket::UNIX->new(
		Socket => '/var/tmp/myprogram.sock'
	);

	$appender->log(message => "Log me\n");

=head1 DESCRIPTION

This is a simple appender for writing to a unix domain socket. It relies on
L<Socket> and only logs to an existing socket - ie. very useful to always log
debug streams to the socket. 

The appender tries to stream to a socket. The socket in questions is beeing
created by the client who wants to listen, once created the messages are coming thru.

=head1 EXAMPLE

Write a client quickly using the Socket module:

	use Socket;

	my $s = "/var/tmp/myprogram.sock";

	unlink($s) or die("Failed to unlin socket - check permissions.\n");

	# be sure to set a correct umask so that the appender is allowed to stream to:
	# umask(000);

	socket(my $socket, PF_UNIX, SOCK_DGRAM, 0);
	bind($socket, sockaddr_un($s));

	while (1) {
		while ($line = <$socket>) {
			print $line;
		}
	}


=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Jean Stebens E<lt>debian.helba@recursor.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

