#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::Warn;


is($INC{'Devel/FIXME.pm'}, undef, "Devel::FIXME isn't loaded yet");

sub Devel::FIXME::rules {
	sub {
		my $self = shift;
		return Devel::FIXME::SHOUT() if $self->{file} eq __FILE__;
		return Devel::FIXME::DROP();
	}
}

warning_is {
	use_ok("Devel::FIXME");
} "# FIXME: foo at " . __FILE__ . " line " . __LINE__ . ".", "emits proper FIXME"; # FIXME foo

ok($INC{'Devel/FIXME.pm'}, "Now it has been loaded");

