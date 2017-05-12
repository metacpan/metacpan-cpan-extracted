use Test::Simple 'no_plan';
use lib './lib';
use File::PathInfo;
my $abs = Cwd::cwd().'/t';

my $f = File::PathInfo->new($abs);
ok $f;

my $val;

ok $val = $f->errstr('this is a val for errstr') or die;
### $val

ok($val, "val $val");
