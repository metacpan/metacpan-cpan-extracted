use strict;
use warnings;

use Test::More tests => 1;

use Test::DZil;

my $dist_ini = dist_ini({
    name     => 'DZT-Sample',
    abstract => 'Sample DZ Dist',
    author   => 'E. Xavier Ample <example@example.org>',
    license  => 'Perl_5',
    copyright_holder => 'E. Xavier Ample',
    version => '1.0.0',
}, qw/
    GatherDir
    FakeRelease
/,
    [ 'Covenant' => {
        pledge_file => 'FOO',
    } ],
);

my $tzil = Builder->from_config(
    { dist_root => 'corpus' },
    { add_files => {
        'source/dist.ini' => $dist_ini
    },
}
);

$tzil->build;

like $tzil->slurp_file('build/FOO'),
    qr/CPAN Covenant/,
    "Pledge file exists";
