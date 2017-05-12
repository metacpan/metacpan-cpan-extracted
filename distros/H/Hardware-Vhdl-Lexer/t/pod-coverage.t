#!perl -T

use Test::More;

eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" 
} else {
    plan tests => 1;
}

#pod_coverage_ok('Hardware::Vhdl::Lexer', {also_private => qr/^START$/}, 'Hardware::Vhdl::Lexer with START private');
pod_coverage_ok(
    "Hardware::Vhdl::Lexer",
    { also_private => [ qr/^[A-Z_]+$/ ], },
    "Hardware::Vhdl::Lexer, with all-caps functions as privates",
);