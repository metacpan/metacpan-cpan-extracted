#!/usr/bin/perl
use strict; use warnings;
use POE qw( Component::AssaultCube::ServerQuery );
use Games::AssaultCube::MasterserverQuery;

$|++;

POE::Session->create(
	inline_states => {
		_start		=> \&_start,
		_child		=> sub {},
		_stop		=> sub {},
		ac_ping		=> \&got_ping_data,
		do_pings	=> \&do_pings,
	},
);

POE::Kernel->run;
exit;

sub _start {
	$_[HEAP]->{query} = POE::Component::AssaultCube::ServerQuery->new;
	$_[HEAP]->{query}->register;

	# get the masterserver list
	$_[HEAP]->{serverlist} = Games::AssaultCube::MasterserverQuery->new->run->servers;

warn "got " . scalar @{ $_[HEAP]->{serverlist} } . " servers from Masterserver";

	$_[KERNEL]->delay( 'do_pings' => 1 );

	return;
}

sub do_pings {
	my $server = shift @{ $_[HEAP]->{serverlist} };
	if ( defined $server ) {
		$_[HEAP]->{query}->addserver( $server->{ip}, $server->{port} );

		$_[KERNEL]->delay( 'do_pings' => 1 + rand( 10 ) );
	}

	return;
}

sub got_ping_data {
	# $response is a Games::AssaultCube::ServerQuery::Response object
	my( $server, $response ) = @_[ARG0, ARG1];

	if ( defined $response ) {
		warn "got ping data from server " . $server->ID;
	} else {
		warn "server " . $server->ID . " is not responding!";
	}

	return;
}
