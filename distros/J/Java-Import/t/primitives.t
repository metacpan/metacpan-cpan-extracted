use Test::Simple tests => 10;

use Java::Import;

my $jstring = jstring("hi there");
if ( "$jstring" eq "hi there" ) {
	ok(1);
} else {
	ok(0);
}

my $jint = Java::Import::jint(1);
if ( "$jint" == 1 ) {
	ok(1);
} else {
	ok(0);
}

my $jboolean = Java::Import::jboolean(1);
if ( "$jboolean" eq "true" ) {
	ok(1);
} else {
	ok(0);
}

$jboolean = Java::Import::jboolean(0);
if ( "$jboolean" eq "false" ) {
	ok(1);
} else {
	ok(0);
}

$jshort = Java::Import::jshort(10);
if ( "$jshort" == 10 ) {
	ok(1);
} else {
	ok(0);
}

$jlong = Java::Import::jlong(100000000);
if ( "$jlong" == 100000000 ) {
	ok(1);
} else {
	ok(0);
}

$jfloat = Java::Import::jfloat(3.1234);
if ( "$jfloat" == 3.1234 ) {
	ok(1);
} else {
	ok(0);
}

$jdouble = Java::Import::jdouble(3.1234);
if ( "$jdouble" == 3.1234 ) {
	ok(1);
} else { 
	ok(0);
}

$jchar = Java::Import::jchar('a');
if ( "$jchar" eq 'a' ) {
	ok(1);
} else {
	ok(0);
}

$jbyte = Java::Import::jbyte('a');
if ( "$jbyte" == 97 ) {
	ok(1);
} else {
	ok(0);
}
