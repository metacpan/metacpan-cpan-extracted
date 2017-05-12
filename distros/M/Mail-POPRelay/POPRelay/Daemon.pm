package Mail::POPRelay::Daemon;

use strict;
use Mail::POPRelay;
use File::Tail;
use vars qw[@ISA $VERSION ];
use POSIX qw[setsid ];

@ISA     = qw[Mail::POPRelay ];
$VERSION = '0.1.1';


# trap signals
# ---------
sub __setupSignals {
	my $self = shift;

	$SIG{'TERM'} = sub { $self->wipeRelayDirectory(); $self->generateRelayFile(); };
	$SIG{'KILL'} = sub { $self->wipeRelayDirectory(); $self->generateRelayFile(); };
	$SIG{'HUP'}  = sub { 
				$self->initWithConfigFile($self->{'configFile'}); 
				$self->cleanRelayDirectory();
				$self->generateRelayFile(); 
	};
}


# daemonize
# ---------
sub init {
	my $self = Mail::POPRelay::initWithConfigFile(@_);

	defined(my $pid = fork()) or die "Unable to fork: $!";
	if ($pid) {
		# parent
		return $pid;
	} else {
		# sibling
		#chdir('/')              or die "Can't chdir to /: $!";
		setsid()                or die "Can't start new session: $!";
		open STDERR, '>&STDOUT' or die "Can't dup stdout: $!";

		$self->__setupSignals();
		$self->__mainLoop();

		return $self;
	}
}


# ---------
sub __mainLoop {
	my $self = shift;

	my $fileTail = File::Tail->new (
		name        => $self->{'mailLogFile'},
		interval    => 2,
		maxinterval => 3,
		adjustafter => 3,
	) or die "Unable to tail $self->{'mailLogFile'}: $!";

	my($line, $flag);
	while (defined($line = $fileTail->read())) {
		if ($line =~ m|$self->{'mailLogRegExp'}|) {
			# save processing cycles and exit early if possible
			$flag = 0;
			$flag = 1 if $self->addRelayAddress($1, $2);
			$flag = 1 if $self->cleanRelayDirectory();
			$self->generateRelayFile() if $flag;

		}
	}
	$self->wipeRelayDirectory(); 
	$self->generateRelayFile();
}


1337;

__END__

=head1 NAME

Mail::POPRelay::Daemon - Dynamic Relay Access Control Daemon Class


=head1 SYNOPSIS

Please see README.


=head1 DESCRIPTION

The daemon class of POPRelay.


=head1 DIAGNOSTICS

die().  Will write to syslog eventually.


=head1 SIGNALS

=over 8

Described below are the actions taken for recieving various signals.

=item HUP

The config file is reloaded and the relay file is regenerated.

=item KILL

The relay file is wiped clean.

=item TERM

The relay file is wiped clean.

=back

=head1 CONTRIBUTE

If you feel compelled to write a subclass of POPRelay::Daemon, please sent
it to the author for incorporation into the next release.


=head1 AUTHOR

Keith Hoerling <keith@hoerling.com>


=head1 SEE ALSO

Mail::POPRelay(3pm), poprelay_cleanup(1p).

=cut

# $Id: Daemon.pm,v 1.1.1.1 2002/05/28 07:32:59 keith Exp $
