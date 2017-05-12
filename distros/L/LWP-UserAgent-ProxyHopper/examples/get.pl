#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use LWP::UserAgent::ProxyHopper;

my $ua = LWP::UserAgent::ProxyHopper->new( agent => 'fox', timeout => 2);

$ua->proxify_load( debug => 1 );

for ( 1..20 ) {
    print "\n\n\nITERATION #$_\n";

    my $response = $ua->proxify_get('http://www.privax.us/ip-test/');

    if ( $response->is_success ) {
        my $content = $response->content;
        if ( my ( $ip ) = $content
            =~ m|<p>.+?IP Address:\s*</strong>\s*(.+?)\s+|s
        ) {
            printf "\n\nSucces!!! \n%s\n", $ip;
        }
        else {
            printf "Response is successfull but seems like we got a wrong "
                    . " page... here is what we got:\n%s\n", $content;
        }
    }
    else {
        print '[script] Network error: ' . $response->status_line;
    }
}