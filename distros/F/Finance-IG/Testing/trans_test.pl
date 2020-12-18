#!/usr/bin/perl 
use FindBin;
use lib $FindBin::RealBin;        # for special REST::Client 
use lib $FindBin::RealBin."/../lib"; # for IG 
#use lib $FindBin::RealBin."/Record"; # for other special REST::Client that records. 
use Time::Piece; 

use Finance::IG; 
use JSON; 

#$INC{'REST/Client.pm'} =~m#Testing/REST/Client.pm# or 
#$INC{'REST/Client.pm'} =~m#Testing/Record/REST/Client.pm# or 
#   die "Using wrong REST::Client ".$INC{'REST/Client.pm'}; 

my $ig; 

# with Testing::Record::REST;;Client need correct data 
$ig=Finance::IG->new(
                username=> "igusername",
                password=> "ig_correct_password",
                apikey=>   "securitykey",
                isdemo=>0,
);

$ig->login(); 

#my $a=$ig->history('2020-10-29T00:00','2020-10-29'); 
# my $a=$ig->history('2020-10-29T00:00',localtime->strftime("%Y-%m-%d")); 

my $a; 
my $page=0; 
my @transactions; 
# while ($a=$ig->transactions(++$page,(scalar localtime)-10*30*24*3600,scalar localtime))
#while ($a=$ig->transactions(++$page,Time::Piece->strptime("2020-01-01","%Y-%m-%d-%H.%M"),scalar localtime))
while ($a=$ig->transactions(++$page,Time::Piece->strptime("2020-01-01","%Y-%m-%d-%H.%M"),'2020-12-11T18:15:00'))
{  
   @$a=grep { $_->{status} ne 'REJECTED' } @$a; 
   push(@transactions,@$a); 

   # print @transactions+0, "\n"; 
} 
   # 2020-07-08T01:06:12
   @transactions=sort { $b->{dateUtc} cmp $a->{dateUtc} } @transactions; 

   for $p1 (@transactions)
   { 
     for my $key (sort keys %$p1) 
     { 
       # print "key $key\n"; 
       if ($key eq 'profitAndLoss')
       { 
         $p1->{$key}=~s/\xA3/£/g; 
         $p1->{$key}=~s/£-/-£/; 
       } 
       if (ref($p1->{$key}) eq 'JSON::PP::Boolean')
       {  
           $p1->{$key}=$p1->{$key}?1:0; 
       }  
       
     } 
   }
my $format="%-25sdateUtc %-25sopenDateUtc %30sinstrumentName %6ssize %10sprofitAndLoss %8stransactionType %sopenLevel %9.2fcloseLevel\n"; 
#my $format="%-25sdateUtc %-25sopenDateUtc %30sinstrumentName %6ssize %10sprofitAndLoss %8stransactionType %9.2fopenLevel %9.2fcloseLevel\n"; 
# my $format="%-20sdate %10sinstrumentName %-60sdescription %4.2fsize %sstatus\n"; 
$ig->printpos("stdout","",$format); 
map { $ig->printpos("stdout",$_,$format);  } @transactions; 
exit; 

# print the following keys in a typical transaction 
#key cashTransaction
#key closeLevel
#key currency
#key date
#key dateUtc
#key instrumentName
#key openDateUtc
#key openLevel
#key period
#key profitAndLoss
#key reference
#key size






if (0) 
{ 
   for $p1 (@transactions)
   { 
     printf "*****\n";  
     # print $p1->{date} ."\n"; 
     for my $key (sort keys %$p1) 
     { 
       next if $key eq 'dealId'; 
       next if $key eq 'epic'; 
       next if $key eq 'currency'; 
       next if (grep { $key eq $_ } (qw/reference limitLevel trailingStopDistance guaranteedStop trailingStep Distance limitDistance stopLevel goodTillDate period dealReference stopDistance/));    
       if ($key eq 'profitAndLoss')
       { 
         $p1->{$key}=~s/\xA3/£/g; 
         $p1->{$key}=~s/£-/-£/; 
       } 
       if (ref($p1->{$key}) eq 'JSON::PP::Boolean')
       {  
           $p1->{$key}=$p1->{$key}?1:0; 
       }  
       
       print "key $key is ".(ref($p1->{$key})?ref($p1->{$key}):$p1->{$key})."\n"; 
     } 
   }
exit; 
} 
my $format="%-20sdate %20sinstrumentName %6ssize %10sprofitAndLoss %8stransactionType \n"; 
# my $format="%-20sdate %10sinstrumentName %-60sdescription %4.2fsize %sstatus\n"; 
$ig->printpos("stdout","",$format); 
map { $ig->printpos("stdout",$_,$format);  } @transactions; 


