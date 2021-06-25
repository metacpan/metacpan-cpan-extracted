#!/usr/bin/perl 
#######################################################################################
# 
# This is tthe program that records the potted responses that are used in testing. 
# You need a real account to use this, with working password. 
# 
# The REST::Client used writes the responses to file in Data with a name based on hash of 
# request parameters. It also sends the request off just like a regular REST::Client. 
# So bear in mind there are 3 types of REST::Client on view here. 
# The original and canonical one, the mock version at Finance::IG::REST::Client and the recording version that 
# is at Finance::IG::Record::REST::Client and calls the original one as well as skuttling away 
# the special files used when the mock version is used. 
# For the mock version, the wonderful Package::Alias is used to rename the module so that we use the mock 
# instead of the real version. 
# For the Recorder, rather more earthy techniques have to be imployed, its a horrible hack, but we need to generate those
# files to make the test data for testing the Finance::IG module. 
# This program has more functionality than needed (option parsing) because it was based on a command line utility. 
#######################################################################################

use FindBin;
use lib $FindBin::RealBin."/../lib/Finance/IG/Record";

use Finance::IG; 
use Getopt::Std; 
use Time::Piece; 
use strict; 
no strict 'refs';
use warnings; 

my $ig; 

use lib $FindBin::RealBin."/../..";

# This file needs a valid account to do anything useful. 
# This will be your account, not mine! 
# You can hardcode here or use a credential fiie. 
# Running this script will allow you to generate 
# new canned test data for new test scripts. 
if ( eval (require "credentials.pl") ) 
{
  $ig=Finance::IG->new(cred()); 
} 
else
{ 
  $ig=Finance::IG->new(
                username=> "igusername", 
                password=> "ig_correct_password", 
                apikey=>   "securitykey", 
                isdemo=>0, 
  );
}  

my %opt; 
my $sortlist; 

my $valid=getopts('ho:tf:ng:s:S', \%opt);  

# t display headers every 10 lines 
# n no headers 
# f n : use format number 
# h help
# g grep  
# S print NO summary line 
# s sort list 
# sort list can be 
# a comma seperated list of fields each with an optional minus sign eg 
#   -s'-profitpc,instrumentName'   sorts by profit highest first, and if the same, then orders by name 
#   Here the following can be used as abbreviations 
#  n instrumentName
#  o open => level
#  b bid 
#  v value => atRisk 
#  p profitpe
# if no commas 
#  or a comma seperated list of elements, each of which may be optionally started with - for reverse sort
#  the above abbrevs may be used. default is -p,n or -profitpc,instrumentName or -pn 

