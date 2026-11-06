#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use Config ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover ();

my $default = Devel::XSCover->new;
is($default->dir, '.', 'the default dir');
is($default->db, 'cover_db', 'the default db');
is($default->report_name, 'XSCover', 'the default report');
is($default->make, 'make', 'the default make');
is_deeply([$default->tests], [], 'no test files');
is_deeply([$default->plains], [], 'no plain files');
is($default->timeout, 0, 'no timeout');
is_deeply([$default->ignores], [], 'no ignores');
ok(!$default->keep, 'not kept');
ok($default->delete_db, 'the db is deleted');
ok(!$default->no_perl, 'Devel::Cover is on');
ok(!$default->dry, 'not dry');
ok(!$default->silent, 'not silent');
is($default->gcov, undef, 'no gcov override');

my $argv = Devel::XSCover->new_from_argv(qw(
    -dir Ex-Op -db cov -report html_basic -gcov /usr/bin/gcov-14
    -make gmake -test t/01-a.t -test t/02-b.t -ignore vendor/ -ignore ^src/old
    -plain t/04-threads.t -timeout 90 -cover /opt/bin/cover
    -keep -no_delete -no_perl -threads_covered -dry -silent
));
is($argv->dir, 'Ex-Op', '-dir');
is($argv->db, 'cov', '-db');
is($argv->report_name, 'html_basic', '-report');
is($argv->cover, '/opt/bin/cover', '-cover');
is($argv->gcov, '/usr/bin/gcov-14', '-gcov');
is($argv->make, 'gmake', '-make');
is_deeply([$argv->tests], ['t/01-a.t', 't/02-b.t'], '-test twice');
is_deeply([$argv->plains], ['t/04-threads.t'], '-plain');
is($argv->timeout, 90, '-timeout');
is_deeply([$argv->ignores], ['vendor/', '^src/old'], '-ignore twice');
ok($argv->keep, '-keep');
ok(!$argv->delete_db, '-no_delete');
ok($argv->no_perl, '-no_perl');
ok($argv->threads_covered, '-threads_covered');
ok($argv->dry, '-dry');
ok($argv->silent, '-silent');

my $one = Devel::XSCover->new(test => 't/one.t', ignore => 'x', plain => 't/two.t');
is_deeply([$one->tests], ['t/one.t'], 'a single test file as a string');
is_deeply([$one->ignores], ['x'], 'a single ignore as a string');
is_deeply([$one->plains], ['t/two.t'], 'a single plain file as a string');

my $tmp = File::Temp->newdir;
my $sbin = File::Spec->catdir($tmp, 'sbin');
File::Path::make_path($sbin);
{
    local $^X = File::Spec->catfile($tmp, 'bin', 'perl');
    local %Config::Config = (installsitescript => undef, installsitebin => '', installscript => $sbin);
    is_deeply(Devel::XSCover->new->cover_command, ['cover'], 'no cover beside perl nor in the install directories, so the bare name for the path to find');
    is_deeply(Devel::XSCover->new(cover => '')->cover_command, ['cover'], 'an empty -cover is no override');
    open my $fh, '>', File::Spec->catfile($sbin, 'cover') or die;
    close $fh;
    my @inc = Devel::XSCover->report_inc;
    is_deeply(Devel::XSCover->new->cover_command, [$^X, @inc, File::Spec->catfile($sbin, 'cover')], 'the cover in an install directory runs under the same perl');
}
{
    delete local $INC{'Devel/XSCover.pm'};
    is_deeply([Devel::XSCover->report_inc], [], 'no -I when the module was not loaded from a file');
    local $INC{'Devel/XSCover.pm'} = File::Spec->catfile($tmp, 'Devel', 'XSCover.pm');
    is_deeply([Devel::XSCover->report_inc], [], 'and none when the report module is not beside it');
}

{
    my $dist = File::Spec->catdir($tmp, "defaults");
    File::Path::make_path($dist);
    open my $fh, ">", File::Spec->catfile($dist, ".xs_cover") or die;
    print $fh "# the dist's own defaults\n-ignore 'include/vendor' -report text # trailing\n-timeout 30\n";
    close $fh;
    my $here = Devel::XSCover->new_from_argv(qw(-ignore ^src/old), "-dir", $dist, qw(-report html_basic));
    is_deeply([$here->ignores], ["include/vendor", "^src/old"], "the file's ignore comes before the command line's");
    is($here->report_name, "html_basic", "a single-valued option on the command line wins");
    is($here->timeout, 30, "and one from the file alone holds");
    is_deeply([Devel::XSCover->defaults_from_file(qw(-dir), File::Spec->catdir($tmp, "nowhere"))], [], "no file, no words");
}

done_testing;
