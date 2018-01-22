use strict;
use warnings;
use Test::More;
use lib 't';

# -d:ModuleBreaker=...  operates on complete matches of fully qualified 
#                       module names

my $stub = qq("$^X" -Iblib/lib -Ilib -It -MIncludeAll -d:ModuleBreaker);
my ($c,@f);

@f = qx($stub=Some::Module t/bptracker.pl -f);
ok(@f==2,  'finds module subs in multiple files');

$c = qx($stub=Some::Module t/bptracker.pl -c);
ok($c == 3,'finds module subs in multiple files');

@f = qx($stub=Some::Module t/bptracker.pl -s);
ok(3==(grep /sm\d/,@f),  'breaks in correct subs in multiple files');

$c = qx($stub=Module::Bogus t/bptracker.pl -c);
ok($c == 0, 'no breakpoints for bogus module');

$c = qx($stub=Module::Bogus,Some::Module t/bptracker.pl -c);
ok($c == 3, 'mix of bogus and valid modules');

$c = qx($stub=Some::OtherModule t/bptracker.pl -c);
ok($c == 2, 'ignore subs in wrong namespace') or diag $c;

@f = qx($stub=Some::OtherModule t/bptracker.pl -s);
ok(grep(/^so\d/,@f) == 2, 'ignore subs in wrong namespace') or diag @f;

$c = qx($stub=Some::OtherModule,Foo::Some::Module t/bptracker.pl -c);
ok($c == 4, 'multiple modules');

$c = qx($stub=Some t/bptracker.pl -c);
ok($c == 0, 'partial match ignored');

done_testing();
