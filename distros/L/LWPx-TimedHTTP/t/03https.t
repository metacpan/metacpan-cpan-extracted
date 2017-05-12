#!perl
use strict;
use Test::More tests => 1;
use LWP::UserAgent;
use LWPx::TimedHTTP qw(:autoinstall);

SKIP: { 
    skip "You don't have SSL installed - read README.SSL in the libwww-perl distribution to find out why", 1 unless eval { require LWP::Protocol::https };
    my $ua = LWP::UserAgent->new;   
    my $r = $ua->get("https://google.com");
    #diag( $r->code." ".$r->message." ".$r->header('Client-Request-Connect-Time') );
    $TODO = "you might not be online";
    ok( $r->header('Client-Request-Connect-Time'),  "google.com isn't faster than a speeding bullet" );
}