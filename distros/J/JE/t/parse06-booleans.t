#!perl -T

use Test::More tests => 6;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  true;
  false;
  
  var a = true;
  var b = false;
  
  var c = true == false;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-6: Check side-effects

my $tmp;
ok( ($tmp = $j->prop('a')) and ref $tmp eq 'JE::Boolean' );
ok( !($tmp = $j->prop('b')) and ref $tmp eq 'JE::Boolean' );
ok( !($tmp = $j->prop('c')) and ref $tmp eq 'JE::Boolean' );
