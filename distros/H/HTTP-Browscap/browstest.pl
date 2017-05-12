#!/usr/bin/perl

use lib '/home/james/lib/perl';

use HTTP::Browscap;

my $browser = new HTTP::Browscap;

$browser->setbrowser('Mozilla/4.03 (Win16; I)');

print $browser->property( {    # browser => 'Mozilla/4.03 (Win16; I)',
			    property => 'majorver' } );

$browser->setbrowser();

print "\n----\n";

print $browser->property( {    # browser => 'Mozilla/4.03 (Win16; I)',
			    property => 'majorver' } );
