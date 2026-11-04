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

my $here     = Cwd::getcwd();
my $fixture  = File::Spec->catfile($here, qw(t fixtures gcov llvm helper.gcov.txt));
my $expected = slurp($fixture);

my $tmp  = File::Temp->newdir;
my $dist = File::Spec->catdir($tmp, 'dist');
File::Path::make_path(File::Spec->catdir($dist, 'src'));
my $log  = File::Spec->catfile($tmp, 'calls.txt');
my $gcov = XSCoverTest::fake_script($tmp, 'fake-gcov', "pwd >> '$log'\necho \"\$@\" >> '$log'\ncat '$fixture'");

my $reader = Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcov]);
is($reader->run_gcov('src/helper.gcda'), $expected, 'the text the tool printed comes back whole');
is_deeply([ split /\n/, slurp($log) ], [ Cwd::abs_path($dist), '-abct -o src/helper.gcda helper' ],
    'the tool ran inside the dist directory, on the counter file by its relative path and the object by its stem');
is(Cwd::getcwd(), $here, 'and the caller is back where it was');
ok(!-e File::Spec->catfile($dist, 'cover_db'), 'nothing is saved unless asked');

my $save = File::Spec->catdir($tmp, 'keep', 'gcov');
Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcov], save => $save)->run_gcov('src/helper.gcda');
is(slurp(File::Spec->catfile($save, 'src#helper.gcov.txt')), $expected, 'with save, the text is kept under the flattened object path, the directory made on the way');

my $mute = XSCoverTest::fake_script($tmp, 'fake-mute', ':');
ok(!eval { Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$mute])->run_gcov('src/helper.gcda'); 1 }, 'a tool that prints nothing is an error');
is($@, "xs_cover: $mute -abct -o src/helper.gcda helper produced nothing in $dist\n", 'which names the command and the directory');
is(Cwd::getcwd(), $here, 'the caller is back where it was after the failure too');

my $missing = File::Spec->catfile($tmp, 'no-such-gcov');
ok(!eval { Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$missing])->run_gcov('src/helper.gcda'); 1 }, 'a tool that is not there is the same error');
is($@, "xs_cover: $missing -abct -o src/helper.gcda helper produced nothing in $dist\n", 'naming the path that could not run');

{
    no warnings 'redefine';
    local *Devel::XSCover::Gcov::_capture = sub { undef };
    ok(!eval { Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcov])->run_gcov('src/helper.gcda'); 1 }, 'a pipe that cannot be opened is an error');
    is($@, "xs_cover: $gcov -abct -o src/helper.gcda helper produced nothing in $dist\n", 'reported as the tool producing nothing');
}

my $gone = File::Spec->catdir($tmp, 'gone');
ok(!eval { Devel::XSCover::Gcov->new(dir => $gone, silent => 1, gcov => [$gcov])->run_gcov('src/helper.gcda'); 1 }, 'a dist directory that is not there is an error');
like($@, qr/^xs_cover: cannot chdir to \Q$gone\E: .+\n\z/, 'before the tool runs');
is(Cwd::getcwd(), $here, 'and the caller has not moved');

my $blocked = File::Spec->catdir($tmp, 'blocked');
File::Path::make_path(File::Spec->catdir($blocked, 'src#helper.gcov.txt'));
ok(!eval { Devel::XSCover::Gcov->new(dir => $dist, silent => 1, gcov => [$gcov], save => $blocked)->run_gcov('src/helper.gcda'); 1 }, 'a save file that cannot be written is an error');
like($@, qr/^xs_cover: cannot write \Q$blocked\E\/src#helper\.gcov\.txt: .+\n\z/, 'naming the file');

done_testing;
