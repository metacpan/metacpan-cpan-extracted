#!perl -w
use strict;
use Test::More;
use Test::Exception;

use FormValidator::Simple::Struct;

# test FormValidator::Simple::Struct here

sub HASHREF {'excepted hash ref'};
sub ARRAYREF {'excepted array ref'};
sub REF {'excepted ref'};
sub INVALID{'excepted ' . $_[0]};

my $v = FormValidator::Simple::Struct->new();
# no nest scalar 
ok $v->check("aaa" , "ASCII");
ok $v->check("111" , "INT");

# no nest scalar exception
ok !$v->check("aaa" , "INT");
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param';
ok $v->check("111" , "ASCII");
ok !$v->has_error;

# arrayref 
ok $v->check([111 , 1222, 333] , ["INT"]);
ok $v->check([111 , 1222, 333] , ["INT" , "INT" , "INT"]);
ok $v->check([111 , 1222, "aaa"] , ["INT" , "INT" , "ASCII"]);
ok $v->check([111 , 1222, ""] , ["INT" , "INT" , "ASCII"]);
ok !$v->has_error;
ok !$v->check([111 , 1222, ""] , ["INT" , "INT" , ["ASCII",'NOT_BLANK']]);
ok !$v->check([111 , 1222, ""] , ["INT" , "INT" , ["ASCII",['LENGTH' , 1, 5] ,'NOT_BLANK']]);
ok !$v->check([111 , 1222, "aaa"] , ["INT" , "INT" , "ASCII" , "INT"]);
ok !$v->check([111 , 1222, "aaa" , "aaa"] , ["INT" , "INT" , "ASCII"]);
ok $v->has_error;

# arrayref exception
ok !$v->check([qw/aaa 222 ccc/] , ["INT"]);
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->[0]';
is $v->get_error->[1]{message},INVALID('INT');
is $v->get_error->[1]{position},'$param->[2]';
ok !$v->get_error->[2];


# hash in array
ok $v->check([{id => 111,id2=> 22.2 },{id=> 1222 , id2=> 1.11},{id=> 333 , id2=> 44.44}] , [{id =>"INT",id2 => "DECIMAL"}]);
ok !$v->check([{id => "1aaa1" },{id=>"aaa1222" },{id=> "333"}] , [{id =>"INT"}]);

ok $v->check([
    {
        id => 111,id2=> [{id=> 22}]
    }] , 
    [{
        id =>"INT",id2 => [{id => ["INT"]}]
    }]);

# this is Specification
ok $v->check([] , [{id =>"INT"}]);
ok $v->check([] , [[]]);

# hash ref 
ok $v->check({ hoge => 'fuga'},{hoge => "ASCII"});
ok $v->check({ hoge => 111},{hoge => "ASCII"});
ok $v->check({ hoge => 111},{hoge => "INT"});

# hash ref exception
ok !$v->check({ hoge => 'fuga'},{hoge => "INT"});
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->{hoge}';

# hash ref multivalue
ok $v->check({hoge => 'fuga' , fuga => "fuga" },{hoge => "ASCII" , fuga=> "ASCII"});
ok $v->check({hoge => "fuga" , fuga => "fuga" },{hoge => "ASCII" , fuga => "ASCII"});
ok $v->check({hoge => 111 , fuga => "fuga"},{hoge => "INT" , fuga => "ASCII"});

# hash ref multivalue exception
ok !$v->check({hoge => "fuga" , fuga => "fuga" },{hoge => "INT" , fuga => "INT"});
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[1]{message},INVALID('INT');

# hash randomization
if($v->get_error->[0]{position} eq '$param->{fuga}'){
    is $v->get_error->[0]{position},'$param->{fuga}';
    is $v->get_error->[1]{position},'$param->{hoge}';
}else{
    is $v->get_error->[0]{position},'$param->{hoge}';
    is $v->get_error->[1]{position},'$param->{fuga}';
}

# nested ref
ok $v->check({hoge => [qw/111 222 333/] , fuga => "fuga" },{hoge => ['INT'] , fuga=> "ASCII"});
ok $v->check({hoge =>  {hoge => "hpge"} , fuga => "fuga" },{hoge => {hoge => "ASCII"}, fuga=> "ASCII"});
ok $v->check({hoge =>  {hoge => 111} , fuga => "fuga" },{hoge => {hoge => "INT"}, fuga=> "ASCII"});

# nested ref exception
ok !$v->check({hoge => [qw/aaa vvv ccc/] , fuga => "fuga" },{hoge => ['INT'] , fuga=> "ASCII"});

ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->{hoge}->[0]';
is $v->get_error->[1]{message},INVALID('INT');
is $v->get_error->[1]{position},'$param->{hoge}->[1]';
is $v->get_error->[2]{message},INVALID('INT');
is $v->get_error->[2]{position},'$param->{hoge}->[2]';

ok !$v->check({hoge =>  {hoge => "hpge"} , fuga => "fuga" },{hoge => {hoge => "INT"}, fuga=> "ASCII"});
ok !$v->check({hoge =>  {hoge => 111} , fuga => "fuga" },{hoge => {hoge => "INT"}, fuga=> "INT"});

# length exception
ok !$v->check({fuga => "fuga" },{fuga=> [["LENGTH" , 5 , 10]]});
ok $v->has_error;
is $v->get_error->[0]{message},'LENGTH IS WRONG';
is $v->get_error->[0]{min_value},5;
is $v->get_error->[0]{max_value},10;

# between exception
ok !$v->check({fuga => "3" },{fuga=> [["BETWEEN" , 5 , 10]]});
ok $v->has_error;
is $v->get_error->[0]{message},'BETWEEN IS WRONG';
is $v->get_error->[0]{min_value},5;
is $v->get_error->[0]{max_value},10;

done_testing;
