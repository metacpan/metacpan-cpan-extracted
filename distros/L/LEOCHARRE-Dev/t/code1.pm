package code1;
use strict;

sub _private {
   my $somecodehere = 1;
   _haha();
   _haha();
   _haha();
   return $somecodehere;   
}



sub public_suba {
   print "I am public";
   public_sub2();
}

sub public_subb {
   print "I am also public";
}



sub public_subc {
   print "I am also public";
}




sub _haha {
   print "yup";
   return;
}


1;
