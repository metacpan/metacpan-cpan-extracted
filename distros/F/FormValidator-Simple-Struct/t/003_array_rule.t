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
# no nest scalar 
ok $v->check("aaa" , ["NOT_BLANK","ASCII"]);
ok $v->check("111" , ["NOT_BLANK","INT"]);

# no nest scalar exception
ok !$v->check("aaa" , ["NOT_BLANK","INT"]);
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param';
ok $v->check("111" , ["NOT_BLANK","ASCII"]);
ok !$v->has_error;

# arrayref 
ok $v->check([111 , 1222, 333] , [["NOT_BLANK","INT"]]);
ok !$v->has_error;
# arrayref exception
ok !$v->check([qw/aaa 222 ccc/] , [["NOT_BLANK","INT"]]);
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->[0]';
is $v->get_error->[1]{message},INVALID('INT');
is $v->get_error->[1]{position},'$param->[2]';
ok !$v->get_error->[2];

# hash ref 
ok $v->check({ hoge => 'fuga'},{hoge => ["NOT_BLANK","ASCII"]});
ok $v->check({ hoge => 111},{hoge => ["NOT_BLANK","ASCII"]});
ok $v->check({ hoge => 111},{hoge => ["NOT_BLANK","INT"]});

# hash ref exception
ok !$v->check({ hoge => 'fuga'},{hoge => ["NOT_BLANK","INT"]});
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->{hoge}';

# hash ref multivalue
ok $v->check({hoge => 'fuga' , fuga => "fuga" },{hoge => ["NOT_BLANK","ASCII"] , fuga=> ["NOT_BLANK","ASCII"]});
ok $v->check({hoge => "fuga" , fuga => "fuga" },{hoge => ["NOT_BLANK","ASCII"] , fuga => ["NOT_BLANK","ASCII"]});
ok $v->check({hoge => 111 , fuga => "fuga"},{hoge => ["NOT_BLANK","INT"] , fuga => ["NOT_BLANK","ASCII"]});
ok !$v->check({hoge => "" , fuga => "fuga"},{hoge => ["NOT_BLANK","INT"] , fuga => ["NOT_BLANK","ASCII"]});

ok $v->check({hoge => {fuga => "fuga"}},{hoge => {fuga => ["NOT_BLANK","ASCII"]}});
ok !$v->check({hoge => {fuga => ""}},{hoge => {fuga => ["NOT_BLANK","ASCII"]}});
ok $v->check({hoge => [{fuga => "fuga"}]},{hoge => [{fuga => ["NOT_BLANK","ASCII"]}]});
ok !$v->check({hoge => [{fuga => ""}]},{hoge => [{fuga => ["NOT_BLANK","ASCII"]}]});


ok !$v->check({hoge => [{fuga => ""}]},{hoge => {fuga => ["NOT_BLANK","ASCII"]}});
ok !$v->check({hoge => "fuga"},{hoge => [{fuga => ["NOT_BLANK","ASCII"]}]});
ok !$v->check({hoge => [{fuga => ""}]},["NOT_BLANK","ASCII"]);


# hash ref multivalue exception
ok !$v->check({hoge => "fuga" , fuga => "fuga" },{hoge => ["NOT_BLANK","INT"] , fuga => ["NOT_BLANK","INT"]});
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
ok $v->check({hoge => [qw/111 222 333/] , fuga => "fuga" },{hoge => ['INT'] , fuga=> ["NOT_BLANK","ASCII"]});
ok $v->check({hoge =>  {hoge => "hpge"} , fuga => "fuga" },{hoge => {hoge => ["NOT_BLANK","ASCII"]}, fuga=> ["NOT_BLANK","ASCII"]});
ok $v->check({hoge =>  {hoge => 111} , fuga => "fuga" },{hoge => {hoge => ["NOT_BLANK","INT"]}, fuga=> ["NOT_BLANK","ASCII"]});

# nested ref exception
ok !$v->check({hoge => [qw/aaa vvv ccc/] , fuga => "fuga" },{hoge => ['INT'] , fuga=> ["NOT_BLANK","ASCII"]});

ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->{hoge}->[0]';
is $v->get_error->[1]{message},INVALID('INT');
is $v->get_error->[1]{position},'$param->{hoge}->[1]';
is $v->get_error->[2]{message},INVALID('INT');
is $v->get_error->[2]{position},'$param->{hoge}->[2]';

ok !$v->check({hoge =>  {hoge => "hpge"} , fuga => "fuga" },{hoge => {hoge => ["NOT_BLANK","INT"]}, fuga=> ["NOT_BLANK","ASCII"]});
ok !$v->check({hoge =>  {hoge => 111} , fuga => "fuga" },{hoge => {hoge => ["NOT_BLANK","INT"]}, fuga=> ["NOT_BLANK","INT"]});

# hash ref value is not exist
ok !$v->check({fuga => "fuga" },{hoge => ["NOT_BLANK"] , fuga=> ["NOT_BLANK"]});
ok !$v->check({},{hoge => ["NOT_BLANK"] , fuga=> ["NOT_BLANK"]});
ok !$v->check({hoge => 'hoge' , },{hoge => ["NOT_BLANK"] , fuga=> ["NOT_BLANK"]});

ok $v->check({id => 1 ,used_skill => [qw/1 2 3/]}, {id => ['INT'] ,used_skill => [['INT' , 'NOT_BLANK']]});
ok $v->check({id => 1 ,used_skill => []}, {id => ['INT'] ,used_skill => [['INT' , 'NOT_BLANK']]});
ok !$v->check({id => 1 ,}, {id => ['INT'] ,used_skill => [['INT' , 'NOT_BLANK']]});

done_testing;
