use strict;
use warnings;
use feature ":all";
##################################
# use Log::ger::Output "Screen"; #
# use Log::OK {                  #
#     opt=>"verbose",            #
#     lvl=>"info"                #
#   };                           #
#                                #
# use Data::Dumper;              #
##################################

use Test::More;
use HTTP::State ":flags";
use HTTP::State::Cookie ":all";


#Skip this test if HTTP::Cookie jar is not installed
BEGIN{
  eval { require HTTP::CookieJar};
  if($@){
    plan skip_all=>1;
  }
}


#use HTTP::CookieJar;


my @strings=(
  encode_set_cookie(cookie_struct(name2=>"value2", "Expires"=>(time+10))),
  encode_set_cookie(cookie_struct(name1=>"value", "Expires"=>(time+10))),
  encode_set_cookie(cookie_struct(name3=>"value3", "Max-Age"=>13, "SameSite"=>"Lax")),

  encode_set_cookie(cookie_struct(name4=>"value4", "Domain"=>"wrong.com", "Max-Age"=>13, "SameSite"=>"Lax")),
  encode_set_cookie(cookie_struct(name5=>"value5", "Domain"=>"my.site.com.au", "Max-Age"=>13, "SameSite"=>"Strict"))
);

my $state_jar=HTTP::State->new();
my $cookie_jar=HTTP::CookieJar->new();

my $url='http://my.site.com.au/path/to/file.pdf';
for (@strings){
  $state_jar->add($url, $_);
  $cookie_jar->add($url, $_);
}

my @hs=sort $state_jar->dump_cookies;

my @hc=sort $cookie_jar->dump_cookies;

ok @hs==@hc, "Correct count";


for(0..$#hs){
  ok 0==index($hs[$_], $hc[$_]), "Cookie match";
}


#say "";
my $state_jar2=HTTP::State->new();
my $cookie_jar2=HTTP::CookieJar->new();

# load with swapped dumps
#
$state_jar2->load_cookies(@hc);
$cookie_jar2->load_cookies(@hs);

@hs=sort $state_jar2->dump_cookies;

@hc=sort $cookie_jar2->dump_cookies;


ok @hs==@hc, "Correct count";

for(0..$#hc){
  ok 0==index($hs[$_], $hc[$_]), "Cookie match";
}



done_testing;
