#!perl

use 5.010001;
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

use File::Slurper qw(read_text);
use Finance::Currency::Convert::Mandiri qw(convert_currency get_currencies);

my $page = "$Bin/data/page-2022-02-26.html";

my $res = get_currencies(_page_content => read_text($page));
#use DD; dd $res;
is($res->[0], 200, "get_currencies() status") or diag explain $res;
$Finance::Currency::Convert::Mandiri::_get_res = $res;

is(convert_currency(1, "USD", "IDR"), 14370, "convert_currency() 1");
is(convert_currency(1, "USD", "IDR", "sell_ttc"), 14525, "convert_currency() 2");

done_testing;
