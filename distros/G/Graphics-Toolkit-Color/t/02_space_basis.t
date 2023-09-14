#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 105;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Basis';

eval "use $module";
is( not($@), 1, 'could load the module');

my $obj = Graphics::Toolkit::Color::Space::Basis->new();
is( $obj,  undef,       'constructor needs arguments');

$obj = Graphics::Toolkit::Color::Space::Basis->new([1]);
is( ref $obj, $module,  'one constructor argument is enough');

my $bad = Graphics::Toolkit::Color::Space::Basis->new(qw/Aleph beth gimel daleth he/);
my $s3d = Graphics::Toolkit::Color::Space::Basis->new([qw/Alpha beta gamma/]);
my $s5d = Graphics::Toolkit::Color::Space::Basis->new([qw/Aleph beth gimel daleth he/], [qw/m n o p q/]);

is( $bad,  undef,     'need as els axis name array as argument');
is( ref $s3d,  $module,   'created 3d space');
is( ref $s5d,  $module,   'created 5d space');

is( $s3d->count,         3,     'did count three args');
is( $s5d->count,         5,     'did count five args');
is( ($s3d->keys)[0],    'alpha',     'repeat first 3d key back');
is( ($s3d->keys)[-1],   'gamma',     'repeat last 5d key back');
is( ($s5d->keys)[0],    'aleph',     'repeat first 3d key back');
is( ($s5d->keys)[-1],   'he',        'repeat last 5d key shortcut back');
is( ($s3d->shortcuts)[0],    'a',    'repeat first 3d key shortcut back');
is( ($s3d->shortcuts)[-1],   'g',    'repeat last 5d key shortcut back');
is( ($s5d->shortcuts)[0],    'm',    'repeat first 3d key shortcut back');
is( ($s5d->shortcuts)[-1],   'q',    'repeat last 5d key shortcut back');
is( $s3d->name,         'ABG',       'correct name from 3 initials');
is( $s5d->name,       'MNOPQ',     'correct name from 5 initials');
is( ($s3d->iterator)[-1],   2,       'correct last value of 0..2 iterator');
is( ($s5d->iterator)[-1],   4,       'correct last value of 0..4 iterator');

is( $s3d->is_key('Alpha'),  1,       'found key alpha');
is( $s3d->is_key('zeta'),   0,       'not found made up key zeta');
is( $s5d->is_key('gimel'),  1,       'found key gimel');
is( $s5d->is_key('lamed'),  0,       'not found made up key lamed');

is( $s3d->is_shortcut('G'),   1,      'found key shortcut g');
is( $s3d->is_shortcut('e'),   0,      'not found made up key shortcut e');
is( $s5d->is_shortcut('P'),   1,      'found key shortcut H');
is( $s5d->is_shortcut('l'),   0,      'not found made up key shortcut l');

is( $s3d->is_key_or_shortcut('Alpha'),  1, 'alpha is a key');
is( $s3d->is_key_or_shortcut('A'),      1, 'a is a shortcut');
is( $s3d->is_key_or_shortcut('Cen'),    0, 'Cen is not a key');
is( $s3d->is_key_or_shortcut('C'),      0, 'c is not a shortcut');

is( $s3d->is_array({}),                 0, 'HASH is not an ARRAY');
is( $s3d->is_array([]),                 0, 'empty ARRAY has not enogh content');
is( $s3d->is_array([2,2]),              0, 'too small ARRAY');
is( $s3d->is_array([1,2,3,4]),          0, 'too large ARRAY');
is( $s3d->is_array([1,2,3]),            1, 'correctly sized value ARRAY');

is( $s3d->is_hash([]),        0,      'array is not a hash');
is( $s3d->is_hash({alpha => 1, beta => 20, gamma => 3}), 1, 'valid hash with right keys');
is( $s3d->is_hash({ALPHA => 1, Beta => 20, gamma => 3}), 1, 'key casing gets ignored');
is( $s3d->is_hash({a => 1, b => 1, g => 3}),             1, 'valid shortcut hash');
is( $s3d->is_hash({a => 1, B => 1, g => 3}),             1, 'shortcut casing gets ignored');
is( $s3d->is_hash({a => 1, b => 1, g => 3, h => 4}),     0, 'too many hash key shortcut ');
is( $s3d->is_hash({alph => 1, beth => 1, gimel => 4, daleth => 2, he => 4}), 0, 'one wrong hash key');

is( $s5d->is_partial_hash([]),   0,      'array is not a partial hash');
is( $s5d->is_partial_hash({aleph => 1, beth => 2, gimel => 3, daleth => 4, he => 5}), 1, 'valid hash with right keys is also correct partial hash');
is( $s5d->is_partial_hash({aleph => 1, beth => 20, gimel => 3, daleth => 4, he => 5, o => 6}), 0, 'partial hash can not have more keys than full hash definition');
is( $s5d->is_partial_hash({aleph => 1 }),              1, 'valid partial hash to have only one korrect key');
is( $s5d->is_partial_hash({ALEPH => 1 }),              1, 'ignore casing');
is( $s5d->is_partial_hash({aleph => 1, bet => 2, }),  0, 'one bad key makes partial invalid');

