#!perl

use Test::More;
use Devel::Cover::Report::Clover::Builder;

use FindBin;
use lib ($FindBin::Bin);
use testcover;

my $DB = testcover::run('multi_file');

my $b        = BUILDER( { name => 'test', db => $DB, include_condition_criteria => 0 } );
my $proj     = $b->project;
my @packages = @{ $proj->packages };
my $package  = $proj->package('');

my @test = (
    sub {
        my $t = "packages - count";
        is( scalar @packages, 2, $t );
    },
    sub {
        my $t       = "package - single item found";
        my $package = $proj->package('');
        ok( $package, $t );
    },
    sub {
        my $t       = "package - single item found with no args";
        my $package = $proj->package();
        ok( $package, $t );
    },
    sub {
        my $t       = "package - undef";
        my $package = $proj->package('adfasf');
        is( $package, undef, $t );
    },
    sub {
        my $t       = "classes - count";
        my $package = $proj->package('');
        my @classes = @{ $package->classes };
        is( scalar @classes, 1, $t );
    },
    sub {
        my $t        = "filename";
        my $package  = $proj->package('');
        my $filename = $package->files()->[0]->filename();
        is( $filename, 'MultiFile.pm', $t );
    },
    sub {
        my $t       = "summarize";
        my $package = $proj->package('MultiFile');
        my $s       = $package->summarize()->{total};

        is( $s->{covered}, 14, "$t - covered value" );
        is( $s->{total},   24, "$t - total value" );

    },
    sub {
        my $t       = "metrics - criteria(branch)";
        my $package = $proj->package('MultiFile');
        my $s       = $package->metrics;

        my $expect = {
            'classes'             => 3,
            'complexity'          => 0,
            'conditionals'        => 2,
            'coveredconditionals' => 0,
            'coveredelements'     => 14,
            'coveredmethods'      => 4,
            'coveredstatements'   => 10,
            'elements'            => 22,
            'files'               => 3,
            'loc'                 => 8,
            'methods'             => 5,
            'ncloc'               => 26,
            'statements'          => 15
        };

        is_deeply( $s, $expect, $t );

    },
    sub {
        my $t       = "metrics - criteria(branch+conditional)";
        my $b       = BUILDER( { name => 'test', db => $DB, include_condition_criteria => 1 } );
        my $proj    = $b->project;
        my $package = $proj->package('MultiFile');
        my $s       = $package->metrics;

        my $expect = {
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
        };

        is_deeply( $s, $expect, $t );

    },
);

plan tests => scalar @test + 1;

$_->() foreach @test;

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}

