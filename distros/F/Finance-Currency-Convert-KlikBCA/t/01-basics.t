#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::Slurper qw(read_text);
use Finance::Currency::Convert::KlikBCA qw(convert_currency get_currencies);
use Test::More 0.98;

my $page = "$Bin/data/page.html";

my $res = get_currencies(_page_content => read_text($page));
is($res->[0], 200, "get_currencies() status");
$Finance::Currency::Convert::KlikBCA::_get_res = $res;

is(convert_currency(1, "USD", "IDR"), 13100, "convert_currency() 1");
is(convert_currency(1, "USD", "IDR", "sell_ttc"), 13250, "convert_currency() 2");

done_testing;
