#!/usr/bin/perl

use strict;
use warnings;

use utf8;

#use Test::More 'no_plan';
use Test::More tests => 8;
use Test::Differences;
use File::Temp 'tempdir';
use IO::Any;
use JSON::MaybeXS;
use Test::Exception;

use FindBin '$Bin';

BEGIN {
	use_ok ( 'JSON::Util' ) or exit;
}

exit main();

sub main {
	my $jsonxs = JSON::MaybeXS->new->utf8->pretty->convert_blessed;
	my $tmpdir = tempdir( CLEANUP => 1 );
	
	my $utf8_data = [
			'foo'   => 'baz',
			'ščžť'  => 'ľřďôŮ',
			'トップ' => 'お問い合わせ'
	];
	
    eq_or_diff(
		JSON::Util->decode([$Bin, 'stock', '01.json']),
		{'bar' => 'foo'},
		'JSON::Util->decode("filename")'
	);
	
    JSON::Util->encode(
    	$utf8_data,
		[$tmpdir, 'someother.json'],
	);
	my $test_json_file_content = IO::Any->slurp([$tmpdir, 'someother.json']);
	$test_json_file_content =~ s/\s+$//; # strip final newline (introduced in JSON::XS 2.26)
    eq_or_diff(
		$test_json_file_content,
		IO::Any->slurp([$Bin, 'stock', '02.json']),
		'JSON::Util->encode()',
	);
	eq_or_diff(
		JSON::Util->decode([$tmpdir, 'someother.json'], {'LOCK_SH'=>1}),
		$utf8_data,
		'JSON::Util->decode() back',
	);
	
	my $json = JSON::Util->new('pretty' => 0);
	is($json->encode([987,789]), '[987,789]', '$json->encode([])');
	is($json->encode({987 => 789}), '{"987":789}', '$json->encode({})');
	
	LOCKING: {
		my $read_lock = IO::Any->read([$tmpdir, 'someother.json'], {'LOCK_SH'=>1});
		dies_ok {
			JSON::Util->encode(
				{},
				[$tmpdir, 'someother.json'],
				{'LOCK_EX'=>1, 'LOCK_NB'=>1})
		}'encode() while file locked must fail';
		
		eq_or_diff(
			JSON::Util->decode([$tmpdir, 'someother.json'], {'LOCK_SH'=>1}),
			$utf8_data,
			'and content must not be changed',
		);
	}	

	return 0;
}

