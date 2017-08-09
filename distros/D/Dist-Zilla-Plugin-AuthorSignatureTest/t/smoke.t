#!perl

use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use Test::DZil;


my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                ['GatherDir'],
                ['AuthorSignatureTest']
            )
        }
    }
);

$tzil->build;

cmp_deeply(
    $tzil->distmeta,
    superhashof(
        {
            prereqs => {
                develop => {
                    requires => {
                        'Test::Signature' => 0
                    }
                }
            }
        }
    ),
    'Test::Signature develop prereqs'
);

like $tzil->slurp_file('build/xt/author/signature.t'),
    qr/\Qrequire Test::Signature/,
    'xt/author/signature.t content';

done_testing;
