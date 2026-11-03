#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
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

my $one = Devel::XSCover->new(test => 't/one.t', ignore => 'x');
is_deeply([$one->tests], ['t/one.t'], 'a single test file as a string');
is_deeply([$one->ignores], ['x'], 'a single ignore as a string');


done_testing;
