use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Find ();
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');

my $dir = XSCoverTest::copy_spike();
my %before;
File::Find::find({ no_chdir => 1, wanted => sub { $before{$_} = (stat $_)[9] if -f $_ } }, "$dir");

my $out = '';
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    is(Devel::XSCover->new(dir => "$dir", dry => 1, report => 'text')->run, 0, 'a dry run exits 0');
    select $old;
}
my @lines = grep { /^xs_cover: / } split /\n/, $out;
like($lines[0], qr/^xs_cover: running \S+ Makefile\.PL$/, '1: configure, since the copy has no Makefile');
like($lines[1], qr/^xs_cover: touched 5 source files$/, '2: the touch');
like($lines[2], qr/^xs_cover: running make OPTIMIZE=-O0 -g -fprofile-arcs -ftest-coverage -fprofile-update=atomic(?: -fcondition-coverage)? OTHERLDFLAGS=-fprofile-arcs -ftest-coverage$/, '3: the build');
like($lines[3], qr/^xs_cover: t\/04-threads\.t use threads, which Devel::Cover does not work with, so it runs without it$/, '4: the thread test found');
like($lines[4], qr/^xs_cover: running prove -b -j1 t\/01-basic\.t t\/02-fork\.t t\/03-exit\.t under Devel::Cover$/, '5: the rest under Devel::Cover');
like($lines[5], qr/^xs_cover: running prove -b -j1 t\/04-threads\.t without Devel::Cover$/, '6: the thread test without');
like($lines[6], qr/^xs_cover: read 0 objects$/, '7: no counters in an unbuilt copy');
like($lines[7], qr/^xs_cover: no C counters found, nothing to write$/, '8: nothing to write');
like($lines[8], qr/^xs_cover: running (?:\S+ )*\S*cover -nogcov -report text \S+$/, '9: cover, with its own gcov pass off');
like($lines[9], qr/^xs_cover: removed 0 counter files and touched 5 sources/, '10: the clean-up');
is(scalar @lines, 10, 'ten lines');

my %after;
File::Find::find({ no_chdir => 1, wanted => sub { $after{$_} = (stat $_)[9] if -f $_ } }, "$dir");
is_deeply(\%after, \%before, 'no file changed or appeared');

done_testing;
