use strict;
use warnings;
use Test::More 0.96 tests => 2;
use Test::Output;
use autodie;
use Test::DZil;

my $tzil;

stderr_like(
    sub {
        $tzil = Builder->from_config(
            { dist_root => 'corpus/DZ1' },
            { add_files => {
                'source/dist.ini' => simple_ini('GatherDir', 'DistManifestTests')
                }
            },
        );
    },
    qr/^!!!.*deprecate/m,
    'Got a deprecation warning'
);

$tzil->build;

my @xtests = map $_->name =~ m{^xt/} ? $_->name : (), @{ $tzil->files };
ok(
    (grep { $_ eq 'xt/release/dist-manifest.t' } @xtests),
    'dist-manifest.t exists'
) or diag explain \@xtests;
