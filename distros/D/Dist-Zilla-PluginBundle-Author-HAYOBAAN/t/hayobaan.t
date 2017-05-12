use strict;
use warnings;
use Test::More 0.96;
use File::pushd qw/tempd/;
use Path::Tiny;

use Test::DZil;

my $corpus = path('corpus/DZT')->absolute;

my $wd = tempd;

my $tzil = Builder->from_config( { dist_root => "$corpus" }, );

ok( $tzil->build, "build dist with \@Author::HAYOBAAN" );

done_testing;
