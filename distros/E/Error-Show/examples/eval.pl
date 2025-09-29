use strict;
use warnings;
use feature "say";

use Error::Show;


my $prog='

  sub call_me {
    $a+1/0;
  }

  say "hello there";
  call_me;

  ';



# Normal string eval
{
  say "================== Normal string eval =====================";
  my $result =eval $prog; 
  if($@){
    say $@;
  }

}

{
  say "================== Normal string with context =====================";
  my $result =eval $prog; 
  if($@){
    say Error::Show::context $@;
  }

}



say "";

{
  say "================== eval streval =====================";
  my $result =eval {streval $prog};
  if($@){
    say Error::Show::context $@;
  }


}
