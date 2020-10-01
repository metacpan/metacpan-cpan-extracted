#!/usr/bin/perl -T

use strict;
use warnings;

use Test::Most tests => 4;
use Test::Warn;

is($INC{'Devel/FIXME.pm'}, undef, "Devel::FIXME isn't loaded yet");

sub Devel::FIXME::rules {
	sub {
		my $self = shift;
		return Devel::FIXME::SHOUT() if $self->{file} eq __FILE__;
		return Devel::FIXME::DROP();
	}
}

my ( $file, $line ) = ( quotemeta(__FILE__), __LINE__ ); # FIXME foo

warning_like {
	use_ok("Devel::FIXME");
} qr/# FIXME: foo at $file line $line\.$/, "emits proper fixme";

ok($INC{'Devel/FIXME.pm'}, 'Now it has been loaded');
