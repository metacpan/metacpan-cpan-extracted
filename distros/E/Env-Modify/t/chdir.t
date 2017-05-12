use Test::More tests => 11;

use Env::Modify ':system', ':chdir', 'backticks';
use Cwd;
use strict;
use warnings;

my $cwd0 = Cwd::getcwd();
ok( (-d "foo") || mkdir("foo"), 'directory 1 avail' );
ok( (-d "foo/bar") || mkdir("foo/bar"), "directory 2 avail" );
ok( (-d "foo/bar/baz") || mkdir("foo/bar/baz"), "directory 3 avail" );

my $c1 = system("cd foo ; pwd ; printenv | grep foo");
ok($c1 == 0, 'chdir ok');
my $cwd1 = Cwd::getcwd();

ok($cwd1 =~ m{/foo$}, 'chdir ok');
my $c2 = system("cd foo 2> /dev/null");
ok($c2 != 0, 'chdir foo failed when we are already in foo');

my $o3 = backticks("cd bar/baz && pwd");
my $c3 = $?;
ok($c3 == 0, 'chdir bar/baz successful');
ok($o3 =~ m{foo/bar/baz$}, 'backticks produce correct output');
my $cwd2 = Cwd::getcwd();
ok($cwd2 =~ m{/foo/bar/baz$}, '2nd chdir ok');

my $c4 = system("cd ../../..");
ok($c4 == 0, 'chdir back to orig no error');
my $cwd3 = Cwd::getcwd();
ok($cwd3 eq $cwd0, 'chdir back to original directory');

rmdir("foo/bar/baz") &&
    rmdir("foo/bar") &&
    rmdir("foo");
