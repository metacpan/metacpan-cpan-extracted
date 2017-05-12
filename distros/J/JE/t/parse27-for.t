#!perl -T

use Test::More tests => 63;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  for ( var t4 in {a:0} ) ; 
  for ( var t5 = 5 in {} ) ; 

  for ( var t6    ; ; ) break
  for ( var t7 = 7   ; ; ) break
  for ( var t8a    , t8b ; ; ) break
  for ( var t9a = 9 , t9b    ; ; ) break
  for ( var t10a     , t10b = 10 ; ; ) break
  for ( var t11a = 11 , t11b = 11.5 ; ; ) break

  for ( var t12a    ; t12b = 0 ; ) ;
  for ( var t13a = 7   ; t13b = 0 ; ) ;
  for ( var t14a    , t14b ; t14c = 0 ; ) ;
  for ( var t15a = 9 , t15b   ; t15c = 0 ; ) ;
  for ( var t16a     , t16b = 10 ; t16c = 0 ; ) ;
  for ( var t17a = 11 , t17b = 11.5 ; t17c = 0 ; ) ;

  for ( var t18a    ; ; t18b = 1 ) if(this.t18b) break
  for ( var t19a = 7   ; ; t19b = 1 ) if(this.t19b) break
  for ( var t20a    , t20b ; ; t20c = 1 ) if(this.t20c) break
  for ( var t21a = 9 , t21b   ; ; t21c = 1 ) if(this.t21c) break
  for ( var t22a     , t22b = 10 ; ; t22c = 1 ) if(this.t22c) break
  for ( var t23a = 11 , t23b = 11.5 ; ; t23c = 1 ) if(this.t23c) break

  for ( var t24a    ; t24b = 1 ; t24c = 1 ) if(this.t24c) break
  for ( var t25a = 7   ; t25b = 1 ; t25c = 1 ) if(this.t25c) break
  for ( var t26a    , t26b ; t26c = 1 ; t26d = 1 ) if(this.t26d) break
  for ( var t27a = 9 , t27b   ; t27c = 1 ; t27d = 1 ) if(this.t27d) break
  for ( var t28a , t28b = 10 ; t28c = 1 ; t28d = 1 ) if(this.t28d) break
  for ( var t29a = 11 , t29b = 11.5 ; t29c = 1 ; t29d = 1 ) 
      if(this.t29d) break

  for ( t30 = 30 ;          ; ) break
  for ( t31a = 31 ; t31b = 0 ;      ) ;
  for ( t32a = 32 ;           ; t32b = 32.5 ) if(this.t32b) break
  for ( t33a = 33 ; t33b = 33.5 ; t33c = 33.7 ) if(this.t33c) break


  for(var t34 in{a:0});
  for(var t35=5 in{});

  for(var t36;;)break
  for(var t37=7;;)break
  for(var t38a,t38b;;)break
  for(var t39a=9,t39b;;)break
  for(var t40a,t40b=10;;)break
  for(var t41a=11,t41b=11.5;;)break

  for(var t42a;t42b=0;);
  for(var t43a=7;t43b=0;);
  for(var t44a,t44b;t44c=0;);
  for(var t45a=9,t45b;t45c=0;);
  for(var t46a,t46b=10;t46c=0;);
  for(var t47a=11,t47b=11.5;t47c=0;);

  for(var t48a;;t48b=1)if(this.t48b) break
  for(var t49a=7;;t49b=1)if(this.t49b) break
  for(var t50a,t50b;;t50c=1)if(this.t50c) break
  for(var t51a=9,t51b;;t51c=1)if(this.t51c) break
  for(var t52a,t52b=10;;t52c=1)if(this.t52c) break
  for(var t53a=11,t53b=11.5;;t53c=1)if(this.t53c) break

  for(var t54a;t54b=1;t54c=1)if(this.t54c) break
  for(var t55a=7;t55b=1;t55c=1)if(this.t55c) break
  for(var t56a,t56b;t56c=1;t56d=1)if(this.t56d) break
  for(var t57a=9,t57b;t57c=1;t57d=1)if(this.t57d) break
  for(var t58a,t58b=10;t58c=1;t58d=1)if(this.t58d) break
  for(var t59a=11,t59b=11.5;t59c=1;t59d=1)if(this.t59d) break

  for(t60=30;;)break
  for(t61a=31;t61b=0;);
  for(t62a=32;;t62b=32.5)if(this.t62b) break
  for(t63a=33;t63b=33.5;t63c=33.7)if(this.t63c) break

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-63: Check side-effects

