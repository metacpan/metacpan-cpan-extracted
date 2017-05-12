use Test::More tests => 135;
use Test::Warn;

BEGIN {
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
}

package TestApp::Localize;
use Locale::Maketext::Utils;
use base 'Locale::Maketext::Utils';

our $Encoding = 'utf8';

our %Lexicon = (
    '_AUTO'    => 42,
    'Fallback' => 'Fallback orig',
    'One Side' => 'I am not one sides',
);

__PACKAGE__->make_alias( 'i_alias1', 1 );

sub output_test {
    my ( $lh, $string ) = @_;
    return "TEST $string TEST";
}

package TestApp::Localize::en;
use base 'TestApp::Localize';

package TestApp::Localize::en_us;
use base 'TestApp::Localize';

package TestApp::Localize::es_es;
use base 'TestApp::Localize';

package TestApp::Localize::i_default;
use base 'TestApp::Localize';

package TestApp::Localize::i_oneside;
use base 'TestApp::Localize';

__PACKAGE__->make_alias( [qw(i_alias2 i_alias3)], 0 );

# our $Onesided = 1;
our %Lexicon = (
    'One Side' => '',
);

package TestApp::Localize::fr;
use base 'TestApp::Localize';

our $Encoding = 'utf7';

our %Lexicon = (
    'Hello World' => '[output,strong,Bonjour] Monde',
);

sub init {
    my ($lh) = @_;
    $lh->SUPER::init();
    $lh->{'numf_comma'}       = 1;      # Locale::Maketext numf()
    $lh->{'list_seperator'}   = '. ';
    $lh->{'oxford_seperator'} = '';
    $lh->{'list_default_and'} = '&&';
    return $lh;
}

package main;

{
    local $ENV{'maketext_obj_skip_env'} = 1;
    local $ENV{'maketext_obj'}          = 'CURRENT VALUE';

    my $noarg = TestApp::Localize->get_handle();

    # depending on their Locales::Base may not have one of these
    ok( $noarg->language_tag() eq 'en' || $noarg->language_tag() eq 'en-us', 'get_handle no arg' );

    my $first_lex = ( @{ $noarg->_lex_refs() } )[0];
    ok( !exists $first_lex->{'_AUTO'}, '_AUTO removal/remove_key_from_lexicons()' );

    # L::M adds an additional lexicon, was index 0 before the 0.20 update
    is( $noarg->{'_removed_from_lexicons'}{'1'}{'_AUTO'}, '42', '_AUTO removal archive/remove_key_from_lexicons()' );

    ok( $ENV{'maketext_obj'} ne $noarg, 'ENV maketext_obj_skip_env true' );
}

my $no_arg = TestApp::Localize->get_handle();
like( ref($no_arg), qr/TestApp::Localize::en(?:\_us)?/, 'no argument has highest level langtag NS' );

my $en = TestApp::Localize->get_handle('en');
ok( $ENV{'maketext_obj'} eq $en, 'ENV maketext_obj_skip_env false' );

ok( $en->get_language_class() eq 'TestApp::Localize::en',                   'get_language_class() obj method' );
ok( TestApp::Localize::fr->get_language_class() eq 'TestApp::Localize::fr', 'get_language_class() class method' );
ok( !defined $en->get_base_class_dir(),                                     'get_base_class_dir() returns undefined for non .pm based base class' );
ok( !defined $en->list_available_locales(),                                 'list_available_locales() returns undefined for non .pm based base class' );

