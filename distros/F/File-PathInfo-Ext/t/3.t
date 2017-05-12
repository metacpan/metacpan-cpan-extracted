use Test::Simple 'no_plan';
use lib './lib';
use strict;
use File::PathInfo::Ext;
use Cwd;

my $cwd = cwd;
open(F1,">$cwd/t/f1");
print F1 'ha';
close F1;

open(F2,">$cwd/t/f2");
print F2 'ha';
close F2;



my $f = new File::PathInfo::Ext("$cwd/t/f1");
ok($f);

ok( $f->rename('f2') == 0,'cannot rename to f2 beacuse already exists');

ok(-f "$cwd/t/f2");
ok(-f "$cwd/t/f1");


unlink("$cwd/t/f2");
unlink("$cwd/t/f1");

