#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse;
my $json = '{"yes":true,"no":false}';
my $jp = JSON::Parse->new ();
$jp->set_true ('Yes, that is so true');
my $out = $jp->run ($json);
print $out->{yes}, "\n";

