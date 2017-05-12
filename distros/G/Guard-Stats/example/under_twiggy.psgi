#!/usr/bin/perl -w

use strict;

# A semi-real example for Guard::Stats
# Run as `twiggy -Ilib --listen :<port> <this_file>`

# Then access the script:
# http://localhost:<port>/stat for statustics
# http://localhost:<port>/time for time distribution
# http://localhost:<port>/ for random delay (0..1 sec)
# http://localhost:<port>/?delay=<n.n> for specific delay

# This one is quick and dirty wrt handling request. Sorry for that.

# See search.cpan.org/perldoc?PSGI for how everything works here.

use AE;
use YAML;

use Guard::Stats;
my $stat = Guard::Stats->new( want_times => 1 );

my $app = sub {
	my $env = shift;

	warn "Serving: $env->{REQUEST_URI}";

	# Diagnostic URLs /stat.* for statistics, /time.* for time distribution
	if ($env->{REQUEST_URI} =~ /stat/) {
		return [200, 
			[ "Content-Type" => "text/plain" ],
			[Dump($stat->get_stat)]];
	} elsif ($env->{REQUEST_URI} =~ /time/) {
		return [200, 
			[ "Content-Type" => "text/plain" ],
			[Dump($stat->get_times)]];
	};

	# The requests - 200, sleep for random/specific time, EOF
	# Only these are measured
	my $guard = $stat->guard;
	return sub {
		my $answer = shift;
		my $writer = $answer->([ 200, [ "Content-Type" => "text/plain" ]]);

		$env->{QUERY_STRING} =~ /delay=(\d+\.?\d*)/;
		my $delay = $1 || rand();

		# Start AnyEvent timer
		my $timer; $timer=AE::timer $delay, 0, sub {
			$writer->write("OK $delay sec\n");
			$writer->close;
			$guard->end();
			undef $timer;
		}; # end timer callback
	}; # end PSGI callback
}; # end PSGI app
