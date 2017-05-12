use strict;
use warnings;

use Test::More;
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update var_append var_getreset var_length/;

ok my $id = var_create(), 'var_create';

ok ! var_read(undef), 'var_read (undef)';
is var_read($id), '', 'var_read (init empty test)';

ok var_update($id, "test"), 'var_update';
my $read = var_read($id);
is $read, 'test', 'var_read';
$read = "hoge";
is var_read($id), 'test', 'var_read ref test';

is var_length($id), 4, 'var_length';

ok ! var_update(undef,"test2"), 'var_update (undef id)';

ok var_update($id, undef), 'var_update (val empty)';
is var_read($id), '', 'var_read (val empty)';
ok var_update($id, ''), 'var_update (val "")';
is var_read($id), '', 'var_read (val "")';

ok ! var_read(-1), 'var_read (id -1)';

var_update($id, "abcdefg");
var_update($id, "abc");
is var_read($id), 'abc';

ok var_append($id, 'def'), 'var_append';
is var_read($id), 'abcdef', 'var_append, result confirm';

is var_getreset($id), 'abcdef', 'var_getreset';
is var_read($id), '', 'after var_getreset';

ok var_destory($id), 'var_destory';
ok ! var_destory(undef), 'var_destory (fail)';
ok ! var_destory(-1), 'var_destory (-1)';

done_testing;
