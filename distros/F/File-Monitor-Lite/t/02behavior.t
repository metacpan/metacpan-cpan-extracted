use Test::More tests => 15;
use File::Monitor::Lite;
use File::Touch;
use File::Spec::Functions ':ALL';
use lib 'lib';

unlink glob '*.test';
my $m = File::Monitor::Lite->new( name => ['*.test'], in => '.',);

note 'create t.test';
touch 't.test';

ok $m->check, 'check done';
is_deeply [$m->created], [rel2abs('t.test')], 't.test created';
is_deeply [$m->deleted], [] , 'nothing deleted';
is_deeply [$m->modified], [] , 'nothing modified';
is_deeply [$m->observed], [rel2abs('t.test')], 'observing t.test';

note 'modify t.test';
open FILE, '>t.test';
print FILE 'testing...';
close FILE;
ok $m->check, 'check done';
is_deeply [$m->created], [], 'nothing created';
is_deeply [$m->deleted], [] , 'nothing deleted';
is_deeply [$m->modified], [rel2abs('t.test')] , 't.test modified';
is_deeply [$m->observed], [rel2abs('t.test')], 'observing t.test';

note 'delete t.test';
unlink glob '*.test';
ok $m->check, 'check done';
is_deeply [$m->created], [], 'nothing created';
is_deeply [$m->deleted], [rel2abs('t.test')] , 't.test deleted';
is_deeply [$m->modified], [] , 'nothing modified';
is_deeply [$m->observed], [], 'observing nothing';
