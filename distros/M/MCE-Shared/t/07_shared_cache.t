#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
   use_ok 'MCE::Flow';
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Cache';
}

MCE::Flow::init {
   max_workers => 1
};

tie my %h1, 'MCE::Shared', { module => 'MCE::Shared::Cache' }, max_keys => 100;

is( tied(%h1)->blessed, 'MCE::Shared::Cache', 'shared cache, tied ref' );

tie my $keys, 'MCE::Shared';
tie my $e1,   'MCE::Shared';
tie my $e2,   'MCE::Shared';
tie my $d1,   'MCE::Shared';
tie my $s1,   'MCE::Shared';

tied(%h1)->assign( k1 => 10, k2 => '', k3 => '' );

my $h5 = MCE::Shared->cache( max_keys => 100 );

$h5->set( n => 0 );

sub cmp_array {
   no warnings qw(uninitialized);

   return ok(0, $_[2]) if (ref $_[0] ne 'ARRAY' || ref $_[1] ne 'ARRAY');
   return ok(0, $_[2]) if (@{ $_[0] } != @{ $_[1] });

   for (0 .. $#{ $_[0] }) {
      return ok(0, $_[2]) if ($_[0][$_] ne $_[1][$_]);
   }

   ok(1, $_[2]);
}

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

MCE::Flow::run( sub {
   $h1{k1}  +=  5;
   $h1{k2}  .= '';
   $h1{k3}  .= 'foobar';
   $keys     = join(' ', keys %h1);
   $h5->{n}  = 20;
});

MCE::Flow::finish;

is( $h1{k1}, 15, 'shared cache, check fetch, store' );
is( $h1{k2}, '', 'shared cache, check blank value' );
is( $h1{k3}, 'foobar', 'shared cache, check concatenation' );
is( $keys, 'k3 k2 k1', 'shared cache, check firstkey, nextkey' );
is( $h5->{n}, 20, 'shared cache, check value' );

MCE::Flow::run( sub {
   $e1 = exists $h1{'k2'} ? 1 : 0;
   $d1 = delete $h1{'k2'};
   $e2 = exists $h1{'k2'} ? 1 : 0;
   %h1 = (); $s1 = keys %h1;
   $h1{ret} = [ 'wind', 'air' ];
});

MCE::Flow::finish;

is( $e1,  1, 'shared cache, check exists before delete' );
is( $d1, '', 'shared cache, check delete' );
is( $e2,  0, 'shared cache, check exists after delete' );
is( $s1,  0, 'shared cache, check clear' );
is( $h1{ret}->[1], 'air', 'shared cache, check auto freeze/thaw' );

{
   $h5->clear();

   my @vals = $h5->pipeline(            # ( "a_a", "b_b", "c_c" )
      [ "set", foo => "a_a" ],
      [ "set", bar => "b_b" ],
      [ "set", baz => "c_c" ],
      [ "mget", qw/ foo bar baz / ]
   );

   my $len = $h5->pipeline(             # 3, same as $h5->len
      [ "set", foo => "i_i" ],
      [ "set", bar => "j_j" ],
      [ "set", baz => "k_k" ],
      [ "len" ]
   );

   cmp_array(
      [ @vals ], [ qw/ a_a b_b c_c / ],
      'shared cache, check pipeline list'
   );

   is( $len, 3, 'shared cache, check pipeline scalar' );

   @vals = $h5->pipeline_ex(            # ( "c_c", "b_b", "a_a" )
      [ "set", foo => "c_c" ],
      [ "set", bar => "b_b" ],
      [ "set", baz => "a_a" ]
   );

   cmp_array(
      [ @vals ], [ qw/ c_c b_b a_a / ],
      'shared cache, check pipeline_ex list'
   );
}

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
## https://en.wikipedia.org/wiki/Prayer_of_Saint_Francis
##
## {
##       'Make' => 'me',
##          'a' => 'channel',
##         'of' => 'Your',
##   'peace...' => 'Where',
##   'there\'s' => 'despair',
##         'in' => 'life',
##        'let' => 'me',
##      'bring' => 'hope...',
##      'Where' => 'there'
##         'is' => 'darkness',
##       'only' => 'light...',
##         '16' => '18',
##          '7' => '9',
##          '2' => '3',
## }

