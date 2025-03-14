# Some more tests on overloading of '**' and '**=', mainly aimed
# at checking that string and NV values are handled as expected.
use strict;
use warnings;
use Config;
use Math::GMPz qw(:mpz);

use Test::More;

my($op, $op1, $op2);

my $obj1 = 2 ** Math::GMPz->new(4);
cmp_ok(ref($obj1), 'eq', 'Math::GMPz', "2 ** obj(4) returns Math::GMPz object");

my $obj2 = Math::GMPz->new(2) ** 4;
cmp_ok(ref($obj2), 'eq', 'Math::GMPz', "obj(2) ** 4 returns Math::GMPz obj");

cmp_ok($obj1, '==', 16, "\$obj1 set to correct value");
cmp_ok($obj2, '==', 16, "\$obj2 set to correct value");

eval { my $x = $obj1 ** -1;};
like($@, qr/^Negative argument supplied to Math::GMPz::overload_pow/, "'**'croaks on -ve exponent");
$op = '-3';
cmp_ok($op ** $obj1, '==', 43046721, "'**'ok on -ve  IV operand");
cmp_ok($op **= $obj1, '==', 43046721, "'**='ok on -ve  IV operand");
cmp_ok(Math::GMPz->new(-3) ** $obj1, '==', 43046721, "'**'ok on -ve Math::GMPz object operand");
$op = Math::GMPz->new(-3);
cmp_ok($op **= $obj1, '==', 43046721, "'**='ok on -ve Math::GMPz object operand");

eval { my $x = $obj1 ** '4.1';};
like($@, qr/^Non-integer string value/, "'**' croaks on non-integer string exponent");
eval { $obj1 **= '4.1';};
like($@, qr/^Non-integer string value/, "'**=' croaks on non-integer string exponent");

eval { my $x = '4.1' ** $obj1;};
like($@, qr/^Non-integer string value/, "'**' croaks on non-integer string operand");
$op = '4.1';
eval { $op **= $obj1;};
like($@, qr/^Non-integer string value/, "'**=' croaks on non-integer string operand");

cmp_ok($obj1 ** 4.5, '==', $obj2 ** 4.9, "'**' ok on non-integer NV exponent");
cmp_ok(4.5 ** $obj1, '==', 4.9 ** $obj2, "'**' ok on non-integer NV operandt");
cmp_ok($obj1 **= 4.5, '==', $obj2 **= 4.9, "'**=' ok on non-integer NV exponent");
($op1, $op2) = (4.5, 4.9);
cmp_ok($op1 **= $obj1, '==', $op2 **= $obj2, "'**=' ok on non-integer NV operand");

eval { my $x = $obj1 ** ('2' x 20);};
like($@, qr/^Exponent does not fit into unsigned long int in Math::GMPz::overload_pow/, "'**' croak on overflow from string value");
eval { $obj1 **= ('2' x 20);};
like($@, qr/Exponent must fit into an unsigned long/, "'**=' croak on overflow from string value");

eval { my $x = $obj1 ** 1e25};
like($@, qr/^/, "'**' croak on overflow from NV value");
eval { $obj1 **= 1e25};
like($@, qr/Exponent must fit into an unsigned long/, "'**=' croak on overflow from NV value");

if($Config{ivsize} > $Config{longsize}) {
  eval { my $obj = $obj1 ** Math::GMPz->new(1 << 40);};
  like($@, qr/^Exponent does not fit into unsigned long int in Math::GMPz::overload_pow/, "**' detects overflow of ULONG_MAX (in object) when UV_MAX has not been exceeded");
  eval { my $obj  = $obj1 ** (1 << 40);};
  like($@, qr/^Exponent does not fit into unsigned long int in Math::GMPz::overload_pow/, "**' detects overflow of ULONG_MAX (in IV) when UV_MAX has not been exceeded");

  eval { $obj1 **= Math::GMPz->new(1 << 40);};
  like($@, qr/Exponent must fit into an unsigned long/, "**=' detects overflow of ULONG_MAX (in object) when UV_MAX has not been exceeded");
  eval { $obj1 **= (1 << 40);};
  like($@, qr/^Exponent does not fit into unsigned long int in Math::GMPz::overload_pow_eq/, "**=' detects overflow of ULONG_MAX (in IV) when UV_MAX has not been exceeded");
}

done_testing();
