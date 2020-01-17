#!/usr/bin/env perl

use 5.012;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;

use Carp;
use Encode;
use Encode::CN;
use YAML;
use YAML::Loader;

use File::Slurp;
use Config::Tiny;
use Cwd qw'cwd abs_path';
use File::Basename;
use Huawei::Info::Ipaddr;
use POSIX qw/strftime/;
use Spreadsheet::WriteExcel;

#初始化本地时间
my $time = strftime( "%Y%m%d", localtime() );

#获取当前脚本绝对路径
my $dir = dirname( abs_path($0) );

#指定系统路径分隔符
my $split = "\\";

#初始化相关变量
my ( $config_dir, $report_dir );

#设置配置文件路径
my $config_ini = $dir . $split . "config.ini";

#------------------------------------------------------------------------------
#机房数据映射哈希
#------------------------------------------------------------------------------
my %location = (
  "chaosuan"    => "超算机房",
  "pengboshi"   => "鹏博士机房",
  "huitian"     => "汇天机房",
  "chaoyangmen" => "朝阳门机房",
);

#------------------------------------------------------------------------------
#初始化配置文件路径
#------------------------------------------------------------------------------
sub create_ini {

  #配置文件初始化
  my $text = '#配置目录文件夹
config_dir = config
report_dir = report
';

  #将配置文件转码未CP936
  $text = encode( "cp936", decode_utf8("$text") );

  #判断INI配置文件是否存在
  write_file( $config_ini, $text );
}

#------------------------------------------------------------------------------
#防火墙配置解析准备
#------------------------------------------------------------------------------
sub prepare {

  #初始化配置文件
  create_ini() unless -f $config_ini;
  my $config = new Config::Tiny->read($config_ini);

  #如果实例化成功则croak
  croak encode( "cp936", decode_utf8("请检查配置文件是否存在") )
    unless $config;

  #网络配置文件夹
  $config_dir = $dir . $split . $config->{"_"}{"config_dir"};

  #报表输出文件夹
  $report_dir = $dir . $split . $config->{"_"}{"report_dir"};

  #检查相关文件夹是否存在，不存在则新建
  mkdir $config_dir unless -d $config_dir;
  mkdir $report_dir unless -d $report_dir;
}

#------------------------------------------------------------------------------
#将数据写入EXCEL表格
#------------------------------------------------------------------------------
sub write_excel {

  #接收外部传递的配置文件夹
  my $rev = shift;

  #获取计算结果
  my $ret = arp_mac_info($rev);

  #网络设备本身IP信息
  my $ret1 = $ret->[0];

  #接入层交换机MAC信息
  my $ret2 = $ret->[1];

  #获取解析到的IP并打印
  my $ret1_count = scalar( keys %{$ret1} );
  my $ret2_count = scalar( keys %{$ret2} );

  #打印扫描到的IP数量
  say encode( "cp936", decode_utf8("共扫描到 $ret1_count 个网络设备IP") );
  say encode( "cp936", decode_utf8("共扫描到 $ret2_count 个服务器IP") );

  #创建EXCEL表格
  my $wb_name = "数据中心_IP地址归属表" . "_$time" . '.xls';
  $wb_name = encode( "cp936", decode_utf8($wb_name) );

  #设备绝对路径
  my $filename = $report_dir . $split . $wb_name;
  my $workbook = Spreadsheet::WriteExcel->new($filename);

  #新建sheet
  my $sheet1 = decode_utf8('网络设备IP地址定位表');
  my $sheet2 = decode_utf8('接入层交换机IP定位表');

  my $worksheet1 = $workbook->add_worksheet($sheet1);
  my $worksheet2 = $workbook->add_worksheet($sheet2);

  #设置表单格式
  my $format = $workbook->add_format();
  $format->set_bold();
  $format->set_color('purple');
  $format->set_bg_color('orange');
  $format->set_size(16);
  $format->set_border(1);
  $format->set_align('center');
  $format->set_valign('vcenter');

  my $format_1 = $workbook->add_format();
  $format_1->set_size(12);
  $format_1->set_border(1);
  $format_1->set_align('center');
  $format_1->set_valign('vcenter');

  my $format_2 = $workbook->add_format();
  $format_2->set_size(12);
  $format_2->set_align('center');
  $format_2->set_valign('vcenter');

  #设置格式
  $worksheet1->set_column( 0, 5, 28.5, $format_2 );
  $worksheet2->set_column( 0, 5, 28.5, $format_2 );

  #创建表单-表头
  my $excel_array = [
    decode_utf8("IP地址"),      decode_utf8("关联设备"),
    decode_utf8("关联接口"),  decode_utf8("MAC地址"),
    decode_utf8("所属VLAN|BD"), decode_utf8("所在机房"),
  ];
  $worksheet1->write_row( 0, 0, $excel_array, $format );
  $worksheet2->write_row( 0, 0, $excel_array, $format );

  #sheet1写入数据
  my $row1 = 1;
  foreach my $ip ( sort ( keys %{$ret1} ) ) {

    #获取解析结果并分解
    my $ip_info   = $ret1->{$ip};
    my $ipaddr    = $ip_info->{"ip"};
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode_utf8($location);
    }
    else {
      $location = decode_utf8("非标命名未解析成功");
    }

    #临时封装匿名数组
    my $array = [ $ipaddr, $hostname, $interface, $mac, $vlan, $location ];

    #写入计算数据
    $worksheet1->set_row( $row1, 22.5 );
    $worksheet1->write_row( $row1, 0, $array, $format_1 );
    $row1++;
  }

  #sheet2写入数据
  my $row2 = 1;
  foreach my $ip ( sort ( keys %{$ret2} ) ) {

    #获取解析结果并分解
    my $ip_info   = $ret2->{$ip};
    my $ipaddr    = $ip_info->{"ip"};
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode_utf8($location);
    }
    else {
      $location = decode_utf8("非标命名未解析成功");
    }

    #临时封装匿名数组
    my $array = [ $ipaddr, $hostname, $interface, $mac, $vlan, $location ];

    #写入计算数据
    $worksheet2->set_row( $row2, 22.5 );
    $worksheet2->write_row( $row2, 0, $array, $format_1 );
    $row2++;
  }

  #持久化数据结构
  my $yaml = "数据中心_IP归属查询.yaml";
  $yaml = $report_dir . $split . $yaml;
  $yaml = encode( "cp936", decode_utf8($yaml) );
  YAML::DumpFile( $yaml, $ret );
}

#------------------------------------------------------------------------------
#实际处理函数
#------------------------------------------------------------------------------
prepare();
write_excel($config_dir);

