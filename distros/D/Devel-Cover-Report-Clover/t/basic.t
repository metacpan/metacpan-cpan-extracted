#!perl

use Test::Exception;
use Test::More;

use FindBin;
use lib ($FindBin::Bin);
use testcover;

use Devel::Cover::Report::Clover;
use Devel::Cover::Report::Clover::Reportable;

my $reportable = Devel::Cover::Report::Clover::Reportable->new();

my $DB = testcover::run('multi_file');

my @test = (
    sub {
        my $t = "output_file - outputdir + outputfile are defined";

        my $dir     = "/dir";
        my $file    = "file.xml";
        my $options = {
            outputdir => $dir,
            option    => { outputfile => $file, }
        };

        my $got    = Devel::Cover::Report::Clover::output_file($options);
        my $expect = "$dir/$file";

        is( $got, $expect, $t );

    },
    sub {
        my $t = "builder - name comes from correct option";

        my $expect = 'test';
        my $o      = { 'option' => { 'projectname' => $expect } };
        my $got    = Devel::Cover::Report::Clover::builder( $DB, $o )->name;

        is( $got, $expect, $t );
    },
    sub {
        my $t = "builder - db param comes from first param correctly";

        my $expect = $DB;
        my $o      = {};
        my $got    = Devel::Cover::Report::Clover::builder( $expect, $o )->db;

        is( $got, $expect, $t );
    },
    sub {
        my $t = "builder - include_condition_criteria is on by default";

        my $expect = 1;
        my $o      = {};
        my $b      = Devel::Cover::Report::Clover::builder( $DB, {} );
        my $got    = $b->include_condition_criteria;

        is( $got, $expect, $t );
    },
    sub {
        my $t = "reportable->report - dies";
        throws_ok( sub { $reportable->report() }, '/implement/', $t );
    },
    sub {
        my $t = "reportable->summarize - dies";
        throws_ok( sub { $reportable->summarize() }, '/implement/', $t );
    },
    sub {
        my $t = "reportable->metrics - dies";
        throws_ok( sub { $reportable->metrics() }, '/implement/', $t );
    },
);

plan tests => scalar @test;

$_->() foreach @test;

