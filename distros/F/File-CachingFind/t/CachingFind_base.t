# Before `make install' is performed this script should be runable
# with `make test'. After `make install' it should work as `perl
# t/CachingFind_base.t'

use strict;

######################### We start with some black magic to print on failure.

my $loaded;
BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::CachingFind;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use Cwd 'abs_path';
my $this_dir = abs_path('.');
my $test_include1 = $this_dir.'/t/test.h';
my $test_include2 = $this_dir.'/t/testdir1/test.h';
my $test_include3 = $this_dir.'/t/testdir2/Test.h';
my $test_include4 = $this_dir.'/t/testdir3/test.h';

-e $test_include4  and  unlink $test_include4;

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
sub test_undefined
{
    if (defined($_[1]))	{ print "not ok $_[0]\t(defined)\n"; }
    else		{ print "ok $_[0]\n"; }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2
my $all = File::CachingFind->new(Path => ['.']);
test_defined('2', $all);

# 3
my $found = join(',', $all->findInPath('MANIFEST'));
test_eq('3', $found, $this_dir.'/MANIFEST');

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 4
my $includes = File::CachingFind->new(Path => ['.'],
				      Filter => '\.h$');
test_defined('4', $includes);

# 5
$found = join(',', $includes->findInPath('MANIFEST'));
test_eq('5', $found, '');

# 6
$found = join(',', $includes->findInPath('Test.h'));
test_eq('6', $found, $test_include3);

# 7
$found = join(',', sort $includes->findInPath('test.h'));
test_eq('7', $found, $test_include1.','.$test_include2);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 8
$includes = File::CachingFind->new(Path => ['.'],
				   Filter => '\.h$',
				   Normalize => sub{lc @_});
test_defined('8', $includes);

# 9
$found = join(',', sort $includes->findInPath('test.h'));
test_eq('9', $found, $test_include1.','.$test_include2.','.$test_include3);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 10
$includes = File::CachingFind->new(Path => ['t!'],
				   Filter => '\.h$');
test_defined('10', $includes);

# 11
$found = join(',', $includes->findInPath('test.h'));
test_eq('11', $found, $test_include1);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 12
$includes = File::CachingFind->new(Path => ['t!', 't'],
				   Filter => '\.h$');
test_defined('12', $includes);

# 13
$found = join(',', sort $includes->findInPath('test.h'));
test_eq('13', $found, $test_include1.','.$test_include1.','.$test_include2);

# 14
$found = $includes->findFirstInPath('MANIFEST');
test_undefined('14', $found);

# 15
$found = $includes->findFirstInPath('test.h');
test_eq('15', $found, $test_include1);

# 16
$found = $includes->findBestInPath('test.h',
				   sub{ length($_[0]) <=> length($_[1]) });
test_eq('16', $found, $test_include1);

# 17
$found = join(',', $includes->findMatch('^T'));
test_eq('17', $found, $test_include3);

# 18
$found = join(',', sort $includes->findMatch('^t'));
test_eq('18', $found, $test_include1.','.$test_include1.','.$test_include2);

# 19
$found = $includes->findFirstMatch('^t');
test_eq('19', $found, $test_include1);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 20
$all = File::CachingFind->new(Path => ['.']);
test_defined('20', $all);

# 21
$found = $all->findBestMatch('\.h$',
			     sub{ length($_[0]) <=> length($_[1]) });
test_eq('21', $found, $test_include1);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 22
my $none = File::CachingFind->new(Path => ['./not-existing-path']);
test_defined('22', $none);

# 23
$found = join(',', $none->findInPath('test.h'));
test_eq('23', $found, '');
