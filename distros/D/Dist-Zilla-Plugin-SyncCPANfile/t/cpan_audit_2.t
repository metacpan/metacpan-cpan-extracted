#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestCPANfile;
use CPAN::Audit::DB;
use Clone qw(clone);

use Dist::Zilla::Plugin::SyncCPANfile;

my $log = '';

{
    no warnings 'redefine';

    sub Dist::Zilla::Plugin::SyncCPANfile::log {
        my ($self, $msg) = @_;

        $log .= $msg . "\n";
    }

    sub CPAN::Audit::DB::db {
        return {
            dists => {
                LikelyNotThere => {
                    advisories => [
                        { id => 1, affected_versions => '<3.1', fixed_versions => '>=3.1' },
                        { id => 2, affected_versions => '<3.7', fixed_versions => '>=3.7' },
                        { id => 3, affected_versions => '<3.8', fixed_versions => undef },
                    ],
                    main_module => 'LikelyNotThere',
                    versions => [
                        { date => '2023-07-01T13:00:00', version => '3.6' },
                        { date => '2023-07-02T13:00:00', version => '3.7' },
                        { date => '2023-07-03T13:00:00', version => '3.8' },
                    ]
                    },
            }, 
            module2dist => {
                LikelyNotThere => 'LikelyNotThere',
            }, 
        };
    }
}

sub test_cpanfile {
    my $desc    = shift;
    my $prereqs = shift;
    my $config  = shift;
    my $tests   = shift;
    my $test    = build_dist( clone( $prereqs ), $config);

    my $content = $test->{cpanfile}->slurp_raw;
    ok check_cpanfile( $content, $prereqs ), $desc;

    for my $regex_test ( @{ $tests || [] } ) {
        for my $regex ( @{ $regex_test->{content} || [] } ) {
            like $content, $regex, "$regex matches content";
        }

        for my $regex ( @{ $regex_test->{log} || [] } ) {
            like $log, $regex, "$regex matches log";
        }
    }
}

test_cpanfile
    'cpan_audit - version range includes fixed version, but lower minimum',
    [
        Prereqs => [ LikelyNotThere => ">3.1, <4.5" ]
    ],
    { cpan_audit => 1 },
    [
        { log => [ qr/Current version range includes vulnerable versions. Consider updating the minimum to 3.7/ ] },
    ]
;

$log = '';
test_cpanfile
    'cpan_audit - version range includes fixed version, fixed version is minimum',
    [
        Prereqs => [ LikelyNotThere => ">=3.7, <4.5" ]
    ],
    { cpan_audit => 1 },
    [
        { log => [ qr/\A\z/ ], },
    ]
;

done_testing;
