#!/usr/bin/perl
use strict; use warnings;

my $numtests;
BEGIN {
	$numtests = 9 + 40;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;

	}
}

use Test::More tests => $numtests;

use_ok( 'Games::AssaultCube' );
use_ok( 'Games::AssaultCube::Utils' );
use_ok( 'Games::AssaultCube::Log::Line' );
use_ok( 'Games::AssaultCube::ServerQuery::Response' );
use_ok( 'Games::AssaultCube::ServerQuery' );
use_ok( 'Games::AssaultCube::MasterserverQuery::Response' );
use_ok( 'Games::AssaultCube::MasterserverQuery' );
use_ok( 'POE::Component::AssaultCube::ServerQuery::Server' );
use_ok( 'POE::Component::AssaultCube::ServerQuery' );

foreach my $event ( qw(	AdminPasswords      DemoStop          Killed
			AutoBalance         DNSLookup         LoadedMap
			Base                FatalError        MapError
			BlacklistEntries    FlagDropped       MasterserverReply
			CallVote            FlagFailedScore   MasterserverRequest
			ClientAdmin         FlagForcedPickup  Says
			ClientChangeRole    FlagLost          ScoreboardStart
			ClientConnected     FlagReset         StartupText
			ClientDisconnected  FlagReturned      Status
			ClientNickChange    FlagScoredKTF     Suicide
			ClientStatus        FlagScored        TeamStatus
			ClientVersion       FlagStole         Unknown
			ConfigError         GameStart
			DemoStart           GameStatus
) ) {

	use_ok( 'Games::AssaultCube::Log::Line::' . $event );
}
