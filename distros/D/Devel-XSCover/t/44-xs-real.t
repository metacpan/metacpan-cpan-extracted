use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Config;
use Test::More;
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover::Build ();
use Devel::XSCover::XS ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');
plan skip_all => 'real builds are skipped on Windows' if $^O eq 'MSWin32';
plan skip_all => "no compiler found through $Config{cc}" if Devel::XSCover::Build->new->compiler->{name} eq 'unknown';
plan skip_all => 'set XS_COVER_REAL_TESTS to build the spike' unless $ENV{XS_COVER_REAL_TESTS} || $ENV{RELEASE_TESTING};

my $dir = XSCoverTest::copy_spike();
is(Devel::XSCover::Build->new(dir => "$dir", silent => 1)->run, 0, 'the spike builds');
my $xs = Devel::XSCover::XS->new(dir => "$dir");
my @maps = $xs->read;
is(scalar @maps, 1, 'one generated file');
is($maps[0]{c}, 'Spike.c', 'Spike.c');
my %line = map { $_->{names}[0] => $_->{line} } $xs->subroutines($maps[0]);
is($line{'Spike::add'}, 20, 'add on 20 from the freshly generated c');
is($line{'Spike::More::triple'}, 4, 'triple on 4');
is(scalar keys %line, 11, 'eleven XSUBs');

done_testing;
