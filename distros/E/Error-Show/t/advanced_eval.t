use strict;
use warnings;
use feature ":all";
use Test::More;

use Error::Show;

# Test the eval line offsetting works

my $program=
'# line before 1 
# line before 2
# line before 3
##_START
sub{
my $tmp;
$tmp=1+1;
$tmp=1+1;
$tmp=1+1;
my $test=1+a;
$tmp=1+1;
$tmp=1+1;
$tmp=1+1;
}
##_END
# line after 1
# line after 2
# line arfer 3
';

my $sub;
$sub=eval {Error::Show::streval $program};
my $error=$@;
ok $error, "Expected syntax error";

# Test that with no adjustments we get the expected line numbers
# Syntax error should be on line 8

if($error){
  my $context=Error::Show::context $error, keep=>1;

  my $match='10=> my \$test=1\+a;';
  say STDERR "CONTEXT $context";
  ok $context=~/$match/s, "Found error on expected unmodified line";
  #say $context;
}

# Test that with adjustments we get the expected line numbers
# Syntax error should be on line 4
if($error){
  my $context=Error::Show::context $error, start_mark=>'##_START', end_mark=>'##_END';
  
  #my $match='5=> my $test=1+a;';
  my $match='6=> my \$test=1\+a;';
  ok $context=~/$match/s, "Found error on expected modified line";
  #say $context;
}



# Test runtime errors

$program=
'# line before 1 
# line before 2
# line before 3
##_START
sub{
my $tmp;
$tmp=1+1;
$tmp=1+1;
$tmp=1+1;
my $test=1/0;
$tmp=1+1;
$tmp=1+1;
$tmp=1+1;
}
##_END
# line after 1
# line after 2
# line arger 3
';

$sub=Error::Show::streval $program;

ok !$@, "Compiled ok";

eval {
  $sub->()
};

if($@){
  my $context=Error::Show::context $@, keep=>1;
  my $match='10=> my \$test=1/0;';
  ok $context=~/$match/ms;
  say $context;
}
eval {
  $sub->()
};

if($@){
  my $context=Error::Show::context $@,  start_mark=>'##_START', end_mark=>'##_END';
  my $match='6=> my \$test=1/0;';
  ok $context=~/$match/ms;
  say $context;
}

done_testing;
