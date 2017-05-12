#!/usr/bin/env perl -w

# Check that the module correctly fails on some bad XML cases.

use strict;
use Test;
BEGIN { plan tests => 6 }

# Just try to use the module.
use Jabber::Lite; ok(1);


# Submit a number of known good objects.  All should return no errors.
# If any are considered bad, then the parsing has gone wrong.
my @badobjs = (
		"<doc/> ",
		"<doc></doc> ",
		'<doc a1="v1"></doc>',
		"<doc>&amp;&lt;&gt;&quot;'</doc>",
		"<doc>&lt;tag?></doc>",
		);

foreach my $curobj( @badobjs ){
	my $jobj = Jabber::Lite->new();

	my ( $tobj, $lastresult, $pending ) = $jobj->create_and_parse( $curobj );
	my $gotinvalid = 0;
	while( $pending !~ /^\s*$/ ){
		( $lastresult, $pending ) = $tobj->parse_more( $pending );
		if( $lastresult == -2 ){
			$gotinvalid = 1;
			$pending = "";
			print "# Received invalid XML?\n";
		}

		# Clear anything.
		if( $lastresult == 1 ){
			my $throwout = $jobj->get_latest() ;
			print "# Clearing object\n";
		}
		print "# End of loop - $lastresult\n";
	}

	print "# $curobj returned $lastresult $gotinvalid X\n";

	if( $lastresult > 0 && ! $gotinvalid ){
		ok( 1 );
	}else{
		ok( 0 );
	}

}


exit;
__END__
