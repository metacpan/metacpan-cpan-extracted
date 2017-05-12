use strict;
use Math::BigInt;
use Test::More tests => 13;

use_ok('Language::MzScheme');

my $env = Language::MzScheme->new;
my $identity = $env->eval('(lambda (x) x)');
my $data = [
    1792,
    "string",
    [1 .. 6],
    ["a" .. "f"],
    [[-1, -2], [-3, -4], [-5, -6]],
    { a => 1, b => 2 },
    undef,
    \undef,
    \&use_ok,
    Math::BigInt->new,
];

foreach my $datum (@$data, $data, \$data) {
    my $scheme_value = $identity->($datum);
    is_deeply(
        $scheme_value->as_perl_data,
        $datum,
        "roundtrip: ".$scheme_value->as_write,
    );
}

