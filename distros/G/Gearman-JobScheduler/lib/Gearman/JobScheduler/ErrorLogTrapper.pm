#
# Log4perl's trapper module
# (http://log4perl.sourceforge.net/releases/Log-Log4perl/docs/html/Log/Log4perl/FAQ.html#e95ee)
#
package Gearman::JobScheduler::ErrorLogTrapper;

use strict;
use warnings;

use Log::Log4perl qw(:easy);

sub TIEHANDLE {
	my $class = shift;
	bless [], $class;
}

sub PRINT {
	my $self = shift;
	$Log::Log4perl::caller_depth++;
	DEBUG @_;
	$Log::Log4perl::caller_depth--;
}

sub FILENO {
	return undef;
}

1;
