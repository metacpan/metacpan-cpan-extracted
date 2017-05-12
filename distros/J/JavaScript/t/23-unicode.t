#!perl

use Test::More;

use strict;
use warnings;

use JavaScript;

if (JavaScript->does_handle_utf8) {
    plan tests => 9;
}
else {
    plan skip_all => "No unicode support in SpiderMonkey";
}

my $runtime = new JavaScript::Runtime();
my $context = $runtime->create_context();

is( $context->eval(q!"\251"!), "\x{a9}", "got &copy;" );
is( $context->eval(q!"\xe9"!), "\x{e9}", "got e-actute" );
is( $context->eval(q!"\u2668"!), "\x{2668}", "got hot springs" );

$context->eval( 'copy = "\251" ');
is( $context->eval(q!copy!), "\x{a9}", "got &copy;" );

$context->bind_value( copy2 => "\251" );
is( $context->eval(q!copy2!), "\x{a9}", "got &copy;" );

# utf8 hash key in JS -> perl
$context->bind_value( ucopy => "\x{e9}" );
my $hash = $context->eval("x = {}; x[ucopy] = 1; x;");
my ($key) = keys %$hash;
is( $key, "\xe9", "unicode hash keys" );

# utf8 hash key in perl -> JS
$context->bind_value( uhash => { "\x{e9}" => 1 } );
is( $context->eval("uhash[ ucopy ]" ), 1, "unicode hash keys from perl" );

$context->unbind_value("uhash");
$context->unbind_value("ucopy");
$context->bind_value( ucopy => "\x{2668}" );
$context->bind_value( uhash => { "\x{2668}" => 1 } );
is( $context->eval(q{uhash[ucopy]}), 1, "unicode hash keys from perl" );

# Creating another runtime should work
my $rt2 = JavaScript::Runtime->new();
ok(1);