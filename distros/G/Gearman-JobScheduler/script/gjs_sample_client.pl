#!/usr/bin/env perl

use strict;
use warnings;
use Modern::Perl "2012";

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../samples";

use Gearman::JobScheduler;
use Gearman::JobScheduler::Admin;
use NinetyNineBottlesOfBeer;
use Addition;
use AdditionAlwaysFails;
use Data::Dumper;


sub main()
{
	for (my $x = 1; $x < 100; ++$x) {
		say STDERR "Will enqueue NinetyNineBottlesOfBeer on Gearman";
		my $gearman_job_id = NinetyNineBottlesOfBeer->enqueue_on_gearman({how_many_bottles => $x});
		say STDERR "Gearman job ID: $gearman_job_id";
	}
}

main();
