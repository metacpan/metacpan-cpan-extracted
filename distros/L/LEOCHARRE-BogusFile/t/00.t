use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();


use LEOCHARRE::BogusFile ':all';


my %f = qw(
   ./t/aa.tmp  100
   ./t/bb.tmp  1000
   ./t/cc.tmp  12000 
   ./t/dd.tmp  12k
   ./t/cc.tmp  0
);

while (my($r,$s) = each %f){
   unlink $r;
   my $z = make_bogus_file($r,$s);
   ok( $z, 'make_bogus_file()');
   warn("# $z, $r $s\n\n");
   
}
   
ok_part('resolving sizeargs..');

for my $s(qw/12k 1.23M 100 1M 5M 256k/){
   warn("# resolving arg: $s..\n");
   my $_s = arg2bytes($s);
   ok( $_s, 'arg2bytes()');
   ok( eval{ arg2bytes($s) } );
   warn("# got $_s\n\n");
}
   
for my $bad ( qw/asjdfh 238jr23/){

   ok( ! eval{ arg2bytes($bad) } );
}











sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



