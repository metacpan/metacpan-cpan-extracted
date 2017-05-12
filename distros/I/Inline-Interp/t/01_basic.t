use strict;
use Test::More tests => 3;

require_ok( 'Inline::Echo' );

eval "use Inline 'Echo' => 'function hello_world {hello world}';";
ok(!$@, "created a code block $@");

is(&hello_world({echo => 0}), 'hello world', "function returned ok");
