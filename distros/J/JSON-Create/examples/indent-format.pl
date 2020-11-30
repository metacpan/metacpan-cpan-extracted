#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
my %thing = ("it's your thing" => [qw! do what you !, {wanna => 'do'}],
	     "I can't tell you" => [{who => 2}, qw! sock it!, 2]);
my $jc = JSON::Create->new ();
$jc->indent (1);
my $out = $jc->run (\%thing);
$out =~ s/^(\t+)/ "  " x length ($1) /gesm;
print $out;
