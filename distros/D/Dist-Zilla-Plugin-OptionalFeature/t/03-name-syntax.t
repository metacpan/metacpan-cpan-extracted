use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::CPAN::Meta::JSON::Version;
use Test::DZil;
use Path::Tiny;

use Config::MVP::Reader::INI 2.101461;  # for spaces in section names

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ OptionalFeature => 'Feature Name' => {
                            -description => 'feature description',
                            # use default phase, type
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/invalid syntax for optional feature name 'Feature Name'/,
        'bad feature name is disallowed',
    );

    # we test that this really does violate the spec, so if the spec ever gets
    # changed, we'll know to remove our prohibition.

    my $spec = Test::CPAN::Meta::JSON::Version->new(data => {
        optional_features => {
            'Feature Name' => {
                description => 'feature description',
                prereqs => {
                    runtime => { requires => { A => 0 } },
                },
            },
        },
        prereqs => {
            runtime => { suggests => { A => 0 } },
            develop => { requires => { A => 0 } },
        },
    });

    my $result = $spec->parse;
    my @errors = $spec->errors;
    cmp_deeply(
        \@errors,
        superbagof(re(qr/^\QKey 'Feature Name' is not a legal identifier. (optional_features -> Feature Name) [Validation: 2]\E$/)),
        'metadata is invalid',
    )
    or diag 'got:', join("\n", '', @errors);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
