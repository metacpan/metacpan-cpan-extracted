#!perl -T

use Test::More tests => 64;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok(
my $code = $j->parse(q{
  var q = 1
  var r = 1 | 2
  var s = 3 || 4
  var t7 = 6 >= 5
  var t8 = 9 <= 10

  t9 = 5
  t10 = 6; t10 -= 1
  t11 = 7; t11 *= 2
  t12 = 8; t12 /= 2
  t13 = 9; t13 %= 4
  t14 = 0; t14 += 2
  t15 = 1; t15 &= 2
  t16 = 2; t16 ^= 3
  t17 = 3; t17 |= 5
  t18 = 4; t18 <<= 5
  t19 = 5; t19 >>>= 6
  t20 = 6; t20 >>=  7

  ;t21=5;
  t22 = 6;t22-=1;
  t23 = 7;t23*=2;
  t24 = 8;t24/=2;
  t25 = 9;t25%=4;
  t26 = 0;t26+=2;
  t27 = 1;t27&=2;
  t28 = 2;t28^=3;
  t29 = 3;t29|=5;
  t30 = 4;t30<<=5;
  t31 = 5;t31>>>=6;
  t32 = 6;t32>>=7;

  t33 = 1 ? 2 : 3
  ;t34=1?2:3;
  0 ? nothing = 2 : t35 = 3 ? 4 : 5
  ;1?t36=2:nothing=3?4:5;

  for(t37 = 5 ;0;);
  for(t38 = 6, t38 -= 1 ;0;);
  for(t39 = 7, t39 *= 2 ;0;);
  for(t40 = 8, t40 /= 2 ;0;);
  for(t41 = 9, t41 %= 4 ;0;);
  for(t42 = 0, t42 += 2 ;0;);
  for(t43 = 1, t43 &= 2 ;0;);
  for(t44 = 2, t44 ^= 3 ;0;);
  for(t45 = 3, t45 |= 5 ;0;);
  for(t46 = 4, t46 <<= 5 ;0;);
  for(t47 = 5, t47 >>>= 6 ;0;);
  for(t48 = 6, t48 >>=  7 ;0;);
 
  for(t49=5;0;);
  for(t50 = 6,t50-=1;0;);
  for(t51 = 7,t51*=2;0;);
  for(t52 = 8,t52/=2;0;);
  for(t53 = 9,t53%=4;0;);
  for(t54 = 0,t54+=2;0;);
  for(t55 = 1,t55&=2;0;);
  for(t56 = 2,t56^=3;0;);
  for(t57 = 3,t57|=5;0;);
  for(t58 = 4,t58<<=5;0;);
  for(t59 = 5,t59>>>=6;0;);
  for(t60 = 6,t60>>=7;0;);

  for(t61 = 1 ? 2 : 3 ;0;);
  for(t62=1?2:3;0;);
  for(0 ? nothing = 2 : t63 = 3 ? 4 : 5 ;0;);
  for(1?t64=2:nothing=3?4:5;0;);

}),	'JE::Code');

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-64: Check side-effects

is( $j->prop('q'), 1, 'q is 1' );
is( $j->prop('r'), 3,  'r is 3'   );
is( $j->prop('s'),  3,   's is 3'    );
is( $j->prop('t7'), 'true', 't7 is true' );
is( $j->prop('t8'), 'true',   't8 is true'  );
is( $j->prop('t9'),  5,        ' = '          );
is( $j->prop('t10'), 5,        ' -= '          );
is( $j->prop('t11'), 14,      ' *= '           );
is( $j->prop('t12'), 4,     ' /= '            );
is( $j->prop('t13'), 1,   ' %= '            );
is( $j->prop('t14'), 2,  ' += '          );
is( $j->prop('t15'), 0, ' &= '        );
is( $j->prop('t16'), 1, ' ^= '      );
is( $j->prop('t17'), 7,  ' |= '    );
is( $j->prop('t18'), 128, ' <<= '  );
is( $j->prop('t19'), 0,   ' >>>= ' );
is( $j->prop('t20'), 0,  ' >>= '  );
is( $j->prop('t21'), 5, '='      );
is( $j->prop('t22'), 5, '-='   );
is( $j->prop('t23'), 14, '*=' );
is( $j->prop('t24'), 4,  '/=' );
is( $j->prop('t25'), 1, '%=' );
is( $j->prop('t26'), 2, '+=' );
is( $j->prop('t27'), 0, '&=' );
is( $j->prop('t28'), 1, '^=' );
is( $j->prop('t29'), 7,  '|=' );
is( $j->prop('t30'), 128, '<<=' );
is( $j->prop('t31'), 0,   '>>>='  );
is( $j->prop('t32'), 0,  '>>='       );
is( $j->prop('t33'), 2, 'a ? b : c'      );
is( $j->prop('t34'), 2, 'a?b:c'               );
is( $j->prop('t35'), 4, 'a ? b = c : d = e ? f : g' );
is( $j->prop('t36'), 2, 'a?b=c:d=e?f:g'                  );
is( $j->prop('t37'), 5, '" = " in for(;;)'                   );
is( $j->prop('t38'), 5, '" -= " in for(;;)'                     );
is( $j->prop('t39'), 14, '" *= " in for(;;)'                      );
is( $j->prop('t40'), 4,  '" /= " in for(;;)'                       );
is( $j->prop('t41'), 1, '" %= " in for(;;)'                        );
is( $j->prop('t42'), 2, '" += " in for(;;)'                       );
is( $j->prop('t43'), 0, '" &= " in for(;;)'                     );
is( $j->prop('t44'), 1, '" ^= " in for(;;)'                  );
is( $j->prop('t45'), 7,  '" |= " in for(;;)'             );
is( $j->prop('t46'), 128, '" <<= " in for(;;)'       );
is( $j->prop('t47'), 0,   '" >>>= " in for(;;)'  );
is( $j->prop('t48'), 0,  '" >>= " in for(;;)' );
is( $j->prop('t49'), 5, '"=" in for(;;)'    );
is( $j->prop('t50'), 5, '"-=" in for(;;)'  );
is( $j->prop('t51'), 14, '"*=" in for(;;)' );
is( $j->prop('t52'), 4,  '"/=" in for(;;)' );
is( $j->prop('t53'), 1, '"%=" in for(;;)' );
is( $j->prop('t54'), 2, '"+=" in for(;;)' );
is( $j->prop('t55'), 0, '"&=" in for(;;)' );
is( $j->prop('t56'), 1, '"^=" in for(;;)' );
is( $j->prop('t57'), 7,  '"|=" in for(;;)' );
is( $j->prop('t58'), 128, '"<<=" in for(;;)' );
is( $j->prop('t59'), 0,   '">>>=" in for(;;)'  );
is( $j->prop('t60'), 0,  '">>=" in for(;;)'       );
is( $j->prop('t61'), 2, 'a ? b : c in for(;;)'        );
is( $j->prop('t62'), 2, 'a?b:c in for(;;)'                );
is( $j->prop('t63'), 4, 'a ? b = c : d = e ? f : g in for(;;)' );
is( $j->prop('t64'), 2, 'a?b=c:d=e?f:g in for(;;)'                 );
