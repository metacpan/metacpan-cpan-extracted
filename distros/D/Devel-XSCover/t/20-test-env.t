use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Path ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Test ();

plan skip_all => 'shell scripts stand in for make and prove here' if $^O eq 'MSWin32';

my $dir = File::Temp->newdir;
my $log = File::Spec->catfile($dir, 'log');
my $record = "echo \"\$0 \$@\" >> $log; echo \"H=[\$HARNESS_PERL_SWITCHES]\" >> $log; echo \"P=[\$PERL5OPT]\" >> $log";
my $make  = XSCoverTest::fake_script($dir, 'fake-make', $record);
my $prove = XSCoverTest::fake_script($dir, 'fake-prove', $record);
File::Path::make_path(File::Spec->catdir($dir, 't'));
for my $t (qw(a b c)) {
    open my $fh, '>', File::Spec->catfile($dir, 't', "$t.t") or die;
    close $fh;
}
open my $th, '>', File::Spec->catfile($dir, 't', 'd.t') or die;
print $th "use strict;\nuse threads;\n1;\n";
close $th;
sub log_lines { open my $fh, '<', $log or return (); my @l = <$fh>; chomp @l; unlink $log; @l }

my $db = File::Spec->catdir(File::Spec->rel2abs($dir), 'cover_db');
my $t = Devel::XSCover::Test->new(dir => "$dir", make => $make, prove => $prove, silent => 1);
is($t->db_path, $db, 'the db path is absolute under the dir');
my $dep = Devel::XSCover::Test->new->deparse_switch;
like($dep, qr/(?:^|\s)-MDevel::XSCover::Deparse$/, 'the deparse switch loads the module');
my $sw = "$dep -MDevel::Cover=-db,$db,-ignore,^/,-silent,1";
is($t->switches, $sw, 'the switches, silent since the object is');
is(Devel::XSCover::Test->new(dir => "$dir")->switches, "$dep -MDevel::Cover=-db,$db,-ignore,^/", 'the switches without silent, with the ignore of absolute paths');
is(Devel::XSCover::Test->new(dir => "$dir", no_deparse => 1)->switches, "-MDevel::Cover=-db,$db,-ignore,^/", 'and without the deparse module when told');
{
    local $ENV{DEVEL_COVER_TEST_OPTS} = '-Ilocal';
    is($t->switches, "-Ilocal $sw", 'DEVEL_COVER_TEST_OPTS comes first');
}
like(Devel::XSCover::Test->new(dir => "$dir", silent => 1)->switches, qr/,-silent,1$/, 'silent silences Devel::Cover');
is_deeply([$t->commands], [[[$prove, '-b', '-j1', 't/a.t', 't/b.t', 't/c.t'], 1], [[$prove, '-b', '-j1', 't/d.t'], 0]], 'a test that uses threads is found and run plain by itself, so the suite goes through prove');
is_deeply([$t->thread_tests], ['t/d.t'], 'the thread test found');
is_deeply([Devel::XSCover::Test->new(dir => "$dir", make => $make, silent => 1, threads_covered => 1)->commands], [[[$make, 'test'], 1]], 'make test alone when thread tests are to be left in');
unlink File::Spec->catfile($dir, 't', 'd.t');
is_deeply([$t->commands], [[[$make, 'test'], 1]], 'make test alone with no thread test');

is($t->run, 0, 'the fake make test run');
my @l = log_lines();
like($l[0], qr/fake-make test$/, 'make test ran');
is($l[1], "H=[$sw]", 'HARNESS_PERL_SWITCHES set');
is($l[2], "P=[$sw]", 'PERL5OPT set');

$t = Devel::XSCover::Test->new(dir => "$dir", make => $make, prove => $prove, silent => 1, test => ['t/b.t']);
is_deeply([$t->commands], [[[$prove, '-b', '-j1', 't/b.t'], 1]], 'one test file through prove');

$t = Devel::XSCover::Test->new(dir => "$dir", make => $make, prove => $prove, silent => 1, plain => ['t/c.t']);
is_deeply([$t->commands], [[[$prove, '-b', '-j1', 't/a.t', 't/b.t'], 1], [[$prove, '-b', '-j1', 't/c.t'], 0]],
    'a plain file splits the suite in two prove runs');
{
    local $ENV{HARNESS_PERL_SWITCHES} = '-w';
    local $ENV{PERL5OPT} = '-w';
    is($t->run, 0, 'the split run');
}
@l = log_lines();
like($l[0], qr/fake-prove -b -j1 t\/a\.t t\/b\.t$/, 'the covered files first');
is($l[1], "H=[$sw]", 'under Devel::Cover');
like($l[3], qr/fake-prove -b -j1 t\/c\.t$/, 'the plain file second');
is($l[4], 'H=[]', 'without the switches, even when the caller had them');
is($l[5], 'P=[]', 'and without PERL5OPT');

$t = Devel::XSCover::Test->new(dir => "$dir", make => $make, prove => $prove, silent => 1, test => ['t/a.t', 't/c.t'], plain => ['t/c.t']);
is_deeply([$t->commands], [[[$prove, '-b', '-j1', 't/a.t'], 1], [[$prove, '-b', '-j1', 't/c.t'], 0]], 'test and plain together');

$t = Devel::XSCover::Test->new(dir => "$dir", make => $make, prove => $prove, silent => 1, no_perl => 1);
is_deeply([$t->commands], [[[$make, 'test'], 0]], 'no_perl: make test without Devel::Cover');
is($t->run, 0, 'the plain suite run');
@l = log_lines();
is($l[1], 'H=[]', 'no switches');
$t = Devel::XSCover::Test->new(dir => "$dir", make => $make, prove => $prove, silent => 1, no_perl => 1, test => ['t/a.t']);
is_deeply([$t->commands], [[[$prove, '-b', '-j1', 't/a.t'], 0]], 'no_perl with a test file: prove without Devel::Cover');

my $fail = XSCoverTest::fake_script($dir, 'fake-fail', 'exit 3');
$t = Devel::XSCover::Test->new(dir => "$dir", make => $fail, silent => 1);
is($t->run, 3, 'the exit status is the test command\'s');

my $out = '';
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    is(Devel::XSCover::Test->new(dir => "$dir", make => $fail, dry => 1)->run, 0, 'a dry run runs nothing');
    select $old;
}
like($out, qr/^xs_cover: running \S+fake-fail test under Devel::Cover$/m, 'and prints the command');

done_testing;
