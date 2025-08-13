#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 127;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Format';

use_ok( $module, 'could load the module');
use Graphics::Toolkit::Color::Space::Basis;
my $basis = Graphics::Toolkit::Color::Space::Basis->new([qw/alpha beta gamma/], undef, undef, 'alias');

my $obj = Graphics::Toolkit::Color::Space::Format->new( );
like( $obj,   qr/First argument/,  'constructor needs basis as first argument');

$obj = Graphics::Toolkit::Color::Space::Format->new( $basis );
is( ref $obj, $module,  'one constructor argument is enough');

my $pobj = Graphics::Toolkit::Color::Space::Format->new( $basis, undef, undef,  '%' );
is( ref $pobj, $module,  'used second argument: suffix');
my $ppobj = Graphics::Toolkit::Color::Space::Format->new( $basis, undef, undef, ['%','%','%','%'] );
is( ref $ppobj, '',  'too many elements in suffix definition');

my $vobj = Graphics::Toolkit::Color::Space::Format->new( $basis, '\d{2}', undef, '%' );
is( ref $pobj, $module,  'used third argument argument: value format');
my $vvobj = Graphics::Toolkit::Color::Space::Format->new( $basis, [ '\d{2}','\d{2}','\d{2}','\d{2}' ], undef, '%' );
is( ref $vvobj, '',  'too many elements in value format definition');

my $cobj = Graphics::Toolkit::Color::Space::Format->new( $basis, [ '\d{1}','\d{2}','\d{3}' ], undef, ['$','@','%'] );
is( ref $cobj, $module, 'fully custom format definition');

my ($vals, $name) = $obj->deformat('abg:0,2.2,-3');
is( ref $vals,        'ARRAY', 'could deformat values');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             0, 'first value');
is( $vals->[1],           2.2, 'secong value');
is( $vals->[2],            -3, 'third value');
is( $name,     'named_string', 'found right format name');

($vals, $name) = $pobj->deformat('abg:1%,2%,3%');
is( ref $vals,        'ARRAY', 'could deformat values with suffix');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');
is( $name,     'named_string', 'found right format name');

($vals, $name) = $pobj->deformat(' alias:1,2,3');
is( ref $vals,        'ARRAY', 'could deformat values with space name alias and leading space');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');
is( $name,     'named_string', 'found right format name');

($vals, $name) = $pobj->deformat(' abg: 1 %, 2 % , 3% ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in named string');
is( $name,     'named_string', 'recognized named string format');
($vals, $name) = $vobj->deformat(' abg: 1 %, 2 % , 3% ');
is( ref $vals,        '', 'values need to have two digits with custom value format');
($vals, $name) = $vobj->deformat(' abg: 11 %, 22 % , 33% ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in named string with custom value format');
is( $name,     'named_string', 'recognized named string format with custom value format');
($vals, $name) = $cobj->deformat(' abg: 1 %, 2 % , 3% ');
is( ref $vals,        '', 'values custom format is not met');
($vals, $name) = $cobj->deformat(' abg: 1 $, 22 @ , 333% ');
is( ref $vals,        'ARRAY', 'recognized custom format');
is( $name,     'named_string', 'found named string as custom format');

($vals, $name) = $pobj->deformat(' abg( 1 %, 2 % , 3% ) ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in css string');
is( $name,       'css_string', 'recognized CSS string format');
($vals, $name) = $pobj->deformat(' alias( 1 %, 2 % , 3% ) ');
is( ref $vals,        'ARRAY', 'deformatted css string with space name alias');
is( $name,       'css_string', 'recognized CSS string format');
($vals, $name) = $pobj->deformat(' abg( 1 , 2  , 3 ) ');
is( ref $vals,        'ARRAY', 'ignored missing suffixes');
is( $name,       'css_string', 'recognized CSS string format');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');


($vals, $name) = $obj->deformat( ['ABG',1,2,3] );
is( $name,       'named_array', 'recognized named array');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $obj->deformat( ['ALIAs',1,2,3] );
is( $name,       'named_array', 'recognized named array with space name alias');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $obj->deformat( ['ABG',' -1','2.2 ','.3'] );
is( $name,       'named_array', 'recognized named array with spaces');
is( ref $vals,         'ARRAY', 'got values in a vector');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],             -1, 'first value');
is( $vals->[1],            2.2, 'second value');
is( $vals->[2],             .3, 'third value');

