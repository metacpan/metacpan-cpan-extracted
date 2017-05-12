#!/usr/bin/perl

use Test::File::ShareDir -share => {
  -dist   => { 'EWS-Client'  => 'share' }
};

use lib './lib';
use EWS::Client;
use DateTime;

my $ews = EWS::Client->new({
    server      => 'exchangeserver.example.com',
    username    => 'oliver',
    password    => 's3kr1t', # or set in $ENV{EWS_PASS}
    use_negotiated_auth => 1, # only for NTLM
});

my $entries = $ews->calendar->retrieve({
    start => DateTime->now(),
    end   => DateTime->now->add( months => 1 ),
});

print "I retrieved ". $entries->count ." items\n";

while ($entries->has_next) {
    my $e = $entries->next;
    print $e->Subject, ' at ', $e->Start, "\n";
}
