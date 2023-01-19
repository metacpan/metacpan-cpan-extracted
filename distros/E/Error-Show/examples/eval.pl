use strict;
use warnings;
use feature "say";

use Error::Show;


my $prog='say "hello there";
$a+1/0;
';
#$prog="sub { $prog }";
my $code =eval $prog; 
if($@){
  say "ERROR is".Error::Show::context error=>$@, program=>$prog;
}

eval {$code->()};

if($@){
  say "ERROR is".Error::Show::context error=>$@, program=>$prog;
}

