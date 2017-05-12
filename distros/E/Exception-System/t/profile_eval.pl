#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';	
use Exception::Base 'Exception::System';

foreach (1..10000) {
    eval { Exception::System->throw(message=>'Message') };
    if ($@) {
	my $e = Exception::Base->catch;
        if ($e->isa('Exception::Base') and $e->matches('Message')) { 1; }
    }
}

print "tmon.out data collected. Call dprofpp\n";
