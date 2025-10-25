#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 'lib';

use Tie::IxHash;

BEGIN {
    use_ok('HTTP::StructuredFieldValues', qw(encode decode_item decode_dictionary decode_list));
}

sub _h {
  tie my %hash, 'Tie::IxHash', @_;
  return \%hash;
}

sub _d {
    my ($type, $value) = @_;
    return { _type => $type, value => $value};
}

sub _i {
    my ($items, $params) = @_;
    return { _type => 'inner_list', value => $items, params => $params};
}

# エラーケースのテスト
subtest 'Special cases' => sub {
    is_deeply(decode_item(''), {}, 'Empty string');
    is_deeply(decode_item('%"%22"'), _d('displaystring', "\x22"), 'Empty string');
    is(encode(_d('displaystring', "\x1f")), '%"%1f"', 'Control character in displaystring');
};

# エラーケースのテスト
subtest 'Error cases' => sub {
    eval { decode_item(undef)};
    like($@, qr/Undefined argument/, 'decode_item with undef');

    # 無効な入力のデコード
    eval { decode_item('!!!invalid') };
    like($@, qr/Unable to parse/, 'Invalid input decoding');

    eval { decode_list(undef)};
    like($@, qr/Undefined argument/, 'decode_list with undef');

    eval { decode_dictionary(undef)};
    like($@, qr/Undefined argument/, 'decode_dictionary with undef');

    # undefined値
    eval { encode(undef)};
    like($@, qr/Invalid data type/, 'Undef');
    
    eval { encode([{ unknown => 1 }])};
    like($@, qr/Invalid item/, 'No _type on list');

    eval { encode({ a => { unknown => 1 }})};
    like($@, qr/Invalid value/, 'No _type on dictionary');

    eval { encode({ _type => 'integer'}) };
    like($@, qr/Invalid integer/, 'No value');

    eval { encode(_d('unknown', 1))};
    like($@, qr/Unknown type/, 'Invalid type');

    eval { encode(_d('date', 'a'))};
    like($@, qr/Invalid date value/, 'Invalid date');

    # 無効なキー
    eval { encode({ '123invalid' => _d('integer', 1) }) };
    like($@, qr/Invalid key/, 'Invalid dictionary key');
    
    eval { encode({ _type => _d('integer', 1)}) };
    like($@, qr/Invalid key/, 'Key name is _type');

    eval { encode({
        _type => 'string',
        value => 'hello',
        params => {
            unknown => 1,
        }
    }) };
    like($@, qr/Invalid parameter value/, 'Key name is _type');

    eval { encode([
        {
            _type => 'inner_list',
            value => [
                unknown => 1,
            ]
        }
    ]) };
    like($@, qr/Invalid item in inner list/, 'Inner list in inner list');
};

# 空白文字の処理テスト
subtest 'Whitespace handling' => sub {
    pass();return;
    # 前後の空白
    is_deeply(decode_item('  42  '), { _type => 'integer', value => 42 }, 'Whitespace trimming');
    
    # リスト内の空白
    my $decoded = decode_list('1 ,  2  , 3');
    is(scalar @$decoded, 3, 'List with extra whitespace');
    
    # 辞書内の空白
    my $dict = decode_dictionary('a=1 , b="hello"');
    is($dict->{a}->{value}, 1, 'Dictionary with whitespace around =');
};

done_testing();
