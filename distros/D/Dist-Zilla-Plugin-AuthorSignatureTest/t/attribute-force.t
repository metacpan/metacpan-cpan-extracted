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
                ['AuthorSignatureTest' => {
                    force => '1',
                  }
                ]
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

like $tzil->slurp_file('build/xt/author/signature.t'),
    qr/\QTest::Signature::signature_force_ok();/,
    'xt/author/signature.t content';

$tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                ['GatherDir'],
                ['AuthorSignatureTest' => {
                    force => '0',
                  }
                ]
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

like $tzil->slurp_file('build/xt/author/signature.t'),
    qr/\QTest::Signature::signature_ok();/,
    'xt/author/signature.t content';


done_testing;

