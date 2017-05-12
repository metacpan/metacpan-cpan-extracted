#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
BEGIN { $ENV{DEBUG_CB} = 2 }
use Devel::Leak::Cb;
use Sub::Name;

my $glb = cb {
	# sub is not a closure => compiled as static
	# hence not destroyed till the end of time and marked as leaked
	# for such subs use common sub {}
};

my $var;
my $sub; $sub = cb {
	$var;
}; # not leaked

my $sux; $sux = cb {
	$sux;
}; # leaked
