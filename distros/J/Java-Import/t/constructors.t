use Test::Simple tests => 3;

#test calling all defined constructors as well as an undefined one on a random class

use Java::Import qw(
	java.lang.StringBuffer
);

eval {

	my $sb1 = new java::lang::StringBuffer();
	ok(1); #if we get to here without an exception were good

	my $sb2 = new java::lang::StringBuffer(jstring("A String"));
	ok( "$sb2" eq "A String" );

	my $sb3 = new java::lang::StringBuffer(Java::Import::jint(2));
	my $cap = $sb3->capacity();
	if ( "$cap" eq 2 ) {
		ok(1);
	} else {
		ok(0);
	}

	#XXX TODO make sure Perl checks that all objects passed in are of type ClassProxy
	#my $sb4 = new java::lang::StringBuffer("crap");

};
