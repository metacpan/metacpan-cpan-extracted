# vim:set filetype=perl sw=4 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:
#########################

use Test::More no_plan => ; # tests => 30;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cuezi', qw(comp); }

is(comp('sīlo'), 'sīlate', 'comparative of sīlo');
is(comp('lēve'), 'lēvase', 'comparative of lēve');
is(comp('sidi'), 'sidîse', 'comparative of sidi');
is(comp('gggo'), 'gggâte', 'comparative of gggo');
is(comp('ggge'), 'gggâse', 'comparative of ggge');
is(comp('gggi'), 'gggîse', 'comparative of gggi');
is(comp('gēgo'), 'gēgate', 'comparative of gēgo');
is(comp('gēge'), 'gēgase', 'comparative of gēge');
is(comp('gēgi'), 'gēgise', 'comparative of gēgi');
