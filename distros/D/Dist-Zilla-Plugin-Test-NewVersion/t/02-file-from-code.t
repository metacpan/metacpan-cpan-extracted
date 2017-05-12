use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Cwd 'getcwd';

# build fake dist
my $tzil = Builder->from_config({
    dist_root => path(qw(t corpus file-from-code)),
});
$tzil->build;

my $build_dir = $tzil->tempdir->subdir('build');
my $file = path($build_dir, 'xt', 'release', 'new-version.t');
ok( -e $file, 'test created');

my $contents = $file->slurp;
like($file->slurp, qr/"\Q$_\E"/, "test checks the $_ module")
    foreach map { quotemeta } qw(
        lib/Foo.pm
        lib/ExtUtils/MakeMaker.pm
    );

# run the tests

my $cwd = getcwd;
chdir $build_dir;

my $new_lib = path($build_dir, 'lib')->stringify;
unshift @INC, $new_lib;

subtest "running $new_lib..." => sub {
    do $file;
    diag "got error: $@\n" if $@;
};

chdir $cwd;
done_testing;
