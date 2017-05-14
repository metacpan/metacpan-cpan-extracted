use Test::Simple tests => 14;

use Java::Import qw(
	java.lang.Class
);

#call a method that returns a Java Array and check it out
my $sb_class = java::lang::Class->forName(jstring("java.lang.StringBuffer"));
my $constructors = $sb_class->getConstructors();
ok(scalar(@$constructors) == 3);

#look at each element in the array and make sure it is what we think it is
foreach my $constructor ( @$constructors ) {
	if ( $constructor->isa('java::lang::reflect::Constructor') ) {
		ok(1);
	}
}

#access the array via regular array syntax
for ( my $i = 0; $i < scalar(@$constructors); $i++ ) {
	my $constructor = $$constructors[$i];
	if ( $constructor->isa('java::lang::reflect::Constructor') ) {
		ok(1);
	}
}

#create a Java Array
my $array = Java::Import::newJavaArray('java.lang.String', 3);
ok($array);

#populate the array
for ( my $i = 0; $i < scalar(@$array); $i++ ) {
	$$array[$i] = jstring("$i");
	ok(1);
}

#access it again to make sure we can get what we put in there, and they are in the right place
for ( my $i = 0; $i < scalar(@$array); $i++ ) {
	my $test = $$array[$i];
	if ( "$test" == "$i" ) {
		ok(1);
	}
}
