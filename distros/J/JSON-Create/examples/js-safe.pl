#!/home/ben/software/install/bin/perl
use warnings;
use strict;
binmode STDOUT, ":utf8";
use JSON::Create;
my $in = ["\x{2028}"];
my $jc = JSON::Create->new ();
print $jc->run ($in), "\n";
$jc->no_javascript_safe (1);
print $jc->run ($in), "\n";

