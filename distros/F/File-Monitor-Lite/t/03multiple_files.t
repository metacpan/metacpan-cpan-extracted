use Test::More tests => 20;
use File::Monitor::Lite;
use File::Touch;
use File::Spec::Functions ':ALL';
use lib 'lib';

unlink glob '*.test';
my $m = File::Monitor::Lite->new( name => ['*.test'], in => '.',);

note 'create t1.test';
touch 't1.test';

ok $m->check, 'check done';
is_deeply [$m->created], [rel2abs('t1.test')], 't1.test created';
is_deeply [$m->deleted], [] , 'nothing deleted';
is_deeply [$m->modified], [] , 'nothing modified';
is_deeply [$m->observed], [rel2abs('t1.test')], 'observing t1.test';

note 'create t2.test, t3.test; modify t1.test';
touch 't2.test';
touch 't3.test';
open FILE, '>t1.test';
print FILE 'testing';
close FILE;

ok $m->check, 'check done';
is_deeply [$m->created], [rel2abs('t2.test'), rel2abs('t3.test')], 't.test created';
is_deeply [$m->deleted], [] , 'nothing deleted';
is_deeply [$m->modified], [rel2abs('t1.test')] , 'nothing modified';
is_deeply [$m->observed], [rel2abs('t1.test'), rel2abs('t2.test'), rel2abs('t3.test')], 'observing t.test';


note 'delete t2.test t3.test';
unlink 't2.test','t3.test';
ok $m->check, 'check done';
is_deeply [$m->created], [], 'nothing created';
is_deeply [$m->deleted], [rel2abs('t2.test'),rel2abs('t3.test')] , 't.test deleted';
is_deeply [$m->modified], [] , 'nothing modified';
is_deeply [$m->observed], [rel2abs('t1.test')], 'observing nothing';

note 'delete t1.test';
unlink 't1.test';
ok $m->check, 'check done';
is_deeply [$m->created], [], 'nothing created';
is_deeply [$m->deleted], [rel2abs('t1.test')] , 't.test deleted';
is_deeply [$m->modified], [] , 'nothing modified';
is_deeply [$m->observed], [], 'observing nothing';
