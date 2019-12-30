#!/usr/bin/env perl

use 5.012;
use warnings;
no warnings 'uninitialized';

use YAML;
use YAML::Dumper;
use Encode;
use Encode::CN;

use Carp;
use POSIX qw/strftime/;
use Config::Tiny;

use File::Slurp;
use Cwd qw'cwd abs_path';
use File::Basename;
use Huawei::Healthchecker;
use Spreadsheet::WriteExcel;

#------------------------------------------------------------------------------
# 巡检报表相关全局变量
#------------------------------------------------------------------------------

#初始化本地时间
my $time = strftime( "%Y%m%d", localtime() );

#获取当前脚本绝对路径
my $dir = dirname( abs_path($0) );

#指定系统路径分隔符
my $split = "\\";

#设置配置文件路径
my $config_ini = $dir . $split . "config.ini";

sub create_ini {

    #配置文件初始化
    my $text = '#配置巡检目录文件夹
config_dir = config
report_dir = report
';

    #将配置文件转码未CP936
    $text = encode( "cp936", decode_utf8("$text") );

    #判断INI配置文件是否存在
    if ( not -f $config_ini ) {
        write_file( $config_ini, $text );
    }
}

#初始化配置文件
create_ini() unless -f $config_ini;
my $config = new Config::Tiny->read($config_ini);

#如果实例化成功则croak
croak encode( "cp936", decode_utf8("请检查配置文件是否存在") )
    unless $config;

#网络配置文件夹
my $config_dir = $dir . $split . $config->{"_"}{"config_dir"};

#报表输出文件夹
my $report_dir = $dir . $split . $config->{"_"}{"report_dir"};

#检查相关文件夹是否存在，不存在则新建
mkdir $config_dir unless -d $config_dir;
mkdir $report_dir unless -d $report_dir;

#待解析的配置文件
my @files = grep {/\.cfg$|\.conf$|\.config$/} read_dir($config_dir);

#预检查目录文件夹是否为空，为空则退出后续动作
croak encode(
    "cp936",
    decode_utf8(
        "检索到配置文件为空，请填充待巡检设备配置！")
) unless @files;

