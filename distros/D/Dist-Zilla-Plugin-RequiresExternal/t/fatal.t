#!/usr/bin/env perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use English '-no_match_vars';
use Test::Most tests => 3;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 1 },
    {   add_files => {
            'source/dist.ini' => simple_ini(
                ['@Basic'],
                [   RequiresExternal => {
                        fatal    => 1,
                        requires => ['this_is_supposed_to_fail'],
                    },
                ],
            ),
            'source/lib/DZT/Sample.pm' => <<'END_SAMPLE_PM',
package DZT::Sample;
# ABSTRACT: Sample package
1;
END_SAMPLE_PM
        },
    },
);

lives_ok( sub { $tzil->build() }, 'build' );
ok( ( grep { $ARG->name eq 't/000-requires_external.t' } @{ $tzil->files } ),
    'test script added'
);
dies_ok( sub { $tzil->run_tests_in( $tzil->built_in ) }, 'test' );
