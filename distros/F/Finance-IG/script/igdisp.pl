#!/usr/bin/perl 
use FindBin;
use lib $FindBin::RealBin."/../lib";

use Finance::IG; 
use Getopt::Std; 
use Time::Piece; 
use strict; 
no strict 'refs';
use warnings; 


my %opt; 
getopts('otf:Nhn:s:SO:g:', \%opt) or die("Aborted!"); 

my $ig; 

# IG Credentials needed. 
# You can add them to enviroment variables as bellow or 
# directly hardcode them below. 
# It can be useful to have a demo account to, this should be a seperate instance of the 
# object. 

$ig=Finance::IG->new(
                username=> $ENV{IGUSER}, 
                password=> $ENV{IGPASS}, 
                apikey=>   $ENV{IGAPIKEY}, 
                isdemo=>0, 
); 

die "missing credentials username, try setting the environment variable IGUSER" if ($ig->username eq ''); 
die "missing credentials password, try setting the environment variable IGPASS" if ($ig->username eq ''); 
die "missing credentials apikey, try setting the environment variable IGAPIKEY" if ($ig->username eq ''); 
my $sortlist; 

# -o auto-generate a time based file and use this to send output to 
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

my $gel; 
my $maskint; 
if ($opt{O})
{ 
   $gel=1; # default is date must be greater than specified. 
   if ($opt{O}=~s/^([-\+=><])//) 
   { 
     $gel=-1 if ($1 eq '-' or $1 eq '<'); 
     $gel=1  if ($1 eq '+' or $1 eq '>'); 
     $gel=0  if ($1 eq '='); 
   } 
   $opt{O}=~s#/#-#g; 

   my $warning; 
   my $tt; 
   {
        local $SIG{__WARN__} = sub {$warning = shift};
        $tt=Time::Piece->strptime($opt{O},"%Y-%m-%dT%H:%M:%S")  or die "strptime failed for -O $opt{O} "  ; 
   } 
   $tt or die "#2strptime failed for -O $opt{O} "; 
   my @a=split(/[-:T]/,$opt{O}); # how many elements were parsed? 
   # we expect that for <, =, or > it always means or equal to, and we need to mask the comparison. 
   # so that if all before a day was given we expect to mask the hrs min and sec and then do <= to 
   # likewise if = is specified, gel==0, then we expect to mask the result and then do -- 
   # likewise uf > is specified we implement >= on the masked value.  
   # to mask a Time::Piece object, we subtract the curent minor units, eg to mask sec and mins $t=$t-$t->sec-$t->min*60; 
   # Easy way to mask is to change the format string used to convert the data
   $maskint=@a; # so 6 means all supplied, 3 means format string truncated to %Y-%m-%d etc 
   $opt{O}=$tt; 
} 

$opt{h} and help(); 
$opt{g}//=''; 

if (exists $opt{n} and !$opt{t})
{ 
  $opt{S}=1; 
  $opt{N}=!$opt{N}; 
} 

my $f=""; 
my $out="stdout"; 

$ig->login(); 

my $p=$ig->positions(); 
$p=$ig->agg($p,$sortlist); 
# $ig->sorter(['-atrisk'],$p); 

printf "%d Positions\n",@$p+0 if (!$opt{S}); 

if ($opt{o})
{
  # output file auto generated
 
  my $date=Time::Piece->gmtime(); 
  my $d="/home/mark/igrec/r2"; 
  my $f=$date->strftime("$d/%Y-%m-%d-%H.%M.txt"); 

  open($out,">$f") or die "failed to open $f"; 
  
} 

my @format=(
           "%-41sinstrumentName %+6.2fsize %-9.2flevel ".
           "%-9.2fbid £%-8.2fprofit %5.1fprofitpc%% £%10.2fatrisk\n", 
     
           "%sepic|%sinstrumentName|%0.2fsize|%-0.2flevel|".
           "%-0.2fbid|£%-0.2fprofit|%0.1fprofitpc%%|£%0.2fatrisk\n", 
 
           "%sepic|%sinstrumentName|%0.2fsize|%-0.2flevel|".
           "%-0.2fbid|£%-0.2fprofit|%0.1fprofitpc%%|£%0.2fatrisk|%smarketStatus\n", 

           #4  
           "%-41sinstrumentName %screatedDateUTC %+6.2fsize %-9.2flevel ".
           "%-9.2fbid £%-8.2fprofit %5.1fprofitpc%% £%10.2fatrisk\n", 
     
          ); 
my $format; 

if (defined($opt{f}))
{ 
   die "option fn out of range (0..".(@format+0).")"  if ($opt{f}<1 || $opt{f}>@format+0); 
   $format=$format[$opt{f}-1]; 
   if ($opt{f}>1) 
   { 
     $ig->uds(''); 
   } 
} 
else
{ 
    $format=$format[0]; 
} 

my $titles=["Epic", 'Name','Size','Open','Latest','P/L','P/L','Value']; 
$titles=undef; 

#print"\n"; 



my $value=0;
my $profit=0;  
my $count=0; 

for my $position (@$p)
{ 
  # $ig-> printpos($out,$position,$format,-0.5,+0.5); 
  $ig->printpos($out , $titles, $format)
                                    if (!$opt{N} and ($count==0 or  ( $opt{t} and ($count+1)%10==0)));
  $count++;
  $ig-> printpos($out,$position,$format)
      if ((!$opt{n} or $position->{instrumentName}=~m/$opt{n}/i) and 
          (!$opt{O} or datecmp($position->{createdDateUTC},$opt{O},$maskint,$gel)) and 
            ($opt{g}!~m/t/  or  $position->{marketStatus} eq 'TRADEABLE') and
            ($opt{g}!~m/n/  or  $position->{marketStatus} ne 'TRADEABLE') and   # not tradeable 
          1
         )
      ; 

  $value+=$position->{bid}*$position->{size}; 
  $profit+=$position->{profit}; 
} 

$ig->printpos($out , $titles, $format) if (!$opt{N});  

my $capital=10000; # hardcode your capital here! 

my $accounts=$ig->accounts(); 
# my ($account)=grep { $_->{accountId} eq "..." } @$accounts; 
my ($account)=grep { $_->{accountType} eq "SPREADBET" } @$accounts; 

my $balance=$account->{balance}->{balance}; 
my $margin=$account->{balance}->{balance}+$account->{balance}->{profitLoss}-$account->{balance}->{available}; 
my $available=$account->{balance}->{available};

my $pc=int(1000*($profit+$balance-$capital)/$capital)/10; 
my $ppc=int(1000*$profit/$value)/10; 
print "# Total value $value balance=£$balance profit on open trades=£$profit as % of value $ppc% capital=$capital margin/av=£$margin/£$available profit/capital=$pc%\n" if (!$opt{S}); 

sub datecmp
{
  my ($t1,$t2,$maskint,$gel)=@_; 

  my @f=qw(%Y %m %d T%H %M %S); 
  @f=@f[0..$maskint-1]; 
  my $f=join(':',@f); 
  $f=~s/:/-/ for 1 .. 2; 
  $f=~s/://; 
   
  my $warning; 
  {
        local $SIG{__WARN__} = sub {$warning = shift};
        $t1=Time::Piece->strptime($t1,$f) if (ref($t1) ne 'Time::Piece'); 
        $t2=Time::Piece->strptime($t2,$f) if (ref($t2) ne 'Time::Piece'); 
  } 
  return $t1==$t2 if ($gel==0); 
  return $t1<=$t2 if ($gel==-1); 
  return $t1>=$t2; # if ($gel==1); 
} 
sub help
{ my ($mess)=@_; 
# -o auto-generate a time based file and use this to send output to 
# t display headers every 10 lines 
# n no headers 
# f n : use format number 
# h help
# g grep  
# s print NO summary line 
   print "$mess\n" if ($mess);  
   print "
-o Send output to an autogenerated, time based file. 
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
