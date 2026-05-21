#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 91;

my $module = 'Graphics::Toolkit::Color::Space::Format';
eval "use $module";
is( not($@), 1, 'could load the module'); #say $@;
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

#### deformat ##########################################################
# named string
my ($vals, $name) = $form->deformat('abg:0,2.2,-3');
is( $name,     'named_string', 'found right format name');
is_tuple( $vals, [0, 2.2, -3], [qw/first second third/], 'deformat named string');
($vals, $name) = $pform->deformat('abg:1%,2%,3%');
is( $name,     'named_string', 'found right format name');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat values with suffix');
($vals, $name) = $pform->deformat(' alias:1,2,3');
is( $name,     'named_string', 'found right format name');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat values with space name alias and leading space');
($vals, $name) = $pform->deformat(' abg: 1%, 2% , 3%  ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in named string');
is( $name,     'named_string', 'recognized named string format');
($vals, $name) = $vobj->deformat(' abg: 1%, 2% , 3% ');
is( ref $vals,        '', 'values need to have two digits with custom value format');
($vals, $name) = $vobj->deformat(' abg: 11 %, 22 % , 33% ');
is( ref $vals,    'ARRAY', 'can have spaces before suffix');

($vals, $name) = $cobj->deformat(' abg: 1%, 2% , 3% ');
is( ref $vals,        '', 'ignored custom suffixed, brought wrong ones');
($vals, $name) = $cobj->deformat(' abg: 1$, 22@ , 333% ');
is( $name,     'named_string', 'found named string as custom format');
is_tuple( $vals, [1, 22, 333], [qw/first second third/], ' deformat named string with custom suffix');
($vals, $name) = $pform->deformat(' abg:.1% .22%    0.33% ');
is( $name,     'named_string', 'found format of named string');
is_tuple( $vals, [.1, .22, .33], [qw/first second third/], 'deformat named string without commas');

# CSS string
($vals, $name) = $pform->deformat(' abg( 1%, 2% ,3%  ) ');
is( $name,       'css_string', 'recognized CSS string format');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat CSS string with commas and suffix');

($vals, $name) = $pform->deformat(' alias( 1%, 2% , 3% ) ');
is( $name,       'css_string', 'recognized CSS string format');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat CSS string with commas and suffix and weird spacing');

($vals, $name) = $pform->deformat(' abg( 1 , 2  , 3 ) ');
is( $name,       'css_string', 'recognized CSS string format');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat CSS string and ignored missing suffix');

($vals, $name) = $pform->deformat(' abg( .1 1.2  3 ) ');
is_tuple( $vals, [.1, 1.2, 3], [qw/first second third/], 'deformat CSS string wthout commas');

($vals, $name) = $pform->deformat(' abg( .1 1.2  3 %) ');
is( ref $vals, '', 'deformat CSS: suffix and no commas does not work');

# named array
($vals, $name) = $form->deformat( ['ABG',1,2,3] );
is( $name,       'named_array', 'recognized named array');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat named array and ints');

($vals, $name) = $form->deformat( ['ALIAs',1,2,3] );
is( $name,       'named_array', 'recognized named array with space name alias');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat named array using space name alias');

($vals, $name) = $form->deformat( ['ABG',' -1','2.2 ','.3'] );
is( $name,       'named_array', 'recognized named array with spaces');
is_tuple( $vals, [-1, 2.2, .3], [qw/first second third/], 'deformat named array with various number formats');

($vals, $name) = $form->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with lc name');

($vals, $name) = $form->deformat( [' abg',1,2,3] );
is( ref $vals,         'ARRAY', 'spaces in name are acceptable');

($vals, $name) = $pform->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with suffix missing');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat values of named array with suffix missing');

($vals, $name) = $pform->deformat( ['abg',' 1%',' .2%','.3% '] );
is( $name,       'named_array', 'recognized named array with suffixes');
is_tuple( $vals, [1, .2, .3], [qw/first second third/], 'deformat values of named array with suffix');

# hash
($vals, $name) = $form->deformat( {a=>1, b=>2, g=>3} );
is( $name,              'hash', 'recognized hash format');
is_tuple( $vals, [1, 2, 3], [qw/first second third/], 'deformat hash with short axis names');
($vals, $name) = $form->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash format with full names');
($vals, $name) = $pform->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash even when left suffixes');
($vals, $name) = $pform->deformat( {ALPHA =>'1%', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,            'hash', 'recognized hash with suffixes');
($vals, $name) = $vobj->deformat( {ALPHA =>'1%', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,             undef, 'values needed 2 digits in custom value format');
($vals, $name) = $vobj->deformat( {ALPHA =>'21 %', BETA =>'92% ', GAMMA=>' 13%'} );
is( $name,            'hash', 'can tolerate space before suffix');
($vals, $name) = $vobj->deformat( {ALPHA =>'21%', BETA =>'92% ', GAMMA=>' 13%'} );
is( $name,            'hash', 'recognized hash with suffixes and custom value format');

#### format ############################################################
# list
my (@list) = $form->format( [0,2.2,-3], 'list');
is_tuple( \@list, [0, 2.2, -3], [qw/first second third/], 'format list');

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
is_tuple( $vals, [0, 2.2, -3], [qw/first second third/], 'deformat custom pstring format');

is( $form->has_formatter('str'),                  0, 'formatter not yet inserted');
is( $form->has_formatter('bbb'), 0, 'vector name is not a format');
is( $form->has_formatter('c'),   0, 'vector sigil is not  a format');
is( $form->has_formatter('list'),1, 'list is a format');
is( $form->has_formatter('hash'),1, 'hash is a format');
is( $form->has_formatter('char_hash'),1, 'char_hash is a format');

exit 0;
