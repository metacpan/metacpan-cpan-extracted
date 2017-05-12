#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
use boolean;
my $thing = {'Yes' => true, 'No' => false};
my $jc = JSON::Create->new ();
print $jc->run ($thing), "\n";
$jc->bool ('boolean');
print $jc->run ($thing), "\n";

