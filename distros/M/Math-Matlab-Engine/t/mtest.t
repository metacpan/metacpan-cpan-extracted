use Test;
BEGIN{ $| = 1; plan tests => 24;}
END {print "not ok 1\n" unless $loaded;}
use Math::Matlab::Engine;
$loaded = 1;
ok(1);

$ep = Math::Matlab::Engine->new;
ok($ep->PutMatrix('N',2,3,[1,2,3,4,5,6]));
ok($n=$ep->GetMatrix('N'));
ok($n->[0]->[0],1);
ok($n->[0]->[1],2);
ok($n->[0]->[2],3);
ok($n->[1]->[0],4);
ok($n->[1]->[1],5);
ok($n->[1]->[2],6);

ok($ep->PutMatrix('E1',3,1,[1,0,0]));
ok($ep->PutMatrix('E2',3,1,[0,1,0]));
ok($ep->PutMatrix('E3',3,1,[0,0,1]));

ok($ep->EvalString("N1=N*E1"));
ok($ep->EvalString("N2=N*E2"));
ok($ep->EvalString("N3=N*E3"));

$n1 = $ep->GetMatrix('N1');
ok($n1->[0]->[0],1);
ok(!defined($n1->[0]->[1]));
ok($n1->[1]->[0],4);

$n2 = $ep->GetMatrix('N2');
ok($n2->[0]->[0],2);
ok(!defined($n2->[0]->[1]));
ok($n2->[1]->[0],5);

$n3 = $ep->GetMatrix('N3');
ok($n3->[0]->[0],3);
ok(!defined($n3->[0]->[1]));
ok($n3->[1]->[0],6);



$ep->Close;
