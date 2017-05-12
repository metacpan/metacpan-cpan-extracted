use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use FormValidator::Nested::Messages::ja;
use Class::Param;


use utf8;
use lib 't/lib';

use My::CustomValidator;

my ($fvt, $res, @error_params);

$fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});
$FormValidator::Nested::MESSAGES = {
    %{$FormValidator::Nested::Messages::ja::MESSAGES},
    %{$My::CustomValidator::MESSAGES},
};

{ # mycustom
    check({
        mail => 'chiba@geminium.com',
    }, 'validator/custom', 0);
    check({
        mail => 'hoge',
    }, 'validator/custom', 1, 'mail', 'メールアドレスはhogeと入力しないでください');
}


sub check {
    my ($param, $key, $error, $param_name, $msg) = @_;

    $res = $fvt->validate(Class::Param->new($param), $key);

    is $res->has_error => $error;

    my $error_params = $res->error_params;

    if ( $error ) {
        is $error_params->{$param_name}->[0]->msg => $msg;
    }
}

done_testing;
