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

plan skip_all => 'shell scripts stand in for make, gcov and cover here' if $^O eq 'MSWin32';
delete local @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};

my $dir = File::Temp->newdir;
my $abs = Cwd::abs_path("$dir");
for my $rel (qw(Makefile.PL Makefile Foo.xs lib/Foo.pm)) {
    my $path = File::Spec->catfile($abs, $rel);
    my ($vol, $d) = File::Spec->splitpath($path);
    File::Path::make_path(File::Spec->catpath($vol, $d, ''));
    open my $fh, '>', $path or die "$path: $!";
    close $fh;
}
my $log = File::Spec->catfile($abs, 'log');
my $record = "echo \"\$(basename \$0) \$@\" >> $log";
my $make  = XSCoverTest::fake_script($abs, 'fake-make', "$record\n[ \"\$1\" = test ] && { touch Foo.gcda; exit 3; }\nexit 0");
my $gcov  = XSCoverTest::fake_script($abs, 'fake-gcov', "$record\ncase \"\$*\" in *--version*) ;; *) printf '%s\\n' '        -:    0:Source:/elsewhere/other.c' '        1:    1:int x;' ;; esac\nexit 0");
my $cover = XSCoverTest::fake_script($abs, 'fake-cover', "$record\nexit 0");
my $cover_fail = XSCoverTest::fake_script($abs, 'fake-cover-fail', "$record\nexit 1");
sub log_lines { open my $fh, '<', $log or return (); my @l = <$fh>; chomp @l; unlink $log; @l }

my ($out, $status, @warn);
sub run_it {
    my (%opt) = @_;
    $out = '';
    @warn = ();
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    $status = Devel::XSCover->new(dir => $abs, make => $make, gcov => $gcov, cover => $cover, %opt)->run;
    select $old;
}

run_it();
is($status, 3, 'the exit status is the tests\' when they fail');
is_deeply(\@warn, ["xs_cover: the tests failed with status 3, reporting what ran\n"], 'which is said, and the run goes on');
my @log = log_lines();
is($log[1], 'fake-make test', 'the tests ran');
like($log[3], qr/^fake-gcov -abct (?:--conditions )?-o Foo\.gcda Foo$/, 'the counter file they left is read');
is($log[4], "fake-cover -nogcov -report XSCover $abs/cover_db", 'and cover runs on what there is');
like($out, qr/^xs_cover: read 1 object$/m, 'one object read');
like($out, qr/^xs_cover: no C counters found, nothing to write$/m, 'whose only source is outside the distribution, so nothing is written');
like($out, qr/^xs_cover: removed 1 counter file and touched 1 source, so the next make rebuilds without coverage$/m, 'the clean-up in the singular');
ok(!-f File::Spec->catfile($abs, 'Foo.gcda'), 'the counter file is gone');

run_it(cover => $cover_fail);
is($status, 3, 'a failing cover does not change the exit status');
is_deeply(\@warn, ["xs_cover: the tests failed with status 3, reporting what ran\n", "xs_cover: cover exited with status 1\n"], 'but is said');

run_it(cover => File::Spec->catfile($abs, 'no-such-cover'));
is($warn[1], "xs_cover: cover exited with status 127\n", 'a cover that cannot be run is 127');

my $missing = File::Spec->catdir($abs, 'missing');
ok(!eval { Devel::XSCover->new(dir => $missing, cover => $cover, silent => 1)->report('cover_db'); 1 }, 'the report dies when the directory is not there');
like($@, qr/^xs_cover: cannot chdir to \Q$missing\E: /, 'saying so');

done_testing;
