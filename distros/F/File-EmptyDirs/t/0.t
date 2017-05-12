use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::EmptyDirs 'remove_empty_dirs';
use File::Find::Rule;
use Cwd;


mkdir cwd().'/t/emptyhere';
mkdir cwd().'/t/emptyhere/more';
mkdir cwd().'/t/emptyhere/more/stuff';

my @ed = File::Find::Rule->directory->in(cwd.'/t/emptyhere');
ok(scalar @ed);
### @ed




my $removed = remove_empty_dirs(cwd.'/t/emptyhere');

ok($removed == 2 , "removed 2 == $removed");

#

my @ed2 = File::Find::Rule->directory->in(cwd.'/t/emptyhere');


ok( (scalar @ed2  == 1),'no dirs now except for t');
### @ed2

rmdir cwd().'/t/emptyhere';
