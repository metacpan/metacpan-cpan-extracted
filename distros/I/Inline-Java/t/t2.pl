use strict ;

use blib ;

BEGIN {
	$Inline::Java::DEBUG = 1 ;
}


package Foo ;

use Inline (
	Java => <<'END',
class Foo {
   String data = "data" ;

   public Foo() {
      System.out.println("new Foo object being created") ;
   }

   public String get_data(){
      return data ;
   }

   public void set_data(String d){
      data = d ;
   }

   public class Fighters {
      public Fighters() {
      }
   }
}
END
	FORCE_BUILD => 1,
	NAME => "Foo") ;


package Bar ;

use Inline (
	Java => <<'END',
class Bar extends Foo {
   String data = "data" ;

   public Bar(Foo f) {
      System.out.println("new Bar object being created") ;
   }

   public String get_data(){
      return data ;
   }

   public void set_data(String d){
      data = d ;
   }
}
END
	FORCE_BUILD => 1,
	NAME => "Bar") ;


my $f = new Foo::Foo() ;
my $b = new Bar::Bar($f) ;

