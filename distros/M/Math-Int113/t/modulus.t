use strict;
use warnings;
use Math::Int113 qw(divmod);
use Test::More;

# https://github.com/Perl/perl5/pull/22122 attended to some strangeness re the values
# used in the first test. (It's just a test to check that nothing untoward has happened.)
cmp_ok(Math::Int113->new(4611686018427387903) % Math::Int113->new(-13835058055282163712), '==', 4611686018427387903 % -13835058055282163712, "sanity check");

my ($div, $mod) = divmod((2 ** 105) + 123456789, (2 ** 65) + 987654321);
cmp_ok(ref($div), 'eq', 'Math::Int113', '1: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '1: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', 1099511627746, '1: division done correctly in divmod');
cmp_ok($mod, '==', 20867234289616163283, '1: modulus done correctly in divmod');

($div, $mod) = divmod((2 ** 105) + 123456789, -((2 ** 65) + 987654321));
cmp_ok(ref($div), 'eq', 'Math::Int113', '2: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '2: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', -1099511627746, '2: division done correctly in divmod');
cmp_ok($mod, '==', -16026253858790594270, '2: modulus done correctly in divmod');

($div, $mod) = divmod(-((2 ** 105) + 123456789), (2 ** 65) + 987654321);
cmp_ok(ref($div), 'eq', 'Math::Int113', '3: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '3: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', -1099511627746, '3: division done correctly in divmod');
cmp_ok($mod, '==', 16026253858790594270, '3: modulus done correctly in divmod');

($div, $mod) = divmod(-((2 ** 105) + 123456789), -((2 ** 65) + 987654321));
cmp_ok(ref($div), 'eq', 'Math::Int113', '4: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '4: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', 1099511627746, '4: division done correctly in divmod');
cmp_ok($mod, '==', -20867234289616163283, '4: modulus done correctly in divmod');

($div, $mod) = divmod((2 ** 105) + 123456789.8, (2 ** 65) + 987654321.8);
cmp_ok(ref($div), 'eq', 'Math::Int113', '5: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '5: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', 1099511627746, '5: division done correctly in divmod');
cmp_ok($mod, '==', 20867234289616163283, '5: modulus done correctly in divmod');

($div, $mod) = divmod((2 ** 105) + 123456789.8, -((2 ** 65) + 987654321.8));
cmp_ok(ref($div), 'eq', 'Math::Int113', '6: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '6: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', -1099511627746, '6: division done correctly in divmod');
cmp_ok($mod, '==', -16026253858790594270, '6: modulus done correctly in divmod');

($div, $mod) = divmod(-((2 ** 105) + 123456789.8), (2 ** 65) + 987654321.8);
cmp_ok(ref($div), 'eq', 'Math::Int113', '7: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '7: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', -1099511627746, '7: division done correctly in divmod');
cmp_ok($mod, '==', 16026253858790594270, '7: modulus done correctly in divmod');

($div, $mod) = divmod(-((2 ** 105) + 123456789.8), -((2 ** 65) + 987654321.8));
cmp_ok(ref($div), 'eq', 'Math::Int113', '8: division in divmod returns Math::Int113 object');
cmp_ok(ref($mod), 'eq', 'Math::Int113', '8: modulus in divmod returns Math::Int113 object');
cmp_ok($div, '==', 1099511627746, '8: division done correctly in divmod');
cmp_ok($mod, '==', -20867234289616163283, '8: modulus done correctly in divmod');

eval {require Math::GMPz;};

unless($@) {
  for(1..100) {
    my $add = 1 + int(rand(2000));
    my $mul = 2 + int(rand(2 ** 32));

    my $div = (~0) + $add;
    my $num = (~0) * $mul;
    my $zmod = (Math::GMPz->new(~0) * $mul) % (Math::GMPz->new(~0) + $add);

    my $mod = $num % $div;
    my $msg = sprintf("%.36g %% %.36g == %.36g", $num, $div, $mod);
    cmp_ok($mod, '==', $zmod, "1: $msg");

    my $mdiv = Math::Int113->new($div);
    $mod = $num % $mdiv;
    $msg = sprintf("%.36g %% %s == %s", $num, $mdiv, $mod);
    cmp_ok("$mod", 'eq', "$zmod", "2: $msg");

    my $mnum = Math::Int113->new($num);
    $mod = $mnum % $div;
    $msg = sprintf("%s %% %.36g == %s", $num, $mdiv, $mod);
    cmp_ok("$mod", 'eq', "$zmod", "3: $msg");

    $mod = $mnum % $mdiv;
    $msg = sprintf("%s %% %s == %s", $num, $mdiv, $mod);
    cmp_ok("$mod", 'eq', "$zmod", "4: $msg");
  }
}
else {
  warn "Skippping tests as Math::GMPz failed to load";
}

done_testing();
