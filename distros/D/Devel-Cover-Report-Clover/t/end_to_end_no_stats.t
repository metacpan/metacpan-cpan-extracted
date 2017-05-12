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

my $MULTI_FILE_DB = testcover::run('Empty');

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
                        'classes'             => 0,
                        'complexity'          => 0,
                        'conditionals'        => 0,
                        'coveredconditionals' => 0,
                        'coveredelements'     => 0,
                        'coveredmethods'      => 0,
                        'coveredstatements'   => 0,
                        'elements'            => 0,
                        'files'               => 0,
                        'loc'                 => 0,
                        'methods'             => 0,
                        'ncloc'               => 0,
                        'packages'            => 0,
                        'statements'          => 0
                    },
                    'name'     => $proj_name,
                    'packages' => []
                },
                'version' => $Devel::Cover::Report::Clover::VERSION
            };

            is_deeply( $report, $expect, $t );
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

plan tests => scalar @test;

$_->() foreach @test;

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}

