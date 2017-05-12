#!perl -T

use Test::More tests => 59;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code') or die $@;
  t4 = 0x0;
  t5 = 0x1;
  t6 = 0x2;
  t7 = 0x3;
  t8 = 0x4;
  t9 = 0x5;
  t10 = 0x6;
  t11 = 0x7;
  t12 = 0x8;
  t13 = 0x9;
  t14 = 0xA;
  t15 = 0xB;
  t16 = 0xC;
  t17 = 0xD;
  t18 = 0xE;
  t19 = 0xF;
  t20 = 0xa;
  t21 = 0xb;
  t22 = 0xc;
  t23 = 0xd;
  t24 = 0xe;
  t25 = 0xf;
  t26 = 0xdeadbeef;
  t27 = 0xdEAdbEEf;
  t28 = 0xf00d;
  t29 = 0xF00D;
  t30 = 0x007cab5;
  t31 = 0x31337;

  t32 = 0X0;
  t33 = 0X1;
  t34 = 0X2;
  t35 = 0X3;
  t36 = 0X4;
  t37 = 0X5;
  t38 = 0X6;
  t39 = 0X7;
  t40 = 0X8;
  t41 = 0X9;
  t42 = 0XA;
  t43 = 0XB;
  t44 = 0XC;
  t45 = 0XD;
  t46 = 0XE;
  t47 = 0XF;
  t48 = 0Xa;
  t49 = 0Xb;
  t50 = 0Xc;
  t51 = 0Xd;
  t52 = 0Xe;
  t53 = 0Xf;
  t54 = 0Xdeadbeef;
  t55 = 0XdEAdbEEf;
  t56 = 0Xf00d;
  t57 = 0XF00D;
  t58 = 0X007cab5;
  t59 = 0X31337;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-59: Check side-effects

is( $j->prop('t4'), 0 );
is( $j->prop('t5'), 1 );
is( $j->prop('t6'), 2 );
is( $j->prop('t7'), 3 );
is( $j->prop('t8'), 4 );
is( $j->prop('t9'), 5 );
is( $j->prop('t10'), 6 );
is( $j->prop('t11'), 7 );
is( $j->prop('t12'), 8 );
is( $j->prop('t13'), 9 );
is( $j->prop('t14'), 10 );
is( $j->prop('t15'), 11 );
is( $j->prop('t16'), 12 );
is( $j->prop('t17'), 13 );
is( $j->prop('t18'), 14 );
is( $j->prop('t19'), 15 );
is( $j->prop('t20'), 10 );
is( $j->prop('t21'), 11 );
is( $j->prop('t22'), 12 );
is( $j->prop('t23'), 13  );
is( $j->prop('t24'), 14    );
is( $j->prop('t25'), 15      );
is( $j->prop('t26'), 0xdeadbeef );
is( $j->prop('t27'), 0xdeadbeef   );
is( $j->prop('t28'), 0xf00d        );
is( $j->prop('t29'), 0xf00d        );
is( $j->prop('t30'), 0x007cab5    );
is( $j->prop('t31'), 0x31337    );
is( $j->prop('t32'), 0       );
is( $j->prop('t33'), 1    );
is( $j->prop('t34'), 2  );
is( $j->prop('t35'), 3 );
is( $j->prop('t36'), 4 );
is( $j->prop('t37'), 5 );
is( $j->prop('t38'), 6 );
is( $j->prop('t39'), 7 );
is( $j->prop('t40'), 8 );
is( $j->prop('t41'), 9 );
is( $j->prop('t42'), 10 );
is( $j->prop('t43'), 11 );
is( $j->prop('t44'), 12 );
is( $j->prop('t45'), 13 );
is( $j->prop('t46'), 14 );
is( $j->prop('t47'), 15 );
is( $j->prop('t48'), 10 );
is( $j->prop('t49'), 11 );
is( $j->prop('t50'), 12 );
is( $j->prop('t51'), 13  );
is( $j->prop('t52'), 14    );
is( $j->prop('t53'), 15      );
is( $j->prop('t54'), 0xdeadbeef );
is( $j->prop('t55'), 0xdeadbeef   );
is( $j->prop('t56'), 0xf00d        );
is( $j->prop('t57'), 0xf00d        );
is( $j->prop('t58'), 0x007cab5    );
is( $j->prop('t59'), 0x31337    );
