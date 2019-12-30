package Huawei::Healthchecker;

#版本信息
our $VERSION = "0.12";

use 5.012;
use warnings;
use Net::Compare;

#引用导出函数
use Exporter;

#继承parent相关变量
use parent 'Exporter';

#自动导出健康检查函数
our @EXPORT = qw(health_check);

#设置华为设备通用健康检查哈希数据模型
my $attr = {
    'hardware' => {
        'device_version'     => 'dis device',
        'module_status'      => 'dis device',
        'power_status'       => 'dis device power',
        'disk_status'        => 'dis health',
        'fan_status'         => 'dis device fan',
        'alarm_status'       => 'dis device alarm hardware',
        'temperature_status' => 'dis device temperature all',
    },
    'status' => {
        'cpu_status'       => 'dis cpu',
        'memory_status'    => 'dis memory',
        'ntp_status'       => 'dis ntp status',
        'vrrp_status'      => 'dis vrrp',
        'eth_trunk_status' => 'dis eth-trunk',
        'err_down_status'  => 'dis error-down recovery',
    }
};

#固化硬件巡检参数为数组（哈希无序）
my $hardware = $attr->{"hardware"};

#固化关键指标巡检参数为数组（哈希无序）
my $status = $attr->{"status"};

#-------------------------------------------------------------------------
# 网络设备- 关键指标巡检阈值
#-------------------------------------------------------------------------
#CPU告警阈值
my $cpu_threshold = 60;

#内存告警阈值
my $memory_threshold = 80;

#CPU历史MAX告警阈值
my $cpu_max_threshold = 85;

#磁盘告警阈值
my $disk_threshold = 75;

#-------------------------------------------------------------------------
# 网络设备-华为设备巡检入口函数
#-------------------------------------------------------------------------
sub health_check {

    #接收待巡检配置文件
    my $config = shift;

    #解析巡检输出
    my $rev = status_check($config);

    #初始化变量-设备巡检日志
    my @comment;

    #获取设备版本信息
    #my $verison = $rev->{"verison"};

    #初始化设备硬件状态巡检结果-数组
    my @hardware_ret;
    push @hardware_ret,
        $rev->{"hardware"}{"device_module"}{"health"} || "unknow";
    push @hardware_ret,
        $rev->{"hardware"}{"device_power"}{"health"} || "unknow";
    push @hardware_ret,
        $rev->{"hardware"}{"device_disk"}{"health"} || "unknow";
    push @hardware_ret,
        $rev->{"hardware"}{"device_fan"}{"health"} || "unknow";
    push @hardware_ret,
        $rev->{"hardware"}{"device_temperature"}{"health"} || "unknow";
    push @hardware_ret,
        $rev->{"hardware"}{"device_alarm"}{"health"} || "unknow";

    #初始化设备关键指标巡检结果-数组
    my @status_ret;
    push @status_ret, $rev->{"status"}{"device_cpu"}{"health"}    || "unknow";
    push @status_ret, $rev->{"status"}{"device_memory"}{"health"} || "unknow";
    push @status_ret, $rev->{"status"}{"device_ntp"}{"health"}    || "unknow";
    push @status_ret, $rev->{"status"}{"device_vrrp"}{"health"}   || "unknow";
    push @status_ret,
        $rev->{"status"}{"device_eth_trunk"}{"health"} || "unknow";
    push @status_ret,
        $rev->{"status"}{"device_err_down"}{"health"} || "unknow";

    #遍历 $rev->{"hardware"} 各属性哈希值
    foreach ( keys %{ $rev->{"hardware"} } ) {
        my $ret = $rev->{"hardware"}->{$_};
        if ( defined $ret->{"log"} ) {
            push @comment, $ret->{"log"};
        }
    }

    #遍历 $rev->{"status"} 各属性哈希值
    foreach ( keys %{ $rev->{"status"} } ) {
        my $ret = $rev->{"status"}->{$_};
        if ( defined $ret->{"log"} ) {
            push @comment, $ret->{"log"};
        }
    }

    #将设备描述数组转换未字符串
    my $comment = join( "\n", @comment ) if @comment;

    #计算设备巡检健康度
    my $score = calculate_score($rev);

    #封装计算结果到匿名数组中，方便EXCEL读写
    my $result = [ @hardware_ret, @status_ret, $score, $comment ];

    #返回健康检查结果
    return ( $rev, $result );
}

