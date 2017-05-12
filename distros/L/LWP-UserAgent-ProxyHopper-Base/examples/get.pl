#!/usr/bin/env perl

package LWP::UserAgent::Prox;

use lib qw(../lib  lib);
use base 'LWP::UserAgent';
use base 'LWP::UserAgent::ProxyHopper::Base';

package main;

use strict;
use warnings;

my $ua = LWP::UserAgent::Prox->new( agent => 'fox', timeout => 2,


);

$ua->proxify_load( debug => 1, );

for ( 1..10 ) {
    my $response = $ua->proxify_get('http://whatismyipaddress.com/');

    if ( $response->is_success ) {
        my $content = $response->content;
        if ( my ( $ip ) = $content
            =~ m|<!-- do not script -->\s*([\d.]+)\s*<!-- do not script -->|i
        ) {
            printf "\n\nSucces!!! \n%s\n", $ip;
        }
        else {
            printf "Response is successfull but seems like we got a wrong "
                    . " page... here is what we got:\n%s\n", $content;
        }
    }
    else {
        printf "\n[SCRIPT] Network error: %s\n", $response->status_line;
    }
}