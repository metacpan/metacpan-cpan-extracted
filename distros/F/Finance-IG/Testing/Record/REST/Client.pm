package REST::Client; 
use JSON; 
use Digest::MD5 qw(md5 md5_hex md5_base64);
my $datapath; 
our $fdebug=1; 
 
BEGIN { 
  my $rcpath; 
  shift(@INC); # remove local path that was needed to find this file 
  my $thispath=$INC{'REST/Client.pm'}; # /home/mark/igrec/Testing/Record/REST/Client.pm
  $datapath=$thispath; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=$datapath."/Data"; 
  mkdir $datapath; 
  delete $INC{'REST/Client.pm'};    #
  require REST::Client;             # determine path to original module.  
  $rcpath=$INC{'REST/Client.pm'};   # typically /usr/share/perl5/REST/Client.pm
 open(F,$rcpath) or die "Cannot find REST::Client not installed? "; 
 my $code=join("",<F>);
 close F; 
 $code=~s/REST::Client/REST::Cli_orig/gm; 
 $code=~s/return if \$self->can\('setHost'\)/return if \$self->can('ContentFile')/gm; 
 $code=~s/no strict 'refs';/no strict 'refs';no warnings 'redefine';/gm; 
 eval  $code ; 
} 

for my $name (qw/
                 PUT GET POST new _buildAccessors _buildUseragent getUseragent setUseragent 
                 request _prepareURL getHost getTimeout
                 getCert getCa getPkcs12 getFollow getContentFile responseCode
                 responseHeader responseContent setHost
                /
             )
{
  no strict 'refs';
  no warnings 'redefine';
  my $orig = \&{"REST::Cli_orig::$name"};
  my $before= \&{"REST::Client::before_$name"}; 
  my $after= \&{"REST::Client::after_$name"}; 
  my $responseContent = \&{"REST::Cli_orig::responseContent"};
  my $responseHeader = \&{"REST::Cli_orig::responseHeader"};
 
  *{"REST::Client::$name"} = 
    sub { 
           my $self=$_[0]; 
           defined(&$before) and &$before(@_);
           my @return_values = wantarray ? $orig->(@_) : scalar $orig->(@_);
 
           if (defined(&$after))
           { 
              my $headers={}; 
              for my $header (&{"REST::Cli_orig::responseHeaders"})
              {
               #print "retrieving header named $header\n"; 
               my $value=''; 
               
               $value=$self->responseHeader($header);  
               #print "$header=$value\n";  
               $headers->{$header}=$value; 
              } 
              &$after($self, 
                      \@_,
                      JSON->new->canonical->encode(
                                   { content=>decode_json($self->responseContent) , 
                                     headers=>$headers
                                   }
                                  )
                     ); 
           }  
           return wantarray ? @return_values : $return_values[0];
        };
}

#sub before_POST
#{
#   print "b4 post @_\n"; 
#   die; 
#}
sub after_POST
{ 
  my ($self,$rparams,$content)=@_; 
  local $"=', '; 
  #die "@$rparams"; 
  my ($url,$jdata,$headers)=@$rparams; 
  #my $jheaders=encode_json($headers);  
  print "headers#1=$headers\n";
  my $jheaders=JSON->new->canonical->encode($headers);  
  # print "After POST url=$url jdata=$jdata  jheaders=$jheaders, content=\n". encode_json($content)."\n";
  #### $content=JSON->new->canonical->encode(decode_json($content)->{$content}); 
  $content=~s/("currentAccountId":)("[^"]+")/$1"REDACTED1"/g; 
  $content=~s/("clientId":)("[^"]+")/$1"REDACTED2"/g; 
  $content=~s/("accountId":)("[^"]+")/$1"REDACTED3"/g; 
  #$content=~s/\xfffd/£/gms; 
  $content=~s/\xA3/£/gms; 
  $content=~s/("X-SECURITY-TOKEN":)("[^"]+)"/$1"."/g;
  $content=~s/("CST":)("[^"]+)"/$1"."/g;

  $jdata=~s/("identifier":)("[^"]+")/$1"igusername"/g; 
  $jdata=~s/("password":)("[^"]+")/$1"ig_correct_password"/g; 
  $jheaders=~s/("X-IG-API-KEY":)("[^"]+)"/$1"securitykey"/g;
  $jheaders=~s/("X-SECURITY-TOKEN":)("[^"]+)"/$1"."/g;
  $jheaders=~s/("CST":)("[^"]+)"/$1"."/g;
  # print "After POST url=$url jdata=$jdata  jheaders=$jheaders, content=\n". $content."\n"; 
 
  $fdebug and print " url=$url\n jdata=$jdata\n jheaders=$jheaders\n"; 
  my $file="$datapath/".md5_hex($url,$jdata,$jheaders).".txt"; 
  $fdebug and print "writing file $file\n"; 
  open(F,">",$file) or die "Cannot open file $file for write"; 
  print F $content."\n"; ; 
  close F; 
} 
sub after_GET
{ 
  my ($self,$rparams,$content)=@_; 
  print "AFTER GET $$rparams[1]\n"; 
  print "rparams=@$rparams\n"; 
  my ($url,$headers)=@$rparams; 
#  my $jheaders=JSON->new->canonical->encode($headers); 
  
  print "AFTER GET url=$url jdata=$jdata jheaders=$jheaders\n"; 
  after_POST($self,[$url,$jdata,$headers] ,$content); 
} 
1; 

