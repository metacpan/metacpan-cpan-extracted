#!/usr/bin/perl
# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/
use strict; use warnings;

# DEBUG on
use FindBin qw( $Bin );
use lib $Bin .'/../lib/';
use lib $Bin .'/../blib/';
# DEBUG off

use Devel::CoverReport 0.05;
use Devel::CoverReport::Feedback 0.05;

use Data::Compare;
use English qw( -no_match_vars );
use File::Path 1.07 qw( rmtree );
use File::Slurp qw( read_dir read_file );
use Test::More 0.94;
use YAML::Syck qw( LoadFile );

my @tests = (
    {
        name      => 'Full report',
        reference => 'Full_Report',
        params    => {
            verbose => 0,
            quiet   => 1,
            summary => 0,

            cover_db  => $Bin . q{/Samples/Simple/cover_db-20090919},
            formatter => 'YAML',
            criterion => { 'statement'=>1, 'branch'=>1, 'condition'=>1, 'path'=>1, 'subroutine'=>1, 'pod'=>1, 'time'=>1 },
            report    => { 'summary'=>1, 'index'=>1, 'coverage'=>1, 'runs'=>1, 'run-details'=>1, },

            exclude     => [],
            exclude_dir => [],
            exclude_re  => [],
            include     => [],
            include_dir => [],
            include_re  => [ q{.} ],
            mention     => [],
            mention_dir => [],
            mention_re  => [],
        },
        compare => \&_equals_yml,
    },

    {
        name      => 'Statement coverage report',
        reference => 'Statement_Report',
        params    => {
            verbose => 1,
            quiet   => 0,
            summary => 0,

            cover_db  => $Bin . q{/Samples/Simple/cover_db-20090919},
            formatter => 'YAML',
            criterion => { 'statement'=>1 },
            report    => { 'summary'=>1, 'index'=>1, 'coverage'=>1, 'runs'=>1, 'run-details'=>1, },

            exclude     => [],
            exclude_dir => [],
            exclude_re  => [],
            include     => [],
            include_dir => [],
            include_re  => [ q{.} ],
            mention     => [],
            mention_dir => [],
            mention_re  => [],
        },
        compare => \&_equals_yml,
    },
);

plan tests => 3 * scalar @tests;

# Each test has 3 stages:
#   - creating new Devel::CoverReport object
#   - running make_report()
#   - analising output

if (not -d $Bin .q{/tmp/}) {
    mkdir $Bin .q{/tmp/};
}

my $i = 0;
foreach my $test (@tests) {
    my $output_directory = $Bin .q{/tmp/Devel-CoverReport-t-}. $PID . q{-} . $i++;

#    diag ("Using $output_directory as tmp output.");

    if (-d $output_directory) {
        rmtree($output_directory, { keep_root => 1 });
    }
    else {
        mkdir $output_directory;
    }

    $test->{'params'}->{'output'} = $output_directory;

    my $cover_report = Devel::CoverReport->new( %{ $test->{'params'} } );

    isa_ok($cover_report, 'Devel::CoverReport', $test->{'name'} . q{ (1/3)});

    is ($cover_report->make_report(), 0, $test->{'name'} . q{ (2/3) make_report()});

    my $reference_directory = $Bin . q{/Devel-CoverReport_reference/} . $test->{'reference'};
    
    if (not -d $reference_directory) {
        fail("No reference for diff: ". $test->{'reference'});
        next;
    }

    my @reference_files = read_dir($reference_directory);
    my $diff_failures = 0;
    foreach my $reference_file (@reference_files) {
        if ($reference_file =~ m{^\.}) {
            next;
        }

        if (not -f $output_directory . q{/} . $reference_file) {
            diag("missing: ". $output_directory . q{/} . $reference_file);
            $diff_failures++;
            next;
        }

        # Compare files, using different methods..
        my $equals = $test->{'compare'}->($reference_directory . q{/} . $reference_file, $output_directory    . q{/} . $reference_file);

        if (not $equals) {
            diag("differ: ". $output_directory . q{/} . $reference_file . q{ vs }. $reference_directory . q{/} . $reference_file);
            $diff_failures++;
        }
    }

    is ($diff_failures, 0, $test->{'name'} . q{ (3/3) diff});

    if ($diff_failures == 0) {
        # Delete results only, when test passed.
        #
        # If it failed, or was skipped - User will probably want to inspect them so leave.
        rmtree($output_directory, {} );
    }
}

sub _equals_raw { # {{{
    my ( $file_a, $file_b ) = @_;

    my $reference_data = read_file($file_a);
    my $output_data    = read_file($file_b);

    if ($reference_data eq $output_data) {
        return 1;
    }

    return;
} # }}}

sub _equals_yml { # {{{
    my ( $file_a, $file_b ) = @_;

    my $reference_data = LoadFile($file_a);
    my $output_data    = LoadFile($file_b);

    if (Compare($reference_data, $output_data)) {
        return 1;
    }

    return;
} # }}}

package Devel::CoverReport::Feedback;

no warnings;

sub _print {}

use warnings;

# vim: fdm=marker
