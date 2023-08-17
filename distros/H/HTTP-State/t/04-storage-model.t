use strict;
use warnings;
use feature ":all";
##################################
# use Data::Dumper;              #
# use Log::ger::Output "Screen"; #
#                                #
# use Log::OK {                  #
#   lvl=>"info",                 #
#   opt=>"verbose"               #
# };                             #
##################################

use Test::More;
use HTTP::State;
use HTTP::State::Cookie ":all";


# Tests for RFC6265bis Section 5.6 and storage processing steps
{
  
  my $jar=HTTP::State->new;
  my $string="name=value; Secure";
  my $request_host="hello.com.au";
  my $request_scheme="https";
  my $request_path="/path/to/file.pdf";

  my $url="$request_scheme://$request_host$request_path";

  $jar->store_cookies($url, undef,  0xFF, $string);
  my @dump=$jar->dump_cookies;

  #say STDERR " COOKIE VALUE IS: ",join ", ", @dump;
  ok @dump == 1, "Cookie added";

  #Test  default values
  my $c=$dump[0];

  # Default domain should be set to request host
  ok $c=~/Domain=$request_host/, "Default domain set";  

  # Default path set to  'dirname' of path if not ending with a slash
  use File::Basename qw<dirname>;
  my $p=dirname $request_path;

  ok $c=~m|Path=$p|, "Default path set";

  #  Default samesite is none
  ok $c=~m|SameSite=Default|, "Default samesite";

  #  Default persistent is faule. No Max-Age or Expiry 
  ok $c!~m|Persistent|, "Default not persistent";
}

{
  # Reject cookie as domain mismatch  to url
  my $jar=HTTP::State->new;
  my $domain="some.com.au; Secure";
  my $string="name=value; Domain=$domain";
  my $request_host="www.hello.com.au";
  my $request_scheme="https";
  my $request_path="/path/to/file.pdf";

  my $url="$request_scheme://$request_host$request_path";
  $jar->store_cookies($url, undef,  0xFF, $string);
  my @dump=$jar->dump_cookies;

  #say STDERR " COOKIE VALUE IS: ",join ", ", @dump;
  #say STDERR Dumper @dump;
  ok @dump == 0, "Cookie attempt to set wrong domain";

}

{
  # Reject cookie as scheme is not secure but secure attribute is set
  my $jar=HTTP::State->new;
  my $string="name=value; Secure";
  my $request_host="www.hello.com.au";
  my $request_scheme="http";
  my $request_path="/path/to/file.pdf";

  my $url="$request_scheme://$request_host$request_path";
  $jar->store_cookies($url, undef, 0xFF,  $string);
  my @dump=$jar->dump_cookies;

  #say STDERR " COOKIE VALUE IS: ",join ", ", @dump;
  #say STDERR Dumper @dump;
  ok @dump == 0, "Cookie attempt set secure on insecure channel";
}
{
  # Reject cookie as due to same site being None but cookie is non secure
  my $jar=HTTP::State->new;
  my $string="name=value; SameSite=None";
  my $request_host="www.hello.com.au";
  my $request_scheme="http";
  my $request_path="/path/to/file.pdf";

  my $url="$request_scheme://$request_host$request_path";
  $jar->store_cookies($url, undef, 0xFF,  $string);
  my @dump=$jar->dump_cookies;

  #say STDERR " COOKIE VALUE IS: ",join ", ", @dump;
  #say STDERR Dumper @dump;
  ok @dump == 0, "Same site of none attempted on non secure cookie ";
}

{
  #  Add a cookie and then expire
  my $jar=HTTP::State->new;
  my $string="name=value; SameSite=None; Secure";
  my $request_host="www.hello.com.au";
  my $request_scheme="https";
  my $request_path="/path/to/file.pdf";

  my $url="$request_scheme://$request_host$request_path";
  $jar->store_cookies($url, undef, 0xFF,  $string);
  my @dump=$jar->dump_cookies;

  ok @dump == 1,  "Cookie added";
  
  $string="name=value; SameSite=None; Secure; Max-Age=-1";
  $jar->store_cookies($url, undef, 0xFF,  $string);
  @dump=$jar->dump_cookies;

  ok @dump == 0,  "Cookie expired";
}

{
  #  Add a cookie and then update the value
  my $jar=HTTP::State->new;
  my $string="name=value; SameSite=None; Secure";
  my $request_host="www.hello.com.au";
  my $request_scheme="https";
  my $request_path="/path/to/file.pdf";

  my $url="$request_scheme://$request_host$request_path";
  $jar->store_cookies($url, undef,  0xFF, $string);
  my @dump=$jar->dump_cookies;

  ok @dump == 1,  "Cookie added";
  
  $string="name=new_value; SameSite=None; Secure;";
  $jar->store_cookies($url, undef, 0xFF,  $string);
  @dump=$jar->dump_cookies;

  ok @dump == 1,  "Cookie updated";
  ok $dump[0]=~ /name=new_value/, "Value updated";
  #say STDERR Dumper @dump;
}


done_testing;
