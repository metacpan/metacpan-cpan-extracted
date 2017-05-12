#!/usr/bin/env perl -w

# Check that the module's SRV ordering is indeed random.

use strict;
use Test;
BEGIN { plan tests => 2 }

use Jabber::Lite; ok(1);

my $jobj = new Jabber::Lite;

srand(time);

# Under the hood poking around.
@{$jobj->{'_resolved'}{'testsrv.example.com'}{'srv'}{'1'}} = (
			"0 1234 testA.example.com.",
			"0 1234 testB.example.com.",
			"0 1234 testC.example.com.",
			"0 1234 testD.example.com.",
			"0 1234 testE.example.com.",
			"0 1234 testF.example.com.",
			"60 1234 testG.example.com.",
			"50 1234 testH.example.com.",
			);
@{$jobj->{'_resolved'}{'testsrv.example.com'}{'srv'}{'10'}} = (
		"0 1234 testI.example.com.",
		);

@{$jobj->{'_resolved'}{'testA.example.com.'}{'address'}} = ( "1.2.3.1" );
@{$jobj->{'_resolved'}{'testB.example.com.'}{'address'}} = ( "1.2.3.2" );
@{$jobj->{'_resolved'}{'testC.example.com.'}{'address'}} = ( "1.2.3.3" );
@{$jobj->{'_resolved'}{'testD.example.com.'}{'address'}} = ( "1.2.3.4", "4.3.2.1" );
@{$jobj->{'_resolved'}{'testE.example.com.'}{'address'}} = ( "1.2.3.5" );
@{$jobj->{'_resolved'}{'testF.example.com.'}{'address'}} = ( "1.2.3.6" );
@{$jobj->{'_resolved'}{'testG.example.com.'}{'address'}} = ( "1.2.3.7" );
@{$jobj->{'_resolved'}{'testH.example.com.'}{'address'}} = ( "1.2.3.8" );
@{$jobj->{'_resolved'}{'testI.example.com.'}{'address'}} = ( "1.2.3.9" );

my $loop = 0;
my %seenstrings = ();
while( $loop < 50 ){
	$loop++;
	my @list = $jobj->resolved();
	my $str = join( ":", @list );
	$seenstrings{"$str"}++;
	print "# Try #$loop returned $str\n";
}

# $seencount should be 2 or more.
my $seencount = 0;
foreach my $seenkey( keys %seenstrings ){
	$seencount++;
}

if( $seencount > 1 ){
	print "# ->resolved returned $seencount different strings, expecting more than 1\n";
	ok(1);
}else{
	print "# Multiple calls to ->resolved always returned the same string.\n";
	print "# rand() appears to be broken?\n";
	ok(0);
}


exit;
__END__
