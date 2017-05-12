#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use Hash::Extract qw(hash_extract);

BEGIN{
$] >= 5.009_005 or plan skip_all => "perl $] does not supprot named capture";
}
plan tests => 1;

&test01_named_capture_buffer;

sub test01_named_capture_buffer
{
	my $text = "sample message";
	$text =~ /(?<word>\w+)/ or die "regexp failed";
	hash_extract(\%+, my $word);
	is($word, 'sample');
}

