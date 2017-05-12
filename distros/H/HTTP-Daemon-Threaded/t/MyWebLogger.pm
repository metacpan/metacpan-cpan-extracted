package MyWebLogger;

use HTTP::Daemon::Threaded::Logger;
use base qw(HTTP::Daemon::Threaded::Logger);

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
#
#	make sure we can open the logfile
#
	my $self = { %args };
	bless $self, $class;
	$self->set_client(delete $self->{AptTAC})
		if $self->{AptTAC};

	my $old_fh = select(STDERR);
	$| = 1;
	select($old_fh);

	return $self;
}

sub log {

	print STDERR $_[1], "\n";
	return $_[0];
}

sub close {
	return $_[0];
}

1;