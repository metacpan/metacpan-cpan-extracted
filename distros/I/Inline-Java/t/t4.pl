use strict ;

use blib ;

my @tests = split(/;;;;;/,<<'ETESTS');
Inline->bind(Java => <<'JAVA',
class a {
  public a(){
  }
  public int get(){
    return 5 ;
  }
}
JAVA
NAME => "a"
) ;

my $a = new a() ;
print $a->get() . "\n" ;
;;;;;
Inline->bind(Java => <<'JAVA',
class b {
  public b(){
  }
  public int get(){
    return 6 ;
  }
}
JAVA
NAME => "a"
) ;

my $b = new b() ;
print $b->get() . "\n" ;
ETESTS

foreach my $t (@tests){
	# `rm -Rf ./_Inline_test/*` ;

	eval $t ;
	if ($@){
		die $@ ;
	}
}

