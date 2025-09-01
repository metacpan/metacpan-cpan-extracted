#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 143;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Format';

eval "use $module";
is( not($@), 1, 'could load the module');
use Graphics::Toolkit::Color::Space::Basis;
my $basis = Graphics::Toolkit::Color::Space::Basis->new([qw/alpha beta gamma/], undef, undef, 'alias');

my $form = Graphics::Toolkit::Color::Space::Format->new( );
like( $form,   qr/First argument/,  'constructor needs basis as first argument');

$form = Graphics::Toolkit::Color::Space::Format->new( $basis );
is( ref $form, $module,  'one constructor argument is enough');

my $pform = Graphics::Toolkit::Color::Space::Format->new( $basis, undef, undef,  '%' );
is( ref $pform, $module,  'used second argument: suffix');
my $ppobj = Graphics::Toolkit::Color::Space::Format->new( $basis, undef, undef, ['%','%','%','%'] );
is( ref $ppobj, '',  'too many elements in suffix definition');

my $vobj = Graphics::Toolkit::Color::Space::Format->new( $basis, '\d{2}', undef, '%' );
is( ref $pform, $module,  'used third argument argument: value format');
my $vvobj = Graphics::Toolkit::Color::Space::Format->new( $basis, [ '\d{2}','\d{2}','\d{2}','\d{2}' ], undef, '%' );
is( ref $vvobj, '',  'too many elements in value format definition');

my $cobj = Graphics::Toolkit::Color::Space::Format->new( $basis, [ '\d{1}','\d{2}','\d{3}' ], undef, ['$','@','%'] );
is( ref $cobj, $module, 'fully custom format definition');

my ($vals, $name) = $form->deformat('abg:0,2.2,-3');
is( ref $vals,        'ARRAY', 'could deformat values');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             0, 'first value');
is( $vals->[1],           2.2, 'secong value');
is( $vals->[2],            -3, 'third value');
is( $name,     'named_string', 'found right format name');

($vals, $name) = $pform->deformat('abg:1%,2%,3%');
is( ref $vals,        'ARRAY', 'could deformat values with suffix');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');
is( $name,     'named_string', 'found right format name');

($vals, $name) = $pform->deformat(' alias:1,2,3');
is( ref $vals,        'ARRAY', 'could deformat values with space name alias and leading space');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');
is( $name,     'named_string', 'found right format name');

($vals, $name) = $pform->deformat(' abg: 1%, 2% , 3%  ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in named string');
is( $name,     'named_string', 'recognized named string format');
($vals, $name) = $vobj->deformat(' abg: 1%, 2% , 3% ');
is( ref $vals,        '', 'values need to have two digits with custom value format');
($vals, $name) = $vobj->deformat(' abg: 11 %, 22 % , 33% ');
is( ref $vals,         '', 'can not have spaces before suffix');
($vals, $name) = $cobj->deformat(' abg: 1%, 2% , 3% ');
is( ref $vals,        '', 'ignored custom suffixed, brought wrong ones');
($vals, $name) = $cobj->deformat(' abg: 1$, 22@ , 333% ');
is( ref $vals,        'ARRAY', 'recognized custom format');
is( $name,     'named_string', 'found named string as custom format');
($vals, $name) = $pform->deformat(' abg:.1% .22%    0.33% ');
is( ref $vals,        'ARRAY', 'commas are optional');
is( @$vals,                 3, 'got all values');
cmp_ok( $vals->[0], '==',  .1, 'first value');
cmp_ok( $vals->[1], '==', .22, 'second value');
cmp_ok( $vals->[2], '==',0.33, 'third value');
is( $name,     'named_string', 'found named string as custom format');

($vals, $name) = $pform->deformat(' abg( 1%, 2% ,3%  ) ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in css string');
is( $name,       'css_string', 'recognized CSS string format');
($vals, $name) = $pform->deformat(' alias( 1%, 2% , 3% ) ');
is( ref $vals,        'ARRAY', 'deformatted css string with space name alias');
is( $name,       'css_string', 'recognized CSS string format');
($vals, $name) = $pform->deformat(' abg( 1 , 2  , 3 ) ');
is( ref $vals,        'ARRAY', 'ignored missing suffixes');
is( $name,       'css_string', 'recognized CSS string format');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');
($vals, $name) = $pform->deformat(' abg( .1 1.2  3 ) ');
is( ref $vals,        'ARRAY', 'commas in CSS string format are optional');
cmp_ok( $vals->[0], '==',  .1, 'first value');
cmp_ok( $vals->[1], '==', 1.2, 'second value');
cmp_ok( $vals->[2], '==',   3, 'third value');


($vals, $name) = $form->deformat( ['ABG',1,2,3] );
is( $name,       'named_array', 'recognized named array');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $form->deformat( ['ALIAs',1,2,3] );
is( $name,       'named_array', 'recognized named array with space name alias');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $form->deformat( ['ABG',' -1','2.2 ','.3'] );
is( $name,       'named_array', 'recognized named array with spaces');
is( ref $vals,         'ARRAY', 'got values in a vector');
is( @$vals,                  3, 'right amount of values');
cmp_ok( $vals->[0], '==',   -1, 'first value');
cmp_ok( $vals->[1], '==',  2.2, 'second value');
cmp_ok( $vals->[2], '==',   .3, 'third value');