$h5->assign( qw(
   Make me a channel of Your peace...
   Where there's despair in life let me bring hope...
   Where there is darkness only light...
   16 18 7 9 2 3
));

## Key order is preserved via LRU rules. Sorting is not required.

## find keys

cmp_array(
   [ $h5->pairs('key =~ /\.\.\./') ], [ qw/ peace... Where / ],
   'shared cache, check find keys =~ match (pairs)'
);
cmp_array(
   [ $h5->keys('key =~ /\.\.\./') ], [ qw/ peace... / ],
   'shared cache, check find keys =~ match (keys)'
);
cmp_array(
   [ $h5->vals('key =~ /\.\.\./') ], [ qw/ Where / ],
   'shared cache, check find keys =~ match (vals)'
);

cmp_array(
   [ $h5->pairs('key !~ /^[a-z]/') ],
   [ qw/ 2 3 7 9 16 18 Where there Make me / ],
   'shared cache, check find keys !~ match (pairs)'
);
cmp_array(
   [ $h5->keys('key !~ /^[a-z]/') ],
   [ qw/ 2 7 16 Where Make / ],
   'shared cache, check find keys !~ match (keys)'
);
cmp_array(
   [ $h5->vals('key !~ /^[a-z]/') ],
   [ qw/ 3 9 18 there me / ],
   'shared cache, check find keys !~ match (vals)'
);

cmp_array(
   [ $h5->pairs('key !~ /^[a-z]/ :AND val =~ /^\d$/') ],
   [ qw/ 2 3 7 9 / ],
   'shared cache, check find keys && match (pairs)'
);
cmp_array(
   [ $h5->keys('key !~ /^[a-z]/ :AND val =~ /^\d$/') ],
   [ qw/ 2 7 / ],
   'shared cache, check find keys && match (keys)'
);
cmp_array(
   [ $h5->vals('key !~ /^[a-z]/ :AND val =~ /^\d$/') ],
   [ qw/ 3 9 / ],
   'shared cache, check find keys && match (vals)'
);

cmp_array(
   [ $h5->pairs('key eq a') ], [ qw/ a channel / ],
   'shared cache, check find keys eq match (pairs)'
);
cmp_array(
   [ $h5->keys('key eq a') ], [ qw/ a / ],
   'shared cache, check find keys eq match (keys)'
);
cmp_array(
   [ $h5->vals('key eq a') ], [ qw/ channel / ],
   'shared cache, check find keys eq match (vals)'
);

is( $h5->pairs('key ne there\'s'), 26, 'shared cache, check find keys ne match (pairs)' );
is( $h5->keys('key ne there\'s'), 13, 'shared cache, check find keys ne match (keys)' );
is( $h5->vals('key ne there\'s'), 13, 'shared cache, check find keys ne match (vals)' );

is( $h5->pairs('key lt bring'),    12, 'shared cache, check find keys lt match (pairs)' );
is( $h5->keys('key lt bring'),     6, 'shared cache, check find keys lt match (keys)' );
is( $h5->vals('key lt bring'),     6, 'shared cache, check find keys lt match (vals)' );

is( $h5->pairs('key le bring'),    14, 'shared cache, check find keys le match (pairs)' );
is( $h5->keys('key le bring'),     7, 'shared cache, check find keys le match (keys)' );
is( $h5->vals('key le bring'),     7, 'shared cache, check find keys le match (vals)' );

