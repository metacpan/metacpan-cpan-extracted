#!/usr/bin/perl

use strict;
use warnings;
no warnings 'redefine';
use Test::More;
use Data::Dumper;
use Encode qw(decode_utf8);
use URI;
use utf8;

binmode(\*STDOUT, ':utf8');

use IRI;

sub confirm_tests {
	my $base	= URI->new(shift->abs);
	my $b		= $base->as_string;
	my $tests	= shift;
	while (my ($url, $expect) = each %$tests) {
		my $u	= URI->new_abs($url, $base)->as_string;
		is($u, $expect, "CONFIRM: $url [$b]");
	}
}

sub run_tests {
	my $base	= shift;
	my $b		= $base->abs;
	my $tests	= shift;
	while (my ($url, $expect) = each %$tests) {
		my $i	= IRI->new(value => $url, base => $base);
		is($i->abs, $expect, "$url [$b]");
	}
}

subtest 'base resolution tests from rfc3986 5.4.1' => sub {
	my $base	= IRI->new(value => "http://a/b/c/d;p?q");
	my %REL_TESTS	= (
		"g:h"		=> "g:h",
		"g"			=> "http://a/b/c/g",
		"./g"		=> "http://a/b/c/g",
		"g/"		=> "http://a/b/c/g/",
		"/g"		=> "http://a/g",
		"//g"		=> "http://g",
		"?y"		=> "http://a/b/c/d;p?y",
		"g?y"		=> "http://a/b/c/g?y",
		"#s"		=> "http://a/b/c/d;p?q#s",
		"g#s"		=> "http://a/b/c/g#s",
		"g?y#s"		=> "http://a/b/c/g?y#s",
		";x"		=> "http://a/b/c/;x",
		"g;x"		=> "http://a/b/c/g;x",
		"g;x?y#s"	=> "http://a/b/c/g;x?y#s",
		""			=> "http://a/b/c/d;p?q",
		"."			=> "http://a/b/c/",
		"./"		=> "http://a/b/c/",
		".."		=> "http://a/b/",
		"../"		=> "http://a/b/",
		"../g"		=> "http://a/b/g",
		"../.."		=> "http://a/",
		"../../"	=> "http://a/",
		"../../g"	=> "http://a/g",
	);
	run_tests($base, \%REL_TESTS);
	confirm_tests($base, \%REL_TESTS);
};

done_testing();
