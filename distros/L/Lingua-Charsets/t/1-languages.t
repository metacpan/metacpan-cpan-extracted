#!/usr/bin/perl -w

use strict;
use Test::Simple tests => 2;
use Lingua::Charsets;
use JSON::Any;

my $lc		= Lingua::Charsets->new;
my $json	= JSON::Any->new;

my @tests	= (
	{
		lang	=> 'zh',
		json	=> '["gb2312","big5-eten","gbk","euc-cn"]',
	},
	{
		lang	=> 'sr',
		json	=> '["cp1251","iso-8859-5","iso-8859-2","cp1250"]'
	}
);

for (0..$#tests) {

	my $test	= $tests[$_];
	my $control	= $test->{ json };
	my $charsets	= $lc->charsets_for( $test->{ lang } );
	
	ok ( $control eq $json->encode( $charsets ) );
}
