use strict ;

use blib ;


use Inline Java => <<'END_OF_JAVA_CODE' ;

public class cache {
	public int i = 0 ;

	public cache(){
	}

	public void m1(int j){
		i++ ;
	}

	public void m2(int i){
	}

	public void m3(int i){
	}

	public void m4(int i){
	}

	public void m5(int i){
	}
}   
END_OF_JAVA_CODE


my $c = new cache() ;
for (my $i = 0 ; $i < 10000 ; $i++){
	$c->m1($i) ;
}
print $c->{i} . "\n" ;

