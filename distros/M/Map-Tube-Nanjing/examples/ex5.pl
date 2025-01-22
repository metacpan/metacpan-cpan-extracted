#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Nanjing;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 line\n";
        exit 1;
}
my $line = decode_utf8($ARGV[0]);

# Object.
my $obj = Map::Tube::Nanjing->new;

# Get stations for line.
my $stations_ar = $obj->get_stations($line);

# Print out.
map { print encode_utf8($_->name)."\n"; } @{$stations_ar};

# Output:
# Usage: __PROG__ line

# Output with 'foo' argument.
# Map::Tube::get_stations(): ERROR: Invalid Line Name [foo]. (status: 105) file __PROG__ on line __LINE__

# Output with '南京地铁1号线' argument.
# 迈皋桥
# 红山动物园
# 南京站
# 新模范马路
# 玄武门
# 鼓楼
# 珠江路
# 新街口
# 张府园
# 三山街
# 中华门
# 安德门
# 天隆寺
# 软件大道
# 花神庙
# 南京南站
# 双龙大道
# 河定桥
# 胜太路
# 百家湖
# 小龙湾
# 竹山路
# 天印大道
# 龙眠大道
# 南医大·江苏经贸学院
# 南京交院
# 中国药科大学