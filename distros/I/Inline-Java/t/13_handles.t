use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test';

use Inline(
	Java => 'DATA',
) ;

use Inline::Java qw(caught) ;


BEGIN {
	# Leave previous server enough time to die...
	sleep(1) ;
	plan(tests => 12) ;
}


my $t = new t13() ;

{
	my $f = File::Spec->catfile("t", "t13.txt") ;
	my $o = t13->getWriter($f) ;
	my $h = new Inline::Java::Handle($o) ;
	for (my $i = 1 ; $i <= 10 ; $i++){
	 	print $h "$i\n" ;
	}
	close($h) ;	
	ok(1) ;

	$o = t13->getReader($f) ;
	$h = new Inline::Java::Handle($o) ;
	for (my $i = 1 ; $i <= 10 ; $i++){
		my $l = <$h> ;
		ok($l, $i) ;
	}
	ok(! defined(<$h>)) ;
}


# It seems that filehandle destruction leaks on certain version
# of Perl. We will change this test to a warning.
if ($t->__get_private()->{proto}->ObjectCount() != 1){
	warn "\nWARNING: Your Perl version ($]) seems to leak tied filehandles. Using\n" .
		"Inline::Java::Handle objects will result in memory leaks both in Perl\n" .
		"and in Java\n" ;
} 


__END__

__Java__


import java.io.* ;

class t13 {
	public t13(){
	}

	public static Reader getReader(String file) throws FileNotFoundException {
		return new FileReader(file) ;
	}

	public static Reader getBufferedReader(String file) throws FileNotFoundException {
		return new BufferedReader(new FileReader(file)) ;
	}

	public static InputStream getInputStream(String file) throws FileNotFoundException {
		return new FileInputStream(file) ;
	}

	public static InputStream getBufferedInputStream(String file) throws FileNotFoundException {
		return new BufferedInputStream(new FileInputStream(file)) ;
	}

	public static Writer getWriter(String file) throws IOException {
		return new FileWriter(file) ;
	}

	public static Writer getBufferedWriter(String file) throws IOException {
		return new BufferedWriter(new FileWriter(file)) ;
	}

	public static OutputStream getOutputStream(String file) throws FileNotFoundException {
		return new FileOutputStream(file) ;
	}

	public static OutputStream getBufferedOutputStream(String file) throws FileNotFoundException {
		return new BufferedOutputStream(new FileOutputStream(file)) ;
	}
}

