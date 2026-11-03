use 5.020;
use strict;
use warnings;
use Config;
use Test::More;
use lib 't/lib';
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover::Build ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');
plan skip_all => 'real builds are skipped on Windows' if $^O eq 'MSWin32';
my $cc = Devel::XSCover::Build->new->compiler;
plan skip_all => "no compiler found through $Config{cc}" if $cc->{name} eq 'unknown';
plan skip_all => 'set XS_COVER_REAL_TESTS to build the spike' unless $ENV{XS_COVER_REAL_TESTS} || $ENV{RELEASE_TESTING};

my $dir = XSCoverTest::copy_spike();

my $build = Devel::XSCover::Build->new(dir => "$dir", silent => 1);
is($build->run, 0, 'the spike builds with the coverage flags');
ok(-f File::Spec->catfile($dir, 'Spike.gcno'), 'Spike.gcno beside Spike.o');
ok(-f File::Spec->catfile($dir, 'src', 'helper.gcno'), 'src/helper.gcno beside src/helper.o');
ok(-f File::Spec->catfile($dir, 'blib', 'arch', 'auto', 'Spike', "Spike.$Config{dlext}"), 'the bundle is linked');
ok(!-f File::Spec->catfile($dir, 'Spike.gcda'), 'no counters before any test ran');

is($build->run, 0, 'a second run rebuilds without complaint');
ok(!$build->needs_configure, 'the Makefile is fresh after it');

done_testing;
