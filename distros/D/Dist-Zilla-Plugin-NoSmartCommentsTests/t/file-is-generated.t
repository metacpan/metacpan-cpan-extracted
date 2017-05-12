use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZ1' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                ('GatherDir', 'Test::NoSmartComments')
            ),
        },
    },
);
$tzil->build;

my $count = map { $_->name eq 'xt/release/no-smart-comments.t' ? $_ : () } @{ $tzil->files };
ok $count => 'no-smart-comments.t exists';

done_testing;
