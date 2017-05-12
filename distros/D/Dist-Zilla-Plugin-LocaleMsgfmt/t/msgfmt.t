#!perl

use strict;
use warnings;

use Dist::Zilla     1.093250;
use Dist::Zilla::Tester;
use Path::Class;
use Test::File;
use Test::More      tests => 8;
use Test::Warn;

# build fake repository
my $tzil = Dist::Zilla::Tester->from_config({
  dist_root => dir( qw{ t msgfmt } ),
});

warning_like { $tzil->build } qr/^Skipping invalid path:/, "invalid path gives warning";

my $share = $tzil->root->subdir( "share" );
file_exists_ok( $share->file( "locale1", "basic.mo" ), "1st dir" );
file_exists_ok( $share->file( "locale2", "basic.mo" ), "2nd dir" );

# recursive
file_exists_ok( $share->file( "locale1", "a", "a", "basic.mo" ), "recurse" );
file_exists_ok( $share->file( "locale1", "a", "b", "basic.mo" ), "recurse" );
file_exists_ok( $share->file( "locale1", "b", "a", "basic.mo" ), "recurse" );
file_exists_ok( $share->file( "locale1", "b", "b", "basic.mo" ), "recurse" );
file_exists_ok( $share->file( "locale1", "b",      "basic.mo" ), "recurse" );

