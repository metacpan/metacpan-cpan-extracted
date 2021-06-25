use strict; 

use FindBin;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Test::Simple tests=>10; 

my $tester=$FindBin::RealBin."/../Testing/trans_test.pl"; 

# $^X is current version of perl , path to. 

my $lc=0; 
open(F,"$^X $tester |") or die "unable to run $^X".$FindBin::RealBin. "/../Testing/test.pl"; 
my @lines; 
while (<F>)
{ 
   $lc++; 
   chomp; 
   push(@lines,$_); 
} 

# These counts are very specific things for my trading in this period. But they do check to a degree that 
# the correct records were returned. 
# This is considered a better test than just doing an md5 of the results. 
my $count=grep { m#Long Interest for US/Can share# } @lines; 
ok($count==232, "Transaction results, Long Interest count"); 
$count=grep { m#DEAL# } @lines; 
ok($count==270,"TRansaction results, DEAL"); 
$count=grep { m#Long Interest for# and !m#US/Can share# } @lines; 
ok($count==149,"Long Interest"); 
$count=grep { m#Adjustment for dividend in# } @lines; 
ok($count==21,"Adjustment for Dividend"); 
$count=grep { m#Short Interest for US/Can# } @lines; 
ok($count==17,"Short Interest for US/Can"); 
$count=grep { m#Stock Borrowing for US/Can# } @lines; 
ok($count==17,"Stock Borrowing for US/Can"); 
$count=grep { m#Adjustment for dividend# } @lines; 
ok($count==29,"Adjustment for dividend"); 
$count=grep { m#Card payment# } @lines; 
ok($count==12,"Card payment"); 
$count=grep { m#Funds Transfer from CFD# } @lines; 
ok($count==1,"Funds Transfer from CFD"); 
ok($lc==728, "Output line count is correct"); 
 
