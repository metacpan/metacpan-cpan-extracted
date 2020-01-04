package MyLogger;

use strict;
use warnings;

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub info {
	my $self = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag(@_);
	}
}

sub trace {
	my $self = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag(@_);
	}
}

sub debug {
	my $self = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag(@_);
	}
}

sub AUTOLOAD {
	our $AUTOLOAD;
	my $param = $AUTOLOAD;

	unless($param eq 'MyLogger::DESTROY') {
		::diag("Need to define $param");
	}
}

1;