#------------------------------------------------------------------------------
# 巡检报表输出EXCEL 函数入口
#------------------------------------------------------------------------------
sub write_excel {

    #接收网络设备巡检报告
    my $result = shift;

    #初始化SHEET表单变量
    my $sheet_name = decode_utf8( "网络设备巡检报表" . "-$time" );

    #初始化EXCEL表单
    my $excel_name = encode(
        "cp936",
        decode_utf8(
                  "中信银行信用卡-网络设备巡检报告"
                . "_$time" . '.xls'
        )
    );

    my $filename = $report_dir . $split . $excel_name;

    # 创建EXCEL表格
    my $workbook = Spreadsheet::WriteExcel->new($filename);

    #解决提示文件丢失的BUG
    $workbook->compatibility_mode();

    # 创建EXCEL SHEET表单
    my $worksheet = $workbook->add_worksheet($sheet_name);

    # 设置表单样式
    my $format = $workbook->add_format();
    $format->set_bold();
    $format->set_color('blue');
    $format->set_bg_color('red');
    $format->set_size(18);
    $format->set_border(1);
    $format->set_align('center');
    $format->set_valign('vcenter');

    # 设置表单样式1
    my $format_1 = $workbook->add_format();
    $format_1->set_size(12);
    $format_1->set_border(1);
    $format_1->set_color('red');
    $format_1->set_bg_color('gray');
    $format_1->set_align('left');
    $format_1->set_valign('vcenter');

    # 设置表单样式2
    my $format_2 = $workbook->add_format();
    $format_2->set_size(12);
    $format_2->set_align('center');
    $format_2->set_valign('vcenter');

    # 设置表单样式3
    my $format_3 = $workbook->add_format();
    $format_3->set_size(12);
    $format_3->set_border(1);
    $format_3->set_align('center');
    $format_3->set_valign('vcenter');

    # 合并表头列宽和格式
    $worksheet->set_column( 0, 14, 30, $format_2 );

    # EXCEL表头信息
    my $excel_array = [

        #----------------------------------------------------------------
        # 设备硬件状态指标抬头
        #----------------------------------------------------------------
        decode_utf8("设备名称"),

        #decode_utf8("版本信息"),
        decode_utf8("板卡状态"),
        decode_utf8("电源状态"),
        decode_utf8("硬盘状态"),
        decode_utf8("风扇状态"),
        decode_utf8("温度状态"),
        decode_utf8("硬件告警"),

        #----------------------------------------------------------------
        # 设备关键运行指标抬头
        #----------------------------------------------------------------
        decode_utf8("CPU指标"),
        decode_utf8("内存指标"),
        decode_utf8("NTP状态"),
        decode_utf8("VRRP状态"),
        decode_utf8("ETH-TRUNK检查"),
        decode_utf8("ERR-DOWN检查"),

        #----------------------------------------------------------------
        # 设备关键运行指标抬头
        #----------------------------------------------------------------
        decode_utf8("健康检查得分"),
        decode_utf8("巡检日志摘要"),
    ];

    #将表头样式写入EXCEL表格
    $worksheet->write_row( 0, 0, $excel_array, $format );

    #设置表格行数计数器
    my $row = 1;

    #遍历巡检结果并写入EXCEL
    foreach ( keys( %{$result} ) ) {

        #获取设备巡检报告
        my $rev = $result->{$_}{"result"};

        #遍历 $rev->{"hardware"} 各属性哈希值
        foreach my $key ( keys %{ $result->{$_}{"hardware"} } ) {

            #抽取巡检报告的 hardware 日志属性
            my $ret = $result->{$_}{"hardware"}{$key};

            #转换 log 编码
            if ( defined $ret->{"log"} ) {

                #获取当前log属性
                my $log = $ret->{"log"};

                #转换编码
                $log = decode_utf8("$log");

                #删除 log 属性再添加新日志字段
                delete $result->{$_}{"hardware"}->{$key}{"log"};
                $result->{$_}{"hardware"}->{$key}{"log"} = $log;
            }
        }

        #遍历 $rev->{"status"} 各属性哈希值
        foreach my $key ( keys %{ $result->{$_}{"status"} } ) {

            #抽取巡检报告的 hardware 日志属性
            my $ret = $result->{$_}{"status"}{$key};

            #转换 log 编码
            if ( defined $ret->{"log"} ) {

                #获取当前log属性
                my $log = $ret->{"log"};

                #转换编码
                $log = decode_utf8("$log");

                #删除 log 属性再添加新日志字段
                delete $result->{$_}{"status"}{$key}{"log"};
                $result->{$_}{"status"}{$key}{"log"} = $log;
            }
        }

        #获取设备名称
        s/\.(.*)$//;

        #将设备名压入数组头部
        unshift @{$rev}, "$_";

        #抽取巡检报告日志并转码
        my $log = pop @{$rev};

        #将设备巡检日志转码
        $log = decode_utf8("$log");

        #将转码后的数据压入数组末尾
        push @{$rev}, $log;
        $result->{$_}{"result"} = $rev;

        #抽取巡检报告得分情况
        my $score = $rev->[-2];

        #如果巡检得分过低则高亮显示
        if ( $score >= 85 ) {
            $worksheet->set_row( $row, 22.5 );
            $worksheet->write_row( $row, 0, $rev, $format_3 );
        }
        else {
            $worksheet->set_row( $row, 22.5 );
            $worksheet->write_row( $row, 0, $rev, $format_1 );
        }
        $row++;
    }

    #YAML文件名初始化
    my $yaml_name = encode(
        "cp936",
        decode_utf8(
            "中信银行信用卡_网络设备巡检明细档_$time.yml")
    );
    my $yaml_file = $report_dir . $split . $yaml_name;

    #将巡检结果写入YAML数据表
    YAML::DumpFile( $yaml_file, $result );
}

#------------------------------------------------------------------------------
# 网络配置批量巡检 - 函数入口
#------------------------------------------------------------------------------
sub start_checker {

    #初始化巡检结果变量
    my $result;

    if (@files) {

        #运行提示
        say encode(
            'cp936',
            decode_utf8(
                "\n[中信银行信用卡] --网络设备自动巡检工具 V2.019 BY \<careline\@126\.com\>\n"
            )
        );
        say encode( 'cp936',
            decode_utf8("\n请稍等，配置加载中 \n") );

        #将实时巡检输出进行健康检查解析
        foreach (@files) {
            my $filename = $config_dir . $split . $_;

            #进行监控检查分析
            my ( $rev, $ret ) = health_check($filename);

            #创建配置遍历数据结构
            $result->{$_} = $rev;

            #将巡检结果写入报告中
            $result->{$_}{"result"} = $ret;
        }
    }

    #将巡检结果写入报表输出
    write_excel($result);
    say encode( 'cp936',
        decode_utf8("\n程序已处理完毕 ... ... \n\n") );
}

start_checker();
