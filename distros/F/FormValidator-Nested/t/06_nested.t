use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;

use utf8;
use lib 't/lib';

my ($fvt, $res, @error_params);

$fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});


{ # nested
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
    }, 'nested', 0);
    check({
        user => {
            name => '',
            mail => 'chiba@geminium.com',
        },
        user_array => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
    }, 'nested', 1, 'user[name]', '名前は必須です');
    check({
        user_array => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
    }, 'nested', 1, 'user', 'ユーザは必須です');
    check({
        user => 'hoge',
        user_array => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
    }, 'nested', 1, 'user', 'ユーザは形式が正しくありません');
}

{ # nested-array
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => [
            {
                name => '千葉征弘',
                mail => 'chiba@geminium.com',
            },
            {
                name => '千葉征弘2',
                mail => 'chiba+test@geminium.com',
            }
        ],
    }, 'nested', 0);
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
    }, 'nested', 0);
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => [
            {
                name => '千葉征弘',
                mail => 'chiba@geminium.com',
            },
            {
                name => '',
                mail => 'chiba+test@geminium.com',
            }
        ],
    }, 'nested', 1, 'user_array[1][name]', '名前は必須です');
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => [
            {
                name => '千葉征弘',
                mail => 'chiba@geminium.com',
            },
            [
                name => '千葉征弘',
                mail => 'chiba@geminium.com',
            ],
        ],
    }, 'nested', 1, 'user_array', 'ユーザarrayは形式が正しくありません');
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => 'hoge',
    }, 'nested', 1, 'user_array', 'ユーザarrayは形式が正しくありません');
    check({
        user => {
            name => '千葉征弘',
            mail => 'chiba@geminium.com',
        },
        user_array => [],
    }, 'nested', 1, 'user_array', 'ユーザarrayは必須です');
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
