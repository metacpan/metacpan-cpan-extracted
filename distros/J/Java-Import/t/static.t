use Test::Simple tests => 1;

use Java::Import qw(
	java.lang.Class
);

#call a static method on a class

eval {
	my $class = java::lang::Class->forName(jstring("java.lang.StringBuffer"));
	ok(1);
};
