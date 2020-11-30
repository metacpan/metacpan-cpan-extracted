#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
$jc->strict (1);
print "Before: ", $jc->run (\1), "\n";
$jc->type_handler (sub {
		       my ($thing) = @_;
		       if (ref $thing eq 'SCALAR') {
			   return $$thing;
		       }
		   });
print "After: ", $jc->run (\1), "\n";

