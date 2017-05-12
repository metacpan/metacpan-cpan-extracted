use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/File/Util.pm',
    'lib/File/Util/Cookbook.pod',
    'lib/File/Util/Definitions.pm',
    'lib/File/Util/Exception.pm',
    'lib/File/Util/Exception/Diagnostic.pm',
    'lib/File/Util/Exception/Standard.pm',
    'lib/File/Util/Interface/Classic.pm',
    'lib/File/Util/Interface/Modern.pm',
    'lib/File/Util/Manual.pod',
    'lib/File/Util/Manual/Examples.pod',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001_canuseit.t',
    't/002_isa.t',
    't/003_can.t',
    't/004_portable.t',
    't/005_ftests.t',
    't/006_io.t',
    't/007_flock.t',
    't/008_export_ok.t',
    't/009_empty_subclass.t',
    't/010_unicode.t',
    't/011_abspaths.t',
    't/012_atomize_path.t',
    't/013_interface_classic.t',
    't/014_interface_modern.t',
    't/015_destroy.t',
    't/016_new.t',
    't/017_make_dir_list_dir.t',
    't/018_list_dir_advancedmatch.t',
    't/019_load_dir.t',
    't/020_write_file.t',
    't/021_list_dir_regression.t',
    't/txt'
);

notabs_ok($_) foreach @files;
done_testing;
