use Test::Simple tests => 1;


{
	#import the requested class
	use Java::Import qw(
		java.lang.StringBuffer
	);
	
	#check to make sure the namespace has been created by calling new on it
	eval {
		my $sb = new java::lang::StringBuffer();
	};
	
	#if the new succeeded then the namespace was setup correctly
	ok($@ ? 0 : 1);
}
