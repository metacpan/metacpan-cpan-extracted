use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Copy ();
use File::Find ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover ();

plan skip_all => 'shell scripts stand in for make, gcov and cover here' if $^O eq 'MSWin32';
plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
delete local @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};

my $fixture = File::Spec->catdir(qw(t fixtures spike));
my $gcov_text = Cwd::abs_path(File::Spec->catdir(qw(t fixtures gcov llvm)));
my $dir = File::Temp->newdir;
my $abs = Cwd::abs_path("$dir");
File::Find::find({
    no_chdir => 1,
    wanted   => sub {
        return unless -f $_;
        my $to = File::Spec->catfile($abs, File::Spec->abs2rel($_, $fixture));
        my ($vol, $d) = File::Spec->splitpath($to);
        File::Path::make_path(File::Spec->catpath($vol, $d, ''));
        File::Copy::copy($_, $to) or die "copy $_: $!";
    },
}, $fixture);
for my $rel (qw(Makefile.PL Makefile old.gcda src/old.gcda)) {
    open my $fh, '>', File::Spec->catfile($abs, $rel) or die "$rel: $!";
    close $fh;
}
my $log = File::Spec->catfile($abs, 'log');
my $record = "echo \"\$(basename \$0) \$@\" >> $log";
my $make  = XSCoverTest::fake_script($abs, 'fake-make', "$record\n[ \"\$1\" = test ] && touch Spike.gcda Spike.gcno src/helper.gcda\nexit 0");
my $cover = XSCoverTest::fake_script($abs, 'fake-cover', "$record\nexit 0");
my $gcov  = XSCoverTest::fake_script($abs, 'fake-gcov', <<"SH");
$record
case "\$*" in
    *--version*) ;;
    *Spike*) cat $gcov_text/Spike.gcov.txt ;;
    *helper*) cat $gcov_text/helper.gcov.txt ;;
esac
exit 0
SH
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
is($status, 0, 'a run whose tests write counters exits 0');
is_deeply(\@warn, [], 'without a warning');
like($out, qr/^xs_cover: removed 2 stale counter files left by an earlier run$/m, 'the counter files of an earlier run go before the tests');
my @log = log_lines();
like($log[0], qr/^fake-make OPTIMIZE=/, 'the build');
is($log[1], 'fake-make test', 'the tests');
is($log[2], "fake-gcov --version", 'the gcov tool asked for its flow graph kind');
like($log[3], qr/^fake-gcov -abct (?:--conditions )?-o Spike\.gcda Spike$/, 'then gcov on the first counter file, from the directory');
like($log[4], qr/^fake-gcov -abct (?:--conditions )?-o src\/helper\.gcda helper$/, 'and on the second, named by its stem');
is($log[5], "fake-cover -nogcov -report XSCover $abs/cover_db", 'then cover on the database');
is(scalar @log, 6, 'and nothing else');
like($out, qr/^xs_cover: read 2 objects$/m, 'two objects read');
like($out, qr/^xs_cover: writing 4 files, 41 statements, 14 branches, 16 subroutines to \Q$abs\E\/cover_db\/runs\/\d+\.\d+\.\d+$/m, 'the four sources of the fixture written as one run');
unlike($out, qr/no C counters found/, 'so the counters were found');
like($out, qr/^xs_cover: removed 3 counter files and touched 4 sources, so the next make rebuilds without coverage$/m, 'the clean-up counts the counter files and the graph beside one of them');
my @runs = glob File::Spec->catfile($abs, 'cover_db', 'runs', '*');
is(scalar @runs, 1, 'one run in the database');
ok(-d File::Spec->catdir($abs, 'cover_db', 'structure'), 'with its structure');
ok(!-f File::Spec->catfile($abs, $_), "$_ is removed") for qw(Spike.gcda Spike.gcno src/helper.gcda old.gcda src/old.gcda);
ok(!-d File::Spec->catdir($abs, 'cover_db.gcov'), 'and the saved gcov text with them');

run_it(keep => 1, silent => 1);
is($status, 0, 'a kept, silent run exits 0');
is($out, '', 'and says nothing');
@log = log_lines();
is($log[5], "fake-cover -nogcov -report XSCover -silent $abs/cover_db", 'cover is told to be silent too');
ok(-f File::Spec->catfile($abs, $_), "$_ is kept") for qw(Spike.gcda Spike.gcno src/helper.gcda);
ok(-f File::Spec->catfile($abs, 'cover_db.gcov', 'Spike.gcov.txt'), 'and the gcov text beside the database');
ok(-f File::Spec->catfile($abs, 'cover_db.gcov', 'src#helper.gcov.txt'), 'flattened by name');
@runs = glob File::Spec->catfile($abs, 'cover_db', 'runs', '*');
is(scalar @runs, 1, 'the database was started afresh');

done_testing;
