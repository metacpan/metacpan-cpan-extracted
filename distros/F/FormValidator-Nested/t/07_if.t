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


{ # mail
    check({
        mail => '',
        mail2 => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => 'hoge',
    }, 'if', 0);
    check({
        mail => '',
        mail2 => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => '',
    }, 'if', 1, 'mail', 'メールアドレスは必須です');
}
{ # mail2
    check({
        mail2 => '',
        mail => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => '',
    }, 'if', 0);
    check({
        mail2 => '',
        mail => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => 'hoge',
    }, 'if', 1, 'mail2', 'メールアドレス2は必須です');
}
{ # mail3
    check({
        mail3 => '',
        mail => 'nihen@megabbs.com',
        mail2 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => 'hoga',
    }, 'if', 0);
    check({
        mail3 => '',
        mail => 'nihen@megabbs.com',
        mail2 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => 'hoge',
    }, 'if', 1, 'mail3', 'メールアドレス3は必須です');
}
{ # mail4
    check({
        mail4 => '',
        mail => 'nihen@megabbs.com',
        mail2 => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => 'hoga',
    }, 'if', 0);
    check({
        mail4 => '',
        mail => 'nihen@megabbs.com',
        mail2 => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail5 => 'nihen@megabbs.com',
        target => 'hoge',
    }, 'if', 1, 'mail4', 'メールアドレス4は必須です');
}
{ # mail5
    check({
        mail5 => '',
        mail => 'nihen@megabbs.com',
        mail2 => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        target => 'hoge',
        target_empty => 'a',
    }, 'if', 0);
    check({
        mail5 => '',
        mail => 'nihen@megabbs.com',
        mail2 => 'nihen@megabbs.com',
        mail3 => 'nihen@megabbs.com',
        mail4 => 'nihen@megabbs.com',
        target => 'hoge',
        target_empty => '',
    }, 'if', 1, 'mail5', 'メールアドレス5は必須です');
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
