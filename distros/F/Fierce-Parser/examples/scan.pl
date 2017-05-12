#!/usr/bin/perl -w

use strict;
use Fierce::Parser;
use Data::Dumper;
my $fp = new Fierce::Parser;

if (defined($ARGV[0])){
    my $domain = $ARGV[0];
    my @d;
    push(@d,$domain);
    my $parser = $fp->parse_scan('',@d);
    my @nodes    = $parser->get_all_nodes();

    foreach my $n (@nodes){
        my $node = $n;
        my $name_servers = $node->name_servers;
        my $zone_transfers = $node->zone_transfers;
        my $bruteforce = $node->bruteforce;
        my $vhost = $node->vhost;
        my $subdomain_bruteforce = $node->subdomain_bruteforce;
        my $ext_bruteforce = $node->ext_bruteforce;
        my $reverse_lookups = $node->reverse_lookups;
        my $wildcard = $node->wildcard;
        my $findmx = $node->findmx;
        my $find_nearby = $node->find_nearby;
        print "===== " . $n->domain . " ====\n";

        print "Nameservers:\n";
        foreach ( @{ $name_servers->nodes } ) {
            print "\tHostname:" . "\t" . $_->hostname . "\n";
            print "\tIP: " . "\t\t" . $_->ip . "\n";
        }   

        print "ZoneTransfers:\n";
        foreach ( @{ $zone_transfers->result } ) {
            print "\tNameServer:" . "\t" . $_->name_server . " - Enabled\n";
#            print "\tOutput: " . "\t" . $_->output . "\n";
        }   

        print "MX:\n";
        foreach ( @{ $findmx->result } ) {
            print "\tPreference:" . "\t" . $_->preference . "\n";
            print "\tExchange: " . "\t" . $_->exchange . "\n";
        }   

        print "Prefix Bruteforce:\n";
        foreach ( @{ $bruteforce->nodes } ) {
            print "\tHostname:" . "\t" . $_->hostname . "\n";
            print "\tIP: " . "\t\t" . $_->ip . "\n";
        }

        if (defined ($vhost) ) {
            print "Virtual Hosts:\n";
            foreach ( @{ $vhost->nodes } ) {
                print "\tHostname:" . "\t" . $_->hostname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
        }
        if ( defined ($ext_bruteforce ) ) {
            print "Extension Bruteforce:\n";
            foreach ( @{ $ext_bruteforce->nodes } ) {
                print "\tHostname:" . "\t" . $_->hostname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
        }

        print "Reverse Lookup:\n";
        foreach ( @{ $reverse_lookups->nodes } ) {
            print "\tHostname:" . "\t" . $_->hostname . "\n";
            print "\tIP: " . "\t\t" . $_->ip . "\n";
        }
        
        print "Find Nearby:\n";
        foreach ( @{ $find_nearby->ptrs } ) {
            print "\tHostname:" . "\t" . $_->hostname . "\n";
            print "\tPtrdname:" . "\t" . $_->ptrdname . "\n";
            print "\tIP: " . "\t\t" . $_->ip . "\n";
        }
    }
}
else {
    print "Usage: $0 [domain]\n";
}
