use v5.38;
use Test::More;

eval "use Test::PerlTidy";
plan skip_all => "Test::PerlTidy required for testing code style" if $@;

run_tests(
    path       => '.',
    perltidyrc => '.perltidyrc',
    exclude    => [ qr{^\.build/}, qr{^Luv-CLI-[\d.]+/}, qr{^blib/} ],
);