is( $s3d->key_pos('alpha'),  0,         'alpha is the first key');
is( $s3d->key_pos('beta'),   1,         'beta is the second key');
is( $s3d->key_pos('emma'),   undef,     'emma is not akey');
is( $s5d->key_pos('aleph'),  0,         'aleph is the first key');
is( $s5d->key_pos('he'),     4,         'he is the fourth key');
is( $s5d->key_pos('emma'),   undef,     'emma is not akey');


is( ref $s3d->shortcut_hash_from_list(1,2,3),  'HASH',      'HASH with given values and shortcut keys created');
is( ref $s3d->shortcut_hash_from_list(1,2,3,4),    '',      'HASH not created because too many arguments');
is( ref $s3d->shortcut_hash_from_list(1,2),        '',      'HASH not created because not enough arguments');
is( $s3d->shortcut_hash_from_list(1,2,3)->{'a'},  1,        'right value under "a" key in the converted hash');
is( $s3d->shortcut_hash_from_list(1,2,3)->{'b'},  2,        'right value under "b" key in the converted hash');
is( $s3d->shortcut_hash_from_list(1,2,3)->{'g'},  3,        'right value under "g" key in the converted hash');
is( int keys %{$s3d->shortcut_hash_from_list(1,2,3)},  3,   'right amount of shortcut keys');

is( ref $s5d->key_hash_from_list(1,2,3,4,5),  'HASH',      'HASH with given values and full name keys created');
is( ref $s5d->key_hash_from_list(1,2,3,4,5,6),    '',      'HASH not created because too many arguments');
is( ref $s5d->key_hash_from_list(1,2,3,4),        '',      'HASH not created because not enough arguments');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'aleph'},  1,    'right value under "aleph" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'beth'},   2,    'right value under "beta" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'gimel'},  3,    'right value under "gimel" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'daleth'}, 4,    'right value under "daleth" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'he'},     5,    'right value under "he" key in the converted hash');
is( int keys %{$s5d->key_hash_from_list(1,2,3,4,5)}, 5,    'right amount of shortcut keys');

my @list = $s5d->list_from_hash( {aleph => 1, beth => 2, gimel => 3, daleth => 4, he => 5} );
is( int @list,  5, 'right of values extracted keys');
is( $list[0],   1, 'first extracted value is correct');
is( $list[1],   2, 'second extracted value is correct');
is( $list[2],   3, 'third extracted value is correct');
is( $list[3],   4, 'fourth extracted value is correct');
is( $list[4],   5, 'fifth extracted value is correct');
@list = $s5d->list_from_hash( {aleph => 1, beth => 2, O => 3, daleth => 4, y => 5} );
is( $list[0],  undef, 'no values extraced because one key was wrong');

is( $s3d->list_value_from_key('alpha', 1,2,3), 1,   'got correct first value from list by key');
is( $s3d->list_value_from_key('beta', 1,2,3),  2,   'got correct second value from list by key');
is( $s3d->list_value_from_key('gamma', 1,2,3), 3,   'got correct third value from list by key');
is( $s3d->list_value_from_key('he', 1,2,3), undef,  'get undef when asking with unknown key');
is( $s3d->list_value_from_key('alpha', 1,2), undef, 'get undef when giving not enough values');

is( $s3d->list_value_from_shortcut('a', 1,2,3), 1,       'got correct first value from list by shortcut');
is( $s3d->list_value_from_shortcut('b', 1,2,3), 2,       'got correct second value from list by shortcut');
is( $s3d->list_value_from_shortcut('g', 1,2,3), 3,       'got correct third value from list by shortcut');
is( $s3d->list_value_from_shortcut('h', 1,2,3), undef,   'get undef when asking with unknown key');
is( $s3d->list_value_from_key('a ', 1,2), undef,         'get undef when giving not enough values');


is( $s3d->deformat_partial_hash(),   undef,       'partial deformat needs an HASH');
is( $s3d->deformat_partial_hash({}), undef,       'partial deformat needs an not empty HASH');
is( $s3d->deformat_partial_hash({a=>1,b=>1,g=>1,k=>1}), undef,       'partial HASH is too long');
is( ref $s3d->deformat_partial_hash({a=>1,b=>2,g=>3}), 'HASH',       'partial HASH has all the keys');
my $ph = $s3d->deformat_partial_hash({Alpha=>1,b=>2,g=>3});
is( ref $ph, 'HASH',   'deparse all keys with mixed case and shortcut');
is( $ph->{0}, 1,       'first key has right value');
is( $ph->{1}, 2,       'second key has right value');
is( $ph->{2}, 3,       'third key has right value');
is( int keys %$ph, 3,  'right amount of keys in deparsed hash');

$ph = $s3d->deformat_partial_hash({gamma => 3});
is( ref $ph, 'HASH',   'deparse just one key with mixed case and shortcut');
is( $ph->{2}, 3,       'third and only key has right value');
is( int keys %$ph, 1,  'right amount of keys in deparsed hash');

$ph = $s5d->deformat_partial_hash({Aleph => 6, q => 5});
is( ref $ph, 'HASH',   'deparse just two keys with mixed case and shortcut');
is( $ph->{0}, 6,       'first key aleph has right value');
is( $ph->{4}, 5,       'second key He has right value');
is( int keys %$ph, 2,  'right amount of keys in deparsed hash');

exit 0;
