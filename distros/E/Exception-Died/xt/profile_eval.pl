#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';	
use Exception::Died '%SIG';

foreach (1..10000) {
    eval { die 'Message' };
    if ($@) {
	my $e = Exception::Base->catch;
        if ($e->isa('Exception::Base') and $e->matches('Message')) { 1; }
    }
}

print "tmon.out data collected. Call dprofpp\n";
