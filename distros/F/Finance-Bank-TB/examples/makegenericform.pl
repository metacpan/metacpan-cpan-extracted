#!/usr/bin/perl -w

use lib qw(./blib/lib);

use Finance::Bank::TB;

$mid = '9999';
$key = '12345678';

my $tb_obj = Finance::Bank::TB->new($mid,$key);

$vs = '1111';
$amt = '1234.50';
$rurl = "https://moja.tatrabanka.sk/cgi-bin/e-commerce/start/example.jsp";

$tb_obj->configure(
                cs => '0308',
                vs => $vs,
                amt => $amt,
                rurl => $rurl,
                rsms => '903666666',
                desc => 'Example_Description',
                rem => 'kozo@pobox.sk',
        );

print $tb_obj->pay_form("TatraPay",1);

#print "OFFIC: initStr: 99991234.5070311110308https://moja.tatrabanka.sk/cgi-bin/e-commerce/start/example.jsp\n";
#print "DEBUG: initStr: $tb_obj->{'initstr'}\n";
