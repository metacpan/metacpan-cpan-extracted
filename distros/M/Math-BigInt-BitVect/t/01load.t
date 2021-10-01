# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt');
    use_ok('Math::BigInt::BitVect');
};

my @mods = ('Math::BigInt',
            'Math::BigInt::Lib',
            'Math::BigInt::BitVect',
            'Bit::Vector',
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
