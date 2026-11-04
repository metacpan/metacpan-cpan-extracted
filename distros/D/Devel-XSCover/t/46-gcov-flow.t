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
use Devel::XSCover::Gcov ();

plan skip_all => 'the stand-in scripts are sh' if $^O eq 'MSWin32';

sub slurp { my $f = shift; open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

sub said {
    my ($code) = @_;
    my $out = '';
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    $code->();
    select $old;
    return $out;
}

my $here = Cwd::getcwd();
my $dump = File::Spec->catfile($here, qw(t fixtures flow llvm helper.flow.txt));
my $json = File::Spec->catfile($here, qw(t fixtures flow gcc helper.flow.json));

my $tmp  = File::Temp->newdir;
my $dist = File::Spec->catdir($tmp, 'dist');
File::Path::make_path(File::Spec->catdir($dist, 'src'));
my $log  = File::Spec->catfile($tmp, 'calls.txt');
my $llvm = XSCoverTest::fake_script($tmp, 'fake-llvm-cov', "pwd >> '$log'\necho \"\$@\" >> '$log'\necho 'the summary on stdout is not the graph'\ncat '$dump' >&2");
my $gcc  = XSCoverTest::fake_script($tmp, 'fake-gcov', "pwd >> '$log'\necho \"\$@\" >> '$log'\necho 'a note on stderr is not the graph' >&2\ncat '$json'");

my $none = Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$llvm]);
is($none->run_flow('src/helper.gcda'), '', 'without a flow kind there is no graph');
ok(!-e $log, 'and the tool is not run');

is(said(sub { Devel::XSCover::Gcov->new(dir => $dist, dry => 1, gcov => ['llvm-cov', 'gcov'], flow => 'llvm')->run_flow('src/helper.gcda') }),
    "xs_cover: running llvm-cov gcov --dump -n -o src/helper.gcda helper\n", 'llvm is asked for its dump');
is(said(sub { Devel::XSCover::Gcov->new(dir => $dist, dry => 1, gcov => ['gcov-14'], flow => 'gcc', conditions => 1)->run_flow('src/helper.gcda') }),
    "xs_cover: running gcov-14 -abct --json-format --conditions -o src/helper.gcda helper\n", 'gcc for its json, with conditions when they are on');
ok(!-e $log, 'a dry run does not run the tool either');

my $reader = Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$llvm], flow => 'llvm');
is($reader->run_flow('src/helper.gcda'), slurp($dump), 'the llvm dump is read from the error stream, the output stream dropped');
is_deeply([ split /\n/, slurp($log) ], [ Cwd::abs_path($dist), '--dump -n -o src/helper.gcda helper' ], 'run inside the dist directory');
is(Cwd::getcwd(), $here, 'and the caller is back where it was');
unlink $log;

$reader = Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcc], flow => 'gcc');
is($reader->run_flow('src/helper.gcda'), slurp($json), 'the gcc json is read from the output stream, the error stream dropped');
is_deeply([ split /\n/, slurp($log) ], [ Cwd::abs_path($dist), '-abct --json-format -o src/helper.gcda helper' ], 'without conditions when they are off');

my $save = File::Spec->catdir($tmp, 'keep', 'gcov');
Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$llvm], flow => 'llvm', save => $save)->run_flow('src/helper.gcda');
is(slurp(File::Spec->catfile($save, 'src#helper.flow.txt')), slurp($dump), 'the llvm dump is saved as flow.txt beside the gcov text');
Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcc], flow => 'gcc', save => $save)->run_flow('src/helper.gcda');
is(slurp(File::Spec->catfile($save, 'src#helper.flow.json')), slurp($json), 'the gcc json as flow.json');

my $mute = XSCoverTest::fake_script($tmp, 'fake-mute', ':');
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is(Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$mute], flow => 'gcc')->run_flow('src/helper.gcda'), '', 'a tool that gives no graph gives nothing');
}
is_deeply(\@warnings, ["xs_cover: $mute -abct --json-format -o src/helper.gcda helper produced no flow graph in $dist, branches come from gcov's blocks alone\n"],
    'with a warning that says where the branches come from instead');

my $missing = File::Spec->catfile($tmp, 'no-such-llvm-cov');
@warnings = ();
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is(Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$missing], flow => 'llvm')->run_flow('src/helper.gcda'), '', 'a tool that is not there gives nothing');
}
is_deeply(\@warnings, ["xs_cover: $missing --dump -n -o src/helper.gcda helper produced no flow graph in $dist, branches come from gcov's blocks alone\n"],
    'with the same warning');
is(Cwd::getcwd(), $here, 'the caller is back where it was');

@warnings = ();
{
    no warnings 'redefine';
    local *Devel::XSCover::Gcov::_capture_stderr = sub { undef };
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is(Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$llvm], flow => 'llvm')->run_flow('src/helper.gcda'), '', 'a pipe that cannot be opened gives nothing');
}
is_deeply(\@warnings, ["xs_cover: $llvm --dump -n -o src/helper.gcda helper produced no flow graph in $dist, branches come from gcov's blocks alone\n"],
    'with the same warning, the graph being optional');

my $gone =File::Spec->catdir($tmp, 'gone');
ok(!eval { Devel::XSCover::Gcov->new(dir => $gone, silent => 1, gcov => [$llvm], flow => 'llvm')->run_flow('src/helper.gcda'); 1 }, 'a dist directory that is not there is an error');
like($@, qr/^xs_cover: cannot chdir to \Q$gone\E: .+\n\z/, 'before the tool runs');

my $blocked = File::Spec->catdir($tmp, 'blocked');
File::Path::make_path(File::Spec->catdir($blocked, 'src#helper.flow.json'));
ok(!eval { Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcc], flow => 'gcc', save => $blocked)->run_flow('src/helper.gcda'); 1 }, 'a save file that cannot be written is an error');
like($@, qr/^xs_cover: cannot write \Q$blocked\E\/src#helper\.flow\.json: .+\n\z/, 'naming the file');

done_testing;
