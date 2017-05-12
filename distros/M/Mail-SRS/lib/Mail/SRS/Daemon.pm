package Mail::SRS::Daemon;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $SRSSOCKET);
use Exporter;
use IO::Socket;
use IO::Select;
use Getopt::Long;
use Mail::SRS qw(:all);

@ISA = qw(Exporter);

@EXPORT_OK = qw($SRSSOCKET);
%EXPORT_TAGS = (
		all	=> \@EXPORT_OK,
			);

$SRSSOCKET = '/tmp/srsd';

sub new {
	my $class = shift;
	my $args = ($#_ == 0) ? %{ (shift) } : { @_ };

	my @secrets = ref($args->{Secret}) eq 'ARRAY'
					? @{ $args->{Secret} }
					: [ $args->{Secret} ];

	if (exists $args->{SecretFile} && defined $args->{SecretFile}) {
		my $secretfile = $args->{SecretFile};
		die "Secret file $secretfile not readable"
						unless -r $secretfile;
		local *FH;
		open(FH, "<$secretfile")
						or die "Cannot open $secretfile: $!";
		while (<FH>) {
			next unless /\S/;
			next if /^#/;
			push(@secrets, $_);
		}
		close(FH);
	}

	die "No secret or secretfile given. Use --secret or --secretfile, ".
					"and ensure the secret file is not empty."
						unless @secrets;

	# Preserve the pertinent original arguments, mostly for fun.
	my $self = {
		Secret		=> $args->{Secret},
		SecretFile	=> $args->{SecretFile},
			};
	$self->{Socket} = delete $args->{Socket} if exists $args->{Socket};

	# An alternative pattern would be to inherit this, rather than
	# delegate to it.
	$args->{Secret} = \@secrets;
	# All other args are passed on verbatim.
	my $srs = new Mail::SRS($args);

	$self->{Instance} = $srs;

	return bless $self, $class;
}

sub run {
	my ($self) = @_;
	my $srs = $self->{Instance};

	print STDERR "Starting SRS daemon in PID $$\n";

	# Until we decide that forward() and reverse() can die, this will
	# allow us to trap the error messages from those subroutines.
	local $SIG{__WARN__} = sub { die @_; };

	my $listen = $self->{Socket};
	unless ($listen) {
		unlink($SRSSOCKET) if -e $SRSSOCKET;
		$listen ||= new IO::Socket::UNIX(
						Type	=> SOCK_STREAM,
						Local	=> $SRSSOCKET,
						Listen	=> 1,
							);
		die "Unable to create listen socket: $!" unless $listen;
	}

	my $select = new IO::Select();
	$select->add($listen);

	while (my @socks = $select->can_read) {
		foreach my $sock (@socks) {
			if ($sock == $listen) {
				# print "Accept on $sock\n";
				$select->add($listen->accept());
			}
			else {
				my $line = <$sock>;
				if (defined($line)) {
					chomp($line);
					# print "Read '$line' on $sock\n";
					my @args = split(/\s+/, $line);
					my $cmd = uc shift @args;
					eval {
						if ($cmd eq 'FORWARD') {
							$sock->print($srs->forward(@args), "\n");
						}
						elsif ($cmd eq 'REVERSE') {
							$sock->print($srs->reverse(@args), "\n");
						}
						else {
							die "Invalid command $cmd";
						}
					};
					if ($@) {
						$sock->print("ERROR: $@");
						$select->remove($sock);
						$sock->close();
					}
				}

				# Exim requires that we unconditionally close the socket
				# print "Close on $sock\n";
				$select->remove($sock);
				$sock->flush();
				$sock->close();
				undef $sock;
			}
		}
		my @exc = $select->has_exception(0);
		foreach my $sock (@exc) {
			# print "Exception on $sock\n";
			$select->remove($sock);
			$sock->close();
		}
	}
}

__END__

=head1 NAME

Mail::SRS::Daemon - modular daemon for Mail::SRS

=head1 SYNOPSIS

my $daemon = new Mail::SRS::Daemon(
	SecretFile  => $secretfile,
	Separator   => $separator,
		);
$daemon->run();

=head1 DESCRIPTION

The SRS daemon listens on a socket for SRS address transformation
requests. It transforms the addresses and returns the new addresses
on the socket.

It may be invoked from exim using ${readsocket ...}, and probably
from other MTAs as well. See http://www.anarres.org/projects/srs/
for examples.

=head1 METHODS

=head2 $daemon = new Mail::SRS::Daemon(...)

Construct a new Mail::SRS object and return it.  All parameters which
are valid for Mail::SRS are also valid for Mail::SRS::Daemon and will
be passed to the constructor of Mail::SRS verbatim. The exception to
this rule is the Secret parameter, which will be promoted to a list
and will have all secrets from SecretFile included. New parameters
are documented here. See L<Mail::SRS> for the rest.

=over 4

=item SecretFile => $string

A file to read for secrets. Secrets are specified once per line. The
first specified secret is used for encoding. Secrets are written
one per line. Blank lines and lines starting with a # are ignored.
If Secret is not given, then the secret file must be nonempty.

Secret will specify a primary secret and override SecretFile if both
are specified. However, secrets read from SecretFile still be used
for decoding if both are specified.

=item Socket => $socket

An instance of IO::Socket, presumed to be a listening socket. This
may be provided in order to use a preexisting socket, rather than have
Mail::SRS::Daemon construct a new socket.

=back

=head2 $daemon->run()

Run the daemon. This method will never return. Errors and exceptions
are caught, and error messages are returned down the socket.

=head1 EXPORTS

Given :all, this module exports the following variables.

=over 4

=item $SRSSOCKET

The filename of the default socket created by Mail::SRS::Daemon.

=back

=head1 PROTOCOL

The daemon waits for a single line of text from the client, and will
respond with a single line. The lines are all of the form "COMMAND
args...". Currently, two commands are supported: forward and reverse.

A forward request looks like:

	FORWARD sender@source.com alias@forwarder.com

A reverse request looks like:

	REVERSE srs0+HHH=TT=domain=local-part@forwarder.com

In either case, the daemon will respond with either a translated
address, or a line starting "ERROR ", followed by a message.

=head1 TODO

Add more daemon-related options, such as path to socket, or inet
socket address.

=head1 SEE ALSO

L<Mail::SRS>, L<srsd>, http://www.anarres.org/projects/srs/

=head1 AUTHOR

    Shevek
    CPAN ID: SHEVEK
    cpan@anarres.org
    http://www.anarres.org/projects/

=head1 COPYRIGHT

Copyright (c) 2004 Shevek. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__END__
