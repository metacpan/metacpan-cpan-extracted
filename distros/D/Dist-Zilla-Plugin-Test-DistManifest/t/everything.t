use strict;
use warnings;
use Test::More 0.96 tests => 1;
use autodie;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZ1' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                ('GatherDir', 'Test::DistManifest')
            ),
        },
    },
);
$tzil->build;

my @xtests = map $_->name =~ m{^xt/} ? $_->name : (), @{ $tzil->files };
ok(
    (grep { $_ eq 'xt/release/dist-manifest.t' } @xtests),
    'dist-manifest.t exists'
) or diag explain \@xtests;
