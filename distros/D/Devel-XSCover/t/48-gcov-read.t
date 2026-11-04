use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Copy ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Gcov ();

plan skip_all => 'the stand-in scripts are sh' if $^O eq 'MSWin32';

sub slurp { my $f = shift; open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $here = Cwd::getcwd();
my $text = File::Spec->catfile($here, qw(t fixtures gcov llvm helper.gcov.txt));
my $dump = File::Spec->catfile($here, qw(t fixtures flow llvm helper.flow.txt));

my $tmp  = File::Temp->newdir;
my $dist = File::Spec->catdir($tmp, 'dist');
for my $rel (qw(src/helper.c include/spike.h)) {
    my $to = File::Spec->catfile($dist, $rel);
    my ($vol, $d) = File::Spec->splitpath($to);
    File::Path::make_path(File::Spec->catpath($vol, $d, ''));
    File::Copy::copy(File::Spec->catfile($here, 't', 'fixtures', 'spike', $rel), $to) or die "copy $rel: $!";
}
for my $rel (qw(src/helper.gcda src/helper.gcno blib/arch/stale.gcda)) {
    my $path = File::Spec->catfile($dist, $rel);
    my ($vol, $d) = File::Spec->splitpath($path);
    File::Path::make_path(File::Spec->catpath($vol, $d, ''));
    open my $fh, '>', $path or die "$path: $!";
    close $fh;
}
my $log  = File::Spec->catfile($tmp, 'calls.txt');
my $gcov = XSCoverTest::fake_script($tmp, 'fake-llvm-cov', "echo \"\$@\" >> '$log'\ncase \"\$1\" in\n--dump) cat '$dump' >&2 ;;\n*) cat '$text' ;;\nesac");

my $out = '';
my @objects;
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    @objects = Devel::XSCover::Gcov->new(dir => $dist, gcov => [$gcov], flow => 'llvm', ignore => ['^include/'])->read;
    select $old;
}
is($out, "xs_cover: running $gcov -abct -o src/helper.gcda helper\n"
    . "xs_cover: running $gcov --dump -n -o src/helper.gcda helper\n"
    . "xs_cover: read 1 object\n", 'gcov then the flow graph for the one counter file, and the count in the singular');
is_deeply([ split /\n/, slurp($log) ], ['-abct -o src/helper.gcda helper', '--dump -n -o src/helper.gcda helper'], 'the tool ran twice, the stale counter under blib never read');
is(scalar @objects, 1, 'one object');
is($objects[0]{object}, 'src/helper.gcda', 'named by its counter file');
is_deeply([ sort keys %{ $objects[0]{files} } ], ['src/helper.c'], 'its files after the filter, the header dropped by the ignore pattern');
is_deeply($objects[0]{generated}, {}, 'nothing generated');
is_deeply($objects[0]{files}{'src/helper.c'}{blocks}, [ { line => 5, arms => [1, 1, 1, 0] } ], 'the blocks from the gcov text');
is_deeply($objects[0]{files}{'src/helper.c'}{decisions}, [ { line => 5, arms => [1, 1, 0, 1] } ], 'and the decisions from the graph');
is(Cwd::getcwd(), $here, 'the caller is back where it was');

unlink $log;
is_deeply([ Devel::XSCover::Gcov->new(dir => $dist, silent => 1, dry => 1, gcov => [$gcov], flow => 'llvm')->read ], [], 'a dry read returns no objects');
ok(!-e $log, 'and never runs the tool');

done_testing;
