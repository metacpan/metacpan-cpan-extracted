#!perl

BEGIN {
    $MOCKTIME = 0;
    eval {
        require Test::MockTime;
        $MOCKTIME = 1;
    };
}

use Test::Exception;
use Test::MockObject::Extends;
use Test::More;
use Devel::Cover::Report::Clover::Builder;

use FindBin;
use lib ($FindBin::Bin);
use testcover;

my $EMPTY_DB = testcover::run('Empty');

my @test = (
    sub {
        my $t        = "accept_criteria - array exists and has items in it";
        my @criteria = Devel::Cover::Report::Clover::Builder->accept_criteria();

        ok( scalar @criteria > 0, $t );
    },
    sub {
        my $t = "template_dir - returns valid folder";

        my $ret = Devel::Cover::Report::Clover::Builder::template_dir();

        ok( -d $ret, $t );
    },
    sub {
        my $t = "template_file - which template file to use";

        my $ret    = Devel::Cover::Report::Clover::Builder::template_file();
        my $expect = 'clover.tt';

        is( $ret, $expect, $t );
    },
    sub {
        my $t = "new - file registry object created";

        my $b = BUILDER( { name => 'test', db => $EMPTY_DB } );
        ok( $b->file_registry, $t );
    },
    sub {
        my $t = "new - project created";

        my $b = BUILDER( { name => 'test', db => $EMPTY_DB } );
        ok( $b->project, $t );
    },
    sub {
        my $expect = 'test';
        my $t      = "new - project created - name is $expect";

        my $b = BUILDER( { name => $expect, db => $EMPTY_DB } );
        is( $b->project->name, $expect, $t );
    },
    sub {
        my $t = 'include_condition_criteria - not specified defaults to true';
        my $b = BUILDER( { db => $EMPTY_DB } );
        ok( $b->include_condition_criteria, $t );
    },
    sub {
        my $t = "include_condition_criteria - set to '0' turns it off";
        my $b = BUILDER( { db => $EMPTY_DB, include_condition_criteria => 0 } );
        is( $b->include_condition_criteria, 0, $t );
    },
    sub {
        my $t = "include_condition_criteria - set to undef defaults to true";
        my $b = BUILDER( { db => $EMPTY_DB, include_condition_criteria => undef } );
        ok( $b->include_condition_criteria, $t );
    },
    sub {
        my $t = "generate - no file specified should die";
        my $b = BUILDER( { db => $EMPTY_DB } );

        dies_ok( sub { $b->generate() }, $t );
    },
    sub {
        my $t = "generate - bad file specified should die";
        my $b = BUILDER( { db => $EMPTY_DB } );

        dies_ok( sub { $b->generate('.') }, $t );
    },
    sub {
        my $t = "report_xml - template toolkit dies on error";
        my $b = Test::MockObject::Extends->new( BUILDER( { db => $EMPTY_DB } ) );
        $b->mock( 'template_file', sub { return ''; } );
        $b->mock( 'report', sub { return {}; } );
        throws_ok( sub { $b->report_xml() }, 'Template::Exception', $t );
    },
    sub {
    SKIP: {
            skip "Test::MockTime is not installed", 1 unless $MOCKTIME;

            my $t = "report - top level structure looks good";

            my $b = BUILDER( { name => 'Project Name', db => $EMPTY_DB } );

            my $project = $b->project;
            $project = Test::MockObject::Extends->new($project);
            $project->mock( 'report', sub { return {} } );
            $b->project($project);

            Test::MockTime::set_fixed_time(123456789);
            my $report = $b->report();
            my $expect = {
                generated_by => 'Devel::Cover::Report::Clover',
                version      => $Devel::Cover::Report::Clover::VERSION,
                generated    => time(),
                project      => $project->report(),

            };
            Test::MockTime::restore_time();

            is_deeply( $report, $expect, $t );
        }

    },

);

plan tests => scalar @test;

$_->() foreach @test;

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}
