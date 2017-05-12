#!/usr/bin/env perl

use Device::Hue;
use common::sense;

	my $hue = Device::Hue->new({ 'debug' => 1 });

	my $lights = $hue->lights;

	foreach (@$lights) {
		say join(" - ", $_->id, $_->modelid, $_->name);
	}



