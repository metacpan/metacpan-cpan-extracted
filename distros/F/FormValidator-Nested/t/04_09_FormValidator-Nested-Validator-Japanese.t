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

{ # hiragana
    check({
        name => 'あをん',
    }, 'validator/japanese', 0);
    check({
        name => 'あおン',
    }, 'validator/japanese', 1, 'name', '名前はひらがなで入力してください');
}

{ # katakana
    check({
        name_k => 'アヲン',
    }, 'validator/japanese', 0);
    check({
        name_k => 'あおン',
    }, 'validator/japanese', 1, 'name_k', '名前_kはカタカナで入力してください');
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