is( $h5->pairs('key gt bring'),    14, 'shared cache, check find keys gt match (pairs)' );
is( $h5->keys('key gt bring'),     7, 'shared cache, check find keys gt match (keys)' );
is( $h5->vals('key gt bring'),     7, 'shared cache, check find keys gt match (vals)' );

is( $h5->pairs('key ge bring'),    16, 'shared cache, check find keys ge match (pairs)' );
is( $h5->keys('key ge bring'),     8, 'shared cache, check find keys ge match (keys)' );
is( $h5->vals('key ge bring'),     8, 'shared cache, check find keys ge match (vals)' );

cmp_array(
   [ $h5->pairs('key == 16') ], [ qw/ 16 18 / ],
   'shared cache, check find keys == match (pairs)'
);
cmp_array(
   [ $h5->keys('key == 16') ], [ qw/ 16 / ],
   'shared cache, check find keys == match (keys)'
);
cmp_array(
   [ $h5->vals('key == 16') ], [ qw/ 18 / ],
   'shared cache, check find keys == match (vals)'
);

is( $h5->pairs('key != 16'), 4, 'shared cache, check find keys != match (pairs)' );
is( $h5->keys('key != 16'), 2, 'shared cache, check find keys != match (keys)' );
is( $h5->vals('key != 16'), 2, 'shared cache, check find keys != match (vals)' );

is( $h5->pairs('key <   7'), 2, 'shared cache, check find keys <  match (pairs)' );
is( $h5->keys('key <   7'), 1, 'shared cache, check find keys <  match (keys)' );
is( $h5->vals('key <   7'), 1, 'shared cache, check find keys <  match (vals)' );

is( $h5->pairs('key <=  7'), 4, 'shared cache, check find keys <= match (pairs)' );
is( $h5->keys('key <=  7'), 2, 'shared cache, check find keys <= match (keys)' );
is( $h5->vals('key <=  7'), 2, 'shared cache, check find keys <= match (vals)' );

is( $h5->pairs('key >   2'), 4, 'shared cache, check find keys >  match (pairs)' );
is( $h5->keys('key >   2'), 2, 'shared cache, check find keys >  match (keys)' );
is( $h5->vals('key >   2'), 2, 'shared cache, check find keys >  match (vals)' );

is( $h5->pairs('key >=  2'), 6, 'shared cache, check find keys >= match (pairs)' );
is( $h5->keys('key >=  2'), 3, 'shared cache, check find keys >= match (keys)' );
is( $h5->vals('key >=  2'), 3, 'shared cache, check find keys >= match (vals)' );

## find vals

cmp_array(
   [ $h5->pairs('val =~ /\.\.\./') ],
   [ qw/ only light... bring hope... / ],
   'shared cache, check find vals =~ match (pairs)'
);
cmp_array(
   [ $h5->keys('val =~ /\.\.\./') ],
   [ qw/ only bring / ],
   'shared cache, check find vals =~ match (keys)'
);
cmp_array(
   [ $h5->vals('val =~ /\.\.\./') ],
   [ qw/ light... hope... / ],
   'shared cache, check find vals =~ match (vals)'
);

cmp_array(
   [ $h5->pairs('val !~ /^[a-z]/') ],
   [ qw/ 2 3 7 9 16 18 peace... Where of Your / ],
   'shared cache, check find vals !~ match (pairs)'
);
cmp_array(
   [ $h5->keys('val !~ /^[a-z]/') ],
   [ qw/ 2 7 16 peace... of / ],
   'shared cache, check find vals !~ match (keys)'
);
cmp_array(
   [ $h5->vals('val !~ /^[a-z]/') ],
   [ qw/ 3 9 18 Where Your / ],
   'shared cache, check find vals !~ match (vals)'
);

cmp_array(
   [ $h5->pairs('val =~ /\d/ :OR val eq Where') ],
   [ qw/ 2 3 7 9 16 18 peace... Where / ],
   'shared cache, check find vals || match (pairs)'
);
cmp_array(
   [ $h5->keys('val =~ /\d/ :OR val eq Where') ],
   [ qw/ 2 7 16 peace... / ],
   'shared cache, check find vals || match (keys)'
);
cmp_array(
   [ $h5->vals('val =~ /\d/ :OR val eq Where') ],
   [ qw/ 3 9 18 Where / ],
   'shared cache, check find vals || match (vals)'
);

cmp_array(
   [ $h5->pairs('val eq life') ], [ qw/ in life / ],
   'shared cache, check find vals eq match (pairs)'
);
cmp_array(
   [ $h5->keys('val eq life') ], [ qw/ in / ],
   'shared cache, check find vals eq match (keys)'
);
cmp_array(
   [ $h5->vals('val eq life') ], [ qw/ life / ],
   'shared cache, check find vals eq match (vals)'
);

is( $h5->pairs('val ne despair'), 26, 'shared cache, check find vals ne match (pairs)' );
is( $h5->keys('val ne despair'), 13, 'shared cache, check find vals ne match (keys)' );
is( $h5->vals('val ne despair'), 13, 'shared cache, check find vals ne match (vals)' );

is( $h5->pairs('val lt hope...'), 16, 'shared cache, check find vals lt match (pairs)' );
is( $h5->keys('val lt hope...'),  8, 'shared cache, check find vals lt match (keys)' );
is( $h5->vals('val lt hope...'),  8, 'shared cache, check find vals lt match (vals)' );

is( $h5->pairs('val le hope...'), 18, 'shared cache, check find vals le match (pairs)' );
is( $h5->keys('val le hope...'),  9, 'shared cache, check find vals le match (keys)' );
is( $h5->vals('val le hope...'),  9, 'shared cache, check find vals le match (vals)' );

is( $h5->pairs('val gt hope...'), 10, 'shared cache, check find vals gt match (pairs)' );
is( $h5->keys('val gt hope...'),  5, 'shared cache, check find vals gt match (keys)' );
is( $h5->vals('val gt hope...'),  5, 'shared cache, check find vals gt match (vals)' );

is( $h5->pairs('val ge hope...'), 12, 'shared cache, check find vals ge match (pairs)' );
is( $h5->keys('val ge hope...'),  6, 'shared cache, check find vals ge match (keys)' );
is( $h5->vals('val ge hope...'),  6, 'shared cache, check find vals ge match (vals)' );

cmp_array(
   [ $h5->pairs('val == 9') ], [ qw/ 7 9 / ],
   'shared cache, check find vals == match (pairs)'
);
cmp_array(
   [ $h5->keys('val == 9') ], [ qw/ 7 / ],
   'shared cache, check find vals == match (keys)'
);
cmp_array(
   [ $h5->vals('val == 9') ], [ qw/ 9 / ],
   'shared cache, check find vals == match (vals)'
);

is( $h5->pairs('val !=  9'), 4, 'shared cache, check find vals != match (pairs)' );
is( $h5->keys('val !=  9'), 2, 'shared cache, check find vals != match (keys)' );
is( $h5->vals('val !=  9'), 2, 'shared cache, check find vals != match (vals)' );

is( $h5->pairs('val <   9'), 2, 'shared cache, check find vals <  match (pairs)' );
is( $h5->keys('val <   9'), 1, 'shared cache, check find vals <  match (keys)' );
is( $h5->vals('val <   9'), 1, 'shared cache, check find vals <  match (vals)' );

is( $h5->pairs('val <=  9'), 4, 'shared cache, check find vals <= match (pairs)' );
is( $h5->keys('val <=  9'), 2, 'shared cache, check find vals <= match (keys)' );
is( $h5->vals('val <=  9'), 2, 'shared cache, check find vals <= match (vals)' );

is( $h5->pairs('val >  18'), 0, 'shared cache, check find vals >  match (pairs)' );
is( $h5->keys('val >  18'), 0, 'shared cache, check find vals >  match (keys)' );
is( $h5->vals('val >  18'), 0, 'shared cache, check find vals >  match (vals)' );

