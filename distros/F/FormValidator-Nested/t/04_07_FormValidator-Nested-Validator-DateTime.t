use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::Filter;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;

use utf8;

my ($fvt, $res, @error_params);

my $pp = FormValidator::Nested::ProfileProvider::YAML->new({
    dir => 't/var/profile',
});
$fvt = FormValidator::Nested->new({
    profile_provider => $pp,
});
my $fvtf = FormValidator::Nested::Filter->new({
    profile_provider => $pp,
});

{ # not_blank_date
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
    }, 'validator/datetime', 1, 'not_blank_start', 'not_blank_開始日は必須です');
    check({
        not_blank_start_year  => '2009',
    }, 'validator/datetime', 1, 'not_blank_start', 'not_blank_開始日は必須です');
    check({
    }, 'validator/datetime', 1, 'not_blank_start', 'not_blank_開始日は必須です');
}

{ # date
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        start_year  => '2009',
        start_month => '7',
        start_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        start_year  => '2009',
        start_month => '6',
        start_day   => '31',
    }, 'validator/datetime', 1, 'start', '開始日は正しい日付形式ではありません');
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        start_year  => '2009',
        start_month => '13',
        start_day   => '30',
    }, 'validator/datetime', 1, 'start', '開始日は正しい日付形式ではありません');
    # !うるう年
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        start_year  => '2009',
        start_month => '2',
        start_day   => '29',
    }, 'validator/datetime', 1, 'start', '開始日は正しい日付形式ではありません');
    # うるう年
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        start_year  => '2008',
        start_month => '2',
        start_day   => '29',
    }, 'validator/datetime', 0);
}
{ # greater_than_equal
    # invalidな日付の場合はエラーなしとする
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater_start_year  => '2009',
        greater_start_month => '6',
        greater_start_day   => '31',
        greater_end_year  => '2009',
        greater_end_month => '7',
        greater_end_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater_start_year  => '2009',
        greater_start_month => '6',
        greater_start_day   => '30',
        greater_end_year  => '2009',
        greater_end_month => '6',
        greater_end_day   => '31',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater_start_year  => '2009',
        greater_start_month => '7',
        greater_start_day   => '2',
        greater_end_year  => '2009',
        greater_end_month => '7',
        greater_end_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater_start_year  => '2009',
        greater_start_month => '7',
        greater_start_day   => '3',
        greater_end_year  => '2009',
        greater_end_month => '7',
        greater_end_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater_start_year  => '2009',
        greater_start_month => '7',
        greater_start_day   => '1',
        greater_end_year  => '2009',
        greater_end_month => '6',
        greater_end_day   => '30',
    }, 'validator/datetime', 1, 'greater_end', 'greater_終了日はgreater_開始日よりも未来か同日で入力してください');
}
{ # greater_than
    # invalidな日付の場合はエラーなしとする
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater2_start_year  => '2009',
        greater2_start_month => '6',
        greater2_start_day   => '31',
        greater2_end_year  => '2009',
        greater2_end_month => '7',
        greater2_end_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater2_start_year  => '2009',
        greater2_start_month => '6',
        greater2_start_day   => '30',
        greater2_end_year  => '2009',
        greater2_end_month => '6',
        greater2_end_day   => '31',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater2_start_year  => '2009',
        greater2_start_month => '7',
        greater2_start_day   => '2',
        greater2_end_year  => '2009',
        greater2_end_month => '7',
        greater2_end_day   => '3',
    }, 'validator/datetime', 0);
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater2_start_year  => '2009',
        greater2_start_month => '7',
        greater2_start_day   => '3',
        greater2_end_year  => '2009',
        greater2_end_month => '7',
        greater2_end_day   => '3',
    }, 'validator/datetime', 1, 'greater2_end', 'greater2_終了日はgreater2_開始日よりも未来で入力してください');
    check({
        not_blank_start_year  => '2009',
        not_blank_start_month => '7',
        not_blank_start_day   => '3',
        greater2_start_year  => '2009',
        greater2_start_month => '7',
        greater2_start_day   => '1',
        greater2_end_year  => '2009',
        greater2_end_month => '6',
        greater2_end_day   => '30',
    }, 'validator/datetime', 1, 'greater2_end', 'greater2_終了日はgreater2_開始日よりも未来で入力してください');
}


sub check {
    my ($param, $key, $error, $param_name, $msg) = @_;
    $param = Class::Param->new($param);
    $param = $fvtf->filter($param, $key);
    $res = $fvt->validate($param, $key);

    is $res->has_error => $error;

    my $error_params = $res->error_params;

    if ( $error ) {
        is $error_params->{$param_name}->[0]->msg => $msg;
    }
}

done_testing;
