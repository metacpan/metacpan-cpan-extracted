#!perl

use strict;
use warnings;
use Test::Spec;
use Test::VCR::LWP qw(withVCR);
use Test::Deep;
use LWP::UserAgent;
use LWPx::Profile;
use File::Spec;

describe "A LWP profiling run" => sub {
	my $ua;
	before each => sub {
		$ua = LWP::UserAgent->new;
	};
	
	
	it "should be able to profile a request" => sub {
		LWPx::Profile::start_profiling();
		my $req = $ua->get('http://www.google.com/');
		my $results = LWPx::Profile::stop_profiling();
		
		my ($stats) = values %$results;
		
		# a bunch of assertions to make sure the data is sane.
		is($stats->{count}, 1);
		cmp_ok($stats->{first_duration},       '>', 0);
		cmp_ok($stats->{time_of_first_sample}, '>', 0);
	 	
		is($stats->{total_duration},      $stats->{first_duration});
		is($stats->{shortest_duration},   $stats->{first_duration});
		is($stats->{longest_duration},    $stats->{first_duration});
		
		is($stats->{time_of_last_sample}, $stats->{time_of_first_sample});
	};
	
	it "should be able to profile the same request multiple times" => sub {
		LWPx::Profile::start_profiling();
		my $req = $ua->get('http://www.google.com/');
		$req = $ua->get('http://www.google.com/');
		$req = $ua->get('http://www.google.com/');
		
		my $results = LWPx::Profile::stop_profiling();
		
		my ($stats) = values %$results;
		
		is($stats->{count}, 3);
		cmp_ok($stats->{first_duration},       '>', 0);
		cmp_ok($stats->{time_of_first_sample}, '>', 0);
	 	
		cmp_ok($stats->{total_duration},    '>', $stats->{first_duration});
		cmp_ok($stats->{shortest_duration}, '<', $stats->{longest_duration});
		
		cmp_ok($stats->{time_of_last_sample}, '>', $stats->{time_of_first_sample});
	};
	
	
	it "should be able to profile different requests" => sub {
		LWPx::Profile::start_profiling();
		my $req = $ua->get('http://www.google.com/');
		$req = $ua->get('http://www.perl.org/');
		
		
		my $results = LWPx::Profile::stop_profiling();
		
		my @requests = keys %$results;
		my @stats    = values %$results;
		
		is(scalar @stats, 2);
		is($stats[0]{count}, 1);
		is($stats[1]{count}, 1);
		
		like($requests[0], qr/www\.perl\.org|www\.google\.com/);
		like($requests[1], qr/www\.perl\.org|www\.google\.com/);
	};
};


withVCR {
	runtests;
} tape => File::Spec->catfile(qw:t lwpx-profile.tape:);