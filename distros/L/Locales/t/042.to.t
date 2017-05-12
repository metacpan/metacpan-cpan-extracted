
# Auto generated during CLDR build

use Test::More tests => 13 + 1102;

use lib 'lib', '../lib';

BEGIN {
    use_ok('Locales::DB::Language::to');
    use_ok('Locales::DB::Territory::to');
}

diag("Sanity checking Locales::DB::Language::to $Locales::DB::Language::to::VERSION DB");

use Locales;
use Locales::DB::Language::en;
use Locales::DB::Territory::en;

my @en_lang_codes = sort( keys %Locales::DB::Language::en::code_to_name );
my @en_terr_codes = sort( keys %Locales::DB::Territory::en::code_to_name );

my @my_lang_codes = sort( keys %Locales::DB::Language::to::code_to_name );
my @my_terr_codes = sort( keys %Locales::DB::Territory::to::code_to_name );
my %lang_lu;
my %terr_lu;
@lang_lu{@my_lang_codes} = ();
@terr_lu{@my_terr_codes} = ();
ok( $Locales::DB::Language::to::cldr_version eq $Locales::cldr_version,  'CLDR version is correct' );
ok( $Locales::DB::Language::to::VERSION eq ( $Locales::VERSION - 0.25 ), 'VERSION is correct' );

ok( !( grep { !exists $lang_lu{$_} } @en_lang_codes ), 'to languages contains en' );
ok( !( grep { !exists $terr_lu{$_} } @en_terr_codes ), 'to territories contains en' );

