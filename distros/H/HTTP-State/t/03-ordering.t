use strict;
use warnings;

##################################
# use Log::ger::Output "Screen"; #
# use Log::OK {                  #
#   lvl=>"info",                 #
#   opt=>"verbose"               #
# };                             #
##################################

use Test::More;
use HTTP::State::Cookie qw":constants :encode :decode cookie_struct";
use HTTP::State;


my $jar=HTTP::State->new;

my $domain;
my $path;
my $name="test";
my $value="value1";

my $url;
my $cookie=cookie_struct(
  $name=>$value,
  domain=>$domain,
  path=>$path,
  secure=>1
);


{
  
  # DEFAULT DOMAIN
  #
  my $url="https://test.example.com.au";
  $jar->clear->store_cookies($url, undef, 0xFF,  $cookie);
  my ($encoded)=$jar->dump_cookies;
  
  # no domain set so use the url as default
  ok $encoded=~/Domain=test\.example\.com\.au/, "Default domain";
  # No path set
  ok $encoded=~/Path=\//, "Default path";
}

{
  # DEFAULT PATH
  #
  $cookie=cookie_struct(
    $name=>$value,
    domain=>$domain,
    path=>$path,
    secure=>1
  );
  my $url="https://test.example.com.au/my/path/here/da.pdf";
  $jar->clear->store_cookies($url,undef, 0xFF,  $cookie);

  my ($encoded)=$jar->dump_cookies;
  ok  $encoded=~/Path=\/my\/path\/here/, "Default Path. Upto right most /";
}

{
  # Prevent domain attribute targeting sub domains.
  #
  $jar->clear;
  $cookie=cookie_struct(
    $name=>$value,
    domain=>"a.test.example.com.au",
    path=>$path
  );
  
  $url="http://test.example.com.au/my/path/here/da.pdf";
  $jar->store_cookies($url, undef, 0xFF,  $cookie);

  my @encoded=$jar->dump_cookies;
  ok @encoded ==0, "Attempt sub domain cookie set";
}
{
  # Prevent domain attribute targeting public suffix domain
  #
  $jar->clear;
  $cookie=cookie_struct(
    $name=>$value,
    domain=>"com.au",
    path=>$path
  );
  
  $url="http://test.example.com.au/my/path/here/da.pdf";
  $jar->store_cookies($url, undef, 0xFF, $cookie);

  my @encoded=$jar->dump_cookies;
  ok @encoded == 0, "Ignore Attempt public domain cookie set";
}

{
  # Test cookies with different domains and same path and name 
  # adding correctly
  #
  $jar->clear;
  for(qw<a b c d e>){
    $url="https://dd.$_.example.com/";
    $cookie=cookie_struct(
      name=>"my_cookie",
      domain=>"dd.$_.example.com",
      secure=>1
    );
    $jar->store_cookies($url, undef, 0xFF,  $cookie);
  }
  $url="https://dd.dd.example.com/";
  $cookie=cookie_struct(
    name=>"my_cookie",
    domain=>"dd.dd.example.com",
    secure=>1
  );
  $jar->store_cookies($url, undef, 0xFF,  $cookie);
  my @encoded=$jar->dump_cookies;

  ok @encoded==6, "Count ok";
}

{
  # Set a cookie with the same name and path but different domains
  #
  $jar->clear;
  $url="https://dd.dd.example.com/";
  $cookie=cookie_struct(
    name=>"my_cookie",
    domain=>"dd.dd.example.com",
    secure=>1
  );

  $jar->store_cookies($url, undef, 0xFF,  $cookie) for 1..5;
  my @encoded=$jar->dump_cookies;

  ok @encoded==1, "Count ok";

}

{
  # Invariant creation time for cookie replacement
  #
  $jar->clear;
  $url="https://dd.dd.example.com/";
  $cookie=cookie_struct(
    name=>"my_cookie",
    domain=>"dd.dd.example.com",
    secure=>1
  );

  $jar->store_cookies($url, undef, 0xFF,  $cookie);
  my $db=$jar->db;
  my $time=$db->[0][COOKIE_CREATION_TIME];
  sleep 1;
  
  $jar->store_cookies($url, undef, 0xFF,  $cookie);
  ok @$db==1, "Count ok";

  my $new_time=$db->[0][COOKIE_CREATION_TIME];
  ok $new_time == $time, "Creation time ok";
}

done_testing;
