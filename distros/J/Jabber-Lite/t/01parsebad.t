#!/usr/bin/env perl -w

# Check that the module correctly fails on some bad XML cases.

use strict;
use Test;
BEGIN { plan tests => 6 }

# Just try to use the module.
use Jabber::Lite; ok(1);


# Submit a number of known bad objects.  All should return '-2'.
# If any are considered good, then the parsing has gone wrong.
my @badobjs = (
		"<doc//>",				# Double '/'.
		"<doc> <doc ?  </doc",			# '?' wrong.
		"<doc><a</a> </doc>",			# broken.
		"<doc> <.doc></.doc> </doc> ",		# Name with '.'
		"<doc><?target some data></doc>",	# No '?>' to close.
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
		}

		# Clear anything.
		my $throwout = $jobj->get_latest() if( $lastresult == 1 );
	}

	# print STDERR "# $curobj returned $lastresult $gotinvalid " . $jobj->toStr . "X\n";
	print "# $curobj returned $lastresult $gotinvalid X\n";
		
	if( $gotinvalid ){
		# print STDERR "Foo\n";
		ok( 1 );
	}elsif( $lastresult != 1 ){
		# print STDERR "Bar\n";
		ok( 1 );
	}else{
		# print STDERR "Blah\n";
		ok( 0 );
	}

}


exit;
__END__
