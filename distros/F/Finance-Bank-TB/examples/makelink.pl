#!/usr/bin/perl -w

use lib qw(./blib/lib);

use Finance::Bank::TB;

$mid = '007';
$key = 'JimiBond';

my $tb_obj = Finance::Bank::TB->new($mid,$key);

$vs = '3350078';
$amt = '516';
$rurl = 'http://www.server.sk/Your/Reply/Page';

$tb_obj->configure(
                cs => '0308',
                vs => $vs,
                amt => $amt,
                rurl => $rurl,
                rsms => '903666666',
                desc => 'Example_Description',
                rem => 'kozo@pobox.sk',
        );

print $tb_obj->pay_link("tatra");
