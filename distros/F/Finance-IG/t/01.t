use strict; 

use FindBin;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Test::Simple tests=>5; 

my $tester=$FindBin::RealBin."/../Testing/test.pl"; 

open(F,"$tester -h  |") or die "unable to run ".$FindBin::RealBin. "/../Testing/test.pl"; 
my $lc=0; 
while (<F>)
{ 
   $lc++; 
}  
close F; 
ok($?>>8==1,"-h command exits status 1"); 
ok($lc>10,"-h command produces at least 10 lines of output"); 

$lc=0; 
open(F,"$tester |") or die "unable to run ".$FindBin::RealBin. "/../Testing/test.pl"; 
my $md5=Digest::MD5->new;
while (<F>)
{ 
   $lc++; 
   $md5->add($_);  
   if ($lc==1) 
   { 
      chomp; 
      ok($_ eq '66 Positions', "First summary line is correct"); 
   } 
   
}  
close F;
ok($md5->hexdigest() eq '2c26fac8eddd5e1f904510668e803450', "md5 of output agrees"); 
ok($lc==70, "Output line count is correct"); 
 
