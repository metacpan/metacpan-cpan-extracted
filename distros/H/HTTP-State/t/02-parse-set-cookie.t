use strict;
use warnings;
use feature ":all";

##################################
# use Log::ger::Output "Screen"; #
# use Log::OK {                  #
#   lvl=>"info",                 #
#   opt=>"verbose"               #
# };                             #
##################################

use Test::More;
use HTTP::State;
use HTTP::State::Cookie ":all";


{
  # No attributes
  my $string=encode_set_cookie cookie_struct a=>"b";
  ok $string eq "a=b", "no attributes or \";\"";
}
{
  # Unkown attributes
  my $string=encode_set_cookie cookie_struct a=>"b", "unkown", "value";
  ok $string eq "a=b", "unkown attribute ignored\";\"";
}
{
  # Case sensitivities
  my $string=encode_set_cookie cookie_struct a=>"b", "path", "/";
  ok $string eq "a=b; Path=/", "lower case Path ok";

  $string=encode_set_cookie cookie_struct a=>"b", "PATH", "/";
  ok $string eq "a=b; Path=/", "upper case Path ok";

  $string=encode_set_cookie cookie_struct a=>"b", "Path", "/";
  ok $string eq "a=b; Path=/", "mixed case Path ok";
}


done_testing;

