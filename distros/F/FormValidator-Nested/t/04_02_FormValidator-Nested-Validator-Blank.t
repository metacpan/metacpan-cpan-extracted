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

{ # not_blank
    check({
        name => '千葉征弘',
        evalval => '126',
    }, 'validator/blank', 0);

    check({
        name => '',
        evalval => '126',
    }, 'validator/blank', 1, 'name', '名前は必須です');
    check({
        name => undef,
        evalval => '126',
    }, 'validator/blank', 1, 'name', '名前は必須です');
    check({
        evalval => '126',
    }, 'validator/blank', 1, 'name', '名前は必須です');
}

{ # eval
    check({
        name => '千葉征弘',
        evalval => '126',
    }, 'validator/blank', 0);
    check({
        name => '千葉征弘',
    }, 'validator/blank', 1, 'evalval', 'evalvalは正しくありません');
    check({
        name => '千葉征弘',
        evalval => '125',
    }, 'validator/blank', 1, 'evalval', 'evalvalは正しくありません');
}

{ # notblank_eval
    check({
        name => '千葉征弘',
        evalval => '126',
        notblank_evalval => '126',
    }, 'validator/blank', 0);
    check({
        name => '千葉征弘',
        evalval => '126',
        notblank_evalval => '125',
    }, 'validator/blank', 1, 'notblank_evalval', 'notblank_evalvalは正しくありません');
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
