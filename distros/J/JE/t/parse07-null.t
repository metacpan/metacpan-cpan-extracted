#!perl -T

use Test::More tests => 4;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  null;

  var a = null;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Test 4: Check side-effects

my $tmp;
ok( ($tmp = $j->prop('a')) eq 'null' and ref $tmp eq 'JE::Null' );
