#!perl -T

use Test::More tests => 15;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');

switch ( 1 ) { }
switch ( 1 ) { case 1 : t4 = 4 }
switch ( 1 ) { default : t5 = 4 }
switch ( 1 ) {
	case 1 :
	case 2 : t6 = 6 ; ;
}
switch ( 89 ) {
	case 1 : t7a = 4
	case 2 : t7b = 6
	default : t7 = 6
	case 3  : t7a = 6
	case 4 : t7b  = 7
}
switch ( 89 ) {
	default : t8 = 6
	case 3 : ; t8a = 6
	case 4 : t8b = 7
}
switch ( 89 ) {
	case 3 : ; ;
	case 4 :
	default : t9 = 6
}

switch(1){}
switch(1){case(1):t10 = 4}
switch(1){default:t11 = 4}
switch(1){case(1):case(2):t12 = 6;;}
switch(89){case(1):t13a=4;case(2):t13b=6;default:t13=6;case(3):t13a=6;case(4):t13b=7}
switch(89){default:t14 = 6;case(3):;t14a = 6;case(4):t14b = 7}
switch(89){case(3):;;case(4):default:t15 = 6}


--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-15: Check side-effects

is( $j->prop('t4'), 4,                 'switch-case'               );
is( $j->prop('t5'), 4,               'switch-default'                 );
is( $j->prop('t6'), 6,            'switch-case-case'                    );
ok( $j->prop('t7')  eq 6 && $j->prop('t7a') eq 6 &&
    $j->prop('t7b') eq 7,      'switch-case-case-default-case-case'      );
ok( $j->prop('t8')  eq 6 && $j->prop('t8a') eq 6 &&
    $j->prop('t8b') eq 7,    'switch-default-case-case'                  );
is( $j->prop('t9'), 6,     'switch-case-case-default'                   );
is( $j->prop('t10'), 4,   'switch-case (minimal white space)'         );
is( $j->prop('t11'), 4,   'switch-default  (minimal white space)'    );
is( $j->prop('t12'), 6,    'switch-case-case (minimal white space)' );
ok( $j->prop('t13')  eq 6 && $j->prop('t13a') eq 6 &&
    $j->prop('t13b') eq 7,
  'switch-case-case-default-case-case (minimal white space)' );
ok( $j->prop('t14')  eq 6 && $j->prop('t14a') eq 6 &&
    $j->prop('t14b') eq 7,
  'switch-default-case-case (minimal white space)'                      );
is( $j->prop('t15'), 6, 'switch-case-case-default (minimal white space)' );
