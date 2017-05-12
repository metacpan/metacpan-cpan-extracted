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

{ # max_length
    check({
        name => '千葉征弘' . 'x' x 26,
    }, 'validator/string', 0);
    check({
        name => '千葉征弘' . 'x' x 27,
    }, 'validator/string', 1, 'name', '名前は30文字以内で入力してください');
}

{ # length
    check({
        name_length => '千葉征弘' . 'x' x 26,
    }, 'validator/string', 0);
    check({
        name_length => '千葉征弘' . 'x' x 25,
    }, 'validator/string', 1, 'name_length', '名前_lengthは30文字で入力してください');
    check({
        name_length => '千葉征弘' . 'x' x 27,
    }, 'validator/string', 1, 'name_length', '名前_lengthは30文字で入力してください');
}

{ # between-length
    check({
        name_between_length => '千葉征弘' . 'x' x 25,
    }, 'validator/string', 1, 'name_between_length', '名前_between_lengthは30-50文字で入力してください');
    check({
        name_between_length => '千葉征弘' . 'x' x 26,
    }, 'validator/string', 0);

    check({
        name_between_length => '千葉征弘' . 'x' x 46,
    }, 'validator/string', 0);
    check({
        name_between_length => '千葉征弘' . 'x' x 47,
    }, 'validator/string', 1, 'name_between_length', '名前_between_lengthは30-50文字で入力してください');
}

{ # alpha_num
    check({
        alnum => 'abc',
    }, 'validator/string', 0);
    check({
        alnum => '123',
    }, 'validator/string', 0);
    check({
        alnum => 'aBc123',
    }, 'validator/string', 0);
    check({
        alnum => 'abc123-',
    }, 'validator/string', 1, 'alnum', 'alnumキーはアルファベットと数字で入力してください');
    check({
        alnum => 'abc123あ',
    }, 'validator/string', 1, 'alnum', 'alnumキーはアルファベットと数字で入力してください');
    check({
        alnum => 'abc123%',
    }, 'validator/string', 1, 'alnum', 'alnumキーはアルファベットと数字で入力してください');
}

{ # ascii
    check({
        ascii => 'abc',
    }, 'validator/string', 0);
    check({
        ascii => '123',
    }, 'validator/string', 0);
    check({
        ascii => 'abc!@#$%&^*()-_|\\"\':;/?][{},<>.',
    }, 'validator/string', 0);
    check({
        ascii => 'abc123-' . "\x80",
    }, 'validator/string', 1, 'ascii', 'asciiキーは半角英数記号で入力してください');
    check({
        ascii => 'abc123-あ',
    }, 'validator/string', 1, 'ascii', 'asciiキーは半角英数記号で入力してください');
}

{ # in
    check({
        in => 'abc',
    }, 'validator/string', 0);
    check({
        in => 'cde',
    }, 'validator/string', 0);
    check({
        in => 'abc1',
    }, 'validator/string', 1, 'in', 'inキーは正しくありません');
}

{ # no_break
    check({
        no_break  => 'abc',
    }, 'validator/string', 0);
    check({
        no_break => "abc\x0d",
    }, 'validator/string', 1, 'no_break', 'no_breakキーに改行コードが含まれています');
    check({
        no_break => "abc\x0a",
    }, 'validator/string', 1, 'no_break', 'no_breakキーに改行コードが含まれています');
    check({
        no_break => "abc\x0a\x0d",
    }, 'validator/string', 1, 'no_break', 'no_breakキーに改行コードが含まれています');
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
