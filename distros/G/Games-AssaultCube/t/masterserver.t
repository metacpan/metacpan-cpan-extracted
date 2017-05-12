#!/usr/bin/perl
use strict; use warnings;

# import our helper modules
use Games::AssaultCube::MasterserverQuery;
use HTTP::Response;

my( $numtests, @replies );
BEGIN {
	$numtests = 0;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;

	}

	# setup our reply stuff
	@replies = (
		{
			name	=> 'invalid data',
			data	=> 'asdf13  asdlfk',
			invalid	=> 1,
		},
		{
			name	=> 'corrupt data',
			data	=> <<'END',
addserver 213.239.218.142 28323;
addserver 213.239.218.142 28333;
addserver 76.248.8.154 28763;
addserver 213.136.33.162 28763;
addserver 78.129.140.170
END

			invalid	=> 1,
		},
		{
			name	=> 'empty serverlist',
			data	=> '',
			attrs	=> {
				num_servers	=> 0,
				servers		=> [],
			},
		},
		{
			name	=> 'one server in the list',
			data	=> 'addserver 66.207.162.130 2000;',
			attrs	=> {
				num_servers	=> 1,
				servers		=> [
					{
						ip	=> '66.207.162.130',
						port	=> 2000,
					},
				],
			},
		},
		{
			name	=> 'many servers in the list',
			data	=> <<'END',
addserver 66.207.162.130 3000;
addserver 90.23.155.137 28763;
addserver 62.56.90.141 28763;
addserver 213.239.218.142 28243;
addserver 213.239.218.142 28253;
addserver 213.239.218.142 28323;
addserver 213.239.218.142 28333;
addserver 76.248.8.154 28763;
addserver 213.136.33.162 28763;
addserver 78.129.140.170 1337;
addserver 83.194.10.171 28763;
addserver 89.187.132.171 28763;
addserver 91.102.66.178 28763;
END

			attrs	=> {
				num_servers	=> 13,
				servers		=> [
					{
						ip	=> '66.207.162.130',
						port	=> 3000,
					},
					{
						ip	=> '90.23.155.137',
						port	=> 28763,
					},
					{
						ip	=> '62.56.90.141',
						port	=> 28763,
					},
					{
						ip	=> '213.239.218.142',
						port	=> 28243,
					},
					{
						ip	=> '213.239.218.142',
						port	=> 28253,
					},
					{
						ip	=> '213.239.218.142',
						port	=> 28323,
					},
					{
						ip	=> '213.239.218.142',
						port	=> 28333,
					},
					{
						ip	=> '76.248.8.154',
						port	=> 28763,
					},
					{
						ip	=> '213.136.33.162',
						port	=> 28763,
					},
					{
						ip	=> '78.129.140.170',
						port	=> 1337,
					},
					{
						ip	=> '83.194.10.171',
						port	=> 28763,
					},
					{
						ip	=> '89.187.132.171',
						port	=> 28763,
					},
					{
						ip	=> '91.102.66.178',
						port	=> 28763,
					},
				],
			},
		},
	);

	# add the tests
	foreach my $t ( @replies ) {
		if ( exists $t->{'invalid'} ) {
			$numtests += 1;
		} else {
			$numtests += 2;					# sanity tests
			$numtests += scalar keys %{ $t->{'attrs'} };	# attr tests
		}
	}
}

use Test::More tests => $numtests;

# setup our "fake" server object
my $query = Games::AssaultCube::MasterserverQuery->new();

# recreate the datagram!
foreach my $test ( @replies ) {
	# actually parse it
	my $response;
	eval {
		my $http = HTTP::Response->new( 200, undef, undef, $test->{'data'} );
		$response = Games::AssaultCube::MasterserverQuery::Response->new( $query, $http );
	};

	# Should it have died?
	if ( exists $test->{'invalid'} ) {
		is( defined $@, 1, "Parsed '" . $test->{'name'} . "' and died as expected" );
		next;
	} else {
		is( ! $@, 1, "Parsed '" . $test->{'name'} . "' with no errors" );
		diag( $@ ) if $@;
	}

	# some basic sanity tests
	$test->{'attrs'}->{'masterserver'} = 'http://masterserver.cubers.net/cgi-bin/AssaultCube.pl/retrieve.do?item=list';

	# test the result data!
	foreach my $attr ( sort keys %{ $test->{'attrs'} } ) {
		# what type of attr?
		if ( defined $test->{'attrs'}->{ $attr } ) {
			if ( ! ref( $test->{'attrs'}->{ $attr } ) ) {
				cmp_ok( $response->$attr(), 'eq', $test->{'attrs'}->{ $attr }, "Testing attribute($attr)" );
			} else {
				is_deeply( $response->$attr(), $test->{'attrs'}->{ $attr }, "Testing datastruct attribute($attr)" );
			}
		} else {
			is( ! defined $response->$attr(), 1, "Testing undef attribute($attr)" );
		}
	}
}
