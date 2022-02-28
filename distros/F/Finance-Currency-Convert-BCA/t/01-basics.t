#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

use File::Slurper qw(read_text);
use Finance::Currency::Convert::BCA qw(convert_currency get_currencies);

my $page = "$Bin/data/page-2022-02-26.html";

my $res = get_currencies(_page_content => read_text($page));
is($res->[0], 200, "get_currencies() status") or diag explain $res;
$Finance::Currency::Convert::BCA::_get_res = $res;

is(convert_currency(1, "USD", "IDR"), 14366, "convert_currency() 1");
is(convert_currency(1, "USD", "IDR", "sell_ttc"), 14516, "convert_currency() 2");

done_testing;
