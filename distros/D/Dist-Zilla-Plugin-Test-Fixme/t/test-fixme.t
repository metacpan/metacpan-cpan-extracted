#!perl

use strict;
use warnings;

use Dist::Zilla::Tester;
use Path::Class;
use Test::More tests => 1;

# build fake dist
my $tzil =
  Dist::Zilla::Tester->from_config( { dist_root => dir(qw(t test-fixme)), } );

my $tempdir       = $tzil->tempdir;
my $sourcedir     = $tempdir->subdir('source');
my $builddir      = $tempdir->subdir('build');
my $expected_file = $builddir->subdir('xt')->subdir('release')->file('fixme.t');

chdir $sourcedir;

$tzil->build;

END {    # Remove (empty) dir created by building the dists
    require File::Path;
    my $tmp = $tempdir->parent;
    chdir $tmp->parent;
    File::Path::remove_tree( $tmp, { keep_root => 0 } );
}

ok( -e $expected_file, 'test created' );
