use strict;
use Test::More;
use Test::DZil;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/dist' },
        { add_files => {
            'source/dist.ini' => simple_ini('GatherDir', 'MetaJSON', 'Prereqs::FromCPANfile'),
        } },
    );
    $tzil->build;

    my $meta = $tzil->distmeta;

    is_deeply $meta->{prereqs}, {
        runtime => {
            requires => {
                'Plack' => '1.0000', # normalized
                'DBI' => '>= 1, < 2',
            },
        },
        test => {
            requires => {
                'Test::More' => '0.90',
            },
            recommends => {
                'Test::TCP' => '0.2',
            },
        },
    };

    is_deeply $meta->{optional_features}, {
        sqlite => {
            description => 'SQLite support',
            prereqs => {
                runtime => {
                    requires => {
                        'DBD::SQLite' => 0,
                    },
                },
            },
        },
        fastcgi => {
            description => 'fastcgi',
            prereqs => {
                test => {
                    recommends => {
                        'Test::FastCGI' => '1',
                    },
                },
            },
        }
    };
}

done_testing;