my $has_sub_todo = eval { require Sub::Todo } ? 1 : 0;
$! = 0;    # just to be sure
ok( !$en->add_lexicon_override_hash( 'en', 'before', { a => 1 } ), "add_lexicon_override_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon" );
SKIP: {
    skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
    ok( $! > 0, 'add_lexicon_override_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}
SKIP: {
    skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
    ok( $! == 0, 'add_lexicon_override_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}

ok( !$en->add_lexicon_fallback_hash( 'en', 'after', { b => 1 } ), "add_lexcion_fallback_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon" );
SKIP: {
    skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
    ok( $! > 0, 'add_lexicon_fallback_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}
SKIP: {
    skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
    ok( $! == 0, 'add_lexicon_fallback_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}

ok( !$en->del_lexicon_hash( 'en', 'before' ), "del_lexicon_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon" );
SKIP: {
    skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
    ok( $! > 0, 'del_lexicon_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}
SKIP: {
    skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
    ok( $! == 0, 'del_lexicon_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}

ok( !$en->del_lexicon_hash( '*', 'after' ), "del_lexicon_hash() returns false w/ * even with non Tie::Hash::ReadonlyStack compat Lexicon" );
SKIP: {
    skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
    ok( $! > 0, 'del_lexicon_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}
SKIP: {
    skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
    ok( $! == 0, 'del_lexicon_hash() + * w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
    $! = 0;
}

ok( $en->language_tag() eq 'en',                'get_handle en' );
ok( $en->langtag_is_loadable('invalid') eq '0', 'langtag_is_loadable() w/ unloadable tag' );
ok(
    ref $en->langtag_is_loadable('fr') eq 'TestApp::Localize::fr',
    'langtag_is_loadable() w/ loadable tag'
);

my $is_singleton = TestApp::Localize->get_handle('en');
ok( $en eq $is_singleton, 'same args result in singleton behavior' );

my $one   = TestApp::Localize->get_handle( 'en', 'fr' );
my $two   = TestApp::Localize->get_handle( 'en', 'fr' );
my $three = TestApp::Localize->get_handle( 'fr', 'en' );

ok( $one eq $two,   'singleton same order is the same obj' );
ok( $two ne $three, 'singleton different order is not the same obj' );

ok( $en->encoding() eq 'utf8', 'base $Encoding' );

{
    local $en->{'_get_key_from_lookup'} = sub {
        return 'look up version';
    };
    ok( $en->maketext('Needs looked up') eq 'look up version', '_get_key_from_lookup' );
}

my $bad = TestApp::Localize->get_handle('bad');
ok( $bad->language_tag() eq 'en', 'invalid get_handle arg' );
$bad->{'_log_phantom_key'} = sub {
    $ENV{'_log_phantum_key'} = 'done';
};
ok( $bad->maketext('Not in Lexicon') eq 'Not in Lexicon' && $ENV{'_log_phantum_key'} eq 'done', '_log_phantom_key' );

my $oneside = TestApp::Localize->get_handle('i_oneside');

#
# ok($TestApp::Localize::i_oneside::Lexicon{'One Side'} eq '', '$Onesided untouched initially');
# ok($oneside->maketext('One Side') eq 'One Side', 'Once used $Onesided returns proper value');
# ok(ref $TestApp::Localize::i_oneside::Lexicon{'One Side'} eq 'SCALAR', 'Once used $Onesided does lexicon (sanity check that it is not just falling back)');

my $alias1 = TestApp::Localize->get_handle('i_alias1');
ok( $alias1->get_language_tag() eq 'i_alias1', '$Aliaspkg w/ string' );
my $alias2 = TestApp::Localize->get_handle('i_alias2');
ok( $alias2->get_language_tag() eq 'i_alias2', '$Aliaspkg w/ array ref 1' );
my $alias3 = TestApp::Localize->get_handle('i_alias3');
ok( $alias3->get_language_tag() eq 'i_alias3',          '$Aliaspkg w/ array ref 2' );
ok( $alias1->fetch('One Side') eq 'I am not one sides', 'Base class make_alias' );

# ok($alias2->fetch('One Side') eq 'One Side', 'Extended class make_alias');

my $en_US = TestApp::Localize->get_handle('en-US');
ok( $en_US->language_tag() eq 'en-us',     'get_handle en-US' );
ok( $en_US->get_language_tag() eq 'en_us', 'get_language_tag()' );

my $fallback = TestApp::Localize->get_handle('ca');
is( $fallback->get_language_tag(), 'es_es', 'fallback object is from CLDR not I18N::LangTags::panic_languages() (ca would be fr in this class)' );

my $fr = TestApp::Localize->get_handle('fr');
{
    local $fr->{'use_external_lex_cache'} = 1;

    is( $fr->lextext('Hello World'),                         '[output,strong,Bonjour] Monde',       'lextext() returns the lexicon value in uncompiled form before the compiled value is cached' );
    is( $fr->lextext('Glorb GLib Glob [output,strong,Bop]'), 'Glorb GLib Glob [output,strong,Bop]', 'lextext() returns the phrase in uncompiled form when it is not in the lex' );

    warning_is {
        is( $fr->text('Hello World'), $fr->lextext('Hello World'), 'text() returns the same value as lextext()' );
    }
    'text() is deprecated, use lextext() instead', 'text() complains about being deprecated"';

    ok( !exists $fr->{'_external_lex_cache'}{'Hello World'}, 'Sanity: phrase is not yet cached' );
    $fr->maketext('Hello World');    # cache it
    ok( exists $fr->{'_external_lex_cache'}{'Hello World'}, 'Sanity: maketext() caches compiled version' );    # make sure it is no cached
    is( $fr->lextext('Hello World'),                         '[output,strong,Bonjour] Monde',       'lextext() returns the lexicon value in uncompiled form after the compiled value is cached' );
    is( $fr->lextext('Glorb GLib Glob [output,strong,Bop]'), 'Glorb GLib Glob [output,strong,Bop]', 'lextext() subsequently returns the phrase in uncompiled form when it is not in the lex' );
}

ok( $fr->language_tag() eq 'fr',                  'get_handle fr' );
ok( $fr->get_base_class() eq 'TestApp::Localize', 'get_base_class()' );
{
    local $fr->{'-t-STDIN'} = 0;
    is( $fr->fetch('Hello World'), '<strong>Bonjour</strong> Monde', 'fetch() method' );
}
ok( $fr->{'numf_comma'} eq '1', 'init set value ok' );

# safe to assume print() will work to if fetch() does...

{
    local $/ = "\n";               # just to be sure we're testing consistently …
    local $fr->{'-t-STDIN'} = 0;
    is( $fr->get('Hello World'), "<strong>Bonjour</strong> Monde\n", 'get() method' );

    # safe to assume say() will work to if get() does...
}
ok( $fr->encoding() eq 'utf7',                 'class $Encoding' );
ok( $fr->fetch('Fallback') eq 'Fallback orig', 'fallback  behavior' );
ok( $fr->fetch('Thank you') eq 'Thank you',    'fail_with _AUTO behavior' );

$fr->append_to_lexicons(
    {
        '_' => {
            'Fallback' => 'Fallback new',
        },
        'fr' => {
            'Thank you' => 'Merci',
        },
    }
);

ok( $fr->fetch('Thank you') eq 'Merci',       'append_to_lexicons()' );
ok( $fr->fetch('Fallback') eq 'Fallback new', 'fallback behavior after append' );

my $fr_hr = $fr->lang_names_hashref( 'en-uk', 'it', 'xxyyzz' );

ok( $fr_hr->{'en'} eq 'anglais',         'names default' );
ok( $fr_hr->{'en-uk'} eq 'anglais (uk)', 'names suffix' );
ok( $fr_hr->{'it'} eq 'italien',         'names normal' );
ok( $fr_hr->{'xxyyzz'} eq 'xxyyzz',      'names fake' );

my $sig_warn = exists $SIG{__WARN__} && defined $SIG{__WARN__} ? $SIG{__WARN__} : 'no exists/defined';

#my $base_sig_warn = exists $Locales::Base::SIG{__WARN__} && defined $Locales::Base::SIG{__WARN__} ? $Locales::Base::SIG{__WARN__} : 'no exists/defined';
my ( $loc_hr, $nat_hr ) = $fr->lang_names_hashref( 'en-uk', 'it', 'xxyyzz' );
my $sig_warn_aft = exists $SIG{__WARN__} && defined $SIG{__WARN__} ? $SIG{__WARN__} : 'no exists/defined';

#my $base_sig_warn_aft = exists $Locales::Base::SIG{__WARN__} && defined $Locales::Base::SIG{__WARN__} ? $Locales::Base::SIG{__WARN__} : 'no exists/defined';
ok( $sig_warn eq $sig_warn_aft, 'main sig warn unchanged by lang_names_hashref()' );

# ok($base_sig_warn eq $base_sig_warn_aft, 'locale::base sig warn unchanged by lang_names_hashref()');

ok( $loc_hr->{'en'} eq 'anglais',         'array context handle locale names default' );
ok( $loc_hr->{'en-uk'} eq 'anglais (uk)', 'array context handle locale names suffix' );
ok( $loc_hr->{'it'} eq 'italien',         'array context handle locale names normal' );
ok( $loc_hr->{'xxyyzz'} eq 'xxyyzz',      'array context handle locale  names fake' );

ok( $nat_hr->{'en'} eq 'English',         'array context native names default' );
ok( $nat_hr->{'en-uk'} eq 'English (uk)', 'array context native names suffix' );
ok( $nat_hr->{'it'} eq 'italiano',        'array context native names normal' );
ok( $nat_hr->{'xxyyzz'} eq 'xxyyzz',      'array context native names fake' );

my $loadable_hr = $fr->loadable_lang_names_hashref( 'en-uk', 'it', 'xxyyzz', 'fr' );

ok( ( keys %{$loadable_hr} ) == 2 && exists $loadable_hr->{'en'} && exists $loadable_hr->{'fr'}, 'loadable names' );

# prepare
my $dir = './my_lang_pm_search_paths_test';
mkdir $dir;
mkdir "$dir/TestApp";
mkdir "$dir/TestApp/Localize";
die "mkdir $@" if !-d "$dir/TestApp/Localize";

open my $pm, '>', "$dir/TestApp/Localize/it.pm" or die "open $!";
print {$pm} <<'IT_END';
package TestApp::Localize::it;
use base 'TestApp::Localize';

__PACKAGE__->make_alias('it_us');

our %Lexicon = (
    'Hello World' => 'Ciao Mondo',
);

1;
IT_END
close $pm;

require "$dir/TestApp/Localize/it.pm";
my $it_us = TestApp::Localize->get_handle('it_us');
ok( $it_us->fetch('Hello World') eq 'Ciao Mondo', '.pm file alias test' );

# _lang_pm_search_paths
$en->{'_lang_pm_search_paths'} = [$dir];
my $dir_hr = $en->lang_names_hashref();
ok( ( keys %{$dir_hr} ) == 2 && exists $dir_hr->{'en'} && exists $dir_hr->{'it'}, '_lang_pm_search_paths names' );

# @INC
unshift @INC, $dir;
my $inc_hr = $fr->lang_names_hashref();
ok( ( keys %{$inc_hr} ) == 2 && exists $inc_hr->{'en'} && exists $inc_hr->{'it'}, '@INC names' );

delete $en->{'_get_key_from_lookup'};    #  don't this anymore

# datetime

ok( $en->maketext('[datetime]') =~ m{ \A \w+ \s \d+ [,] \s \d+ \z }xms, 'undef 1st undef 2nd' );
ok( $en->maketext('[datetime,,YYYY]') =~ m{\d},                         'datetime() first arg empty string' );
is( $en->maketext('[datetime,,YYYY]'), $en->maketext('[current_year]'), 'current_year()' );

# perl -MDateTime -E 'say DateTime::Locale->load("en")->format_for("yMMMM");'
# 'yMMMM' is a format_for() value
is( $en->maketext('[datetime,,yMMMM]'), $en->maketext('[datetime,,MMMM y]'), 'format_for() patterns work' );

my $dt_obj = DateTime->new( 'year' => 1978 );    # DateTime already brought in by prev [datetime] call

# due to rt 49724 it may be 19NN or just NN so we make the century optional
ok( $en->maketext( '[datetime,_1]', $dt_obj ) =~ m{^January 1, (?:19)?78$}i, '1st arg object' );
like( $en->maketext( '[datetime,_1,_2]', { 'year' => 1977 }, '' ), qr{^January 1, (?:19)?77$}i, '1st arg hashref' );
is( $en->maketext( '[datetime,_1,_2]', { 'year' => 1977 }, 'yyyy' ), '1977', '2nd arg string' );
like( $en->maketext( '[datetime,_1,_2]', { 'year' => 1977 }, sub { $_[0]->{'locale'}->datetime_format_long } ), qr{^January 1, (?:19)?77.*12:00:00 AM .*$}i, '2nd arg coderef' );
like( $en->maketext( '[datetime,_1,_2]', { 'year' => 1978, 'month' => 11, 'day' => 13 }, sub { $_[0]->{'locale'}->datetime_format_long } ), qr{^November 13, (?:19)?78.*12:00:00 AM .*$}i, '[datetime] English' );
like( $fr->maketext( '[datetime,_1,_2]', { 'year' => 1999, 'month' => 7,  'day' => 17 }, sub { $_[0]->{'locale'}->datetime_format_long } ), qr{^17 juillet (?:19)?99.*00:00:00 .*$}i,      '[datetime] French' );

like( $en->maketext( '[datetime,_1,datetime_format_short]', { 'year' => 1977 } ), qr{1/1/77.*12:00 AM}, '2nd arg DateTime::Locale method name' );

# is( $en->maketext('[datetime,_1,_2]', {'year'=>1977}, 'invalid' ), 'invalid', '2nd arg DateTime::Locale method name invalid');

my $epoch = time;
my $epoch_utc = DateTime->from_epoch( 'epoch' => $epoch, 'time_zone' => 'UTC' );

# CLDR has no second since epoch: ok( $en->maketext('[datetime,_1,%s]','UTC') >= $epoch , '1st arg TZ');
is( $en->maketext( '[datetime,_1,date_format_long]', $epoch ),       $epoch_utc->format_cldr( $epoch_utc->{'locale'}->date_format_long ), '1st arg Epoch' );
is( $en->maketext( '[datetime,_1,date_format_long]', "$epoch:UTC" ), $epoch_utc->format_cldr( $epoch_utc->{'locale'}->date_format_long ), '1st arg Epoch:TZ' );

# numf w/ decimal support

my $pi = 355 / 113;
like( $en->maketext( "pi is [numf,_1]", $pi ), qr/pi is 3.14159[0-9]/, 'default decimal behavior' );

{
    no warnings 'numeric';

    # uncomment once we can address the warning
    # is( $en->maketext("pi is [numf,_1,_2]",$pi,''), 'pi is 3', 'w/ empty');
}
is( $en->maketext( "pi is [numf,_1,_2]", $pi, 0 ), 'pi is 3', 'w/ zero' );
like( $en->maketext( "pi is [numf,_1,_2]", $pi, 6 ),   qr/pi is 3.14159[0-9]/,, 'w/ number' );
like( $en->maketext( "pi is [numf,_1,_2]", $pi, -6 ),  qr/pi is 3.14159[0-9]/,, 'w/ negative' );
like( $en->maketext( "pi is [numf,_1,_2]", $pi, 6.2 ), qr/pi is 3.14159[0-9]/,, 'w/ decimal' );

#is( $en->maketext("pi is [numf,_1,_2]",$pi,'%.3f'), 'pi is 3.142', 'w/ no numeric');

{
    no warnings 'numeric';

    # uncomment once we can address the warning
    # is( $en->maketext("pi is [numf,_1,]",$pi), 'pi is 3', 'bn: w/ empty');
}
is( $en->maketext( "pi is [numf,_1,0]", $pi ), 'pi is 3', 'bn: w/ zero' );
like( $en->maketext( "pi is [numf,_1,6]",   $pi ), qr/pi is 3.14159[0-9]/, 'bn: w/ number' );
like( $en->maketext( "pi is [numf,_1,-6]",  $pi ), qr/pi is 3.14159[0-9]/, 'bn: w/ negative' );
like( $en->maketext( "pi is [numf,_1,6.2]", $pi ), qr/pi is 3.14159[0-9]/, 'bn: w/ decimal' );

# is( $en->maketext("pi is [numf,_1,_2]",$pi,'%.3f'), 'pi is 3.142', 'bn: w/ no numeric');

is( $en->numf(),      0, 'numf no args is zero' );
is( $en->numf(undef), 0, 'numf nundef is zero' );

# uncomment once we can address the warning
# is( $en->numf(''), 0, 'numf empty is zero' );

# join

ok( $en->maketext( "[join,~,,_*]",   1, 2, 3, 4 ) eq '1,2,3,4', "join all" );
ok( $en->maketext( "[join,,_*]",     1, 2, 3, 4 ) eq '1234',    "blank sep" );
ok( $en->maketext( "[join,_*]",      1, 2, 3, 4 ) eq '21314',   "no sep" );
ok( $en->maketext( "[join,-,_2,_4]", 1, 2, 3, 4 ) eq '2-4',     "join specifc" );

# ok( $en->maketext("[join,-,_2.._#]",1,2,3,4) eq '2-3-4', "join range");

# list

# ok( $en->maketext("[_1] is [list,and,_2.._#]",qw(a)) eq 'a is ','list no arg');
# ok( $en->maketext("[_1] is [list,and,_2.._#]",qw(a b)) eq 'a is b','list one arg "and" sep');
# ok( $en->maketext("[_1] is [list,&&,_2.._#]",qw(a b c)) eq 'a is b && c','list 2 arg special sep');
# ok( $en->maketext("[_1] is [list,,_2.._#]",qw(a b c d)) eq 'a is b, c, & d','list 3 arg undef sep');
# ok( $en->maketext("[_1] is [list,or,_2.._#]",qw(a b c d e)) eq 'a is b, c, d, or e','list 4 arg "or" sep');
# ok( $en->maketext("[_1] is [list,and,_2.._#]",qw(a b c d e)) eq 'a is b, c, d, and e','list 4 arg "and" sep');
#
# ok( $fr->maketext("[_1] is [list,,_2.._#]",qw(a b c d e)) eq 'a is b. c. d && e','specials set by class');

# boolean

ok( $en->maketext( 'boolean [boolean,_1,true,false] x',      1 ) eq 'boolean true x',      'boolean 2 arg true' );
ok( $en->maketext( 'boolean [boolean,_1,true,false] x',      0 ) eq 'boolean false x',     'boolean 2 arg false' );
ok( $en->maketext( 'boolean [boolean,_1,true,false] x',      undef ) eq 'boolean false x', 'boolean 2 arg undef' );
ok( $en->maketext( 'boolean [boolean,_1,true,false,null] x', 1 ) eq 'boolean true x',      'boolean 3 arg true' );
ok( $en->maketext( 'boolean [boolean,_1,true,false,null] x', 0 ) eq 'boolean false x',     'boolean 3 arg false' );
ok( $en->maketext( 'boolean [boolean,_1,true,false,null] x', undef ) eq 'boolean null x',  'boolean 3 arg undef' );

# output

ok( $en->maketext('hello [output,test,hello world]') eq 'hello TEST hello world TEST', "output() with existing function" );
$! = 0;
ok( $en->maketext('hello [output,notexists,hello world]') eq 'hello hello world', "output() with non existant function" );

SKIP: {
    skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
    ok( $! > 0, 'output() with non existant function + Sub::Todo sets $!' );
    $! = 0;
}
SKIP: {
    skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
    ok( $! == 0, 'output() with non existant function w/ out Sub::Todo does not get $! set' );
    $! = 0;
}

# convert

SKIP: {
    eval 'use Math::Units';
    skip 'Math::Units required for testing convert()', 1 if $@;
    ok( $en->maketext( "[convert,_*]", 1, 'ft', 'in' ) eq '12', 'convert() method' );
}

# format_bytes

is( $en->format_bytes(1023),    '1,023 bytes', 'format_bytes() bytes' );
is( $en->format_bytes(1048576), '1 MB',        'format_bytes() not bytes' );
like( $en->format_bytes(1023.12345), qr/1,023.\d{2}\xC2\xA0bytes/, 'format_bytes() bytes default max decimal' );
like( $en->format_bytes(2796553), qr/2.\d{2} MB/, 'format_bytes() not bytes default max decimal' );
like( $en->format_bytes( 1023.12345, 3 ), qr/1,023.\d{3}\xC2\xA0bytes/, 'format_bytes() bytes arg max decimal' );
like( $en->format_bytes( 2796553, 3 ), qr/2.\d{3} MB/, 'format_bytes() bytes arg max decimal' );

# __WS
# my %ws_spiff = (
#     "Multiple\nLine\n\tformatted\nstring" => {
#         'name'   => 'multiline',
#         'expect' => 'Multiple Line formatted string',
#     },
#     '  Leading WS' => {
#         'name'   => 'leading WS',
#         'expect' => 'Leading WS',
#     },
#     "Trailing WS \n" => {
#         'name'   => 'trailing WS',
#         'expect' => 'Trailing WS',
#     },
#     "Multiple   \n\t  Internal" => {
#         'name'   => 'internal WS',
#         'expect' => 'Multiple Internal',
#     },
#     " All    three   \n\t  types   and multple times\n" => {
#         'name'   => 'multipe types/occurances',
#         'expect' => 'All three types and multple times',
#     },
#     "… leading ellipsis" => {
#         'name'   => 'leafing ellipsis',
#         'expect' => ' … leading ellipsis',
#     }
# );
# for my $ws ( sort keys %ws_spiff ) {
#     is( Locale::Maketext::Utils::__WS($ws), $ws_spiff{$ws}{'expect'}, "__WS: $ws_spiff{$ws}{'name'}" );
# }

is( $en->makethis( "[quant,_1,en-one,en-other,en-zero]", 0 ), 'en-zero', 'makethis() en' );
is( $en->makethis_base( "[quant,_1,en-one,en-other,en-zero]", 0 ), 'en-zero', 'makethis_base() en' );
is( $fr->makethis( "[quant,_1,en-one,en-other,en-zero]", 0 ), '0 en-one', 'makethis() non-en rule' );    # fr has no spec-zero so this should be fr rules
is( $fr->makethis_base( "[quant,_1,en-one,en-other,en-zero]", 0 ), 'en-zero', 'makethis_base() non-en rule' );

is( $fr->makethis( "[quant,_1,en-one,en-other,en-zero]", 123456 ), '123 456 en-other', 'makethis() non-en format' );    # fr has no spec-zero so this should be fr rules
is( $fr->makethis_base( "[quant,_1,en-one,en-other,en-zero]", 123456 ), '123,456 en-other', 'makethis_base() non-en format' );

{
    local $fr->{'cache'}{'makethis_base'} = undef;
    local $fr->{'fallback_locale'} = "fr";
    is( $fr->makethis( "[quant,_1,en-one,en-other,en-zero]", 123456 ), '123 456 en-other', 'makethis() w/ fallback non-en format' );    # fr has no spec-zero so this should be fr rules
    is( $fr->makethis_base( "[quant,_1,en-one,en-other,en-zero]", 123456 ), '123 456 en-other', 'makethis_base() w/ fallback non-en format' );
}

is( $en->makevar( "I am “[_1]”.", 'bob' ), 'I am “bob”.', 'makevar() maketext()s' );
is( $en->makevar( [ "I am “[_1]”.", 'bob' ] ), 'I am “bob”.', 'makevar() maketext()s array ref (only arg)' );
like( $en->makevar( ["I am “[_1]”."], 'bob' ), qr/^ARRAY/, 'makevar() does not maketext() array ref when there are more args' );

for my $lh ( $en, $fr ) {
    my $loc = $lh->get_locales_obj;

    is( $lh->list_and( 1, 2, 3, 4, 5, 6 ), $loc->get_list_and( 1, 2, 3, 4, 5, 6 ), "list_and() has default behavior :: $loc->{'locale'}" );

    my $str;
    {
        local $loc->{'misc'}{'list_quote_mode'} = 'all';
        $str = $loc->get_list_and( 1, 2, 3, 4, 5, 6 );
    }
    is( $lh->list_and_quoted( 1, 2, 3, 4, 5, 6 ), $str, "list_and_quoted() has 'all' behavior :: $loc->{'locale'}" );
}

# cleanup
unlink "$dir/TestApp/Localize/it.pm";
rmdir "$dir/TestApp/Localize";
rmdir "$dir/TestApp";
rmdir $dir;
warn "Could not cleanup $dir" if -d $dir;
