#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;
use charnames ':full';


my $class = 'Grapheme::Ngram';

use_ok($class);

my $object = new_ok($class);

ok($object->new());
ok($object->new(1,2));
ok($object->new({}));
ok($object->new({a => 1}));

ok($class->new());

is(scalar(@{$object->_tokenize('')}),0,'tokenize empty default 1-gram');

is(scalar(@{$object->ngram()}),0,'undef default 1-gram');
is(scalar(@{$object->ngram('')}),0,'empty default 1-gram');
is(scalar(@{$object->ngram('a','b')}),1,'a default, invalid width');


is(scalar(@{$object->ngram('a')}),1,'a default 1-gram');
is(scalar(@{$object->ngram('a',1)}),1,'a,1 1-gram');
is(scalar(@{$object->ngram('aa',1)}),2,'aa,1 1-gram');

is(scalar(@{$object->ngram('',2)}),0,'empty,2 2-gram');
is(scalar(@{$object->ngram('aa',3)}),1,'aa,3 2-gram');

is(scalar(@{$object->ngram('aa',2)}),1,'aa,2 2-gram');
is(scalar(@{$object->ngram('aaa',2)}),2,'aa,2 2-gram');

is(scalar(@{$object->ngram(
  "a\N{COMBINING DIAERESIS}a",
  2,
)}),1,'combining diaeresis,2 2-gram');

is(scalar(@{$object->ngram(
  "\N{LATIN SMALL LETTER A WITH DIAERESIS}a",
  2,
)}),1,'composed a-diaeresis,2 2-gram');

is(scalar(@{$object->ngram(
  "\N{LATIN SMALL LETTER A WITH DIAERESIS}\N{COMBINING DOT BELOW}a",
  2,
)}),1,'composed a-diaeresis+dot below,2 2-gram');

my $test_ngram = 
$object->ngram(
  "\N{LATIN SMALL LETTER A WITH DIAERESIS}\N{COMBINING DOT BELOW}ab",
  2);

is_deeply(
  $test_ngram,
  [ "\N{LATIN SMALL LETTER A WITH DIAERESIS}\N{COMBINING DOT BELOW}a",
    "ab",
  ],
  'deeply a-diaeresis+dot below,2 2-gram'
);

done_testing;
