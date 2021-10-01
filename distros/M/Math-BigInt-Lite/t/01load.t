# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::Lite');
    use_ok('Math::BigInt');
};

my @mods = ('Math::BigInt::Lite',
            'Math::BigInt',
            'Math::BigRat',         # used in tests
            );

diag("");
diag("Testing with Perl $], $^X");
diag("");
diag(sprintf("%12s %s\n", 'Version', 'Module'));
diag(sprintf("%12s %s\n", '-------', '------'));
for my $mod (@mods) {
    my $str = "undef";
    eval "require $mod";
    unless ($@) {
        my $ver = $mod -> VERSION();
        $str = defined($ver) ? $ver : 'undef';
        diag(sprintf("%12s %s\n", $str, $mod));
    }
}
diag("");