is( $j->prop('t4'), 'a', 'var a in b'    );
is( $j->prop('t5'), 5,       'var a = b in c' );
is( $j->prop('t6'), 'undefined', 'var a ; ;'      );
is( $j->prop('t7'),  7,              'var a = b ; ;'  );
ok( $j->prop('t8a') eq 'undefined' &&
    $j->prop('t8b') eq 'undefined',     'var a , b ; ;'   );
ok( $j->prop('t9a') eq  9          &&
    $j->prop('t9b') eq 'undefined',       'var a = x , b ; ;' );
ok( $j->prop('t10a') eq 'undefined' &&
    $j->prop('t10b') eq  10,               'var a , b = x ; ;'   );
ok( $j->prop('t11a') eq 11          &&
    $j->prop('t11b') eq 11.5,              'var a = x , b = y ; ;' );
ok( $j->prop('t12a') eq 'undefined' &&
    $j->prop('t12b') eq  0,               'var a ; b ;'             );
ok( $j->prop('t13a') eq 7           &&
    $j->prop('t13b') eq 0,              'var a = x ; b ;'           );
ok( $j->prop('t14a') eq 'undefined' &&
    $j->prop('t14b') eq 'undefined' &&
    $j->prop('t14c') eq 0, 'var a , b ; c ;' );
ok( $j->prop('t15a') eq 9           &&
    $j->prop('t15b') eq 'undefined' &&
    $j->prop('t15c') eq  0, 'var a = x , b ; c ;' );
ok( $j->prop('t16a') eq 'undefined' &&
    $j->prop('t16b') eq 10         &&
    $j->prop('t16c') eq 0, 'var a , b = x ; c ;' );
ok( $j->prop('t17a') eq 11         &&
    $j->prop('t17b') eq 11.5       &&
    $j->prop('t17c') eq 0, 'var a = x , b = y ; c ;' );
ok( $j->prop('t18a') eq 'undefined' &&
    $j->prop('t18b') eq  1, 'var a ; ; b' );
ok( $j->prop('t19a') eq 7           &&
    $j->prop('t19b') eq 1, 'var a = x ; ; b' );
ok( $j->prop('t20a') eq 'undefined' &&
    $j->prop('t20b') eq 'undefined' &&
    $j->prop('t20c') eq 1, 'var a , b ; ; c' );
ok( $j->prop('t21a') eq 9           &&
    $j->prop('t21b') eq 'undefined' &&
    $j->prop('t21c') eq  1, 'var a = x , b ; ; c' );
ok( $j->prop('t22a') eq 'undefined' &&
    $j->prop('t22b') eq 10         &&
    $j->prop('t22c') eq 1, 'var a , b = x ; ; c' );
ok( $j->prop('t23a') eq 11         &&
    $j->prop('t23b') eq 11.5       &&
    $j->prop('t23c') eq 1, 'var a = x , b = y ; ; c' );
ok( $j->prop('t24a') eq 'undefined' &&
    $j->prop('t24b') eq  1          &&
    $j->prop('t24c') eq 1, 'var a ; b ; c' );
ok( $j->prop('t25a') eq 7          &&
    $j->prop('t25b') eq 1          &&
    $j->prop('t25c') eq 1, 'var a = x ; b ; c' );
ok( $j->prop('t26a') eq 'undefined' &&
    $j->prop('t26b') eq 'undefined' &&
    $j->prop('t26c') eq 1          &&
    $j->prop('t26d') eq 1, 'var a , b ; c ; d' );
ok( $j->prop('t27a') eq 9          &&
    $j->prop('t27b') eq 'undefined' &&
    $j->prop('t27c') eq  1          &&
    $j->prop('t27d') eq 1, 'var a = x , b ; c ; d' );
ok( $j->prop('t28a') eq 'undefined' &&
    $j->prop('t28b') eq  10        &&
    $j->prop('t28c') eq 1        &&
    $j->prop('t28d') eq 1, 'var a , b = x ; c ; d' );
ok( $j->prop('t29a') eq 11     &&
    $j->prop('t29b') eq 11.5 &&
    $j->prop('t29c') eq 1  &&
    $j->prop('t29d') eq 1, 'var a = x , b = y ; c ; d' );
is( $j->prop('t30'), 30,   'a ; ;'                    );
ok( $j->prop('t31a') eq 31 &&
    $j->prop('t31b') eq 0,  'a ; b ;'                );
ok( $j->prop('t32a') eq 32 &&
    $j->prop('t32b') eq 32.5, 'a ; ; b'           );
ok( $j->prop('t33a') eq 33  &&
    $j->prop('t33b') eq 33.5 &&
    $j->prop('t33c') eq 33.7, 'a ; b ; c'                    );
