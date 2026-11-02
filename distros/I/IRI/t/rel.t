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
	my @tests	= @$tests;
	while (my ($url, $expect) = splice(@tests, 0, 2, ())) {
		my $i	= URI->new($url);
		my $r	= $i->rel($base);
		my $u	= URI->new_abs($expect, $base)->as_string;
		is($u, $url, "CONFIRM: $url [$b]");
	}
}

sub run_tests {
	my $base	= shift;
	my $b		= $base->abs;
	my $tests	= shift;
	my @tests	= @$tests;
	while (my ($url, $expect) = splice(@tests, 0, 2, ())) {
		my $i	= IRI->new(value => $url);
		my $r	= $i->rel($base);
# 		warn "Turning " . $i->abs . " into a relative IRI using base $b ===> " . $r->abs;
		is($r->as_string, $expect, "$url [$b]");
	}
}

subtest 'rel: scheme,host' => sub {
	my $base	= IRI->new(value => "http://www.example.org/");
	my @REL_TESTS	= (
		'http://www.example.com/'			=> '//www.example.com/',
		'https://www.example.org/'			=> 'https://www.example.org/',
		'http://www.example.org/'			=> '',
		'http://www.example.org/foo'		=> 'foo',
		'http://www.example.org/foo/bar'	=> 'foo/bar',
		'http://www.example.org/#hello'		=> '#hello',
		'http://www.example.org/?query'		=> '?query',
		'http://www.example.org/foo?query'		=> 'foo?query',
	);
	run_tests($base, \@REL_TESTS);
	confirm_tests($base, \@REL_TESTS);
};

subtest 'rel: scheme,host,path' => sub {
	my $base	= IRI->new(value => "http://www.example.org/foo/bar");
	my @REL_TESTS	= (
		'http://www.example.com/'			=> '//www.example.com/',
		'https://www.example.org/'			=> 'https://www.example.org/',
		'http://www.example.org/'			=> '../',
		'http://www.example.org/foo'		=> '../foo',
		'http://www.example.org/foo/bar'	=> '',
		'http://www.example.org/#hello'		=> '../#hello',
		'http://www.example.org/?query'		=> '../?query',
	);
	run_tests($base, \@REL_TESTS);
	confirm_tests($base, \@REL_TESTS);
};

subtest 'rel: scheme,host,path 2' => sub {
	my $base	= IRI->new(value => "http://xmlns.com/foaf/0.1/");
	my @REL_TESTS	= (
		'http://xmlns.com/foaf/0.1/name'	=> 'name',
	);
	run_tests($base, \@REL_TESTS);
	confirm_tests($base, \@REL_TESTS);
};

subtest 'tests derived from rfc3986 5.4.1' => sub {
	my $base	= IRI->new(value => "http://a/b/c/d;p?q");
	my @REL_TESTS	= (
		"g:h"					=> "g:h",
		"http://a/b/c/g"		=> "g",
		"http://a/b/c/g/"		=> "g/",
		"http://a/g"			=> "/g",
		"http://g"				=> "//g",
		"http://a/b/c/d;p?y"	=> "?y",
		"http://a/b/c/g?y"		=> "g?y",
		"http://a/b/c/d;p?q#s"	=> "#s",
		"http://a/b/c/g#s"		=> "g#s",
		"http://a/b/c/g?y#s"	=> "g?y#s",
		"http://a/b/c/;x"		=> ";x",
		"http://a/b/c/g;x"		=> "g;x",
		"http://a/b/c/g;x?y#s"	=> "g;x?y#s",
		"http://a/b/c/d;p?q"	=> "",
		"http://a/b/c/"			=> "./",
		"http://a/b/"			=> "../",
		"http://a/b/g"			=> "../g",
		"http://a/"				=> "../../",
		"http://a/g"			=> "/g",
	);
	run_tests($base, \@REL_TESTS);
	confirm_tests($base, \@REL_TESTS);
};

subtest 'rel: scheme,host,path,query' => sub {
	my $base	= IRI->new(value => "http://example.org/sparql?query=ASK%7B%7D%0A");
	my @REL_TESTS	= (
		'http://example.org/sparql#defaultGraph'	=> 'sparql#defaultGraph',
	);
	run_tests($base, \@REL_TESTS);
	confirm_tests($base, \@REL_TESTS);
};

subtest 'http relative IRI construction with different bases' => sub {
	my $iri        = IRI->new(value => 'http://example.org:80/foo/bar/baz#xyz?q=ff');

	my $base0    = IRI->new(value => 'http://example.org/');
	my $base1    = IRI->new(value => 'http://example.org:80/foo');
	my $base2    = IRI->new(value => 'http://example.org:80/foo/');
	my $base3    = IRI->new(value => 'http://example.org:80/foo/ba');
	my $base4    = IRI->new(value => 'http://example.org:80/foo/bar/?q=ff');
	my $base5    = IRI->new(value => 'https://example.org:80/foo/bar/baz');
	my $base6    = IRI->new(value => 'http://example.com:80/foo/bar/baz');
	my $base7    = IRI->new(value => 'http://example.org:81/foo/bar/baz');

	is($iri->rel($base0)->abs, '//example.org:80/foo/bar/baz#xyz?q=ff', 'different port');
	is($iri->rel($base1)->abs, 'foo/bar/baz#xyz?q=ff', '/foo');
	is($iri->rel($base2)->abs, 'bar/baz#xyz?q=ff', '/bar');
	is($iri->rel($base3)->abs, 'bar/baz#xyz?q=ff', '/foo/ba (shared prefix, but ending mid-path)');
	is($iri->rel($base4)->abs, 'baz#xyz?q=ff', 'extra query');
	is($iri->rel($base5)->abs, 'http://example.org:80/foo/bar/baz#xyz?q=ff', 'different scheme');
	is($iri->rel($base6)->abs, '//example.org:80/foo/bar/baz#xyz?q=ff', 'different host');
	is($iri->rel($base7)->abs, '//example.org:80/foo/bar/baz#xyz?q=ff', 'different port');
};

done_testing();
