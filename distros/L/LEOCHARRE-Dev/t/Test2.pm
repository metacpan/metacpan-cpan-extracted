package Test2;
use lib './lib';
use LEOCHARRE::DEBUG2 qw(debug DEBUG _debug_test);
use strict;



sub new {
   my $class = shift;   
   my $self ={};
   bless $self, $class;
   return $self;   
}

sub debug_is_on {
   my $self = shift;


   debug("as func\n");
   $self->debug("as method\n");

   
   
   _debug_test("as func\n");   
   $self->_debug_test("as method\n");


   

   DEBUG or return 0;

   $self->DEBUG or return 0;
   
   return 1;
}



sub _show_symbol_table {
  
  require Data::Dumper;
   
  print STDERR " SYMBOL TABLE\n"
   . Data::Dumper::Dumper(\%Test2::);
   print STDERR "\n";


}




1;


