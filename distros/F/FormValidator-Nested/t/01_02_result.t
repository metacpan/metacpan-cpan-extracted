use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;

use utf8;


my $fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});

my $res = $fvt->validate(Class::Param->new({
    mail3 => ('x' x 100) . '@geminium.com',
}), 'result');

is $res->has_error => 1;

my $error_params = $res->error_params;

ok $error_params->{mail}->[0]->isa('FormValidator::Nested::Result::Param');

is $error_params->{mail}->[0]->key => 'mail';
ok $error_params->{mail}->[0]->validator->isa('FormValidator::Nested::Profile::Param::Validator');

is $error_params->{mail}->[0]->msg => 'メールアドレスは必須です';


# カスタムメッセージ
is $error_params->{mail2}->[0]->msg => 'メールアドレスは必須だよー';

# オプションメッセージ
is $error_params->{mail3}->[0]->msg => 'メールアドレスは100文字以内で入力してください';


done_testing;
