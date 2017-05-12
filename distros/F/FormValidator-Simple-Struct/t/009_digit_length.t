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

ok $v->check({hoge =>  "123456789.123" },{hoge=> [['DIGIT_LENGTH' , 9 , 3]]});

ok !$v->check({hoge =>  "1123456789.123" },{hoge=> [['DIGIT_LENGTH' , 9 , 3]]});
ok !$v->check({hoge =>  "123456789.1123" },{hoge=> [['DIGIT_LENGTH' , 9 , 3]]});

done_testing;
