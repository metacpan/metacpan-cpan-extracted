#!perl -T

use Test::More tests => 7;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  function b( c ) {
  };

  function d() {
  };

  function e( f,g,h) {
  };

  function f(f, g ,h ) {
  };
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-7: Check side-effects

# A bit noisy right now, because function bodies do not stringify properly
# yet. They produce lots of warnings.
local $SIG{__WARN__} = sub{};

like( $j->prop('b'), qr/^function b\(c\)/ );
like( $j->prop('d'), qr/^function d\(\)/    );
like( $j->prop('e'), qr/^function e\(f,g,h\)/ );
like( $j->prop('f'), qr/^function f\(f,g,h\)/  );
