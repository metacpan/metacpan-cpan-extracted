use warnings;
use strict;
use Test::More;

use Dios;

plan tests => 4;

subtest 'String literals' => sub {
    multi cmd('add2', $cmd, 'add')  { is $cmd, 'add', 'Add correct' }

    multi cmd('sub2', $cmd, 'sub')  { is $cmd, 'sub', 'Sub correct' }

    multi cmd('other2', $cmd where { !/add|sub/ }, qq{$cmd}) {
        isnt $cmd, 'add',   'cmd not add correct';
        isnt $cmd, 'sub',   'cmd not sub correct';
    }

    multi cmd('diff', $cmd, $other) {
        isnt $cmd,   'add',   'cmd not add correct';
        isnt $cmd,   'sub',   'cmd not sub correct';
        isnt $other, 'add',   'other not add correct';
        isnt $other, 'sub',   'other not sub correct';
        isnt $cmd,   $other,  'cmd not other correct';
    }

    cmd('add2',   'add',   'add');
    cmd('sub2',   'sub',   'sub');
    cmd('other2', 'other', 'other');
    cmd('diff',   'other', 'nother');
};

subtest 'Numeric literals' => sub {
    multi name (0)  { 'zero' }
    multi name (1)  { 'one'  }
    multi name ($n) { 'many'.name($n-6).name($n-7) }

    is name(0), 'zero',        'Zero name';
    is name(1), 'one',         'One name';
    is name(7), 'manyonezero', 'Seven name';
};

subtest 'Regex literals' => sub {
    multi meta (m/foo/)         { 'foo' }
    multi meta (/ ba [rz] /xi)  { 'bar' }
    multi meta ($x)             { uc $x }

    is meta('foo'), 'foo', 'foo';
    is meta('bar'), 'bar', 'bar';
    is meta('Bar'), 'bar', 'Bar';
    is meta('BAR'), 'bar', 'BAR';
    is meta('bAz'), 'bar', 'bAz';
    is meta('qux'), 'QUX', 'qux';
    is meta('bat'), 'BAT', 'bat';
};

subtest 'Error messages' => sub {

    func str('str') { 'str' }

    is str('str'), 'str', 'Normal str call ok';

    ok !eval{ str('other'); 1}, 'Other str failed';
    like $@, qr/\QValue ("other") for unnamed 1st positional parameter did not satisfy the constraint\E/,
                                'Correct error message';

    ok !eval{ str(\1); 1}, '\1 str failed';
    like $@, qr/\QValue (\1) for unnamed 1st positional parameter is not of type Str\E/,
                                'Correct error message';

    ok !eval{ str(); 1}, 'no param str failed';
    like $@, qr/\QNo argument found for unnamed 1st positional parameter \E/,
                                'Correct error message';


    func num($ultimate, $answer, 42) { 42 }

    is num(0,0,42), 42, 'Normal num call ok';

    ok !eval{ num(0,0,86); 1}, 'Other num failed';
    like $@, qr/\QValue (86) for unnamed 3rd positional parameter did not satisfy the constraint\E/,
                                'Correct error message';

    ok !eval{ num(0,0,\1); 1}, '\1 failed';
    like $@, qr/\QValue (\1) for unnamed 3rd positional parameter is not of type Num\E/,
                                'Correct error message';
};

done_testing();

