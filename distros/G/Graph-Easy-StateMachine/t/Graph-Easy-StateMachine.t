# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Graph-Easy-StateMachine.t'
#########################

use Test::More;
BEGIN { plan tests => 13 };

{
    package SyntaxError;
    use Test::More;
    if (eval <<\BLAH)
use Graph::Easy::StateMachine <<ARF;
[BASE] - arf -> [B]
[B] - arf -> [C]
[B] - arf -> [D]
ARF
1;
BLAH
    {
        fail('ambiguous edge is syntax error');
    }else{
        my $E;
        $E = $@;
        like($E,qr/ambiguous/,'ambiguous edge is syntax error');
    }
}

package BibbityBoo;
use Test::More;
use Graph::Easy;
use Graph::Easy::StateMachine;

  my $graph = Graph::Easy->new( <<FSA );
      [ START ] => [ disconnected ]
      = goodconnect => [ inprogress ]
      = goodconnect => [ connected ]
      = sentrequest => [ requestsent ]
      = readresponse => [ haveresponse ]
      = done => [ END ]
      # Try pasting this into the form
      # at http://bloodgate.com/graph-demo
      [ disconnected ], [ inprogress ], [connected ] ,
      [ requestsent ] , [ haveresponse ]
      -- whoops --> [FAIL]
FSA
  my $code = $graph->as_FSA( base => 'bibbity');
  ok(eval  $code);
  my $boo = bless [], 'bibbity::START';
  ok($boo->disconnected);
  ok($boo->goodconnect);
  is(ref($boo), 'bibbity::inprogress');
  ok($boo->goodconnect);
  is(ref($boo), 'bibbity::connected');
  

  use Graph::Easy::StateMachine <<FSA ;
      [BASE] -> [ START ] = goA => [ A ]
      [ A ] = goB => [ B ]
      [ START ] = goB => [ B ]
FSA
  my $w = bless {};

  ok($w->START);
  is('BibbityBoo::B', ref ($w->goA->goB), "chaining");
  eval { $w->START };
  ok ( $@ =~ m/invalid state transition B->START/ );

  sub BibbityBoo::B::Drink { 'coffee' }
package BibbityBobbityBoo;
BEGIN { @ISA = qw/BibbityBoo/ }

use Graph::Easy::StateMachine ' [B] -> [C] ';

my $q = bless [];
$q->START->goB;
package BibbityBoo; # get back where we have Test::More imported
is('coffee', $q->Drink, "inherited state methods");

is('BibbityBobbityBoo::C', ref ($q->C), "inheritance");
eval { $w->C };
ok ($@);



