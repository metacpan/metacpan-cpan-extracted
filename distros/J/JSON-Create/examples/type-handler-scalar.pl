#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
$jc->strict (1);
print $jc->run (\1), "\n";
$jc->type_handler (sub {
		       my ($thing) = @_;
		       if (ref $thing eq 'SCALAR') {
			   return $$thing;
		       }
		   });
print $jc->run (\1), "\n";

