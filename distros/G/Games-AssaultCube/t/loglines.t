#!/usr/bin/perl
use strict; use warnings;

# Import some helper routines
use Games::AssaultCube::Log::Line;
use Games::AssaultCube::Utils qw( get_role_from_name get_team_from_name get_gamemode_from_name get_gamemode_from_fullname get_mastermode_name get_mastermode_from_name );
use DateTime;

# Test each "known" log line we have and see what happens
my( $numtests, %loglines );
BEGIN {
	$numtests = 0;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;

	}

	%loglines = (
		AdminPasswords		=> {
			line		=> 'read 6 admin passwords from config/serverpwd.cfg',
			attrs		=> {
				count	=> 6,
				config	=> 'config/serverpwd.cfg',
			},
		},
		AutoBalance		=> {
			line		=> 'at-target: -320, 2:529 4:567 7:541 8:537 12:561 13:573 15:504 16:630 18:480 19:576 21:549  pick:18',
			attrs		=> {
				target	=> -320,
				pick	=> 18,
				players	=> {
					2	=> 529,
					4	=> 567,
					7	=> 541,
					8	=> 537,
					12	=> 561,
					13	=> 573,
					15	=> 504,
					16	=> 630,
					18	=> 480,
					19	=> 576,
					21	=> 549,
				},
			},
		},
		BlacklistEntries	=> {
			line		=> 'read 3 (0) blacklist entries from config/serverblacklist.cfg',
			attrs		=> {
				count		=> 3,
				count_secondary	=> 0,
				config		=> 'config/serverblacklist.cfg',
			},
		},
		CallVote		=> [
			{
				line	=> '[201.62.198.172] client DaviConde failed to call a vote: load map \'ac_desert2\' in mode \'team deathmatch\' (voting is currently disabled)',
				attrs	=> {
					ip		=> '201.62.198.172',
					nick		=> 'DaviConde',
					type		=> 'loadmap',
					target		=> 'ac_desert2 - team deathmatch',
					failure		=> 1,
					failure_reason	=> 'voting is currently disabled',
				},
			},
			{
				line	=> '[201.62.198.172] client DaviConde called a vote: load map \'ac_desert2\' in mode \'team deathmatch\'',
				attrs	=> {
					ip		=> '201.62.198.172',
					nick		=> 'DaviConde',
					type		=> 'loadmap',
					target		=> 'ac_desert2 - team deathmatch',
					failure		=> 0,
					failure_reason	=> undef,
				},
			},
			{
				line	=> '[189.82.218.23] client LucKaZ failed to call a vote: force player William to the enemy team (no permission)',
				attrs	=> {
					ip		=> '189.82.218.23',
					nick		=> 'LucKaZ',
					type		=> 'force',
					target		=> 'William',
					failure		=> 1,
					failure_reason	=> 'no permission',
				},
			},
			{
				line	=> '[189.37.35.229] client _-_NaKaTa_-_] called a vote: kick player Igor(BR)',
				attrs	=> {
					ip		=> '189.37.35.229',
					nick		=> '_-_NaKaTa_-_]',
					type		=> 'kick',
					target		=> 'Igor(BR)',
					failure		=> 0,
					failure_reason	=> undef,
				},
			},
			{
				line	=> '[213.192.8.77] client diamonds|czech| called a vote: shuffle teams',
				attrs	=> {
					ip		=> '213.192.8.77',
					nick		=> 'diamonds|czech|',
					type		=> 'shuffle',
					target		=> 'teams',
					failure		=> 0,
					failure_reason	=> undef,
				},
			},
			{
				line	=> '[201.11.201.111] client unarmecunha failed to call a vote: ban player tka0 (there is already a vote pending)',
				attrs	=> {
					ip		=> '201.11.201.111',
					nick		=> 'unarmecunha',
					type		=> 'ban',
					target		=> 'tka0',
					failure		=> 1,
					failure_reason	=> 'there is already a vote pending',
				},
			},
			{
				line	=> '[87.67.128.88] client XxLeGenDxX-CLA- called a vote: remove all bans',
				attrs	=> {
					ip		=> '87.67.128.88',
					nick		=> 'XxLeGenDxX-CLA-',
					type		=> 'remove',
					target		=> 'all bans',
					failure		=> 0,
					failure_reason	=> undef,
				},
			},
			{
				line	=> '[189.29.127.99] client eu failed to call a vote:  (invalid vote)',
				attrs	=> {
					ip		=> '189.29.127.99',
					nick		=> 'eu',
					type		=> 'invalid',
					target		=> 'invalid',
					failure		=> 1,
					failure_reason	=> 'invalid vote',
				},
			},
			{
				line	=> '[190.65.139.55] client ICE=PUNX called a vote: enable autoteam',
				attrs	=> {
					ip		=> '190.65.139.55',
					nick		=> 'ICE=PUNX',
					type		=> 'enable',
					target		=> 'autoteam',
					failure		=> 0,
					failure_reason	=> undef,
				},
			},
			{
				line	=> '[99.141.95.78] client BS-DoWnED called a vote: change mastermode to \'open\'',
				attrs	=> {
					ip		=> '99.141.95.78',
					nick		=> 'BS-DoWnED',
					type		=> 'change',
					target		=> 'mastermode to \'open\'',
					failure		=> 0,
					failure_reason	=> undef,
				},
			},
			{
				line	=> '[70.119.239.248] client NiNjA failed to call a vote: stop demo (no permission)',
				attrs	=> {
					ip		=> '70.119.239.248',
					nick		=> 'NiNjA',
					type		=> 'stop',
					target		=> 'demo',
					failure		=> 1,
					failure_reason	=> 'no permission',
				},
			},
			{
				line	=> '[70.119.239.248] client foo called a vote: ',
				attrs	=> {
					ip		=> '70.119.239.248',
					nick		=> 'foo',
					type		=> 'invalid',
					target		=> 'invalid',
					failure		=> 1,
					failure_reason	=> 'empty vote',
				},
			},
		],
		ClientAdmin		=> [
			{
				line		=> '[78.42.217.6] player BS-Getler used admin password in line 9',
				attrs		=> {
					ip		=> '78.42.217.6',
					nick		=> 'BS-Getler',
					password	=> 9,
					unbanned	=> 0,
				},
			},
			{
				line		=> '[78.42.217.6] logged in using the admin password in line 28, (ban removed)',
				attrs		=> {
					ip		=> '78.42.217.6',
					nick		=> 'unarmed',
					password	=> 28,
					unbanned	=> 1,
				},
			},
		],
		ClientChangeRole	=> [
			{
				line		=> '[78.42.217.6] set role of player BS-Getler to admin',
				attrs		=> {
					ip		=> '78.42.217.6',
					nick		=> 'BS-Getler',
					role		=> get_role_from_name( 'ADMIN' ),
					role_name	=> 'ADMIN',
				},
			},
			{
				line		=> '[78.42.217.6] set role of player BS-Getler to normal player',
				attrs		=> {
					ip		=> '78.42.217.6',
					nick		=> 'BS-Getler',
					role		=> get_role_from_name( 'DEFAULT' ),
					role_name	=> 'DEFAULT',
				},
			},
		],
		ClientConnected		=> {
			line		=> '[189.106.185.163] client connected',
			attrs		=> {
				ip	=> '189.106.185.163',
			},
		},
		ClientDisconnected	=> [
			{
				line	=> '[189.19.121.121] disconnecting client Thau (server FULL - maxclients)',
				attrs	=> {
					ip	=> '189.19.121.121',
					nick	=> 'Thau',
					reason	=> 'server FULL - maxclients',
					forced	=> 1,
				},
			},
			{
				line	=> '[189.19.121.121] disconnected client Thau',
				attrs	=> {
					ip	=> '189.19.121.121',
					nick	=> 'Thau',
					reason	=> 'disconnected',
					forced	=> 0,
				},
			},
		],
		ClientNickChange	=> {
			line		=> '[189.107.95.94] gustavoqw changed his name to gustavo',
			attrs		=> {
				ip	=> '189.107.95.94',
				nick	=> 'gustavo',
				oldnick	=> 'gustavoqw',
			},
		},
		ClientStatus		=> [
			{
				line	=> ' 0 p4SqV            CLA     4     2 normal  84.124.240.176',
				attrs	=> {
					ip		=> '84.124.240.176',
					nick		=> 'p4SqV',
					cn		=> 0,
					frags		=> 4,
					deaths		=> 2,
					role		=> get_role_from_name( 'DEFAULT' ),
					role_name	=> 'DEFAULT',
					flags		=> undef,
					team		=> get_team_from_name( 'CLA' ),
					team_name	=> 'CLA',
				},
			},
			{
				line	=> '32 J.VICTOR         RVSF    0     0     0 normal  189.87.217.66',
				attrs	=> {
					ip		=> '189.87.217.66',
					nick		=> 'J.VICTOR',
					cn		=> 32,
					frags		=> 0,
					deaths		=> 0,
					role		=> get_role_from_name( 'DEFAULT' ),
					role_name	=> 'DEFAULT',
					flags		=> 0,
					team		=> get_team_from_name( 'RVSF' ),
					team_name	=> 'RVSF',
				},
			},
			{
				line	=> ' 9 |KH|Bullpup      RVSF   30    21     1 admin   99.243.165.231',
				attrs	=> {
					ip		=> '99.243.165.231',
					nick		=> '|KH|Bullpup',
					cn		=> 9,
					frags		=> 30,
					deaths		=> 21,
					role		=> get_role_from_name( 'ADMIN' ),
					role_name	=> 'ADMIN',
					flags		=> 1,
					team		=> get_team_from_name( 'RVSF' ),
					team_name	=> 'RVSF',
				},
			},
			{
				line	=> ' 1 johnshepperd        -2     5     1 normal  72.70.225.223',
				attrs	=> {
					ip		=> '72.70.225.223',
					nick		=> 'johnshepperd',
					cn		=> 1,
					frags		=> -2,
					deaths		=> 5,
					role		=> get_role_from_name( 'DEFAULT' ),
					role_name	=> 'DEFAULT',
					flags		=> 1,
					team		=> get_team_from_name( 'NONE' ),
					team_name	=> 'NONE',
				},
			},
			{
				line	=> ' 0 WestSide_Jatu       85     3 normal  88.78.205.59',
				attrs	=> {
					ip		=> '88.78.205.59',
					nick		=> 'WestSide_Jatu',
					cn		=> 0,
					frags		=> 85,
					deaths		=> 3,
					role		=> get_role_from_name( 'DEFAULT' ),
					role_name	=> 'DEFAULT',
					flags		=> undef,
					team		=> get_team_from_name( 'NONE' ),
					team_name	=> 'NONE',
				},
			},
		],
		ClientVersion	=> {
			line	=> '[84.133.135.78] runs AC 1002 (defs: 06)',
			attrs	=> {
				ip	=> '84.133.135.78',
				version	=> 1002,
				defs	=> '06',
			},
		},
		ConfigError	=> [
			{
				line	=> 'could not read config file \'config/maprot_flags.cfg\'',
				attrs	=> {
					errortype	=> 'config read',
					what		=> 'config/maprot_flags.cfg',
				},
			},
			{
				line	=> 'maprot error: map \'#ac_toxic\' not found',
				attrs	=> {
					errortype	=> 'maprot missing map',
					what		=> '#ac_toxic',
				},
			},
		],
		DemoStart	=> {
			line	=> 'Demo recording started.',
			attrs	=> {},
		},
		DemoStop	=> [
			{
				line	=> 'Demo "Tue Feb 17 11:14:58 2009: ctf, bs_dust2_0.6, 1.32MB" recorded.',
				attrs	=> {
					'map'			=> 'bs_dust2_0.6',
					gamemode		=> get_gamemode_from_name( 'ctf' ),
					gamemode_name		=> 'CTF',
					gamemode_fullname	=> 'ctf',
					size			=> int( 1.32 * 1024 * 1024 ),
					datetime		=> DateTime->new(
									year	=> 2009,
									month	=> 2,
									day	=> 17,
									hour	=> 11,
									minute	=> 14,
									second	=> 58,
								),
				},
			},
			{
				line	=> 'Demo "Fri Apr 14 8:38:52 2008: last swiss standing, bs_dust2_0.6, 13.2kB" recorded.',
				attrs	=> {
					'map'			=> 'bs_dust2_0.6',
					gamemode		=> get_gamemode_from_name( 'lss' ),
					gamemode_name		=> 'LSS',
					gamemode_fullname	=> 'last swiss standing',
					size			=> int( 13.2 * 1024 ),
					datetime		=> DateTime->new(
									year	=> 2008,
									month	=> 4,
									day	=> 14,
									hour	=> 8,
									minute	=> 38,
									second	=> 52,
								),
				},
			},
		],
		DNSLookup	=> {
			line	=> 'looking up localhost...',
			attrs	=> {
				host	=> 'localhost',
			},
		},
		FatalError	=> {
			line	=> 'AssaultCube fatal error: could not create server info socket',
			attrs	=> {
				error	=> 'could not create server info socket',
			},
		},
		FlagDropped	=> {
			line	=> '[99.141.95.78] DoWnED dropped the flag',
			attrs	=> {
				ip	=> '99.141.95.78',
				nick	=> 'DoWnED',
			},
		},
		FlagFailedScore	=> {
			line	=> '[78.42.217.6] BS-Dreamworker failed to score',
			attrs	=> {
				ip	=> '78.42.217.6',
				nick	=> 'BS-Dreamworker',
			},
		},
		FlagForcedPickup	=> {
			line	=> '[190.154.116.217] NightFire got forced to pickup the flag',
			attrs	=> {
				ip	=> '190.154.116.217',
				nick	=> 'NightFire',
			},
		},
		FlagLost	=> {
			line	=> '[90.19.142.50] |Lag]Guigui45 lost the flag',
			attrs	=> {
				ip	=> '90.19.142.50',
				nick	=> '|Lag]Guigui45',
			},
		},
		FlagReset	=> {
			line	=> 'the server reset the flag for team CLA',
			attrs	=> {
				team		=> get_team_from_name( 'CLA' ),
				team_name	=> 'CLA',
			},
		},
		FlagReturned	=> {
			line	=> '[90.19.142.50] FooBar\' returned the flag',
			attrs	=> {
				ip	=> '90.19.142.50',
				nick	=> 'FooBar\'',
			},
		},
		FlagScored	=> {
			line	=> '[81.220.95.115] xeno scored with the flag for RVSF, new score 1',
			attrs	=> {
				ip		=> '81.220.95.115',
				nick		=> 'xeno',
				team		=> get_team_from_name( 'RVSF' ),
				team_name	=> 'RVSF',
				score		=> 1,
			},
		},
		FlagScoredKTF	=> {
			line	=> '[88.244.14.117] nedimdedikya scored, carrying for 15 seconds, new score 32',
			attrs	=> {
				ip	=> '88.244.14.117',
				nick	=> 'nedimdedikya',
				carried	=> 15,
				score	=> 32,
			},
		},
		FlagStole	=> {
			line	=> '[90.19.142.50] |Lag]Guigui45 stole the flag',
			attrs	=> {
				ip	=> '90.19.142.50',
				nick	=> '|Lag]Guigui45',
			},
		},
		GameStart	=> {
			line	=> 'Game start: team deathmatch on ac_snow, 20 players, 6 minutes remaining, mastermode 0, (itemlist preloaded, \'getmap\' not prepared)',
			attrs	=> {
				'map'			=> 'ac_snow',
				players			=> 20,
				minutes			=> 6,
				mastermode		=> 0,
				mastermode_name		=> get_mastermode_name( 0 ),
				gamemode		=> get_gamemode_from_fullname( 'team deathmatch' ),
				gamemode_name		=> 'TDM',
				gamemode_fullname	=> 'team deathmatch',
			},
		},
		GameStatus	=> [
			{
				line	=> 'Game status: ctf on bs_dust2_0.6, 12 minutes remaining, open',
				attrs	=> {
					'map'			=> 'bs_dust2_0.6',
					minutes			=> 12,
					finished		=> 0,
					gamemode		=> get_gamemode_from_name( 'ctf' ),
					gamemode_name		=> 'CTF',
					gamemode_fullname	=> 'capture the flag',
					mastermode		=> get_mastermode_from_name( 'open' ),
					mastermode_name		=> 'OPEN',
				}
			},
			{
				line	=> 'Game status: deathmatch on ac_snow, game finished, open',
				attrs	=> {
					'map'			=> 'ac_snow',
					minutes			=> 0,
					finished		=> 1,
					gamemode		=> get_gamemode_from_name( 'dm' ),
					gamemode_name		=> 'DM',
					gamemode_fullname	=> 'deathmatch',
					mastermode		=> get_mastermode_from_name( 'open' ),
					mastermode_name		=> 'OPEN',
				}
			},
		],
		Killed		=> [
			{
				line	=> '[77.135.156.74] HerbertSchlang gibbed his teammate ahtung',
				attrs	=> {
					ip	=> '77.135.156.74',
					nick	=> 'HerbertSchlang',
					victim	=> 'ahtung',
					tk	=> 1,
					gib	=> 1,
					score	=> -2,
				},
			},
			{
				line	=> '[62.178.2.78] FranzJoseph fragged kevinu\\',
				attrs	=> {
					ip	=> '62.178.2.78',
					nick	=> 'FranzJoseph',
					victim	=> 'kevinu\\',
					tk	=> 0,
					gib	=> 0,
					score	=> 1,
				},
			},
			{
				line	=> '[193.110.17.39] 123 gibbed root',
				attrs	=> {
					ip	=> '193.110.17.39',
					nick	=> '123',
					victim	=> 'root',
					tk	=> 0,
					gib	=> 1,
					score	=> 2,
				},
			},
			{
				line	=> '[90.62.188.137] polo14470 fragged his teammate kevinu\\',
				attrs	=> {
					ip	=> '90.62.188.137',
					nick	=> 'polo14470',
					victim	=> 'kevinu\\',
					tk	=> 1,
					gib	=> 0,
					score	=> -1,
				},
			},
		],
		LoadedMap	=> {
			line	=> 'loaded map packages/maps/servermaps/ac_depot_classic.cgz, 15188 + 10447(1559) bytes.',
			attrs	=> {
				'map'		=> 'ac_depot_classic',
				mapsize		=> 15188,
				cfgsize		=> 10447,
				cfgzsize	=> 1559,
			},
		},
		MapError	=> {
			line	=> 'map "dust2" does not support "ctf": flag bases missing',
			attrs	=> {
				'map'			=> 'dust2',
				error			=> 'flag bases missing',
				gamemode		=> get_gamemode_from_name( 'ctf' ),
				gamemode_name		=> 'CTF',
				gamemode_fullname	=> 'capture the flag',
			},
		},
		MasterserverReply	=> [
			{
				line	=> 'masterserver reply: ',
				attrs	=> {
					reply	=> '',
					success	=> 1,
				},
			},
			{
				line	=> 'masterserver reply: Registration successful. Due to caching it might take a few minutes to see the your server in the serverlist',
				attrs	=> {
					reply	=> 'Registration successful. Due to caching it might take a few minutes to see the your server in the serverlist',
					success	=> 1,
				},
			},
			{
				line	=> 'Server not registered, could not ping you. Make sure your server is accessible from the internet.',
				attrs	=> {
					reply	=> 'Server not registered, could not ping you. Make sure your server is accessible from the internet.',
					success	=> 0,
				},
			},
		],
		MasterserverRequest	=> {
			line	=> 'sending request to masterserver.cubers.net...',
			attrs	=> {
				server	=> 'masterserver.cubers.net',
			},
		},
		Says		=> [
			{
				line	=> '[62.178.2.78] FranzJoseph says: \'sorry\'',
				attrs	=> {
					ip	=> '62.178.2.78',
					nick	=> 'FranzJoseph',
					text	=> 'sorry',
					isteam	=> 0,
					spam	=> 0,
				},
			},
			{
				line	=> '[90.33.247.71] CaptainMcClayn says to team CLA: \'Defend the flag!\'',
				attrs	=> {
					ip	=> '90.33.247.71',
					nick	=> 'CaptainMcClayn',
					text	=> 'Defend the flag!',
					isteam	=> 1,
					spam	=> 0,
				},
			},
			{
				line	=> '[90.212.12.30] BS-AS0M says: \'lol i cant says im spamming lol\', SPAM detected',
				attrs	=> {
					ip	=> '90.212.12.30',
					nick	=> 'BS-AS0M',
					text	=> 'lol i cant says im spamming lol',
					isteam	=> 0,
					spam	=> 1,
				},
			},
			{
				line	=> '[63.228.163.170] 0GAAAAR/ahmed says: \'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',
				attrs	=> {
					ip	=> '63.228.163.170',
					nick	=> '0GAAAAR/ahmed',
					text	=> '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',
					isteam	=> 0,
					spam	=> 0,
				},
			},
		],
		ScoreboardStart	=> [
			{
				line	=> 'cn name             team frag death role    host',
				attrs	=> {},
			},
			{	line	=> 'cn name             team frag death flags  role    host',
				attrs	=> {},
			},
			{	line	=> 'cn name             frag death role    host',
				attrs	=> {},
			},
			{
				line	=> 'cn name             frag death flags  role    host',
				attrs	=> {},
			},
		],
		StartupText	=> [
			{
				line	=> 'logging local AssaultCube server now..',
				attrs	=> {},
			},
			{
				line	=> 'dedicated server started, waiting for clients...',
				attrs	=> {},
			},
		],
		Status		=> {
			line	=> 'Status at 14-02-2009 19:44:10: 22 remote clients, 101.3 send, 5.7 rec (K/sec)',
			attrs	=> {
				players		=> 22,
				sent		=> 101.3,
				'recv'		=> 5.7,
				datetime	=> DateTime->new(
							year	=> 2009,
							month	=> 2,
							day	=> 14,
							hour	=> 19,
							minute	=> 44,
							second	=> 10,
						),
			},
		},
		Suicide		=> {
			line	=> '[193.110.17.39] 123 suicided',
			attrs	=> {
				ip	=> '193.110.17.39',
				nick	=> '123',
			},
		},
		TeamStatus	=> [
			{
				line	=> 'Team  CLA: 11 players,   27 frags',
				attrs	=> {
					team		=> get_team_from_name( 'CLA' ),
					team_name	=> 'CLA',
					players		=> 11,
					frags		=> 27,
					flags		=> undef,
				},
			},
			{
				line	=> 'Team RVSF: 11 players,  157 frags,    2 flags',
				attrs	=> {
					team		=> get_team_from_name( 'RVSF' ),
					team_name	=> 'RVSF',
					players		=> 11,
					frags		=> 157,
					flags		=> 2,
				},
			},
		],
		Unknown		=> [
			{
				line	=> 'some gibberish text',
				attrs	=> {
					ip	=> undef,
					text	=> 'some gibberish text',
				},
			},
			{
				line	=> '[45.231.55.18] some gibberish text',
				attrs	=> {
					ip	=> '45.231.55.18',
					text	=> 'some gibberish text',
				},
			},
		],
	);

	# add 4 tests per log object ( parse, event match, line match, attr test )
	# also, add the actual attribute checks
	foreach my $l ( keys %loglines ) {
		if ( ref( $loglines{ $l } ) eq 'HASH' ) {
			$numtests += 4;
			$numtests += scalar keys %{ $loglines{ $l }->{'attrs'} };
		} else {
			$numtests += 4 * scalar @{ $loglines{ $l } };
			foreach my $line ( @{ $loglines{ $l } } ) {
				$numtests += scalar keys %{ $line->{'attrs'} };
			}
		}
	}
}

