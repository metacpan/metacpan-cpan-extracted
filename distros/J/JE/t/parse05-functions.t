#!perl -T

use Test::More tests => 23;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  t4 = function(){}
  t5 = function (){}
  t6 = function( ){}
  t7 = function() {}
  t8 = function(){ }
  t9 = function(/**/){}

  t10 = function(p1,p2){ }
  t11 = function (p1,p2) { 1; }
  t12 = function named(p1,p2) { 1; }
  t13 = function named (p1,p2) { 1; }

  t14
  =
  function
  (
  )
  {
  }

  // Function declarations:

  function t15(){}
  function t16 (){}
  function t17( ){}
  function t18() {}
  function t19(){ }
  function t20(/**/){}

  function
  t21
  (
  )
  {
  }

  function t22(p1,p2){ }
  function t23 (p1,p2) { 1; }
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-23: Check side-effects

# A bit noisy right now, because function bodies do not stringify properly
# yet. They produce lots of warnings.
local $SIG{__WARN__} = sub{};

like( $j->prop('t4'), qr/^function anon\d+\(\) \{/ );
like( $j->prop('t5'), qr/^function anon\d+\(\) \{/ );
like( $j->prop('t6'), qr/^function anon\d+\(\) \{/ );
like( $j->prop('t7'), qr/^function anon\d+\(\) \{/ );
like( $j->prop('t8'), qr/^function anon\d+\(\) \{/  );
like( $j->prop('t9'), qr/^function anon\d+\(\) \{/    );
like( $j->prop('t10'), qr/^function anon\d+\(p1,p2\) \{/ );
like( $j->prop('t11'), qr/^function anon\d+\(p1,p2\) \{/   );
like( $j->prop('t12'), qr/^function named\(p1,p2\) \{/      );
like( $j->prop('t13'), qr/^function named\(p1,p2\) \{/      );
like( $j->prop('t14'), qr/^function anon\d+\(\) \{/        );
like( $j->prop('t15'), qr/^function t15\(\) \{/          );
like( $j->prop('t16'), qr/^function t16\(\) \{/       );
like( $j->prop('t17'), qr/^function t17\(\) \{/     );
like( $j->prop('t18'), qr/^function t18\(\) \{/    );
like( $j->prop('t19'), qr/^function t19\(\) \{/   );
like( $j->prop('t20'), qr/^function t20\(\) \{/   );
like( $j->prop('t21'), qr/^function t21\(\) \{/    );
like( $j->prop('t22'), qr/^function t22\(p1,p2\) \{/ );
like( $j->prop('t23'), qr/^function t23\(p1,p2\) \{/  );
