use strict;
use warnings;
use Dir::ls;
use File::pushd;
use File::Spec;
use File::Temp;
use Sort::filevercmp;
use Test::More;
use sort 'stable';

my $testdir = File::Temp->newdir;

my @testfiles = qw(test1  test2.foo.tar  TEST3  test3.bar  test4.TXT  test5  test5~  .test5.log  Test_6.Txt  test7.out  test8.jpg);
my %testcontents = (
  test1 => 'ab',
  TEST3 => 'abcde',
  'test3.bar' => 'abcd',
  test5 => 'abcd',
);
foreach my $testfile (@testfiles) {
  my $testpath = File::Spec->catfile($testdir, $testfile);
  open my $testfh, '>', $testpath or die "Failed to create $testpath for testing: $!";
  print $testfh $testcontents{$testfile} if exists $testcontents{$testfile};
}
my $testpath = File::Spec->catdir($testdir, 'test.d');
mkdir $testpath or die "Failed to create $testpath for testing: $!";
$testcontents{'test.d'} = "\0"x(-s $testpath); # for later size check

my (@sorted_byname, @sorted_byext);
{
  use locale;
  # Test locale-sensitive sorting
  @sorted_byname = sort @testfiles, 'test.d', '.', '..';
  @sorted_byext = sort { Dir::ls::_ext_sorter($a) cmp Dir::ls::_ext_sorter($b) } @sorted_byname;
}

my @default_list = ls $testdir;
my @default_sort = grep { !m/^\./ } @sorted_byname;
is_deeply \@default_list, \@default_sort, 'default list correct';

{
  my $cwd = pushd $testdir;
  my @cwd_list = ls;
  my @cwd_sort = grep { !m/^\./ } @sorted_byname;
  is_deeply \@cwd_list, \@cwd_sort, 'cwd list correct';
}

my @reverse_list = ls $testdir, {reverse => 1};
my @reverse_sort = reverse grep { !m/^\./ } @sorted_byname;
is_deeply \@reverse_list, \@reverse_sort, 'reverse list correct';

{
  my $cwd = pushd $testdir;
  my @cwd_reverse_list = ls {reverse => 1};
  my @cwd_reverse_sort = reverse grep { !m/^\./ } @sorted_byname;
  is_deeply \@cwd_reverse_list, \@cwd_reverse_sort, 'cwd reverse list correct';
}

my @almost_all_list = ls $testdir, {'almost-all' => 1};
my @almost_all_sort = grep { !m/^\.\.?\z/ } @sorted_byname;
is_deeply \@almost_all_list, \@almost_all_sort, 'almost-all list correct';

my @all_list = ls $testdir, {all => 1};
my @all_sort = @sorted_byname;
is_deeply \@all_list, \@all_sort, 'all list correct';

my @no_backups_list = ls $testdir, {all => 1, 'ignore-backups' => 1};
my @no_backups_sort = grep { !m/~\z/ } @sorted_byname;
is_deeply \@no_backups_list, \@no_backups_sort, 'ignore-backups list correct';

my @hide_list = ls $testdir, {hide => 'test*.T??'};
my @hide_sort = grep { !m/^\./ and !m/^test.*\.T..\z/ } @sorted_byname;
is_deeply \@hide_list, \@hide_sort, 'hide list correct';

my @hide_all_list = ls $testdir, {a => 1, hide => 'test*'};
my @hide_all_sort = @sorted_byname;
is_deeply \@hide_all_list, \@hide_all_sort, 'hide overriden by all';

my @hide_almost_all_list = ls $testdir, {A => 1, hide => 'test*'};
my @hide_almost_all_sort = grep { !m/^\.\.?\z/ } @sorted_byname;
is_deeply \@hide_almost_all_list, \@hide_almost_all_sort, 'hide overriden by almost-all';

my @ignore_list = ls $testdir, {ignore => 'test[15]'};
my @ignore_sort = grep { !m/^\./ and !m/^test[15]\z/ } @sorted_byname;
is_deeply \@ignore_list, \@ignore_sort, 'ignore list correct';

my @ignore_all_list = ls $testdir, {-a => 1, '--ignore' => '*.*'};
my @ignore_all_sort = grep { !m/^[^.]+\./ } @sorted_byname;
is_deeply \@ignore_all_list, \@ignore_all_sort, 'ignore with all';

my @ignore_almost_all_list = ls $testdir, {-A => 1, ignore => 'test?.{out,jpg}'};
my @ignore_almost_all_sort = grep { !m/^\.\.?\z/ and !m/^test.\.(out|jpg)\z/ } @sorted_byname;
is_deeply \@ignore_almost_all_list, \@ignore_almost_all_sort, 'ignore with almost all';

my @by_ext_list = ls $testdir, {'almost-all' => 1, sort => 'extension'};
my @by_ext_sort = grep { !m/^\.\.?\z/ } @sorted_byext;
is_deeply \@by_ext_list, \@by_ext_sort, 'extension sorted list correct';

my @by_size_list = ls $testdir, {'almost-all' => 1, sort => 'size'};
my @by_size_sort = sort { length($testcontents{$b}||'') <=> length($testcontents{$a}||'') } grep { !m/^\.\.?\z/ } @sorted_byname;
is_deeply \@by_size_list, \@by_size_sort, 'size sorted list correct';

my @by_version_list = ls $testdir, {'almost-all' => 1, sort => 'version'};
my @by_version_sort = sort filevercmp @testfiles, 'test.d';
is_deeply \@by_version_list, \@by_version_sort, 'version sorted list correct';

my @dirs_first_list = ls $testdir, {'almost-all' => 1, 'group-directories-first' => 1};
my @dirs_first_sort = ('test.d', grep { !m/^\.\.?\z/ and $_ ne 'test.d' } @sorted_byname);
is_deeply \@dirs_first_list, \@dirs_first_sort, 'group directories first';

my @dirs_first_reverse_list = ls $testdir, {'almost-all' => 1, 'group-directories-first' => 1, reverse => 1};
my @dirs_first_reverse_sort = ('test.d', reverse grep { !m/^\.\.?\z/ and $_ ne 'test.d' } @sorted_byname);
is_deeply \@dirs_first_reverse_list, \@dirs_first_reverse_sort, 'group directories first with reverse sort';

my @indicators_list = ls $testdir, {-p => 1};
my @indicators_sort = map { $_ eq 'test.d' ? "$_/" : $_ } grep { !m/^\./ } @sorted_byname;
is_deeply \@indicators_list, \@indicators_sort, 'directory indicators added';

done_testing;
