#!perl

use Test::More;
use Devel::Cover::Report::Clover::Builder;

use FindBin;
use lib ($FindBin::Bin);
use testcover;

my $DB = testcover::run('multi_file');

my $b     = BUILDER( { name => 'test', db => $DB, include_condition_criteria => 0 } );
my $p     = $b->project;
my @files = @{ $p->files };

my @test = (
    sub {
        my $t = "files - 3 of them";
        is( scalar @files, 3, $t );
    },
    sub {
        my $t = "loc";
        is( $p->loc(), 17, $t );
    },
    sub {
        my $t = "ncloc";
        is( $p->ncloc(), 34, $t );
    },
    sub {
        my $t      = "metrics - criteria(branch)";
        my $s      = $p->metrics;
        my $expect = {
            'classes'             => 4,
            'complexity'          => 0,
            'conditionals'        => 2,
            'coveredconditionals' => 0,
            'coveredelements'     => 25,
            'coveredmethods'      => 7,
            'coveredstatements'   => 18,
            'elements'            => 33,
            'files'               => 3,
            'loc'                 => 17,
            'methods'             => 8,
            'ncloc'               => 34,
            'packages'            => 2,
            'statements'          => 23
        };

        is_deeply( $s, $expect, $t );
    },
    sub {
        my $t = "metrics - criteria(branch+conditional)";

        my $b      = BUILDER( { name => 'test', db => $DB, include_condition_criteria => 1 } );
        my $p      = $b->project;
        my $s      = $p->metrics;
        my $expect = {
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
        };

        is_deeply( $s, $expect, $t );
    },
);

plan tests => scalar @test;

$_->() foreach @test;

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}

