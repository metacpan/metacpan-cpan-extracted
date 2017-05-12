use strict;
use warnings;

use MarpaX::Demo::SampleScripts;

use Test::More tests => 1;

# ------------------------------------------------

my($object) = MarpaX::Demo::SampleScripts -> new;

isa_ok($object, 'MarpaX::Demo::SampleScripts', '$object');

print "# Internal test count: 1\n";
