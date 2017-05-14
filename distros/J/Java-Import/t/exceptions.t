use Test::Simple tests => 2;

use Java::Import qw(
	java.lang.Class
);

eval {
	#throw an exception for something that does not exist
	my $class = java::lang::Class->forName(jstring('doesnotexist'));
};

if ( $@ ) {
	#just check if it was even thrown
	ok(1);
	#check type of exception is the correct type
	if ( $@->isa('java::lang::ClassNotFoundException') ) {
		ok(1);
	} else {
		ok(0);
	}
} else {
	ok(0);
}