($vals, $name) = $form->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with lc name');

($vals, $name) = $form->deformat( [' abg',1,2,3] );
is( ref $vals,              '', 'spaces in name are not acceptable');

($vals, $name) = $pform->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with suffix missing');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $pform->deformat( ['abg',' 1%',' .2%','.3% '] );
is( $name,       'named_array', 'recognized named array with suffixes');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
cmp_ok( $vals->[0], '==',    1, 'first value');
cmp_ok( $vals->[1], '==',   .2, 'second value');
cmp_ok( $vals->[2], '==',   .3, 'third value');

($vals, $name) = $form->deformat( {a=>1, b=>2, g=>3} );
is( $name,              'hash', 'recognized hash format');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $form->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash format with full names');
($vals, $name) = $pform->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash even when left suffixes');
($vals, $name) = $pform->deformat( {ALPHA =>'1%', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,            'hash', 'recognized hash with suffixes');
($vals, $name) = $vobj->deformat( {ALPHA =>'1%', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,             undef, 'values needed 2 digits in custom value format');
($vals, $name) = $vobj->deformat( {ALPHA =>'21 %', BETA =>'92% ', GAMMA=>' 13%'} );
is( $name,             undef, 'can not tolerate space before suffix');
($vals, $name) = $vobj->deformat( {ALPHA =>'21%', BETA =>'92% ', GAMMA=>' 13%'} );
is( $name,            'hash', 'recognized hash with suffixes and custom value format');

my (@list) = $form->format( [0,2.2,-3], 'list');
is( @list,                   3, 'got a list with right lengths');
is( $list[0],                0, 'first value');
is( $list[1],              2.2, 'second value');
is( $list[2],               -3, 'third value');

my $hash = $form->format( [0,2.2,-3], 'hash');
is( ref $hash,          'HASH', 'could format into HASH');
is( int keys %$hash,         3, 'right amount of keys');
is( $hash->{'alpha'},        0, 'first value');
is( $hash->{'beta'},       2.2, 'second value');
is( $hash->{'gamma'},       -3, 'third value');

$hash = $form->format( [0,2.2,-3], 'char_hash');
is( ref $hash,          'HASH', 'could format into HASH with character keys');
is( int keys %$hash,         3, 'right amount of keys');
is( $hash->{'a'},            0, 'first value');
is( $hash->{'b'},          2.2, 'second value');
is( $hash->{'g'},           -3, 'third value');

my $array = $form->format( [0,2.2,-3], 'named_array');
is( ref $array,          'ARRAY', 'could format into HASH with character keys');
is( int@$array,                4, 'right amount of elements');
is( $array->[0],           'ABG', 'first value is color space name');
is( $array->[1],               0, 'first numerical value');
is( $array->[2],             2.2, 'second numerical value');
is( $array->[3],              -3, 'third numerical value');

my $string = $form->format( [0,2.2,-3], 'named_string');
is( ref $string,                   '', 'could format into string');
is( $string,        'abg: 0, 2.2, -3', 'string syntax ist correct');

$string = $form->format( [0,2.2,-3], 'css_string');
is( ref $string,                '', 'could format into CSS string');
is( $string,     'abg(0, 2.2, -3)', 'string syntax ist correct');

$string = $pform->format( [0,2.2,-3], 'css_string');
is( ref $string,                 '', 'could format into CSS string with suffixes');
is( $string,   'abg(0%, 2.2%, -3%)', 'string syntax ist correct');


$string = $form->format( [0,2.2,-3], 'pstring');
is( $string,                    '', 'no pstring format found by universal formatter');
is( $form->has_formatter('pstring'), 0, 'there is no pstring format');

my $fref = $form->add_formatter('pstring', sub {return '%'.join ',',@{$_[1]}} );
is( ref $fref,       'CODE', 'added formatter');
$string = $form->format( [0,2.2,-3], 'pstring');
is( $string,           '%0,2.2,-3', 'formatted into pstring');
is( $form->has_formatter('pstring'), 1, 'there is now a pstring format');

($vals, $name) = $form->deformat( '%0,2.2,-3' );
is( $name,                 undef, 'found no deformatter for pstring format');
is( $form->has_deformatter('pstring'), 0, 'there is no pstring deformatter');

my $dref = $form->add_deformatter('pstring', sub { [split(',', substr($_[1] , 1))]  });
is( ref $dref,       'CODE', 'added deformatter');

is( $form->has_deformatter('pstring'), 1, 'there is now a pstring deformatter');
($vals, $name) = $form->deformat( '%0,2.2,-3' );
is( $name,                 'pstring', 'now found deformatter for pstring format');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              0, 'first value');
is( $vals->[1],            2.2, 'second value');
is( $vals->[2],             -3, 'third value');

is( $form->has_formatter('str'),                  0, 'formatter not yet inserted');
is( $form->has_formatter('bbb'), 0, 'vector name is not a format');
is( $form->has_formatter('c'),   0, 'vector sigil is not  a format');
is( $form->has_formatter('list'),1, 'list is a format');
is( $form->has_formatter('hash'),1, 'hash is a format');
is( $form->has_formatter('char_hash'),1, 'char_hash is a format');


exit 0;
