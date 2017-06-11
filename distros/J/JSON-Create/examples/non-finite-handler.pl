#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create;
my $bread = { 'curry' => -sin(9**9**9) };
my $jcnfh = JSON::Create->new ();
print $jcnfh->run ($bread), "\n";
$jcnfh->non_finite_handler(sub { return 'null'; });
print $jcnfh->run ($bread), "\n";
