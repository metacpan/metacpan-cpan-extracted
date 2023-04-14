# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::FastCalc');
    use_ok('Math::BigInt');         # Math::BigInt is required for the tests
};

my @mods = (
            'Math::BigInt',
            'Math::BigInt::Lib',
            'Math::BigInt::Calc',
            'Math::BigInt::FastCalc',
           );

diag("");
diag("Testing with Perl $], $^X");
diag("");
diag(sprintf("%12s %s\n", 'Version', 'Module'));
diag(sprintf("%12s %s\n", '-------', '------'));
for my $mod (@mods) {
    my $ver = $mod -> VERSION();
    my $str = defined($ver) ? $ver : 'undef';
    diag(sprintf("%12s %s\n", $str, $mod));
}
diag("");
