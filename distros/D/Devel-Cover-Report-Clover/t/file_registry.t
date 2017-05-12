#!perl

use Test::More;

use Devel::Cover::Report::Clover::Builder;

use FindBin;
use lib ($FindBin::Bin);
use testcover;

my $DB = testcover::run('multi_file');

my @test = (
    sub {
        my $t = "file_names - 3 items in there";
        my $b = BUILDER( { name => 'test', db => $DB } );

        my $file_registry = $b->file_registry;

        my $got = $file_registry->file_names();

        is( scalar @$got, 3, $t );
    },
    sub {
        my $t = "file_names - list is expected";
        my $b = BUILDER( { name => 'test', db => $DB } );

        my $file_registry = $b->file_registry;

        my $got    = $file_registry->file_names();
        my @expect = $b->db->cover->items;

        is_deeply( $got, \@expect, $t );
    },
    sub {
        my $t = "files - 3 items in there";
        my $b = BUILDER( { name => 'test', db => $DB } );

        my $file_registry = $b->file_registry;

        my $got = $file_registry->files();

        is( scalar @$got, 3, $t );
    },
    sub {
        my $t = "file - get each one individually";
        my $b = BUILDER( { name => 'test', db => $DB } );

        my $file_registry = $b->file_registry;

        my $files = $file_registry->files();
        foreach (@$files) {
            my $got = $file_registry->file($_);
            is( $_, $got->name, "$t - $_" );
        }

    },
    sub {
        my $t = "classes - count";
        my $b = BUILDER( { name => 'test', db => $DB } );

        my $file_registry = $b->file_registry;

        my $classes = $file_registry->classes();

        is( scalar @$classes, 4, $t );

    },

    sub {
        my $t = "packages - count";
        my $b = BUILDER( { name => 'test', db => $DB } );

        my $file_registry = $b->file_registry;

        my $packages = $file_registry->packages();

        is( scalar @$packages, 2, $t );

    },

);

plan tests => scalar @test + ( 3 - 1 );

$_->() foreach @test;

sub BUILDER {
    return Devel::Cover::Report::Clover::Builder->new(shift);
}

