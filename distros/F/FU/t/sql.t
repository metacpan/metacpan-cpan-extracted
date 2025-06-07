use v5.36;
use Test::More;
use FU::SQL;
use experimental 'builtin';

sub t($obj, $sql, $params, @opt) {
    my($gotsql, $gotparams) = $obj->compile(@opt);
    is $gotsql, $sql;
    is_deeply $gotparams, $params;
}

my @q_ident = (quote_identifier => sub($x) { $x =~ s/"/_/rg });

my $x;
t P '', '?', [''];
t P '', '$1', [''], placeholder_style => 'pg';
t P undef, '?', [undef];
t RAW '', '', [];
t IDENT '"hello"', '"hello"', [];
t IDENT '"hello"', '_hello_', [], @q_ident;
t SQL('select', '1'), 'select 1', [];
t SQL('select', P '1'), 'select ?', [1];
t SQL('select', $x = '1'), 'select ?', [1];
t SQL('select', RAW($x = 1)), 'select 1', [];
t SQL(builtin::true, {}, [], \1), '? ? ? ?', [builtin::true, {}, [], \1];
t SQL(builtin::true, {}, [], \1), '$1 $2 $3 $4', [builtin::true, {}, [], \1], placeholder_style => 'pg';
t SQL(map SQL($_), qw/a b c/), 'a b c', [];
t SQL(map SQL($_,$_.'x',$_), qw/a b c/), 'a ? a b ? b c ? c', ['ax','bx','cx'];
t SQL(map P($_), 1,2,3), '? ? ?', [1,2,3];
t SQL(map { $_ } 1,2,3), '? ? ?', [1,2,3];

$x = 'oops';
my $y = 'y';
t SQL("SELECT $x"), '?', ["SELECT $x"];

t PARENS('a', $x), '( a ? )', [$x];

t INTERSPERSE($x, 1, 'a'), '? ? a', [1, $x];
t INTERSPERSE('-', 'a', $x, $y), 'a - ? - ?', [$x, $y];

t COMMA('a', 'b', $x), 'a , b , ?', [$x];

t WHERE($x, '1 = 2', SQL('x = ', $x)),
  'WHERE ( ? ) AND ( 1 = 2 ) AND ( x = ? )', [$x, $x];
t WHERE({ col1 => RAW 'NOW()', col2 => 'a'}),
  'WHERE ( col1 = NOW() ) AND ( col2 = ? )', ['a'];
t WHERE(), 'WHERE 1=1', [];
t WHERE({ '"x' => 1 }), 'WHERE ( _x = ? )', [1], @q_ident;

t WHERE(AND('true', $x), OR($y, 'y'), AND, OR),
  'WHERE ( ( true ) AND ( ? ) ) AND ( ( ? ) OR ( y ) ) AND ( 1=1 ) AND ( 1=0 )', [$x, $y];

t OR({}), '1=0', [];

t SQL(SELECT => COMMA(qw/a b c/), FROM => 'table', WHERE { x => 1, a => undef }),
  'SELECT a , b , c FROM table WHERE ( a IS NULL ) AND ( x = ? )', [1];

t SET({ a => 1, c => RAW 'NOW()', d => undef }),
  'SET a = ? , c = NOW() , d = ?', [1, undef];
t SET({ '"x' => 1 }), 'SET _x = ?', [1], @q_ident;

t VALUES({ a => 1, c => RAW 'NOW()', d => undef }),
  '( a , c , d ) VALUES ( ? , NOW() , ? )', [1, undef];
t VALUES({ '"x' => 1 }), '( _x ) VALUES ( ? )', [1], @q_ident;

t VALUES(1, $x, 'NOW()', RAW 'NOW()'), 'VALUES ( ? , ? , NOW() , NOW() )', [1, $x];
t VALUES([1, $x, 'NOW()', RAW 'NOW()']), 'VALUES ( ? , ? , ? , NOW() )', [1, $x, 'NOW()'];

t VALUES(P {}), 'VALUES ( ? )', [{}];
t VALUES(P []), 'VALUES ( ? )', [[]];

t IN [1,2,'a',undef,$x], 'IN(?,?,?,?,?)', [1,2,'a',undef,$x];
t IN [1,2,'a',undef,$x], '= ANY(?)', [[1,2,'a',undef,$x]], in_style => 'pg';
t IN [], '= ANY($1)', [[]], in_style => 'pg', placeholder_style => 'pg';

t WHERE({ id => IN [1,2] }), 'WHERE ( id IN(?,?) )', [1,2];

sub somefunc { 'not actually const' }
t SQL(somefunc), '?', [somefunc];

use constant constval => 'this is a constant';
t SQL(constval), constval, [];

sub otherfunc { constval }
t SQL(otherfunc), '?', [otherfunc];

sub passthrough { $_[0] }
t SQL(passthrough 'hi'), '?', ['hi'];

use Hash::Util;
my %hash = (v => 'value');
Hash::Util::lock_keys(%hash);
Hash::Util::lock_value(%hash, 'v');
t SQL($hash{v}), 'value', [];

ok !eval { SQL('')->compile(oops => 1); 1 };
like $@, qr/Unknown flag: oops/;

done_testing;
