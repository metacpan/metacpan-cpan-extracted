#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;

require_ok('Lustre::Info');


my $l = Lustre::Info->new;

	$l->is_ost;
	pass("is_ost does not die");

	$l->is_mds;
	pass("is_mds does not die");

	$l->is_mdt;
	pass("is_mdt does not die");

	my @x = $l->get_ost_list;
	pass("get_ost_list returned ".int(@x)." results");