my %uniq = ();
grep { not $uniq{$_}++ } @{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_list'} };
is_deeply(
    [ sort @{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_list'} } ],
    [ sort keys %uniq ],
    "'category_list' contains no duplicates"
);

ok( grep( m/^other$/, @{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_list'} } ), "'category_list' has 'other'" );

is_deeply(
    [ grep !m/^other$/, sort @{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_list'} } ],
    [ grep !m/^other$/, sort keys %{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules'} } ],
    "'category_rules' has necessary 'category_list' items"
);

is_deeply(
    [ sort keys %{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules'} } ],
    [ sort keys %{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules_compiled'} } ],
    "each 'category_rules' has a 'category_rules_compiled'"
);
my $ok_rule_count = 0;
my $error         = '';
for my $rule ( keys %{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules_compiled'} } ) {
    if ( ref( $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules_compiled'}{$rule} ) eq 'CODE' ) {
        $ok_rule_count++;
        next;
    }
    eval $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules_compiled'}{$rule};
    if ($@) {
        $error .= $@;
        next;
    }
    else {
        $ok_rule_count++;
    }
}
ok( $ok_rule_count == keys %{ $Locales::DB::Language::to::misc_info{'plural_forms'}->{'category_rules_compiled'} }, "each 'category_rules_compiled' eval without error - count" );
is( $error, '', "each 'category_rules_compiled' is a code ref or evals without error - errors" );

my $self_obj = Locales->new('to');
ok( ref($self_obj), 'to object created OK' );

is( $self_obj->get_locale_display_pattern_from_code('aa'), $self_obj->get_locale_display_pattern_from_code_fast('aa'), 'get_locale_display_pattern_from_code[_fast] same result for aa' );
is( $self_obj->get_character_orientation_from_code('aa'),  $self_obj->get_character_orientation_from_code('aa'),       'get_character_orientation_from_code[_fast] same result for aa' );

is( $self_obj->get_locale_display_pattern_from_code('ab'), $self_obj->get_locale_display_pattern_from_code_fast('ab'), 'get_locale_display_pattern_from_code[_fast] same result for ab' );
is( $self_obj->get_character_orientation_from_code('ab'),  $self_obj->get_character_orientation_from_code('ab'),       'get_character_orientation_from_code[_fast] same result for ab' );

is( $self_obj->get_locale_display_pattern_from_code('ace'), $self_obj->get_locale_display_pattern_from_code_fast('ace'), 'get_locale_display_pattern_from_code[_fast] same result for ace' );
is( $self_obj->get_character_orientation_from_code('ace'),  $self_obj->get_character_orientation_from_code('ace'),       'get_character_orientation_from_code[_fast] same result for ace' );

is( $self_obj->get_locale_display_pattern_from_code('ach'), $self_obj->get_locale_display_pattern_from_code_fast('ach'), 'get_locale_display_pattern_from_code[_fast] same result for ach' );
is( $self_obj->get_character_orientation_from_code('ach'),  $self_obj->get_character_orientation_from_code('ach'),       'get_character_orientation_from_code[_fast] same result for ach' );

is( $self_obj->get_locale_display_pattern_from_code('ada'), $self_obj->get_locale_display_pattern_from_code_fast('ada'), 'get_locale_display_pattern_from_code[_fast] same result for ada' );
is( $self_obj->get_character_orientation_from_code('ada'),  $self_obj->get_character_orientation_from_code('ada'),       'get_character_orientation_from_code[_fast] same result for ada' );

is( $self_obj->get_locale_display_pattern_from_code('ady'), $self_obj->get_locale_display_pattern_from_code_fast('ady'), 'get_locale_display_pattern_from_code[_fast] same result for ady' );
is( $self_obj->get_character_orientation_from_code('ady'),  $self_obj->get_character_orientation_from_code('ady'),       'get_character_orientation_from_code[_fast] same result for ady' );

is( $self_obj->get_locale_display_pattern_from_code('ae'), $self_obj->get_locale_display_pattern_from_code_fast('ae'), 'get_locale_display_pattern_from_code[_fast] same result for ae' );
is( $self_obj->get_character_orientation_from_code('ae'),  $self_obj->get_character_orientation_from_code('ae'),       'get_character_orientation_from_code[_fast] same result for ae' );

is( $self_obj->get_locale_display_pattern_from_code('af'), $self_obj->get_locale_display_pattern_from_code_fast('af'), 'get_locale_display_pattern_from_code[_fast] same result for af' );
is( $self_obj->get_character_orientation_from_code('af'),  $self_obj->get_character_orientation_from_code('af'),       'get_character_orientation_from_code[_fast] same result for af' );

is( $self_obj->get_locale_display_pattern_from_code('afa'), $self_obj->get_locale_display_pattern_from_code_fast('afa'), 'get_locale_display_pattern_from_code[_fast] same result for afa' );
is( $self_obj->get_character_orientation_from_code('afa'),  $self_obj->get_character_orientation_from_code('afa'),       'get_character_orientation_from_code[_fast] same result for afa' );

is( $self_obj->get_locale_display_pattern_from_code('afh'), $self_obj->get_locale_display_pattern_from_code_fast('afh'), 'get_locale_display_pattern_from_code[_fast] same result for afh' );
is( $self_obj->get_character_orientation_from_code('afh'),  $self_obj->get_character_orientation_from_code('afh'),       'get_character_orientation_from_code[_fast] same result for afh' );

is( $self_obj->get_locale_display_pattern_from_code('agq'), $self_obj->get_locale_display_pattern_from_code_fast('agq'), 'get_locale_display_pattern_from_code[_fast] same result for agq' );
is( $self_obj->get_character_orientation_from_code('agq'),  $self_obj->get_character_orientation_from_code('agq'),       'get_character_orientation_from_code[_fast] same result for agq' );

is( $self_obj->get_locale_display_pattern_from_code('ain'), $self_obj->get_locale_display_pattern_from_code_fast('ain'), 'get_locale_display_pattern_from_code[_fast] same result for ain' );
is( $self_obj->get_character_orientation_from_code('ain'),  $self_obj->get_character_orientation_from_code('ain'),       'get_character_orientation_from_code[_fast] same result for ain' );

is( $self_obj->get_locale_display_pattern_from_code('ak'), $self_obj->get_locale_display_pattern_from_code_fast('ak'), 'get_locale_display_pattern_from_code[_fast] same result for ak' );
is( $self_obj->get_character_orientation_from_code('ak'),  $self_obj->get_character_orientation_from_code('ak'),       'get_character_orientation_from_code[_fast] same result for ak' );

is( $self_obj->get_locale_display_pattern_from_code('akk'), $self_obj->get_locale_display_pattern_from_code_fast('akk'), 'get_locale_display_pattern_from_code[_fast] same result for akk' );
is( $self_obj->get_character_orientation_from_code('akk'),  $self_obj->get_character_orientation_from_code('akk'),       'get_character_orientation_from_code[_fast] same result for akk' );

is( $self_obj->get_locale_display_pattern_from_code('ale'), $self_obj->get_locale_display_pattern_from_code_fast('ale'), 'get_locale_display_pattern_from_code[_fast] same result for ale' );
is( $self_obj->get_character_orientation_from_code('ale'),  $self_obj->get_character_orientation_from_code('ale'),       'get_character_orientation_from_code[_fast] same result for ale' );

is( $self_obj->get_locale_display_pattern_from_code('alg'), $self_obj->get_locale_display_pattern_from_code_fast('alg'), 'get_locale_display_pattern_from_code[_fast] same result for alg' );
is( $self_obj->get_character_orientation_from_code('alg'),  $self_obj->get_character_orientation_from_code('alg'),       'get_character_orientation_from_code[_fast] same result for alg' );

is( $self_obj->get_locale_display_pattern_from_code('alt'), $self_obj->get_locale_display_pattern_from_code_fast('alt'), 'get_locale_display_pattern_from_code[_fast] same result for alt' );
is( $self_obj->get_character_orientation_from_code('alt'),  $self_obj->get_character_orientation_from_code('alt'),       'get_character_orientation_from_code[_fast] same result for alt' );

is( $self_obj->get_locale_display_pattern_from_code('am'), $self_obj->get_locale_display_pattern_from_code_fast('am'), 'get_locale_display_pattern_from_code[_fast] same result for am' );
is( $self_obj->get_character_orientation_from_code('am'),  $self_obj->get_character_orientation_from_code('am'),       'get_character_orientation_from_code[_fast] same result for am' );

is( $self_obj->get_locale_display_pattern_from_code('an'), $self_obj->get_locale_display_pattern_from_code_fast('an'), 'get_locale_display_pattern_from_code[_fast] same result for an' );
is( $self_obj->get_character_orientation_from_code('an'),  $self_obj->get_character_orientation_from_code('an'),       'get_character_orientation_from_code[_fast] same result for an' );

is( $self_obj->get_locale_display_pattern_from_code('ang'), $self_obj->get_locale_display_pattern_from_code_fast('ang'), 'get_locale_display_pattern_from_code[_fast] same result for ang' );
is( $self_obj->get_character_orientation_from_code('ang'),  $self_obj->get_character_orientation_from_code('ang'),       'get_character_orientation_from_code[_fast] same result for ang' );

is( $self_obj->get_locale_display_pattern_from_code('anp'), $self_obj->get_locale_display_pattern_from_code_fast('anp'), 'get_locale_display_pattern_from_code[_fast] same result for anp' );
is( $self_obj->get_character_orientation_from_code('anp'),  $self_obj->get_character_orientation_from_code('anp'),       'get_character_orientation_from_code[_fast] same result for anp' );

is( $self_obj->get_locale_display_pattern_from_code('apa'), $self_obj->get_locale_display_pattern_from_code_fast('apa'), 'get_locale_display_pattern_from_code[_fast] same result for apa' );
is( $self_obj->get_character_orientation_from_code('apa'),  $self_obj->get_character_orientation_from_code('apa'),       'get_character_orientation_from_code[_fast] same result for apa' );

is( $self_obj->get_locale_display_pattern_from_code('ar'), $self_obj->get_locale_display_pattern_from_code_fast('ar'), 'get_locale_display_pattern_from_code[_fast] same result for ar' );
is( $self_obj->get_character_orientation_from_code('ar'),  $self_obj->get_character_orientation_from_code('ar'),       'get_character_orientation_from_code[_fast] same result for ar' );

is( $self_obj->get_locale_display_pattern_from_code('arc'), $self_obj->get_locale_display_pattern_from_code_fast('arc'), 'get_locale_display_pattern_from_code[_fast] same result for arc' );
is( $self_obj->get_character_orientation_from_code('arc'),  $self_obj->get_character_orientation_from_code('arc'),       'get_character_orientation_from_code[_fast] same result for arc' );

is( $self_obj->get_locale_display_pattern_from_code('arn'), $self_obj->get_locale_display_pattern_from_code_fast('arn'), 'get_locale_display_pattern_from_code[_fast] same result for arn' );
is( $self_obj->get_character_orientation_from_code('arn'),  $self_obj->get_character_orientation_from_code('arn'),       'get_character_orientation_from_code[_fast] same result for arn' );

is( $self_obj->get_locale_display_pattern_from_code('arp'), $self_obj->get_locale_display_pattern_from_code_fast('arp'), 'get_locale_display_pattern_from_code[_fast] same result for arp' );
is( $self_obj->get_character_orientation_from_code('arp'),  $self_obj->get_character_orientation_from_code('arp'),       'get_character_orientation_from_code[_fast] same result for arp' );

is( $self_obj->get_locale_display_pattern_from_code('art'), $self_obj->get_locale_display_pattern_from_code_fast('art'), 'get_locale_display_pattern_from_code[_fast] same result for art' );
is( $self_obj->get_character_orientation_from_code('art'),  $self_obj->get_character_orientation_from_code('art'),       'get_character_orientation_from_code[_fast] same result for art' );

is( $self_obj->get_locale_display_pattern_from_code('arw'), $self_obj->get_locale_display_pattern_from_code_fast('arw'), 'get_locale_display_pattern_from_code[_fast] same result for arw' );
is( $self_obj->get_character_orientation_from_code('arw'),  $self_obj->get_character_orientation_from_code('arw'),       'get_character_orientation_from_code[_fast] same result for arw' );

is( $self_obj->get_locale_display_pattern_from_code('as'), $self_obj->get_locale_display_pattern_from_code_fast('as'), 'get_locale_display_pattern_from_code[_fast] same result for as' );
is( $self_obj->get_character_orientation_from_code('as'),  $self_obj->get_character_orientation_from_code('as'),       'get_character_orientation_from_code[_fast] same result for as' );

is( $self_obj->get_locale_display_pattern_from_code('asa'), $self_obj->get_locale_display_pattern_from_code_fast('asa'), 'get_locale_display_pattern_from_code[_fast] same result for asa' );
is( $self_obj->get_character_orientation_from_code('asa'),  $self_obj->get_character_orientation_from_code('asa'),       'get_character_orientation_from_code[_fast] same result for asa' );

is( $self_obj->get_locale_display_pattern_from_code('ast'), $self_obj->get_locale_display_pattern_from_code_fast('ast'), 'get_locale_display_pattern_from_code[_fast] same result for ast' );
is( $self_obj->get_character_orientation_from_code('ast'),  $self_obj->get_character_orientation_from_code('ast'),       'get_character_orientation_from_code[_fast] same result for ast' );

is( $self_obj->get_locale_display_pattern_from_code('ath'), $self_obj->get_locale_display_pattern_from_code_fast('ath'), 'get_locale_display_pattern_from_code[_fast] same result for ath' );
is( $self_obj->get_character_orientation_from_code('ath'),  $self_obj->get_character_orientation_from_code('ath'),       'get_character_orientation_from_code[_fast] same result for ath' );

is( $self_obj->get_locale_display_pattern_from_code('aus'), $self_obj->get_locale_display_pattern_from_code_fast('aus'), 'get_locale_display_pattern_from_code[_fast] same result for aus' );
is( $self_obj->get_character_orientation_from_code('aus'),  $self_obj->get_character_orientation_from_code('aus'),       'get_character_orientation_from_code[_fast] same result for aus' );

is( $self_obj->get_locale_display_pattern_from_code('av'), $self_obj->get_locale_display_pattern_from_code_fast('av'), 'get_locale_display_pattern_from_code[_fast] same result for av' );
is( $self_obj->get_character_orientation_from_code('av'),  $self_obj->get_character_orientation_from_code('av'),       'get_character_orientation_from_code[_fast] same result for av' );

is( $self_obj->get_locale_display_pattern_from_code('awa'), $self_obj->get_locale_display_pattern_from_code_fast('awa'), 'get_locale_display_pattern_from_code[_fast] same result for awa' );
is( $self_obj->get_character_orientation_from_code('awa'),  $self_obj->get_character_orientation_from_code('awa'),       'get_character_orientation_from_code[_fast] same result for awa' );

is( $self_obj->get_locale_display_pattern_from_code('ay'), $self_obj->get_locale_display_pattern_from_code_fast('ay'), 'get_locale_display_pattern_from_code[_fast] same result for ay' );
is( $self_obj->get_character_orientation_from_code('ay'),  $self_obj->get_character_orientation_from_code('ay'),       'get_character_orientation_from_code[_fast] same result for ay' );

is( $self_obj->get_locale_display_pattern_from_code('az'), $self_obj->get_locale_display_pattern_from_code_fast('az'), 'get_locale_display_pattern_from_code[_fast] same result for az' );
is( $self_obj->get_character_orientation_from_code('az'),  $self_obj->get_character_orientation_from_code('az'),       'get_character_orientation_from_code[_fast] same result for az' );

is( $self_obj->get_locale_display_pattern_from_code('ba'), $self_obj->get_locale_display_pattern_from_code_fast('ba'), 'get_locale_display_pattern_from_code[_fast] same result for ba' );
is( $self_obj->get_character_orientation_from_code('ba'),  $self_obj->get_character_orientation_from_code('ba'),       'get_character_orientation_from_code[_fast] same result for ba' );

is( $self_obj->get_locale_display_pattern_from_code('bad'), $self_obj->get_locale_display_pattern_from_code_fast('bad'), 'get_locale_display_pattern_from_code[_fast] same result for bad' );
is( $self_obj->get_character_orientation_from_code('bad'),  $self_obj->get_character_orientation_from_code('bad'),       'get_character_orientation_from_code[_fast] same result for bad' );

is( $self_obj->get_locale_display_pattern_from_code('bai'), $self_obj->get_locale_display_pattern_from_code_fast('bai'), 'get_locale_display_pattern_from_code[_fast] same result for bai' );
is( $self_obj->get_character_orientation_from_code('bai'),  $self_obj->get_character_orientation_from_code('bai'),       'get_character_orientation_from_code[_fast] same result for bai' );

is( $self_obj->get_locale_display_pattern_from_code('bal'), $self_obj->get_locale_display_pattern_from_code_fast('bal'), 'get_locale_display_pattern_from_code[_fast] same result for bal' );
is( $self_obj->get_character_orientation_from_code('bal'),  $self_obj->get_character_orientation_from_code('bal'),       'get_character_orientation_from_code[_fast] same result for bal' );

is( $self_obj->get_locale_display_pattern_from_code('ban'), $self_obj->get_locale_display_pattern_from_code_fast('ban'), 'get_locale_display_pattern_from_code[_fast] same result for ban' );
is( $self_obj->get_character_orientation_from_code('ban'),  $self_obj->get_character_orientation_from_code('ban'),       'get_character_orientation_from_code[_fast] same result for ban' );

is( $self_obj->get_locale_display_pattern_from_code('bas'), $self_obj->get_locale_display_pattern_from_code_fast('bas'), 'get_locale_display_pattern_from_code[_fast] same result for bas' );
is( $self_obj->get_character_orientation_from_code('bas'),  $self_obj->get_character_orientation_from_code('bas'),       'get_character_orientation_from_code[_fast] same result for bas' );

is( $self_obj->get_locale_display_pattern_from_code('bat'), $self_obj->get_locale_display_pattern_from_code_fast('bat'), 'get_locale_display_pattern_from_code[_fast] same result for bat' );
is( $self_obj->get_character_orientation_from_code('bat'),  $self_obj->get_character_orientation_from_code('bat'),       'get_character_orientation_from_code[_fast] same result for bat' );

is( $self_obj->get_locale_display_pattern_from_code('be'), $self_obj->get_locale_display_pattern_from_code_fast('be'), 'get_locale_display_pattern_from_code[_fast] same result for be' );
is( $self_obj->get_character_orientation_from_code('be'),  $self_obj->get_character_orientation_from_code('be'),       'get_character_orientation_from_code[_fast] same result for be' );

is( $self_obj->get_locale_display_pattern_from_code('bej'), $self_obj->get_locale_display_pattern_from_code_fast('bej'), 'get_locale_display_pattern_from_code[_fast] same result for bej' );
is( $self_obj->get_character_orientation_from_code('bej'),  $self_obj->get_character_orientation_from_code('bej'),       'get_character_orientation_from_code[_fast] same result for bej' );

is( $self_obj->get_locale_display_pattern_from_code('bem'), $self_obj->get_locale_display_pattern_from_code_fast('bem'), 'get_locale_display_pattern_from_code[_fast] same result for bem' );
is( $self_obj->get_character_orientation_from_code('bem'),  $self_obj->get_character_orientation_from_code('bem'),       'get_character_orientation_from_code[_fast] same result for bem' );

is( $self_obj->get_locale_display_pattern_from_code('ber'), $self_obj->get_locale_display_pattern_from_code_fast('ber'), 'get_locale_display_pattern_from_code[_fast] same result for ber' );
is( $self_obj->get_character_orientation_from_code('ber'),  $self_obj->get_character_orientation_from_code('ber'),       'get_character_orientation_from_code[_fast] same result for ber' );

is( $self_obj->get_locale_display_pattern_from_code('bez'), $self_obj->get_locale_display_pattern_from_code_fast('bez'), 'get_locale_display_pattern_from_code[_fast] same result for bez' );
is( $self_obj->get_character_orientation_from_code('bez'),  $self_obj->get_character_orientation_from_code('bez'),       'get_character_orientation_from_code[_fast] same result for bez' );

is( $self_obj->get_locale_display_pattern_from_code('bg'), $self_obj->get_locale_display_pattern_from_code_fast('bg'), 'get_locale_display_pattern_from_code[_fast] same result for bg' );
is( $self_obj->get_character_orientation_from_code('bg'),  $self_obj->get_character_orientation_from_code('bg'),       'get_character_orientation_from_code[_fast] same result for bg' );

is( $self_obj->get_locale_display_pattern_from_code('bh'), $self_obj->get_locale_display_pattern_from_code_fast('bh'), 'get_locale_display_pattern_from_code[_fast] same result for bh' );
is( $self_obj->get_character_orientation_from_code('bh'),  $self_obj->get_character_orientation_from_code('bh'),       'get_character_orientation_from_code[_fast] same result for bh' );

is( $self_obj->get_locale_display_pattern_from_code('bho'), $self_obj->get_locale_display_pattern_from_code_fast('bho'), 'get_locale_display_pattern_from_code[_fast] same result for bho' );
is( $self_obj->get_character_orientation_from_code('bho'),  $self_obj->get_character_orientation_from_code('bho'),       'get_character_orientation_from_code[_fast] same result for bho' );

is( $self_obj->get_locale_display_pattern_from_code('bi'), $self_obj->get_locale_display_pattern_from_code_fast('bi'), 'get_locale_display_pattern_from_code[_fast] same result for bi' );
is( $self_obj->get_character_orientation_from_code('bi'),  $self_obj->get_character_orientation_from_code('bi'),       'get_character_orientation_from_code[_fast] same result for bi' );

is( $self_obj->get_locale_display_pattern_from_code('bik'), $self_obj->get_locale_display_pattern_from_code_fast('bik'), 'get_locale_display_pattern_from_code[_fast] same result for bik' );
is( $self_obj->get_character_orientation_from_code('bik'),  $self_obj->get_character_orientation_from_code('bik'),       'get_character_orientation_from_code[_fast] same result for bik' );

is( $self_obj->get_locale_display_pattern_from_code('bin'), $self_obj->get_locale_display_pattern_from_code_fast('bin'), 'get_locale_display_pattern_from_code[_fast] same result for bin' );
is( $self_obj->get_character_orientation_from_code('bin'),  $self_obj->get_character_orientation_from_code('bin'),       'get_character_orientation_from_code[_fast] same result for bin' );

is( $self_obj->get_locale_display_pattern_from_code('bla'), $self_obj->get_locale_display_pattern_from_code_fast('bla'), 'get_locale_display_pattern_from_code[_fast] same result for bla' );
is( $self_obj->get_character_orientation_from_code('bla'),  $self_obj->get_character_orientation_from_code('bla'),       'get_character_orientation_from_code[_fast] same result for bla' );

is( $self_obj->get_locale_display_pattern_from_code('bm'), $self_obj->get_locale_display_pattern_from_code_fast('bm'), 'get_locale_display_pattern_from_code[_fast] same result for bm' );
is( $self_obj->get_character_orientation_from_code('bm'),  $self_obj->get_character_orientation_from_code('bm'),       'get_character_orientation_from_code[_fast] same result for bm' );

is( $self_obj->get_locale_display_pattern_from_code('bn'), $self_obj->get_locale_display_pattern_from_code_fast('bn'), 'get_locale_display_pattern_from_code[_fast] same result for bn' );
is( $self_obj->get_character_orientation_from_code('bn'),  $self_obj->get_character_orientation_from_code('bn'),       'get_character_orientation_from_code[_fast] same result for bn' );

is( $self_obj->get_locale_display_pattern_from_code('bnt'), $self_obj->get_locale_display_pattern_from_code_fast('bnt'), 'get_locale_display_pattern_from_code[_fast] same result for bnt' );
is( $self_obj->get_character_orientation_from_code('bnt'),  $self_obj->get_character_orientation_from_code('bnt'),       'get_character_orientation_from_code[_fast] same result for bnt' );

is( $self_obj->get_locale_display_pattern_from_code('bo'), $self_obj->get_locale_display_pattern_from_code_fast('bo'), 'get_locale_display_pattern_from_code[_fast] same result for bo' );
is( $self_obj->get_character_orientation_from_code('bo'),  $self_obj->get_character_orientation_from_code('bo'),       'get_character_orientation_from_code[_fast] same result for bo' );

is( $self_obj->get_locale_display_pattern_from_code('br'), $self_obj->get_locale_display_pattern_from_code_fast('br'), 'get_locale_display_pattern_from_code[_fast] same result for br' );
is( $self_obj->get_character_orientation_from_code('br'),  $self_obj->get_character_orientation_from_code('br'),       'get_character_orientation_from_code[_fast] same result for br' );

is( $self_obj->get_locale_display_pattern_from_code('bra'), $self_obj->get_locale_display_pattern_from_code_fast('bra'), 'get_locale_display_pattern_from_code[_fast] same result for bra' );
is( $self_obj->get_character_orientation_from_code('bra'),  $self_obj->get_character_orientation_from_code('bra'),       'get_character_orientation_from_code[_fast] same result for bra' );

is( $self_obj->get_locale_display_pattern_from_code('brx'), $self_obj->get_locale_display_pattern_from_code_fast('brx'), 'get_locale_display_pattern_from_code[_fast] same result for brx' );
is( $self_obj->get_character_orientation_from_code('brx'),  $self_obj->get_character_orientation_from_code('brx'),       'get_character_orientation_from_code[_fast] same result for brx' );

is( $self_obj->get_locale_display_pattern_from_code('bs'), $self_obj->get_locale_display_pattern_from_code_fast('bs'), 'get_locale_display_pattern_from_code[_fast] same result for bs' );
is( $self_obj->get_character_orientation_from_code('bs'),  $self_obj->get_character_orientation_from_code('bs'),       'get_character_orientation_from_code[_fast] same result for bs' );

is( $self_obj->get_locale_display_pattern_from_code('btk'), $self_obj->get_locale_display_pattern_from_code_fast('btk'), 'get_locale_display_pattern_from_code[_fast] same result for btk' );
is( $self_obj->get_character_orientation_from_code('btk'),  $self_obj->get_character_orientation_from_code('btk'),       'get_character_orientation_from_code[_fast] same result for btk' );

is( $self_obj->get_locale_display_pattern_from_code('bua'), $self_obj->get_locale_display_pattern_from_code_fast('bua'), 'get_locale_display_pattern_from_code[_fast] same result for bua' );
is( $self_obj->get_character_orientation_from_code('bua'),  $self_obj->get_character_orientation_from_code('bua'),       'get_character_orientation_from_code[_fast] same result for bua' );

is( $self_obj->get_locale_display_pattern_from_code('bug'), $self_obj->get_locale_display_pattern_from_code_fast('bug'), 'get_locale_display_pattern_from_code[_fast] same result for bug' );
is( $self_obj->get_character_orientation_from_code('bug'),  $self_obj->get_character_orientation_from_code('bug'),       'get_character_orientation_from_code[_fast] same result for bug' );

is( $self_obj->get_locale_display_pattern_from_code('byn'), $self_obj->get_locale_display_pattern_from_code_fast('byn'), 'get_locale_display_pattern_from_code[_fast] same result for byn' );
is( $self_obj->get_character_orientation_from_code('byn'),  $self_obj->get_character_orientation_from_code('byn'),       'get_character_orientation_from_code[_fast] same result for byn' );

is( $self_obj->get_locale_display_pattern_from_code('ca'), $self_obj->get_locale_display_pattern_from_code_fast('ca'), 'get_locale_display_pattern_from_code[_fast] same result for ca' );
is( $self_obj->get_character_orientation_from_code('ca'),  $self_obj->get_character_orientation_from_code('ca'),       'get_character_orientation_from_code[_fast] same result for ca' );

is( $self_obj->get_locale_display_pattern_from_code('cad'), $self_obj->get_locale_display_pattern_from_code_fast('cad'), 'get_locale_display_pattern_from_code[_fast] same result for cad' );
is( $self_obj->get_character_orientation_from_code('cad'),  $self_obj->get_character_orientation_from_code('cad'),       'get_character_orientation_from_code[_fast] same result for cad' );

is( $self_obj->get_locale_display_pattern_from_code('cai'), $self_obj->get_locale_display_pattern_from_code_fast('cai'), 'get_locale_display_pattern_from_code[_fast] same result for cai' );
is( $self_obj->get_character_orientation_from_code('cai'),  $self_obj->get_character_orientation_from_code('cai'),       'get_character_orientation_from_code[_fast] same result for cai' );

is( $self_obj->get_locale_display_pattern_from_code('car'), $self_obj->get_locale_display_pattern_from_code_fast('car'), 'get_locale_display_pattern_from_code[_fast] same result for car' );
is( $self_obj->get_character_orientation_from_code('car'),  $self_obj->get_character_orientation_from_code('car'),       'get_character_orientation_from_code[_fast] same result for car' );

is( $self_obj->get_locale_display_pattern_from_code('cau'), $self_obj->get_locale_display_pattern_from_code_fast('cau'), 'get_locale_display_pattern_from_code[_fast] same result for cau' );
is( $self_obj->get_character_orientation_from_code('cau'),  $self_obj->get_character_orientation_from_code('cau'),       'get_character_orientation_from_code[_fast] same result for cau' );

is( $self_obj->get_locale_display_pattern_from_code('cay'), $self_obj->get_locale_display_pattern_from_code_fast('cay'), 'get_locale_display_pattern_from_code[_fast] same result for cay' );
is( $self_obj->get_character_orientation_from_code('cay'),  $self_obj->get_character_orientation_from_code('cay'),       'get_character_orientation_from_code[_fast] same result for cay' );

is( $self_obj->get_locale_display_pattern_from_code('cch'), $self_obj->get_locale_display_pattern_from_code_fast('cch'), 'get_locale_display_pattern_from_code[_fast] same result for cch' );
is( $self_obj->get_character_orientation_from_code('cch'),  $self_obj->get_character_orientation_from_code('cch'),       'get_character_orientation_from_code[_fast] same result for cch' );

is( $self_obj->get_locale_display_pattern_from_code('ce'), $self_obj->get_locale_display_pattern_from_code_fast('ce'), 'get_locale_display_pattern_from_code[_fast] same result for ce' );
is( $self_obj->get_character_orientation_from_code('ce'),  $self_obj->get_character_orientation_from_code('ce'),       'get_character_orientation_from_code[_fast] same result for ce' );

is( $self_obj->get_locale_display_pattern_from_code('ceb'), $self_obj->get_locale_display_pattern_from_code_fast('ceb'), 'get_locale_display_pattern_from_code[_fast] same result for ceb' );
is( $self_obj->get_character_orientation_from_code('ceb'),  $self_obj->get_character_orientation_from_code('ceb'),       'get_character_orientation_from_code[_fast] same result for ceb' );

is( $self_obj->get_locale_display_pattern_from_code('cel'), $self_obj->get_locale_display_pattern_from_code_fast('cel'), 'get_locale_display_pattern_from_code[_fast] same result for cel' );
is( $self_obj->get_character_orientation_from_code('cel'),  $self_obj->get_character_orientation_from_code('cel'),       'get_character_orientation_from_code[_fast] same result for cel' );

is( $self_obj->get_locale_display_pattern_from_code('cgg'), $self_obj->get_locale_display_pattern_from_code_fast('cgg'), 'get_locale_display_pattern_from_code[_fast] same result for cgg' );
is( $self_obj->get_character_orientation_from_code('cgg'),  $self_obj->get_character_orientation_from_code('cgg'),       'get_character_orientation_from_code[_fast] same result for cgg' );

is( $self_obj->get_locale_display_pattern_from_code('ch'), $self_obj->get_locale_display_pattern_from_code_fast('ch'), 'get_locale_display_pattern_from_code[_fast] same result for ch' );
is( $self_obj->get_character_orientation_from_code('ch'),  $self_obj->get_character_orientation_from_code('ch'),       'get_character_orientation_from_code[_fast] same result for ch' );

is( $self_obj->get_locale_display_pattern_from_code('chb'), $self_obj->get_locale_display_pattern_from_code_fast('chb'), 'get_locale_display_pattern_from_code[_fast] same result for chb' );
is( $self_obj->get_character_orientation_from_code('chb'),  $self_obj->get_character_orientation_from_code('chb'),       'get_character_orientation_from_code[_fast] same result for chb' );

is( $self_obj->get_locale_display_pattern_from_code('chg'), $self_obj->get_locale_display_pattern_from_code_fast('chg'), 'get_locale_display_pattern_from_code[_fast] same result for chg' );
is( $self_obj->get_character_orientation_from_code('chg'),  $self_obj->get_character_orientation_from_code('chg'),       'get_character_orientation_from_code[_fast] same result for chg' );

is( $self_obj->get_locale_display_pattern_from_code('chk'), $self_obj->get_locale_display_pattern_from_code_fast('chk'), 'get_locale_display_pattern_from_code[_fast] same result for chk' );
is( $self_obj->get_character_orientation_from_code('chk'),  $self_obj->get_character_orientation_from_code('chk'),       'get_character_orientation_from_code[_fast] same result for chk' );

is( $self_obj->get_locale_display_pattern_from_code('chm'), $self_obj->get_locale_display_pattern_from_code_fast('chm'), 'get_locale_display_pattern_from_code[_fast] same result for chm' );
is( $self_obj->get_character_orientation_from_code('chm'),  $self_obj->get_character_orientation_from_code('chm'),       'get_character_orientation_from_code[_fast] same result for chm' );

is( $self_obj->get_locale_display_pattern_from_code('chn'), $self_obj->get_locale_display_pattern_from_code_fast('chn'), 'get_locale_display_pattern_from_code[_fast] same result for chn' );
is( $self_obj->get_character_orientation_from_code('chn'),  $self_obj->get_character_orientation_from_code('chn'),       'get_character_orientation_from_code[_fast] same result for chn' );

is( $self_obj->get_locale_display_pattern_from_code('cho'), $self_obj->get_locale_display_pattern_from_code_fast('cho'), 'get_locale_display_pattern_from_code[_fast] same result for cho' );
is( $self_obj->get_character_orientation_from_code('cho'),  $self_obj->get_character_orientation_from_code('cho'),       'get_character_orientation_from_code[_fast] same result for cho' );

is( $self_obj->get_locale_display_pattern_from_code('chp'), $self_obj->get_locale_display_pattern_from_code_fast('chp'), 'get_locale_display_pattern_from_code[_fast] same result for chp' );
is( $self_obj->get_character_orientation_from_code('chp'),  $self_obj->get_character_orientation_from_code('chp'),       'get_character_orientation_from_code[_fast] same result for chp' );

is( $self_obj->get_locale_display_pattern_from_code('chr'), $self_obj->get_locale_display_pattern_from_code_fast('chr'), 'get_locale_display_pattern_from_code[_fast] same result for chr' );
is( $self_obj->get_character_orientation_from_code('chr'),  $self_obj->get_character_orientation_from_code('chr'),       'get_character_orientation_from_code[_fast] same result for chr' );

is( $self_obj->get_locale_display_pattern_from_code('chy'), $self_obj->get_locale_display_pattern_from_code_fast('chy'), 'get_locale_display_pattern_from_code[_fast] same result for chy' );
is( $self_obj->get_character_orientation_from_code('chy'),  $self_obj->get_character_orientation_from_code('chy'),       'get_character_orientation_from_code[_fast] same result for chy' );

is( $self_obj->get_locale_display_pattern_from_code('cmc'), $self_obj->get_locale_display_pattern_from_code_fast('cmc'), 'get_locale_display_pattern_from_code[_fast] same result for cmc' );
is( $self_obj->get_character_orientation_from_code('cmc'),  $self_obj->get_character_orientation_from_code('cmc'),       'get_character_orientation_from_code[_fast] same result for cmc' );

is( $self_obj->get_locale_display_pattern_from_code('co'), $self_obj->get_locale_display_pattern_from_code_fast('co'), 'get_locale_display_pattern_from_code[_fast] same result for co' );
is( $self_obj->get_character_orientation_from_code('co'),  $self_obj->get_character_orientation_from_code('co'),       'get_character_orientation_from_code[_fast] same result for co' );

is( $self_obj->get_locale_display_pattern_from_code('cop'), $self_obj->get_locale_display_pattern_from_code_fast('cop'), 'get_locale_display_pattern_from_code[_fast] same result for cop' );
is( $self_obj->get_character_orientation_from_code('cop'),  $self_obj->get_character_orientation_from_code('cop'),       'get_character_orientation_from_code[_fast] same result for cop' );

is( $self_obj->get_locale_display_pattern_from_code('cpe'), $self_obj->get_locale_display_pattern_from_code_fast('cpe'), 'get_locale_display_pattern_from_code[_fast] same result for cpe' );
is( $self_obj->get_character_orientation_from_code('cpe'),  $self_obj->get_character_orientation_from_code('cpe'),       'get_character_orientation_from_code[_fast] same result for cpe' );

is( $self_obj->get_locale_display_pattern_from_code('cpf'), $self_obj->get_locale_display_pattern_from_code_fast('cpf'), 'get_locale_display_pattern_from_code[_fast] same result for cpf' );
is( $self_obj->get_character_orientation_from_code('cpf'),  $self_obj->get_character_orientation_from_code('cpf'),       'get_character_orientation_from_code[_fast] same result for cpf' );

is( $self_obj->get_locale_display_pattern_from_code('cpp'), $self_obj->get_locale_display_pattern_from_code_fast('cpp'), 'get_locale_display_pattern_from_code[_fast] same result for cpp' );
is( $self_obj->get_character_orientation_from_code('cpp'),  $self_obj->get_character_orientation_from_code('cpp'),       'get_character_orientation_from_code[_fast] same result for cpp' );

is( $self_obj->get_locale_display_pattern_from_code('cr'), $self_obj->get_locale_display_pattern_from_code_fast('cr'), 'get_locale_display_pattern_from_code[_fast] same result for cr' );
is( $self_obj->get_character_orientation_from_code('cr'),  $self_obj->get_character_orientation_from_code('cr'),       'get_character_orientation_from_code[_fast] same result for cr' );

is( $self_obj->get_locale_display_pattern_from_code('crh'), $self_obj->get_locale_display_pattern_from_code_fast('crh'), 'get_locale_display_pattern_from_code[_fast] same result for crh' );
is( $self_obj->get_character_orientation_from_code('crh'),  $self_obj->get_character_orientation_from_code('crh'),       'get_character_orientation_from_code[_fast] same result for crh' );

is( $self_obj->get_locale_display_pattern_from_code('crp'), $self_obj->get_locale_display_pattern_from_code_fast('crp'), 'get_locale_display_pattern_from_code[_fast] same result for crp' );
is( $self_obj->get_character_orientation_from_code('crp'),  $self_obj->get_character_orientation_from_code('crp'),       'get_character_orientation_from_code[_fast] same result for crp' );

is( $self_obj->get_locale_display_pattern_from_code('cs'), $self_obj->get_locale_display_pattern_from_code_fast('cs'), 'get_locale_display_pattern_from_code[_fast] same result for cs' );
is( $self_obj->get_character_orientation_from_code('cs'),  $self_obj->get_character_orientation_from_code('cs'),       'get_character_orientation_from_code[_fast] same result for cs' );

is( $self_obj->get_locale_display_pattern_from_code('csb'), $self_obj->get_locale_display_pattern_from_code_fast('csb'), 'get_locale_display_pattern_from_code[_fast] same result for csb' );
is( $self_obj->get_character_orientation_from_code('csb'),  $self_obj->get_character_orientation_from_code('csb'),       'get_character_orientation_from_code[_fast] same result for csb' );

is( $self_obj->get_locale_display_pattern_from_code('cu'), $self_obj->get_locale_display_pattern_from_code_fast('cu'), 'get_locale_display_pattern_from_code[_fast] same result for cu' );
is( $self_obj->get_character_orientation_from_code('cu'),  $self_obj->get_character_orientation_from_code('cu'),       'get_character_orientation_from_code[_fast] same result for cu' );

is( $self_obj->get_locale_display_pattern_from_code('cus'), $self_obj->get_locale_display_pattern_from_code_fast('cus'), 'get_locale_display_pattern_from_code[_fast] same result for cus' );
is( $self_obj->get_character_orientation_from_code('cus'),  $self_obj->get_character_orientation_from_code('cus'),       'get_character_orientation_from_code[_fast] same result for cus' );

is( $self_obj->get_locale_display_pattern_from_code('cv'), $self_obj->get_locale_display_pattern_from_code_fast('cv'), 'get_locale_display_pattern_from_code[_fast] same result for cv' );
is( $self_obj->get_character_orientation_from_code('cv'),  $self_obj->get_character_orientation_from_code('cv'),       'get_character_orientation_from_code[_fast] same result for cv' );

is( $self_obj->get_locale_display_pattern_from_code('cy'), $self_obj->get_locale_display_pattern_from_code_fast('cy'), 'get_locale_display_pattern_from_code[_fast] same result for cy' );
is( $self_obj->get_character_orientation_from_code('cy'),  $self_obj->get_character_orientation_from_code('cy'),       'get_character_orientation_from_code[_fast] same result for cy' );

is( $self_obj->get_locale_display_pattern_from_code('da'), $self_obj->get_locale_display_pattern_from_code_fast('da'), 'get_locale_display_pattern_from_code[_fast] same result for da' );
is( $self_obj->get_character_orientation_from_code('da'),  $self_obj->get_character_orientation_from_code('da'),       'get_character_orientation_from_code[_fast] same result for da' );

is( $self_obj->get_locale_display_pattern_from_code('dak'), $self_obj->get_locale_display_pattern_from_code_fast('dak'), 'get_locale_display_pattern_from_code[_fast] same result for dak' );
is( $self_obj->get_character_orientation_from_code('dak'),  $self_obj->get_character_orientation_from_code('dak'),       'get_character_orientation_from_code[_fast] same result for dak' );

is( $self_obj->get_locale_display_pattern_from_code('dar'), $self_obj->get_locale_display_pattern_from_code_fast('dar'), 'get_locale_display_pattern_from_code[_fast] same result for dar' );
is( $self_obj->get_character_orientation_from_code('dar'),  $self_obj->get_character_orientation_from_code('dar'),       'get_character_orientation_from_code[_fast] same result for dar' );

is( $self_obj->get_locale_display_pattern_from_code('dav'), $self_obj->get_locale_display_pattern_from_code_fast('dav'), 'get_locale_display_pattern_from_code[_fast] same result for dav' );
is( $self_obj->get_character_orientation_from_code('dav'),  $self_obj->get_character_orientation_from_code('dav'),       'get_character_orientation_from_code[_fast] same result for dav' );

is( $self_obj->get_locale_display_pattern_from_code('day'), $self_obj->get_locale_display_pattern_from_code_fast('day'), 'get_locale_display_pattern_from_code[_fast] same result for day' );
is( $self_obj->get_character_orientation_from_code('day'),  $self_obj->get_character_orientation_from_code('day'),       'get_character_orientation_from_code[_fast] same result for day' );

is( $self_obj->get_locale_display_pattern_from_code('de'), $self_obj->get_locale_display_pattern_from_code_fast('de'), 'get_locale_display_pattern_from_code[_fast] same result for de' );
is( $self_obj->get_character_orientation_from_code('de'),  $self_obj->get_character_orientation_from_code('de'),       'get_character_orientation_from_code[_fast] same result for de' );

is( $self_obj->get_locale_display_pattern_from_code('de_at'), $self_obj->get_locale_display_pattern_from_code_fast('de_at'), 'get_locale_display_pattern_from_code[_fast] same result for de_at' );
is( $self_obj->get_character_orientation_from_code('de_at'),  $self_obj->get_character_orientation_from_code('de_at'),       'get_character_orientation_from_code[_fast] same result for de_at' );

is( $self_obj->get_locale_display_pattern_from_code('de_ch'), $self_obj->get_locale_display_pattern_from_code_fast('de_ch'), 'get_locale_display_pattern_from_code[_fast] same result for de_ch' );
is( $self_obj->get_character_orientation_from_code('de_ch'),  $self_obj->get_character_orientation_from_code('de_ch'),       'get_character_orientation_from_code[_fast] same result for de_ch' );

is( $self_obj->get_locale_display_pattern_from_code('del'), $self_obj->get_locale_display_pattern_from_code_fast('del'), 'get_locale_display_pattern_from_code[_fast] same result for del' );
is( $self_obj->get_character_orientation_from_code('del'),  $self_obj->get_character_orientation_from_code('del'),       'get_character_orientation_from_code[_fast] same result for del' );

is( $self_obj->get_locale_display_pattern_from_code('den'), $self_obj->get_locale_display_pattern_from_code_fast('den'), 'get_locale_display_pattern_from_code[_fast] same result for den' );
is( $self_obj->get_character_orientation_from_code('den'),  $self_obj->get_character_orientation_from_code('den'),       'get_character_orientation_from_code[_fast] same result for den' );

is( $self_obj->get_locale_display_pattern_from_code('dgr'), $self_obj->get_locale_display_pattern_from_code_fast('dgr'), 'get_locale_display_pattern_from_code[_fast] same result for dgr' );
is( $self_obj->get_character_orientation_from_code('dgr'),  $self_obj->get_character_orientation_from_code('dgr'),       'get_character_orientation_from_code[_fast] same result for dgr' );

is( $self_obj->get_locale_display_pattern_from_code('din'), $self_obj->get_locale_display_pattern_from_code_fast('din'), 'get_locale_display_pattern_from_code[_fast] same result for din' );
is( $self_obj->get_character_orientation_from_code('din'),  $self_obj->get_character_orientation_from_code('din'),       'get_character_orientation_from_code[_fast] same result for din' );

is( $self_obj->get_locale_display_pattern_from_code('dje'), $self_obj->get_locale_display_pattern_from_code_fast('dje'), 'get_locale_display_pattern_from_code[_fast] same result for dje' );
is( $self_obj->get_character_orientation_from_code('dje'),  $self_obj->get_character_orientation_from_code('dje'),       'get_character_orientation_from_code[_fast] same result for dje' );

is( $self_obj->get_locale_display_pattern_from_code('doi'), $self_obj->get_locale_display_pattern_from_code_fast('doi'), 'get_locale_display_pattern_from_code[_fast] same result for doi' );
is( $self_obj->get_character_orientation_from_code('doi'),  $self_obj->get_character_orientation_from_code('doi'),       'get_character_orientation_from_code[_fast] same result for doi' );

is( $self_obj->get_locale_display_pattern_from_code('dra'), $self_obj->get_locale_display_pattern_from_code_fast('dra'), 'get_locale_display_pattern_from_code[_fast] same result for dra' );
is( $self_obj->get_character_orientation_from_code('dra'),  $self_obj->get_character_orientation_from_code('dra'),       'get_character_orientation_from_code[_fast] same result for dra' );

is( $self_obj->get_locale_display_pattern_from_code('dsb'), $self_obj->get_locale_display_pattern_from_code_fast('dsb'), 'get_locale_display_pattern_from_code[_fast] same result for dsb' );
is( $self_obj->get_character_orientation_from_code('dsb'),  $self_obj->get_character_orientation_from_code('dsb'),       'get_character_orientation_from_code[_fast] same result for dsb' );

is( $self_obj->get_locale_display_pattern_from_code('dua'), $self_obj->get_locale_display_pattern_from_code_fast('dua'), 'get_locale_display_pattern_from_code[_fast] same result for dua' );
is( $self_obj->get_character_orientation_from_code('dua'),  $self_obj->get_character_orientation_from_code('dua'),       'get_character_orientation_from_code[_fast] same result for dua' );

is( $self_obj->get_locale_display_pattern_from_code('dum'), $self_obj->get_locale_display_pattern_from_code_fast('dum'), 'get_locale_display_pattern_from_code[_fast] same result for dum' );
is( $self_obj->get_character_orientation_from_code('dum'),  $self_obj->get_character_orientation_from_code('dum'),       'get_character_orientation_from_code[_fast] same result for dum' );

is( $self_obj->get_locale_display_pattern_from_code('dv'), $self_obj->get_locale_display_pattern_from_code_fast('dv'), 'get_locale_display_pattern_from_code[_fast] same result for dv' );
is( $self_obj->get_character_orientation_from_code('dv'),  $self_obj->get_character_orientation_from_code('dv'),       'get_character_orientation_from_code[_fast] same result for dv' );

is( $self_obj->get_locale_display_pattern_from_code('dyo'), $self_obj->get_locale_display_pattern_from_code_fast('dyo'), 'get_locale_display_pattern_from_code[_fast] same result for dyo' );
is( $self_obj->get_character_orientation_from_code('dyo'),  $self_obj->get_character_orientation_from_code('dyo'),       'get_character_orientation_from_code[_fast] same result for dyo' );

is( $self_obj->get_locale_display_pattern_from_code('dyu'), $self_obj->get_locale_display_pattern_from_code_fast('dyu'), 'get_locale_display_pattern_from_code[_fast] same result for dyu' );
is( $self_obj->get_character_orientation_from_code('dyu'),  $self_obj->get_character_orientation_from_code('dyu'),       'get_character_orientation_from_code[_fast] same result for dyu' );

is( $self_obj->get_locale_display_pattern_from_code('dz'), $self_obj->get_locale_display_pattern_from_code_fast('dz'), 'get_locale_display_pattern_from_code[_fast] same result for dz' );
is( $self_obj->get_character_orientation_from_code('dz'),  $self_obj->get_character_orientation_from_code('dz'),       'get_character_orientation_from_code[_fast] same result for dz' );

is( $self_obj->get_locale_display_pattern_from_code('ebu'), $self_obj->get_locale_display_pattern_from_code_fast('ebu'), 'get_locale_display_pattern_from_code[_fast] same result for ebu' );
is( $self_obj->get_character_orientation_from_code('ebu'),  $self_obj->get_character_orientation_from_code('ebu'),       'get_character_orientation_from_code[_fast] same result for ebu' );

is( $self_obj->get_locale_display_pattern_from_code('ee'), $self_obj->get_locale_display_pattern_from_code_fast('ee'), 'get_locale_display_pattern_from_code[_fast] same result for ee' );
is( $self_obj->get_character_orientation_from_code('ee'),  $self_obj->get_character_orientation_from_code('ee'),       'get_character_orientation_from_code[_fast] same result for ee' );

is( $self_obj->get_locale_display_pattern_from_code('efi'), $self_obj->get_locale_display_pattern_from_code_fast('efi'), 'get_locale_display_pattern_from_code[_fast] same result for efi' );
is( $self_obj->get_character_orientation_from_code('efi'),  $self_obj->get_character_orientation_from_code('efi'),       'get_character_orientation_from_code[_fast] same result for efi' );

is( $self_obj->get_locale_display_pattern_from_code('egy'), $self_obj->get_locale_display_pattern_from_code_fast('egy'), 'get_locale_display_pattern_from_code[_fast] same result for egy' );
is( $self_obj->get_character_orientation_from_code('egy'),  $self_obj->get_character_orientation_from_code('egy'),       'get_character_orientation_from_code[_fast] same result for egy' );

is( $self_obj->get_locale_display_pattern_from_code('eka'), $self_obj->get_locale_display_pattern_from_code_fast('eka'), 'get_locale_display_pattern_from_code[_fast] same result for eka' );
is( $self_obj->get_character_orientation_from_code('eka'),  $self_obj->get_character_orientation_from_code('eka'),       'get_character_orientation_from_code[_fast] same result for eka' );

is( $self_obj->get_locale_display_pattern_from_code('el'), $self_obj->get_locale_display_pattern_from_code_fast('el'), 'get_locale_display_pattern_from_code[_fast] same result for el' );
is( $self_obj->get_character_orientation_from_code('el'),  $self_obj->get_character_orientation_from_code('el'),       'get_character_orientation_from_code[_fast] same result for el' );

is( $self_obj->get_locale_display_pattern_from_code('elx'), $self_obj->get_locale_display_pattern_from_code_fast('elx'), 'get_locale_display_pattern_from_code[_fast] same result for elx' );
is( $self_obj->get_character_orientation_from_code('elx'),  $self_obj->get_character_orientation_from_code('elx'),       'get_character_orientation_from_code[_fast] same result for elx' );

is( $self_obj->get_locale_display_pattern_from_code('en'), $self_obj->get_locale_display_pattern_from_code_fast('en'), 'get_locale_display_pattern_from_code[_fast] same result for en' );
is( $self_obj->get_character_orientation_from_code('en'),  $self_obj->get_character_orientation_from_code('en'),       'get_character_orientation_from_code[_fast] same result for en' );

is( $self_obj->get_locale_display_pattern_from_code('en_au'), $self_obj->get_locale_display_pattern_from_code_fast('en_au'), 'get_locale_display_pattern_from_code[_fast] same result for en_au' );
is( $self_obj->get_character_orientation_from_code('en_au'),  $self_obj->get_character_orientation_from_code('en_au'),       'get_character_orientation_from_code[_fast] same result for en_au' );

is( $self_obj->get_locale_display_pattern_from_code('en_ca'), $self_obj->get_locale_display_pattern_from_code_fast('en_ca'), 'get_locale_display_pattern_from_code[_fast] same result for en_ca' );
is( $self_obj->get_character_orientation_from_code('en_ca'),  $self_obj->get_character_orientation_from_code('en_ca'),       'get_character_orientation_from_code[_fast] same result for en_ca' );

is( $self_obj->get_locale_display_pattern_from_code('en_gb'), $self_obj->get_locale_display_pattern_from_code_fast('en_gb'), 'get_locale_display_pattern_from_code[_fast] same result for en_gb' );
is( $self_obj->get_character_orientation_from_code('en_gb'),  $self_obj->get_character_orientation_from_code('en_gb'),       'get_character_orientation_from_code[_fast] same result for en_gb' );

is( $self_obj->get_locale_display_pattern_from_code('en_us'), $self_obj->get_locale_display_pattern_from_code_fast('en_us'), 'get_locale_display_pattern_from_code[_fast] same result for en_us' );
is( $self_obj->get_character_orientation_from_code('en_us'),  $self_obj->get_character_orientation_from_code('en_us'),       'get_character_orientation_from_code[_fast] same result for en_us' );

is( $self_obj->get_locale_display_pattern_from_code('enm'), $self_obj->get_locale_display_pattern_from_code_fast('enm'), 'get_locale_display_pattern_from_code[_fast] same result for enm' );
is( $self_obj->get_character_orientation_from_code('enm'),  $self_obj->get_character_orientation_from_code('enm'),       'get_character_orientation_from_code[_fast] same result for enm' );

is( $self_obj->get_locale_display_pattern_from_code('eo'), $self_obj->get_locale_display_pattern_from_code_fast('eo'), 'get_locale_display_pattern_from_code[_fast] same result for eo' );
is( $self_obj->get_character_orientation_from_code('eo'),  $self_obj->get_character_orientation_from_code('eo'),       'get_character_orientation_from_code[_fast] same result for eo' );

is( $self_obj->get_locale_display_pattern_from_code('es'), $self_obj->get_locale_display_pattern_from_code_fast('es'), 'get_locale_display_pattern_from_code[_fast] same result for es' );
is( $self_obj->get_character_orientation_from_code('es'),  $self_obj->get_character_orientation_from_code('es'),       'get_character_orientation_from_code[_fast] same result for es' );

is( $self_obj->get_locale_display_pattern_from_code('es_419'), $self_obj->get_locale_display_pattern_from_code_fast('es_419'), 'get_locale_display_pattern_from_code[_fast] same result for es_419' );
is( $self_obj->get_character_orientation_from_code('es_419'),  $self_obj->get_character_orientation_from_code('es_419'),       'get_character_orientation_from_code[_fast] same result for es_419' );

is( $self_obj->get_locale_display_pattern_from_code('es_es'), $self_obj->get_locale_display_pattern_from_code_fast('es_es'), 'get_locale_display_pattern_from_code[_fast] same result for es_es' );
is( $self_obj->get_character_orientation_from_code('es_es'),  $self_obj->get_character_orientation_from_code('es_es'),       'get_character_orientation_from_code[_fast] same result for es_es' );

is( $self_obj->get_locale_display_pattern_from_code('et'), $self_obj->get_locale_display_pattern_from_code_fast('et'), 'get_locale_display_pattern_from_code[_fast] same result for et' );
is( $self_obj->get_character_orientation_from_code('et'),  $self_obj->get_character_orientation_from_code('et'),       'get_character_orientation_from_code[_fast] same result for et' );

is( $self_obj->get_locale_display_pattern_from_code('eu'), $self_obj->get_locale_display_pattern_from_code_fast('eu'), 'get_locale_display_pattern_from_code[_fast] same result for eu' );
is( $self_obj->get_character_orientation_from_code('eu'),  $self_obj->get_character_orientation_from_code('eu'),       'get_character_orientation_from_code[_fast] same result for eu' );

is( $self_obj->get_locale_display_pattern_from_code('ewo'), $self_obj->get_locale_display_pattern_from_code_fast('ewo'), 'get_locale_display_pattern_from_code[_fast] same result for ewo' );
is( $self_obj->get_character_orientation_from_code('ewo'),  $self_obj->get_character_orientation_from_code('ewo'),       'get_character_orientation_from_code[_fast] same result for ewo' );

is( $self_obj->get_locale_display_pattern_from_code('fa'), $self_obj->get_locale_display_pattern_from_code_fast('fa'), 'get_locale_display_pattern_from_code[_fast] same result for fa' );
is( $self_obj->get_character_orientation_from_code('fa'),  $self_obj->get_character_orientation_from_code('fa'),       'get_character_orientation_from_code[_fast] same result for fa' );

is( $self_obj->get_locale_display_pattern_from_code('fan'), $self_obj->get_locale_display_pattern_from_code_fast('fan'), 'get_locale_display_pattern_from_code[_fast] same result for fan' );
is( $self_obj->get_character_orientation_from_code('fan'),  $self_obj->get_character_orientation_from_code('fan'),       'get_character_orientation_from_code[_fast] same result for fan' );

is( $self_obj->get_locale_display_pattern_from_code('fat'), $self_obj->get_locale_display_pattern_from_code_fast('fat'), 'get_locale_display_pattern_from_code[_fast] same result for fat' );
is( $self_obj->get_character_orientation_from_code('fat'),  $self_obj->get_character_orientation_from_code('fat'),       'get_character_orientation_from_code[_fast] same result for fat' );

is( $self_obj->get_locale_display_pattern_from_code('ff'), $self_obj->get_locale_display_pattern_from_code_fast('ff'), 'get_locale_display_pattern_from_code[_fast] same result for ff' );
is( $self_obj->get_character_orientation_from_code('ff'),  $self_obj->get_character_orientation_from_code('ff'),       'get_character_orientation_from_code[_fast] same result for ff' );

is( $self_obj->get_locale_display_pattern_from_code('fi'), $self_obj->get_locale_display_pattern_from_code_fast('fi'), 'get_locale_display_pattern_from_code[_fast] same result for fi' );
is( $self_obj->get_character_orientation_from_code('fi'),  $self_obj->get_character_orientation_from_code('fi'),       'get_character_orientation_from_code[_fast] same result for fi' );

is( $self_obj->get_locale_display_pattern_from_code('fil'), $self_obj->get_locale_display_pattern_from_code_fast('fil'), 'get_locale_display_pattern_from_code[_fast] same result for fil' );
is( $self_obj->get_character_orientation_from_code('fil'),  $self_obj->get_character_orientation_from_code('fil'),       'get_character_orientation_from_code[_fast] same result for fil' );

is( $self_obj->get_locale_display_pattern_from_code('fiu'), $self_obj->get_locale_display_pattern_from_code_fast('fiu'), 'get_locale_display_pattern_from_code[_fast] same result for fiu' );
is( $self_obj->get_character_orientation_from_code('fiu'),  $self_obj->get_character_orientation_from_code('fiu'),       'get_character_orientation_from_code[_fast] same result for fiu' );

is( $self_obj->get_locale_display_pattern_from_code('fj'), $self_obj->get_locale_display_pattern_from_code_fast('fj'), 'get_locale_display_pattern_from_code[_fast] same result for fj' );
is( $self_obj->get_character_orientation_from_code('fj'),  $self_obj->get_character_orientation_from_code('fj'),       'get_character_orientation_from_code[_fast] same result for fj' );

is( $self_obj->get_locale_display_pattern_from_code('fo'), $self_obj->get_locale_display_pattern_from_code_fast('fo'), 'get_locale_display_pattern_from_code[_fast] same result for fo' );
is( $self_obj->get_character_orientation_from_code('fo'),  $self_obj->get_character_orientation_from_code('fo'),       'get_character_orientation_from_code[_fast] same result for fo' );

is( $self_obj->get_locale_display_pattern_from_code('fon'), $self_obj->get_locale_display_pattern_from_code_fast('fon'), 'get_locale_display_pattern_from_code[_fast] same result for fon' );
is( $self_obj->get_character_orientation_from_code('fon'),  $self_obj->get_character_orientation_from_code('fon'),       'get_character_orientation_from_code[_fast] same result for fon' );

is( $self_obj->get_locale_display_pattern_from_code('fr'), $self_obj->get_locale_display_pattern_from_code_fast('fr'), 'get_locale_display_pattern_from_code[_fast] same result for fr' );
is( $self_obj->get_character_orientation_from_code('fr'),  $self_obj->get_character_orientation_from_code('fr'),       'get_character_orientation_from_code[_fast] same result for fr' );

is( $self_obj->get_locale_display_pattern_from_code('fr_ca'), $self_obj->get_locale_display_pattern_from_code_fast('fr_ca'), 'get_locale_display_pattern_from_code[_fast] same result for fr_ca' );
is( $self_obj->get_character_orientation_from_code('fr_ca'),  $self_obj->get_character_orientation_from_code('fr_ca'),       'get_character_orientation_from_code[_fast] same result for fr_ca' );

is( $self_obj->get_locale_display_pattern_from_code('fr_ch'), $self_obj->get_locale_display_pattern_from_code_fast('fr_ch'), 'get_locale_display_pattern_from_code[_fast] same result for fr_ch' );
is( $self_obj->get_character_orientation_from_code('fr_ch'),  $self_obj->get_character_orientation_from_code('fr_ch'),       'get_character_orientation_from_code[_fast] same result for fr_ch' );

is( $self_obj->get_locale_display_pattern_from_code('frm'), $self_obj->get_locale_display_pattern_from_code_fast('frm'), 'get_locale_display_pattern_from_code[_fast] same result for frm' );
is( $self_obj->get_character_orientation_from_code('frm'),  $self_obj->get_character_orientation_from_code('frm'),       'get_character_orientation_from_code[_fast] same result for frm' );

is( $self_obj->get_locale_display_pattern_from_code('fro'), $self_obj->get_locale_display_pattern_from_code_fast('fro'), 'get_locale_display_pattern_from_code[_fast] same result for fro' );
is( $self_obj->get_character_orientation_from_code('fro'),  $self_obj->get_character_orientation_from_code('fro'),       'get_character_orientation_from_code[_fast] same result for fro' );

is( $self_obj->get_locale_display_pattern_from_code('frr'), $self_obj->get_locale_display_pattern_from_code_fast('frr'), 'get_locale_display_pattern_from_code[_fast] same result for frr' );
is( $self_obj->get_character_orientation_from_code('frr'),  $self_obj->get_character_orientation_from_code('frr'),       'get_character_orientation_from_code[_fast] same result for frr' );

is( $self_obj->get_locale_display_pattern_from_code('frs'), $self_obj->get_locale_display_pattern_from_code_fast('frs'), 'get_locale_display_pattern_from_code[_fast] same result for frs' );
is( $self_obj->get_character_orientation_from_code('frs'),  $self_obj->get_character_orientation_from_code('frs'),       'get_character_orientation_from_code[_fast] same result for frs' );

is( $self_obj->get_locale_display_pattern_from_code('fur'), $self_obj->get_locale_display_pattern_from_code_fast('fur'), 'get_locale_display_pattern_from_code[_fast] same result for fur' );
is( $self_obj->get_character_orientation_from_code('fur'),  $self_obj->get_character_orientation_from_code('fur'),       'get_character_orientation_from_code[_fast] same result for fur' );

is( $self_obj->get_locale_display_pattern_from_code('fy'), $self_obj->get_locale_display_pattern_from_code_fast('fy'), 'get_locale_display_pattern_from_code[_fast] same result for fy' );
is( $self_obj->get_character_orientation_from_code('fy'),  $self_obj->get_character_orientation_from_code('fy'),       'get_character_orientation_from_code[_fast] same result for fy' );

is( $self_obj->get_locale_display_pattern_from_code('ga'), $self_obj->get_locale_display_pattern_from_code_fast('ga'), 'get_locale_display_pattern_from_code[_fast] same result for ga' );
is( $self_obj->get_character_orientation_from_code('ga'),  $self_obj->get_character_orientation_from_code('ga'),       'get_character_orientation_from_code[_fast] same result for ga' );

is( $self_obj->get_locale_display_pattern_from_code('gaa'), $self_obj->get_locale_display_pattern_from_code_fast('gaa'), 'get_locale_display_pattern_from_code[_fast] same result for gaa' );
is( $self_obj->get_character_orientation_from_code('gaa'),  $self_obj->get_character_orientation_from_code('gaa'),       'get_character_orientation_from_code[_fast] same result for gaa' );

is( $self_obj->get_locale_display_pattern_from_code('gay'), $self_obj->get_locale_display_pattern_from_code_fast('gay'), 'get_locale_display_pattern_from_code[_fast] same result for gay' );
is( $self_obj->get_character_orientation_from_code('gay'),  $self_obj->get_character_orientation_from_code('gay'),       'get_character_orientation_from_code[_fast] same result for gay' );

is( $self_obj->get_locale_display_pattern_from_code('gba'), $self_obj->get_locale_display_pattern_from_code_fast('gba'), 'get_locale_display_pattern_from_code[_fast] same result for gba' );
is( $self_obj->get_character_orientation_from_code('gba'),  $self_obj->get_character_orientation_from_code('gba'),       'get_character_orientation_from_code[_fast] same result for gba' );

is( $self_obj->get_locale_display_pattern_from_code('gd'), $self_obj->get_locale_display_pattern_from_code_fast('gd'), 'get_locale_display_pattern_from_code[_fast] same result for gd' );
is( $self_obj->get_character_orientation_from_code('gd'),  $self_obj->get_character_orientation_from_code('gd'),       'get_character_orientation_from_code[_fast] same result for gd' );

is( $self_obj->get_locale_display_pattern_from_code('gem'), $self_obj->get_locale_display_pattern_from_code_fast('gem'), 'get_locale_display_pattern_from_code[_fast] same result for gem' );
is( $self_obj->get_character_orientation_from_code('gem'),  $self_obj->get_character_orientation_from_code('gem'),       'get_character_orientation_from_code[_fast] same result for gem' );

is( $self_obj->get_locale_display_pattern_from_code('gez'), $self_obj->get_locale_display_pattern_from_code_fast('gez'), 'get_locale_display_pattern_from_code[_fast] same result for gez' );
is( $self_obj->get_character_orientation_from_code('gez'),  $self_obj->get_character_orientation_from_code('gez'),       'get_character_orientation_from_code[_fast] same result for gez' );

is( $self_obj->get_locale_display_pattern_from_code('gil'), $self_obj->get_locale_display_pattern_from_code_fast('gil'), 'get_locale_display_pattern_from_code[_fast] same result for gil' );
is( $self_obj->get_character_orientation_from_code('gil'),  $self_obj->get_character_orientation_from_code('gil'),       'get_character_orientation_from_code[_fast] same result for gil' );

is( $self_obj->get_locale_display_pattern_from_code('gl'), $self_obj->get_locale_display_pattern_from_code_fast('gl'), 'get_locale_display_pattern_from_code[_fast] same result for gl' );
is( $self_obj->get_character_orientation_from_code('gl'),  $self_obj->get_character_orientation_from_code('gl'),       'get_character_orientation_from_code[_fast] same result for gl' );

is( $self_obj->get_locale_display_pattern_from_code('gmh'), $self_obj->get_locale_display_pattern_from_code_fast('gmh'), 'get_locale_display_pattern_from_code[_fast] same result for gmh' );
is( $self_obj->get_character_orientation_from_code('gmh'),  $self_obj->get_character_orientation_from_code('gmh'),       'get_character_orientation_from_code[_fast] same result for gmh' );

is( $self_obj->get_locale_display_pattern_from_code('gn'), $self_obj->get_locale_display_pattern_from_code_fast('gn'), 'get_locale_display_pattern_from_code[_fast] same result for gn' );
is( $self_obj->get_character_orientation_from_code('gn'),  $self_obj->get_character_orientation_from_code('gn'),       'get_character_orientation_from_code[_fast] same result for gn' );

is( $self_obj->get_locale_display_pattern_from_code('goh'), $self_obj->get_locale_display_pattern_from_code_fast('goh'), 'get_locale_display_pattern_from_code[_fast] same result for goh' );
is( $self_obj->get_character_orientation_from_code('goh'),  $self_obj->get_character_orientation_from_code('goh'),       'get_character_orientation_from_code[_fast] same result for goh' );

is( $self_obj->get_locale_display_pattern_from_code('gon'), $self_obj->get_locale_display_pattern_from_code_fast('gon'), 'get_locale_display_pattern_from_code[_fast] same result for gon' );
is( $self_obj->get_character_orientation_from_code('gon'),  $self_obj->get_character_orientation_from_code('gon'),       'get_character_orientation_from_code[_fast] same result for gon' );

is( $self_obj->get_locale_display_pattern_from_code('gor'), $self_obj->get_locale_display_pattern_from_code_fast('gor'), 'get_locale_display_pattern_from_code[_fast] same result for gor' );
is( $self_obj->get_character_orientation_from_code('gor'),  $self_obj->get_character_orientation_from_code('gor'),       'get_character_orientation_from_code[_fast] same result for gor' );

is( $self_obj->get_locale_display_pattern_from_code('got'), $self_obj->get_locale_display_pattern_from_code_fast('got'), 'get_locale_display_pattern_from_code[_fast] same result for got' );
is( $self_obj->get_character_orientation_from_code('got'),  $self_obj->get_character_orientation_from_code('got'),       'get_character_orientation_from_code[_fast] same result for got' );

is( $self_obj->get_locale_display_pattern_from_code('grb'), $self_obj->get_locale_display_pattern_from_code_fast('grb'), 'get_locale_display_pattern_from_code[_fast] same result for grb' );
is( $self_obj->get_character_orientation_from_code('grb'),  $self_obj->get_character_orientation_from_code('grb'),       'get_character_orientation_from_code[_fast] same result for grb' );

is( $self_obj->get_locale_display_pattern_from_code('grc'), $self_obj->get_locale_display_pattern_from_code_fast('grc'), 'get_locale_display_pattern_from_code[_fast] same result for grc' );
is( $self_obj->get_character_orientation_from_code('grc'),  $self_obj->get_character_orientation_from_code('grc'),       'get_character_orientation_from_code[_fast] same result for grc' );

is( $self_obj->get_locale_display_pattern_from_code('gsw'), $self_obj->get_locale_display_pattern_from_code_fast('gsw'), 'get_locale_display_pattern_from_code[_fast] same result for gsw' );
is( $self_obj->get_character_orientation_from_code('gsw'),  $self_obj->get_character_orientation_from_code('gsw'),       'get_character_orientation_from_code[_fast] same result for gsw' );

is( $self_obj->get_locale_display_pattern_from_code('gu'), $self_obj->get_locale_display_pattern_from_code_fast('gu'), 'get_locale_display_pattern_from_code[_fast] same result for gu' );
is( $self_obj->get_character_orientation_from_code('gu'),  $self_obj->get_character_orientation_from_code('gu'),       'get_character_orientation_from_code[_fast] same result for gu' );

is( $self_obj->get_locale_display_pattern_from_code('guz'), $self_obj->get_locale_display_pattern_from_code_fast('guz'), 'get_locale_display_pattern_from_code[_fast] same result for guz' );
is( $self_obj->get_character_orientation_from_code('guz'),  $self_obj->get_character_orientation_from_code('guz'),       'get_character_orientation_from_code[_fast] same result for guz' );

is( $self_obj->get_locale_display_pattern_from_code('gv'), $self_obj->get_locale_display_pattern_from_code_fast('gv'), 'get_locale_display_pattern_from_code[_fast] same result for gv' );
is( $self_obj->get_character_orientation_from_code('gv'),  $self_obj->get_character_orientation_from_code('gv'),       'get_character_orientation_from_code[_fast] same result for gv' );

is( $self_obj->get_locale_display_pattern_from_code('gwi'), $self_obj->get_locale_display_pattern_from_code_fast('gwi'), 'get_locale_display_pattern_from_code[_fast] same result for gwi' );
is( $self_obj->get_character_orientation_from_code('gwi'),  $self_obj->get_character_orientation_from_code('gwi'),       'get_character_orientation_from_code[_fast] same result for gwi' );

is( $self_obj->get_locale_display_pattern_from_code('ha'), $self_obj->get_locale_display_pattern_from_code_fast('ha'), 'get_locale_display_pattern_from_code[_fast] same result for ha' );
is( $self_obj->get_character_orientation_from_code('ha'),  $self_obj->get_character_orientation_from_code('ha'),       'get_character_orientation_from_code[_fast] same result for ha' );

is( $self_obj->get_locale_display_pattern_from_code('hai'), $self_obj->get_locale_display_pattern_from_code_fast('hai'), 'get_locale_display_pattern_from_code[_fast] same result for hai' );
is( $self_obj->get_character_orientation_from_code('hai'),  $self_obj->get_character_orientation_from_code('hai'),       'get_character_orientation_from_code[_fast] same result for hai' );

is( $self_obj->get_locale_display_pattern_from_code('haw'), $self_obj->get_locale_display_pattern_from_code_fast('haw'), 'get_locale_display_pattern_from_code[_fast] same result for haw' );
is( $self_obj->get_character_orientation_from_code('haw'),  $self_obj->get_character_orientation_from_code('haw'),       'get_character_orientation_from_code[_fast] same result for haw' );

is( $self_obj->get_locale_display_pattern_from_code('he'), $self_obj->get_locale_display_pattern_from_code_fast('he'), 'get_locale_display_pattern_from_code[_fast] same result for he' );
is( $self_obj->get_character_orientation_from_code('he'),  $self_obj->get_character_orientation_from_code('he'),       'get_character_orientation_from_code[_fast] same result for he' );

is( $self_obj->get_locale_display_pattern_from_code('hi'), $self_obj->get_locale_display_pattern_from_code_fast('hi'), 'get_locale_display_pattern_from_code[_fast] same result for hi' );
is( $self_obj->get_character_orientation_from_code('hi'),  $self_obj->get_character_orientation_from_code('hi'),       'get_character_orientation_from_code[_fast] same result for hi' );

is( $self_obj->get_locale_display_pattern_from_code('hil'), $self_obj->get_locale_display_pattern_from_code_fast('hil'), 'get_locale_display_pattern_from_code[_fast] same result for hil' );
is( $self_obj->get_character_orientation_from_code('hil'),  $self_obj->get_character_orientation_from_code('hil'),       'get_character_orientation_from_code[_fast] same result for hil' );

is( $self_obj->get_locale_display_pattern_from_code('him'), $self_obj->get_locale_display_pattern_from_code_fast('him'), 'get_locale_display_pattern_from_code[_fast] same result for him' );
is( $self_obj->get_character_orientation_from_code('him'),  $self_obj->get_character_orientation_from_code('him'),       'get_character_orientation_from_code[_fast] same result for him' );

is( $self_obj->get_locale_display_pattern_from_code('hit'), $self_obj->get_locale_display_pattern_from_code_fast('hit'), 'get_locale_display_pattern_from_code[_fast] same result for hit' );
is( $self_obj->get_character_orientation_from_code('hit'),  $self_obj->get_character_orientation_from_code('hit'),       'get_character_orientation_from_code[_fast] same result for hit' );

is( $self_obj->get_locale_display_pattern_from_code('hmn'), $self_obj->get_locale_display_pattern_from_code_fast('hmn'), 'get_locale_display_pattern_from_code[_fast] same result for hmn' );
is( $self_obj->get_character_orientation_from_code('hmn'),  $self_obj->get_character_orientation_from_code('hmn'),       'get_character_orientation_from_code[_fast] same result for hmn' );

is( $self_obj->get_locale_display_pattern_from_code('ho'), $self_obj->get_locale_display_pattern_from_code_fast('ho'), 'get_locale_display_pattern_from_code[_fast] same result for ho' );
is( $self_obj->get_character_orientation_from_code('ho'),  $self_obj->get_character_orientation_from_code('ho'),       'get_character_orientation_from_code[_fast] same result for ho' );

is( $self_obj->get_locale_display_pattern_from_code('hr'), $self_obj->get_locale_display_pattern_from_code_fast('hr'), 'get_locale_display_pattern_from_code[_fast] same result for hr' );
is( $self_obj->get_character_orientation_from_code('hr'),  $self_obj->get_character_orientation_from_code('hr'),       'get_character_orientation_from_code[_fast] same result for hr' );

is( $self_obj->get_locale_display_pattern_from_code('hsb'), $self_obj->get_locale_display_pattern_from_code_fast('hsb'), 'get_locale_display_pattern_from_code[_fast] same result for hsb' );
is( $self_obj->get_character_orientation_from_code('hsb'),  $self_obj->get_character_orientation_from_code('hsb'),       'get_character_orientation_from_code[_fast] same result for hsb' );

is( $self_obj->get_locale_display_pattern_from_code('ht'), $self_obj->get_locale_display_pattern_from_code_fast('ht'), 'get_locale_display_pattern_from_code[_fast] same result for ht' );
is( $self_obj->get_character_orientation_from_code('ht'),  $self_obj->get_character_orientation_from_code('ht'),       'get_character_orientation_from_code[_fast] same result for ht' );

is( $self_obj->get_locale_display_pattern_from_code('hu'), $self_obj->get_locale_display_pattern_from_code_fast('hu'), 'get_locale_display_pattern_from_code[_fast] same result for hu' );
is( $self_obj->get_character_orientation_from_code('hu'),  $self_obj->get_character_orientation_from_code('hu'),       'get_character_orientation_from_code[_fast] same result for hu' );

is( $self_obj->get_locale_display_pattern_from_code('hup'), $self_obj->get_locale_display_pattern_from_code_fast('hup'), 'get_locale_display_pattern_from_code[_fast] same result for hup' );
is( $self_obj->get_character_orientation_from_code('hup'),  $self_obj->get_character_orientation_from_code('hup'),       'get_character_orientation_from_code[_fast] same result for hup' );

is( $self_obj->get_locale_display_pattern_from_code('hy'), $self_obj->get_locale_display_pattern_from_code_fast('hy'), 'get_locale_display_pattern_from_code[_fast] same result for hy' );
is( $self_obj->get_character_orientation_from_code('hy'),  $self_obj->get_character_orientation_from_code('hy'),       'get_character_orientation_from_code[_fast] same result for hy' );

is( $self_obj->get_locale_display_pattern_from_code('hz'), $self_obj->get_locale_display_pattern_from_code_fast('hz'), 'get_locale_display_pattern_from_code[_fast] same result for hz' );
is( $self_obj->get_character_orientation_from_code('hz'),  $self_obj->get_character_orientation_from_code('hz'),       'get_character_orientation_from_code[_fast] same result for hz' );

is( $self_obj->get_locale_display_pattern_from_code('ia'), $self_obj->get_locale_display_pattern_from_code_fast('ia'), 'get_locale_display_pattern_from_code[_fast] same result for ia' );
is( $self_obj->get_character_orientation_from_code('ia'),  $self_obj->get_character_orientation_from_code('ia'),       'get_character_orientation_from_code[_fast] same result for ia' );

is( $self_obj->get_locale_display_pattern_from_code('iba'), $self_obj->get_locale_display_pattern_from_code_fast('iba'), 'get_locale_display_pattern_from_code[_fast] same result for iba' );
is( $self_obj->get_character_orientation_from_code('iba'),  $self_obj->get_character_orientation_from_code('iba'),       'get_character_orientation_from_code[_fast] same result for iba' );

is( $self_obj->get_locale_display_pattern_from_code('id'), $self_obj->get_locale_display_pattern_from_code_fast('id'), 'get_locale_display_pattern_from_code[_fast] same result for id' );
is( $self_obj->get_character_orientation_from_code('id'),  $self_obj->get_character_orientation_from_code('id'),       'get_character_orientation_from_code[_fast] same result for id' );

is( $self_obj->get_locale_display_pattern_from_code('ie'), $self_obj->get_locale_display_pattern_from_code_fast('ie'), 'get_locale_display_pattern_from_code[_fast] same result for ie' );
is( $self_obj->get_character_orientation_from_code('ie'),  $self_obj->get_character_orientation_from_code('ie'),       'get_character_orientation_from_code[_fast] same result for ie' );

is( $self_obj->get_locale_display_pattern_from_code('ig'), $self_obj->get_locale_display_pattern_from_code_fast('ig'), 'get_locale_display_pattern_from_code[_fast] same result for ig' );
is( $self_obj->get_character_orientation_from_code('ig'),  $self_obj->get_character_orientation_from_code('ig'),       'get_character_orientation_from_code[_fast] same result for ig' );

is( $self_obj->get_locale_display_pattern_from_code('ii'), $self_obj->get_locale_display_pattern_from_code_fast('ii'), 'get_locale_display_pattern_from_code[_fast] same result for ii' );
is( $self_obj->get_character_orientation_from_code('ii'),  $self_obj->get_character_orientation_from_code('ii'),       'get_character_orientation_from_code[_fast] same result for ii' );

is( $self_obj->get_locale_display_pattern_from_code('ijo'), $self_obj->get_locale_display_pattern_from_code_fast('ijo'), 'get_locale_display_pattern_from_code[_fast] same result for ijo' );
is( $self_obj->get_character_orientation_from_code('ijo'),  $self_obj->get_character_orientation_from_code('ijo'),       'get_character_orientation_from_code[_fast] same result for ijo' );

is( $self_obj->get_locale_display_pattern_from_code('ik'), $self_obj->get_locale_display_pattern_from_code_fast('ik'), 'get_locale_display_pattern_from_code[_fast] same result for ik' );
is( $self_obj->get_character_orientation_from_code('ik'),  $self_obj->get_character_orientation_from_code('ik'),       'get_character_orientation_from_code[_fast] same result for ik' );

is( $self_obj->get_locale_display_pattern_from_code('ilo'), $self_obj->get_locale_display_pattern_from_code_fast('ilo'), 'get_locale_display_pattern_from_code[_fast] same result for ilo' );
is( $self_obj->get_character_orientation_from_code('ilo'),  $self_obj->get_character_orientation_from_code('ilo'),       'get_character_orientation_from_code[_fast] same result for ilo' );

is( $self_obj->get_locale_display_pattern_from_code('inc'), $self_obj->get_locale_display_pattern_from_code_fast('inc'), 'get_locale_display_pattern_from_code[_fast] same result for inc' );
is( $self_obj->get_character_orientation_from_code('inc'),  $self_obj->get_character_orientation_from_code('inc'),       'get_character_orientation_from_code[_fast] same result for inc' );

is( $self_obj->get_locale_display_pattern_from_code('ine'), $self_obj->get_locale_display_pattern_from_code_fast('ine'), 'get_locale_display_pattern_from_code[_fast] same result for ine' );
is( $self_obj->get_character_orientation_from_code('ine'),  $self_obj->get_character_orientation_from_code('ine'),       'get_character_orientation_from_code[_fast] same result for ine' );

is( $self_obj->get_locale_display_pattern_from_code('inh'), $self_obj->get_locale_display_pattern_from_code_fast('inh'), 'get_locale_display_pattern_from_code[_fast] same result for inh' );
is( $self_obj->get_character_orientation_from_code('inh'),  $self_obj->get_character_orientation_from_code('inh'),       'get_character_orientation_from_code[_fast] same result for inh' );

is( $self_obj->get_locale_display_pattern_from_code('io'), $self_obj->get_locale_display_pattern_from_code_fast('io'), 'get_locale_display_pattern_from_code[_fast] same result for io' );
is( $self_obj->get_character_orientation_from_code('io'),  $self_obj->get_character_orientation_from_code('io'),       'get_character_orientation_from_code[_fast] same result for io' );

is( $self_obj->get_locale_display_pattern_from_code('ira'), $self_obj->get_locale_display_pattern_from_code_fast('ira'), 'get_locale_display_pattern_from_code[_fast] same result for ira' );
is( $self_obj->get_character_orientation_from_code('ira'),  $self_obj->get_character_orientation_from_code('ira'),       'get_character_orientation_from_code[_fast] same result for ira' );

is( $self_obj->get_locale_display_pattern_from_code('iro'), $self_obj->get_locale_display_pattern_from_code_fast('iro'), 'get_locale_display_pattern_from_code[_fast] same result for iro' );
is( $self_obj->get_character_orientation_from_code('iro'),  $self_obj->get_character_orientation_from_code('iro'),       'get_character_orientation_from_code[_fast] same result for iro' );

is( $self_obj->get_locale_display_pattern_from_code('is'), $self_obj->get_locale_display_pattern_from_code_fast('is'), 'get_locale_display_pattern_from_code[_fast] same result for is' );
is( $self_obj->get_character_orientation_from_code('is'),  $self_obj->get_character_orientation_from_code('is'),       'get_character_orientation_from_code[_fast] same result for is' );

is( $self_obj->get_locale_display_pattern_from_code('it'), $self_obj->get_locale_display_pattern_from_code_fast('it'), 'get_locale_display_pattern_from_code[_fast] same result for it' );
is( $self_obj->get_character_orientation_from_code('it'),  $self_obj->get_character_orientation_from_code('it'),       'get_character_orientation_from_code[_fast] same result for it' );

is( $self_obj->get_locale_display_pattern_from_code('iu'), $self_obj->get_locale_display_pattern_from_code_fast('iu'), 'get_locale_display_pattern_from_code[_fast] same result for iu' );
is( $self_obj->get_character_orientation_from_code('iu'),  $self_obj->get_character_orientation_from_code('iu'),       'get_character_orientation_from_code[_fast] same result for iu' );

is( $self_obj->get_locale_display_pattern_from_code('ja'), $self_obj->get_locale_display_pattern_from_code_fast('ja'), 'get_locale_display_pattern_from_code[_fast] same result for ja' );
is( $self_obj->get_character_orientation_from_code('ja'),  $self_obj->get_character_orientation_from_code('ja'),       'get_character_orientation_from_code[_fast] same result for ja' );

is( $self_obj->get_locale_display_pattern_from_code('jbo'), $self_obj->get_locale_display_pattern_from_code_fast('jbo'), 'get_locale_display_pattern_from_code[_fast] same result for jbo' );
is( $self_obj->get_character_orientation_from_code('jbo'),  $self_obj->get_character_orientation_from_code('jbo'),       'get_character_orientation_from_code[_fast] same result for jbo' );

is( $self_obj->get_locale_display_pattern_from_code('jmc'), $self_obj->get_locale_display_pattern_from_code_fast('jmc'), 'get_locale_display_pattern_from_code[_fast] same result for jmc' );
is( $self_obj->get_character_orientation_from_code('jmc'),  $self_obj->get_character_orientation_from_code('jmc'),       'get_character_orientation_from_code[_fast] same result for jmc' );

is( $self_obj->get_locale_display_pattern_from_code('jpr'), $self_obj->get_locale_display_pattern_from_code_fast('jpr'), 'get_locale_display_pattern_from_code[_fast] same result for jpr' );
is( $self_obj->get_character_orientation_from_code('jpr'),  $self_obj->get_character_orientation_from_code('jpr'),       'get_character_orientation_from_code[_fast] same result for jpr' );

is( $self_obj->get_locale_display_pattern_from_code('jrb'), $self_obj->get_locale_display_pattern_from_code_fast('jrb'), 'get_locale_display_pattern_from_code[_fast] same result for jrb' );
is( $self_obj->get_character_orientation_from_code('jrb'),  $self_obj->get_character_orientation_from_code('jrb'),       'get_character_orientation_from_code[_fast] same result for jrb' );

is( $self_obj->get_locale_display_pattern_from_code('jv'), $self_obj->get_locale_display_pattern_from_code_fast('jv'), 'get_locale_display_pattern_from_code[_fast] same result for jv' );
is( $self_obj->get_character_orientation_from_code('jv'),  $self_obj->get_character_orientation_from_code('jv'),       'get_character_orientation_from_code[_fast] same result for jv' );

is( $self_obj->get_locale_display_pattern_from_code('ka'), $self_obj->get_locale_display_pattern_from_code_fast('ka'), 'get_locale_display_pattern_from_code[_fast] same result for ka' );
is( $self_obj->get_character_orientation_from_code('ka'),  $self_obj->get_character_orientation_from_code('ka'),       'get_character_orientation_from_code[_fast] same result for ka' );

is( $self_obj->get_locale_display_pattern_from_code('kaa'), $self_obj->get_locale_display_pattern_from_code_fast('kaa'), 'get_locale_display_pattern_from_code[_fast] same result for kaa' );
is( $self_obj->get_character_orientation_from_code('kaa'),  $self_obj->get_character_orientation_from_code('kaa'),       'get_character_orientation_from_code[_fast] same result for kaa' );

is( $self_obj->get_locale_display_pattern_from_code('kab'), $self_obj->get_locale_display_pattern_from_code_fast('kab'), 'get_locale_display_pattern_from_code[_fast] same result for kab' );
is( $self_obj->get_character_orientation_from_code('kab'),  $self_obj->get_character_orientation_from_code('kab'),       'get_character_orientation_from_code[_fast] same result for kab' );

is( $self_obj->get_locale_display_pattern_from_code('kac'), $self_obj->get_locale_display_pattern_from_code_fast('kac'), 'get_locale_display_pattern_from_code[_fast] same result for kac' );
is( $self_obj->get_character_orientation_from_code('kac'),  $self_obj->get_character_orientation_from_code('kac'),       'get_character_orientation_from_code[_fast] same result for kac' );

is( $self_obj->get_locale_display_pattern_from_code('kaj'), $self_obj->get_locale_display_pattern_from_code_fast('kaj'), 'get_locale_display_pattern_from_code[_fast] same result for kaj' );
is( $self_obj->get_character_orientation_from_code('kaj'),  $self_obj->get_character_orientation_from_code('kaj'),       'get_character_orientation_from_code[_fast] same result for kaj' );

is( $self_obj->get_locale_display_pattern_from_code('kam'), $self_obj->get_locale_display_pattern_from_code_fast('kam'), 'get_locale_display_pattern_from_code[_fast] same result for kam' );
is( $self_obj->get_character_orientation_from_code('kam'),  $self_obj->get_character_orientation_from_code('kam'),       'get_character_orientation_from_code[_fast] same result for kam' );

is( $self_obj->get_locale_display_pattern_from_code('kar'), $self_obj->get_locale_display_pattern_from_code_fast('kar'), 'get_locale_display_pattern_from_code[_fast] same result for kar' );
is( $self_obj->get_character_orientation_from_code('kar'),  $self_obj->get_character_orientation_from_code('kar'),       'get_character_orientation_from_code[_fast] same result for kar' );

is( $self_obj->get_locale_display_pattern_from_code('kaw'), $self_obj->get_locale_display_pattern_from_code_fast('kaw'), 'get_locale_display_pattern_from_code[_fast] same result for kaw' );
is( $self_obj->get_character_orientation_from_code('kaw'),  $self_obj->get_character_orientation_from_code('kaw'),       'get_character_orientation_from_code[_fast] same result for kaw' );

is( $self_obj->get_locale_display_pattern_from_code('kbd'), $self_obj->get_locale_display_pattern_from_code_fast('kbd'), 'get_locale_display_pattern_from_code[_fast] same result for kbd' );
is( $self_obj->get_character_orientation_from_code('kbd'),  $self_obj->get_character_orientation_from_code('kbd'),       'get_character_orientation_from_code[_fast] same result for kbd' );

is( $self_obj->get_locale_display_pattern_from_code('kcg'), $self_obj->get_locale_display_pattern_from_code_fast('kcg'), 'get_locale_display_pattern_from_code[_fast] same result for kcg' );
is( $self_obj->get_character_orientation_from_code('kcg'),  $self_obj->get_character_orientation_from_code('kcg'),       'get_character_orientation_from_code[_fast] same result for kcg' );

is( $self_obj->get_locale_display_pattern_from_code('kde'), $self_obj->get_locale_display_pattern_from_code_fast('kde'), 'get_locale_display_pattern_from_code[_fast] same result for kde' );
is( $self_obj->get_character_orientation_from_code('kde'),  $self_obj->get_character_orientation_from_code('kde'),       'get_character_orientation_from_code[_fast] same result for kde' );

is( $self_obj->get_locale_display_pattern_from_code('kea'), $self_obj->get_locale_display_pattern_from_code_fast('kea'), 'get_locale_display_pattern_from_code[_fast] same result for kea' );
is( $self_obj->get_character_orientation_from_code('kea'),  $self_obj->get_character_orientation_from_code('kea'),       'get_character_orientation_from_code[_fast] same result for kea' );

is( $self_obj->get_locale_display_pattern_from_code('kfo'), $self_obj->get_locale_display_pattern_from_code_fast('kfo'), 'get_locale_display_pattern_from_code[_fast] same result for kfo' );
is( $self_obj->get_character_orientation_from_code('kfo'),  $self_obj->get_character_orientation_from_code('kfo'),       'get_character_orientation_from_code[_fast] same result for kfo' );

is( $self_obj->get_locale_display_pattern_from_code('kg'), $self_obj->get_locale_display_pattern_from_code_fast('kg'), 'get_locale_display_pattern_from_code[_fast] same result for kg' );
is( $self_obj->get_character_orientation_from_code('kg'),  $self_obj->get_character_orientation_from_code('kg'),       'get_character_orientation_from_code[_fast] same result for kg' );

is( $self_obj->get_locale_display_pattern_from_code('kha'), $self_obj->get_locale_display_pattern_from_code_fast('kha'), 'get_locale_display_pattern_from_code[_fast] same result for kha' );
is( $self_obj->get_character_orientation_from_code('kha'),  $self_obj->get_character_orientation_from_code('kha'),       'get_character_orientation_from_code[_fast] same result for kha' );

is( $self_obj->get_locale_display_pattern_from_code('khi'), $self_obj->get_locale_display_pattern_from_code_fast('khi'), 'get_locale_display_pattern_from_code[_fast] same result for khi' );
is( $self_obj->get_character_orientation_from_code('khi'),  $self_obj->get_character_orientation_from_code('khi'),       'get_character_orientation_from_code[_fast] same result for khi' );

is( $self_obj->get_locale_display_pattern_from_code('kho'), $self_obj->get_locale_display_pattern_from_code_fast('kho'), 'get_locale_display_pattern_from_code[_fast] same result for kho' );
is( $self_obj->get_character_orientation_from_code('kho'),  $self_obj->get_character_orientation_from_code('kho'),       'get_character_orientation_from_code[_fast] same result for kho' );

is( $self_obj->get_locale_display_pattern_from_code('khq'), $self_obj->get_locale_display_pattern_from_code_fast('khq'), 'get_locale_display_pattern_from_code[_fast] same result for khq' );
is( $self_obj->get_character_orientation_from_code('khq'),  $self_obj->get_character_orientation_from_code('khq'),       'get_character_orientation_from_code[_fast] same result for khq' );

is( $self_obj->get_locale_display_pattern_from_code('ki'), $self_obj->get_locale_display_pattern_from_code_fast('ki'), 'get_locale_display_pattern_from_code[_fast] same result for ki' );
is( $self_obj->get_character_orientation_from_code('ki'),  $self_obj->get_character_orientation_from_code('ki'),       'get_character_orientation_from_code[_fast] same result for ki' );

is( $self_obj->get_locale_display_pattern_from_code('kj'), $self_obj->get_locale_display_pattern_from_code_fast('kj'), 'get_locale_display_pattern_from_code[_fast] same result for kj' );
is( $self_obj->get_character_orientation_from_code('kj'),  $self_obj->get_character_orientation_from_code('kj'),       'get_character_orientation_from_code[_fast] same result for kj' );

is( $self_obj->get_locale_display_pattern_from_code('kk'), $self_obj->get_locale_display_pattern_from_code_fast('kk'), 'get_locale_display_pattern_from_code[_fast] same result for kk' );
is( $self_obj->get_character_orientation_from_code('kk'),  $self_obj->get_character_orientation_from_code('kk'),       'get_character_orientation_from_code[_fast] same result for kk' );

is( $self_obj->get_locale_display_pattern_from_code('kl'), $self_obj->get_locale_display_pattern_from_code_fast('kl'), 'get_locale_display_pattern_from_code[_fast] same result for kl' );
is( $self_obj->get_character_orientation_from_code('kl'),  $self_obj->get_character_orientation_from_code('kl'),       'get_character_orientation_from_code[_fast] same result for kl' );

is( $self_obj->get_locale_display_pattern_from_code('kln'), $self_obj->get_locale_display_pattern_from_code_fast('kln'), 'get_locale_display_pattern_from_code[_fast] same result for kln' );
is( $self_obj->get_character_orientation_from_code('kln'),  $self_obj->get_character_orientation_from_code('kln'),       'get_character_orientation_from_code[_fast] same result for kln' );

is( $self_obj->get_locale_display_pattern_from_code('km'), $self_obj->get_locale_display_pattern_from_code_fast('km'), 'get_locale_display_pattern_from_code[_fast] same result for km' );
is( $self_obj->get_character_orientation_from_code('km'),  $self_obj->get_character_orientation_from_code('km'),       'get_character_orientation_from_code[_fast] same result for km' );

is( $self_obj->get_locale_display_pattern_from_code('kmb'), $self_obj->get_locale_display_pattern_from_code_fast('kmb'), 'get_locale_display_pattern_from_code[_fast] same result for kmb' );
is( $self_obj->get_character_orientation_from_code('kmb'),  $self_obj->get_character_orientation_from_code('kmb'),       'get_character_orientation_from_code[_fast] same result for kmb' );

is( $self_obj->get_locale_display_pattern_from_code('kn'), $self_obj->get_locale_display_pattern_from_code_fast('kn'), 'get_locale_display_pattern_from_code[_fast] same result for kn' );
is( $self_obj->get_character_orientation_from_code('kn'),  $self_obj->get_character_orientation_from_code('kn'),       'get_character_orientation_from_code[_fast] same result for kn' );

is( $self_obj->get_locale_display_pattern_from_code('ko'), $self_obj->get_locale_display_pattern_from_code_fast('ko'), 'get_locale_display_pattern_from_code[_fast] same result for ko' );
is( $self_obj->get_character_orientation_from_code('ko'),  $self_obj->get_character_orientation_from_code('ko'),       'get_character_orientation_from_code[_fast] same result for ko' );

is( $self_obj->get_locale_display_pattern_from_code('kok'), $self_obj->get_locale_display_pattern_from_code_fast('kok'), 'get_locale_display_pattern_from_code[_fast] same result for kok' );
is( $self_obj->get_character_orientation_from_code('kok'),  $self_obj->get_character_orientation_from_code('kok'),       'get_character_orientation_from_code[_fast] same result for kok' );

is( $self_obj->get_locale_display_pattern_from_code('kos'), $self_obj->get_locale_display_pattern_from_code_fast('kos'), 'get_locale_display_pattern_from_code[_fast] same result for kos' );
is( $self_obj->get_character_orientation_from_code('kos'),  $self_obj->get_character_orientation_from_code('kos'),       'get_character_orientation_from_code[_fast] same result for kos' );

is( $self_obj->get_locale_display_pattern_from_code('kpe'), $self_obj->get_locale_display_pattern_from_code_fast('kpe'), 'get_locale_display_pattern_from_code[_fast] same result for kpe' );
is( $self_obj->get_character_orientation_from_code('kpe'),  $self_obj->get_character_orientation_from_code('kpe'),       'get_character_orientation_from_code[_fast] same result for kpe' );

is( $self_obj->get_locale_display_pattern_from_code('kr'), $self_obj->get_locale_display_pattern_from_code_fast('kr'), 'get_locale_display_pattern_from_code[_fast] same result for kr' );
is( $self_obj->get_character_orientation_from_code('kr'),  $self_obj->get_character_orientation_from_code('kr'),       'get_character_orientation_from_code[_fast] same result for kr' );

is( $self_obj->get_locale_display_pattern_from_code('krc'), $self_obj->get_locale_display_pattern_from_code_fast('krc'), 'get_locale_display_pattern_from_code[_fast] same result for krc' );
is( $self_obj->get_character_orientation_from_code('krc'),  $self_obj->get_character_orientation_from_code('krc'),       'get_character_orientation_from_code[_fast] same result for krc' );

is( $self_obj->get_locale_display_pattern_from_code('krl'), $self_obj->get_locale_display_pattern_from_code_fast('krl'), 'get_locale_display_pattern_from_code[_fast] same result for krl' );
is( $self_obj->get_character_orientation_from_code('krl'),  $self_obj->get_character_orientation_from_code('krl'),       'get_character_orientation_from_code[_fast] same result for krl' );

is( $self_obj->get_locale_display_pattern_from_code('kro'), $self_obj->get_locale_display_pattern_from_code_fast('kro'), 'get_locale_display_pattern_from_code[_fast] same result for kro' );
is( $self_obj->get_character_orientation_from_code('kro'),  $self_obj->get_character_orientation_from_code('kro'),       'get_character_orientation_from_code[_fast] same result for kro' );

is( $self_obj->get_locale_display_pattern_from_code('kru'), $self_obj->get_locale_display_pattern_from_code_fast('kru'), 'get_locale_display_pattern_from_code[_fast] same result for kru' );
is( $self_obj->get_character_orientation_from_code('kru'),  $self_obj->get_character_orientation_from_code('kru'),       'get_character_orientation_from_code[_fast] same result for kru' );

is( $self_obj->get_locale_display_pattern_from_code('ks'), $self_obj->get_locale_display_pattern_from_code_fast('ks'), 'get_locale_display_pattern_from_code[_fast] same result for ks' );
is( $self_obj->get_character_orientation_from_code('ks'),  $self_obj->get_character_orientation_from_code('ks'),       'get_character_orientation_from_code[_fast] same result for ks' );

is( $self_obj->get_locale_display_pattern_from_code('ksb'), $self_obj->get_locale_display_pattern_from_code_fast('ksb'), 'get_locale_display_pattern_from_code[_fast] same result for ksb' );
is( $self_obj->get_character_orientation_from_code('ksb'),  $self_obj->get_character_orientation_from_code('ksb'),       'get_character_orientation_from_code[_fast] same result for ksb' );

is( $self_obj->get_locale_display_pattern_from_code('ksf'), $self_obj->get_locale_display_pattern_from_code_fast('ksf'), 'get_locale_display_pattern_from_code[_fast] same result for ksf' );
is( $self_obj->get_character_orientation_from_code('ksf'),  $self_obj->get_character_orientation_from_code('ksf'),       'get_character_orientation_from_code[_fast] same result for ksf' );

is( $self_obj->get_locale_display_pattern_from_code('ksh'), $self_obj->get_locale_display_pattern_from_code_fast('ksh'), 'get_locale_display_pattern_from_code[_fast] same result for ksh' );
is( $self_obj->get_character_orientation_from_code('ksh'),  $self_obj->get_character_orientation_from_code('ksh'),       'get_character_orientation_from_code[_fast] same result for ksh' );

is( $self_obj->get_locale_display_pattern_from_code('ku'), $self_obj->get_locale_display_pattern_from_code_fast('ku'), 'get_locale_display_pattern_from_code[_fast] same result for ku' );
is( $self_obj->get_character_orientation_from_code('ku'),  $self_obj->get_character_orientation_from_code('ku'),       'get_character_orientation_from_code[_fast] same result for ku' );

is( $self_obj->get_locale_display_pattern_from_code('kum'), $self_obj->get_locale_display_pattern_from_code_fast('kum'), 'get_locale_display_pattern_from_code[_fast] same result for kum' );
is( $self_obj->get_character_orientation_from_code('kum'),  $self_obj->get_character_orientation_from_code('kum'),       'get_character_orientation_from_code[_fast] same result for kum' );

is( $self_obj->get_locale_display_pattern_from_code('kut'), $self_obj->get_locale_display_pattern_from_code_fast('kut'), 'get_locale_display_pattern_from_code[_fast] same result for kut' );
is( $self_obj->get_character_orientation_from_code('kut'),  $self_obj->get_character_orientation_from_code('kut'),       'get_character_orientation_from_code[_fast] same result for kut' );

is( $self_obj->get_locale_display_pattern_from_code('kv'), $self_obj->get_locale_display_pattern_from_code_fast('kv'), 'get_locale_display_pattern_from_code[_fast] same result for kv' );
is( $self_obj->get_character_orientation_from_code('kv'),  $self_obj->get_character_orientation_from_code('kv'),       'get_character_orientation_from_code[_fast] same result for kv' );

is( $self_obj->get_locale_display_pattern_from_code('kw'), $self_obj->get_locale_display_pattern_from_code_fast('kw'), 'get_locale_display_pattern_from_code[_fast] same result for kw' );
is( $self_obj->get_character_orientation_from_code('kw'),  $self_obj->get_character_orientation_from_code('kw'),       'get_character_orientation_from_code[_fast] same result for kw' );

is( $self_obj->get_locale_display_pattern_from_code('ky'), $self_obj->get_locale_display_pattern_from_code_fast('ky'), 'get_locale_display_pattern_from_code[_fast] same result for ky' );
is( $self_obj->get_character_orientation_from_code('ky'),  $self_obj->get_character_orientation_from_code('ky'),       'get_character_orientation_from_code[_fast] same result for ky' );

is( $self_obj->get_locale_display_pattern_from_code('la'), $self_obj->get_locale_display_pattern_from_code_fast('la'), 'get_locale_display_pattern_from_code[_fast] same result for la' );
is( $self_obj->get_character_orientation_from_code('la'),  $self_obj->get_character_orientation_from_code('la'),       'get_character_orientation_from_code[_fast] same result for la' );

is( $self_obj->get_locale_display_pattern_from_code('lad'), $self_obj->get_locale_display_pattern_from_code_fast('lad'), 'get_locale_display_pattern_from_code[_fast] same result for lad' );
is( $self_obj->get_character_orientation_from_code('lad'),  $self_obj->get_character_orientation_from_code('lad'),       'get_character_orientation_from_code[_fast] same result for lad' );

is( $self_obj->get_locale_display_pattern_from_code('lag'), $self_obj->get_locale_display_pattern_from_code_fast('lag'), 'get_locale_display_pattern_from_code[_fast] same result for lag' );
is( $self_obj->get_character_orientation_from_code('lag'),  $self_obj->get_character_orientation_from_code('lag'),       'get_character_orientation_from_code[_fast] same result for lag' );

is( $self_obj->get_locale_display_pattern_from_code('lah'), $self_obj->get_locale_display_pattern_from_code_fast('lah'), 'get_locale_display_pattern_from_code[_fast] same result for lah' );
is( $self_obj->get_character_orientation_from_code('lah'),  $self_obj->get_character_orientation_from_code('lah'),       'get_character_orientation_from_code[_fast] same result for lah' );

is( $self_obj->get_locale_display_pattern_from_code('lam'), $self_obj->get_locale_display_pattern_from_code_fast('lam'), 'get_locale_display_pattern_from_code[_fast] same result for lam' );
is( $self_obj->get_character_orientation_from_code('lam'),  $self_obj->get_character_orientation_from_code('lam'),       'get_character_orientation_from_code[_fast] same result for lam' );

is( $self_obj->get_locale_display_pattern_from_code('lb'), $self_obj->get_locale_display_pattern_from_code_fast('lb'), 'get_locale_display_pattern_from_code[_fast] same result for lb' );
is( $self_obj->get_character_orientation_from_code('lb'),  $self_obj->get_character_orientation_from_code('lb'),       'get_character_orientation_from_code[_fast] same result for lb' );

is( $self_obj->get_locale_display_pattern_from_code('lez'), $self_obj->get_locale_display_pattern_from_code_fast('lez'), 'get_locale_display_pattern_from_code[_fast] same result for lez' );
is( $self_obj->get_character_orientation_from_code('lez'),  $self_obj->get_character_orientation_from_code('lez'),       'get_character_orientation_from_code[_fast] same result for lez' );

is( $self_obj->get_locale_display_pattern_from_code('lg'), $self_obj->get_locale_display_pattern_from_code_fast('lg'), 'get_locale_display_pattern_from_code[_fast] same result for lg' );
is( $self_obj->get_character_orientation_from_code('lg'),  $self_obj->get_character_orientation_from_code('lg'),       'get_character_orientation_from_code[_fast] same result for lg' );

is( $self_obj->get_locale_display_pattern_from_code('li'), $self_obj->get_locale_display_pattern_from_code_fast('li'), 'get_locale_display_pattern_from_code[_fast] same result for li' );
is( $self_obj->get_character_orientation_from_code('li'),  $self_obj->get_character_orientation_from_code('li'),       'get_character_orientation_from_code[_fast] same result for li' );

is( $self_obj->get_locale_display_pattern_from_code('ln'), $self_obj->get_locale_display_pattern_from_code_fast('ln'), 'get_locale_display_pattern_from_code[_fast] same result for ln' );
is( $self_obj->get_character_orientation_from_code('ln'),  $self_obj->get_character_orientation_from_code('ln'),       'get_character_orientation_from_code[_fast] same result for ln' );

is( $self_obj->get_locale_display_pattern_from_code('lo'), $self_obj->get_locale_display_pattern_from_code_fast('lo'), 'get_locale_display_pattern_from_code[_fast] same result for lo' );
is( $self_obj->get_character_orientation_from_code('lo'),  $self_obj->get_character_orientation_from_code('lo'),       'get_character_orientation_from_code[_fast] same result for lo' );

is( $self_obj->get_locale_display_pattern_from_code('lol'), $self_obj->get_locale_display_pattern_from_code_fast('lol'), 'get_locale_display_pattern_from_code[_fast] same result for lol' );
is( $self_obj->get_character_orientation_from_code('lol'),  $self_obj->get_character_orientation_from_code('lol'),       'get_character_orientation_from_code[_fast] same result for lol' );

is( $self_obj->get_locale_display_pattern_from_code('loz'), $self_obj->get_locale_display_pattern_from_code_fast('loz'), 'get_locale_display_pattern_from_code[_fast] same result for loz' );
is( $self_obj->get_character_orientation_from_code('loz'),  $self_obj->get_character_orientation_from_code('loz'),       'get_character_orientation_from_code[_fast] same result for loz' );

is( $self_obj->get_locale_display_pattern_from_code('lt'), $self_obj->get_locale_display_pattern_from_code_fast('lt'), 'get_locale_display_pattern_from_code[_fast] same result for lt' );
is( $self_obj->get_character_orientation_from_code('lt'),  $self_obj->get_character_orientation_from_code('lt'),       'get_character_orientation_from_code[_fast] same result for lt' );

is( $self_obj->get_locale_display_pattern_from_code('lu'), $self_obj->get_locale_display_pattern_from_code_fast('lu'), 'get_locale_display_pattern_from_code[_fast] same result for lu' );
is( $self_obj->get_character_orientation_from_code('lu'),  $self_obj->get_character_orientation_from_code('lu'),       'get_character_orientation_from_code[_fast] same result for lu' );

is( $self_obj->get_locale_display_pattern_from_code('lua'), $self_obj->get_locale_display_pattern_from_code_fast('lua'), 'get_locale_display_pattern_from_code[_fast] same result for lua' );
is( $self_obj->get_character_orientation_from_code('lua'),  $self_obj->get_character_orientation_from_code('lua'),       'get_character_orientation_from_code[_fast] same result for lua' );

is( $self_obj->get_locale_display_pattern_from_code('lui'), $self_obj->get_locale_display_pattern_from_code_fast('lui'), 'get_locale_display_pattern_from_code[_fast] same result for lui' );
is( $self_obj->get_character_orientation_from_code('lui'),  $self_obj->get_character_orientation_from_code('lui'),       'get_character_orientation_from_code[_fast] same result for lui' );

is( $self_obj->get_locale_display_pattern_from_code('lun'), $self_obj->get_locale_display_pattern_from_code_fast('lun'), 'get_locale_display_pattern_from_code[_fast] same result for lun' );
is( $self_obj->get_character_orientation_from_code('lun'),  $self_obj->get_character_orientation_from_code('lun'),       'get_character_orientation_from_code[_fast] same result for lun' );

is( $self_obj->get_locale_display_pattern_from_code('luo'), $self_obj->get_locale_display_pattern_from_code_fast('luo'), 'get_locale_display_pattern_from_code[_fast] same result for luo' );
is( $self_obj->get_character_orientation_from_code('luo'),  $self_obj->get_character_orientation_from_code('luo'),       'get_character_orientation_from_code[_fast] same result for luo' );

is( $self_obj->get_locale_display_pattern_from_code('lus'), $self_obj->get_locale_display_pattern_from_code_fast('lus'), 'get_locale_display_pattern_from_code[_fast] same result for lus' );
is( $self_obj->get_character_orientation_from_code('lus'),  $self_obj->get_character_orientation_from_code('lus'),       'get_character_orientation_from_code[_fast] same result for lus' );

is( $self_obj->get_locale_display_pattern_from_code('luy'), $self_obj->get_locale_display_pattern_from_code_fast('luy'), 'get_locale_display_pattern_from_code[_fast] same result for luy' );
is( $self_obj->get_character_orientation_from_code('luy'),  $self_obj->get_character_orientation_from_code('luy'),       'get_character_orientation_from_code[_fast] same result for luy' );

is( $self_obj->get_locale_display_pattern_from_code('lv'), $self_obj->get_locale_display_pattern_from_code_fast('lv'), 'get_locale_display_pattern_from_code[_fast] same result for lv' );
is( $self_obj->get_character_orientation_from_code('lv'),  $self_obj->get_character_orientation_from_code('lv'),       'get_character_orientation_from_code[_fast] same result for lv' );

is( $self_obj->get_locale_display_pattern_from_code('mad'), $self_obj->get_locale_display_pattern_from_code_fast('mad'), 'get_locale_display_pattern_from_code[_fast] same result for mad' );
is( $self_obj->get_character_orientation_from_code('mad'),  $self_obj->get_character_orientation_from_code('mad'),       'get_character_orientation_from_code[_fast] same result for mad' );

is( $self_obj->get_locale_display_pattern_from_code('mag'), $self_obj->get_locale_display_pattern_from_code_fast('mag'), 'get_locale_display_pattern_from_code[_fast] same result for mag' );
is( $self_obj->get_character_orientation_from_code('mag'),  $self_obj->get_character_orientation_from_code('mag'),       'get_character_orientation_from_code[_fast] same result for mag' );

is( $self_obj->get_locale_display_pattern_from_code('mai'), $self_obj->get_locale_display_pattern_from_code_fast('mai'), 'get_locale_display_pattern_from_code[_fast] same result for mai' );
is( $self_obj->get_character_orientation_from_code('mai'),  $self_obj->get_character_orientation_from_code('mai'),       'get_character_orientation_from_code[_fast] same result for mai' );

is( $self_obj->get_locale_display_pattern_from_code('mak'), $self_obj->get_locale_display_pattern_from_code_fast('mak'), 'get_locale_display_pattern_from_code[_fast] same result for mak' );
is( $self_obj->get_character_orientation_from_code('mak'),  $self_obj->get_character_orientation_from_code('mak'),       'get_character_orientation_from_code[_fast] same result for mak' );

is( $self_obj->get_locale_display_pattern_from_code('man'), $self_obj->get_locale_display_pattern_from_code_fast('man'), 'get_locale_display_pattern_from_code[_fast] same result for man' );
is( $self_obj->get_character_orientation_from_code('man'),  $self_obj->get_character_orientation_from_code('man'),       'get_character_orientation_from_code[_fast] same result for man' );

is( $self_obj->get_locale_display_pattern_from_code('map'), $self_obj->get_locale_display_pattern_from_code_fast('map'), 'get_locale_display_pattern_from_code[_fast] same result for map' );
is( $self_obj->get_character_orientation_from_code('map'),  $self_obj->get_character_orientation_from_code('map'),       'get_character_orientation_from_code[_fast] same result for map' );

is( $self_obj->get_locale_display_pattern_from_code('mas'), $self_obj->get_locale_display_pattern_from_code_fast('mas'), 'get_locale_display_pattern_from_code[_fast] same result for mas' );
is( $self_obj->get_character_orientation_from_code('mas'),  $self_obj->get_character_orientation_from_code('mas'),       'get_character_orientation_from_code[_fast] same result for mas' );

is( $self_obj->get_locale_display_pattern_from_code('mdf'), $self_obj->get_locale_display_pattern_from_code_fast('mdf'), 'get_locale_display_pattern_from_code[_fast] same result for mdf' );
is( $self_obj->get_character_orientation_from_code('mdf'),  $self_obj->get_character_orientation_from_code('mdf'),       'get_character_orientation_from_code[_fast] same result for mdf' );

is( $self_obj->get_locale_display_pattern_from_code('mdr'), $self_obj->get_locale_display_pattern_from_code_fast('mdr'), 'get_locale_display_pattern_from_code[_fast] same result for mdr' );
is( $self_obj->get_character_orientation_from_code('mdr'),  $self_obj->get_character_orientation_from_code('mdr'),       'get_character_orientation_from_code[_fast] same result for mdr' );

is( $self_obj->get_locale_display_pattern_from_code('men'), $self_obj->get_locale_display_pattern_from_code_fast('men'), 'get_locale_display_pattern_from_code[_fast] same result for men' );
is( $self_obj->get_character_orientation_from_code('men'),  $self_obj->get_character_orientation_from_code('men'),       'get_character_orientation_from_code[_fast] same result for men' );

is( $self_obj->get_locale_display_pattern_from_code('mer'), $self_obj->get_locale_display_pattern_from_code_fast('mer'), 'get_locale_display_pattern_from_code[_fast] same result for mer' );
is( $self_obj->get_character_orientation_from_code('mer'),  $self_obj->get_character_orientation_from_code('mer'),       'get_character_orientation_from_code[_fast] same result for mer' );

is( $self_obj->get_locale_display_pattern_from_code('mfe'), $self_obj->get_locale_display_pattern_from_code_fast('mfe'), 'get_locale_display_pattern_from_code[_fast] same result for mfe' );
is( $self_obj->get_character_orientation_from_code('mfe'),  $self_obj->get_character_orientation_from_code('mfe'),       'get_character_orientation_from_code[_fast] same result for mfe' );

is( $self_obj->get_locale_display_pattern_from_code('mg'), $self_obj->get_locale_display_pattern_from_code_fast('mg'), 'get_locale_display_pattern_from_code[_fast] same result for mg' );
is( $self_obj->get_character_orientation_from_code('mg'),  $self_obj->get_character_orientation_from_code('mg'),       'get_character_orientation_from_code[_fast] same result for mg' );

is( $self_obj->get_locale_display_pattern_from_code('mga'), $self_obj->get_locale_display_pattern_from_code_fast('mga'), 'get_locale_display_pattern_from_code[_fast] same result for mga' );
is( $self_obj->get_character_orientation_from_code('mga'),  $self_obj->get_character_orientation_from_code('mga'),       'get_character_orientation_from_code[_fast] same result for mga' );

is( $self_obj->get_locale_display_pattern_from_code('mgh'), $self_obj->get_locale_display_pattern_from_code_fast('mgh'), 'get_locale_display_pattern_from_code[_fast] same result for mgh' );
is( $self_obj->get_character_orientation_from_code('mgh'),  $self_obj->get_character_orientation_from_code('mgh'),       'get_character_orientation_from_code[_fast] same result for mgh' );

is( $self_obj->get_locale_display_pattern_from_code('mh'), $self_obj->get_locale_display_pattern_from_code_fast('mh'), 'get_locale_display_pattern_from_code[_fast] same result for mh' );
is( $self_obj->get_character_orientation_from_code('mh'),  $self_obj->get_character_orientation_from_code('mh'),       'get_character_orientation_from_code[_fast] same result for mh' );

is( $self_obj->get_locale_display_pattern_from_code('mi'), $self_obj->get_locale_display_pattern_from_code_fast('mi'), 'get_locale_display_pattern_from_code[_fast] same result for mi' );
is( $self_obj->get_character_orientation_from_code('mi'),  $self_obj->get_character_orientation_from_code('mi'),       'get_character_orientation_from_code[_fast] same result for mi' );

is( $self_obj->get_locale_display_pattern_from_code('mic'), $self_obj->get_locale_display_pattern_from_code_fast('mic'), 'get_locale_display_pattern_from_code[_fast] same result for mic' );
is( $self_obj->get_character_orientation_from_code('mic'),  $self_obj->get_character_orientation_from_code('mic'),       'get_character_orientation_from_code[_fast] same result for mic' );

is( $self_obj->get_locale_display_pattern_from_code('min'), $self_obj->get_locale_display_pattern_from_code_fast('min'), 'get_locale_display_pattern_from_code[_fast] same result for min' );
is( $self_obj->get_character_orientation_from_code('min'),  $self_obj->get_character_orientation_from_code('min'),       'get_character_orientation_from_code[_fast] same result for min' );

is( $self_obj->get_locale_display_pattern_from_code('mis'), $self_obj->get_locale_display_pattern_from_code_fast('mis'), 'get_locale_display_pattern_from_code[_fast] same result for mis' );
is( $self_obj->get_character_orientation_from_code('mis'),  $self_obj->get_character_orientation_from_code('mis'),       'get_character_orientation_from_code[_fast] same result for mis' );

is( $self_obj->get_locale_display_pattern_from_code('mk'), $self_obj->get_locale_display_pattern_from_code_fast('mk'), 'get_locale_display_pattern_from_code[_fast] same result for mk' );
is( $self_obj->get_character_orientation_from_code('mk'),  $self_obj->get_character_orientation_from_code('mk'),       'get_character_orientation_from_code[_fast] same result for mk' );

is( $self_obj->get_locale_display_pattern_from_code('mkh'), $self_obj->get_locale_display_pattern_from_code_fast('mkh'), 'get_locale_display_pattern_from_code[_fast] same result for mkh' );
is( $self_obj->get_character_orientation_from_code('mkh'),  $self_obj->get_character_orientation_from_code('mkh'),       'get_character_orientation_from_code[_fast] same result for mkh' );

is( $self_obj->get_locale_display_pattern_from_code('ml'), $self_obj->get_locale_display_pattern_from_code_fast('ml'), 'get_locale_display_pattern_from_code[_fast] same result for ml' );
is( $self_obj->get_character_orientation_from_code('ml'),  $self_obj->get_character_orientation_from_code('ml'),       'get_character_orientation_from_code[_fast] same result for ml' );

is( $self_obj->get_locale_display_pattern_from_code('mn'), $self_obj->get_locale_display_pattern_from_code_fast('mn'), 'get_locale_display_pattern_from_code[_fast] same result for mn' );
is( $self_obj->get_character_orientation_from_code('mn'),  $self_obj->get_character_orientation_from_code('mn'),       'get_character_orientation_from_code[_fast] same result for mn' );

is( $self_obj->get_locale_display_pattern_from_code('mnc'), $self_obj->get_locale_display_pattern_from_code_fast('mnc'), 'get_locale_display_pattern_from_code[_fast] same result for mnc' );
is( $self_obj->get_character_orientation_from_code('mnc'),  $self_obj->get_character_orientation_from_code('mnc'),       'get_character_orientation_from_code[_fast] same result for mnc' );

is( $self_obj->get_locale_display_pattern_from_code('mni'), $self_obj->get_locale_display_pattern_from_code_fast('mni'), 'get_locale_display_pattern_from_code[_fast] same result for mni' );
is( $self_obj->get_character_orientation_from_code('mni'),  $self_obj->get_character_orientation_from_code('mni'),       'get_character_orientation_from_code[_fast] same result for mni' );

is( $self_obj->get_locale_display_pattern_from_code('mno'), $self_obj->get_locale_display_pattern_from_code_fast('mno'), 'get_locale_display_pattern_from_code[_fast] same result for mno' );
is( $self_obj->get_character_orientation_from_code('mno'),  $self_obj->get_character_orientation_from_code('mno'),       'get_character_orientation_from_code[_fast] same result for mno' );

is( $self_obj->get_locale_display_pattern_from_code('mo'), $self_obj->get_locale_display_pattern_from_code_fast('mo'), 'get_locale_display_pattern_from_code[_fast] same result for mo' );
is( $self_obj->get_character_orientation_from_code('mo'),  $self_obj->get_character_orientation_from_code('mo'),       'get_character_orientation_from_code[_fast] same result for mo' );

is( $self_obj->get_locale_display_pattern_from_code('moh'), $self_obj->get_locale_display_pattern_from_code_fast('moh'), 'get_locale_display_pattern_from_code[_fast] same result for moh' );
is( $self_obj->get_character_orientation_from_code('moh'),  $self_obj->get_character_orientation_from_code('moh'),       'get_character_orientation_from_code[_fast] same result for moh' );

is( $self_obj->get_locale_display_pattern_from_code('mos'), $self_obj->get_locale_display_pattern_from_code_fast('mos'), 'get_locale_display_pattern_from_code[_fast] same result for mos' );
is( $self_obj->get_character_orientation_from_code('mos'),  $self_obj->get_character_orientation_from_code('mos'),       'get_character_orientation_from_code[_fast] same result for mos' );

is( $self_obj->get_locale_display_pattern_from_code('mr'), $self_obj->get_locale_display_pattern_from_code_fast('mr'), 'get_locale_display_pattern_from_code[_fast] same result for mr' );
is( $self_obj->get_character_orientation_from_code('mr'),  $self_obj->get_character_orientation_from_code('mr'),       'get_character_orientation_from_code[_fast] same result for mr' );

is( $self_obj->get_locale_display_pattern_from_code('ms'), $self_obj->get_locale_display_pattern_from_code_fast('ms'), 'get_locale_display_pattern_from_code[_fast] same result for ms' );
is( $self_obj->get_character_orientation_from_code('ms'),  $self_obj->get_character_orientation_from_code('ms'),       'get_character_orientation_from_code[_fast] same result for ms' );

is( $self_obj->get_locale_display_pattern_from_code('mt'), $self_obj->get_locale_display_pattern_from_code_fast('mt'), 'get_locale_display_pattern_from_code[_fast] same result for mt' );
is( $self_obj->get_character_orientation_from_code('mt'),  $self_obj->get_character_orientation_from_code('mt'),       'get_character_orientation_from_code[_fast] same result for mt' );

is( $self_obj->get_locale_display_pattern_from_code('mua'), $self_obj->get_locale_display_pattern_from_code_fast('mua'), 'get_locale_display_pattern_from_code[_fast] same result for mua' );
is( $self_obj->get_character_orientation_from_code('mua'),  $self_obj->get_character_orientation_from_code('mua'),       'get_character_orientation_from_code[_fast] same result for mua' );

is( $self_obj->get_locale_display_pattern_from_code('mul'), $self_obj->get_locale_display_pattern_from_code_fast('mul'), 'get_locale_display_pattern_from_code[_fast] same result for mul' );
is( $self_obj->get_character_orientation_from_code('mul'),  $self_obj->get_character_orientation_from_code('mul'),       'get_character_orientation_from_code[_fast] same result for mul' );

is( $self_obj->get_locale_display_pattern_from_code('mun'), $self_obj->get_locale_display_pattern_from_code_fast('mun'), 'get_locale_display_pattern_from_code[_fast] same result for mun' );
is( $self_obj->get_character_orientation_from_code('mun'),  $self_obj->get_character_orientation_from_code('mun'),       'get_character_orientation_from_code[_fast] same result for mun' );

is( $self_obj->get_locale_display_pattern_from_code('mus'), $self_obj->get_locale_display_pattern_from_code_fast('mus'), 'get_locale_display_pattern_from_code[_fast] same result for mus' );
is( $self_obj->get_character_orientation_from_code('mus'),  $self_obj->get_character_orientation_from_code('mus'),       'get_character_orientation_from_code[_fast] same result for mus' );

is( $self_obj->get_locale_display_pattern_from_code('mwl'), $self_obj->get_locale_display_pattern_from_code_fast('mwl'), 'get_locale_display_pattern_from_code[_fast] same result for mwl' );
is( $self_obj->get_character_orientation_from_code('mwl'),  $self_obj->get_character_orientation_from_code('mwl'),       'get_character_orientation_from_code[_fast] same result for mwl' );

is( $self_obj->get_locale_display_pattern_from_code('mwr'), $self_obj->get_locale_display_pattern_from_code_fast('mwr'), 'get_locale_display_pattern_from_code[_fast] same result for mwr' );
is( $self_obj->get_character_orientation_from_code('mwr'),  $self_obj->get_character_orientation_from_code('mwr'),       'get_character_orientation_from_code[_fast] same result for mwr' );

is( $self_obj->get_locale_display_pattern_from_code('my'), $self_obj->get_locale_display_pattern_from_code_fast('my'), 'get_locale_display_pattern_from_code[_fast] same result for my' );
is( $self_obj->get_character_orientation_from_code('my'),  $self_obj->get_character_orientation_from_code('my'),       'get_character_orientation_from_code[_fast] same result for my' );

is( $self_obj->get_locale_display_pattern_from_code('myn'), $self_obj->get_locale_display_pattern_from_code_fast('myn'), 'get_locale_display_pattern_from_code[_fast] same result for myn' );
is( $self_obj->get_character_orientation_from_code('myn'),  $self_obj->get_character_orientation_from_code('myn'),       'get_character_orientation_from_code[_fast] same result for myn' );

is( $self_obj->get_locale_display_pattern_from_code('myv'), $self_obj->get_locale_display_pattern_from_code_fast('myv'), 'get_locale_display_pattern_from_code[_fast] same result for myv' );
is( $self_obj->get_character_orientation_from_code('myv'),  $self_obj->get_character_orientation_from_code('myv'),       'get_character_orientation_from_code[_fast] same result for myv' );

is( $self_obj->get_locale_display_pattern_from_code('na'), $self_obj->get_locale_display_pattern_from_code_fast('na'), 'get_locale_display_pattern_from_code[_fast] same result for na' );
is( $self_obj->get_character_orientation_from_code('na'),  $self_obj->get_character_orientation_from_code('na'),       'get_character_orientation_from_code[_fast] same result for na' );

is( $self_obj->get_locale_display_pattern_from_code('nah'), $self_obj->get_locale_display_pattern_from_code_fast('nah'), 'get_locale_display_pattern_from_code[_fast] same result for nah' );
is( $self_obj->get_character_orientation_from_code('nah'),  $self_obj->get_character_orientation_from_code('nah'),       'get_character_orientation_from_code[_fast] same result for nah' );

is( $self_obj->get_locale_display_pattern_from_code('nai'), $self_obj->get_locale_display_pattern_from_code_fast('nai'), 'get_locale_display_pattern_from_code[_fast] same result for nai' );
is( $self_obj->get_character_orientation_from_code('nai'),  $self_obj->get_character_orientation_from_code('nai'),       'get_character_orientation_from_code[_fast] same result for nai' );

is( $self_obj->get_locale_display_pattern_from_code('nap'), $self_obj->get_locale_display_pattern_from_code_fast('nap'), 'get_locale_display_pattern_from_code[_fast] same result for nap' );
is( $self_obj->get_character_orientation_from_code('nap'),  $self_obj->get_character_orientation_from_code('nap'),       'get_character_orientation_from_code[_fast] same result for nap' );

is( $self_obj->get_locale_display_pattern_from_code('naq'), $self_obj->get_locale_display_pattern_from_code_fast('naq'), 'get_locale_display_pattern_from_code[_fast] same result for naq' );
is( $self_obj->get_character_orientation_from_code('naq'),  $self_obj->get_character_orientation_from_code('naq'),       'get_character_orientation_from_code[_fast] same result for naq' );

is( $self_obj->get_locale_display_pattern_from_code('nb'), $self_obj->get_locale_display_pattern_from_code_fast('nb'), 'get_locale_display_pattern_from_code[_fast] same result for nb' );
is( $self_obj->get_character_orientation_from_code('nb'),  $self_obj->get_character_orientation_from_code('nb'),       'get_character_orientation_from_code[_fast] same result for nb' );

is( $self_obj->get_locale_display_pattern_from_code('nd'), $self_obj->get_locale_display_pattern_from_code_fast('nd'), 'get_locale_display_pattern_from_code[_fast] same result for nd' );
is( $self_obj->get_character_orientation_from_code('nd'),  $self_obj->get_character_orientation_from_code('nd'),       'get_character_orientation_from_code[_fast] same result for nd' );

is( $self_obj->get_locale_display_pattern_from_code('nds'), $self_obj->get_locale_display_pattern_from_code_fast('nds'), 'get_locale_display_pattern_from_code[_fast] same result for nds' );
is( $self_obj->get_character_orientation_from_code('nds'),  $self_obj->get_character_orientation_from_code('nds'),       'get_character_orientation_from_code[_fast] same result for nds' );

is( $self_obj->get_locale_display_pattern_from_code('ne'), $self_obj->get_locale_display_pattern_from_code_fast('ne'), 'get_locale_display_pattern_from_code[_fast] same result for ne' );
is( $self_obj->get_character_orientation_from_code('ne'),  $self_obj->get_character_orientation_from_code('ne'),       'get_character_orientation_from_code[_fast] same result for ne' );

is( $self_obj->get_locale_display_pattern_from_code('new'), $self_obj->get_locale_display_pattern_from_code_fast('new'), 'get_locale_display_pattern_from_code[_fast] same result for new' );
is( $self_obj->get_character_orientation_from_code('new'),  $self_obj->get_character_orientation_from_code('new'),       'get_character_orientation_from_code[_fast] same result for new' );

is( $self_obj->get_locale_display_pattern_from_code('ng'), $self_obj->get_locale_display_pattern_from_code_fast('ng'), 'get_locale_display_pattern_from_code[_fast] same result for ng' );
is( $self_obj->get_character_orientation_from_code('ng'),  $self_obj->get_character_orientation_from_code('ng'),       'get_character_orientation_from_code[_fast] same result for ng' );

is( $self_obj->get_locale_display_pattern_from_code('nia'), $self_obj->get_locale_display_pattern_from_code_fast('nia'), 'get_locale_display_pattern_from_code[_fast] same result for nia' );
is( $self_obj->get_character_orientation_from_code('nia'),  $self_obj->get_character_orientation_from_code('nia'),       'get_character_orientation_from_code[_fast] same result for nia' );

is( $self_obj->get_locale_display_pattern_from_code('nic'), $self_obj->get_locale_display_pattern_from_code_fast('nic'), 'get_locale_display_pattern_from_code[_fast] same result for nic' );
is( $self_obj->get_character_orientation_from_code('nic'),  $self_obj->get_character_orientation_from_code('nic'),       'get_character_orientation_from_code[_fast] same result for nic' );

is( $self_obj->get_locale_display_pattern_from_code('niu'), $self_obj->get_locale_display_pattern_from_code_fast('niu'), 'get_locale_display_pattern_from_code[_fast] same result for niu' );
is( $self_obj->get_character_orientation_from_code('niu'),  $self_obj->get_character_orientation_from_code('niu'),       'get_character_orientation_from_code[_fast] same result for niu' );

is( $self_obj->get_locale_display_pattern_from_code('nl'), $self_obj->get_locale_display_pattern_from_code_fast('nl'), 'get_locale_display_pattern_from_code[_fast] same result for nl' );
is( $self_obj->get_character_orientation_from_code('nl'),  $self_obj->get_character_orientation_from_code('nl'),       'get_character_orientation_from_code[_fast] same result for nl' );

is( $self_obj->get_locale_display_pattern_from_code('nl_be'), $self_obj->get_locale_display_pattern_from_code_fast('nl_be'), 'get_locale_display_pattern_from_code[_fast] same result for nl_be' );
is( $self_obj->get_character_orientation_from_code('nl_be'),  $self_obj->get_character_orientation_from_code('nl_be'),       'get_character_orientation_from_code[_fast] same result for nl_be' );

is( $self_obj->get_locale_display_pattern_from_code('nmg'), $self_obj->get_locale_display_pattern_from_code_fast('nmg'), 'get_locale_display_pattern_from_code[_fast] same result for nmg' );
is( $self_obj->get_character_orientation_from_code('nmg'),  $self_obj->get_character_orientation_from_code('nmg'),       'get_character_orientation_from_code[_fast] same result for nmg' );

is( $self_obj->get_locale_display_pattern_from_code('nn'), $self_obj->get_locale_display_pattern_from_code_fast('nn'), 'get_locale_display_pattern_from_code[_fast] same result for nn' );
is( $self_obj->get_character_orientation_from_code('nn'),  $self_obj->get_character_orientation_from_code('nn'),       'get_character_orientation_from_code[_fast] same result for nn' );

is( $self_obj->get_locale_display_pattern_from_code('no'), $self_obj->get_locale_display_pattern_from_code_fast('no'), 'get_locale_display_pattern_from_code[_fast] same result for no' );
is( $self_obj->get_character_orientation_from_code('no'),  $self_obj->get_character_orientation_from_code('no'),       'get_character_orientation_from_code[_fast] same result for no' );

is( $self_obj->get_locale_display_pattern_from_code('nog'), $self_obj->get_locale_display_pattern_from_code_fast('nog'), 'get_locale_display_pattern_from_code[_fast] same result for nog' );
is( $self_obj->get_character_orientation_from_code('nog'),  $self_obj->get_character_orientation_from_code('nog'),       'get_character_orientation_from_code[_fast] same result for nog' );

is( $self_obj->get_locale_display_pattern_from_code('non'), $self_obj->get_locale_display_pattern_from_code_fast('non'), 'get_locale_display_pattern_from_code[_fast] same result for non' );
is( $self_obj->get_character_orientation_from_code('non'),  $self_obj->get_character_orientation_from_code('non'),       'get_character_orientation_from_code[_fast] same result for non' );

is( $self_obj->get_locale_display_pattern_from_code('nqo'), $self_obj->get_locale_display_pattern_from_code_fast('nqo'), 'get_locale_display_pattern_from_code[_fast] same result for nqo' );
is( $self_obj->get_character_orientation_from_code('nqo'),  $self_obj->get_character_orientation_from_code('nqo'),       'get_character_orientation_from_code[_fast] same result for nqo' );

is( $self_obj->get_locale_display_pattern_from_code('nr'), $self_obj->get_locale_display_pattern_from_code_fast('nr'), 'get_locale_display_pattern_from_code[_fast] same result for nr' );
is( $self_obj->get_character_orientation_from_code('nr'),  $self_obj->get_character_orientation_from_code('nr'),       'get_character_orientation_from_code[_fast] same result for nr' );

is( $self_obj->get_locale_display_pattern_from_code('nso'), $self_obj->get_locale_display_pattern_from_code_fast('nso'), 'get_locale_display_pattern_from_code[_fast] same result for nso' );
is( $self_obj->get_character_orientation_from_code('nso'),  $self_obj->get_character_orientation_from_code('nso'),       'get_character_orientation_from_code[_fast] same result for nso' );

is( $self_obj->get_locale_display_pattern_from_code('nub'), $self_obj->get_locale_display_pattern_from_code_fast('nub'), 'get_locale_display_pattern_from_code[_fast] same result for nub' );
is( $self_obj->get_character_orientation_from_code('nub'),  $self_obj->get_character_orientation_from_code('nub'),       'get_character_orientation_from_code[_fast] same result for nub' );

is( $self_obj->get_locale_display_pattern_from_code('nus'), $self_obj->get_locale_display_pattern_from_code_fast('nus'), 'get_locale_display_pattern_from_code[_fast] same result for nus' );
is( $self_obj->get_character_orientation_from_code('nus'),  $self_obj->get_character_orientation_from_code('nus'),       'get_character_orientation_from_code[_fast] same result for nus' );

is( $self_obj->get_locale_display_pattern_from_code('nv'), $self_obj->get_locale_display_pattern_from_code_fast('nv'), 'get_locale_display_pattern_from_code[_fast] same result for nv' );
is( $self_obj->get_character_orientation_from_code('nv'),  $self_obj->get_character_orientation_from_code('nv'),       'get_character_orientation_from_code[_fast] same result for nv' );

is( $self_obj->get_locale_display_pattern_from_code('nwc'), $self_obj->get_locale_display_pattern_from_code_fast('nwc'), 'get_locale_display_pattern_from_code[_fast] same result for nwc' );
is( $self_obj->get_character_orientation_from_code('nwc'),  $self_obj->get_character_orientation_from_code('nwc'),       'get_character_orientation_from_code[_fast] same result for nwc' );

is( $self_obj->get_locale_display_pattern_from_code('ny'), $self_obj->get_locale_display_pattern_from_code_fast('ny'), 'get_locale_display_pattern_from_code[_fast] same result for ny' );
is( $self_obj->get_character_orientation_from_code('ny'),  $self_obj->get_character_orientation_from_code('ny'),       'get_character_orientation_from_code[_fast] same result for ny' );

is( $self_obj->get_locale_display_pattern_from_code('nym'), $self_obj->get_locale_display_pattern_from_code_fast('nym'), 'get_locale_display_pattern_from_code[_fast] same result for nym' );
is( $self_obj->get_character_orientation_from_code('nym'),  $self_obj->get_character_orientation_from_code('nym'),       'get_character_orientation_from_code[_fast] same result for nym' );

is( $self_obj->get_locale_display_pattern_from_code('nyn'), $self_obj->get_locale_display_pattern_from_code_fast('nyn'), 'get_locale_display_pattern_from_code[_fast] same result for nyn' );
is( $self_obj->get_character_orientation_from_code('nyn'),  $self_obj->get_character_orientation_from_code('nyn'),       'get_character_orientation_from_code[_fast] same result for nyn' );

is( $self_obj->get_locale_display_pattern_from_code('nyo'), $self_obj->get_locale_display_pattern_from_code_fast('nyo'), 'get_locale_display_pattern_from_code[_fast] same result for nyo' );
is( $self_obj->get_character_orientation_from_code('nyo'),  $self_obj->get_character_orientation_from_code('nyo'),       'get_character_orientation_from_code[_fast] same result for nyo' );

is( $self_obj->get_locale_display_pattern_from_code('nzi'), $self_obj->get_locale_display_pattern_from_code_fast('nzi'), 'get_locale_display_pattern_from_code[_fast] same result for nzi' );
is( $self_obj->get_character_orientation_from_code('nzi'),  $self_obj->get_character_orientation_from_code('nzi'),       'get_character_orientation_from_code[_fast] same result for nzi' );

is( $self_obj->get_locale_display_pattern_from_code('oc'), $self_obj->get_locale_display_pattern_from_code_fast('oc'), 'get_locale_display_pattern_from_code[_fast] same result for oc' );
is( $self_obj->get_character_orientation_from_code('oc'),  $self_obj->get_character_orientation_from_code('oc'),       'get_character_orientation_from_code[_fast] same result for oc' );

is( $self_obj->get_locale_display_pattern_from_code('oj'), $self_obj->get_locale_display_pattern_from_code_fast('oj'), 'get_locale_display_pattern_from_code[_fast] same result for oj' );
is( $self_obj->get_character_orientation_from_code('oj'),  $self_obj->get_character_orientation_from_code('oj'),       'get_character_orientation_from_code[_fast] same result for oj' );

is( $self_obj->get_locale_display_pattern_from_code('om'), $self_obj->get_locale_display_pattern_from_code_fast('om'), 'get_locale_display_pattern_from_code[_fast] same result for om' );
is( $self_obj->get_character_orientation_from_code('om'),  $self_obj->get_character_orientation_from_code('om'),       'get_character_orientation_from_code[_fast] same result for om' );

is( $self_obj->get_locale_display_pattern_from_code('or'), $self_obj->get_locale_display_pattern_from_code_fast('or'), 'get_locale_display_pattern_from_code[_fast] same result for or' );
is( $self_obj->get_character_orientation_from_code('or'),  $self_obj->get_character_orientation_from_code('or'),       'get_character_orientation_from_code[_fast] same result for or' );

is( $self_obj->get_locale_display_pattern_from_code('os'), $self_obj->get_locale_display_pattern_from_code_fast('os'), 'get_locale_display_pattern_from_code[_fast] same result for os' );
is( $self_obj->get_character_orientation_from_code('os'),  $self_obj->get_character_orientation_from_code('os'),       'get_character_orientation_from_code[_fast] same result for os' );

is( $self_obj->get_locale_display_pattern_from_code('osa'), $self_obj->get_locale_display_pattern_from_code_fast('osa'), 'get_locale_display_pattern_from_code[_fast] same result for osa' );
is( $self_obj->get_character_orientation_from_code('osa'),  $self_obj->get_character_orientation_from_code('osa'),       'get_character_orientation_from_code[_fast] same result for osa' );

is( $self_obj->get_locale_display_pattern_from_code('ota'), $self_obj->get_locale_display_pattern_from_code_fast('ota'), 'get_locale_display_pattern_from_code[_fast] same result for ota' );
is( $self_obj->get_character_orientation_from_code('ota'),  $self_obj->get_character_orientation_from_code('ota'),       'get_character_orientation_from_code[_fast] same result for ota' );

is( $self_obj->get_locale_display_pattern_from_code('oto'), $self_obj->get_locale_display_pattern_from_code_fast('oto'), 'get_locale_display_pattern_from_code[_fast] same result for oto' );
is( $self_obj->get_character_orientation_from_code('oto'),  $self_obj->get_character_orientation_from_code('oto'),       'get_character_orientation_from_code[_fast] same result for oto' );

is( $self_obj->get_locale_display_pattern_from_code('pa'), $self_obj->get_locale_display_pattern_from_code_fast('pa'), 'get_locale_display_pattern_from_code[_fast] same result for pa' );
is( $self_obj->get_character_orientation_from_code('pa'),  $self_obj->get_character_orientation_from_code('pa'),       'get_character_orientation_from_code[_fast] same result for pa' );

is( $self_obj->get_locale_display_pattern_from_code('paa'), $self_obj->get_locale_display_pattern_from_code_fast('paa'), 'get_locale_display_pattern_from_code[_fast] same result for paa' );
is( $self_obj->get_character_orientation_from_code('paa'),  $self_obj->get_character_orientation_from_code('paa'),       'get_character_orientation_from_code[_fast] same result for paa' );

is( $self_obj->get_locale_display_pattern_from_code('pag'), $self_obj->get_locale_display_pattern_from_code_fast('pag'), 'get_locale_display_pattern_from_code[_fast] same result for pag' );
is( $self_obj->get_character_orientation_from_code('pag'),  $self_obj->get_character_orientation_from_code('pag'),       'get_character_orientation_from_code[_fast] same result for pag' );

is( $self_obj->get_locale_display_pattern_from_code('pal'), $self_obj->get_locale_display_pattern_from_code_fast('pal'), 'get_locale_display_pattern_from_code[_fast] same result for pal' );
is( $self_obj->get_character_orientation_from_code('pal'),  $self_obj->get_character_orientation_from_code('pal'),       'get_character_orientation_from_code[_fast] same result for pal' );

is( $self_obj->get_locale_display_pattern_from_code('pam'), $self_obj->get_locale_display_pattern_from_code_fast('pam'), 'get_locale_display_pattern_from_code[_fast] same result for pam' );
is( $self_obj->get_character_orientation_from_code('pam'),  $self_obj->get_character_orientation_from_code('pam'),       'get_character_orientation_from_code[_fast] same result for pam' );

is( $self_obj->get_locale_display_pattern_from_code('pap'), $self_obj->get_locale_display_pattern_from_code_fast('pap'), 'get_locale_display_pattern_from_code[_fast] same result for pap' );
is( $self_obj->get_character_orientation_from_code('pap'),  $self_obj->get_character_orientation_from_code('pap'),       'get_character_orientation_from_code[_fast] same result for pap' );

is( $self_obj->get_locale_display_pattern_from_code('pau'), $self_obj->get_locale_display_pattern_from_code_fast('pau'), 'get_locale_display_pattern_from_code[_fast] same result for pau' );
is( $self_obj->get_character_orientation_from_code('pau'),  $self_obj->get_character_orientation_from_code('pau'),       'get_character_orientation_from_code[_fast] same result for pau' );

is( $self_obj->get_locale_display_pattern_from_code('peo'), $self_obj->get_locale_display_pattern_from_code_fast('peo'), 'get_locale_display_pattern_from_code[_fast] same result for peo' );
is( $self_obj->get_character_orientation_from_code('peo'),  $self_obj->get_character_orientation_from_code('peo'),       'get_character_orientation_from_code[_fast] same result for peo' );

is( $self_obj->get_locale_display_pattern_from_code('phi'), $self_obj->get_locale_display_pattern_from_code_fast('phi'), 'get_locale_display_pattern_from_code[_fast] same result for phi' );
is( $self_obj->get_character_orientation_from_code('phi'),  $self_obj->get_character_orientation_from_code('phi'),       'get_character_orientation_from_code[_fast] same result for phi' );

is( $self_obj->get_locale_display_pattern_from_code('phn'), $self_obj->get_locale_display_pattern_from_code_fast('phn'), 'get_locale_display_pattern_from_code[_fast] same result for phn' );
is( $self_obj->get_character_orientation_from_code('phn'),  $self_obj->get_character_orientation_from_code('phn'),       'get_character_orientation_from_code[_fast] same result for phn' );

is( $self_obj->get_locale_display_pattern_from_code('pi'), $self_obj->get_locale_display_pattern_from_code_fast('pi'), 'get_locale_display_pattern_from_code[_fast] same result for pi' );
is( $self_obj->get_character_orientation_from_code('pi'),  $self_obj->get_character_orientation_from_code('pi'),       'get_character_orientation_from_code[_fast] same result for pi' );

is( $self_obj->get_locale_display_pattern_from_code('pl'), $self_obj->get_locale_display_pattern_from_code_fast('pl'), 'get_locale_display_pattern_from_code[_fast] same result for pl' );
is( $self_obj->get_character_orientation_from_code('pl'),  $self_obj->get_character_orientation_from_code('pl'),       'get_character_orientation_from_code[_fast] same result for pl' );

is( $self_obj->get_locale_display_pattern_from_code('pon'), $self_obj->get_locale_display_pattern_from_code_fast('pon'), 'get_locale_display_pattern_from_code[_fast] same result for pon' );
is( $self_obj->get_character_orientation_from_code('pon'),  $self_obj->get_character_orientation_from_code('pon'),       'get_character_orientation_from_code[_fast] same result for pon' );

is( $self_obj->get_locale_display_pattern_from_code('pra'), $self_obj->get_locale_display_pattern_from_code_fast('pra'), 'get_locale_display_pattern_from_code[_fast] same result for pra' );
is( $self_obj->get_character_orientation_from_code('pra'),  $self_obj->get_character_orientation_from_code('pra'),       'get_character_orientation_from_code[_fast] same result for pra' );

is( $self_obj->get_locale_display_pattern_from_code('pro'), $self_obj->get_locale_display_pattern_from_code_fast('pro'), 'get_locale_display_pattern_from_code[_fast] same result for pro' );
is( $self_obj->get_character_orientation_from_code('pro'),  $self_obj->get_character_orientation_from_code('pro'),       'get_character_orientation_from_code[_fast] same result for pro' );

is( $self_obj->get_locale_display_pattern_from_code('ps'), $self_obj->get_locale_display_pattern_from_code_fast('ps'), 'get_locale_display_pattern_from_code[_fast] same result for ps' );
is( $self_obj->get_character_orientation_from_code('ps'),  $self_obj->get_character_orientation_from_code('ps'),       'get_character_orientation_from_code[_fast] same result for ps' );

is( $self_obj->get_locale_display_pattern_from_code('pt'), $self_obj->get_locale_display_pattern_from_code_fast('pt'), 'get_locale_display_pattern_from_code[_fast] same result for pt' );
is( $self_obj->get_character_orientation_from_code('pt'),  $self_obj->get_character_orientation_from_code('pt'),       'get_character_orientation_from_code[_fast] same result for pt' );

is( $self_obj->get_locale_display_pattern_from_code('pt_br'), $self_obj->get_locale_display_pattern_from_code_fast('pt_br'), 'get_locale_display_pattern_from_code[_fast] same result for pt_br' );
is( $self_obj->get_character_orientation_from_code('pt_br'),  $self_obj->get_character_orientation_from_code('pt_br'),       'get_character_orientation_from_code[_fast] same result for pt_br' );

is( $self_obj->get_locale_display_pattern_from_code('pt_pt'), $self_obj->get_locale_display_pattern_from_code_fast('pt_pt'), 'get_locale_display_pattern_from_code[_fast] same result for pt_pt' );
is( $self_obj->get_character_orientation_from_code('pt_pt'),  $self_obj->get_character_orientation_from_code('pt_pt'),       'get_character_orientation_from_code[_fast] same result for pt_pt' );

is( $self_obj->get_locale_display_pattern_from_code('qu'), $self_obj->get_locale_display_pattern_from_code_fast('qu'), 'get_locale_display_pattern_from_code[_fast] same result for qu' );
is( $self_obj->get_character_orientation_from_code('qu'),  $self_obj->get_character_orientation_from_code('qu'),       'get_character_orientation_from_code[_fast] same result for qu' );

is( $self_obj->get_locale_display_pattern_from_code('raj'), $self_obj->get_locale_display_pattern_from_code_fast('raj'), 'get_locale_display_pattern_from_code[_fast] same result for raj' );
is( $self_obj->get_character_orientation_from_code('raj'),  $self_obj->get_character_orientation_from_code('raj'),       'get_character_orientation_from_code[_fast] same result for raj' );

is( $self_obj->get_locale_display_pattern_from_code('rap'), $self_obj->get_locale_display_pattern_from_code_fast('rap'), 'get_locale_display_pattern_from_code[_fast] same result for rap' );
is( $self_obj->get_character_orientation_from_code('rap'),  $self_obj->get_character_orientation_from_code('rap'),       'get_character_orientation_from_code[_fast] same result for rap' );

is( $self_obj->get_locale_display_pattern_from_code('rar'), $self_obj->get_locale_display_pattern_from_code_fast('rar'), 'get_locale_display_pattern_from_code[_fast] same result for rar' );
is( $self_obj->get_character_orientation_from_code('rar'),  $self_obj->get_character_orientation_from_code('rar'),       'get_character_orientation_from_code[_fast] same result for rar' );

is( $self_obj->get_locale_display_pattern_from_code('rm'), $self_obj->get_locale_display_pattern_from_code_fast('rm'), 'get_locale_display_pattern_from_code[_fast] same result for rm' );
is( $self_obj->get_character_orientation_from_code('rm'),  $self_obj->get_character_orientation_from_code('rm'),       'get_character_orientation_from_code[_fast] same result for rm' );

is( $self_obj->get_locale_display_pattern_from_code('rn'), $self_obj->get_locale_display_pattern_from_code_fast('rn'), 'get_locale_display_pattern_from_code[_fast] same result for rn' );
is( $self_obj->get_character_orientation_from_code('rn'),  $self_obj->get_character_orientation_from_code('rn'),       'get_character_orientation_from_code[_fast] same result for rn' );

is( $self_obj->get_locale_display_pattern_from_code('ro'), $self_obj->get_locale_display_pattern_from_code_fast('ro'), 'get_locale_display_pattern_from_code[_fast] same result for ro' );
is( $self_obj->get_character_orientation_from_code('ro'),  $self_obj->get_character_orientation_from_code('ro'),       'get_character_orientation_from_code[_fast] same result for ro' );

is( $self_obj->get_locale_display_pattern_from_code('roa'), $self_obj->get_locale_display_pattern_from_code_fast('roa'), 'get_locale_display_pattern_from_code[_fast] same result for roa' );
is( $self_obj->get_character_orientation_from_code('roa'),  $self_obj->get_character_orientation_from_code('roa'),       'get_character_orientation_from_code[_fast] same result for roa' );

is( $self_obj->get_locale_display_pattern_from_code('rof'), $self_obj->get_locale_display_pattern_from_code_fast('rof'), 'get_locale_display_pattern_from_code[_fast] same result for rof' );
is( $self_obj->get_character_orientation_from_code('rof'),  $self_obj->get_character_orientation_from_code('rof'),       'get_character_orientation_from_code[_fast] same result for rof' );

is( $self_obj->get_locale_display_pattern_from_code('rom'), $self_obj->get_locale_display_pattern_from_code_fast('rom'), 'get_locale_display_pattern_from_code[_fast] same result for rom' );
is( $self_obj->get_character_orientation_from_code('rom'),  $self_obj->get_character_orientation_from_code('rom'),       'get_character_orientation_from_code[_fast] same result for rom' );

is( $self_obj->get_locale_display_pattern_from_code('ru'), $self_obj->get_locale_display_pattern_from_code_fast('ru'), 'get_locale_display_pattern_from_code[_fast] same result for ru' );
is( $self_obj->get_character_orientation_from_code('ru'),  $self_obj->get_character_orientation_from_code('ru'),       'get_character_orientation_from_code[_fast] same result for ru' );

is( $self_obj->get_locale_display_pattern_from_code('rup'), $self_obj->get_locale_display_pattern_from_code_fast('rup'), 'get_locale_display_pattern_from_code[_fast] same result for rup' );
is( $self_obj->get_character_orientation_from_code('rup'),  $self_obj->get_character_orientation_from_code('rup'),       'get_character_orientation_from_code[_fast] same result for rup' );

is( $self_obj->get_locale_display_pattern_from_code('rw'), $self_obj->get_locale_display_pattern_from_code_fast('rw'), 'get_locale_display_pattern_from_code[_fast] same result for rw' );
is( $self_obj->get_character_orientation_from_code('rw'),  $self_obj->get_character_orientation_from_code('rw'),       'get_character_orientation_from_code[_fast] same result for rw' );

is( $self_obj->get_locale_display_pattern_from_code('rwk'), $self_obj->get_locale_display_pattern_from_code_fast('rwk'), 'get_locale_display_pattern_from_code[_fast] same result for rwk' );
is( $self_obj->get_character_orientation_from_code('rwk'),  $self_obj->get_character_orientation_from_code('rwk'),       'get_character_orientation_from_code[_fast] same result for rwk' );

is( $self_obj->get_locale_display_pattern_from_code('sa'), $self_obj->get_locale_display_pattern_from_code_fast('sa'), 'get_locale_display_pattern_from_code[_fast] same result for sa' );
is( $self_obj->get_character_orientation_from_code('sa'),  $self_obj->get_character_orientation_from_code('sa'),       'get_character_orientation_from_code[_fast] same result for sa' );

is( $self_obj->get_locale_display_pattern_from_code('sad'), $self_obj->get_locale_display_pattern_from_code_fast('sad'), 'get_locale_display_pattern_from_code[_fast] same result for sad' );
is( $self_obj->get_character_orientation_from_code('sad'),  $self_obj->get_character_orientation_from_code('sad'),       'get_character_orientation_from_code[_fast] same result for sad' );

is( $self_obj->get_locale_display_pattern_from_code('sah'), $self_obj->get_locale_display_pattern_from_code_fast('sah'), 'get_locale_display_pattern_from_code[_fast] same result for sah' );
is( $self_obj->get_character_orientation_from_code('sah'),  $self_obj->get_character_orientation_from_code('sah'),       'get_character_orientation_from_code[_fast] same result for sah' );

is( $self_obj->get_locale_display_pattern_from_code('sai'), $self_obj->get_locale_display_pattern_from_code_fast('sai'), 'get_locale_display_pattern_from_code[_fast] same result for sai' );
is( $self_obj->get_character_orientation_from_code('sai'),  $self_obj->get_character_orientation_from_code('sai'),       'get_character_orientation_from_code[_fast] same result for sai' );

is( $self_obj->get_locale_display_pattern_from_code('sal'), $self_obj->get_locale_display_pattern_from_code_fast('sal'), 'get_locale_display_pattern_from_code[_fast] same result for sal' );
is( $self_obj->get_character_orientation_from_code('sal'),  $self_obj->get_character_orientation_from_code('sal'),       'get_character_orientation_from_code[_fast] same result for sal' );

is( $self_obj->get_locale_display_pattern_from_code('sam'), $self_obj->get_locale_display_pattern_from_code_fast('sam'), 'get_locale_display_pattern_from_code[_fast] same result for sam' );
is( $self_obj->get_character_orientation_from_code('sam'),  $self_obj->get_character_orientation_from_code('sam'),       'get_character_orientation_from_code[_fast] same result for sam' );

is( $self_obj->get_locale_display_pattern_from_code('saq'), $self_obj->get_locale_display_pattern_from_code_fast('saq'), 'get_locale_display_pattern_from_code[_fast] same result for saq' );
is( $self_obj->get_character_orientation_from_code('saq'),  $self_obj->get_character_orientation_from_code('saq'),       'get_character_orientation_from_code[_fast] same result for saq' );

is( $self_obj->get_locale_display_pattern_from_code('sas'), $self_obj->get_locale_display_pattern_from_code_fast('sas'), 'get_locale_display_pattern_from_code[_fast] same result for sas' );
is( $self_obj->get_character_orientation_from_code('sas'),  $self_obj->get_character_orientation_from_code('sas'),       'get_character_orientation_from_code[_fast] same result for sas' );

is( $self_obj->get_locale_display_pattern_from_code('sat'), $self_obj->get_locale_display_pattern_from_code_fast('sat'), 'get_locale_display_pattern_from_code[_fast] same result for sat' );
is( $self_obj->get_character_orientation_from_code('sat'),  $self_obj->get_character_orientation_from_code('sat'),       'get_character_orientation_from_code[_fast] same result for sat' );

is( $self_obj->get_locale_display_pattern_from_code('sbp'), $self_obj->get_locale_display_pattern_from_code_fast('sbp'), 'get_locale_display_pattern_from_code[_fast] same result for sbp' );
is( $self_obj->get_character_orientation_from_code('sbp'),  $self_obj->get_character_orientation_from_code('sbp'),       'get_character_orientation_from_code[_fast] same result for sbp' );

is( $self_obj->get_locale_display_pattern_from_code('sc'), $self_obj->get_locale_display_pattern_from_code_fast('sc'), 'get_locale_display_pattern_from_code[_fast] same result for sc' );
is( $self_obj->get_character_orientation_from_code('sc'),  $self_obj->get_character_orientation_from_code('sc'),       'get_character_orientation_from_code[_fast] same result for sc' );

is( $self_obj->get_locale_display_pattern_from_code('scn'), $self_obj->get_locale_display_pattern_from_code_fast('scn'), 'get_locale_display_pattern_from_code[_fast] same result for scn' );
is( $self_obj->get_character_orientation_from_code('scn'),  $self_obj->get_character_orientation_from_code('scn'),       'get_character_orientation_from_code[_fast] same result for scn' );

is( $self_obj->get_locale_display_pattern_from_code('sco'), $self_obj->get_locale_display_pattern_from_code_fast('sco'), 'get_locale_display_pattern_from_code[_fast] same result for sco' );
is( $self_obj->get_character_orientation_from_code('sco'),  $self_obj->get_character_orientation_from_code('sco'),       'get_character_orientation_from_code[_fast] same result for sco' );

is( $self_obj->get_locale_display_pattern_from_code('sd'), $self_obj->get_locale_display_pattern_from_code_fast('sd'), 'get_locale_display_pattern_from_code[_fast] same result for sd' );
is( $self_obj->get_character_orientation_from_code('sd'),  $self_obj->get_character_orientation_from_code('sd'),       'get_character_orientation_from_code[_fast] same result for sd' );

is( $self_obj->get_locale_display_pattern_from_code('se'), $self_obj->get_locale_display_pattern_from_code_fast('se'), 'get_locale_display_pattern_from_code[_fast] same result for se' );
is( $self_obj->get_character_orientation_from_code('se'),  $self_obj->get_character_orientation_from_code('se'),       'get_character_orientation_from_code[_fast] same result for se' );

is( $self_obj->get_locale_display_pattern_from_code('see'), $self_obj->get_locale_display_pattern_from_code_fast('see'), 'get_locale_display_pattern_from_code[_fast] same result for see' );
is( $self_obj->get_character_orientation_from_code('see'),  $self_obj->get_character_orientation_from_code('see'),       'get_character_orientation_from_code[_fast] same result for see' );

is( $self_obj->get_locale_display_pattern_from_code('seh'), $self_obj->get_locale_display_pattern_from_code_fast('seh'), 'get_locale_display_pattern_from_code[_fast] same result for seh' );
is( $self_obj->get_character_orientation_from_code('seh'),  $self_obj->get_character_orientation_from_code('seh'),       'get_character_orientation_from_code[_fast] same result for seh' );

is( $self_obj->get_locale_display_pattern_from_code('sel'), $self_obj->get_locale_display_pattern_from_code_fast('sel'), 'get_locale_display_pattern_from_code[_fast] same result for sel' );
is( $self_obj->get_character_orientation_from_code('sel'),  $self_obj->get_character_orientation_from_code('sel'),       'get_character_orientation_from_code[_fast] same result for sel' );

is( $self_obj->get_locale_display_pattern_from_code('sem'), $self_obj->get_locale_display_pattern_from_code_fast('sem'), 'get_locale_display_pattern_from_code[_fast] same result for sem' );
is( $self_obj->get_character_orientation_from_code('sem'),  $self_obj->get_character_orientation_from_code('sem'),       'get_character_orientation_from_code[_fast] same result for sem' );

is( $self_obj->get_locale_display_pattern_from_code('ses'), $self_obj->get_locale_display_pattern_from_code_fast('ses'), 'get_locale_display_pattern_from_code[_fast] same result for ses' );
is( $self_obj->get_character_orientation_from_code('ses'),  $self_obj->get_character_orientation_from_code('ses'),       'get_character_orientation_from_code[_fast] same result for ses' );

is( $self_obj->get_locale_display_pattern_from_code('sg'), $self_obj->get_locale_display_pattern_from_code_fast('sg'), 'get_locale_display_pattern_from_code[_fast] same result for sg' );
is( $self_obj->get_character_orientation_from_code('sg'),  $self_obj->get_character_orientation_from_code('sg'),       'get_character_orientation_from_code[_fast] same result for sg' );

is( $self_obj->get_locale_display_pattern_from_code('sga'), $self_obj->get_locale_display_pattern_from_code_fast('sga'), 'get_locale_display_pattern_from_code[_fast] same result for sga' );
is( $self_obj->get_character_orientation_from_code('sga'),  $self_obj->get_character_orientation_from_code('sga'),       'get_character_orientation_from_code[_fast] same result for sga' );

is( $self_obj->get_locale_display_pattern_from_code('sgn'), $self_obj->get_locale_display_pattern_from_code_fast('sgn'), 'get_locale_display_pattern_from_code[_fast] same result for sgn' );
is( $self_obj->get_character_orientation_from_code('sgn'),  $self_obj->get_character_orientation_from_code('sgn'),       'get_character_orientation_from_code[_fast] same result for sgn' );

is( $self_obj->get_locale_display_pattern_from_code('sh'), $self_obj->get_locale_display_pattern_from_code_fast('sh'), 'get_locale_display_pattern_from_code[_fast] same result for sh' );
is( $self_obj->get_character_orientation_from_code('sh'),  $self_obj->get_character_orientation_from_code('sh'),       'get_character_orientation_from_code[_fast] same result for sh' );

is( $self_obj->get_locale_display_pattern_from_code('shi'), $self_obj->get_locale_display_pattern_from_code_fast('shi'), 'get_locale_display_pattern_from_code[_fast] same result for shi' );
is( $self_obj->get_character_orientation_from_code('shi'),  $self_obj->get_character_orientation_from_code('shi'),       'get_character_orientation_from_code[_fast] same result for shi' );

is( $self_obj->get_locale_display_pattern_from_code('shn'), $self_obj->get_locale_display_pattern_from_code_fast('shn'), 'get_locale_display_pattern_from_code[_fast] same result for shn' );
is( $self_obj->get_character_orientation_from_code('shn'),  $self_obj->get_character_orientation_from_code('shn'),       'get_character_orientation_from_code[_fast] same result for shn' );

is( $self_obj->get_locale_display_pattern_from_code('si'), $self_obj->get_locale_display_pattern_from_code_fast('si'), 'get_locale_display_pattern_from_code[_fast] same result for si' );
is( $self_obj->get_character_orientation_from_code('si'),  $self_obj->get_character_orientation_from_code('si'),       'get_character_orientation_from_code[_fast] same result for si' );

is( $self_obj->get_locale_display_pattern_from_code('sid'), $self_obj->get_locale_display_pattern_from_code_fast('sid'), 'get_locale_display_pattern_from_code[_fast] same result for sid' );
is( $self_obj->get_character_orientation_from_code('sid'),  $self_obj->get_character_orientation_from_code('sid'),       'get_character_orientation_from_code[_fast] same result for sid' );

is( $self_obj->get_locale_display_pattern_from_code('sio'), $self_obj->get_locale_display_pattern_from_code_fast('sio'), 'get_locale_display_pattern_from_code[_fast] same result for sio' );
is( $self_obj->get_character_orientation_from_code('sio'),  $self_obj->get_character_orientation_from_code('sio'),       'get_character_orientation_from_code[_fast] same result for sio' );

is( $self_obj->get_locale_display_pattern_from_code('sit'), $self_obj->get_locale_display_pattern_from_code_fast('sit'), 'get_locale_display_pattern_from_code[_fast] same result for sit' );
is( $self_obj->get_character_orientation_from_code('sit'),  $self_obj->get_character_orientation_from_code('sit'),       'get_character_orientation_from_code[_fast] same result for sit' );

is( $self_obj->get_locale_display_pattern_from_code('sk'), $self_obj->get_locale_display_pattern_from_code_fast('sk'), 'get_locale_display_pattern_from_code[_fast] same result for sk' );
is( $self_obj->get_character_orientation_from_code('sk'),  $self_obj->get_character_orientation_from_code('sk'),       'get_character_orientation_from_code[_fast] same result for sk' );

is( $self_obj->get_locale_display_pattern_from_code('sl'), $self_obj->get_locale_display_pattern_from_code_fast('sl'), 'get_locale_display_pattern_from_code[_fast] same result for sl' );
is( $self_obj->get_character_orientation_from_code('sl'),  $self_obj->get_character_orientation_from_code('sl'),       'get_character_orientation_from_code[_fast] same result for sl' );

is( $self_obj->get_locale_display_pattern_from_code('sla'), $self_obj->get_locale_display_pattern_from_code_fast('sla'), 'get_locale_display_pattern_from_code[_fast] same result for sla' );
is( $self_obj->get_character_orientation_from_code('sla'),  $self_obj->get_character_orientation_from_code('sla'),       'get_character_orientation_from_code[_fast] same result for sla' );

is( $self_obj->get_locale_display_pattern_from_code('sm'), $self_obj->get_locale_display_pattern_from_code_fast('sm'), 'get_locale_display_pattern_from_code[_fast] same result for sm' );
is( $self_obj->get_character_orientation_from_code('sm'),  $self_obj->get_character_orientation_from_code('sm'),       'get_character_orientation_from_code[_fast] same result for sm' );

is( $self_obj->get_locale_display_pattern_from_code('sma'), $self_obj->get_locale_display_pattern_from_code_fast('sma'), 'get_locale_display_pattern_from_code[_fast] same result for sma' );
is( $self_obj->get_character_orientation_from_code('sma'),  $self_obj->get_character_orientation_from_code('sma'),       'get_character_orientation_from_code[_fast] same result for sma' );

is( $self_obj->get_locale_display_pattern_from_code('smi'), $self_obj->get_locale_display_pattern_from_code_fast('smi'), 'get_locale_display_pattern_from_code[_fast] same result for smi' );
is( $self_obj->get_character_orientation_from_code('smi'),  $self_obj->get_character_orientation_from_code('smi'),       'get_character_orientation_from_code[_fast] same result for smi' );

is( $self_obj->get_locale_display_pattern_from_code('smj'), $self_obj->get_locale_display_pattern_from_code_fast('smj'), 'get_locale_display_pattern_from_code[_fast] same result for smj' );
is( $self_obj->get_character_orientation_from_code('smj'),  $self_obj->get_character_orientation_from_code('smj'),       'get_character_orientation_from_code[_fast] same result for smj' );

is( $self_obj->get_locale_display_pattern_from_code('smn'), $self_obj->get_locale_display_pattern_from_code_fast('smn'), 'get_locale_display_pattern_from_code[_fast] same result for smn' );
is( $self_obj->get_character_orientation_from_code('smn'),  $self_obj->get_character_orientation_from_code('smn'),       'get_character_orientation_from_code[_fast] same result for smn' );

is( $self_obj->get_locale_display_pattern_from_code('sms'), $self_obj->get_locale_display_pattern_from_code_fast('sms'), 'get_locale_display_pattern_from_code[_fast] same result for sms' );
is( $self_obj->get_character_orientation_from_code('sms'),  $self_obj->get_character_orientation_from_code('sms'),       'get_character_orientation_from_code[_fast] same result for sms' );

is( $self_obj->get_locale_display_pattern_from_code('sn'), $self_obj->get_locale_display_pattern_from_code_fast('sn'), 'get_locale_display_pattern_from_code[_fast] same result for sn' );
is( $self_obj->get_character_orientation_from_code('sn'),  $self_obj->get_character_orientation_from_code('sn'),       'get_character_orientation_from_code[_fast] same result for sn' );

is( $self_obj->get_locale_display_pattern_from_code('snk'), $self_obj->get_locale_display_pattern_from_code_fast('snk'), 'get_locale_display_pattern_from_code[_fast] same result for snk' );
is( $self_obj->get_character_orientation_from_code('snk'),  $self_obj->get_character_orientation_from_code('snk'),       'get_character_orientation_from_code[_fast] same result for snk' );

is( $self_obj->get_locale_display_pattern_from_code('so'), $self_obj->get_locale_display_pattern_from_code_fast('so'), 'get_locale_display_pattern_from_code[_fast] same result for so' );
is( $self_obj->get_character_orientation_from_code('so'),  $self_obj->get_character_orientation_from_code('so'),       'get_character_orientation_from_code[_fast] same result for so' );

is( $self_obj->get_locale_display_pattern_from_code('sog'), $self_obj->get_locale_display_pattern_from_code_fast('sog'), 'get_locale_display_pattern_from_code[_fast] same result for sog' );
is( $self_obj->get_character_orientation_from_code('sog'),  $self_obj->get_character_orientation_from_code('sog'),       'get_character_orientation_from_code[_fast] same result for sog' );

is( $self_obj->get_locale_display_pattern_from_code('son'), $self_obj->get_locale_display_pattern_from_code_fast('son'), 'get_locale_display_pattern_from_code[_fast] same result for son' );
is( $self_obj->get_character_orientation_from_code('son'),  $self_obj->get_character_orientation_from_code('son'),       'get_character_orientation_from_code[_fast] same result for son' );

is( $self_obj->get_locale_display_pattern_from_code('sq'), $self_obj->get_locale_display_pattern_from_code_fast('sq'), 'get_locale_display_pattern_from_code[_fast] same result for sq' );
is( $self_obj->get_character_orientation_from_code('sq'),  $self_obj->get_character_orientation_from_code('sq'),       'get_character_orientation_from_code[_fast] same result for sq' );

is( $self_obj->get_locale_display_pattern_from_code('sr'), $self_obj->get_locale_display_pattern_from_code_fast('sr'), 'get_locale_display_pattern_from_code[_fast] same result for sr' );
is( $self_obj->get_character_orientation_from_code('sr'),  $self_obj->get_character_orientation_from_code('sr'),       'get_character_orientation_from_code[_fast] same result for sr' );

is( $self_obj->get_locale_display_pattern_from_code('srn'), $self_obj->get_locale_display_pattern_from_code_fast('srn'), 'get_locale_display_pattern_from_code[_fast] same result for srn' );
is( $self_obj->get_character_orientation_from_code('srn'),  $self_obj->get_character_orientation_from_code('srn'),       'get_character_orientation_from_code[_fast] same result for srn' );

is( $self_obj->get_locale_display_pattern_from_code('srr'), $self_obj->get_locale_display_pattern_from_code_fast('srr'), 'get_locale_display_pattern_from_code[_fast] same result for srr' );
is( $self_obj->get_character_orientation_from_code('srr'),  $self_obj->get_character_orientation_from_code('srr'),       'get_character_orientation_from_code[_fast] same result for srr' );

is( $self_obj->get_locale_display_pattern_from_code('ss'), $self_obj->get_locale_display_pattern_from_code_fast('ss'), 'get_locale_display_pattern_from_code[_fast] same result for ss' );
is( $self_obj->get_character_orientation_from_code('ss'),  $self_obj->get_character_orientation_from_code('ss'),       'get_character_orientation_from_code[_fast] same result for ss' );

is( $self_obj->get_locale_display_pattern_from_code('ssa'), $self_obj->get_locale_display_pattern_from_code_fast('ssa'), 'get_locale_display_pattern_from_code[_fast] same result for ssa' );
is( $self_obj->get_character_orientation_from_code('ssa'),  $self_obj->get_character_orientation_from_code('ssa'),       'get_character_orientation_from_code[_fast] same result for ssa' );

is( $self_obj->get_locale_display_pattern_from_code('ssy'), $self_obj->get_locale_display_pattern_from_code_fast('ssy'), 'get_locale_display_pattern_from_code[_fast] same result for ssy' );
is( $self_obj->get_character_orientation_from_code('ssy'),  $self_obj->get_character_orientation_from_code('ssy'),       'get_character_orientation_from_code[_fast] same result for ssy' );

is( $self_obj->get_locale_display_pattern_from_code('st'), $self_obj->get_locale_display_pattern_from_code_fast('st'), 'get_locale_display_pattern_from_code[_fast] same result for st' );
is( $self_obj->get_character_orientation_from_code('st'),  $self_obj->get_character_orientation_from_code('st'),       'get_character_orientation_from_code[_fast] same result for st' );

is( $self_obj->get_locale_display_pattern_from_code('su'), $self_obj->get_locale_display_pattern_from_code_fast('su'), 'get_locale_display_pattern_from_code[_fast] same result for su' );
is( $self_obj->get_character_orientation_from_code('su'),  $self_obj->get_character_orientation_from_code('su'),       'get_character_orientation_from_code[_fast] same result for su' );

is( $self_obj->get_locale_display_pattern_from_code('suk'), $self_obj->get_locale_display_pattern_from_code_fast('suk'), 'get_locale_display_pattern_from_code[_fast] same result for suk' );
is( $self_obj->get_character_orientation_from_code('suk'),  $self_obj->get_character_orientation_from_code('suk'),       'get_character_orientation_from_code[_fast] same result for suk' );

is( $self_obj->get_locale_display_pattern_from_code('sus'), $self_obj->get_locale_display_pattern_from_code_fast('sus'), 'get_locale_display_pattern_from_code[_fast] same result for sus' );
is( $self_obj->get_character_orientation_from_code('sus'),  $self_obj->get_character_orientation_from_code('sus'),       'get_character_orientation_from_code[_fast] same result for sus' );

is( $self_obj->get_locale_display_pattern_from_code('sux'), $self_obj->get_locale_display_pattern_from_code_fast('sux'), 'get_locale_display_pattern_from_code[_fast] same result for sux' );
is( $self_obj->get_character_orientation_from_code('sux'),  $self_obj->get_character_orientation_from_code('sux'),       'get_character_orientation_from_code[_fast] same result for sux' );

is( $self_obj->get_locale_display_pattern_from_code('sv'), $self_obj->get_locale_display_pattern_from_code_fast('sv'), 'get_locale_display_pattern_from_code[_fast] same result for sv' );
is( $self_obj->get_character_orientation_from_code('sv'),  $self_obj->get_character_orientation_from_code('sv'),       'get_character_orientation_from_code[_fast] same result for sv' );

is( $self_obj->get_locale_display_pattern_from_code('sw'), $self_obj->get_locale_display_pattern_from_code_fast('sw'), 'get_locale_display_pattern_from_code[_fast] same result for sw' );
is( $self_obj->get_character_orientation_from_code('sw'),  $self_obj->get_character_orientation_from_code('sw'),       'get_character_orientation_from_code[_fast] same result for sw' );

is( $self_obj->get_locale_display_pattern_from_code('swb'), $self_obj->get_locale_display_pattern_from_code_fast('swb'), 'get_locale_display_pattern_from_code[_fast] same result for swb' );
is( $self_obj->get_character_orientation_from_code('swb'),  $self_obj->get_character_orientation_from_code('swb'),       'get_character_orientation_from_code[_fast] same result for swb' );

is( $self_obj->get_locale_display_pattern_from_code('swc'), $self_obj->get_locale_display_pattern_from_code_fast('swc'), 'get_locale_display_pattern_from_code[_fast] same result for swc' );
is( $self_obj->get_character_orientation_from_code('swc'),  $self_obj->get_character_orientation_from_code('swc'),       'get_character_orientation_from_code[_fast] same result for swc' );

is( $self_obj->get_locale_display_pattern_from_code('syc'), $self_obj->get_locale_display_pattern_from_code_fast('syc'), 'get_locale_display_pattern_from_code[_fast] same result for syc' );
is( $self_obj->get_character_orientation_from_code('syc'),  $self_obj->get_character_orientation_from_code('syc'),       'get_character_orientation_from_code[_fast] same result for syc' );

is( $self_obj->get_locale_display_pattern_from_code('syr'), $self_obj->get_locale_display_pattern_from_code_fast('syr'), 'get_locale_display_pattern_from_code[_fast] same result for syr' );
is( $self_obj->get_character_orientation_from_code('syr'),  $self_obj->get_character_orientation_from_code('syr'),       'get_character_orientation_from_code[_fast] same result for syr' );

is( $self_obj->get_locale_display_pattern_from_code('ta'), $self_obj->get_locale_display_pattern_from_code_fast('ta'), 'get_locale_display_pattern_from_code[_fast] same result for ta' );
is( $self_obj->get_character_orientation_from_code('ta'),  $self_obj->get_character_orientation_from_code('ta'),       'get_character_orientation_from_code[_fast] same result for ta' );

is( $self_obj->get_locale_display_pattern_from_code('tai'), $self_obj->get_locale_display_pattern_from_code_fast('tai'), 'get_locale_display_pattern_from_code[_fast] same result for tai' );
is( $self_obj->get_character_orientation_from_code('tai'),  $self_obj->get_character_orientation_from_code('tai'),       'get_character_orientation_from_code[_fast] same result for tai' );

is( $self_obj->get_locale_display_pattern_from_code('te'), $self_obj->get_locale_display_pattern_from_code_fast('te'), 'get_locale_display_pattern_from_code[_fast] same result for te' );
is( $self_obj->get_character_orientation_from_code('te'),  $self_obj->get_character_orientation_from_code('te'),       'get_character_orientation_from_code[_fast] same result for te' );

is( $self_obj->get_locale_display_pattern_from_code('tem'), $self_obj->get_locale_display_pattern_from_code_fast('tem'), 'get_locale_display_pattern_from_code[_fast] same result for tem' );
is( $self_obj->get_character_orientation_from_code('tem'),  $self_obj->get_character_orientation_from_code('tem'),       'get_character_orientation_from_code[_fast] same result for tem' );

is( $self_obj->get_locale_display_pattern_from_code('teo'), $self_obj->get_locale_display_pattern_from_code_fast('teo'), 'get_locale_display_pattern_from_code[_fast] same result for teo' );
is( $self_obj->get_character_orientation_from_code('teo'),  $self_obj->get_character_orientation_from_code('teo'),       'get_character_orientation_from_code[_fast] same result for teo' );

is( $self_obj->get_locale_display_pattern_from_code('ter'), $self_obj->get_locale_display_pattern_from_code_fast('ter'), 'get_locale_display_pattern_from_code[_fast] same result for ter' );
is( $self_obj->get_character_orientation_from_code('ter'),  $self_obj->get_character_orientation_from_code('ter'),       'get_character_orientation_from_code[_fast] same result for ter' );

is( $self_obj->get_locale_display_pattern_from_code('tet'), $self_obj->get_locale_display_pattern_from_code_fast('tet'), 'get_locale_display_pattern_from_code[_fast] same result for tet' );
is( $self_obj->get_character_orientation_from_code('tet'),  $self_obj->get_character_orientation_from_code('tet'),       'get_character_orientation_from_code[_fast] same result for tet' );

is( $self_obj->get_locale_display_pattern_from_code('tg'), $self_obj->get_locale_display_pattern_from_code_fast('tg'), 'get_locale_display_pattern_from_code[_fast] same result for tg' );
is( $self_obj->get_character_orientation_from_code('tg'),  $self_obj->get_character_orientation_from_code('tg'),       'get_character_orientation_from_code[_fast] same result for tg' );

is( $self_obj->get_locale_display_pattern_from_code('th'), $self_obj->get_locale_display_pattern_from_code_fast('th'), 'get_locale_display_pattern_from_code[_fast] same result for th' );
is( $self_obj->get_character_orientation_from_code('th'),  $self_obj->get_character_orientation_from_code('th'),       'get_character_orientation_from_code[_fast] same result for th' );

is( $self_obj->get_locale_display_pattern_from_code('ti'), $self_obj->get_locale_display_pattern_from_code_fast('ti'), 'get_locale_display_pattern_from_code[_fast] same result for ti' );
is( $self_obj->get_character_orientation_from_code('ti'),  $self_obj->get_character_orientation_from_code('ti'),       'get_character_orientation_from_code[_fast] same result for ti' );

is( $self_obj->get_locale_display_pattern_from_code('tig'), $self_obj->get_locale_display_pattern_from_code_fast('tig'), 'get_locale_display_pattern_from_code[_fast] same result for tig' );
is( $self_obj->get_character_orientation_from_code('tig'),  $self_obj->get_character_orientation_from_code('tig'),       'get_character_orientation_from_code[_fast] same result for tig' );

is( $self_obj->get_locale_display_pattern_from_code('tiv'), $self_obj->get_locale_display_pattern_from_code_fast('tiv'), 'get_locale_display_pattern_from_code[_fast] same result for tiv' );
is( $self_obj->get_character_orientation_from_code('tiv'),  $self_obj->get_character_orientation_from_code('tiv'),       'get_character_orientation_from_code[_fast] same result for tiv' );

is( $self_obj->get_locale_display_pattern_from_code('tk'), $self_obj->get_locale_display_pattern_from_code_fast('tk'), 'get_locale_display_pattern_from_code[_fast] same result for tk' );
is( $self_obj->get_character_orientation_from_code('tk'),  $self_obj->get_character_orientation_from_code('tk'),       'get_character_orientation_from_code[_fast] same result for tk' );

is( $self_obj->get_locale_display_pattern_from_code('tkl'), $self_obj->get_locale_display_pattern_from_code_fast('tkl'), 'get_locale_display_pattern_from_code[_fast] same result for tkl' );
is( $self_obj->get_character_orientation_from_code('tkl'),  $self_obj->get_character_orientation_from_code('tkl'),       'get_character_orientation_from_code[_fast] same result for tkl' );

is( $self_obj->get_locale_display_pattern_from_code('tl'), $self_obj->get_locale_display_pattern_from_code_fast('tl'), 'get_locale_display_pattern_from_code[_fast] same result for tl' );
is( $self_obj->get_character_orientation_from_code('tl'),  $self_obj->get_character_orientation_from_code('tl'),       'get_character_orientation_from_code[_fast] same result for tl' );

is( $self_obj->get_locale_display_pattern_from_code('tlh'), $self_obj->get_locale_display_pattern_from_code_fast('tlh'), 'get_locale_display_pattern_from_code[_fast] same result for tlh' );
is( $self_obj->get_character_orientation_from_code('tlh'),  $self_obj->get_character_orientation_from_code('tlh'),       'get_character_orientation_from_code[_fast] same result for tlh' );

is( $self_obj->get_locale_display_pattern_from_code('tli'), $self_obj->get_locale_display_pattern_from_code_fast('tli'), 'get_locale_display_pattern_from_code[_fast] same result for tli' );
is( $self_obj->get_character_orientation_from_code('tli'),  $self_obj->get_character_orientation_from_code('tli'),       'get_character_orientation_from_code[_fast] same result for tli' );

is( $self_obj->get_locale_display_pattern_from_code('tmh'), $self_obj->get_locale_display_pattern_from_code_fast('tmh'), 'get_locale_display_pattern_from_code[_fast] same result for tmh' );
is( $self_obj->get_character_orientation_from_code('tmh'),  $self_obj->get_character_orientation_from_code('tmh'),       'get_character_orientation_from_code[_fast] same result for tmh' );

is( $self_obj->get_locale_display_pattern_from_code('tn'), $self_obj->get_locale_display_pattern_from_code_fast('tn'), 'get_locale_display_pattern_from_code[_fast] same result for tn' );
is( $self_obj->get_character_orientation_from_code('tn'),  $self_obj->get_character_orientation_from_code('tn'),       'get_character_orientation_from_code[_fast] same result for tn' );

is( $self_obj->get_locale_display_pattern_from_code('to'), $self_obj->get_locale_display_pattern_from_code_fast('to'), 'get_locale_display_pattern_from_code[_fast] same result for to' );
is( $self_obj->get_character_orientation_from_code('to'),  $self_obj->get_character_orientation_from_code('to'),       'get_character_orientation_from_code[_fast] same result for to' );

is( $self_obj->get_locale_display_pattern_from_code('tog'), $self_obj->get_locale_display_pattern_from_code_fast('tog'), 'get_locale_display_pattern_from_code[_fast] same result for tog' );
is( $self_obj->get_character_orientation_from_code('tog'),  $self_obj->get_character_orientation_from_code('tog'),       'get_character_orientation_from_code[_fast] same result for tog' );

is( $self_obj->get_locale_display_pattern_from_code('tpi'), $self_obj->get_locale_display_pattern_from_code_fast('tpi'), 'get_locale_display_pattern_from_code[_fast] same result for tpi' );
is( $self_obj->get_character_orientation_from_code('tpi'),  $self_obj->get_character_orientation_from_code('tpi'),       'get_character_orientation_from_code[_fast] same result for tpi' );

is( $self_obj->get_locale_display_pattern_from_code('tr'), $self_obj->get_locale_display_pattern_from_code_fast('tr'), 'get_locale_display_pattern_from_code[_fast] same result for tr' );
is( $self_obj->get_character_orientation_from_code('tr'),  $self_obj->get_character_orientation_from_code('tr'),       'get_character_orientation_from_code[_fast] same result for tr' );

is( $self_obj->get_locale_display_pattern_from_code('trv'), $self_obj->get_locale_display_pattern_from_code_fast('trv'), 'get_locale_display_pattern_from_code[_fast] same result for trv' );
is( $self_obj->get_character_orientation_from_code('trv'),  $self_obj->get_character_orientation_from_code('trv'),       'get_character_orientation_from_code[_fast] same result for trv' );

is( $self_obj->get_locale_display_pattern_from_code('ts'), $self_obj->get_locale_display_pattern_from_code_fast('ts'), 'get_locale_display_pattern_from_code[_fast] same result for ts' );
is( $self_obj->get_character_orientation_from_code('ts'),  $self_obj->get_character_orientation_from_code('ts'),       'get_character_orientation_from_code[_fast] same result for ts' );

is( $self_obj->get_locale_display_pattern_from_code('tsi'), $self_obj->get_locale_display_pattern_from_code_fast('tsi'), 'get_locale_display_pattern_from_code[_fast] same result for tsi' );
is( $self_obj->get_character_orientation_from_code('tsi'),  $self_obj->get_character_orientation_from_code('tsi'),       'get_character_orientation_from_code[_fast] same result for tsi' );

is( $self_obj->get_locale_display_pattern_from_code('tt'), $self_obj->get_locale_display_pattern_from_code_fast('tt'), 'get_locale_display_pattern_from_code[_fast] same result for tt' );
is( $self_obj->get_character_orientation_from_code('tt'),  $self_obj->get_character_orientation_from_code('tt'),       'get_character_orientation_from_code[_fast] same result for tt' );

is( $self_obj->get_locale_display_pattern_from_code('tum'), $self_obj->get_locale_display_pattern_from_code_fast('tum'), 'get_locale_display_pattern_from_code[_fast] same result for tum' );
is( $self_obj->get_character_orientation_from_code('tum'),  $self_obj->get_character_orientation_from_code('tum'),       'get_character_orientation_from_code[_fast] same result for tum' );

is( $self_obj->get_locale_display_pattern_from_code('tup'), $self_obj->get_locale_display_pattern_from_code_fast('tup'), 'get_locale_display_pattern_from_code[_fast] same result for tup' );
is( $self_obj->get_character_orientation_from_code('tup'),  $self_obj->get_character_orientation_from_code('tup'),       'get_character_orientation_from_code[_fast] same result for tup' );

is( $self_obj->get_locale_display_pattern_from_code('tut'), $self_obj->get_locale_display_pattern_from_code_fast('tut'), 'get_locale_display_pattern_from_code[_fast] same result for tut' );
is( $self_obj->get_character_orientation_from_code('tut'),  $self_obj->get_character_orientation_from_code('tut'),       'get_character_orientation_from_code[_fast] same result for tut' );

is( $self_obj->get_locale_display_pattern_from_code('tvl'), $self_obj->get_locale_display_pattern_from_code_fast('tvl'), 'get_locale_display_pattern_from_code[_fast] same result for tvl' );
is( $self_obj->get_character_orientation_from_code('tvl'),  $self_obj->get_character_orientation_from_code('tvl'),       'get_character_orientation_from_code[_fast] same result for tvl' );

is( $self_obj->get_locale_display_pattern_from_code('tw'), $self_obj->get_locale_display_pattern_from_code_fast('tw'), 'get_locale_display_pattern_from_code[_fast] same result for tw' );
is( $self_obj->get_character_orientation_from_code('tw'),  $self_obj->get_character_orientation_from_code('tw'),       'get_character_orientation_from_code[_fast] same result for tw' );

is( $self_obj->get_locale_display_pattern_from_code('twq'), $self_obj->get_locale_display_pattern_from_code_fast('twq'), 'get_locale_display_pattern_from_code[_fast] same result for twq' );
is( $self_obj->get_character_orientation_from_code('twq'),  $self_obj->get_character_orientation_from_code('twq'),       'get_character_orientation_from_code[_fast] same result for twq' );

is( $self_obj->get_locale_display_pattern_from_code('ty'), $self_obj->get_locale_display_pattern_from_code_fast('ty'), 'get_locale_display_pattern_from_code[_fast] same result for ty' );
is( $self_obj->get_character_orientation_from_code('ty'),  $self_obj->get_character_orientation_from_code('ty'),       'get_character_orientation_from_code[_fast] same result for ty' );

is( $self_obj->get_locale_display_pattern_from_code('tyv'), $self_obj->get_locale_display_pattern_from_code_fast('tyv'), 'get_locale_display_pattern_from_code[_fast] same result for tyv' );
is( $self_obj->get_character_orientation_from_code('tyv'),  $self_obj->get_character_orientation_from_code('tyv'),       'get_character_orientation_from_code[_fast] same result for tyv' );

is( $self_obj->get_locale_display_pattern_from_code('tzm'), $self_obj->get_locale_display_pattern_from_code_fast('tzm'), 'get_locale_display_pattern_from_code[_fast] same result for tzm' );
is( $self_obj->get_character_orientation_from_code('tzm'),  $self_obj->get_character_orientation_from_code('tzm'),       'get_character_orientation_from_code[_fast] same result for tzm' );

is( $self_obj->get_locale_display_pattern_from_code('udm'), $self_obj->get_locale_display_pattern_from_code_fast('udm'), 'get_locale_display_pattern_from_code[_fast] same result for udm' );
is( $self_obj->get_character_orientation_from_code('udm'),  $self_obj->get_character_orientation_from_code('udm'),       'get_character_orientation_from_code[_fast] same result for udm' );

is( $self_obj->get_locale_display_pattern_from_code('ug'), $self_obj->get_locale_display_pattern_from_code_fast('ug'), 'get_locale_display_pattern_from_code[_fast] same result for ug' );
is( $self_obj->get_character_orientation_from_code('ug'),  $self_obj->get_character_orientation_from_code('ug'),       'get_character_orientation_from_code[_fast] same result for ug' );

is( $self_obj->get_locale_display_pattern_from_code('uga'), $self_obj->get_locale_display_pattern_from_code_fast('uga'), 'get_locale_display_pattern_from_code[_fast] same result for uga' );
is( $self_obj->get_character_orientation_from_code('uga'),  $self_obj->get_character_orientation_from_code('uga'),       'get_character_orientation_from_code[_fast] same result for uga' );

is( $self_obj->get_locale_display_pattern_from_code('uk'), $self_obj->get_locale_display_pattern_from_code_fast('uk'), 'get_locale_display_pattern_from_code[_fast] same result for uk' );
is( $self_obj->get_character_orientation_from_code('uk'),  $self_obj->get_character_orientation_from_code('uk'),       'get_character_orientation_from_code[_fast] same result for uk' );

is( $self_obj->get_locale_display_pattern_from_code('umb'), $self_obj->get_locale_display_pattern_from_code_fast('umb'), 'get_locale_display_pattern_from_code[_fast] same result for umb' );
is( $self_obj->get_character_orientation_from_code('umb'),  $self_obj->get_character_orientation_from_code('umb'),       'get_character_orientation_from_code[_fast] same result for umb' );

is( $self_obj->get_locale_display_pattern_from_code('und'), $self_obj->get_locale_display_pattern_from_code_fast('und'), 'get_locale_display_pattern_from_code[_fast] same result for und' );
is( $self_obj->get_character_orientation_from_code('und'),  $self_obj->get_character_orientation_from_code('und'),       'get_character_orientation_from_code[_fast] same result for und' );

is( $self_obj->get_locale_display_pattern_from_code('ur'), $self_obj->get_locale_display_pattern_from_code_fast('ur'), 'get_locale_display_pattern_from_code[_fast] same result for ur' );
is( $self_obj->get_character_orientation_from_code('ur'),  $self_obj->get_character_orientation_from_code('ur'),       'get_character_orientation_from_code[_fast] same result for ur' );

is( $self_obj->get_locale_display_pattern_from_code('uz'), $self_obj->get_locale_display_pattern_from_code_fast('uz'), 'get_locale_display_pattern_from_code[_fast] same result for uz' );
is( $self_obj->get_character_orientation_from_code('uz'),  $self_obj->get_character_orientation_from_code('uz'),       'get_character_orientation_from_code[_fast] same result for uz' );

is( $self_obj->get_locale_display_pattern_from_code('vai'), $self_obj->get_locale_display_pattern_from_code_fast('vai'), 'get_locale_display_pattern_from_code[_fast] same result for vai' );
is( $self_obj->get_character_orientation_from_code('vai'),  $self_obj->get_character_orientation_from_code('vai'),       'get_character_orientation_from_code[_fast] same result for vai' );

is( $self_obj->get_locale_display_pattern_from_code('ve'), $self_obj->get_locale_display_pattern_from_code_fast('ve'), 'get_locale_display_pattern_from_code[_fast] same result for ve' );
is( $self_obj->get_character_orientation_from_code('ve'),  $self_obj->get_character_orientation_from_code('ve'),       'get_character_orientation_from_code[_fast] same result for ve' );

is( $self_obj->get_locale_display_pattern_from_code('vi'), $self_obj->get_locale_display_pattern_from_code_fast('vi'), 'get_locale_display_pattern_from_code[_fast] same result for vi' );
is( $self_obj->get_character_orientation_from_code('vi'),  $self_obj->get_character_orientation_from_code('vi'),       'get_character_orientation_from_code[_fast] same result for vi' );

is( $self_obj->get_locale_display_pattern_from_code('vo'), $self_obj->get_locale_display_pattern_from_code_fast('vo'), 'get_locale_display_pattern_from_code[_fast] same result for vo' );
is( $self_obj->get_character_orientation_from_code('vo'),  $self_obj->get_character_orientation_from_code('vo'),       'get_character_orientation_from_code[_fast] same result for vo' );

is( $self_obj->get_locale_display_pattern_from_code('vot'), $self_obj->get_locale_display_pattern_from_code_fast('vot'), 'get_locale_display_pattern_from_code[_fast] same result for vot' );
is( $self_obj->get_character_orientation_from_code('vot'),  $self_obj->get_character_orientation_from_code('vot'),       'get_character_orientation_from_code[_fast] same result for vot' );

is( $self_obj->get_locale_display_pattern_from_code('vun'), $self_obj->get_locale_display_pattern_from_code_fast('vun'), 'get_locale_display_pattern_from_code[_fast] same result for vun' );
is( $self_obj->get_character_orientation_from_code('vun'),  $self_obj->get_character_orientation_from_code('vun'),       'get_character_orientation_from_code[_fast] same result for vun' );

is( $self_obj->get_locale_display_pattern_from_code('wa'), $self_obj->get_locale_display_pattern_from_code_fast('wa'), 'get_locale_display_pattern_from_code[_fast] same result for wa' );
is( $self_obj->get_character_orientation_from_code('wa'),  $self_obj->get_character_orientation_from_code('wa'),       'get_character_orientation_from_code[_fast] same result for wa' );

is( $self_obj->get_locale_display_pattern_from_code('wae'), $self_obj->get_locale_display_pattern_from_code_fast('wae'), 'get_locale_display_pattern_from_code[_fast] same result for wae' );
is( $self_obj->get_character_orientation_from_code('wae'),  $self_obj->get_character_orientation_from_code('wae'),       'get_character_orientation_from_code[_fast] same result for wae' );

is( $self_obj->get_locale_display_pattern_from_code('wak'), $self_obj->get_locale_display_pattern_from_code_fast('wak'), 'get_locale_display_pattern_from_code[_fast] same result for wak' );
is( $self_obj->get_character_orientation_from_code('wak'),  $self_obj->get_character_orientation_from_code('wak'),       'get_character_orientation_from_code[_fast] same result for wak' );

is( $self_obj->get_locale_display_pattern_from_code('wal'), $self_obj->get_locale_display_pattern_from_code_fast('wal'), 'get_locale_display_pattern_from_code[_fast] same result for wal' );
is( $self_obj->get_character_orientation_from_code('wal'),  $self_obj->get_character_orientation_from_code('wal'),       'get_character_orientation_from_code[_fast] same result for wal' );

is( $self_obj->get_locale_display_pattern_from_code('war'), $self_obj->get_locale_display_pattern_from_code_fast('war'), 'get_locale_display_pattern_from_code[_fast] same result for war' );
is( $self_obj->get_character_orientation_from_code('war'),  $self_obj->get_character_orientation_from_code('war'),       'get_character_orientation_from_code[_fast] same result for war' );

is( $self_obj->get_locale_display_pattern_from_code('was'), $self_obj->get_locale_display_pattern_from_code_fast('was'), 'get_locale_display_pattern_from_code[_fast] same result for was' );
is( $self_obj->get_character_orientation_from_code('was'),  $self_obj->get_character_orientation_from_code('was'),       'get_character_orientation_from_code[_fast] same result for was' );

is( $self_obj->get_locale_display_pattern_from_code('wen'), $self_obj->get_locale_display_pattern_from_code_fast('wen'), 'get_locale_display_pattern_from_code[_fast] same result for wen' );
is( $self_obj->get_character_orientation_from_code('wen'),  $self_obj->get_character_orientation_from_code('wen'),       'get_character_orientation_from_code[_fast] same result for wen' );

is( $self_obj->get_locale_display_pattern_from_code('wo'), $self_obj->get_locale_display_pattern_from_code_fast('wo'), 'get_locale_display_pattern_from_code[_fast] same result for wo' );
is( $self_obj->get_character_orientation_from_code('wo'),  $self_obj->get_character_orientation_from_code('wo'),       'get_character_orientation_from_code[_fast] same result for wo' );

is( $self_obj->get_locale_display_pattern_from_code('xal'), $self_obj->get_locale_display_pattern_from_code_fast('xal'), 'get_locale_display_pattern_from_code[_fast] same result for xal' );
is( $self_obj->get_character_orientation_from_code('xal'),  $self_obj->get_character_orientation_from_code('xal'),       'get_character_orientation_from_code[_fast] same result for xal' );

is( $self_obj->get_locale_display_pattern_from_code('xh'), $self_obj->get_locale_display_pattern_from_code_fast('xh'), 'get_locale_display_pattern_from_code[_fast] same result for xh' );
is( $self_obj->get_character_orientation_from_code('xh'),  $self_obj->get_character_orientation_from_code('xh'),       'get_character_orientation_from_code[_fast] same result for xh' );

is( $self_obj->get_locale_display_pattern_from_code('xog'), $self_obj->get_locale_display_pattern_from_code_fast('xog'), 'get_locale_display_pattern_from_code[_fast] same result for xog' );
is( $self_obj->get_character_orientation_from_code('xog'),  $self_obj->get_character_orientation_from_code('xog'),       'get_character_orientation_from_code[_fast] same result for xog' );

is( $self_obj->get_locale_display_pattern_from_code('yao'), $self_obj->get_locale_display_pattern_from_code_fast('yao'), 'get_locale_display_pattern_from_code[_fast] same result for yao' );
is( $self_obj->get_character_orientation_from_code('yao'),  $self_obj->get_character_orientation_from_code('yao'),       'get_character_orientation_from_code[_fast] same result for yao' );

is( $self_obj->get_locale_display_pattern_from_code('yap'), $self_obj->get_locale_display_pattern_from_code_fast('yap'), 'get_locale_display_pattern_from_code[_fast] same result for yap' );
is( $self_obj->get_character_orientation_from_code('yap'),  $self_obj->get_character_orientation_from_code('yap'),       'get_character_orientation_from_code[_fast] same result for yap' );

is( $self_obj->get_locale_display_pattern_from_code('yav'), $self_obj->get_locale_display_pattern_from_code_fast('yav'), 'get_locale_display_pattern_from_code[_fast] same result for yav' );
is( $self_obj->get_character_orientation_from_code('yav'),  $self_obj->get_character_orientation_from_code('yav'),       'get_character_orientation_from_code[_fast] same result for yav' );

is( $self_obj->get_locale_display_pattern_from_code('yi'), $self_obj->get_locale_display_pattern_from_code_fast('yi'), 'get_locale_display_pattern_from_code[_fast] same result for yi' );
is( $self_obj->get_character_orientation_from_code('yi'),  $self_obj->get_character_orientation_from_code('yi'),       'get_character_orientation_from_code[_fast] same result for yi' );

is( $self_obj->get_locale_display_pattern_from_code('yo'), $self_obj->get_locale_display_pattern_from_code_fast('yo'), 'get_locale_display_pattern_from_code[_fast] same result for yo' );
is( $self_obj->get_character_orientation_from_code('yo'),  $self_obj->get_character_orientation_from_code('yo'),       'get_character_orientation_from_code[_fast] same result for yo' );

is( $self_obj->get_locale_display_pattern_from_code('ypk'), $self_obj->get_locale_display_pattern_from_code_fast('ypk'), 'get_locale_display_pattern_from_code[_fast] same result for ypk' );
is( $self_obj->get_character_orientation_from_code('ypk'),  $self_obj->get_character_orientation_from_code('ypk'),       'get_character_orientation_from_code[_fast] same result for ypk' );

is( $self_obj->get_locale_display_pattern_from_code('yue'), $self_obj->get_locale_display_pattern_from_code_fast('yue'), 'get_locale_display_pattern_from_code[_fast] same result for yue' );
is( $self_obj->get_character_orientation_from_code('yue'),  $self_obj->get_character_orientation_from_code('yue'),       'get_character_orientation_from_code[_fast] same result for yue' );

is( $self_obj->get_locale_display_pattern_from_code('za'), $self_obj->get_locale_display_pattern_from_code_fast('za'), 'get_locale_display_pattern_from_code[_fast] same result for za' );
is( $self_obj->get_character_orientation_from_code('za'),  $self_obj->get_character_orientation_from_code('za'),       'get_character_orientation_from_code[_fast] same result for za' );

is( $self_obj->get_locale_display_pattern_from_code('zap'), $self_obj->get_locale_display_pattern_from_code_fast('zap'), 'get_locale_display_pattern_from_code[_fast] same result for zap' );
is( $self_obj->get_character_orientation_from_code('zap'),  $self_obj->get_character_orientation_from_code('zap'),       'get_character_orientation_from_code[_fast] same result for zap' );

is( $self_obj->get_locale_display_pattern_from_code('zbl'), $self_obj->get_locale_display_pattern_from_code_fast('zbl'), 'get_locale_display_pattern_from_code[_fast] same result for zbl' );
is( $self_obj->get_character_orientation_from_code('zbl'),  $self_obj->get_character_orientation_from_code('zbl'),       'get_character_orientation_from_code[_fast] same result for zbl' );

is( $self_obj->get_locale_display_pattern_from_code('zen'), $self_obj->get_locale_display_pattern_from_code_fast('zen'), 'get_locale_display_pattern_from_code[_fast] same result for zen' );
is( $self_obj->get_character_orientation_from_code('zen'),  $self_obj->get_character_orientation_from_code('zen'),       'get_character_orientation_from_code[_fast] same result for zen' );

is( $self_obj->get_locale_display_pattern_from_code('zh'), $self_obj->get_locale_display_pattern_from_code_fast('zh'), 'get_locale_display_pattern_from_code[_fast] same result for zh' );
is( $self_obj->get_character_orientation_from_code('zh'),  $self_obj->get_character_orientation_from_code('zh'),       'get_character_orientation_from_code[_fast] same result for zh' );

is( $self_obj->get_locale_display_pattern_from_code('znd'), $self_obj->get_locale_display_pattern_from_code_fast('znd'), 'get_locale_display_pattern_from_code[_fast] same result for znd' );
is( $self_obj->get_character_orientation_from_code('znd'),  $self_obj->get_character_orientation_from_code('znd'),       'get_character_orientation_from_code[_fast] same result for znd' );

is( $self_obj->get_locale_display_pattern_from_code('zu'), $self_obj->get_locale_display_pattern_from_code_fast('zu'), 'get_locale_display_pattern_from_code[_fast] same result for zu' );
is( $self_obj->get_character_orientation_from_code('zu'),  $self_obj->get_character_orientation_from_code('zu'),       'get_character_orientation_from_code[_fast] same result for zu' );

is( $self_obj->get_locale_display_pattern_from_code('zun'), $self_obj->get_locale_display_pattern_from_code_fast('zun'), 'get_locale_display_pattern_from_code[_fast] same result for zun' );
is( $self_obj->get_character_orientation_from_code('zun'),  $self_obj->get_character_orientation_from_code('zun'),       'get_character_orientation_from_code[_fast] same result for zun' );

is( $self_obj->get_locale_display_pattern_from_code('zxx'), $self_obj->get_locale_display_pattern_from_code_fast('zxx'), 'get_locale_display_pattern_from_code[_fast] same result for zxx' );
is( $self_obj->get_character_orientation_from_code('zxx'),  $self_obj->get_character_orientation_from_code('zxx'),       'get_character_orientation_from_code[_fast] same result for zxx' );

is( $self_obj->get_locale_display_pattern_from_code('zza'), $self_obj->get_locale_display_pattern_from_code_fast('zza'), 'get_locale_display_pattern_from_code[_fast] same result for zza' );
is( $self_obj->get_character_orientation_from_code('zza'),  $self_obj->get_character_orientation_from_code('zza'),       'get_character_orientation_from_code[_fast] same result for zza' );

