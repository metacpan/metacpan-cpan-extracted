package Huawei::Info::Ipaddr;

use 5.012;
use warnings;
no warnings 'uninitialized';

use Net::Compare;
use File::Next;

#继承EXPORTER属性
use Exporter;
use parent 'Exporter';

#设备版本信息和默认导出函数
our $VERSION = 0.02;
our @EXPORT  = qw 'switch_arp_mac arp_mac_info arp_mac_get';

#------------------------------------------------------------------------------
# 常量 ip_str mac_str 数据格式
#------------------------------------------------------------------------------
my $ip_str  = '(\d+\.){3}\d+';
my $mac_str = '([0-9a-fA-F]{4}\-){2}([0-9a-fA-F]{4})';

#------------------------------------------------------------------------------
# 数据中心 -- 机房数据字典
#------------------------------------------------------------------------------
my %dc_map = (
    "CC-DC1" => "chaosuan",
    "CC-DC2" => "pengboshi",
    "HT"     => "huitian",
    "CYM"    => "chaoyangmen",
);

#------------------------------------------------------------------------------
# 华为交换机 IP-MAC 解析函数入口 -- 接收待解析的文件夹
#------------------------------------------------------------------------------
sub arp_mac_info {

    #接收待解析的配置文件夹
    my $dir = shift;

    #计算配置解析结果
    my $rev = arp_mac_get($dir);

    #解析 arp_info
    my $arp_info = $rev->{"arp_info"};

    #解析 mac_info
    my $mac_info = $rev->{"mac_info"};

    #设备本身 ipaddr 信息
    my $ret1;

    #接入层连接设备 ipaddr 信息
    my $ret2;

    #第一阶段，抓取设备本身IP地址信息
    foreach my $device ( @{$arp_info} ) {

        #获取设备 arp_info 详情
        $device = $device->{ join( '', keys %{$device} ) };

        #获取设备位置
        my $location = $device->{"location"};

        #获取设备名称
        my $hostname = $device->{"hostname"};

        #获取设备接口
        next unless ( exists $device->{"interface"} );
        my $interfaces = $device->{"interface"};

        #遍历设备接口
        foreach my $interface ( keys %{$interfaces} ) {
            my $int_info = $interfaces->{$interface};

            #遍历接口下的 Ipaddr
            foreach my $ip ( keys %{$int_info} ) {
                my $ip_info = $int_info->{$ip};

                #获取arp等信息
                my $exp_time = $ip_info->{"exp_time"};
                my $mac      = $ip_info->{"mac"};
                my $vlan     = $ip_info->{"vlan"} || undef;

                #如果arp永不超时，则认为设备本身ipaddr
                if ( $exp_time eq "forever" ) {

                    #绑定IP写入结果
                    $ret1->{$ip}{"location"}  = $location;
                    $ret1->{$ip}{"hostname"}  = $hostname;
                    $ret1->{$ip}{"interface"} = $interface;
                    $ret1->{$ip}{"mac"}       = $mac;
                    $ret1->{$ip}{"vlan"}      = $vlan;
                    $ret1->{$ip}{"ip"}        = $ip;
                }
            }
        }
    }

    #第二阶段，抓取接入层交换机MAC地址对应的IP信息
    foreach my $device ( @{$mac_info} ) {

        #抓取设备MAC信息
        $device = $device->{ join( '', keys %{$device} ) };

        #获取设备位置信息
        my $location = $device->{"location"};

        #获取设备主机名
        my $hostname = $device->{"hostname"};

        #获取设备接口
        next unless ( exists $device->{"interface"} );
        my $interfaces = $device->{"interface"};

        #实例化相关变量
        my $mac;
        my $vlan;

        #遍历接口信息
        foreach my $interface ( keys %{$interfaces} ) {

            #获取接口信息
            my $int_info = $interfaces->{$interface};

            #设备接口 MAC VLAN 信息
            foreach $mac ( keys %{$int_info} ) {

                #获取相关的VLAN信息
                $vlan = $int_info->{$mac};

                #遍历arp相关信息
                foreach my $arp_device ( @{$arp_info} ) {

                  #获取实际的内容 -- 待修复
                  #my $detail = $arp_device->{join ('', keys %{$arp_device})};

                    #获取设备接口
                    next unless ( exists $arp_device->{"interface"} );
                    my $ints = $arp_device->{"interface"};

                    #遍历设备接口
                    foreach my $int ( keys %{$ints} ) {
                        my $int_info = $ints->{$int};

                        #遍历接口下的 Ipaddr
                        foreach my $ip ( keys %{$int_info} ) {
                            my $ip_info = $int_info->{$ip};

                            #获取arp_mac地址信息
                            my $arp_mac = $ip_info->{"mac"};

                            #如果mac相同则匹配成功
                            if ( $mac eq $arp_mac ) {

                                #绑定IP写入结果
                                $ret2->{$ip}{"location"}  = $location;
                                $ret2->{$ip}{"hostname"}  = $hostname;
                                $ret2->{$ip}{"interface"} = $interface;
                                $ret2->{$ip}{"mac"}       = $mac;
                                $ret2->{$ip}{"vlan"}      = $vlan;
                                $ret2->{$ip}{"ip"}        = $ip;
                            }
                        }
                    }
                }
            }
        }
    }

    #返回计算结果
    my $ret = [ $ret1, $ret2 ];
    return $ret;
}

