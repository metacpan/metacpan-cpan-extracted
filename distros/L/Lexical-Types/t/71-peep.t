#!perl -T

use strict;
use warnings;

use Test::More tests => 11 + 6 * 3;

our $counter;

sub Int::TYPEDSCALAR { ++$counter }

{
 my $desc = 'peephole optimization of conditionals';

 local $counter;
 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   if ($_[0]) {
    my Int $z;
    return 1;
   } elsif ($_[1] || $_[2]) {
    my Int $z;
    return 2;
   } elsif ($_[3] && $_[4]) {
    my Int $z;
    return 3;
   } elsif ($_[5] ? $_[6] : 0) {
    my Int $z;
    return 4;
   } else {
    my Int $z;
    return 5;
   }
   return 0;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->(1);
 is $counter, 1, "$desc : first branch was properly compiled";
 is $ret,     1, "$desc : first branch returned 1";

 $ret = $code->(0, 1);
 is $counter, 2, "$desc : second branch was properly compiled";
 is $ret,     2, "$desc : second branch returned 2";

 $ret = $code->(0, 0, 0, 1, 1);
 is $counter, 3, "$desc : third branch was properly compiled";
 is $ret,     3, "$desc : third branch returned 3";

 $ret = $code->(0, 0, 0, 0, 0, 1, 1);
 is $counter, 4, "$desc : fourth branch was properly compiled";
 is $ret,     4, "$desc : fourth branch returned 4";

 $ret = $code->();
 is $counter, 5, "$desc : fifth branch was properly compiled";
 is $ret,     5, "$desc : fifth branch returned 5";
}

{
 my $desc = 'peephole optimization of C-style loops';

 local $counter;

 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   my $ret = 0;
   for (
     my Int $i = 0
    ;
     do { my Int $x; $i < 4 }
    ;
     do { my Int $y; ++$i }
   ) {
    my Int $z;
    $ret += $i;
   }
   return $ret;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->();
 is $counter, 1 + 5 + 4 + 4, "$desc was properly compiled";
 is $ret,     6,             "$desc returned 0+1+2+3";
}

{
 my $desc = 'peephole optimization of range loops';

 local $counter;
 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   my $ret = 0;
   for ((do { my Int $z; 0 }) .. (do { my Int $z; 3 })) {
    my Int $z;
    $ret += $_;
   }
   return $ret;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->();
 is $counter, 2 + 4, "$desc was properly compiled";
 is $ret,     6,     "$desc returned 0+1+2+3";
}

{
 my $desc = 'peephole optimization of empty loops (RT #66164)';

 local $counter;
 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   my $ret = 0;
   for (;;) {
    my Int $z;
    ++$ret;
    return $ret;
   }
   return $ret;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->();
 is $counter, 1, "$desc was properly compiled";
 is $ret,     1, "$desc returned 1";
}

{
 my $desc = 'peephole optimization of map';

 local $counter;
 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   join ':', map {
    my Int $z;
    "x${_}y"
   } @_
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->(1, 2);
 is $counter, 2,         "$desc was properly compiled";
 is $ret,     'x1y:x2y', "$desc returned the right value";
}

{
 my $desc = 'peephole optimization of grep';

 local $counter;
 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   join ':', grep {
    my Int $z;
    $_ <= 3
   } @_
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->(1 .. 5);
 is $counter, 5,       "$desc was properly compiled";
 is $ret,     '1:2:3', "$desc returned the right value";
}

{
 my $desc = 'peephole optimization of substitutions';

 local $counter;
 local $@;
 my $code = eval <<' TESTCASE';
  use Lexical::Types;
  sub {
   my $str = $_[0];
   $str =~ s{
    ([0-9])
   }{
    my Int $z;
    9 - $1;
   }xge;
   $str;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->('0123456789');
 is $counter, 10,           "$desc was properly compiled";
 is $ret,     '9876543210', "$desc returned the right value";
}
