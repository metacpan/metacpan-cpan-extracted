# -*- mode: perl; -*-

use strict;             # restrict unsafe constructs
use warnings;           # enable optional warnings

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::GMP');
    use_ok('Math::BigInt');         # Math::BigInt is required for the tests
};

my @mods = ('Math::BigInt::GMP',
            'Math::BigInt');

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
diag(sprintf("%12s %s\n", 'Version', 'Library'));
diag(sprintf("%12s %s\n", '-------', '-------'));
my $GMP_version = Math::BigInt::GMP::gmp_version();
diag(sprintf("%12s %s\n", $GMP_version || '-', 'GMP'));
diag("");
