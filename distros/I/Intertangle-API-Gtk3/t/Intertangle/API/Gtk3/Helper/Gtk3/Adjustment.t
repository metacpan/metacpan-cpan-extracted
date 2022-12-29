#!/usr/bin/env perl

use Test::Most;

use Renard::Incunabula::Common::Setup;

use lib 't/lib';

use Gtk3;
plan Gtk3::init_check
	? ( tests    => 2 )
	: ( skip_all => 'Could not init GTK' );

use Intertangle::API::Gtk3::Helper ();
Intertangle::API::Gtk3::Helper->import;
use Intertangle::API::Gtk3::Helper::Gtk3::Adjustment;

my $adjustment = Gtk3::Adjustment->new(5, 0, 10, 1, 2, 2);

subtest "Increment" => fun() {
	$adjustment->set_value(5);
	is $adjustment->get_value, 5, 'starting value';
	$adjustment->increment_step;
	is $adjustment->get_value, 6, 'increment value';
	$adjustment->increment_step;
	is $adjustment->get_value, 7, 'increment value';
};

subtest "Decrement" => fun() {
	$adjustment->set_value(5);
	is $adjustment->get_value, 5, 'starting value';
	$adjustment->decrement_step;
	is $adjustment->get_value, 4, 'decrement value';
	$adjustment->decrement_step;
	is $adjustment->get_value, 3, 'decrement value';
};

done_testing;
