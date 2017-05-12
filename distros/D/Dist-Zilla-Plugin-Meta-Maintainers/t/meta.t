use strict;
use warnings;

use JSON::MaybeXS qw( decode_json );
use Test::DZil;
use Test::More;

my @maintainers = (
    'Dave Rolsky <autarch@urth.org>',
    'Jane Schmane <jschmane@example.com>',
);

my $tzil = Builder->from_config(
    { dist_root => 't/test-data/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                {},
                'MakeMaker',
                'MetaConfig',
                'MetaJSON',
                [
                    'Meta::Maintainers' => {
                        maintainer => \@maintainers,
                    },
                ],
            ),
        },
    },
);

$tzil->build;

my $meta = decode_json( $tzil->slurp_file('build/META.json') );
is_deeply(
    $meta->{x_maintainers},
    \@maintainers,
    'maintainers are added to metadata as x_maintainers'
);

done_testing();
