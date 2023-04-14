package Faker::Plugin::JaJp::AddressCountryName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_address_country_name());
}

sub data_for_address_country_name {
  state $address_country_name = [
    'アフガニスタン',
    'アルバニア',
    'アルジェリア',
    'アメリカ領サモア',
    'アンドラ',
    'アンゴラ',
    'アンギラ',
    '南極大陸',
    'アンティグアバーブーダ',
    'アルゼンチン',
    'アルメニア',
    'アルバ',
    'オーストラリア',
    'オーストリア',
    'アゼルバイジャン',
    'バハマ',
    'バーレーン',
    'バングラデシュ',
    'バルバドス',
    'ベラルーシ',
    'ベルギー',
    'ベリーズ',
    'ベナン',
    'バミューダ島',
    'ブータン',
    'ボリビア',
    'ボスニア・ヘルツェゴビナ',
    'ボツワナ',
    'ブーベ島',
    'ブラジル',
    'イギリス領インド洋地域',
    'イギリス領ヴァージン諸島',
    'ブルネイ',
    'ブルガリア',
    'ブルキナファソ',
    'ブルンジ',
    'カンボジア',
    'カメルーン',
    'カナダ',
    'カーボベルデ',
    'ケイマン諸島',
    '中央アフリカ共和国',
    'チャド',
    'チリ',
    '中国',
    'クリスマス島',
    'ココス諸島',
    'コロンビア',
    'コモロ',
    'コンゴ共和国',
    'クック諸島',
    'コスタリカ',
    'コートジボワール',
    'クロアチア',
    'キューバ',
    'キプロス共和国',
    'チェコ共和国',
    'デンマーク',
    'ジブチ共和国',
    'ドミニカ国',
    'ドミニカ共和国',
    'エクアドル',
    'エジプト',
    'エルサルバドル',
    '赤道ギニア共和国',
    'エリトリア',
    'エストニア',
    'エチオピア',
    'フェロー諸島',
    'フォークランド諸島',
    'フィジー共和国',
    'フィンランド',
    'フランス',
    'フランス領ギアナ',
    'フランス領ポリネシア',
    'フランス領極南諸島',
    'ガボン',
    'ガンビア',
    'ジョージア',
    'ドイツ',
    'ガーナ',
    'ジブラルタル',
    'ギリシャ',
    'グリーンランド',
    'グレナダ',
    'グアドループ',
    'グアム',
    'グアテマラ',
    'ガーンジー',
    'ギニア',
    'ギニアビサウ',
    'ガイアナ',
    'ハイチ',
    'ハード島とマクドナルド諸島',
    'バチカン市国',
    'ホンジュラス',
    '香港',
    'ハンガリー',
    'アイスランド',
    'インド',
    'インドネシア',
    'イラン',
    'イラク',
    'アイルランド共和国',
    'マン島',
    'イスラエル',
    'イタリア',
    'ジャマイカ',
    '日本',
    'ジャージー島',
    'ヨルダン',
    'カザフスタン',
    'ケニア',
    'キリバス',
    '朝鮮',
    '韓国',
    'クウェート',
    'キルギス共和国',
    'ラオス人民民主共和国',
    'ラトビア',
    'レバノン',
    'レソト',
    'リベリア',
    'リビア国',
    'リヒテンシュタイン',
    'リトアニア',
    'ルクセンブルク',
    'マカオ',
    'マケドニア共和国',
    'マダガスカル',
    'マラウィ',
    'マレーシア',
    'モルディブ',
    'マリ',
    'マルタ共和国',
    'マーシャル諸島',
    'マルティニーク',
    'モーリタニア・イスラム共和国',
    'モーリシャス',
    'マヨット',
    'メキシコ',
    'ミクロネシア連邦',
    'モルドバ共和国',
    'モナコ公国',
    'モンゴル',
    'モンテネグロ共和国',
    'モントセラト',
    'モロッコ',
    'モザンビーク',
    'ミャンマー',
    'ナミビア',
    'ナウル',
    'ネパール',
    'オランダ領アンティル',
    'オランダ',
    'ニューカレドニア',
    'ニュージーランド',
    'ニカラグア',
    'ニジェール',
    'ナイジェリア',
    'ニース',
    'ノーフォーク島',
    '北マリアナ諸島',
    'ノルウェー',
    'オマーン',
    'パキスタン',
    'パラオ',
    'パレスチナ自治区',
    'パナマ',
    'パプアニューギニア',
    'パラグアイ',
    'ペルー',
    'フィリピン',
    'ピトケアン諸島',
    'ポーランド',
    'ポルトガル',
    'プエルトリコ',
    'カタール',
    'レユニオン',
    'ルーマニア',
    'ロシア',
    'ルワンダ',
    'サン・バルテルミー島',
    'セントヘレナ',
    'セントクリストファー・ネイビス連邦',
    'セントルシア',
    'セント・マーチン島',
    'サンピエール島・ミクロン島',
    'セントビンセント・グレナディーン',
    'サモア',
    'サンマリノ',
    'サントメプリンシペ',
    'サウジアラビア',
    'セネガル',
    'セルビア',
    'セイシェル',
    'シエラレオネ',
    'シンガポール',
    'スロバキア',
    'スロベニア',
    'ソロモン諸島',
    'ソマリア',
    '南アフリカ共和国',
    'サウスジョージア・サウスサンドウィッチ諸島',
    'スペイン',
    'スリランカ',
    'スーダン',
    'スリナム',
    'スヴァールバル諸島およびヤンマイエン島',
    'スワジランド王国',
    'スウェーデン',
    'スイス',
    'シリア',
    '台湾',
    'タジキスタン共和国',
    'タンザニア',
    'タイ',
    '東ティモール',
    'トーゴ',
    'トケラウ',
    'トンガ',
    'トリニダード・トバゴ',
    'チュニジア',
    'トルコ',
    'トルクメニスタン',
    'タークス・カイコス諸島',
    'ツバル',
    'ウガンダ',
    'ウクライナ',
    'アラブ首長国連邦',
    'イギリス',
    'アメリカ合衆国',
    '合衆国領有小離島',
    'アメリカ領ヴァージン諸島',
    'ウルグアイ',
    'ウズベキスタン',
    'バヌアツ',
    'ベネズエラ',
    'ベトナム',
    'ウォリス・フツナ',
    '西サハラ',
    'イエメン',
    'ザンビア',
    'ジンバブエ',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressCountryName - Address Country Name

=cut

=head1 ABSTRACT

Address Country Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressCountryName;

  my $plugin = Faker::Plugin::JaJp::AddressCountryName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressCountryName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address country name.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::JaJp>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address country name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressCountryName;

  my $plugin = Faker::Plugin::JaJp::AddressCountryName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressCountryName")

  # my $result = $plugin->execute;

  # 'グリーンランド';

  # my $result = $plugin->execute;

  # 'アイルランド共和国';

  # my $result = $plugin->execute;

  # 'スヴァールバル諸島およびヤンマイエン島';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressCountryName;

  my $plugin = Faker::Plugin::JaJp::AddressCountryName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressCountryName")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut