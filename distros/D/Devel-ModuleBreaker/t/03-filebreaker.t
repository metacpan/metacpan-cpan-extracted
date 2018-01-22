use strict;
use warnings;
use Test::More;
use lib 't';

# -d:FileBreaker=...  operates on partial matches of filenames that
#                     contain subs

my $stub = qq("$^X" -Iblib/lib -Ilib -It -MIncludeAll -d:FileBreaker);
my ($c,@f);

@f = qx($stub=t/Some/Module t/bptracker.pl -f);
ok(@f==2,  'expr matches multiple files') or diag @f;

@f = qx($stub=Some/Module t/bptracker.pl -f);
ok(@f==3,  'expr matches multiple files') or diag @f;

@f = qx($stub=Some t/bptracker.pl -f);
ok(@f==4,  'expr matches multiple files') or diag @f;

$c = qx($stub=Some/Module.pm t/bptracker.pl -c);
ok($c == 4,'finds subs in multiple files') or diag $c;

@f = qx($stub=Some/Module.pm t/bptracker.pl -s);
ok(4==(grep /sm\d/,@f),  'breaks in correct subs in multiple files');
ok(2==(grep /fsm\d/,@f),  'breaks in correct subs in file that matches expression');

$c = qx($stub=Module::Bogus t/bptracker.pl -c);
ok($c == 0, 'no breakpoints for bogus module');

$c = qx($stub=Module/Bogus,Some/Module t/bptracker.pl -c);
ok($c > 0, 'mix of bogus and valid modules');

$c = qx($stub=Some/OtherModule.pm t/bptracker.pl -c);
ok($c == 3, 'include subs in wrong namespace') or diag $c;

@f = qx($stub=Some/OtherModule t/bptracker.pl -s);
ok(grep(/^so\d/,@f) == 2, 'break in subs in correct namespace') or diag @f;
ok(grep(/^sm\d/,@f) == 1, 'break in subs in wrong namespace') or diag @f;

$c = qx($stub=Some/OtherModule,Foo/Some/Module t/bptracker.pl -c);
ok($c == 5, 'multiple modules') or diag $c;

@f = qx($stub=Some/OtherModule,Foo/Some/Module t/bptracker.pl -f);
chomp(@f);
ok($f[0] =~ m{.*/Foo/Some/Module.pm,2},
   'break in correct number of subs file 1');
ok($f[1] =~ m{.*/Some/OtherModule.pm,3}, 
   'break in correct number of subs file 2');

$c = qx($stub=Some t/bptracker.pl -c);
ok($c > 0, 'partial match retuns many results');

done_testing();
