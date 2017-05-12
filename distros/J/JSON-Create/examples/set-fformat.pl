#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
my @array = (1000000000.0,3.141592653589793238462643383279502884197169399375105820974944592307816406,0.000000001);
print $jc->run (\@array), "\n";
$jc->set_fformat ('%.3f');
print $jc->run (\@array), "\n";
$jc->set_fformat ('%E');
print $jc->run (\@array), "\n";
$jc->set_fformat ();
print $jc->run (\@array), "\n";
