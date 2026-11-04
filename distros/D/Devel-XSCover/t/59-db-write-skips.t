use 5.020;
use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::DB ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };

my $dir = File::Temp->newdir;
open my $fh, '>', File::Spec->catfile($dir, 'm.c') or die;
print $fh "int f(int x)\n{\n    return x;\n}\n";
close $fh;
my $tmp = File::Temp->newdir;
my $db  = Cwd::abs_path("$tmp");

my $gone = File::Spec->catdir($dir, 'gone');
eval { Devel::XSCover::DB->new(dir => $gone, db => $db, silent => 1)->write({}) };
like($@, qr/^xs_cover: cannot chdir to \Q$gone\E: /, 'a directory that is not there is a plain message');

my $entries = {
    'm.c'    => { statement => [[1, 2], [3, 2]], branch => [[1, 'if (x)', [2, 0]]], subroutine => [[1, 'f', 2]], condition => [] },
    'lost.c' => { statement => [[1, 1]], branch => [], subroutine => [], condition => [] },
};
my (@warn, $run);
my $out = '';
{
    local $SIG{__WARN__} = sub { push @warn, @_ };
    local *STDOUT;
    open STDOUT, '>', \$out or die;
    $run = Devel::XSCover::DB->new(dir => "$dir", db => $db, dry => 1)->write($entries);
}
is_deeply(\@warn, ["xs_cover: no source lost.c under $dir, skipped\n"], 'a file that is not under dir is skipped with a warning');
is_deeply([ @{$run}{qw(files statement branch subroutine condition)} ], [1, 2, 1, 1, 0], 'and is not counted');
like($run->{run}, qr/^\Q@{[ File::Spec->catdir($db, 'runs') ]}\E/, 'the run path is under the database');
is($out, "xs_cover: writing 1 file, 2 statements, 1 branches, 1 subroutines to $run->{run}\n", 'the summary line is printed when not silent');
ok(!-e File::Spec->catdir($db, 'runs'), 'a dry run writes nothing');

my $old = { 'm.c' => { statement => [[1, 2], [3, 2]], branch => [], subroutine => [[1, 'f', 2]] } };
$run = Devel::XSCover::DB->new(dir => "$dir", db => $db, silent => 1)->write($old);
is($run->{condition}, 0, 'an entries hash without condition lists, as 0.01 built them, writes no conditions');
my $here = Cwd::getcwd();
chdir $dir or die;
my $cover = Devel::Cover::DB->new(db => $db)->merge_runs;
my @collected = $cover->collected;
my $file = $cover->cover->file('m.c');
chdir $here;
is_deeply(\@collected, ['branch', 'statement', 'subroutine'], 'and collects three criteria');
is($file->statement->location(3)->[0]->covered, 2, 'with the statements read back');

done_testing;
