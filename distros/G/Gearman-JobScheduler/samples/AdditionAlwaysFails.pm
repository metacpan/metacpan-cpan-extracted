package AdditionAlwaysFails;

use strict;
use warnings;
use Modern::Perl "2012";

use Moose;
with 'Gearman::JobScheduler::AbstractFunction';


# Run job
sub run($;$)
{
	my ($self, $args) = @_;

	my $a = $args->{a};
	my $b = $args->{b};

	say STDERR "Going to add $a and $b";

	die "Algebra is hard.";
}


no Moose;    # gets rid of scaffolding


# Return package name instead of 1 or otherwise worker.pl won't know the name of the package it's loading
__PACKAGE__;
