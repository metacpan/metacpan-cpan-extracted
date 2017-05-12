#!perl

BEGIN {
    $MOCKTIME = 0;
    eval {
        require Test::MockTime;
        $MOCKTIME = 1;
    };
}

use Test::More;
use Devel::Cover::Report::Clover::Builder;
use FindBin;
use lib ($FindBin::Bin);
use testcover;

my $MULTI_FILE_DB = testcover::run('multi_file');

my @test = (
    sub {
    SKIP: {
            skip "Test::MockTime is not installed", 1 unless $MOCKTIME;

            my $t = "report - end to end";

            my $proj_name = "Multi File";

            Test::MockTime::set_fixed_time(123456789);
            my $b = BUILDER(
                {   name                       => $proj_name,
                    db                         => $MULTI_FILE_DB,
                    include_condition_criteria => 1
                }
            );

            my $report = $b->report();
            Test::MockTime::restore_time();

            my $expect = {
                'generated'    => 123456789,
                'generated_by' => 'Devel::Cover::Report::Clover',
                'project'      => {
                    'metrics' => {
                        'classes'             => 4,
                        'complexity'          => 0,
                        'conditionals'        => 4,
                        'coveredconditionals' => 0,
                        'coveredelements'     => 25,
                        'coveredmethods'      => 7,
                        'coveredstatements'   => 18,
                        'elements'            => 35,
                        'files'               => 3,
                        'loc'                 => 17,
                        'methods'             => 8,
                        'ncloc'               => 34,
                        'packages'            => 2,
                        'statements'          => 23
                    },
                    'name'     => $proj_name,
                    'packages' => [
                        {   'files' => [
                                {   'classes' => [
                                        {   'metrics' => {
                                                'complexity'          => 0,
                                                'conditionals'        => 0,
                                                'coveredconditionals' => 0,
                                                'coveredelements'     => 11,
                                                'coveredmethods'      => 3,
                                                'coveredstatements'   => 8,
                                                'elements'            => 11,
                                                'loc'                 => 9,
                                                'methods'             => 3,
                                                'ncloc'               => 8,
                                                'statements'          => 8
                                            },
                                            'name'        => 'MultiFile',
                                            'name_dotted' => 'MultiFile',
                                        }
                                    ],
                                    'metrics' => {
                                        'classes'             => 1,
                                        'complexity'          => 0,
                                        'conditionals'        => 0,
                                        'coveredconditionals' => 0,
                                        'coveredelements'     => 11,
                                        'coveredmethods'      => 3,
                                        'coveredstatements'   => 8,
                                        'elements'            => 11,
                                        'loc'                 => 9,
                                        'methods'             => 3,
                                        'ncloc'               => 8,
                                        'statements'          => 8
                                    },
                                    'name'     => 'cover_db_test/multi_file/MultiFile.pm',
                                    'filename' => 'MultiFile.pm'
                                }
                            ],
                            'metrics' => {
                                'classes'             => 1,
                                'complexity'          => 0,
                                'conditionals'        => 0,
                                'coveredconditionals' => 0,
                                'coveredelements'     => 11,
                                'coveredmethods'      => 3,
                                'coveredstatements'   => 8,
                                'elements'            => 11,
                                'files'               => 1,
                                'loc'                 => 9,
                                'methods'             => 3,
                                'ncloc'               => 8,
                                'statements'          => 8
                            },
                            'name'        => 'main',
                            'name_dotted' => 'main'
                        },
                        {   'files' => [
                                {   'classes' => [
                                        {   'metrics' => {
                                                'complexity'          => 0,
                                                'conditionals'        => 4,
                                                'coveredconditionals' => 0,
                                                'coveredelements'     => 8,
                                                'coveredmethods'      => 2,
                                                'coveredstatements'   => 6,
                                                'elements'            => 18,
                                                'loc'                 => 3,
                                                'methods'             => 3,
                                                'ncloc'               => 14,
                                                'statements'          => 11
                                            },
                                            'name'        => 'Sub',
                                            'name_dotted' => 'Sub'
                                        }
                                    ],
                                    'metrics' => {
                                        'classes'             => 1,
                                        'complexity'          => 0,
                                        'conditionals'        => 4,
                                        'coveredconditionals' => 0,
                                        'coveredelements'     => 8,
                                        'coveredmethods'      => 2,
                                        'coveredstatements'   => 6,
                                        'elements'            => 18,
                                        'loc'                 => 3,
                                        'methods'             => 3,
                                        'ncloc'               => 14,
                                        'statements'          => 11
                                    },
                                    'name'     => 'cover_db_test/multi_file/MultiFile.pm',
                                    'filename' => 'MultiFile.pm'
                                },
                                {   'classes' => [
                                        {   'metrics' => {
                                                'complexity'          => 0,
                                                'conditionals'        => 0,
                                                'coveredconditionals' => 0,
                                                'coveredelements'     => 3,
                                                'coveredmethods'      => 1,
                                                'coveredstatements'   => 2,
                                                'elements'            => 3,
                                                'loc'                 => 3,
                                                'methods'             => 1,
                                                'ncloc'               => 6,
                                                'statements'          => 2
                                            },
                                            'name'        => 'First',
                                            'name_dotted' => 'First'
                                        }
                                    ],
                                    'metrics' => {
                                        'classes'             => 1,
                                        'complexity'          => 0,
                                        'conditionals'        => 0,
                                        'coveredconditionals' => 0,
                                        'coveredelements'     => 3,
                                        'coveredmethods'      => 1,
                                        'coveredstatements'   => 2,
                                        'elements'            => 3,
                                        'loc'                 => 3,
                                        'methods'             => 1,
                                        'ncloc'               => 6,
                                        'statements'          => 2
                                    },
                                    'name'     => 'cover_db_test/multi_file/MultiFile/First.pm',
                                    'filename' => 'First.pm'
                                },
                                {   'classes' => [
                                        {   'metrics' => {
                                                'complexity'          => 0,
                                                'conditionals'        => 0,
                                                'coveredconditionals' => 0,
                                                'coveredelements'     => 3,
                                                'coveredmethods'      => 1,
                                                'coveredstatements'   => 2,
                                                'elements'            => 3,
                                                'loc'                 => 2,
                                                'methods'             => 1,
                                                'ncloc'               => 6,
                                                'statements'          => 2
                                            },
                                            'name'        => 'Second',
                                            'name_dotted' => 'Second'
                                        }
                                    ],
                                    'metrics' => {
                                        'classes'             => 1,
                                        'complexity'          => 0,
                                        'conditionals'        => 0,
                                        'coveredconditionals' => 0,
                                        'coveredelements'     => 3,
                                        'coveredmethods'      => 1,
                                        'coveredstatements'   => 2,
                                        'elements'            => 3,
                                        'loc'                 => 2,
                                        'methods'             => 1,
                                        'ncloc'               => 6,
                                        'statements'          => 2
                                    },
                                    'name'     => 'cover_db_test/multi_file/MultiFile/Second.pm',
                                    'filename' => 'Second.pm'
                                }
                            ],
                            'metrics' => {
                                'classes'             => 3,
                                'complexity'          => 0,
                                'conditionals'        => 4,
                                'coveredconditionals' => 0,
                                'coveredelements'     => 14,
                                'coveredmethods'      => 4,
                                'coveredstatements'   => 10,
                                'elements'            => 24,
                                'files'               => 3,
                                'loc'                 => 8,
                                'methods'             => 5,
                                'ncloc'               => 26,
                                'statements'          => 15
                            },
                            'name'        => 'MultiFile',
                            'name_dotted' => 'MultiFile'
                        }
                    ]
                },
                'version' => $Devel::Cover::Report::Clover::VERSION
            };
            ok(delete $report->{project}{packages}[0]{files}[0]{classes}[0]{lines}, 'line reporting 1 (existence checked)');
            ok(delete $report->{project}{packages}[1]{files}[0]{classes}[0]{lines}, 'line reporting 2 (existence checked)');
            ok(delete $report->{project}{packages}[1]{files}[1]{classes}[0]{lines}, 'line reporting 3 (existence checked)');
            ok(delete $report->{project}{packages}[1]{files}[2]{classes}[0]{lines}, 'line reporting 4 (existence checked)');
            is_deeply( $report, $expect, 'deep inspection of rest' );
        }
    },
    sub {
        my $t = "generate - writes xml file";

        my $proj_name = "Multi File";
        my $b         = BUILDER( { name => $proj_name, db => $MULTI_FILE_DB } );
        my $outfile   = testcover::test_path('multi_file') . "/clover-1-$$.xml";
        $b->generate($outfile);

        ok( -f $outfile, $t );
    },

    sub {
        my $t = "report - core report entry point writes file";

        my $proj_name = "Multi File";
        my $o         = {
            'option' => {
                'projectname' => "Project Name",
                'outputfile'  => "clover-2-$$.xml"
            },
            'silent'  => 1,
            outputdir => testcover::test_path('multi_file'),
        };

        Devel::Cover::Report::Clover->report( $MULTI_FILE_DB, $o );
        my $outfile = sprintf( "%s/%s", $o->{outputdir}, $o->{option}{outputfile} );

        ok( -f $outfile, $t );
    },

);

$_->() foreach @test;

done_testing();

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}