is( $h5->pairs('val >= 18'), 2, 'shared cache, check find vals >= match (pairs)' );
is( $h5->keys('val >= 18'), 1, 'shared cache, check find vals >= match (keys)' );
is( $h5->vals('val >= 18'), 1, 'shared cache, check find vals >= match (vals)' );

## find undef

$h5->assign( qw/ spring summer fall winter / );
$h5->set( key => undef );

cmp_array(
   [ $h5->pairs('val eq undef') ], [ 'key', undef ],
   'shared cache, check find vals eq undef (pairs)'
);
cmp_array(
   [ $h5->keys('val eq undef') ], [ 'key' ],
   'shared cache, check find vals eq undef (keys)'
);
cmp_array(
   [ $h5->vals('val eq undef') ], [ undef ],
   'shared cache, check find vals eq undef (vals)'
);

cmp_array(
   [ $h5->pairs('val ne undef') ], [ qw/ fall winter spring summer / ],
   'shared cache, check find vals ne undef (pairs)'
);
cmp_array(
   [ $h5->keys('val ne undef') ], [ qw/ fall spring / ],
   'shared cache, check find vals ne undef (keys)'
);
cmp_array(
   [ $h5->vals('val ne undef') ], [ qw/ winter summer / ],
   'shared cache, check find vals ne undef (vals)'
);

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

## Key order is preserved via LRU rules. Sorting is not required.

$h5->clear(); $h5->mset( 0, 'over', 1, 'the', 2, 'rainbow', 3, 77 );

cmp_array(
   [ $h5->pairs() ], [ qw/ 3 77 2 rainbow 1 the 0 over / ],
   'shared cache, check mset'
);
cmp_array(
   [ $h5->mget(0, 2) ], [ qw/ over rainbow / ],
   'shared cache, check mget'
);

cmp_array(
   [ $h5->keys() ], [ qw/ 2 0 3 1 / ],
   'shared cache, check keys'
);
cmp_array(
   [ $h5->vals() ], [ qw/ rainbow over 77 the / ],
   'shared cache, check values'
);
cmp_array(
   [ $h5->pairs() ], [ qw/ 2 rainbow 0 over 3 77 1 the / ],
   'shared cache, check pairs'
);

is( $h5->len(), 4, 'shared cache, check length' );
is( $h5->len(2), 7, 'shared cache, check length( key )' );
is( $h5->incr(3), 78, 'shared cache, check incr' );
is( $h5->decr(3), 77, 'shared cache, check decr' );
is( $h5->incrby(3, 4), 81, 'shared cache, check incrby' );
is( $h5->decrby(3, 4), 77, 'shared cache, check decrby' );
is( $h5->getincr(3), 77, 'shared cache, check getincr' );
is( $h5->get(3), 78, 'shared cache, check value after getincr' );
is( $h5->getdecr(3), 78, 'shared cache, check getdecr' );
is( $h5->get(3), 77, 'shared cache, check value after getdecr' );
is( $h5->append(3, 'ba'), 4, 'shared cache, check append' );
is( $h5->get(3), '77ba', 'shared cache, check value after append' );
is( $h5->getset('3', '77bc'), '77ba', 'shared cache, check getset' );
is( $h5->get(3), '77bc', 'shared cache, check value after getset' );

$h5->assign( 0, 'over', 1, 'the', 2, 'rainbow', 3, 77 );

my $iter  = $h5->iterator();
my $count = 0;
my @check;

while ( my ($key, $val) = $iter->() ) {
   push @check, $key, $val;
   $count++;
}

$iter = $h5->iterator();

while ( my $val = $iter->() ) {
   push @check, $val;
   $count++;
}

is( $count, 8, 'shared cache, check iterator count' );

cmp_array(
   [ @check ], [ qw/ 3 77 2 rainbow 1 the 0 over 77 rainbow the over / ],
   'shared cache, check iterator results'
);

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

