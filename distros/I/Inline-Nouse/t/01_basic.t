use strict;
use Test::Simple tests => 3;

eval "require Inline::Nouse;";
ok(!$@, "loaded Inline::Nouse $@");

eval "use Inline 'Nouse' => 'function hello_world { #r<a>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0 }';";
ok(!$@, "created a code block $@");

ok(&hello_world({echo => 0}) eq "Hello, world!\n", "function returned ok");
