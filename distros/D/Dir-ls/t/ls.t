use strict;
use warnings;
use Dir::ls;
use Path::Tiny 'tempdir';
use Sort::filevercmp;
use Test::More;
use sort 'stable';

my $testdir = tempdir;

my @testfiles = qw(test1  test2.foo.tar  TEST3  test3.bar  test4.TXT  test5  .test5.log  Test_6.Txt  test7.out  test8.jpg);
my %testcontents = (
  test1 => 'ab',
  TEST3 => 'abcde',
  'test3.bar' => 'abcd',
  test5 => 'abcd',
);
$testdir->child($_)->touch for @testfiles;
$testdir->child($_)->spew($testcontents{$_}) for grep { exists $testcontents{$_} } @testfiles;
$testdir->child('test.d')->mkpath;
$testcontents{'test.d'} = 'a'x(-s $testdir->child('test.d')); # for later size check

my (@sorted_byname, @sorted_byext);
{
  use locale;
  # Test locale-sensitive sorting
  @sorted_byname = sort { Dir::ls::_alnum_sorter($a) cmp Dir::ls::_alnum_sorter($b) or $a cmp $b } @testfiles, 'test.d', '.', '..';
  @sorted_byext = sort { Dir::ls::_ext_sorter($a) cmp Dir::ls::_ext_sorter($b) } @sorted_byname;
}

my @default_list = ls $testdir;
my @default_sort = grep { !m/^\./ } @sorted_byname;
is_deeply \@default_list, \@default_sort, 'default list correct';

my @reverse_list = ls $testdir, {reverse => 1};
my @reverse_sort = reverse grep { !m/^\./ } @sorted_byname;
is_deeply \@reverse_list, \@reverse_sort, 'reverse list correct';

my @almost_all_list = ls $testdir, {'almost-all' => 1};
my @almost_all_sort = grep { !m/^\.\.?$/ } @sorted_byname;
is_deeply \@almost_all_list, \@almost_all_sort, 'almost-all list correct';

my @all_list = ls $testdir, {all => 1};
my @all_sort = @sorted_byname;
is_deeply \@all_list, \@all_sort, 'all list correct';

my @by_ext_list = ls $testdir, {'almost-all' => 1, sort => 'extension'};
my @by_ext_sort = grep { !m/^\.\.?$/ } @sorted_byext;
is_deeply \@by_ext_list, \@by_ext_sort, 'extension sorted list correct';

my @by_size_list = ls $testdir, {'almost-all' => 1, sort => 'size'};
my @by_size_sort = sort { length($testcontents{$b}||'') <=> length($testcontents{$a}||'') } grep { !m/^\.\.?$/ } @sorted_byname;
is_deeply \@by_size_list, \@by_size_sort, 'size sorted list correct';

my @by_version_list = ls $testdir, {'almost-all' => 1, sort => 'version'};
my @by_version_sort = sort filevercmp @testfiles, 'test.d';
is_deeply \@by_version_list, \@by_version_sort, 'version sorted list correct';

done_testing;