#-------------------------------------------------------------------------
# 网络设备-设备健康在线巡检函数入口
#-------------------------------------------------------------------------
sub status_check {

    #接收待巡检配置文件
    my $config = shift;

    #设备巡检结果
    my $result;

    #-------------------------------------------------------------------------
    # 网络设备-硬件运行状态巡检命令行输出
    #-------------------------------------------------------------------------
    #my $device_version = catch_cmd( $hardware->{"device_version"}, $config );
    my $device_module = catch_cmd( $hardware->{"module_status"}, $config );
    my $device_power  = catch_cmd( $hardware->{"power_status"},  $config );
    my $device_disk   = catch_cmd( $hardware->{"disk_status"},   $config );
    my $device_fan    = catch_cmd( $hardware->{"fan_status"},    $config );
    my $device_alarm  = catch_cmd( $hardware->{"alarm_status"},  $config );
    my $device_temperature
        = catch_cmd( $hardware->{"temperature_status"}, $config );

    #-------------------------------------------------------------------------
    # 网络设备-关键运行指标巡检命令行输出
    #-------------------------------------------------------------------------
    my $device_cpu    = catch_cmd( $status->{"cpu_status"},    $config );
    my $device_memory = catch_cmd( $status->{"memory_status"}, $config );
    my $device_ntp    = catch_cmd( $status->{"ntp_status"},    $config );
    my $device_vrrp   = catch_cmd( $status->{"vrrp_status"},   $config );
    my $device_eth_trunk
        = catch_cmd( $status->{"eth_trunk_status"}, $config );
    my $device_err_down = catch_cmd( $status->{"err_down_status"}, $config );

    #-------------------------------------------------------------------------
    # 网络设备-硬件运行状态巡检判断
    #-------------------------------------------------------------------------
    #my $device_info        = device_version($device_version);
    my $module_status      = module_status($device_module);
    my $power_status       = power_status($device_power);
    my $disk_status        = disk_status($device_disk);
    my $fan_status         = fan_status($device_fan);
    my $alarm_status       = alarm_status($device_alarm);
    my $temperature_status = temperature_status($device_temperature);

    #-------------------------------------------------------------------------
    # 网络设备-关键运行指标巡检判断
    #-------------------------------------------------------------------------
    my $cpu_status       = cpu_status($device_cpu);
    my $memory_status    = memory_status($device_memory);
    my $ntp_status       = ntp_status($device_ntp);
    my $vrrp_status      = vrrp_status($device_vrrp);
    my $eth_trunk_status = eth_trunk_status($device_eth_trunk);
    my $err_down_status  = err_down_status($device_err_down);

    #-------------------------------------------------------------------------
    # 网络设备-设备版本型号信息 --检查项1 共计1项
    #-------------------------------------------------------------------------
    #$result->{"version"}     = $device_info;

    #-------------------------------------------------------------------------
    # 网络设备-硬件运行状态巡检结果 --检查项2 共计6项
    #-------------------------------------------------------------------------
    $result->{"hardware"}{"device_module"}      = $module_status;
    $result->{"hardware"}{"device_power"}       = $power_status;
    $result->{"hardware"}{"device_fan"}         = $fan_status;
    $result->{"hardware"}{"device_disk"}        = $disk_status;
    $result->{"hardware"}{"device_alarm"}       = $alarm_status;
    $result->{"hardware"}{"device_temperature"} = $temperature_status;

    #-------------------------------------------------------------------------
    # 网络设备-关键运行指标巡检结果 --检查项3 共计6项
    #-------------------------------------------------------------------------
    $result->{"status"}{"device_cpu"}       = $cpu_status;
    $result->{"status"}{"device_memory"}    = $memory_status;
    $result->{"status"}{"device_ntp"}       = $ntp_status;
    $result->{"status"}{"device_vrrp"}      = $vrrp_status;
    $result->{"status"}{"device_eth_trunk"} = $eth_trunk_status;
    $result->{"status"}{"device_err_down"}  = $err_down_status;

    #-------------------------------------------------------------------------
    # 输出巡检结果
    #-------------------------------------------------------------------------
    return $result;
}

