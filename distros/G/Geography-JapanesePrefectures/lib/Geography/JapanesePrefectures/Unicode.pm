package Geography::JapanesePrefectures::Unicode;
use strict;
use warnings;
use utf8;

our $PREFECTURES = [
    { id => 1,  name => '北海道',    region => '北海道',    roman => 'Hokkaido'},
    { id => 2,  name => '青森県',    region => '東北',      roman => 'Aomori' },
    { id => 3,  name => '岩手県',    region => '東北',      roman => 'Iwate' },
    { id => 4,  name => '宮城県',    region => '東北',      roman => 'Miyagi' },
    { id => 5,  name => '秋田県',    region => '東北',      roman => 'Akita' },
    { id => 6,  name => '山形県',    region => '東北',      roman => 'Yamagata' },
    { id => 7,  name => '福島県',    region => '東北',      roman => 'Fukushima' },
    { id => 8,  name => '茨城県',    region => '関東',      roman => 'Ibaraki' },
    { id => 9,  name => '栃木県',    region => '関東',      roman => 'Tochigi' },
    { id => 10, name => '群馬県',    region => '関東',      roman => 'Gunma' },
    { id => 11, name => '埼玉県',    region => '関東',      roman => 'Saitama' },
    { id => 12, name => '千葉県',    region => '関東',      roman => 'Chiba' },
    { id => 13, name => '東京都',    region => '関東',      roman => 'Tokyo' },
    { id => 14, name => '神奈川県',  region => '関東',      roman => 'Kanagawa' },
    { id => 15, name => '新潟県',    region => '信越',      roman => 'Niigata' },
    { id => 16, name => '富山県',    region => '北陸',      roman => 'Toyama' },
    { id => 17, name => '石川県',    region => '北陸',      roman => 'Ishikawa' },
    { id => 18, name => '福井県',    region => '北陸',      roman => 'Fukui' },
    { id => 19, name => '山梨県',    region => '関東',      roman => 'Yamanashi' },
    { id => 20, name => '長野県',    region => '信越',      roman => 'Nagano' },
    { id => 21, name => '岐阜県',    region => '東海',      roman => 'Gifu' },
    { id => 22, name => '静岡県',    region => '東海',      roman => 'Shizuoka' },
    { id => 23, name => '愛知県',    region => '東海',      roman => 'Aichi' },
    { id => 24, name => '三重県',    region => '東海',      roman => 'Mie' },
    { id => 25, name => '滋賀県',    region => '近畿',      roman => 'Shiga' },
    { id => 26, name => '京都府',    region => '近畿',      roman => 'Kyoto' },
    { id => 27, name => '大阪府',    region => '近畿',      roman => 'Osaka' },
    { id => 28, name => '兵庫県',    region => '近畿',      roman => 'Hyōgo' },
    { id => 29, name => '奈良県',    region => '近畿',      roman => 'Nara' },
    { id => 30, name => '和歌山県',  region => '近畿',      roman => 'Wakayama' },
    { id => 31, name => '鳥取県',    region => '中国',      roman => 'Tottori' },
    { id => 32, name => '島根県',    region => '中国',      roman => 'Shimane' },
    { id => 33, name => '岡山県',    region => '中国',      roman => 'Okayama' },
    { id => 34, name => '広島県',    region => '中国',      roman => 'Hiroshima' },
    { id => 35, name => '山口県',    region => '中国',      roman => 'Yamaguchi' },
    { id => 36, name => '徳島県',    region => '四国',      roman => 'Tokushima' },
    { id => 37, name => '香川県',    region => '四国',      roman => 'Kagawa' },
    { id => 38, name => '愛媛県',    region => '四国',      roman => 'Ehime' },
    { id => 39, name => '高知県',    region => '四国',      roman => 'Kōchi' },
    { id => 40, name => '福岡県',    region => '九州',      roman => 'Fukuoka' },
    { id => 41, name => '佐賀県',    region => '九州',      roman => 'Saga' },
    { id => 42, name => '長崎県',    region => '九州',      roman => 'Nagasaki' },
    { id => 43, name => '熊本県',    region => '九州',      roman => 'Kumamoto' },
    { id => 44, name => '大分県',    region => '九州',      roman => 'Ōita' },
    { id => 45, name => '宮崎県',    region => '九州',      roman => 'Miyazaki' },
    { id => 46, name => '鹿児島県',  region => '九州',      roman => 'Kagoshima' },
    { id => 47, name => '沖縄県',    region => '沖縄',      roman => 'Okinawa' },
];

sub prefectures {
    my $self = shift;
    return map { $_->{name} } @$PREFECTURES;
}

sub regions {
    my $self = shift;
    my %uniq;
    return grep { !$uniq{$_}++ } map { $_->{region} } @$PREFECTURES;
}

sub prefectures_in {
    my ( $self, $region ) = @_;
    return map { $_->{name} } grep { $_->{region} eq $region } @$PREFECTURES;
}

sub prefectures_id {
    my ( $self, $prefecture ) = @_;

    for my $pref (@$PREFECTURES) {
        if ( $prefecture eq $pref->{name} ) {
            return $pref->{id};
        }
    }
}

sub prefectures_infos {
    my ($self, $args) = @_;

    return $PREFECTURES;
}

1;
__END__

=encoding utf8

=for stopwords prefecture's

=head1 NAME

Geography::JapanesePrefectures::Unicode - Japanese Prefectures Data.

=head1 SYNOPSIS

    use Geography::JapanesePrefectures::Unicode;

    Geography::JapanesePrefectures::Unicode->prefectures_in('関東');
    # => qw(茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 山梨県)
    
    Geography::JapanesePrefectures::Unicode->prefectures_id('東京');
    # => 13

=head1 DESCRIPTION

This module allows you to get information on Japanese Prefectures names. and region.

=head1 Class Methods

=head2 prefectures

    my @prefectures = Geography::JapanesePrefectures::Unicode->prefectures;

get the prefectures names.

=head2 regions

    my @regions = Geography::JapanesePrefectures::Unicode->regions;

get the region names.

=head2 prefectures_in

    my @prefectures = Geography::JapanesePrefectures::Unicode->prefectures_in('関東');
    # => qw(茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 山梨県)

get prefectures in region.

=head2 prefectures_id

    Geography::JapanesePrefectures::Unicode->prefectures_id('和歌山県');
    # => 30

get prefecture's ID.

=head2 prefectures_infos

    Geography::JapanesePrefectures::Unicode->prefectures_infos();
    # => [ { id => 1,  name => '北海道',    region => '北海道' }, ... ]

get all informations.

=head1 THANKS TO

    Tatsuhiko Miyagawa
    Yappo
    nipotan
    Shot(for greeting)
    nekokak
    lopnor

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<http://ja.wikipedia.org/wiki/JIS_X_0401#.E9.83.BD.E9.81.93.E5.BA.9C.E7.9C.8C.E3.82.B3.E3.83.BC.E3.83.89>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
