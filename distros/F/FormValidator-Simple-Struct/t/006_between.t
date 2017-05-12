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

ok $v->check({hoge =>  8 },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]]});
ok $v->check({hoge =>  15 },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]]});
ok $v->check({hoge =>  1 },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]]});
ok !$v->check({hoge =>  16 },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]]});
ok !$v->check({hoge =>  0 },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]]});

ok $v->check({hoge =>  4  },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 4]]});
ok !$v->check({hoge => 4  },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 3]]});
ok !$v->check({hoge => 4  },{hoge=> ["INT","NOT_BLANK" , ['BETWEEN' , 5]]});
ok $v->check({},{hoge=> ["INT", ['BETWEEN' , 5]]});
ok !$v->check({},{hoge=> ["INT", 'NOT_BLANK',['BETWEEN' , 5]]});

# fuga : 1 ~ 10
ok $v->check({hoge => 10 , fuga => 1} , {
        hoge => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]] , 
        fuga => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , "hoge"]] , 
    });
ok $v->check({hoge => 10 , fuga => 10} , {
        hoge => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]] , 
        fuga => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , "hoge"]] , 
    });
ok !$v->check({hoge => 10 , fuga => 20} , {
        hoge => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]] , 
        fuga => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , "hoge"]] , 
    });
ok !$v->check({hoge => 10 , fuga => 0} , {
        hoge => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , 15]] , 
        fuga => ["INT","NOT_BLANK" , ['BETWEEN' , 1 , "hoge"]] , 
    });
done_testing;
