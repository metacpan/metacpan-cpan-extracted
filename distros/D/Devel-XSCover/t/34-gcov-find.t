use 5.020;
use strict;
use warnings;
use Test::More;
use File::Path ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Gcov ();

my $dir = File::Temp->newdir;
for my $rel (qw(Op.gcda Op.gcno src/a.gcda src/b.gcda lib/Math/Basic/XS.gcda cover_db/gcov/x.gcda blib/arch/y.gcda .git/z.gcda t/no.gcda)) {
    my $path = File::Spec->catfile($dir, $rel);
    my ($vol, $d) = File::Spec->splitpath($path);
    File::Path::make_path(File::Spec->catpath($vol, $d, ''));
    open my $fh, '>', $path or die "$path: $!";
    close $fh;
}
is_deeply([Devel::XSCover::Gcov->new(dir => "$dir", silent => 1)->find_gcda],
    ['Op.gcda', 'lib/Math/Basic/XS.gcda', 'src/a.gcda', 'src/b.gcda', 't/no.gcda'],
    'the counter files at the top, under src and under lib, not under blib, cover_db or .git');

my $r = Devel::XSCover::Gcov->new(dir => "$dir", silent => 1, dry => 1, gcov => ['llvm-cov', 'gcov']);
my $out = '';
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    is($r->run_gcov('src/a.gcda'), '', 'a dry run returns no text');
    select $old;
}
is($out, '', 'and says nothing when silent');
$r = Devel::XSCover::Gcov->new(dir => "$dir", dry => 1, gcov => ['llvm-cov', 'gcov']);
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    $r->run_gcov('src/a.gcda');
    select $old;
}
is($out, "xs_cover: running llvm-cov gcov -abct -o src/a.gcda a\n", 'the gcov command for an object under src');

done_testing;
