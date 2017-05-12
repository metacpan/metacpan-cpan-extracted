#!perl -w
use strict;
use Test::More;

use FormValidator::Simple::Struct;

# test FormValidator::Simple::Struct here

sub HASHREF {'excepted hash ref'};
sub ARRAYREF {'excepted array ref'};
sub REF {'excepted ref'};
sub INVALID{'excepted ' . $_[0]};

my $v = FormValidator::Simple::Struct->new();

ok $v->check({hoge =>  "hoge" },{hoge=> ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 15]]});
ok !$v->check({hoge =>  "hogehogehogehoge" },{hoge=> ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 15]]});

ok $v->check({hoge =>  "hoge" },{hoge=> ["ASCII","NOT_BLANK" , ['LENGTH' , 4]]});
ok !$v->check({hoge =>  "hoge" },{hoge=> ["ASCII","NOT_BLANK" , ['LENGTH' , 3]]});
ok !$v->check({hoge =>  "hoge" },{hoge=> ["ASCII","NOT_BLANK" , ['LENGTH' , 5]]});
ok $v->check({},{hoge=> ["ASCII", ['LENGTH' , 5]]});
ok $v->check({ hoge=> ""},{hoge=> ["ASCII", ['LENGTH' , 5]]});
ok !$v->check({},{hoge=> ["ASCII", 'NOT_BLANK', ['LENGTH' , 5]]});

ok $v->check("hoge" ,["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 15]]);

done_testing;