if (exists $opt{s} and defined $opt{s}) 
{ 
   my @list; 
   if ($opt{s}=~m/^[-nobvp]+$/)
   {
     @list=split(//,$opt{s}); 
   } 
   else
   { 
     @list=split(/,/,$opt{s}); 
     @list=map { s/^-//?('-',$_):$_ } @list; 
   } 
   for (@list)
   { 
       $_='instrumentName' if ($_ eq 'n');  
       $_='level'          if ($_ eq 'o');  
       $_='bid'            if ($_ eq 'b');  
       $_='atrisk'         if ($_ eq 'v');  
       $_='profitpc'       if ($_ eq 'p');  
   } 
   map { ($list[$_] eq '-') and  $list[$_+1]='-'.$list[$_+1]; } (0..$#list); 
   @list=grep { $_ ne '-' } @list; 
   $sortlist=\@list; 
}

if (exists $opt{g} and !$opt{t})
{ 
  $opt{S}=1; 
  $opt{n}=!$opt{n}; 
} 

my $out; 
$out=*STDOUT; 
if ($opt{o})
{
  # output file supplied
 
  my $d="Testing"; 
  my $f=$d."/".$opt{o};  

  open($out,">$f") or die "failed to open $f"; 
  
} 

!$valid and help("Invalid arguments");  
$opt{h} and help(); 

$ig->login(); 

my $p=$ig->positions(); 
$p=$ig->agg($p,$sortlist); 

printf $out "%d Positions\n",@$p+0 if (!$opt{S}); 

my @format=(
           "%-41sinstrumentName %+6.2fsize %-9.2flevel ".
           "%-9.2fbid £%-8.2fprofit %5.1fprofitpc%% £%10.2fatrisk\n", 
     
           "%sepic|%sinstrumentName|%0.2fsize|%-0.2flevel|".
           "%-0.2fbid|£%-0.2fprofit|%0.1fprofitpc%%|£%0.2fatrisk\n", 
 
           "%sepic|%sinstrumentName|%0.2fsize|%-0.2flevel|".
           "%-0.2fbid|£%-0.2fprofit|%0.1fprofitpc%%|£%0.2fatrisk|%smarketStatus\n", 
          ); 

my $format=$format[0]; 
if (defined($opt{f}))
{ 
   die "option fn out of range (0..".(@format+0).")"  if ($opt{f}<1 || $opt{f}>@format+0); 
   $format=$format[$opt{f}-1]; 
   #if ($opt{f}>1) 
   #{ 
   #  $ig->uds(''); 
   #  $demo->uds(''); 
   #} 
} 

my $titles; 
## $titles=["Epic", 'Name','Size','Open','Latest','P/L','P/L','Value']; 
$titles=undef; 

my $value=0;
my $profit=0;  
my $count=0; 

for my $position (@$p)
{ 
  # $ig-> printpos($out,$position,$format,-0.5,+0.5); 
  $ig->printpos($out , $titles, $format)
                                    if (!$opt{n} and ($count==0 or  ( $opt{t} and ($count+1)%10==0)));
  $count++;
  
  $ig-> printpos($out,$position,$format)
      if (!$opt{g} or $position->{instrumentName}=~m/$opt{g}/i); 

  $value+=$position->{bid}*$position->{size}; 
  $profit+=$position->{profit}; 
} 

$ig->printpos($out , $titles, $format) if (!$opt{n});  

my $capital=62000+20000+10000+10000+2000+10000+10000+10000+5000; 

my $accounts=$ig->accounts(); 
# my ($account)=grep { $_->{accountId} eq "..." } @$accounts; 
my ($account)=grep { $_->{accountType} eq "SPREADBET" } @$accounts; 

my $balance=$account->{balance}->{balance}; 
my $margin=$account->{balance}->{balance}+$account->{balance}->{profitLoss}-$account->{balance}->{available}; 
my $available=$account->{balance}->{available};

my $pc=int(1000*($profit+$balance-$capital)/$capital)/10; 
my $ppc=int(1000*$profit/$value)/10; 
print "# Total value $value balance=£$balance profit on open trades=£$profit as % of value $ppc% capital=$capital margin/av=£$margin/£$available profit/capital=$pc%\n" if (!$opt{S}); 


sub help
{ my ($mess)=@_; 
# -o auto-generate a time based file and use this to send output to 
# t display headers every 10 lines 
# n no headers 
# f n : use format number 
# h help
# g grep  
# s print NO summary line 
   print $out "$mess\n" if ($mess);  
   print $out "

This is the test program for IG.pm. Its tested via modification of a standard display program

-o filename  store output in Testing/filenme
-f n use one of the inbuilt formats 1 or 2 
-h this message and exit
-n xxx use xxx as a pattern in name to grep for particular positions
-S print no summary line. 
-N toggle printing of headers. 
-t print title lines every 10 lines. 
-s x Sort output by x where x is a comma seperated list of fields
   optionaly preceded by a minus (for reverse sort). Common fields
   can be abrievated by the following single letter abbreviations, 
     n instrumentName
     o level (opening price for position)
     b bid 
     v atRisk (value atRisk in a position) 
     p profitpe (percentage profit. ) 
   The default could be written in any of the following ways:   
     -s-profitpc,instrumentName or -s-pn or -s-p,n
   It sorts by decending order of profit and where this is the 
   same, orders by name. 
-O [+-=]date[time] Show only positions held Opened later or equal  (+) equal to (-) 
   or earlier or equal (-) than the given date or datetime, eg 
   -O 2020/11/05 or -O 2020/11/05T15:00:00
   Equal to means with ref to the format so that 
   2020/11/05 means the days are equal while 2020/11 means amy time that month 
"; 
 exit(1); 
} 
