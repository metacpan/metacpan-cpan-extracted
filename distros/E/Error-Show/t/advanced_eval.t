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
1+1;
1+1;
1+1;
my $test=1+a;
1+1;
1+1;
1+1;
}
##_END
# line after 1
# line after 2
# line arger 3
';

my $sub=eval $program;
ok $@, "Expected syntax error";

# Test that with no adjustments we get the expected line numbers
# Syntax error should be on line 8

if($@){
  my $context=Error::Show::context error=>$@, program=>$program;
  my $match='9=> my \$test=1\+a;';
  ok $context=~/$match/s, "Found error on expected unmodified line";
  say $context;
}

# Test that with adjustments we get the expected line numbers
# Syntax error should be on line 4
if($@){
  my $context=Error::Show::context error=>$@, program=>$program,
  start_mark=>'##_START',
  end_mark=>'##_END';
  
  #my $match='5=> my $test=1+a;';
  my $match='5=> my \$test=1\+a;';
  ok $context=~/$match/s, "Found error on expected modified line";
  say $context;
}



# Test runtime errors

$program=
'# line before 1 
# line before 2
# line before 3
##_START
sub{
1+1;
1+1;
1+1;
my $test=1/0;
1+1;
1+1;
1+1;
}
##_END
# line after 1
# line after 2
# line arger 3
';

$sub=eval $program;

ok !$@, "Compiled ok";

eval {
  $sub->()
};

if($@){
  my $context=Error::Show::context error=>$@, program=>$program;
  my $match='9=> my \$test=1/0;';
  ok $context=~/$match/ms;
  say $context;
}
eval {
  $sub->()
};

if($@){
  my $context=Error::Show::context error=>$@, program=>$program,
  start_mark=>'##_START',
  end_mark=>'##_END';
  my $match='5=> my \$test=1/0;';
  ok $context=~/$match/ms;
  say $context;
}

done_testing;
