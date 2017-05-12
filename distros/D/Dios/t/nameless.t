use warnings;
use strict;

use Test::More;

plan tests => 16;


use Dios;

func nameless(Str, Int $ , @, %?, *@ ) { 1 }

ok nameless('foo',1,[]),          'Nameless (no hash, nothing slurped)';
ok nameless('foo',1,[],{}),       'Nameless (nothing slurped)';
ok nameless('foo',1,[],{},1..10), 'Nameless (slurped)';

ok !eval{ nameless('foo',1) },    'Failed nameless (no array, etc.) as expected';
like $@, qr/\QNo argument found for unnamed 3rd positional parameter\E/, '...with correct error message';

ok !eval{ nameless('foo') },      'Failed nameless (no int, etc.) as expected';
like $@, qr/\QNo argument found for unnamed 2nd positional parameter\E/, '...with correct error message';

ok !eval{ nameless('foo',\1) },    'Failed nameless (bad Int, etc.) as expected';
like $@, qr/\QValue (\1) for unnamed 2nd positional parameter is not of type Int\E/, '...with correct error message';

ok !eval{ nameless() },            'Failed nameless (no args at all) as expected';
like $@, qr/\QNo argument found for unnamed 1st positional parameter\E/, '...with correct error message';


func namednameless(*%) { 1 }

ok namednameless(),                   'Nameless named slurpy (no args)';
ok namednameless(foo => 1),           'Nameless named slurpy (one arg)';
ok namednameless(foo => 1, foo => 2), 'Nameless named slurpy (repeated arg)';

ok !eval{ namednameless('foo'); 1},   'Nameless named slurpy (odd arg)';
like $@, qr/\QFinal key ("foo") for nameless slurpy parameter (*%) is missing its value\E/,
                                      '...with correct error message';


done_testing();

