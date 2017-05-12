package Geography::China::Provinces;
use strict;
use utf8;
use warnings;
our $VERSION = '0.06';

use Encode qw(decode_utf8);

our $AREAS = {
    1 => { en => 'huabei', zh => '华北', },
    2 => { en => 'dongbei', zh => '东北', },
    3 => { en => 'huadong', zh => '华东', },
    4 => { en => 'zhongnan', zh => '中南', },
    5 => { en => 'xinan', zh => '西南', },
    6 => { en => 'xibei', zh => '西北', },
};
our $REGION_CATEGORIES = {
    1 => { en => 'municipality',
           zh => '直辖市', },
    2 => { en => 'province',
           zh => '省', },
    3 => { en => 'autonomous region',
           zh => '自治区', },
    4 => { en => 'special administrative region',
           zh => '特別行政区', },
};
our $REGION_CATEGORY_MAP = {
    'municipality'          => 1,
    'province'              => 2,
    'autonomous_region'     => 3,
    'special_admin_region'  => 4,
};
our $REGIONS = [
    { category => 1, iso => '11', gb => 'BJ', abbr => '京', area => 1,
      en => 'Beijing', zh => '北京市', capital_zh => '北京市', },
    { category => 1, iso => '12', gb => 'TJ', abbr => '津', area => 1,
      en => 'Tianjin', zh => '天津市', capital_zh => '天津市', },
    { category => 2, iso => '13', gb => 'HE', abbr => '冀', area => 1,
      en => 'Hebei', zh => '河北省', capital_zh => '石家庄市', },
    { category => 2, iso => '14', gb => 'SX', abbr => '晋', area => 1,
      en => 'Shanxi', zh => '山西省', capital_zh => '太原市', },
    { category => 3, iso => '15', gb => 'NM', abbr => '蒙', area => 1,
      en => 'Nei Mongol', zh => '內蒙古自治区', capital_zh => '呼和浩特市', },
    { category => 2, iso => '21', gb => 'LN', abbr => '辽', area => 2,
      en => 'Liaoning', zh => '辽宁省', capital_zh => '沈阳市', },
    { category => 2, iso => '22', gb => 'JL', abbr => '吉', area => 2,
      en => 'Jilin', zh => '吉林省', capital_zh => '长春市', },
    { category => 2, iso => '23', gb => 'HL', abbr => '黑', area => 2,
      en => 'Heilongjiang', zh => '黑龙江省', capital_zh => '哈尔滨市', },
    { category => 1, iso => '31', gb => 'SH', abbr => '沪', area => 3,
      en => 'Shanghai', zh => '上海市', capital_zh => '上海市', },
    { category => 2, iso => '32', gb => 'JS', abbr => '苏', area => 3,
      en => 'Jiangsu', zh => '江苏省', capital_zh => '南京市', },
    { category => 2, iso => '33', gb => 'ZJ', abbr => '浙', area => 3,
      en => 'Zhejiang', zh => '浙江省', capital_zh => '杭州市', },
    { category => 2, iso => '34', gb => 'AH', abbr => '皖', area => 3,
      en => 'Anhui', zh => '安徽省', capital_zh => '合肥市', },
    { category => 2, iso => '35', gb => 'FJ', abbr => '闽', area => 3,
      en => 'Fujian', zh => '福建省', capital_zh => '福州市', },
    { category => 2, iso => '36', gb => 'JX', abbr => '赣', area => 3,
      en => 'Jiangxi', zh => '江西省', capital_zh => '南昌市', },
    { category => 2, iso => '37', gb => 'SD', abbr => '鲁', area => 3,
      en => 'Shangdong', zh => '山东省', capital_zh => '济南市', },
    { category => 2, iso => '41', gb => 'HA', abbr => '豫', area => 4,
      en => 'Henan', zh => '河南省', capital_zh => '郑州市', },
    { category => 2, iso => '42', gb => 'HB', abbr => '鄂', area => 4,
      en => 'Hubei', zh => '湖北省', capital_zh => '武汉市', },
    { category => 2, iso => '43', gb => 'HN', abbr => '湘', area => 4,
      en => 'Hunan', zh => '湖南省', capital_zh => '长沙市', },
    { category => 2, iso => '44', gb => 'GD', abbr => '粤', area => 4,
      en => 'Guangdong', zh => '广东省', capital_zh => '广州市', },
    { category => 3, iso => '45', gb => 'GX', abbr => '桂', area => 4,
      en => 'Guangxi', zh => '广西壮族自治区', capital_zh => '南宁市', },
    { category => 2, iso => '46', gb => 'HI', abbr => '琼', area => 4,
      en => 'Hainan', zh => '海南省', capital_zh => '海口市', },
    { category => 1, iso => '50', gb => 'CQ', abbr => '渝', area => 5,
      en => 'Chongqing', zh => '重庆市', capital_zh => '重庆市', },
    { category => 2, iso => '51', gb => 'SC', abbr => '川', area => 5,
      en => 'Sichuan', zh => '四川省', capital_zh => '成都市', },
    { category => 2, iso => '52', gb => 'GZ', abbr => '黔', area => 5,
      en => 'Guizhou', zh => '贵州省', capital_zh => '贵阳市', },
    { category => 2, iso => '53', gb => 'YN', abbr => '滇', area => 5,
      en => 'Yunnan', zh => '云南省', capital_zh => '昆明市', },
    { category => 3, iso => '54', gb => 'XZ', abbr => '藏', area => 5,
      en => 'Xizang', zh => '西藏自治区', capital_zh => '拉萨市', },
    { category => 2, iso => '61', gb => 'SN', abbr => '陕', area => 6,
      en => 'Shaanxi', zh => '陕西省', capital_zh => '西安市', },
    { category => 2, iso => '62', gb => 'GS', abbr => '甘', area => 6,
      en => 'Gansu', zh => '甘肃省', capital_zh => '兰州市', },
    { category => 2, iso => '63', gb => 'QH', abbr => '青', area => 6,
      en => 'Qinghai', zh => '青海省', capital_zh => '西宁市', },
    { category => 3, iso => '64', gb => 'NX', abbr => '宁', area => 6,
      en => 'Ningxia', zh => '宁夏回族自治区', capital_zh => '银川市', },
    { category => 3, iso => '65', gb => 'XJ', abbr => '新', area => 6,
      en => 'Xinjiang', zh => '新疆维吾尔自治区', capital_zh => '乌鲁木齐市', },
    { category => 2, iso => '71', gb => 'TW', abbr => '台', area => 3,
      en => 'Taiwan', zh => '台湾省', capital_zh => '台北市', },
    { category => 4, iso => '91', gb => 'HK', abbr => '港', area => 4,
      en => 'Hong Kong', zh => '香港特别行政区', capital_zh => '香港', },
    { category => 4, iso => '92', gb => 'MC', abbr => '澳', area => 4,
      en => 'Macao', zh => '澳门特别行政区', capital_zh => '澳门', },
];

