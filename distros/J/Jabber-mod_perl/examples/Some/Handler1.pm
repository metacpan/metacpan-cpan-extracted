package Some::Handler1;
use strict;
use Jabber::mod_perl qw(:constants);


sub handler {


   print STDERR "I am inside ".__PACKAGE__."\n";
   return PASS;

}


1;
