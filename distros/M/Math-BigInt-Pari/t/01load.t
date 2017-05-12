#!perl

use strict;             # restrict unsafe constructs
use warnings;           # enable optional warnings

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::Pari');
    use_ok('Math::BigInt');         # Math::BigInt is required for the tests
};

my @mods = ('Math::BigInt::Pari',
            'Math::BigInt',
            'Math::Pari');

diag("");
diag("Testing with Perl $], $^X");
diag("");
diag(sprintf("%12s %s\n", 'Version', 'Module'));
diag(sprintf("%12s %s\n", '-------', '------'));
for my $mod (@mods) {
    diag(sprintf("%12s %s\n", $mod -> VERSION, $mod));
}

my $pari_ver_exp    = Math::Pari::pari_version_exp();
my $pari_major      = int($pari_ver_exp / 1e6) % 1e3;
my $pari_minor      = int($pari_ver_exp / 1e3) % 1e3;
my $pari_patchlevel =     $pari_ver_exp        % 1e3;
my $pari_ver        = "$pari_major.$pari_minor.$pari_patchlevel";

diag(sprintf("%12s %s\n", $pari_ver, 'PARI'));
diag("");