sub calculate_score {

    #接收health_check计算结果
    my $rev = shift;

    #设备硬件巡检哈希
    my $hardware = $rev->{"hardware"};

    #设备关键指标巡检哈希
    my $status = $rev->{"status"};

    #设备巡检项总数
    my $attr_count
        = ( scalar( keys %{$hardware} ) ) + ( scalar( keys %{$status} ) );

    #硬件巡检通过项计数
    my $hardware_attr = 0;
    foreach ( keys %{$hardware} ) {
        my $ret    = $hardware->{$_};
        my $health = $ret->{"health"};
        if ( defined $health && $health eq "pass" ) {
            ++$hardware_attr;
        }
        else {
            my $alarm = $ret->{"alarm"};
            if ( defined $alarm && $alarm eq "info" ) {
                $hardware_attr -= 0.1;
            }
            elsif ( defined $alarm && $alarm eq "alert" ) {
                $hardware_attr -= 0.2;
            }
            elsif ( defined $alarm && $alarm eq "critic" ) {
                $hardware_attr -= 0.7;
            }
        }
    }

    #关键指标巡检通过项计数
    my $status_attr = 0;
    foreach ( keys %{$status} ) {
        my $ret    = $status->{$_};
        my $health = $ret->{"health"};
        if ( defined $health && $health eq "pass" ) {
            ++$status_attr;
        }
        else {
            my $alarm = $ret->{"alarm"};
            if ( defined $alarm && $alarm eq "info" ) {
                $status_attr -= 0.1;
            }
            elsif ( defined $alarm && $alarm eq "alert" ) {
                $status_attr -= 0.2;
            }
            elsif ( defined $alarm && $alarm eq "critic" ) {
                $status_attr -= 0.7;
            }
        }
    }

    #计算巡检得分情况
    my $score = ( ( $hardware_attr + $status_attr ) / $attr_count ) * 100;

    #返回巡检得分项
    return $score;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 设备版本信息校验
#-------------------------------------------------------------------------
sub device_version {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #设备版本标量
    my $version;

    #遍历巡检结果以捕捉异常模块信息
    foreach ( @{$rev} ) {
        if (/Version\s(.*?)\s(.*)/) {

            #将巡检结果命令行分割为字符串数组
            my $version = $2;

            #将非必要字符串（）处理掉
            $version =~ s/\(//;
            $version =~ s/\)//;

            #捕捉到关键字即跳出
            last;
        }
    }

    #返回巡检结果
    return $version;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 设备模块检查
#-------------------------------------------------------------------------
sub module_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/Unregistered/i} @{$rev} ) ? 1 : 0;

    #设备健康检查
    return $result unless $ret;

    my @msg;

    #遍历巡检结果以捕捉异常模块信息
    foreach ( @{$rev} ) {
        if (/Unregistered/i) {

            #将巡检结果命令行写入数组中
            push @msg, $_;
        }
    }

    if (@msg) {

        #将异常信息写入日志中
        $result->{"log"} = "设备板卡告警：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #监控检查状态
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 电源模块检查
#-------------------------------------------------------------------------
sub power_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/NotSupply/i} @{$rev} ) ? 1 : 0;

    #设备健康检查
    return $result unless $ret;

    my @msg;

    #遍历巡检结果以捕捉异常模块信息
    foreach ( @{$rev} ) {
        if (/NotSupply/i) {

            #将巡检结果命令行写入数组中
            push @msg, $_;
        }
    }

    if (@msg) {

        #将异常信息写入日志中
        $result->{"log"} = "设备电源告警：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #监控检查状态
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 风扇模块检查
#-------------------------------------------------------------------------
sub fan_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/Abnormal/i} @{$rev} ) ? 1 : 0;

    #设备健康检查
    return $result unless $ret;

    my @msg;

    #遍历巡检结果以捕捉异常模块信息
    foreach ( @{$rev} ) {
        if (/Abnormal/i) {

            #将巡检结果命令行写入数组中
            push @msg, $_;
        }
    }

    if (@msg) {

        #将异常信息写入日志中
        $result->{"log"} = "设备风扇告警：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #监控检查状态
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 设备硬件告警检查
#-------------------------------------------------------------------------
sub alarm_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/(critic|alert)/i} @{$rev} ) ? 1 : 0;

    #设备健康检查
    return $result unless $ret;

    my @msg;

    #遍历巡检结果以捕捉异常模块信息
    foreach ( @{$rev} ) {
        if (/(?<alarm>(critic|alert))/i) {

            #将巡检结果命令行写入数组中
            push @msg, $_;
        }
    }

    if (@msg) {

        #将异常信息写入日志中
        $result->{"log"} = "设备硬件告警：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #监控检查状态
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 硬件温度告警检查
#-------------------------------------------------------------------------
sub temperature_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/Abnormal/i} @{$rev} ) ? 1 : 0;

    #设备健康检查
    return $result unless $ret;

    my @msg;

    #遍历巡检结果以捕捉异常模块信息
    foreach ( @{$rev} ) {
        if (/Abnormal/i) {

            #将巡检结果命令行写入数组中
            push @msg, $_;
        }
    }

    if (@msg) {

        #将异常信息写入日志中
        $result->{"log"} = "设备温度告警：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #监控检查状态
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 硬件存储告警检查
#-------------------------------------------------------------------------
sub disk_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #初始化硬盘巡检状态
    my $status = 0;
    my $storage;

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {

        #如果命中磁盘关键字将状态指为1
        if (/System Disk Usage Information/i) {
            $status = 1;
            push @{$storage}, $_;
        }

        #如果命中了存储关键字继续
        elsif ($status) {

            #写入后续巡检结果
            push @{$storage}, $_;
        }

        #检查是否命中主机名
        elsif (/^(\<.*\>|\[.*\])/i) {

            #将巡检输出置0，结束命令行捕捉
            $status = 0;
            last;
        }
    }

    foreach ( @{$storage} ) {
        if (/\s+(\d+)\%\s+/i) {

            #写入异常状态
            $result->{"log"} = "磁盘空间利用率告警：\n" . "$1\%"
                if ( $1 > $disk_threshold );
            $result->{"alarm"} = "info";

            #监控检查状态
            $result->{"health"} = "fail" if ( $1 > $disk_threshold );
        }
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- CPU利用率检查
#-------------------------------------------------------------------------
sub cpu_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {
        if (/CPU Using Percentage/i) {

            #将巡检结果命令行分割为字符串数组
            my @info = map {s/(^\s+|\s+$)//r} split( /\:/, $_ );

            #将CPU运行利用率取出
            my $usage = $info[1];

            #处理利用率指标前后空白字符串
            $usage =~ s/(^\s+|\s+$)//;

            #去除%
            $usage =~ s/\%//;

            #写入异常状态
            $result->{"log"}
                = "CPU利用率超出当前阈值： " . "$usage\%"
                if $usage >= $cpu_threshold;

            #设置越线惩罚机制
            if ( 60 <= $usage && $usage < 70 ) {
                $result->{"alarm"} = "info";
            }
            elsif ( 70 <= $usage && $usage < 80 ) {
                $result->{"alarm"} = "alert";
            }
            elsif ( $usage >= 80 ) {
                $result->{"alarm"} = "critic";
            }

            #监控检查状态
            $result->{"health"} = "fail" if ( $usage >= $cpu_threshold );
        }

        #------------------------------------------------------
        # 检查逻辑待优化
        #------------------------------------------------------
        elsif (/Max CPU Usage \:/i) {

            #将巡检结果命令行分割为字符串数组
            my @info = map {s/(^\s+|\s+$)//r} split( /\:/, $_ );

            #将历史CPU MAX 运行利用率取出
            my $max_usage = $info[1];

            #处理利用率指标前后空白字符串
            $max_usage =~ s/(^\s+|\s+$)//;

            #去除%
            $max_usage =~ s/\%//;

            #写入异常状态
            $result->{"log"}
                = "CPU历史最大利用率超出阈值：" . "$max_usage\%"
                if $max_usage > $cpu_max_threshold;

            $result->{"alarm"} = "critic" if $max_usage > $cpu_max_threshold;

            #监控检查状态
            $result->{"health"} = "fail" if $max_usage > $cpu_max_threshold;
            last;
        }
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- 内存利用率检查
#-------------------------------------------------------------------------
sub memory_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #设置缺省检查结果为PASS

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {
        if (/Memory Using Percentage/i) {

            #将巡检结果命令行分割为字符串数组
            my @info = map {s/(^\s+|\s+$)//r} split( /\:/, $_ );

            #取出内存利用率
            my $usage = $info[1];

            #处理利用率指标前后空白字符串
            $usage =~ s/(^\s+|\s+$)//;

            #去除%字符串
            $usage =~ s/\%//;

            #写入异常状态
            $result->{"log"}
                = "内存利用率超出当前阈值：" . "$usage\%"
                if ( $usage > $memory_threshold );

            #设置越线惩罚机制
            if ( 60 <= $usage && $usage < 70 ) {
                $result->{"alarm"} = "info";
            }
            elsif ( 70 <= $usage && $usage < 80 ) {
                $result->{"alarm"} = "alert";
            }
            elsif ( $usage >= 80 ) {
                $result->{"alarm"} = "critic";
            }

            #监控检查状态
            $result->{"health"} = "fail" if ( $usage >= $memory_threshold );
        }
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- NTP同步状态检查
#-------------------------------------------------------------------------
sub ntp_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {
        if (/clock status/i) {

            #将巡检结果命令行分割为字符串数组
            my @info = map {s/(^\s+|\s+$)//r} split( /\:/, $_ );

            #取出内存利用率
            my $status = $info[1];

            #处理利用率指标前后空白字符串
            $status =~ s/(^\s+|\s+$)//;

            #写入异常状态
            $result->{"log"} = "NTP时钟源未同步\n"
                if ( $status eq "unsynchronized" );
            $result->{"alarm"} = "info";

            #监控检查状态
            $result->{"health"} = "fail" if ( $status eq "unsynchronized" );
        }
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- VRRP状态检查
#-------------------------------------------------------------------------
sub vrrp_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/Info: The VRRP does not exist/i} @{$rev} ) ? 1 : 0;

    #巡检结果命令行输出不存在则跳过
    return $result if $ret;

    my @msg;

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {
        if (/Initialize/i) {
            push @msg, $_;
        }
    }

    #写入异常状态信息
    if (@msg) {

        #添加异常信息到日志
        $result->{"log"}
            = "检测到VRRP工作异常：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #写入后续巡检结果
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- ETH-TRUNK状态检查
#-------------------------------------------------------------------------
sub eth_trunk_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret = ( grep {/Unselect/i} @{$rev} ) ? 1 : 0;

    #巡检结果命令行输出不存在则跳过
    return $result unless $ret;

    my @msg;

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {

        #匹配异常状态信息
        if (/Unselect/i) {

            #将巡检结果命令行写入数组中
            push @msg, $_;
        }
    }

    if (@msg) {

        #写入异常状态信息
        $result->{"log"} = "ETH-TRUNK接口异常：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "critic";

        #写入后续巡检结果
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

#-------------------------------------------------------------------------
# 网络设备-硬件运行状态巡检 -- ERR-DOWN状态检查
#-------------------------------------------------------------------------
sub err_down_status {

    #接收巡检命令行输出
    my $rev = shift;

    #如果没匹配到巡检输出直接返回
    return unless $rev;

    #模块巡检标量
    my $result;

    #初始化巡检结果告警项
    $result->{"alarm"}  = undef;
    $result->{"health"} = "pass";
    $result->{"log"}    = undef;

    #重组巡检结果拼接为字符串
    my $origin = join( "\n", @{$rev} );
    $result->{"origin"} = $origin;

    #快速检查是否有未注册的模块
    my $ret
        = ( grep {/Info: No error-down interface exists/i} @{$rev} ) ? 1 : 0;

    #巡检结果命令行输出不存在则跳过
    return $result if $ret;

    my @msg;

 #遍历巡检结果以捕捉异常模块信息,仅关注最新的告警信息
    foreach ( @{$rev} ) {
        if (/(efm-threshold-event|efm-remote-failure|bpdu-protection|link-flap|storm-control|mac-address-flapping)/i
            )
        {
            #将命中行写入数组中
            push @msg, $_;
        }
    }
    if (@msg) {

        #写入异常状态
        $result->{"log"} = "接口 error-down：\n" . join( "\n", @msg );

        #设置告警等级
        $result->{"alarm"} = "alert";

        #监控检查状态
        $result->{"health"} = "fail";
    }

    #返回巡检结果
    return $result;
}

1;

