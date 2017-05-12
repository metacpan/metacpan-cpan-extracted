#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 6;

use Gtk2::Ex::ICal::Recur;
use Data::Dumper;

my $recur = Gtk2::Ex::ICal::Recur->new;
isa_ok($recur, "Gtk2::Ex::ICal::Recur");

my $model = {
	'dtstart' => { 
		year => 2000,
		month  => 6,
		day    => 20,
	},
	'count' => '17',
	'freq' => 'yearly',
	'interval' => '5',
	'byweekno' => [1, -1],
	'byday' => ['su','fr', 'mo'],
	'exceptions' => [],
};

ok(!$recur->set_model($model));
ok($recur->get_model());

$Data::Dumper::Sortkeys = 1;
my $x = $recur->get_model();

is(Dumper($x), Dumper ($model));

ok($recur->update_preview());

$recur = Gtk2::Ex::ICal::Recur->new;
isa_ok($recur, "Gtk2::Ex::ICal::Recur");