my @list;

$h5->assign( 0, 'over', 1, 'the', 2, 'rainbow', 3, 77 );

while ( my $val = $h5->next ) { push @list, $val; }

cmp_array(
   [ @list ], [ qw/ 77 rainbow the over / ],
   'shared cache, check next'
);

@list = (); $h5->rewind('val =~ /[a-z]/');

while ( my ($key, $val) = $h5->next ) { push @list, $key, $val; }

cmp_array(
   [ @list ], [ qw/ 2 rainbow 1 the 0 over / ],
   'shared cache, check rewind 1'
);

@list = (); $h5->rewind('key =~ /\d/');

while ( my $val = $h5->next ) { push @list, $val; }

cmp_array(
   [ @list ], [ qw/ 77 rainbow the over / ],
   'shared cache, check rewind 2'
);

@list = (); $h5->rewind(qw/ 1 2 /);

while ( my $val = $h5->next ) { push @list, $val; }

cmp_array(
   [ sort @list ], [ sort qw/ rainbow the / ],
   'shared cache, check rewind 3'
);

is( $h5->mexists(qw/ 0 2 3 /),  1, 'shared cache, check mexists 1' );
is( $h5->mexists(qw/ 0 8 3 /), '', 'shared cache, check mexists 2' );

is( $h5->assign( qw/ 4 four 5 five 6 six / ), 3, 'shared cache, check assign 1' );

cmp_array(
   [ sort $h5->vals() ], [ sort qw/ four five six / ],
   'shared cache, check assign 2'
);

is( $h5->mdel(qw/ 4 5 6 /), 3, 'shared cache, check mdel' );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

## https://sacred-texts.com/cla/usappho/sph02.htm (II)

my $sappho_text =
  "ἀλλά τυίδ᾽ ἔλθ᾽, αἴποτα κἀτέρωτα
   τᾶσ ἔμασ αύδωσ αἴοισα πήλγι
   ἔκλυεσ πάτροσ δὲ δόμον λίποισα
   χρύσιον ἦλθεσ.";

my $translation =
  "Whenever before thou has hearkened to me--
   To my voice calling to thee in the distance,
   And heeding, thou hast come, leaving thy father's
   Golden dominions.";

$h5->assign( text => $sappho_text );
is( $h5->get("text"), $sappho_text, 'shared cache, check unicode assign' );

$h5->clear, $h5->set( text => $sappho_text );
is( $h5->get("text"), $sappho_text, 'shared cache, check unicode set' );
is( $h5->len("text"), length($sappho_text), 'shared cache, check unicode len' );

$h5->clear, $h5->set( "ἀθάνατῳ", $sappho_text );
is( $h5->get("ἀθάνατῳ"), $sappho_text, 'shared cache, check unicode get' );
is( $h5->exists("ἀθάνατῳ"), 1, 'shared cache, check unicode exists' );

my @keys = $h5->keys;
my @vals = $h5->vals;

is( $keys[0], "ἀθάνατῳ", 'shared cache, check unicode keys' );
is( $vals[0], $sappho_text, 'shared cache, check unicode vals' );

cmp_array(
   [ $h5->pairs('key =~ /ἀθάνατῳ/') ], [ "ἀθάνατῳ", $sappho_text ],
   'shared cache, check unicode find keys =~ match (pairs)'
);
cmp_array(
   [ $h5->pairs('val =~ /ἔκλυεσ/') ], [ "ἀθάνατῳ", $sappho_text ],
   'shared cache, check unicode find values =~ match (pairs)'
);

my $length = $h5->append("ἀθάνατῳ", "Ǣ");
is( $h5->get("ἀθάνατῳ"), $sappho_text . "Ǣ", 'shared cache, check unicode append' );
is( $length, length($sappho_text) + 1, 'shared cache, check unicode length' );

done_testing;

