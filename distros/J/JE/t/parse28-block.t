#!perl -T

use Test::More tests => 4;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok(
my $code = $j->parse(q{
  {}

  {
  }

  {};
  {}{  {}; {} {}
  }
}),	'JE::Code');

#--------------------------------------------------------------------#
# Test 3: See whether code parsed 6 statements

is( @{ $code->{tree} } - 2, 6, 'code parsed 6 statements');

#--------------------------------------------------------------------#
# Test 4: Run code

$code->execute;
is($@, '', 'execute code');

