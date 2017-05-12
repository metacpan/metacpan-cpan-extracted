use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 4 };

use Gcode::Interpreter;

my $obj = Gcode::Interpreter->new();

ok($obj->set_method('fast'));
ok($obj->set_method('table'));

ok($obj->stats());
ok($obj->position());