# setup our test suite
use Test::More tests => $numtests;

# Go through the tests
foreach my $l ( sort keys %loglines ) {
	# hash or array?
	if ( ref( $loglines{ $l } ) eq 'HASH' ) {
		test_line( $l, $loglines{ $l } );
	} else {
		foreach my $line ( @{ $loglines{ $l } } ) {
			test_line( $l, $line );
		}
	}
}

sub test_line {
	my $event = shift;
	my $data = shift;

	my $log;
	eval {
		$log = Games::AssaultCube::Log::Line->new( $data->{'line'} );
	};

	# basic sanity checks
	is( ! $@, 1, "Parsed $event with no errors" );
	diag( $@ ) if $@;
	cmp_ok( $log->event, 'eq', $event, "Got the event object we expected" );
	cmp_ok( $log->line, 'eq', $data->{'line'}, "The line in the object is the same" );

	# Go through the attributes and see if they are what we expected
	foreach my $attr ( sort keys %{ $data->{'attrs'} } ) {
		# What type of comparison?
		if ( defined $data->{'attrs'}->{ $attr } ) {
			if ( ref $data->{'attrs'}->{ $attr } ) {
				my $reftype = ref( $data->{'attrs'}->{ $attr } );
				if ( $reftype eq 'DateTime' ) {
					# compare datetime objects
					is( $log->$attr()->epoch, $data->{'attrs'}->{ $attr }->epoch, "Testing DateTime attribute($attr)" );
				} elsif ( $reftype eq 'HASH' or $reftype eq 'ARRAY' ) {
					is_deeply( $log->$attr(), $data->{'attrs'}->{ $attr }, "Testing $reftype attribute($attr)" );
				} else {
					die "unknown reftype for comparison: $reftype";
				}
			} else {
				cmp_ok( $log->$attr(), 'eq', $data->{'attrs'}->{ $attr }, "Testing attribute($attr)" );
			}
		} else {
			is( ! defined $log->$attr(), 1, "Testing undef attribute($attr)" );
		}
	}

	# Make sure we have no "unexpected" attributes present in the object
	my $found = 0;
	foreach my $attr ( $log->meta->get_attribute_list ) {
		if ( ! exists $data->{'attrs'}->{ $attr } and $attr ne 'tostr' ) {
			fail( "Unknown attribute - $attr" );
			$found++;
			last;
		}
	}
	pass( "No unknown attributes" ) if ! $found;

	return;
}