($vals, $name) = $obj->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with lc name');

($vals, $name) = $obj->deformat( [' abg',1,2,3] );
is( ref $vals,              '', 'spaces in name are not acceptable');

($vals, $name) = $pobj->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with suffix missing');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $pobj->deformat( ['abg',' 1%',' 2 %','3% '] );
is( $name,       'named_array', 'recognized named array with suffix missing');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $obj->deformat( {a=>1, b=>2, g=>3} );
is( $name,              'hash', 'recognized hash format');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $obj->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash format with full names');
($vals, $name) = $pobj->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash even when left suffixes');
($vals, $name) = $pobj->deformat( {ALPHA =>'1 %', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,            'hash', 'recognized hash with suffixes');
($vals, $name) = $vobj->deformat( {ALPHA =>'1 %', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,             undef, 'values needed 2 digits in custom value format');
($vals, $name) = $vobj->deformat( {ALPHA =>'21 %', BETA =>'92% ', GAMMA=>' 13%'} );
is( $name,            'hash', 'recognized hash with suffixes and custom value format');

my (@list) = $obj->format( [0,2.2,-3], 'list');
is( @list,                   3, 'got a list with right lengths');
is( $list[0],                0, 'first value');
is( $list[1],              2.2, 'second value');
is( $list[2],               -3, 'third value');

my $hash = $obj->format( [0,2.2,-3], 'hash');
is( ref $hash,          'HASH', 'could format into HASH');
is( int keys %$hash,         3, 'right amount of keys');
is( $hash->{'alpha'},        0, 'first value');
is( $hash->{'beta'},       2.2, 'second value');
is( $hash->{'gamma'},       -3, 'third value');

$hash = $obj->format( [0,2.2,-3], 'char_hash');
is( ref $hash,          'HASH', 'could format into HASH with character keys');
is( int keys %$hash,         3, 'right amount of keys');
is( $hash->{'a'},            0, 'first value');
is( $hash->{'b'},          2.2, 'second value');
is( $hash->{'g'},           -3, 'third value');

my $array = $obj->format( [0,2.2,-3], 'named_array');
is( ref $array,          'ARRAY', 'could format into HASH with character keys');
is( int@$array,                4, 'right amount of elements');
is( $array->[0],           'ABG', 'first value is color space name');
is( $array->[1],               0, 'first numerical value');
is( $array->[2],             2.2, 'second numerical value');
is( $array->[3],              -3, 'third numerical value');

my $string = $obj->format( [0,2.2,-3], 'named_string');
is( ref $string,              '', 'could format into string');
is( $string,       'abg: 0, 2.2, -3', 'string syntax ist correct');

$string = $obj->format( [0,2.2,-3], 'css_string');
is( ref $string,                '', 'could format into CSS string');
is( $string,       'abg(0, 2.2, -3)', 'string syntax ist correct');

$string = $pobj->format( [0,2.2,-3], 'css_string');
is( ref $string,                '', 'could format into CSS string with suffixes');
is( $string,       'abg(0%, 2.2%, -3%)', 'string syntax ist correct');


$string = $obj->format( [0,2.2,-3], 'pstring');
is( $string,                    '', 'no pstring format found by universal formatter');
is( $obj->has_format('pstring'), 0, 'there is no pstring format');

my $fref = $obj->add_formatter('pstring', sub {return '%'.join ',',@{$_[1]}});
is( ref $fref,       'CODE', 'added formatter');
$string = $obj->format( [0,2.2,-3], 'pstring');
is( $string,           '%0,2.2,-3', 'formatted into pstring');
is( $obj->has_format('pstring'), 1, 'there is now a pstring format');

($vals, $name) = $obj->deformat( '%0,2.2,-3' );
is( $name,                 undef, 'found no deformatter for pstring format');
is( $obj->has_deformat('pstring'), 0, 'there is no pstring deformatter');

my $dref = $obj->add_deformatter('pstring', sub { $_[0]->check_number_values( [split(',',substr($_[1],1))] ); });
is( ref $dref,       'CODE', 'added deformatter');

is( $obj->has_deformat('pstring'), 1, 'there is now a pstring deformatter');
($vals, $name) = $obj->deformat( '%0,2.2,-3' );
is( $name,                 'pstring', 'now found deformatter for pstring format');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              0, 'first value');
is( $vals->[1],            2.2, 'second value');
is( $vals->[2],             -3, 'third value');

exit 0;
