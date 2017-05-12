use 5.008001;
use utf8;
use strict;
use warnings;

use Test::More 0.92;

use lib 't/lib';
use t_LKT_Util;
use Locale::KeyedText;

t_LKT_Util->message( 'testing new_translator() and most Translator object methods' );

my ($did, $should, $trn1);

eval { t_LKT_Util->new_translator( [q{e}], undef ) };
ok( $@, "t_LKT_Util->new_translator( [q{e}], undef ) died" );

eval { t_LKT_Util->new_translator( undef, [q{e}] ) };
ok( $@, "t_LKT_Util->new_translator( undef, [q{e}] ) died" );

eval { t_LKT_Util->new_translator( [q{e}], [] ) };
ok( $@, "t_LKT_Util->new_translator( [q{e}], [] ) died" );

eval { t_LKT_Util->new_translator( [], [q{e}] ) };
ok( $@, "t_LKT_Util->new_translator( [], [q{e}] ) died" );

$trn1 = t_LKT_Util->new_translator( q{e}, [q{e}] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( q{e}, [q{e}] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: e; MEMBERS: e';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( [q{e}], q{e} );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( [q{e}], q{e} ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: e; MEMBERS: e';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( '0', ['0'] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( '0', ['0'] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: 0; MEMBERS: 0';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( ['0'], '0' );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( ['0'], '0' ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: 0; MEMBERS: 0';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( '0', [q{e}] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( '0', [q{e}] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: 0; MEMBERS: e';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( 'zZ9', [q{e}] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( 'zZ9', [q{e}] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: zZ9; MEMBERS: e';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( ['zZ9'], [q{e}] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( ['zZ9'], [q{e}] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: zZ9; MEMBERS: e';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( ['zZ9','aaa'], [q{e}] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( ['zZ9','aaa'], [q{e}] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: zZ9, aaa; MEMBERS: e';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( [q{e}], '0' );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( [q{e}], '0' ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: e; MEMBERS: 0';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( [q{e}], 'zZ9' );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( [q{e}], 'zZ9' ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: e; MEMBERS: zZ9';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( [q{e}], ['zZ9'] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( [q{e}], ['zZ9'] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: e; MEMBERS: zZ9';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( [q{e}], ['zZ9','aaa'] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( [q{e}], ['zZ9','aaa'] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: e; MEMBERS: zZ9, aaa';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( ['goo','har'], ['wer','thr'] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( ['goo','har'], ['wer','thr'] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: goo, har; MEMBERS: wer, thr';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

$did = t_LKT_Util->serialize( $trn1->get_set_names() );
$should = q|[ 'goo', 'har', ], |;
is( $did, $should, "on init trn1->get_set_names() returns '$did'" );

$did = t_LKT_Util->serialize( $trn1->get_member_names() );
$should = q|[ 'wer', 'thr', ], |;
is( $did, $should, "on init trn1->get_member_names() returns '$did'" );

$trn1 = t_LKT_Util->new_translator( ['go::o','::har'], ['w::er','thr::'] );
isa_ok( $trn1, 'Locale::KeyedText::Translator',
    q|trn1 = new_translator( ['go::o','::har'], ['w::er','thr::'] ) ret TRN obj| );
$did = $trn1->as_debug_str();
$should = 'SETS: go::o, ::har; MEMBERS: w::er, thr::';
is( $did, $should, "on init trn1->as_debug_str() returns '$did'" );

done_testing();

1;
