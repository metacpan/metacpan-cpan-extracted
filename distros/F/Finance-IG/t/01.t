use strict; 

use FindBin;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Test::More tests=>5; 

my $tester=$FindBin::RealBin."/../Testing/test.pl"; 

# $^X is current version of perl , path to. 
open(F,"$^X $tester -h  |") or die "unable to run $^X ".$FindBin::RealBin. "/../Testing/test.pl"; 
my $lc=0; 
while (<F>)
{ 
   $lc++; 
}  
close F; 
ok($?>>8==1,"-h command exits status 1"); 
ok($lc>10,"-h command produces at least 10 lines of output"); 

$lc=0; 
open(F,"$^X $tester |") or die "unable to run $^X".$FindBin::RealBin. "/../Testing/test.pl"; 
my $md5=Digest::MD5->new;
my @lines; 
while (<F>)
{
   s/\s+/ /g; # remove all multiple spaces 
   $lc++; 
   chomp; 
   if ($lc==1) 
   { 
      s/ +$//; 
      ok($_ eq '66 Positions', "First summary line is correct ($_)"); 
   } 
   $md5->add($_);  
   push(@lines,$_); 
}  
close F;
my $h=$md5->hexdigest(); 
#my $expected='2c26fac8eddd5e1f904510668e803450'; 
my $expected='c6a5bf718740ff06ca4314909783eae5'; 
if ($h ne $expected)  # so when this test fails, we need to debug it. Print out the  md5'ed output to stdout 
{ 
   diag "Checksummed text that failed:\n";  
   for my $line (@lines)
   { 
      diag  "    ".$line."\n"; 
   } 
}
#ok(1); 
cmp_ok($h, 'eq', $expected, "md5 of output agrees". ($expected eq $h? '':sprintf("(is %s)",$h)).'.') ; 
ok($lc==70, "Output line count is correct"); 
 
