#!/usr/bin/env perl

use 5.012;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;

use Carp;
use Encode;
use Encode::CN;
use YAML;
use YAML::Dumper;

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
my $split = "/";

#初始化相关变量
my ( $config_dir, $report_dir );

#设置配置文件路径
my $config_ini = $dir . $split . "config.ini";

#------------------------------------------------------------------------------
#机房数据映射哈希
#------------------------------------------------------------------------------
my %location = (
  "bbbsuan"    => "xxx房",
  "bbbboshi"   => "xxx机房",
  "bbbian"     => "xxx房",
  "bbbyangmen" => "xxx机房",
  "bbb0"       => "xxx机房",
  "bbbXDS"     => "xxx厦",
  "bbbCDS"     => "xxx厦",
  "bbbHXHL"    => "xxx鸿联",
  "bbbHXDX"    => "xxx电信",
  "bbbHXLD"    => "xxx联通",
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
  $text = decode( 'cp936', "$text" );

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
  croak "请检查配置文件是否存在" unless $config;

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
  my $ret = ip_info($rev);

  #网络设备本身IP信息
  my $ret1 = $ret->[0];

  #接入层交换机MAC信息
  my $ret2 = $ret->[1];

  #Incomplete ARP MAC信息
  my $ret3 = $ret->[2];

  #IPPHONE MAC 信息
  my $ret4 = $ret->[3];

  # 802.1x 认证信息
  my $ret5 = $ret->[4];

  #异常的ARP MAC信息
  my $ret6 = $ret->[5];

  #获取解析到的IP并打印
  my $ret1_count = scalar( keys %{$ret1} );
  my $ret2_count = scalar( keys %{$ret2} );
  my $ret3_count = scalar( keys %{$ret3} );
  my $ret4_count = scalar( keys %{$ret4} );
  my $ret5_count = scalar( keys %{$ret5} );
  my $ret6_count = scalar( keys %{$ret6} );

  #打印扫描到的IP数量
  say "共扫描到 $ret1_count 个网络设备IP";
  say "共扫描到 $ret2_count 个服务器IP";
  say "共扫描到 $ret3_count 个Incomplete IP";
  say "共扫描到 $ret4_count 台IPPHONE_模拟话机";
  say "共扫描到 $ret5_count 台 dot1x 认证PC主机";
  say "共有 $ret6_count 个解析异常IP \n";

  #创建EXCEL表格
  my $wb_name = "IP地址归属表" . "_$time" . '.xls';

  #设备绝对路径
  my $filename = $report_dir . $split . $wb_name;
  my $workbook = Spreadsheet::WriteExcel->new($filename);

  #新建sheet
  my $sheet1 = decode( 'cp936', '网络设备 IP 定位表' );
  my $sheet2 = decode( 'cp936', '服务器 IP 定位表' );
  my $sheet3 = decode( 'cp936', 'Incomplete ARP定位表' );
  my $sheet4 = decode( 'cp936', 'IPPHONE_模拟电话 记录表' );
  my $sheet5 = decode( 'cp936', '802.1x 认证PC主机' );
  my $sheet6 = decode( 'cp936', '解析异常 ARP 记录表' );

  my $worksheet1 = $workbook->add_worksheet($sheet1);
  my $worksheet2 = $workbook->add_worksheet($sheet2);
  my $worksheet3 = $workbook->add_worksheet($sheet3);
  my $worksheet4 = $workbook->add_worksheet($sheet4);
  my $worksheet5 = $workbook->add_worksheet($sheet5);
  my $worksheet6 = $workbook->add_worksheet($sheet6);

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
  $worksheet1->set_column( 0, 7, 28.5, $format_2 );
  $worksheet2->set_column( 0, 7, 28.5, $format_2 );
  $worksheet3->set_column( 0, 7, 28.5, $format_2 );
  $worksheet4->set_column( 0, 7, 28.5, $format_2 );
  $worksheet5->set_column( 0, 7, 28.5, $format_2 );
  $worksheet6->set_column( 0, 7, 28.5, $format_2 );

  #创建表单-表头
  my $excel_array = [
    decode( 'cp936', "IP地址" ),
    decode( 'cp936', "关联设备" ),
    decode( 'cp936', "关联接口" ),
    decode( 'cp936', "MAC地址" ),
    decode( 'cp936', "所属VLAN|BD" ),
    decode( 'cp936', "上游网关设备" ),
    decode( 'cp936', "所属VRF" ),
    decode( 'cp936', "所在机房" ),
  ];
  $worksheet1->write_row( 0, 0, $excel_array, $format );
  $worksheet2->write_row( 0, 0, $excel_array, $format );
  $worksheet3->write_row( 0, 0, $excel_array, $format );
  $worksheet4->write_row( 0, 0, $excel_array, $format );
  $worksheet5->write_row( 0, 0, $excel_array, $format );
  $worksheet6->write_row( 0, 0, $excel_array, $format );

  #sheet1写入数据
  my $row1 = 1;
  foreach my $ip ( sort ( keys %{$ret1} ) ) {

    #获取解析结果并分
    my $ip_info   = $ret1->{$ip};
    my $ipaddr    = $ip;
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};
    my $vrf       = $ip_info->{"vpn_instance"};
    my $gateway   = $ip_info->{"gate_device"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode( 'cp936', $location );
    }
    else {
      $location = decode( 'cp936', "非标命名未解析成功" );
    }

    #临时封装匿名数组
    my $array =
      [ $ipaddr, $hostname, $interface, $mac, $vlan, $gateway, $vrf, $location ];

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
    my $ipaddr    = $ip;
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};
    my $vrf       = $ip_info->{"vpn_instance"};
    my $gateway   = $ip_info->{"gate_device"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode( 'cp936', $location );
    }
    else {
      $location = decode( 'cp936', "非标命名未解析成功" );
    }

    #临时封装匿名数组
    my $array =
      [ $ipaddr, $hostname, $interface, $mac, $vlan, $gateway, $vrf, $location ];

    #写入计算数据
    $worksheet2->set_row( $row2, 22.5 );
    $worksheet2->write_row( $row2, 0, $array, $format_1 );
    $row2++;
  }

  #sheet3写入数据
  my $row3 = 1;
  foreach my $ip ( sort ( keys %{$ret3} ) ) {

    #获取解析结果并分解
    my $ip_info   = $ret3->{$ip};
    my $ipaddr    = $ip;
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};
    my $vrf       = $ip_info->{"vpn_instance"};
    my $gateway   = $ip_info->{"gate_device"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode( 'cp936', $location );
    }
    else {
      $location = decode( 'cp936', "非标命名未解析成功" );
    }

    #临时封装匿名数组
    my $array =
      [ $ipaddr, $hostname, $interface, $mac, $vlan, $gateway, $vrf, $location ];

    #写入计算数据
    $worksheet3->set_row( $row3, 22.5 );
    $worksheet3->write_row( $row3, 0, $array, $format_1 );
    $row3++;
  }

  #sheet4写入数据
  my $row4 = 1;
  foreach my $ip ( sort ( keys %{$ret4} ) ) {

    #获取解析结果并分解
    my $ip_info   = $ret4->{$ip};
    my $ipaddr    = $ip;
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};
    my $vrf       = $ip_info->{"vpn_instance"};
    my $gateway   = $ip_info->{"gate_device"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode( 'cp936', $location );
    }
    else {
      $location = decode( 'cp936', "非标命名未解析成功" );
    }

    #临时封装匿名数组
    my $array =
      [ $ipaddr, $hostname, $interface, $mac, $vlan, $gateway, $vrf, $location ];

    #写入计算数据
    $worksheet4->set_row( $row4, 22.5 );
    $worksheet4->write_row( $row4, 0, $array, $format_1 );
    $row4++;
  }

  #sheet+5写入数据
  my $row5 = 1;
  foreach my $ip ( sort ( keys %{$ret5} ) ) {

    #获取解析结果并分解
    my $ip_info   = $ret5->{$ip};
    my $ipaddr    = $ip;
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};
    my $vrf       = $ip_info->{"vpn_instance"};
    my $gateway   = $ip_info->{"gate_device"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode( 'cp936', $location );
    }
    else {
      $location = decode( 'cp936', "非标命名未解析成功" );
    }

    #临时封装匿名数组
    my $array =
      [ $ipaddr, $hostname, $interface, $mac, $vlan, $gateway, $vrf, $location ];

    #写入计算数据
    $worksheet5->set_row( $row5, 22.5 );
    $worksheet5->write_row( $row5, 0, $array, $format_1 );
    $row5++;
  }

  #sheet+6写入数据
  my $row6 = 1;
  foreach my $ip ( sort ( keys %{$ret6} ) ) {

    #获取解析结果并分解
    my $ip_info   = $ret6->{$ip};
    my $ipaddr    = $ip;
    my $hostname  = $ip_info->{"hostname"};
    my $interface = $ip_info->{"interface"};
    my $mac       = $ip_info->{"mac"};
    my $vlan      = $ip_info->{"vlan"};
    my $dc_code   = $ip_info->{"location"};
    my $vrf       = $ip_info->{"vpn_instance"};
    my $gateway   = $ip_info->{"gate_device"};

    #转换机房数据字典
    my $location;
    if ( exists $location{$dc_code} ) {
      $location = $location{$dc_code};
      $location = decode( 'cp936', $location );
    }
    else {
      $location = decode( 'cp936', "非标命名未解析成功" );
    }

    #临时封装匿名数组
    my $array =
      [ $ipaddr, $hostname, $interface, $mac, $vlan, $gateway, $vrf, $location ];

    #写入计算数据
    $worksheet6->set_row( $row6, 22.5 );
    $worksheet6->write_row( $row6, 0, $array, $format_1 );
    $row6++;
  }

  #持久化数据结构
  my $yaml = "IP归属查询.yaml";
  $yaml = $report_dir . $split . $yaml;
  YAML::DumpFile( $yaml, $ret );
}

#------------------------------------------------------------------------------
#实际处理函数
#------------------------------------------------------------------------------
say "-" x 100 . "\n";
say 'IP地址扫描工具V0.6 BY<careline@126.com>' . "\n";
prepare();
say "-" x 100 . "\n";
write_excel($config_dir);
say "-" x 100 . "\n";
