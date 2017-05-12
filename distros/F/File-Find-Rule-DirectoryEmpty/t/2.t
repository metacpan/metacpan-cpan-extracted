use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::Find::Rule::DirectoryEmpty;
use Cwd;

mkdir cwd().'/t/emptyhere';


my $o = new File::Find::Rule->directoryempty;
my @ed = $o->in(cwd.'/t');
### @ed
my $count = scalar @ed;

ok($count == 1, "found $count");

rmdir cwd().'/t/emptyhere';







# 
#
#
mkdir cwd().'/t/emptyhere';

my @d = new File::Find::Rule->directoryempty->in('./t');
my $c = scalar @d;

ok($c == 1, "found $c");

rmdir cwd().'/t/emptyhere';

