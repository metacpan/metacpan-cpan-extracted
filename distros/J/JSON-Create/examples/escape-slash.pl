#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
my $in = {'/dog/' => '/run/'};
print $jc->run ($in), "\n";
$jc->escape_slash (1);
print $jc->run ($in), "\n";
$jc->escape_slash (0);
print $jc->run ($in), "\n";
