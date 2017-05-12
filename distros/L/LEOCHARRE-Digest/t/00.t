use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();


use LEOCHARRE::Digest ':all';

my @abs = qw(./t/00.t);
my @abs_fake = qw(./t/0awer0.t);


ok_part('pass..');

for my $f (@abs){
   warn("\n# TESTING '$f'\n");
   my $r = md5_cli($f);
   ok($r, "md5_cli()");
   warn("# '$r' : $f\n");
}



ok_part('fails..');
for my $f (@abs_fake){
   warn("\n# TESTING fake '$f'\n");
   my $r = md5_cli($f);
   ok(!$r, "md5_cli()");
}












sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



