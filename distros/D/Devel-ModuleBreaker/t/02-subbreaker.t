use strict;
use warnings;
use Test::More;
use lib 't';

# -d:SubBreaker=... operates on partial matches of subroutine names and
#                   module names

my $stub = qq("$^X" -Iblib/lib -Ilib -It -MIncludeAll -d:SubBreaker);
my ($c,@f);

@f = qx($stub=Some::Module t/bptracker.pl -f);
ok(@f==4,  'finds subs in multiple files') or diag @f;

$c = qx($stub=Some::Module t/bptracker.pl -c);
ok($c == 7,'finds every sub in multiple files') or diag $c;

$c = qx($stub=sm t/bptracker.pl -c);
ok($c == 7,'finds subs matching /sm/') or diag $c;

$c = qx($stub=::sm t/bptracker.pl -c);
ok($c == 5,'finds subs matching /::sm/') or diag $c;

$c = qx($stub=sm[0-9] t/bptracker.pl -c);
ok($c == 5,'finds subs matching /sm\\d/') or diag $c;

$c = qx($stub=::sm[0-9] t/bptracker.pl -c);
ok($c == 3,'finds subs matching /::sm\\d/') or diag $c;

@f = qx($stub=::sm[0-9] t/bptracker.pl -f);
ok(@f == 2,'finds subs matching /::sm\\d/ in multiple files') or diag @f;

@f = qx($stub=Some::Module t/bptracker.pl -s);
ok(5==(grep /sm\d/,@f),  'breaks in correct subs in multiple files') or diag @f;

$c = qx($stub=Module::Bogus t/bptracker.pl -c);
ok($c == 0, 'no breakpoints for bogus module');

$c = qx($stub=Module::Bogus,Some::Module t/bptracker.pl -c);
ok($c == 7, 'mix of bogus and valid modules') or diag $c;

$c = qx($stub=Some::OtherModule t/bptracker.pl -c);
ok($c == 2, 'ignore subs in wrong namespace') or diag $c;

@f = qx($stub=Some::OtherModule t/bptracker.pl -s);
ok(grep(/^so\d/,@f) == 2, 'ignore subs in wrong namespace') or diag @f;

$c = qx($stub=Some::OtherModule,Foo::Some::Module t/bptracker.pl -c);
ok($c == 4, 'multiple modules');

$c = qx($stub=Some::OtherModule,fsm t/bptracker.pl -c);
ok($c == 4, 'mix module, regexp');

done_testing();
