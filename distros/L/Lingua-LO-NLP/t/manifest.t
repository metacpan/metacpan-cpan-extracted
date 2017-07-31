#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
## no critic(Lax::ProhibitStringyEval::ExceptForRequire, BuiltinFunctions::ProhibitStringyEval)
eval "use Test::CheckManifest $min_tcm; 1" // plan skip_all => "Test::CheckManifest $min_tcm required";

ok_manifest({
        exclude => [ qw# /.git /.gitignore /local /cover_db /release # ],
        filter => [ qr/\.sw[pqr]$/, qr/\.old$/, qr/\.tar.(?:bz2|gz|)$/ ],
    }
);

