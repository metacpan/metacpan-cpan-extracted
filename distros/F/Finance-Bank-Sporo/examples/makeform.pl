#!/usr/bin/perl -w

use lib qw(./blib/lib);

use Finance::Bank::Sporo;

$prenumber = '123456';
$number = '1234567890';

my $sporo_obj = Finance::Bank::Sporo->new($prenumber,$number);

$vs = '3350078';
$amt = '516';
$rurl = 'http://www.server.sk/Your/Reply/Page';

$sporo_obj->configure(
                amt => $amt,
                ss => '2222222222',
                vs => $vs,
                rurl => $rurl,
                param => "vs=$vs",
        );

print $sporo_obj->pay_form();
