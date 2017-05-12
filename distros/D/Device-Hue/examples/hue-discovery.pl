#!/usr/bin/env perl

use common::sense;

use Device::Hue;

	# Pass 'unknown' as bridge and key as we're trying to discover the bridge, so we don't have that info yet
	my $hue = Device::Hue->new({ 'debug' => 0, 'bridge' => 'unknown', 'key' => 'unknown' });

	say 'Detecting through remote upnp...';

	foreach (@{$hue->nupnp}) {
		say "+ Bridge at $_";
	}

	say "Detecting through local discovery...";

	foreach (@{$hue->upnp}) {
		say "+ Bridge at $_";
	}

	say "\nIf one or more bridges were detected, set the environment variable 'HUE_BRIDGE' to one of the detected IP addresses to use the other examples in this folder.";
	say "Note: you'll also need an API key that is granted access by the bridge. See http://developers.meethue.com/gettingstarted.html";
	say "If you have acquired an API key, set the environment variable 'HUE_KEY' to use the examples."

