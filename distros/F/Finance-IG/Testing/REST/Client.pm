package REST::Client; 
use JSON; 
use Digest::MD5 qw(md5 md5_hex md5_base64);
my $datapath; 
my $content; 

use vars '$AUTOLOAD';

my $fdebug=0; # print debug infor relating to files etc. 

sub AUTOLOAD
{
   $AUTOLOAD =~ s/.*:://; 

    for my $name (qw/
                 GET PUT _buildAccessors _buildUseragent getUseragent setUseragent 
                 request _prepareURL getHost getTimeout
                 getCert getCa getPkcs12 getFollow getContentFile responseCode
                 responseHeader responseContent setHost
                 /)
    { 
       if ($AUTOLOAD eq $name)
       {
         return 1; 
       } 
    }

   shift->${\"NEXT::$AUTOLOAD"}(@_); 
}

BEGIN { 
  my $rcpath; 
  my $thispath=$INC{'REST/Client.pm'}; # /home/mark/igrec/Testing/REST/Client.pm
  $datapath=$thispath; 
  #$datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=$datapath."/Data"; 
#  mkdir $datapath; 
} 
=pod 

for my $name (qw/
                 PUT _buildAccessors _buildUseragent getUseragent setUseragent 
                 request _prepareURL getHost getTimeout
                 getCert getCa getPkcs12 getFollow getContentFile responseCode
                 responseHeader responseContent setHost
                /
             )
{
  no strict 'refs';
  no warnings 'redefine';
  #my $orig = \&{"REST::Cli_orig::$name"};
  #my $before= \&{"REST::Client::before_$name"}; 
  #my $after= \&{"REST::Client::after_$name"}; 
  #my $responseContent = \&{"REST::Cli_orig::responseContent"};
 
  *{"REST::Client::$name"} = sub {}; 
} 
=cut

sub new
{ 
  return bless {}; 
} 

sub POST{ 
  my ($self,$url,$jdata,$headers)=@_; 
  local $"=', '; 

  my $jheaders=JSON->new->canonical->encode($headers);  
  if ($jdata)
  { 
    $jdata=~s/("identifier":)("[^"]+")/$1"igusername"/g; 
    $jdata=~s/("password":)("[^"]+")/$1"ig_correct_password"/g; 
  } 
  $jheaders=~s/("X-IG-API-KEY":)("[^"]+)"/$1"securitykey"/g;
  $jheaders=~s/("X-SECURITY-TOKEN":)("[^"]+)"/$1"."/g;
  $jheaders=~s/("CST":)("[^"]+)"/$1"."/g;

  $fdebug and print " url=$url\n jdata=$jdata\n jheaders=$jheaders\n"; 
   
  my $file="$datapath/".md5_hex($url,$jdata,$jheaders).".txt"; 
  $fdebug and print "Reading $file\n"; 
  open(F,"<",$file) or die "Cannot open file $file for read"; 
  binmode(F); 
  read F, $content, 1000000; 
  close F; 
} 
sub responseCode
{
  return 200; 
} 
sub responseContent
{
  $content=~s/,"headers":\{[^}]+\}\}//; 
  $content=~s/\{"content"://; 
  return $content; 
}
sub XSECURITYTOKEN
{ 
   die $content; 
} 
sub responseHeader
{
   my ($self,$header)=@_; 
   my $c=decode_json($content); 
   my $headers=$c->{headers}; 
   return $headers->{$header}; 
} 
sub CST
{
}
sub GET
{
  my ($self,$url,$headers)=@_; 
  POST($self,$url,undef,$headers); 
}
1; 

