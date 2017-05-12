use Test::More tests => 43;    # (39 + (43 * 2));
use Test::Warn;

use Locale::Maketext::Utils::Phrase;

my $non_translatable_type_regexp = Locale::Maketext::Utils::Phrase::get_non_translatable_type_regexp();
is( ref($non_translatable_type_regexp), 'Regexp', 'get_non_translatable_type_regexp() gives regexp reference' );
like( "var", qr/\A$non_translatable_type_regexp\z/, 'regex matches correctly' );
unlike( "complex", qr/\A$non_translatable_type_regexp\z/, 'regex fails to match coorectly' );

my $bn_var_regexp = Locale::Maketext::Utils::Phrase::get_bn_var_regexp();
is( ref($bn_var_regexp), 'Regexp', 'get_bn_var_regexp() gives regexp reference' );

like( "_1",  qr/\A$bn_var_regexp\z/, 'regex matches normal' );
like( "_0",  qr/\A$bn_var_regexp\z/, 'regex matches normal (zero, even though its an odd argument to reference)' );
like( "_-1", qr/\A$bn_var_regexp\z/, 'regex matches negative' );
like( "_*",  qr/\A$bn_var_regexp\z/, 'regex matches star' );

like( "X _1 Y",  qr/$bn_var_regexp/, 'regex unanchored matches normal' );
like( "X _0 Y",  qr/$bn_var_regexp/, 'regex unanchored matches normal (zero, even though its an odd argument to reference)' );
like( "X _-1 Y", qr/$bn_var_regexp/, 'regex unanchored matches negative' );
like( "X _* Y",  qr/$bn_var_regexp/, 'regex unanchored matches star' );

unlike( "~_1",  qr/\A$bn_var_regexp\z/, 'regex !matches escaped normal' );
unlike( "~_0",  qr/\A$bn_var_regexp\z/, 'regex !matches escaped normal (zero, even though its an odd argument to reference)' );
unlike( "~_-1", qr/\A$bn_var_regexp\z/, 'regex !matches escaped negative' );
unlike( "~_*",  qr/\A$bn_var_regexp\z/, 'regex !matches escaped star' );

unlike( "X ~_1 Y",  qr/$bn_var_regexp/, 'regex unanchored !matches escaped normal' );
unlike( "X ~_0 Y",  qr/$bn_var_regexp/, 'regex unanchored !matches escaped normal (zero, even though its an odd argument to reference)' );
unlike( "X ~_-1 Y", qr/$bn_var_regexp/, 'regex unanchored !matches escaped negative' );
unlike( "X ~_* Y",  qr/$bn_var_regexp/, 'regex unanchored !matches escaped star' );

ok( Locale::Maketext::Utils::Phrase::string_has_opening_or_closing_bracket("yo ["),      'string_has_opening_or_closing_bracket() [ is true' );
ok( Locale::Maketext::Utils::Phrase::string_has_opening_or_closing_bracket("yo ]"),      'string_has_opening_or_closing_bracket() [ is true' );
ok( !Locale::Maketext::Utils::Phrase::string_has_opening_or_closing_bracket("yo ~["),    'string_has_opening_or_closing_bracket() ~[ is false' );
ok( !Locale::Maketext::Utils::Phrase::string_has_opening_or_closing_bracket("yo ~["),    'string_has_opening_or_closing_bracket() ~[ is false' );
ok( !Locale::Maketext::Utils::Phrase::string_has_opening_or_closing_bracket("yo howdy"), 'string_has_opening_or_closing_bracket() (none) is false' );

is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont("1,2,3") ], [ 1, 2, 3 ], "split no limit" );
is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont( "1,2,3", 0 ) ], [ 1, 2, 3 ], "split 0 limit" );
warning_like {
    is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont( "1,2,3", "abc" ) ], [ 1, 2, 3 ], "split non-numeric limit" );
}
qr/Argument "abc" isn't numeric in int/i, "non-numeric limit issues warning";

is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont( "1,2,3", -2 ) ], [ 1, "2,3" ], "split negative limit ignores negativity" );
is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont( "1,2,3", 2 ) ],  [ 1, "2,3" ], "split actual limit" );
is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont( "1,2",   3 ) ],  [ 1, 2 ],     "split actual limit more than parts" );
is_deeply( [ Locale::Maketext::Utils::Phrase::_split_bn_cont("1~,2,3~,4") ], [ '1~,2', '3~,4' ], "split w/ esscaped delimeter" );

is_deeply(
    { Locale::Maketext::Utils::Phrase::_get_attr_hash_from_list( [qw(output strong foo key val key2 _2)], 3 ) },
    {qw(key val key2 _2)},
    '_get_attr_hash_from_list() no refs',
);

is_deeply(
    { Locale::Maketext::Utils::Phrase::_get_attr_hash_from_list( [qw(output strong foo _1 key val key2 _2)], 3 ) },
    {qw(key val key2 _2)},
    '_get_attr_hash_from_list() begin ref',
);

is_deeply(
    { Locale::Maketext::Utils::Phrase::_get_attr_hash_from_list( [qw(output strong foo key val key2 _2 _1)], 3 ) },
    {qw(key val key2 _2)},
    '_get_attr_hash_from_list() end ref',
);

is_deeply(
    { Locale::Maketext::Utils::Phrase::_get_attr_hash_from_list( [qw(output strong foo key val _1 key2 _2 _1)], 3 ) },
    {qw(key val key2 _2)},
    '_get_attr_hash_from_list() mid ref',
);

is_deeply(
    { Locale::Maketext::Utils::Phrase::_get_attr_hash_from_list( [qw(output strong foo _1 key val _3 key2 _2 _4)], 3 ) },
    {qw(key val key2 _2)},
    '_get_attr_hash_from_list() mulit ref',
);

is_deeply(
    { Locale::Maketext::Utils::Phrase::_get_attr_hash_from_list( [qw(output strong foo _1 _1 key val _3 _3  key2 _2 _4 _4)], 3 ) },
    {qw(key val key2 _2)},
    '_get_attr_hash_from_list() mulit ref',
);

use Locale::Maketext::Utils::Mock ();
my $lh = Locale::Maketext::Utils::Mock->get_handle();
$lh->set_context_html();
is( $lh->makethis('A tilde is this: _TILDE_, you like?'), 'A tilde is this: ~, you like?', '_TILDE_ in text renders' );
is( $lh->makethis('A tilde [output,strong,is this: _TILDE_~, you like]?'), 'A tilde <strong>is this: ~, you like</strong>?', '_TILDE_ in text renders' );

is_deeply(
    Locale::Maketext::Utils::Phrase::phrase2struct('A tilde is this: _TILDE_, you like?'),
    ['A tilde is this: _TILDE_, you like?'],
    '_TILDE_ in text parses',
);

is_deeply(
    Locale::Maketext::Utils::Phrase::phrase2struct('A tilde [output,strong,is this: _TILDE_~, you like]?'),
    [
        'A tilde ',
        {
            'orig' => '[output,strong,is this: _TILDE_~, you like]',
            'cont' => 'output,strong,is this: _TILDE_~, you like',
            'list' => [
                'output',
                'strong',
                'is this: _TILDE_~, you like',
            ],
            'type' => 'basic',
        },
        '?',
    ],
    '_TILDE_ in BN parses',
);

