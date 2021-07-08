package Finance::IG::REST::Client; 
use JSON; 
use Digest::MD5 qw(md5 md5_hex md5_base64);
my $datapath; 
my $content; 

use vars '$AUTOLOAD';

my $fdebug=0; # print debug infor relating to files etc. 


=encoding utf8

=head1 NAME

Finance::IG::REST::Client - Module to mock REST::Client when testing Finance::IG

=head1 DESCRIPTION

This module mocks REST::CLient. Rather than sending request via the internet a series of files with names derived from a hash of 
url and parameters are retrieved and contain the expected respons. 

The module is intended to be used with use Package::Alias, see below. 

The files can be generated with the module in Testing::Record::REST::Client, but you will need an IG account to run
generate files as you will need to really access the IG site. 

=head1 VERSION 

Version 0.093

=cut

our $VERSION=0.093; 

=head1 SYNOPSIS


    use Package::Alias 'REST::Client'=>'Finance::IG::REST::Client' ; 
    use REST::Client; 

Or     
    use Package::Alias 'REST::Client'=>'Finance::IG::REST::Client' ; 
    use Some::Other::Module::That::UsesREST::Client' 

    calls to Some::Other... # All use the mocked REST::Client; 

=head1 SUBROUTINES/METHODS

This is a list of the implemented methods. We only implement those needed for testing Finance::IG

=head2 new 

No parameters, returns a blessed reference to the item 

=cut 


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

=head2 whoami 

This function is not implemented in the original REST::Client. It returns a string 

        This is Finance::IG::REST::Client 

so that you may know you have succesfully instantiated the right module. 

=cut

sub whoami
{ 
  return "This is Finance::IG::REST::Client"; 
} 

BEGIN { 
  my $rcpath; 
  my $thispath=$INC{'Finance/IG/REST/Client.pm'}; 
  $datapath=$thispath; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 

  $datapath=$datapath."/Data"; 
#  mkdir $datapath; 
} 

#=pod 
#
#for my $name (qw/
#                 PUT _buildAccessors _buildUseragent getUseragent setUseragent 
#                 request _prepareURL getHost getTimeout
#                 getCert getCa getPkcs12 getFollow getContentFile responseCode
#                 responseHeader responseContent setHost
#                /
#             )
#{
#  no strict 'refs';
#  no warnings 'redefine';
# 
#  *{"Finance::IG::REST::Client::$name"} = sub {}; 
#} 
#
#=cut

sub new
{ 
  return bless {}; 
} 

=head2 POST 

Mocks the REST::CLient POST function 

=cut

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
 
=head2 responseCode

returns the success response code (200) 

=cut 

sub responseCode
{
  return 200; 
} 

=head2 responseContent

returns the mocked content of the response

=cut 

sub responseContent
{
  $content=~s/,"headers":\{[^}]+\}\}//; 
  $content=~s/\{"content"://; 
  return $content; 
}

=head2 XSECURITYTOKEN

=cut 

sub XSECURITYTOKEN
{ 
   die $content; 
} 

=head2 responseHeader

returns the mocked response header. 

=cut 

sub responseHeader
{
   my ($self,$header)=@_; 
   my $c=decode_json($content); 
   my $headers=$c->{headers}; 
   return $headers->{$header}; 
} 

=head2 CST 

Dummy function. 

=cut 

sub CST
{
}

=head2 GET 

Dummy function, calls POST

=cut 

sub GET
{
  my ($self,$url,$headers)=@_; 
  POST($self,$url,undef,$headers); 
}
1; 

