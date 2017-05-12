use Test::Simple 'no_plan';

use strict;

use lib './lib';

use Devel::Symdump;
use Getopt::Std;
use vars qw($_part $cwd);


my $x = Devel::Symdump->new('main');


GROUP: for my $group ( qw/packages scalars arrays hashes functions filehandles dirhandles ios unknowns/){

   my @got = $x->$group or next GROUP;
   print STDERR "$group\n";
   map { print " $_\n" } @got;
   print STDERR "\n";

}

ok(1);

   

ok_part("Main lookup..\n");
no strict 'refs';
while ( my($k, $v) = each %{'main::'} ){
   print STDERR " - $k : $v\n";
}

ok_part('simpler');

map { print STDERR "   - - $_\n" } grep { /opt/ } keys %main::;












sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


