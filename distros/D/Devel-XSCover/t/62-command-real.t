use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Config;
use Test::More;
use File::Spec ();
use XSCoverTest ();
use Devel::XSCover ();
use Devel::XSCover::Build ();

plan skip_all => 'the spike dist is not here' unless -f File::Spec->catfile(XSCoverTest::spike_dir(), 'Makefile.PL');
plan skip_all => 'real builds are skipped on Windows' if $^O eq 'MSWin32';
plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => "no compiler found through $Config{cc}" if Devel::XSCover::Build->new->compiler->{name} eq 'unknown';
plan skip_all => 'set XS_COVER_REAL_TESTS to run xs_cover on the spike' unless $ENV{XS_COVER_REAL_TESTS} || $ENV{RELEASE_TESTING};

my $dir = XSCoverTest::copy_spike();
my $out = '';
my $status;
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    $status = Devel::XSCover->new(dir => "$dir", report => 'text', plain => ['t/04-threads.t'])->run;
    select $old;
}
is($status, 0, 'xs_cover on the spike exits 0');
like($out, qr/^xs_cover: writing 4 files, \d+ statements, \d+ branches, 16 subroutines/m, 'four files and sixteen subroutines written');
ok(-d File::Spec->catdir($dir, 'cover_db'), 'the database is there');
ok(!-f File::Spec->catfile($dir, 'Spike.gcda'), 'the counters are removed after the run');
ok(!-f File::Spec->catfile($dir, 'Spike.gcno'), 'and the graphs');
ok(!-d File::Spec->catdir($dir, 'cover_db.gcov'), 'and the saved gcov text');
cmp_ok((stat File::Spec->catfile($dir, 'Spike.xs'))[9], '>=', (stat File::Spec->catfile($dir, 'Spike.o'))[9], 'the sources are newer than the objects again');

my $cover = `cd "$dir" && "$^X" "@{[ (Devel::XSCover->new->cover_command)[0][-1] ]}" -silent -report text cover_db 2>&1`;
like($cover, qr/^Spike\.xs\s+\d+\.\d\s+\d+\.\d\s+(?:n\/a|\d+\.\d)\s+100\.0\s+n\/a\s+n\/a/m, 'the report has the xs with stmt, bran and sub beside the Perl columns, whatever the compiler counts');
like($cover, qr/^blib\/lib\/Spike\.pm\s+100\.0/m, 'and the Perl side from the same run');
like($cover, qr/Spike::plus/, 'the alias');
unlike($cover, qr/^\S*(?:inline\.h|ppport\.h|Spike\.c)\s+(?:\d|n\/a)/m, 'no row for a perl header, ppport.h or the generated c');

{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    $status = Devel::XSCover->new(dir => "$dir", report => 'text', plain => ['t/04-threads.t'], keep => 1, silent => 1)->run;
    select $old;
}
is($status, 0, 'a second run with -keep');
ok(-f File::Spec->catfile($dir, 'Spike.gcda'), 'keeps the counters');
ok(-f File::Spec->catfile($dir, 'cover_db.gcov', 'Spike.gcov.txt'), 'and the gcov text, beside the database');
is($out, '', 'and says nothing when silent');

done_testing;
