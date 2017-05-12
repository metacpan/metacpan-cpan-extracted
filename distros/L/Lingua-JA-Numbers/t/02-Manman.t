#!/usr/local/bin/perl
#
# $Id: 02-Manman.t,v 0.1 2005/08/17 20:11:27 dankogai Exp $
#
use strict;
use Encode qw(encode);
use Lingua::JA::Numbers;
use Test::More tests => 96;

binmode STDOUT, ':utf8';
use bignum;
use utf8;
my $debug = 0;
for (53..100){
	my $num = 10**$_-1;
	my $j = num2ja($num);
	my $n = ja2num($j);
	is($n, $num,  encode("utf8", "$num => $j"));
	$j = num2ja($num, {manman=>1});
	$n = ja2num($j, {manman=>1, debug=>$debug});
	is($n, $num,  encode("utf8", "$num => $j"));
}
__END__

