#!perl

use strict;
use warnings;

use Test::More;
use Test::Directory;
use Module::Runtime qw/use_module/;

use ExtUtils::BundleMaker;

my $dir = Test::Directory->new("t/inc");
my $bm;

$bm = ExtUtils::BundleMaker->new(
    modules => ["Test::WriteVariants"],
    target  => "t/inc/t-wv.inc"
);
$bm->make_bundle();

$dir->has("t-wv.inc");

$bm = ExtUtils::BundleMaker->new(
    modules => ["Test::WriteVariants=0.005"],
    target  => "t/inc/t-wv-p.inc",
    recurse => "v5.8"
);
$bm->make_bundle();

$dir->has("t-wv-p.inc");

$bm = ExtUtils::BundleMaker->new(
    modules => { "Test::WriteVariants" => "0.005" },
    target  => "t/inc/t-wv-h.inc",
    recurse => "v5.10"
);
$bm->make_bundle();

$dir->has("t-wv-h.inc");

eval { $bm = ExtUtils::BundleMaker->new( modules => "Test::WriteVariants", target => "t/inc/t-wv-f.inc" ); };
like( $@, qr/Inappropriate format/, "No scalar for module" );

SKIP:
{
    eval { use_module( "Config::AutoConf", "0.27" ); use_module( 'ExtUtils::CBuilder', '0.280216' ); }
      or skip( "More conditions skipped, no recent Config::AutoConf nor ExtUtils::CBuilder", 1 );

    $bm = ExtUtils::BundleMaker->new(
        modules => ["Config::AutoConf"],
        target  => "t/inc/c-ac-p.inc",
        recurse => "v5.10"
    );
    $bm->make_bundle();

    $dir->has("c-ac-p.inc");

    $bm = ExtUtils::BundleMaker->new(
        modules => { "Config::AutoConf" => "0.27" },
        target  => "t/inc/c-ac-h.inc",
        recurse => "v5.14"
    );
    $bm->make_bundle();

    $dir->has("c-ac-h.inc");
}

done_testing();
