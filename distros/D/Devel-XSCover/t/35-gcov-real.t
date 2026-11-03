use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Config;
use Test::More;
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover::Build ();
use Devel::XSCover::Test ();
use Devel::XSCover::Gcov ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');
plan skip_all => 'real builds are skipped on Windows' if $^O eq 'MSWin32';
plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
my $build = Devel::XSCover::Build->new(silent => 1);
plan skip_all => "no compiler found through $Config{cc}" if $build->compiler->{name} eq 'unknown';
plan skip_all => 'set XS_COVER_REAL_TESTS to build, test and read the spike' unless $ENV{XS_COVER_REAL_TESTS} || $ENV{RELEASE_TESTING};

my $dir = XSCoverTest::copy_spike();
is(Devel::XSCover::Build->new(dir => "$dir", silent => 1)->run, 0, 'the spike builds');
is(Devel::XSCover::Test->new(dir => "$dir", silent => 1, plain => ['t/04-threads.t'])->run, 0, 'and its tests pass');

my $reader = Devel::XSCover::Gcov->new(dir => "$dir", silent => 1, gcov => $build->gcov_command,
    generated => ['Spike.c'], save => File::Spec->catdir($dir, 'cover_db', 'gcov'));
is_deeply([$reader->find_gcda], ['Spike.gcda', 'src/helper.gcda'], 'two counter files');
my @objects = $reader->read;
is(scalar @objects, 2, 'two objects read');
my ($spike, $helper) = @objects;
is($spike->{object}, 'Spike.gcda', 'the Spike object first');
is_deeply([sort keys %{ $spike->{files} }], ['Spike.xs', 'include/spike.h', 'xs/more.xs'], 'its files after the filter: nothing of perl, no ppport.h');
is_deeply([keys %{ $spike->{generated} }], ['Spike.c'], 'the generated c aside');
is($spike->{files}{'Spike.xs'}{lines}{27}, 800002, 'the add line counted in full');
is($spike->{files}{'xs/more.xs'}{lines}{15}, 1, 'the forked child counted');
is($spike->{files}{'xs/more.xs'}{lines}{23}, 0, 'the _exit child not');
is_deeply([sort keys %{ $helper->{files} }], ['include/spike.h', 'src/helper.c'], 'the helper object');
ok(-f File::Spec->catfile($dir, 'cover_db', 'gcov', 'Spike.gcov.txt'), 'the gcov text saved');
ok(-f File::Spec->catfile($dir, 'cover_db', 'gcov', 'src#helper.gcov.txt'), 'with the path flattened');

done_testing;