sub areas { %$AREAS; }

sub _create_entry {
    my $entry = shift;
    +{ %$entry,
        category => {
            id => $entry->{category},
            %{ $REGION_CATEGORIES->{$entry->{category}} },
        },
        area => {
            id => $entry->{area},
            %{ $AREAS->{$entry->{area}} },
        },
    };
}

sub all {
    map { _create_entry($_) } @$REGIONS;
}

sub category {
    my ($class, $name) = @_;
    map { _create_entry($_) } grep { $_->{category} eq $REGION_CATEGORY_MAP->{$name} } @$REGIONS;
}

sub municipals {
    shift->category('municipality');
}

sub provinces {
    shift->category('province');
}

sub autonomous_regions {
    shift->category('autonomous_region');
}

sub special_admin_regions {
    shift->category('special_admin_region');
}

sub area {
    my ($class, $id) = @_;
    map { _create_entry($_) } grep { $_->{area} eq $id } @$REGIONS;
}

sub area_name {
    my ($class, $name) = @_;
    $name = decode_utf8($name);
    my $lang = $name =~ /^[\x20-\x7e]+$/ ? 'en' : 'zh'; # consists only with ASCII => en
    for my $id (keys %$AREAS) {
        return $class->area($id) if $AREAS->{$id}->{$lang} eq $name;
    }
    ();
}

sub iso {
    my ($class, $iso) = @_;
    for my $r (@$REGIONS) {
        return _create_entry($r) if $r->{iso} eq $iso;
    }
    undef;
}

1;

__END__

=head1 NAME

Geography::China::Provinces - To retrieve ISO 3166:CN standard Chinese provinces


=head1 SYNOPSIS

    use Geography::China::Provinces;

    my @municipals = Geography::China::Provinces->municipals;

    my @provinces = Geography::China::Provinces->provinces;

    my @autonomous_regions = Geography::China::Provinces->autonomous_regions;

    my @special_admin_regions = Geography::China::Provinces->special_admin_regions;

    my $region = Geography::China::Provinces->iso(11);


=head1 DESCRIPTION

This module helps retrieving ISO standard Chinese provincial level divisions.


=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Provinces_of_the_People's_Republic_of_China>


=head1 INTERFACE

=head2 all

    my @regions = Geography::China::Provinces->all;
    #=> Get all regions

=head2 municipals

    my @regions = Geography::China::Provinces->municipals;
    #=> Get all municipal cities

=head2 provinces

    my @regions = Geography::China::Provinces->provinces;
    #=> Get all provinces

=head2 autonomous_regions

    my @regions = Geography::China::Provinces->autonomous_regions;
    #=> Get all autonomous regions

=head2 special_admin_regions

    my @regions = Geography::China::Provinces->special_admin_regions;
    #=> Get all special administrative regions

=head2 areas

    my %areas = Geography::China::Provinces->areas;
    #=> Get Chinese geographic areas as a hash

=head2 area

    my @regions = Geography::China::Provinces->area(1);
    #=> Get regions in area 1

=head2 area_name

    my @regions = Geography::China::Provinces->area_name('huadong');
    #=> Get regions in area `huadong'

=head2 iso

    my $region = Geography::China::Provinces->iso(11);
    #=> Get region with ISO code 11

=head2 category

    my @regions = Geography::China::Provinces->category('municipality');
    #=> Get municipal regions


=head1 AUTHOR

yowcow  C<< <yowcow@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2014, yowcow C<< <yowcow@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
