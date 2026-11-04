use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Find ();
use File::Path ();
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');

my $dir = XSCoverTest::copy_spike();
open my $gcda, '>', File::Spec->catfile($dir, 'Spike.gcda') or die;
close $gcda;
File::Path::make_path(File::Spec->catdir($dir, 'cover_db.gcov'));
open my $saved, '>', File::Spec->catfile($dir, 'cover_db.gcov', 'Spike.gcov.txt') or die;
close $saved;
my %before;
File::Find::find({ no_chdir => 1, wanted => sub { $before{$_} = (stat $_)[9] if -f $_ } }, "$dir");

my $out = '';
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    is(Devel::XSCover->new(dir => "$dir", dry => 1, report => 'text', gcov => 'no-such-gcov')->run, 0, 'a dry run exits 0');
    select $old;
}
my @lines = grep { /^xs_cover: / } split /\n/, $out;
like($lines[0], qr/^xs_cover: running \S+ Makefile\.PL$/, '1: configure, since the copy has no Makefile');
like($lines[1], qr/^xs_cover: touched 5 source files$/, '2: the touch');
like($lines[2], qr/^xs_cover: running make OPTIMIZE=-O0 -g -fprofile-arcs -ftest-coverage -fprofile-update=atomic(?: -fcondition-coverage)? OTHERLDFLAGS=-fprofile-arcs -ftest-coverage$/, '3: the build');
like($lines[3], qr/^xs_cover: removed 1 stale counter file left by an earlier run$/, '4: the counter file of an earlier run would go');
like($lines[4], qr/^xs_cover: t\/04-threads\.t use threads, which Devel::Cover does not work with, so it runs without it$/, '5: the thread test found');
like($lines[5], qr/^xs_cover: running prove -b -j1 t\/01-basic\.t t\/02-fork\.t t\/03-exit\.t under Devel::Cover$/, '6: the rest under Devel::Cover');
like($lines[6], qr/^xs_cover: running prove -b -j1 t\/04-threads\.t without Devel::Cover$/, '7: the thread test without');
like($lines[7], qr/^xs_cover: running no-such-gcov -abct (?:--conditions )?-o Spike\.gcda Spike$/, '8: gcov on the counter file, which a dry run has not removed');
like($lines[8], qr/^xs_cover: read 0 objects$/, '9: no gcov text in a dry run');
like($lines[9], qr/^xs_cover: no C counters found, nothing to write$/, '10: nothing to write');
like($lines[10], qr/^xs_cover: running (?:\S+ )*\S*cover -nogcov -report text \S+$/, '11: cover, with its own gcov pass off');
like($lines[11], qr/^xs_cover: removed 1 counter file and touched 5 sources/, '12: the clean-up');
is(scalar @lines, 12, 'twelve lines');

my %after;
File::Find::find({ no_chdir => 1, wanted => sub { $after{$_} = (stat $_)[9] if -f $_ } }, "$dir");
is_deeply(\%after, \%before, 'no file changed or appeared');
ok(-f File::Spec->catfile($dir, 'Spike.gcda'), 'the counter file is still there');
ok(-f File::Spec->catfile($dir, 'cover_db.gcov', 'Spike.gcov.txt'), 'and the saved gcov text');

done_testing;
