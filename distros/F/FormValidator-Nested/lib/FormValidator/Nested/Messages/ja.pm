package FormValidator::Nested::Messages::ja;
use strict;
use warnings;
use utf8;

our $MESSAGES = {
    'String#length'         => '${name}は${length}文字で入力してください',
    'String#alpha_num'      => '${name}はアルファベットと数字で入力してください',
    'String#ascii'          => '${name}は半角英数記号で入力してください',
    'String#max_length'     => '${name}は${max}文字以内で入力してください',
    'String#between_length' => '${name}は${min}-${max}文字で入力してください',
    'String#in'             => '${name}は正しくありません',
    'String#no_break'       => '${name}に改行コードが含まれています',

    'DBIC#unique' => '${name}は既に使われています',
    'DBIC#exist'  => '${name}は存在しません',

    'DateTime#date'               => '${name}は正しい日付形式ではありません',
    'DateTime#greater_than'       => '${name}は${target_name}よりも未来で入力してください',
    'DateTime#greater_than_equal' => '${name}は${target_name}よりも未来か同日で入力してください',

    'Blank#not_blank'  => '${name}は必須です',
    'Blank#evaluation' => '${name}は正しくありません',

    'NotBlank#evaluation' => '${name}は正しくありません',

    'Bool#bool' => '${name}の入力形式が正しくありません',

    'File#max_size' => '${name}は${max}byte以内のファイルをアップロードしてください',

    'Number#number' => '${name}は数字で入力してください',
    'Number#float' => '${name}は数値で入力してください',

    'Email#email' => '${name}の形式が正しくありません',

    'Internal#nested_hash' => '${name}は形式が正しくありません',

    'Japanese#hiragana' => '${name}はひらがなで入力してください',
    'Japanese#katakana' => '${name}はカタカナで入力してください',
};


1;

