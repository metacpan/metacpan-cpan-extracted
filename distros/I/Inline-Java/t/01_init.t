use strict ;
use Test ;

BEGIN {
	$main::cp = $ENV{CLASSPATH} || "<empty>" ;
	plan(tests => 1) ;
	mkdir('./_Inline_test', 0777) unless -e './_Inline_test' ;
}

use Inline Config => 
           DIRECTORY => './_Inline_test' ;

use Inline (
	Java => 'DATA'
) ;

my $ij = $types1::INLINE ;
$ij = $types1::INLINE ; # Stupid warning...
my $jdk = $ij->get_java_config("J2SDK") ;
my $ver = types1->version() ;

print STDERR "\nPerl version is $]\n" ;
print STDERR "Inline version is $Inline::VERSION\n" ;
print STDERR "Inline::Java version is $Inline::Java::VERSION\n" ;

print STDERR "J2SDK version is $ver, from $jdk\n" ;
print STDERR "CLASSPATH is $main::cp\n" ;

if ($ENV{PERL_INLINE_JAVA_EMBEDDED_JNI}){
	print STDERR "Using JNI extension (embedded).\n" ;
}
elsif ($ENV{PERL_INLINE_JAVA_JNI}){
	print STDERR "Using JNI extension.\n" ;
}

ok(1) ;



__END__

__Java__

class types1 {
	static public String version(){
		return System.getProperty("java.version") ;
	}
}



