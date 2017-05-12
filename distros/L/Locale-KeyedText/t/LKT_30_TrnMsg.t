use 5.008001;
use utf8;
use strict;
use warnings;

use Test::More 0.92;

use lib 't/lib';
use t_LKT_Util;
use Locale::KeyedText;

t_LKT_Util->message( 'testing Translator->translate_message() method' );

my $AS = 't_LKT_A_L_';
my $BS = 't_LKT_B_L_';
my $CS = 't_LKT_C_L_';

my ($did, $should, $msg1, $msg2, $msg3, $trn1, $trn2, $trn3, $trn4, $trn11);

# First test that anything does or doesn't work, and test variable substitution.

$msg1 = t_LKT_Util->new_message( 'one' );
pass( q|msg1 = new_message( 'one' ) contains '| . $msg1->as_debug_str() . q|'| );

$msg2 = t_LKT_Util->new_message( 'one', {'spoon'=>'lift','fork'=>'0'} );
pass( q|msg2 = new_message( 'one', {'spoon'=>'lift','fork'=>'0'} ) contains '| . $msg2->as_debug_str() . q|'| );

$msg3 = t_LKT_Util->new_message( 'one', {'spoon'=> undef,'fork'=>q{}} );
pass( q|msg3 = new_message( 'one', {'spoon'=> undef,'fork'=>q{}} ) contains '| . $msg3->as_debug_str() . q|'| );

$trn1 = t_LKT_Util->new_translator( [$AS],['Eng'] );
pass( "trn1 = new_translator( [$AS],['Eng'] ) contains '" . $trn1->as_debug_str() . q|'| );

$trn2 = t_LKT_Util->new_translator( [$BS],['Eng'] );
pass( "trn2 = new_translator( [$BS],['Eng'] ) contains '" . $trn2->as_debug_str() . q|'| );

eval { $trn1->translate_message( 'foo' ) };
ok( $@, "trn1->translate_message( 'foo' ) died" );

eval { $trn1->translate_message( 'Locale::KeyedText::Message' ) };
ok( $@, "trn1->translate_message( 'Locale::KeyedText::Message' ) died" );

$did = $trn1->translate_message( $msg1 );
$should = 'AE - word <fork> < fork > <spoon> <<fork>>';
is( $did, $should, "trn1->translate_message( msg1 ) returns '$did'" );

$did = $trn1->translate_message( $msg2 );
$should = 'AE - word 0 < fork > lift <0>';
is( $did, $should, "trn1->translate_message( msg2 ) returns '$did'" );

$did = $trn1->translate_message( $msg3 );
$should = 'AE - word  < fork >  <>';
is( $did, $should, "trn1->translate_message( msg3 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn2->translate_message( $msg2 ) );
$should = 'undef, ';
is( $did, $should, "trn2->translate_message( msg2 ) returns '$did'" );

# Next test multiple module searching.

$msg1 = t_LKT_Util->new_message( 'one', {'spoon'=>'lift','fork'=>'poke'} );
pass( q|msg1 = new_message( 'one', {'spoon'=>'lift','fork'=>'poke'} ) contains '| . $msg1->as_debug_str() . q|'| );

$msg2 = t_LKT_Util->new_message( 'two' );
pass( q|msg2 = new_message( 'two' ) contains '| . $msg2->as_debug_str() . q|'| );

$msg3 = t_LKT_Util->new_message( 'three', { 'knife'=>'sharp' } );
pass( q|msg3 = new_message( 'three', { 'knife'=>'sharp' } ) contains '| . $msg3->as_debug_str() . q|'| );

$trn1 = t_LKT_Util->new_translator( [$AS,$BS],['Eng','Fre'] );
pass( "trn1 = new_translator( [$AS],['Eng'] ) contains '" . $trn1->as_debug_str() . q|'| );

$trn2 = t_LKT_Util->new_translator( [$AS,$BS],['Fre','Eng'] );
pass( "trn2 = new_translator( [$AS],['Eng'] ) contains '" . $trn2->as_debug_str() . q|'| );

$trn3 = t_LKT_Util->new_translator( [$BS,$AS],['Eng','Fre'] );
pass( "trn3 = new_translator( [$AS],['Eng'] ) contains '" . $trn3->as_debug_str() . q|'| );

$trn4 = t_LKT_Util->new_translator( [$BS,$AS],['Fre','Eng'] );
pass( "trn4 = new_translator( [$AS],['Eng'] ) contains '" . $trn4->as_debug_str() . q|'| );

$did = t_LKT_Util->serialize( $trn1->translate_message( $msg1 ) );
$should = q|'AE - word poke < fork > lift <poke>', |;
is( $did, $should, "trn1->translate_message( msg1 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn1->translate_message( $msg2 ) );
$should = q|'AE - sky pie rye', |;
is( $did, $should, "trn1->translate_message( msg2 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn1->translate_message( $msg3 ) );
$should = q|'BE - eat sharp', |;
is( $did, $should, "trn1->translate_message( msg3 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn2->translate_message( $msg1 ) );
$should = q|'AF - word poke < fork > lift <poke>', |;
is( $did, $should, "trn2->translate_message( msg1 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn2->translate_message( $msg2 ) );
$should = q|'AF - sky pie rye', |;
is( $did, $should, "trn2->translate_message( msg2 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn2->translate_message( $msg3 ) );
$should = q|'BF - eat sharp', |;
is( $did, $should, "trn2->translate_message( msg3 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn3->translate_message( $msg1 ) );
$should = q|'AE - word poke < fork > lift <poke>', |;
is( $did, $should, "trn3->translate_message( msg1 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn3->translate_message( $msg2 ) );
$should = q|'BE - sky pie rye', |;
is( $did, $should, "trn3->translate_message( msg2 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn3->translate_message( $msg3 ) );
$should = q|'BE - eat sharp', |;
is( $did, $should, "trn3->translate_message( msg3 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn4->translate_message( $msg1 ) );
$should = q|'AF - word poke < fork > lift <poke>', |;
is( $did, $should, "trn4->translate_message( msg1 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn4->translate_message( $msg2 ) );
$should = q|'BF - sky pie rye', |;
is( $did, $should, "trn4->translate_message( msg2 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn4->translate_message( $msg3 ) );
$should = q|'BF - eat sharp', |;
is( $did, $should, "trn4->translate_message( msg3 ) returns '$did'" );

$trn11 = t_LKT_Util->new_translator( [$CS],['Eng'] );
pass( "trn11 = new_translator( [$CS],['Eng'] ) contains '" . $trn11->as_debug_str() . q|'| );

$did = t_LKT_Util->serialize( $trn11->translate_message( $msg1 ) );
$should = q|'poke shore lift', |;
is( $did, $should, "trn11->translate_message( msg1 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn11->translate_message( $msg2 ) );
$should = q|'sky fly high', |;
is( $did, $should, "trn11->translate_message( msg2 ) returns '$did'" );

$did = t_LKT_Util->serialize( $trn11->translate_message( $msg3 ) );
$should = q|'sharp zot', |;
is( $did, $should, "trn11->translate_message( msg3 ) returns '$did'" );

done_testing();

package t_LKT_C_L_Eng;

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    my $text_strings = {
        'one' => q[<fork> shore <spoon>],
        'two' => q[sky fly high],
        'three' => q[<knife> zot],
    };
    return $text_strings->{$msg_key};
}

1;
