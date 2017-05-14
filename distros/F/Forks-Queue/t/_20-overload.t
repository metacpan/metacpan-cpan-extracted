use Test::More;
use Carp 'verbose';
use Net::Objwrap qw(:all-test);
use 5.012;
use Scalar::Util 'reftype';

# wrap an object without overloading

my $wrap_cfg = 't/20.cfg';
unlink $wrap_cfg;

my $r0 = [ 1, 2, 3, 4 ];

ok($r0 && ref($r0) eq 'ARRAY', 'created remote var');
ok(! -f $wrap_cfg, 'config file does not exist yet');

ok(wrap($wrap_cfg,$r0), 'wrap successful');
ok(-f $wrap_cfg, 'config file created');

my $r1 = unwrap($wrap_cfg);
ok($r1, 'client as boolean');
ok(ref($r1) eq 'Net::Objwrap::Proxy', 'client ref');

my $str = eval { "$r1" };
ok($str && !$@, 'can stringify');

# numeric operations

my $num = eval {0 + $r1} || 0;
ok($num && !$@, 'can numify');

ok(eval {$r1+5} && eval{$r1+5==$num+5} && !$@, 'can add');
ok(eval {$r1-5} && !$@ && eval {$r1-5 == $num-5} && !$@, 'can subtract');
ok(eval {5-$r1} && !$@ && eval {5-$r1 == 5-$num} && !$@, 'can subtract [swap]');
ok(eval {$r1*5} && !$@ && eval {$r1*5 == 5*$num} && 
   eval{5*$r1} && !$@, 'can multiply');
ok(eval {$r1/5} && eval{$r1/5 == $num/5} && !$@, 'can divide');
if ($num != 0) {
    ok(eval {5/$r1} && !$@ && eval{5/$r1==5/$num} && !$@, 'can divide [swap]');
}
ok(eval{$r1%5 == $num%5} && eval{5%$r1;1}, 'can mod');
ok(eval{$r1<<5 == $num<<5} && !$@, 'can <<');
ok(eval{$r1>>5 == $num>>5} && !$@, 'can >>');
ok(eval{$r1**0.1 == $num**0.1} && !$@, 'can **');
ok(eval{$r1 < 5 == $num < 5} && !$@ &&
   eval{$r1 >= 5 != $num < 5} && !$@, 'can < >=');
ok(eval{$r1 > 5 == $num > 5} && !$@ &&
   eval{$r1 <= 5 != $num > 5} && !$@, 'can > <=');
ok(!eval{$r1 <=> $num} && !$@, 'can <=>');
ok(eval{$r1 == $num} && !$@ && eval{$r1 != $num-100} && !$@, 'can == !=');
ok(eval{($r1 & 5) == ($num & 5)} && !$@ &&
   eval{($r1 | 5) == ($num | 5)} && !$@, 'can & |');
ok(eval{!$r1 == !$num && !$r1 != $num} && !$@, 'can !');
ok(eval{-$r1 == -$num} && !$@, 'can -');

my ($x,$y);
#ok(eval{$x=++$r1;$x==$num+1} && !$@, 'can ++') or diag $x,$str,$r1;
#ok(eval{$x=--$r1;$x+1==$num} && !$@, 'can --') or diag $x,$num,$r1;

ok(eval{$r1==0 ? 1 : log($r1)==log($num)} && !$@, 'can log');
ok(eval{$x=sin($r1);$y=cos($r1);abs($x*$x+$y*$y-1)<1.0e-6} && !$@,
   'can sin/cos');
ok(eval{atan2($r1,1)==atan2($num,1)} && !$@ &&
   eval{atan2(5,$r1)==atan2(5,$num)} && !$@, 'can atan2');
ok(eval{abs($r1)==abs($num)} && !$@, 'can abs');
ok(eval{int($r1)==int($num)} && !$@, 'can int');
ok(eval{~$r1 == ~$num} && !$@, 'can ~') or diag ~$r1, ~$num;
ok(eval{$r1^5 == $num^5} && !$@, 'can ^');

####

ok(eval{$r1 x 5 eq $str x 5} && !$@, 'can x, eq');
ok(eval{$r1 . "foo" eq $str . "foo"} && !$@, 'can .');
ok(eval{"foo" . $r1 eq "foo$str"} && !$@ &&
   eval{"foo$r1" eq "foo" . $str} && !$@, 'can .');
ok(eval{($r1 cmp $str) == 0} && !$@ &&
   eval{("foo" cmp $r1) == -($str cmp "foo")} && !$@, "can cmp");
ok(eval{$r1 lt "foo" == "foo" ge $str} && !$@ &&
   eval{"foo" gt $r1 == $str le "foo"} && !$@, "can lt, gt");
ok(eval{$r1 eq $str && $r1 ne "x$str" && "x$r1" eq "x$str"} && !$@,
   "can eq, ne");
ok(eval{$r1 ^ "foo" eq $str ^ "foo"} && !$@, "can ^.");

####

my $len = length(@$r1);
my $r2 = $r1;
eval { $r2 += 4 };
ok(!$@, 'can +=') or diag $@;
ok(eval{length(@$r2)} == $len, '+= does not affect underlying array')
    or diag Data::Dumper::Dumper($r2,$r1);

done_testing;
