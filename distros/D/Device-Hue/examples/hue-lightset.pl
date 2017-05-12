#!/usr/bin/env perl

use common::sense;

use Device::Hue;
use Device::Hue::LightSet;

	my $hue = new Device::Hue;

	my $set = Device::Hue::LightSet->create($hue->light(1), $hue->light(3));

	$set->on;

	sleep 2;

	$set->off;



