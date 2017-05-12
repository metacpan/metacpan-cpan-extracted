#!/usr/bin/perl -d:NYTProf

use lib 'lib', '../lib';
use Exception::Base;

foreach (1..10000) {
    eval { Exception::Base->throw(message=>'Message') };
    if ($@) {
        my $e = Exception::Base->catch;
        if ($e->isa('Exception::Base') and $e->matches('Message')) { 1; }
    }
}

print "nytprof.out data collected. Call nytprofhtml --open\n";