is( $j->prop('t34'), 'a',    'var a in b (minimal white space)'  );
is( $j->prop('t35'), 5,        'var a=b in c (minimal white space)' );
is( $j->prop('t36'), 'undefined', 'var a;;'                           );
is( $j->prop('t37'),  7,            'var a=b;;'                         );
ok( $j->prop('t38a') eq 'undefined' &&
    $j->prop('t38b') eq 'undefined', 'var a,b;;'                         );
ok( $j->prop('t39a') eq  9          &&
    $j->prop('t39b') eq 'undefined', 'var a=x,b;;'                       );
ok( $j->prop('t40a') eq 'undefined' &&
    $j->prop('t40b') eq  10,        'var a,b=x;;'                       );
ok( $j->prop('t41a') eq 11          &&
    $j->prop('t41b') eq 11.5,     'var a=x,b=y;;'                     );
ok( $j->prop('t42a') eq 'undefined' &&
    $j->prop('t42b') eq  0,    'var a;b;'                          );
ok( $j->prop('t43a') eq 7           &&
    $j->prop('t43b') eq 0, 'var a=x;b;'                        );
ok( $j->prop('t44a') eq 'undefined' &&
    $j->prop('t44b') eq 'undefined' &&
    $j->prop('t44c') eq 0, 'var a,b;c;' );
ok( $j->prop('t45a') eq 9           &&
    $j->prop('t45b') eq 'undefined' &&
    $j->prop('t45c') eq  0, 'var a=x,b;c;' );
ok( $j->prop('t46a') eq 'undefined' &&
    $j->prop('t46b') eq 10         &&
    $j->prop('t46c') eq 0, 'var a,b=x;c;' );
ok( $j->prop('t47a') eq 11         &&
    $j->prop('t47b') eq 11.5       &&
    $j->prop('t47c') eq 0, 'var a=x,b = y ; c ;' );
ok( $j->prop('t48a') eq 'undefined' &&
    $j->prop('t48b') eq  1, 'var a;;b' );
ok( $j->prop('t49a') eq 7           &&
    $j->prop('t49b') eq 1, 'var a=x;;b' );
ok( $j->prop('t50a') eq 'undefined' &&
    $j->prop('t50b') eq 'undefined' &&
    $j->prop('t50c') eq 1, 'var a,b;; c' );
ok( $j->prop('t51a') eq 9           &&
    $j->prop('t51b') eq 'undefined' &&
    $j->prop('t51c') eq  1, 'var a=x,b;;c' );
ok( $j->prop('t52a') eq 'undefined' &&
    $j->prop('t52b') eq 10         &&
    $j->prop('t52c') eq 1, 'var a,b=x;;c' );
ok( $j->prop('t53a') eq 11         &&
    $j->prop('t53b') eq 11.5       &&
    $j->prop('t53c') eq 1, 'var a=x,b=y;;c' );
ok( $j->prop('t54a') eq 'undefined' &&
    $j->prop('t54b') eq  1          &&
    $j->prop('t54c') eq 1, 'var a;b;c' );
ok( $j->prop('t55a') eq 7          &&
    $j->prop('t55b') eq 1          &&
    $j->prop('t55c') eq 1, 'var a=x;b;c' );
ok( $j->prop('t56a') eq 'undefined' &&
    $j->prop('t56b') eq 'undefined' &&
    $j->prop('t56c') eq 1          &&
    $j->prop('t56d') eq 1, 'var a,b;c;d' );
ok( $j->prop('t57a') eq 9          &&
    $j->prop('t57b') eq 'undefined' &&
    $j->prop('t57c') eq  1          &&
    $j->prop('t57d') eq 1, 'var a=x,b;c;d' );
ok( $j->prop('t58a') eq 'undefined' &&
    $j->prop('t58b') eq  10        &&
    $j->prop('t58c') eq 1        &&
    $j->prop('t58d') eq 1, 'var a,b=x;c;d' );
ok( $j->prop('t59a') eq 11     &&
    $j->prop('t59b') eq 11.5 &&
    $j->prop('t59c') eq 1  &&
    $j->prop('t59d') eq 1, 'var a=x,b=y;c;d' );
is( $j->prop('t60'), 30,   'a;;'            );
ok( $j->prop('t61a') eq 31 &&
    $j->prop('t61b') eq 0,  'a;b;'        );
ok( $j->prop('t62a') eq 32 &&
    $j->prop('t62b') eq 32.5, 'a;;b'   );
ok( $j->prop('t63a') eq 33  &&
    $j->prop('t63b') eq 33.5 &&
    $j->prop('t63c') eq 33.7, 'a;b;c' );
