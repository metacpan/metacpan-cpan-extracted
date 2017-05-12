#!/usr/bin/perl -w

use strict;
use Fierce::Parser;
use Data::Dumper;
my $fp = new Fierce::Parser;


if (defined($ARGV[0])){
    my $file = $ARGV[0];
    my $parser = $fp->parse_file($file);
    my @nodes    = $parser->get_all_nodes();

    foreach my $n (@nodes){
        my $node = $n;
        my $name_servers = $node->name_servers;
        my $arin_lookup = $node->arin_lookup;
        my $whois_lookup = $node->whois_lookup;
        my $zone_transfers = $node->zone_transfers;
        my $bruteforce = $node->bruteforce;
        my $vhost = $node->vhost;
        my $subdomain_bruteforce = $node->subdomain_bruteforce;
        my $ext_bruteforce = $node->ext_bruteforce;
        my $reverse_lookups = $node->reverse_lookups;
        my $wildcard = $node->wildcard;
        my $findmx = $node->findmx;
        my $find_nearby = $node->find_nearby;

        print "==== " . $n->domain . " ====\n";
        if ( $name_servers ) {
            print "Nameservers:\n";
            foreach my $i ( @{ $name_servers->nodes } ) {
                print "\tHostname:" . "\t" . $i->hostname . "\n";
                print "\tIP:" . "\t\t" . $i->ip . "\n";
                print "\tZone Transfer:" . "\t";
                my ($zt_status,$zt_output);
                foreach my $zt ( @{ $zone_transfers->result } ) {
                    if ( $i->hostname eq $zt->name_server ) { 
                        if ( $zt->bool == 1 ) {
                            $zt_status = 1;
                            print "Enabled\n";
                            print "\tFound Nodes:\n";
                            foreach my $n ( @{ $zt->nodes } ) {
                                print "\t\t\tIP:\t\t" . $n->ip . "\n";
                                print "\t\t\tHostname:\t" . $n->hostname . "\n";
                                print "\t\t\tType:\t\t" . $n->type . "\n";
                                print "\t\t\tTTL:\t\t" . $n->ttl . "\n";
                            }
                        }
                        else {
                            print "Disabled\n";
                        }
                    }
                }
            }   
            print "\n";
        }

        if ( $arin_lookup ) {
            print "ARIN:\n";
            foreach (  @{ $arin_lookup->result}  ) {
                print "\tNetHandle:" . "\t" . $_->net_handle . "\n";
                print "\tNetRange: " . "\t" . $_->net_range . "\n";
            }   
            print "\n";
        }
        if ( $whois_lookup ) {
            print "Whois:\n";
            foreach ( @{ $whois_lookup->result } ) {
                print "\tNetHandle:" . "\t" . $_->net_handle . "\n";
                print "\tNetRange: " . "\t" . $_->net_range . "\n";
            }   
            print "\n";
        }
 

        if ( $findmx ) {
            print "MX:\n";
            foreach ( @{ $findmx->result } ) {
                print "\tPreference:" . "\t" . $_->preference . "\n";
                print "\tExchange: " . "\t" . $_->exchange . "\n";
            }   
            print "\n";
        }
        
        if ($bruteforce) {
            print "Prefix Bruteforce:\n";
            foreach ( @{ $bruteforce->nodes } ) {
                print "\tHostname:" . "\t" . $_->hostname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
            print "\n";
        }
        if ($vhost) {
            print "Virtual Hosts:\n";
            foreach ( @{ $vhost->nodes } ) {
                print "\tHostname:" . "\t" . $_->hostname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
            print "\n";
        }
        if ($ext_bruteforce){
            print "Extension Bruteforce:\n";
            foreach ( @{ $ext_bruteforce->nodes } ) {
                print "\tHostname:" . "\t" . $_->hostname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
            print "\n";
        }
        if ($reverse_lookups){
            print "Reverse Lookup:\n";
            foreach ( @{ $reverse_lookups->nodes } ) {
                print "\tHostname:" . "\t" . $_->hostname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
            print "\n";
        }
       
        if ($find_nearby){ 
            print "Find Nearby:\n";
            foreach ( @{ $find_nearby->ptrs } ) {
                print "\tPtrdname:" . "\t" . $_->ptrdname . "\n";
                print "\tIP: " . "\t\t" . $_->ip . "\n";
            }
        }
    }

    if ($ARGV[1]) {
        print "ARIN:\n";
        my $arin_search = $ARGV[1];

        use Net::Whois::ARIN;
        use Data::Dumper;
        my $w = Net::Whois::ARIN->new(
                    host    => 'whois.arin.net',
                    port    => 43,
                    timeout => 30,
                );
        if (!defined($ARGV[0])){
            print "Usage: $0 [arin query]\n";
            exit;
        }
        my @out = $w->query($arin_search);
        foreach(@out){
            print "\t$_\n";
        }
    }
}
else {
    print "Usage: $0 [fierce-xml] (arin search term)\n";
}
