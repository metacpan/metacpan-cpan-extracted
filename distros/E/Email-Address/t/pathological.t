use strict;
use warnings;
use Test::More;
use Email::Address;
use Time::HiRes 'time';

my %cases = (
    'CVE-2015-7686' =>
        q{\(¯¯`·.¥«P®ÎÑç€ØfTh€ÐÅ®K»¥.·`¯¯\) <email@example.com>, "(> \" \" <)                              ( ='o'= )                              (\")___(\")  sWeEtAnGeLtHePrInCeSsOfThEsKy" <email2@example.com>, "(i)cRiStIaN(i)" <email3@example.com>, "(S)MaNu_vuOLeAmMazZaReNimOe(*)MiAo(@)" <email4@example.com>},
    'CVE-2018-12558' => "\f" x 30,
);

for my $name ( sort keys %cases ) {
    my $start = Time::HiRes::time();
    Email::Address->parse( $cases{$name} );
    my $time = Time::HiRes::time() - $start;
    ok( $time < 0.5, "Parsing '$name' takes less than 0.5 second($time)" );
}

done_testing();
