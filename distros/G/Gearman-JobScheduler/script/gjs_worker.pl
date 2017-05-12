#!/usr/bin/env perl

=head1 NAME

worker.pl - Start GJS worker

=head1 SYNOPSIS

	# Run instance of the "NinetyNineBottlesOfBeer" Gearman function
	worker.pl NinetyNineBottlesOfBeer

or:

	# Run instance of the Gearman function from "path/to/NinetyNineBottlesOfBeer.pm"
	worker.pl path/to/NinetyNineBottlesOfBeer.pm

=cut

use strict;
use warnings;
use Modern::Perl "2012";

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../samples";

use Gearman::JobScheduler;
use Gearman::JobScheduler::Configuration;
use Gearman::JobScheduler::Worker;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({ level => $DEBUG, utf8=>1, layout => "%d{ISO8601} [%P]: %m%n" });

use Pod::Usage;


sub main()
{
	# Function name, path to function module or path to directory with all functions
	unless (scalar (@ARGV) == 1) {
		pod2usage(1);
	}
	my $gearman_function_name_or_directory = $ARGV[0];

	# Run single worker
	Gearman::JobScheduler::Worker::run_worker($gearman_function_name_or_directory);
}


main();
