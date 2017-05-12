#!perl -w
use strict;
use Test::More;
use utf8;

use FormValidator::Simple::Struct;

# test FormValidator::Simple::Struct here

sub HASHREF {'excepted hash ref'};
sub ARRAYREF {'excepted array ref'};
sub REF {'excepted ref'};
sub INVALID{'excepted ' . $_[0]};

my $v = FormValidator::Simple::Struct->new();

ok !$v->check({hoge =>  "あ　あ" },{hoge=> [['CHARTYPE' , 'HIRAGANA']]});
ok !$v->check({hoge =>  "　あ" },{hoge=> [['CHARTYPE' , 'HIRAGANA']]});
ok !$v->check({hoge =>  "あ　" },{hoge=> [['CHARTYPE' , 'HIRAGANA']]});
ok !$v->check({hoge =>  "　" },{hoge=> [['CHARTYPE' , 'HIRAGANA']]});

ok $v->check({hoge =>  "あ　あ" },{hoge=> [['ALLOWCHARACTER' , 'SPACE'],  ['CHARTYPE' , 'HIRAGANA']]});
ok $v->check({hoge =>  "　あ" },{hoge=> [['ALLOWCHARACTER' , 'SPACE'],  ['CHARTYPE' , 'HIRAGANA']]});
ok $v->check({hoge =>  "あ　" },{hoge=> [['ALLOWCHARACTER' , 'SPACE'],  ['CHARTYPE' , 'HIRAGANA']]});
ok $v->check({hoge =>  "　" },{hoge=> [['ALLOWCHARACTER' , 'SPACE'],  ['CHARTYPE' , 'HIRAGANA']]});
ok !$v->check({hoge =>  "　" },{hoge=> [['ALLOWCHARACTER' , 'SPACE'], 'NOT_BLANK' ,  ['CHARTYPE' , 'HIRAGANA']]});
ok $v->check({hoge =>  "　" },{hoge=> ['NOT_BLANK' , ['ALLOWCHARACTER' , 'SPACE'], ['CHARTYPE' , 'HIRAGANA']]});

done_testing;
