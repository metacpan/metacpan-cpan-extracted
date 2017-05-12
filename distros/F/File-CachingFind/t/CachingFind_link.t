# Before `make install' is performed this script should be runable
# with `make test'.  (Use `make test TEST_VERBOSE=1' if you encounter
# any errors.)  After `make install' it should work as `perl
# t/CachingFind_link.t'

use strict;

######################### We start with some black magic to print on failure.

my $loaded;
BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::CachingFind;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use Cwd 'abs_path';
my $this_dir = abs_path('.');
my $test_include1 = $this_dir.'/t/test.h';
my $test_include2 = $this_dir.'/t/testdir1/test.h';
my $test_include3 = $this_dir.'/t/testdir3/test.h';

-d 't/testdir3'  or  mkdir 't/testdir3', 0777  or  die;
unless (-l $test_include3)
{
    my $symlink = eval { symlink('',''); 1 };
    unless ($symlink  and  symlink $test_include1, $test_include3)
    {
	print "ok $_ # skip symlink doesn't seem to work this machine\n"
	    foreach (2..5);
	exit 0;
    }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# some functions to check the results:
sub test_defined
{
    if (defined($_[1]))	{ print "ok $_[0]\n"; }
    else		{ print "not ok $_[0]\t(undefined)\n"; }
}
sub test_eq
{
    if ($_[1] eq $_[2])	{ print "ok $_[0]\n"; }
    else		{ print "not ok $_[0]\t('$_[1]' ne '$_[2]')\n"; }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2
my $includes = File::CachingFind->new(Path => ['.'],
				      Filter => '\.h$',
				      NoSoftlinks => 1);
test_defined('2', $includes);

# 3
my $found = join(',', sort $includes->findInPath('test.h'));
test_eq('3', $found, $test_include1.','.$test_include2);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 4
$includes = File::CachingFind->new(Path => ['.'],
				   Filter => '\.h$');
test_defined('4', $includes);

# 5
$found = join(',', sort $includes->findInPath('test.h'));
test_eq('5', $found, $test_include1.','.$test_include2.','.$test_include3);
