#!/usr/local/bin/perl
#
# $Id: 01-RoundTrip.t,v 0.1 2005/08/17 20:11:27 dankogai Exp $
#
use strict;
use Encode qw(encode);
use Lingua::JA::Numbers;
use Test::More tests => 169;

my $n = 0;
binmode STDOUT, ':utf8';
use bignum;
use utf8;
my $num = 0; my $fra = 0;
for (1..53){
    my $j = num2ja($num);
    my $n = ja2num($j);
    is($n, $num,  encode("utf8", "$num => $j"));
    $j = num2ja($fra);
    $n = ja2num($j);
    is($n, $fra,  encode("utf8", "$fra => $j"));
    if ($_ <= 21){ # practical
        $j = num2ja($num, {style=>"romaji"});
        $n = ja2num($j);
        is($n, $num,  encode("utf8", "$num => $j"));
        $j = num2ja($num, {style=>"hiragana"});
        $n = ja2num($j);
        is($n, $num,  encode("utf8", "$num => $j"));
        $j = num2ja($num, {style=>"katakana"});
        $n = ja2num($j);
        is($n, $num,  encode("utf8", "$num => $j"));
    }
    #
    $num = $num * 10 + $_ % 10;
    $fra = $num/10**length($num);
}
__END__