#------------------------------------------------------------------------------
# 华为交换机 IP-MAC 批量解析
#------------------------------------------------------------------------------
sub arp_mac_get {

    #接收待解析的配置文件夹
    my $dir = shift;

    #实例化解析结果
    my $ret;

    #实例化 File::Next 对象
    my $files = File::Next::files($dir);

    #迭代取出文件内所有可读文件
    while ( defined( my $file = $files->() ) ) {

        #初始化变量
        my $rev;

        #抓取cfg文件开始解析
        if ( $file =~ /\.(config|conf|cfg|)$/ ) {

            #解析单个文件输出
            $rev = switch_arp_mac($file);

            #如果命中，将解析结果拆解到 函数 $ret
            push @{ $ret->{"arp_info"} }, $rev->{"arp_info"};
            push @{ $ret->{"mac_info"} }, $rev->{"mac_info"};
        }
        else {
            print "$file not parsed \n";
        }
    }

    #返回计算结果
    return $ret;
}

#------------------------------------------------------------------------------
# 华为交换机ARP MAC地址解析函数入口
#------------------------------------------------------------------------------
sub switch_arp_mac {
    my $file = shift;

    #固话ARP MAC获取命令行
    my $arp_cmd = "dis arp";
    my $mac_cmd = "dis mac-address";

    #捕捉命令行输出结果
    my $arp_rev = catch_cmd( $arp_cmd, $file );
    my $mac_rev = catch_cmd( $mac_cmd, $file );

    #计算mac和arp相关属性
    my $arp_ret = switch_arp($arp_rev);
    my $mac_ret = switch_mac($mac_rev);

    #输出计算结果
    my $ret = {
        "arp_info" => $arp_ret,
        "mac_info" => $mac_ret,
    };

    return $ret;
}

