#!perl -w
use strict;
use Test::More;

use FormValidator::Simple::Struct;
use Hash::MultiValue;

# test FormValidator::Simple::Struct here

sub HASHREF {'excepted hash ref'};
sub ARRAYREF {'excepted array ref'};
sub REF {'excepted ref'};
sub INVALID{'excepted ' . $_[0]};

my $v = FormValidator::Simple::Struct->new();
# no nest scalar 
ok $v->check("aaa" , ["NOT_BLANK","ASCII"]);
ok $v->check("111" , ["NOT_BLANK","INT"]);

my $hash = Hash::MultiValue->new(
    hoge => "fuga",
);

# hash ref 
ok $v->check($hash ,{hoge => ["NOT_BLANK","ASCII"]});

$hash = Hash::MultiValue->new(
    hoge => 111,
 );

ok $v->check({ hoge => 111},{hoge => ["NOT_BLANK","ASCII"]});
ok $v->check({ hoge => 111},{hoge => ["NOT_BLANK","INT"]});

# hash ref exception
$hash = Hash::MultiValue->new(
    hoge => "fuga",
);
ok !$v->check($hash,{hoge => ["NOT_BLANK","INT"]});
ok $v->has_error;
is $v->get_error->[0]{message},INVALID('INT');
is $v->get_error->[0]{position},'$param->{hoge}';

done_testing;
