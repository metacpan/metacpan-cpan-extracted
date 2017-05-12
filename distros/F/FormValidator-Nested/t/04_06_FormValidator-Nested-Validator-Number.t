use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;

use utf8;

my ($fvt, $res, @error_params);

$fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});

{ # number
    check({
        zip => '1550033',
    }, 'validator/number', 0);
    check({
        zip => '-1550033',
    }, 'validator/number', 1, 'zip', '郵便番号は数字で入力してください');
    check({
        zip => '+1550033',
    }, 'validator/number', 1, 'zip', '郵便番号は数字で入力してください');
    check({
        zip => 'aaabbbb',
    }, 'validator/number', 1, 'zip', '郵便番号は数字で入力してください');
    check({
        zip => '１２３',
    }, 'validator/number', 1, 'zip', '郵便番号は数字で入力してください');
    check({
        zip => '1111a',
    }, 'validator/number', 1, 'zip', '郵便番号は数字で入力してください');
}

{ # float
    check({
        float => '10',
    }, 'validator/number', 0);
    check({
        float => '10.1',
    }, 'validator/number', 0);
    check({
        float => '10.1a',
    }, 'validator/number', 1, 'float', 'floatは数値で入力してください');
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