#------------------------------------------------------------------------------
#交换机ARP地址解析用例
#IP ADDRESS      MAC ADDRESS    EXP(M) TYPE/VLAN      INTERFACE    VPN-INSTANCE
#------------------------------------------------------------------------------
#10.4.26.21      0433-8948-9b00        I               MEth0/0/0        MGMT
#------------------------------------------------------------------------------
sub switch_arp {

    #接收切割的配置文件
    my $config = shift;

    #抓取配置中主机名
    my $hostname;
    foreach ( @{$config} ) {
        if (/<(?<hostname>.*?)>/) {

            #将命中数据写入变量
            $hostname = $+{hostname};

            #找到即跳出
            last;
        }
    }

    #获取所在机房信息
    my $location;

    #遍历哈希
    foreach my $dc ( keys %dc_map ) {

        #检查是否命中数据字典
        if ( $hostname && $hostname =~ $dc ) {

            #匹配机房字典
            $location = $dc_map{$dc};

            #找到即跳出
            last;
        }
    }

    my $ret;
    $ret->{$hostname}{"hostname"} = $hostname // "UNKNOW";

    #绑定设备所在位置
    $ret->{$hostname}{"location"} = $location // "UNKNOW";

    #遍历元素，构造数据结构
    foreach my $cli ( @{$config} ) {

        #捕捉实际的 dis arp 输出命令
        if ( $cli
            =~ /(?<ipaddr>(\d{1,3}\.){3}(\d{1,3}))\s+(?<mac>(([0-9a-fA-F]{4}\-){2})[0-9a-fA-F]{4})\s+(?<exp_time>\d+\s+)?(?<type_vlan>(.*?))\s+(?<interface>.*?)\s+(?<vpn_instance>.*?)$/
            )
        {
            #获取解析结果
            my $ipaddr    = $+{ipaddr};
            my $interface = $+{interface};

            #分解type vlan数据
            my ( $type, $vlan ) = split( /\//, $+{type_vlan} );

            #输出解析结果
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}{"ipaddr"}
                = $ipaddr;
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}{"mac"}
                = $+{mac};
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}{"exp_time"}
                = $+{exp_time} || "forever";
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}{"type"}
                = $type || undef;
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}{"vlan"}
                = $vlan || undef;
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}{"interface"}
                = $interface || undef;
            $ret->{$hostname}{"interface"}{$interface}{$ipaddr}
                {"vpn_instance"} = $+{vpn_instance} || undef;
        }
    }

    #返回输出结果
    return $ret;
}

#------------------------------------------------------------------------------
#交换机MAC地址解析用例  -- 交换机本身IP 为GE打头的接口
#MAC Address    VLAN/VSI/BD   Learned-From        Type                Age
#------------------------------------------------------------------------------
#0000-5e00-0102 3200/-/-      Eth-Trunk120        dynamic         1829268
#------------------------------------------------------------------------------
sub switch_mac {

    #接收切割的配置文件
    my $config = shift;

    #抓取配置中主机名
    my $hostname;
    foreach ( @{$config} ) {
        if (/<(?<hostname>.*?)>/) {

            #将命中数据写入变量
            $hostname = $+{hostname};

            #找到即跳出
            last;
        }
    }

    #获取所在机房信息
    my $location;

    #遍历哈希
    foreach my $dc ( keys %dc_map ) {

        #检查是否命中数据字典
        if ( $hostname && $hostname =~ $dc ) {

            #匹配机房字典
            $location = $dc_map{$dc};

            #找到即跳出
            last;
        }
    }

    #初始化计算结构
    my $ret;
    $ret->{$hostname}{"hostname"} = $hostname // "UNKNOW";

    #绑定设备所在位置
    $ret->{$hostname}{"location"} = $location // "UNKNOW";

    #遍历元素，构造数据结构
    foreach my $cli ( @{$config} ) {

        #捕捉实际的 dis arp 输出命令
        if ( $cli =~ /$mac_str/ ) {

            #实例化变量
            my ( $mac, $vlan_vsi_bd, $interface ) = split( /\s+/, $cli );

            #抽取MAC对应的VLAN信息
            my ( $vlan, $vsi, $bd ) = split( /\//, $vlan_vsi_bd );

            #过滤非物理接口
            if ( $interface =~ /GE|Vlanif/i ) {

              #输出匹配信息 如果未命中VLAN则使用VXLAN的BD绑定
                if ( $vlan eq '-' ) {
                    $ret->{$hostname}{"interface"}{$interface}{$mac} = $bd;
                }

                #命中VLAN则直接写入VLAN标识
                else {
                    $ret->{$hostname}{"interface"}{$interface}{$mac} = $vlan;
                }
            }
        }
    }

    #返回输出结果
    return $ret;
}

1;


