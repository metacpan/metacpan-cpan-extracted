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
NAME => "<PKG>"
) ;

my $a = new <PKG::>a() ;
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
NAME => "<PKG>"
) ;

my $b = new <PKG::>b() ;
print $b->get() . "\n" ;
ETESTS



my $nb = scalar(@tests) ;

my $cp = "[PERL_INLINE_JAVA=" . join(", ", map{"Test$_"} (0..$nb-1)) . "]" ;
$ENV{CLASSPATH} = $cp ;

my $cnt = 0 ;
foreach my $t (@tests){
	# `rm -Rf ./_Inline_test/*` ;

	# Insert the package name and replace the macros
	my $pkg = "Test$cnt" ;
	$t = "package $pkg ;\n" . $t ;
	$t =~ s/<PKG(|::)>/$pkg$1/g ;

	eval $t ;
	if ($@){
		die $@ ;
	}
	
	$cnt++ ;
}

