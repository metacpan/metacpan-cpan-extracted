use Test;
BEGIN{ $| = 1; plan tests => 11;}
END {print "not ok 1\n" unless $loaded;}
use Math::Matlab::Engine;
$loaded = 1;
ok(1);

$ep = Math::Matlab::Engine->new;
ok($ep->PutArray('N',[3,2],[1,2,3,4,5,6]));

ok($ep->PutArray('E1',[1,3],[1,0,0]));
ok($ep->PutArray('E2',[1,3],[0,1,0]));
ok($ep->PutArray('E3',[1,3],[0,0,1]));

ok($ep->EvalString("N1=N*E1"));
ok($ep->EvalString("N2=N*E2"));
ok($ep->EvalString("N3=N*E3"));

$n1 = $ep->GetArray('N1');
ok($n1->[0]->[0],1);
ok(!defined($n1->[0]->[1]));
ok($n1->[1]->[0],4);
