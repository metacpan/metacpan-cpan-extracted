use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::Find::Rule::DirectoryEmpty;
use Cwd;

mkdir cwd().'/t/emptyhere';


my @ed = File::Find::Rule::DirectoryEmpty->directoryempty->in(cwd.'/t');
### @ed
my $count = scalar @ed;

ok($count == 1, "found $count");

mkdir cwd().'/t/emptyhere2';
mkdir cwd().'/t/emptyhere3';

my @ed2 = File::Find::Rule::DirectoryEmpty->directoryempty->in(cwd.'/t');
$count = scalar @ed2;

ok($count == 3, "found $count");


mkdir cwd().'/t/emptyhere2/haha';
mkdir cwd().'/t/emptyhere2/haha2';

my @ed3 = File::Find::Rule::DirectoryEmpty->directoryempty->in(cwd.'/t');
$count = scalar @ed3;
ok($count == 4, "found $count"); # because now emptyhere2 is no longer empty



my @ed4 = File::Find::Rule::DirectoryEmpty->directoryempty->in(cwd.'/t/emptyhere2');
$count = scalar @ed4;
ok($count == 2, "found $count"); 





rmdir cwd().'/t/emptyhere';
rmdir cwd().'/t/emptyhere2/haha';
rmdir cwd().'/t/emptyhere2/haha2';
rmdir cwd().'/t/emptyhere2';
rmdir cwd().'/t/emptyhere3';

