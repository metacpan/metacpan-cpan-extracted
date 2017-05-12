#!/usr/bin/perl -w

use lib 't/lib';
use warnings;
use strict;

use HTTP::Request;
use JSON;
use Mendoza -withPSGI;
use Plack::Test;
use Test::More;

my @tests = (
#	[METHOD,	PATH,						#PARAMS, #EXPECTED, #DESC]
	['GET',	'/',						{}, 'MEN-DO-ZAAAAAAAAAAAAA!!!!!!!!!!!'],
	['GET',	'/?message=QUERY_STRING_YEAHHH',	{}, 'QUERY_STRING_YEAHHH'],
	['GET',	'/query?array=Hello&array=World',	{}, 'Hello World'],
	['GET',	'/status',					{}, 'ALL IS WELL', 'status ok'],
	['GET',	'/math',					{}, 'MATH IS AWESOME', 'math ok #1'],
	['GET',	'/math/',					{}, 'MATH IS AWESOME', 'math ok #2'],
	['GET',	'/math/sum',				{ one => 1, two => 2 }, 3, 'sum from params ok'],
	['GET',	'/math/sum/1/2',				{}, 3, 'sum from path ok'],
	['GET',	'/math/diff',				{ one => 3, two => 1 }, 2, 'diff ok'],
	['GET',	'/math/factorial',			{ num => 5 }, 405, 'factorial dies ok when bad method'],
	['POST',	'/math/factorial',			{ num => 0 }, 1, 'factorial zero ok'],
	['POST',	'/math/factorial',			{ num => 5 }, 120, 'factorial non-zero ok'],
	['GET',	'/math/constants',			{}, 'I CAN HAZ CONSTANTS', 'constants ok'],
	['GET',	'/math/constants/pi',			{}, 3.14159265359, 'pi ok'],
	['GET',	'/math/constants/golden_ratio',	{}, 1.61803398874, 'golden ratio ok'],
	['GET',	'/math/constants/golden_ration',	{}, 404, 'bad regex ok'],
	['GET',	'/math/sum',				{ one => 'a', two => 2 }, 400, 'bad param ok'],
	['GET',	'/math/asdf',				{ one => 1, two => 2 }, 404, 'wrong method ok'],
	['GET',	'/nath/sum',				{ one => 1, two => 2 }, 404, 'wrong topic ok'],

	['OPTIONS',	'/math/sum',				{}, {
		GET => {
			description => 'Adds two integers from params',
			params => {
				one => { required => 1, integer => 1 },
				two => { required => 1, integer => 1 }
			}
		}
	}, 'OPTIONS ok']
);

my $app = Mendoza->new->to_app;
my $test = Plack::Test->create($app);

my $headers = [
	'Content-Type' => 'application/json; charset=UTF-8',
	'Accept' => 'application/json'
];

plan tests => scalar @tests + 1;

foreach (@tests) {
	my $req = HTTP::Request->new($_->[0], $_->[1], $headers, encode_json($_->[2]));
	my $res = $test->request($req);

	if ($req->method eq 'OPTIONS') {
		is($res->header('Allow'), join(',', keys %{$_->[3]}), 'OPTIONS header ok');
		is_deeply(decode_json($res->content), $_->[3], $_->[4]);
	} else {
		my $content = decode_json($res->content);

		if ($res->is_success) {
			my $path = $_->[1]; $path =~ s/\?.+$//;
			$content = $content->{$_->[0].':'.$path};
		} else {
			$content = $res->code;
		}

		is($content, $_->[3], $_->[4]);
	}
}



done_testing();
