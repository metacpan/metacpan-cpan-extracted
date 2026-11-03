use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Config;
use Cwd ();
use Test::More;
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover::Build ();
use Devel::XSCover::Test ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');
plan skip_all => 'real builds are skipped on Windows' if $^O eq 'MSWin32';
plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => "no compiler found through $Config{cc}" if Devel::XSCover::Build->new->compiler->{name} eq 'unknown';
plan skip_all => 'set XS_COVER_REAL_TESTS to build and test the spike' unless $ENV{XS_COVER_REAL_TESTS} || $ENV{RELEASE_TESTING};

my $dir = XSCoverTest::copy_spike();
is(Devel::XSCover::Build->new(dir => "$dir", silent => 1)->run, 0, 'the spike builds');

my $test = Devel::XSCover::Test->new(dir => "$dir", silent => 1, plain => ['t/04-threads.t']);
is($test->run, 0, 'the suite passes with the thread test run plain');
ok(-f File::Spec->catfile($dir, 'Spike.gcda'), 'the C counters of Spike.o were written');
ok(-f File::Spec->catfile($dir, 'src', 'helper.gcda'), 'and of src/helper.o');
my $runs = File::Spec->catdir($dir, 'cover_db', 'runs');
ok(-d $runs, 'Devel::Cover wrote its runs into the db under the dir');
opendir my $dh, $runs or die;
my @runs = grep { !/^\./ } readdir $dh;
cmp_ok(scalar @runs, '>=', 3, 'one run per covered test process at least');

my $gcov = Devel::XSCover::Build->new->gcov_command;
my $here = Cwd::getcwd();
chdir $dir;
my $out = `@$gcov -abct -o Spike.gcda Spike.xs 2>/dev/null`;
chdir $here;
like($out, qr/^\s*800002:\s*\d+:\s*RETVAL = a \+ b;/m, 'the thread test counted in full on the C side, run plain');

$test = Devel::XSCover::Test->new(dir => "$dir", silent => 1, delete => 0, test => ['t/01-basic.t']);
is($test->run, 0, 'one file again, keeping the db');
opendir $dh, $runs or die;
cmp_ok(scalar(grep { !/^\./ } readdir $dh), '>', scalar @runs, 'and its run was added');

done_testing;
