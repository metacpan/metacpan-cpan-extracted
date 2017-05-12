#!/usr/bin/perl
use strict; use warnings;

# import our helper modules
use MIME::Base64 qw( decode_base64 );
use Games::AssaultCube::ServerQuery;
use Games::AssaultCube::Utils qw( get_gamemode_from_name );

my( $numtests, @replies );
BEGIN {
	$numtests = 0;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;

	}

	# setup our reply datagrams
	# We store it via encode_base64( nfreeze( [ $datagram ] ), '' );
	@replies = (
		{
			name	=> 'nobody on the server',
			data	=> 'BQcCAAAAARc2AQCAaAQAAAoADDJUZWFtIERlYXRobWF0Y2ggIzk5IAwxQ1NOICM5OQwzIGJzMC43LjEAGAAA',
			attrs	=> {
				'map'		=> '',
				players		=> 0,
				protocol	=> 1128,
				max_players	=> 24,
				gamemode	=> get_gamemode_from_name( 'tdm' ),
				minutes_left	=> 10,
				pingtime	=> 1,
				player_list	=> [],
				desc_nocolor	=> 'Team Deathmatch #99 CSN #99 bs0.7.1',
				is_full		=> 0,
			},
		},
		{
			name	=> 'full server',
			data	=> 'BQcCAAAAARdFAQCAaAQAFANhcG9sbG9fZGVzZXJ0Y2l0eQAMMlRlYW0gRGVhdGhtYXRjaCAjMiAMMUNTTiAjNAwzIGJzMC43LjEAFAAA',
			attrs	=> {
				'map'		=> 'apollo_desertcity',
				players		=> 20,
				protocol	=> 1128,
				max_players	=> 20,
				gamemode	=> get_gamemode_from_name( 'tdm' ),
				minutes_left	=> 3,
				pingtime	=> 1,
				player_list	=> [],
				desc_nocolor	=> 'Team Deathmatch #2 CSN #4 bs0.7.1',
				is_full		=> 1,
			},
		},
		{
			name	=> 'not full server',
			data	=> 'BQcCAAAAARcwAQCAaAQFDAthY19kZXBvdAAMMkZsYWdzIAwxQ1NOICMyNQwzIGJzMC43LjEAHAAA',
			attrs	=> {
				'map'		=> 'ac_depot',
				players		=> 12,
				protocol	=> 1128,
				max_players	=> 28,
				gamemode	=> get_gamemode_from_name( 'ctf' ),
				minutes_left	=> 11,
				pingtime	=> 1,
				player_list	=> [],
				desc_nocolor	=> 'Flags CSN #25 bs0.7.1',
				is_full		=> 0,
			},
		},
		{
			name	=> 'retrieving playerlist',
			data	=> 'BQcCAAAAARdAAQGAaAQAAQ9hY19hcmN0aWMADDJNYXRjaCAjMSAMMUNTTiAjMzAMMyBiczAuNy4xAAoAAVB1bmhldGVpcm8AAA==',
			attrs	=> {
				'map'		=> 'ac_arctic',
				players		=> 1,
				protocol	=> 1128,
				max_players	=> 10,
				gamemode	=> get_gamemode_from_name( 'tdm' ),
				minutes_left	=> 15,
				pingtime	=> 1,
				player_list	=> [
					'Punheteiro',
				],
				desc_nocolor	=> 'Match #1 CSN #30 bs0.7.1',
				is_full		=> 0,
			},
		},
		{
			name	=> 'bigger playerlist',
			data	=> 'BQcCAAAAARdfAQGAaAQKAwRhY19hcmN0aWMADDJUT1NPSyAmIE9TT0sgIzIgDDFDU04gIzI2DDMgYnMwLjcuMQAMAAFLaXN0aXppW0hVTl0AUmFpbihCRSlbSkJmcl0AcGFjbyEhAAA=',
			attrs	=> {
				'map'		=> 'ac_arctic',
				players		=> 3,
				protocol	=> 1128,
				max_players	=> 12,
				gamemode	=> get_gamemode_from_name( 'osok' ),
				minutes_left	=> 4,
				pingtime	=> 1,
				player_list	=> [
					'Kistizi[HUN]',
					'Rain(BE)[JBfr]',
					'paco!!',
				],
				desc_nocolor	=> 'TOSOK & OSOK #2 CSN #26 bs0.7.1',
				is_full		=> 0,
			},
		},
		{
			name	=> 'biggest playerlist',
			data	=> 'BQcCAAAAARfdAQGAaAQFFAlhcG9sbG9fZGVzZXJ0Y2l0eQAMMkN1c3RvbU1hcHMgQ1RGIAwxQ1NOICMxNgwzIGJzMC43LjEAFAABTFAAZHVkdTE1NwBEZW5pelR1a2V5AFpFVVMAYWxleGFuZHJlAGFwZmVsbXVzAFRpVGkwNjEzMABPbW1hAFIAfGFDS2F8R2hvc3QqAEtVWlVCT1laAE1vcmV6AGRqZWplAEktTUFHSUMtSQBMdWZmeVtGUl0AU3RlaW5lcgBqdW5pb3IAZDBuZQBNT0haRU0AY3JvcXVldHRlAAA=',
			attrs	=> {
				'map'		=> 'apollo_desertcity',
				players		=> 20,
				protocol	=> 1128,
				max_players	=> 20,
				gamemode	=> get_gamemode_from_name( 'ctf' ),
				minutes_left	=> 9,
				pingtime	=> 1,
				player_list	=> [
					'LP',
					'dudu157',
					'DenizTukey',
					'ZEUS',
					'alexandre',
					'apfelmus',
					'TiTi06130',
					'Omma',
					'R',
					'|aCKa|Ghost*',
					'KUZUBOYZ',
					'Morez',
					'djeje',
					'I-MAGIC-I',
					'Luffy[FR]',
					'Steiner',
					'junior',
					'd0ne',
					'MOHZEM',
					'croquette',
				],
				desc_nocolor	=> 'CustomMaps CTF CSN #16 bs0.7.1',
				is_full		=> 1,
			},
		},
	);

	$numtests += scalar @replies * 14;
}

use Test::More tests => $numtests;

# setup our "fake" server object
my $query = Games::AssaultCube::ServerQuery->new( 'localhost' );

SKIP: {
	# skip all tests if we don't have latest Storable
	eval "use Storable 2.18";
	skip "Storable v2.18+ not installed", scalar @replies * 14 if $@;

	# recreate the datagram!
	foreach my $test ( @replies ) {
		# recover the datagram...
		my $datagram = Storable::thaw( decode_base64( $test->{'data'} ) );
		$datagram = $datagram->[0];

		# actually parse it
		my $response;
		eval {
			$response = Games::AssaultCube::ServerQuery::Response->new( $query, $datagram );
		};
		is( ! $@, 1, "Parsed '" . $test->{'name'} . "' with no errors" );
		diag( $@ ) if $@;

		# some basic sanity tests
		$test->{'attrs'}->{'server'} = 'localhost';
		$test->{'attrs'}->{'port'} = 28763;
		$test->{'attrs'}->{'datagram'} = $datagram;

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
}
