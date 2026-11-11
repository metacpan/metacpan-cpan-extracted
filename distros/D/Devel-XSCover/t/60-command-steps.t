use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover ();

plan skip_all => 'shell scripts stand in for make and cover here' if $^O eq 'MSWin32';
delete local @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};

my $dir = File::Temp->newdir;
my $abs = Cwd::abs_path("$dir");
my $log = File::Spec->catfile($abs, 'log');
my $record = "echo \"\$(basename \$0) \$@ [\$HARNESS_PERL_SWITCHES]\" >> $log; [ -f Foo.gcda ] && echo stale >> $log; exit 0";
my $make  = XSCoverTest::fake_script($abs, 'fake-make', $record);
my $cover = XSCoverTest::fake_script($abs, 'fake-cover', $record);
for my $rel (qw(Makefile.PL Foo.xs src/a.c lib/Foo.pm)) {
    my $path = File::Spec->catfile($abs, $rel);
    my ($vol, $d) = File::Spec->splitpath($path);
    File::Path::make_path(File::Spec->catpath($vol, $d, ''));
    open my $fh, '>', $path or die "$path: $!";
    print $fh "x\n";
    close $fh;
    utime 1000000000, 1000000000, $path;
}
open my $mf, '>', File::Spec->catfile($abs, 'Makefile') or die;
close $mf;
open my $stale, '>', File::Spec->catfile($abs, 'Foo.gcda') or die;
close $stale;
File::Path::make_path(File::Spec->catdir($abs, 'cover_db', 'runs'));

my $out = '';
my $status;
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    $status = Devel::XSCover->new(dir => $abs, make => $make, cover => "$cover -x")->run;
    select $old;
}
is($status, 0, 'a run over fakes exits 0');
open my $lf, '<', $log or die "no log";
my @log = <$lf>;
chomp @log;
like($log[0], qr/^fake-make OPTIMIZE=-O0 -g -fprofile-arcs -ftest-coverage -fprofile-update=atomic(?: -fcondition-coverage)? OTHERLDFLAGS=-fprofile-arcs -ftest-coverage \[\]$/, 'first the build, without the switches');
is($log[1], 'stale', 'the build step still saw the stale counter file, since the build comes first');
like($log[2], qr/^fake-make test \[(?:-I\S+ )?-MDevel::XSCover::Deparse -MDevel::Cover=-db,\Q$abs\E\/cover_db,-dir,\Q$abs\E,-ignore,\^\/,-ignore,\/Install\/Files\\\.pm\$\]$/, 'then the tests under Devel::Cover with the deparse module first, the stale counter file gone by then');
like($log[3], qr/^fake-cover -x -nogcov -report XSCover \Q$abs\E\/cover_db \[\]$/, 'then cover on the database, with its own gcov pass off');
is(scalar @log, 4, 'and nothing else ran');
like($out, qr/removed 1 stale counter file left by an earlier run/, 'which is said');
ok(!-d File::Spec->catdir($abs, 'cover_db', 'runs'), 'the old database went first');
like($out, qr/touched 2 source files/, 'the touch before the build');
like($out, qr/no C counters found, nothing to write/, 'nothing written without counters');
like($out, qr/removed 0 counter files and touched 2 sources/, 'the clean-up at the end');
cmp_ok((stat File::Spec->catfile($abs, 'Foo.xs'))[9], '>', 1000000000, 'the sources are touched');
is((stat File::Spec->catfile($abs, 'lib', 'Foo.pm'))[9], 1000000000, 'the pm is not');

my $fail = XSCoverTest::fake_script($abs, 'fake-fail', 'exit 2');
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    local $SIG{__WARN__} = sub { $out .= "WARN: $_[0]" };
    $status = Devel::XSCover->new(dir => $abs, make => $fail, cover => $cover, silent => 1)->run;
    select $old;
}
is($status, 2, 'a failed build is the exit status');
like($out, qr/WARN: xs_cover: the build failed with status 2/, 'and is said');

my $c = Devel::XSCover->new;
my @cmd = @{ $c->cover_command };
if (@cmd > 1) {
    is($cmd[0], $^X, 'cover runs under the same perl');
    like($cmd[-1], qr/cover$/, 'and is the cover script');
    my ($inc) = grep { /^-I/ } @cmd;
    ok($inc && -f File::Spec->catfile(substr($inc, 2), qw(Devel Cover Report XSCover.pm)), 'with -I for the directory that holds the report module');
}
else {
    is_deeply(\@cmd, ['cover'], 'no cover beside this perl, so the one on the path');
}
is_deeply(Devel::XSCover->new(cover => 'cover -silent')->cover_command, ['cover', '-silent'], 'the override, split');
is_deeply(Devel::XSCover->new(db => 'elsewhere/db')->skip_dirs, ['blib', '.git', 'db'], 'the db directory is skipped by its last part');

done_testing;
