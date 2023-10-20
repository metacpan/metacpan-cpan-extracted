use strict;
use warnings;
use Math::GMPf qw(:mpf);

use Test::More;

# like  ($got, qr/expected/, $test_name);

my $ret = Math::GMPf->new();
my $zero = Math::GMPf->new(0);
my $one = Math::GMPf->new(1);

my $x = 1;
my $y = '1';

eval { Rmpf_div($ret, $one, $zero); };
like($@, qr/Division by zero not allowed/, "Rmpf_div");

eval { Rmpf_div_ui($ret, $one, 0); };
like($@, qr/Division by zero not allowed/, "Rmpf_div_ui");

eval { Rmpf_ui_div($ret, 0, $zero); };
like($@, qr/Division by zero not allowed/, "Rmpf_ui_div");

eval { my $r = $one / $zero; };
like($@, qr/Division by zero not allowed/, "overload_div - object / object");

eval { my $r = $one / 0; };
like($@, qr/Division by zero not allowed/, "overload_div - object / iv");

eval { my $r = $one / '0'; };
like($@, qr/Division by zero not allowed/, "overload_div - object / str");

eval { my $r = 1 / $zero; };
like($@, qr/Division by zero not allowed/, "overload_div - iv / object");

eval { my $r = '1' / $zero; };
like($@, qr/Division by zero not allowed/, "overload_div - str / object");

#################################################

eval { $one /= $zero; };
like($@, qr/Division by zero not allowed/, "overload_div_eq - object / object");

eval { $one /= 0; };
like($@, qr/Division by zero not allowed/, "overload_div_eq - object / iv");

eval { $one /= '0'; };
like($@, qr/Division by zero not allowed/, "overload_div_eq - object / str");

eval { $x /= $zero; };
like($@, qr/Division by zero not allowed/, "overload_div_eq - iv / object");

eval { $y /= $zero; };
like($@, qr/Division by zero not allowed/, "overload_div_eq - str / object");

done_testing();
