# So this package  was used to generate the hashed response files for testing. 
# It cannot be uploaded to cpan named REST::Client as I do not own that name space. 
# You could rename it as below to use. 
# A better approach is likely to use the true name below, and reloacte in the correct place and use Package::Alias
# to call as is now done with Finance::IG::REST::Client. 
# The action in this package is under the hood, it calls the true REST::CLient and records the 
# rsults in files that can later be used stand alone with no internet. 
# So this is a bit broken right now, but only needed if you want to expand the tests for Finance::IG. 
# Could do with some tests of its own! 
package REST::Client; 
use strict; 
no strict 'refs'; 
use warnings; 
no warnings 'redefine'; 

use JSON; 
use Digest::MD5 qw(md5 md5_hex md5_base64);
my $datapath; 
our $fdebug=0; # set to 1 prints some diagnostics about whats going on 

=encoding utf8

=head1 NAME 

Finance::IG::Record::REST::Client, or more generally REST::Client

=head1 Description. 

The aim of this module is to generate files used by the module Finance::IG::REST::Client which is a module that
mocks REST::Client by using pre-canned on disk responses to queries rather than the internet. 

THIS module is designedd to emulate REST::Client in providing data sourced from the internet, but also cans the
exchange for latter use by the mock version of REST::Client

=head1 DESIGN

There are a number of design issues that need to be handled, in particular interjecting this module as well as having the real module loaded. 

The latter is achieved by locating the real module, reading the file, changing the name to REST::Cli_orig, and then using an eval to load it. 

Its an important design decision that the unmodified Finance::IG.pm module is fitted up to use the this module or Finance::IG::REST::Client 
entirely by manipulating %INC. 

=head1 VERSION 

Version 0.093

=head1 SYNOPSIS

See the included file Testing/test-record.pl 

=cut
 
our $VERSION=0.093; 

BEGIN { 
  my $rcpath; 
  shift(@INC); # remove local path that was needed to find this file 
  my $thispath=$INC{'REST/Client.pm'}; 
  $datapath=$thispath;                
  # die "datapath=$datapath";            # /home/mark/igrec/work/Finance-IG/Testing/../lib/Finance/IG/Record/REST/Client.pm
  $datapath=~s#/[^./]+/\.\.##g;          # /home/mark/igrec/work/Finance-IG/lib/Finance/IG/Record/REST/Client.pm 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=~s#/[^/]+$##; 
  $datapath=$datapath."/Testing/Data"; 
  # die "datapath=$datapath";             # /home/mark/igrec/work/Finance-IG/Testing/Data
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

# Doesn't seem needed with global
#    no warnings 'redefine'; 
# Subroutine REST::Client::PUT redefined at ...  
#$SIG{__WARN__} = sub
#{
#    my $warning = shift;
#    my $m; 
#    warn $warning unless $warning =~ /Subroutine .* redefined at \(eval [0-9]+\)/;
#    # Subroutine _buildUseragent redefined at (eval 179) line 491.
#};

for my $name (qw/
                 PUT GET POST new _buildAccessors _buildUseragent getUseragent setUseragent 
                 request _prepareURL getHost getTimeout
                 getCert getCa getPkcs12 getFollow getContentFile responseCode
                 responseHeader responseContent setHost
                /
             )
{
  no strict 'refs';
#  no warnings 'redefine'; # did work but doesn't now. ? 

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


# delete $SIG{__WARN__};  # This causes reinstatement of the warnings. 

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
  #print "headers#1=$headers\n";
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
  #print "AFTER GET $$rparams[1]\n"; 
  #print "rparams=@$rparams\n"; 
  #my ($url,$headers)=@$rparams; 
  my ($url,$jdata,$headers)=@$rparams; 
#  my $jheaders=JSON->new->canonical->encode($headers); 
  
  #print "AFTER GET url=$url jdata=$jdata jheaders=$jheaders\n"; 
  after_POST($self,[$url,$jdata,$headers] ,$content); 
} 
1; 

