#!/usr/bin/perl
use strict; use warnings;
use POE qw( Component::AssaultCube::ServerQuery );

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
	$_[HEAP]->{starttime} = time();
	$_[KERNEL]->yield( 'do_pings' );

	return;
}

sub do_pings {
	$_[HEAP]->{server} = $_[HEAP]->{query}->addserver({ server => '78.46.252.198', port => 28763, frequency => 10 });

	return;
}

sub got_ping_data {
	# $response is a Games::AssaultCube::ServerQuery::Response object
	my( $server, $response ) = @_[ARG0, ARG1];

	# "cool off" after 3 pings
	if ( $_[HEAP]->{counter}++ == 2 ) {
		$_[HEAP]->{query}->delserver( delete $_[HEAP]->{server} );
		$_[HEAP]->{counter} = 0;

		$_[KERNEL]->delay( 'do_pings', 15 );
	}

	if ( defined $response ) {
		warn "[" . $response->timestamp . "] got ping data from " . $server->ID;
	} else {
		warn "server " . $server->ID . " is not responding!";
	}

	# arbitrarily shutdown
	if ( ( $_[HEAP]->{starttime} + ( 1 * 60 ) ) < time() ) {
		warn "shutting down";
		$_[HEAP]->{query}->shutdown;
	}

	return;
}