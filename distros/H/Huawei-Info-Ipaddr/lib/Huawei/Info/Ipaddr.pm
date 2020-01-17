package Huawei::Info::Ipaddr;

use 5.012;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;

use Net::Compare;
use File::Next;

#继承EXPORTER属性
use Exporter;
use parent 'Exporter';

#设备版本信息和默认导出函数
our $VERSION = 0.09;
our @EXPORT =
  qw 'ip_info info_parser device_arp device_mac device_nei device_eth device_info';

#------------------------------------------------------------------------------
# 常量 ip_str mac_str 数据格式
#------------------------------------------------------------------------------
my $ip_str  = '(\d+\.){3}\d+';
my $mac_str = '([0-9a-fA-F]{4}\-){2}([0-9a-fA-F]{4})';

#------------------------------------------------------------------------------
# 数据中心 -- 机房数据字典
#------------------------------------------------------------------------------
my %dc_map = (
  "CC-DC1"   => "chaosuan",
  "CC-DC2"   => "pengboshi",
  "HT"       => "huitian",
  "CYM"      => "chaoyangmen",
  "650"      => "ZH650",
  "CC-ZXDS"  => "CC-ZXDS",
  "CC-RCDS"  => "CC-RCDS",
  "CC-ZHXHL" => "CC-ZHXHL",
  "CC-ZHXDX" => "CC-ZHXDX",
  "CC-ZHXLD" => "CC-ZHXLD",
);

#------------------------------------------------------------------------------
# 华为交换机 IP-MAC 解析函数入口 -- 接收待解析的文件夹
#------------------------------------------------------------------------------
sub ip_info {

  #接收待解析的配置文件夹
  my $dir = shift;

  #计算配置解析结果
  my $rev = info_parser($dir);

  #解析 arp_info
  my $arp_info = $rev->{"arp_info"};

  #解析 mac_info
  my $mac_info = $rev->{"mac_info"};

  #解析 nei_info
  my $nei_info = $rev->{"nei_info"};

  #解析 eth_info
  my $eth_info = $rev->{"eth_info"};

  #解析 location
  my $location = $rev->{"location"};

  #设备本身 ipaddr 信息
  my $ret1;

  #接入层连接设备 ipaddr 信息
  my $ret2;

  #Incomplete ARP 表项
  my $ret3;

  #匹配到的IPPHONE
  my $ret4;

  #匹配到的 802.1X 认证
  my $ret5;

  #IP解析未匹配到 MAC
  my $ret6;

  #遍历当前ARP解析项
  foreach my $device ( keys %{$arp_info} ) {

    #获取当前设备所在机房位置
    my $device_location = $location->{$device};

    #获取当前设备 arp_info 哈希对象
    my $device_rev = $arp_info->{$device};

    #获取当前设备的 mac_info 哈希对象
    my $device_mac = $mac_info->{$device};

    #阶段一 -- 获取设备自身IP地址，索引为设备下自身接口
    foreach my $self_interface ( keys %{ $device_rev->{"self_ip"} } ) {

      #获取当前接口下的IP地址详情
      my $interface_info = $device_rev->{"self_ip"}{$self_interface};

      #遍历当前元素下所有的字段属性
      foreach my $ip_info ( keys %{$interface_info} ) {

        #获取IP地址属性实例
        my $ip_ret = $interface_info->{$ip_info};

        #获取arp等信息
        my $exp_time     = $ip_ret->{"exp_time"};
        my $mac          = $ip_ret->{"mac"};
        my $vlan         = $ip_ret->{"vlan"};
        my $vpn_instance = $ip_ret->{"vpn_instance"};

        #将解析到的结果写入数据结构
        $ret1->{$ip_info}{"location"}     = $device_location;
        $ret1->{$ip_info}{"hostname"}     = $device;
        $ret1->{$ip_info}{"interface"}    = $self_interface;
        $ret1->{$ip_info}{"mac"}          = $mac;
        $ret1->{$ip_info}{"vlan"}         = $vlan;
        $ret1->{$ip_info}{"vpn_instance"} = $vpn_instance;
        $ret1->{$ip_info}{"gate_device"}  = undef;
      }
    }

    #阶段二 -- 获取设备下异常 arp 表项，索引为设备下自身接口
    foreach my $self_interface ( keys %{ $device_rev->{"incomplete"} } ) {

      #获取当前接口下的IP地址详情
      my $interface_info = $device_rev->{"incomplete"}{$self_interface};

      #遍历当前元素下所有的字段属性
      foreach my $ip_info ( keys %{$interface_info} ) {

        #获取IP地址属性实例
        my $ip_ret = $interface_info->{$ip_info};

        #获取arp等信息
        my $exp_time     = $ip_ret->{"exp_time"};
        my $mac          = $ip_ret->{"mac"};
        my $vlan         = $ip_ret->{"vlan"};
        my $vpn_instance = $ip_ret->{"vpn_instance"};

        #将解析到的结果写入数据结构
        $ret3->{$ip_info}{"location"}     = $device_location;
        $ret3->{$ip_info}{"hostname"}     = $device;
        $ret3->{$ip_info}{"interface"}    = $self_interface;
        $ret3->{$ip_info}{"mac"}          = $mac;
        $ret3->{$ip_info}{"vlan"}         = $vlan;
        $ret3->{$ip_info}{"vpn_instance"} = $vpn_instance;
        $ret3->{$ip_info}{"gate_device"}  = undef;
      }
    }

    #阶段三 -- 计算设备当前的ARP表项，索引为设备下自身接口
    foreach my $self_interface ( keys %{ $device_rev->{"dynamic"} } ) {

      #获取当前接口下的IP地址详情
      my $interface_info = $device_rev->{"dynamic"}{$self_interface};

      #遍历当前元素下所有的字段属性
      foreach my $ip_info ( keys %{$interface_info} ) {

        #获取IP地址属性实例
        my $ip_ret = $interface_info->{$ip_info};

        #获取arp等信息
        my $exp_time     = $ip_ret->{"exp_time"};
        my $mac          = $ip_ret->{"mac"};
        my $vlan         = $ip_ret->{"vlan"};
        my $vpn_instance = $ip_ret->{"vpn_instance"};

        #检查ARP学习接口是否为ETH-TRUNK
        if ( $self_interface =~ /Eth-Trunk/ ) {

          #裁剪eth-trunk相关参数
          $self_interface =~ s/\.\d+$//;

          #获取当前ETH-TRUNK的成员接口信息
          my $eth_member = $eth_info->{$device}{$self_interface};

          #遍历当前eth_member接口发现的邻居下的MAC
          foreach my $member ( @{$eth_member} ) {

            #获取当前接口的邻居设备，输出为邻居设备名
            my $device_nei = $nei_info->{$device}{$member}{"neighbor"};

            #判断是否为 ipPhone
            if ( $device_nei =~ /eSpace/i ) {

              #如果命中IP电话，将解析到的结果写入数据结构
              $ret4->{$ip_info}{"location"}     = $device_location;
              $ret4->{$ip_info}{"hostname"}     = $device;
              $ret4->{$ip_info}{"interface"}    = $member;
              $ret4->{$ip_info}{"mac"}          = $mac;
              $ret4->{$ip_info}{"vlan"}         = $vlan;
              $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
              $ret4->{$ip_info}{"gate_device"}  = $device;

              #找到即停
              next;
            }

            #判断是否存在邻居信息
            elsif ( $device_nei && defined $device_nei ) {

              #获取邻居设备的机房位置
              my $nei_location = $location->{$device_nei};

              #调取该设备的MAC地址对象
              my $nei_mac = $mac_info->{$device_nei};

              #遍历邻居的MAC地址信息，寻找能与当前ARP配对接口
              foreach my $nei_interface ( keys %{$nei_mac} ) {

                #获取当前邻居的MAC地址表
                my $nei_ret = $nei_mac->{$nei_interface};

                #判断MAC是否为 authen 类型
                my $mac_type = $nei_ret->{"type"};

                #遍历该接口下所有的MAC地址信息
                foreach my $mac_rev ( keys %{$nei_ret} ) {

                  #如果非MAC地址则调整
                  next unless $mac_rev =~ $mac_str;

                  #获取 mac_vlan 地址
                  my $mac_vlan = $nei_ret->{$mac_rev};

                  #判断MAC地址是否为802.1X认证
                  if ( $mac_type =~ /authen/
                    && $mac eq $mac_rev )
                  {

                    #将解析到的结果写入数据结构
                    $ret5->{$ip_info}{"location"}     = $nei_location;
                    $ret5->{$ip_info}{"hostname"}     = $device_nei;
                    $ret5->{$ip_info}{"vlan"}         = $mac_vlan;
                    $ret5->{$ip_info}{"mac"}          = $mac;
                    $ret5->{$ip_info}{"interface"}    = $nei_interface;
                    $ret5->{$ip_info}{"vpn_instance"} = $vpn_instance;
                    $ret5->{$ip_info}{"gate_device"}  = $device;
                  }

                  #判断MAC地址是否为 静态绑定 sticky
                  elsif ( $mac_type =~ /sticky/
                    && $mac eq $mac_rev )
                  {

                    #将解析到的结果写入数据结构
                    $ret4->{$ip_info}{"location"}     = $nei_location;
                    $ret4->{$ip_info}{"hostname"}     = $device_nei;
                    $ret4->{$ip_info}{"interface"}    = $nei_interface;
                    $ret4->{$ip_info}{"mac"}          = $mac;
                    $ret4->{$ip_info}{"vlan"}         = $mac_vlan;
                    $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
                    $ret4->{$ip_info}{"gate_device"}  = $device;
                  }

                  #进行逻辑判断，是否匹配当前ARP表项
                  elsif ( $mac eq $mac_rev ) {

                    #将解析到的结果写入数据结构
                    $ret2->{$ip_info}{"location"}     = $nei_location;
                    $ret2->{$ip_info}{"hostname"}     = $device_nei;
                    $ret2->{$ip_info}{"vlan"}         = $mac_vlan;
                    $ret2->{$ip_info}{"mac"}          = $mac;
                    $ret2->{$ip_info}{"interface"}    = $nei_interface;
                    $ret2->{$ip_info}{"vpn_instance"} = $vpn_instance;
                    $ret2->{$ip_info}{"gate_device"}  = $device;
                  }
                }
              }
            }

            #如果对端不支持邻居发现
            elsif ( not defined $device_nei ) {

              #查找设备本身ETH-TRUNK下的接口MAC
              my $dev_mac = $mac_info->{$device};

              #遍历设备本身的MAC地址信息，寻找能与当前ARP配对接口
              foreach my $dev_interface ( keys %{$dev_mac} ) {

                #获取当前邻居的MAC地址表
                my $dev_ret = $dev_mac->{$dev_interface};

                #判断MAC是否为 authen 类型
                my $mac_type = $dev_ret->{"type"};

                #遍历该接口下所有的MAC地址信息
                foreach my $mac_rev ( keys %{$dev_ret} ) {

                  #如果非MAC地址则调整
                  next unless $mac_rev =~ $mac_str;

                  #获取 mac_vlan 地址
                  my $mac_vlan = $dev_ret->{$mac_rev};

                  #判断MAC地址是否为802.1X认证
                  if ( $mac_type =~ /authen/
                    && $mac eq $mac_rev )
                  {

                    #将解析到的结果写入数据结构
                    $ret5->{$ip_info}{"location"}     = $device_location;
                    $ret5->{$ip_info}{"hostname"}     = $device;
                    $ret5->{$ip_info}{"vlan"}         = $mac_vlan;
                    $ret5->{$ip_info}{"mac"}          = $mac;
                    $ret5->{$ip_info}{"interface"}    = $dev_interface;
                    $ret5->{$ip_info}{"vpn_instance"} = $vpn_instance;
                    $ret5->{$ip_info}{"gate_device"}  = $device;
                  }

                  #判断MAC地址是否为 静态绑定 sticky
                  elsif ( $mac_type =~ /sticky/
                    && $mac eq $mac_rev )
                  {

                    #将解析到的结果写入数据结构
                    $ret4->{$ip_info}{"location"}     = $device_location;
                    $ret4->{$ip_info}{"hostname"}     = $device;
                    $ret4->{$ip_info}{"vlan"}         = $mac_vlan;
                    $ret4->{$ip_info}{"mac"}          = $mac;
                    $ret4->{$ip_info}{"interface"}    = $dev_interface;
                    $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
                    $ret4->{$ip_info}{"gate_device"}  = $device;
                  }

                  #进行逻辑判断，是否匹配当前ARP表项
                  elsif ( $mac eq $mac_rev ) {

                    #将解析到的结果写入数据结构
                    $ret2->{$ip_info}{"location"}     = $device_location;
                    $ret2->{$ip_info}{"hostname"}     = $device;
                    $ret2->{$ip_info}{"vlan"}         = $mac_vlan;
                    $ret2->{$ip_info}{"mac"}          = $mac;
                    $ret2->{$ip_info}{"interface"}    = $dev_interface;
                    $ret2->{$ip_info}{"vpn_instance"} = $vpn_instance;
                    $ret2->{$ip_info}{"gate_device"}  = $device;
                  }
                }
              }
            }
          }
        }

        #检查ARP学习接口是否支持LLDP发现
        elsif ( $self_interface =~ /GE|Eth\d/ ) {

          #裁剪eth-trunk相关参数
          $self_interface =~ s/\.\d+$//;

          #获取当前接口的邻居设备，输出为邻居设备名
          my $device_nei = $nei_info->{$device}{$self_interface}{"neighbor"};

          #判断是否为 ipPhone
          if ( $device_nei =~ /eSpace/i ) {

            #如果命中IP电话，将解析到的结果写入数据结构
            $ret4->{$ip_info}{"location"}     = $device_location;
            $ret4->{$ip_info}{"hostname"}     = $device;
            $ret4->{$ip_info}{"interface"}    = $self_interface;
            $ret4->{$ip_info}{"mac"}          = $mac;
            $ret4->{$ip_info}{"vlan"}         = $vlan;
            $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
            $ret4->{$ip_info}{"gate_device"}  = $device;

            #找到即停
            next;
          }

          #查看是否匹配
          elsif ( $device_nei && defined $device_nei ) {

            #获取邻居设备的机房位置
            my $nei_location = $location->{$device_nei};

            #调取该设备的MAC地址对象
            my $nei_mac = $mac_info->{$device_nei};

            #遍历邻居的MAC地址信息，寻找能与当前ARP配对接口
            foreach my $nei_interface ( keys %{$nei_mac} ) {

              #获取当前邻居的MAC地址表
              my $nei_ret = $nei_mac->{$nei_interface};

              #判断MAC是否为 authen 类型
              my $mac_type = $nei_ret->{"type"};

              #遍历该接口下所有的MAC地址信息
              foreach my $mac_rev ( keys %{$nei_ret} ) {

                #如果非MAC地址则调整
                next unless $mac_rev =~ $mac_str;

                #获取 mac_vlan 地址
                my $mac_vlan = $nei_ret->{$mac_rev};

                #判断MAC地址是否为802.1X认证
                if ( $mac_type =~ /authen/
                  && $mac eq $mac_rev )
                {

                  #将解析到的结果写入数据结构
                  $ret5->{$ip_info}{"location"}     = $nei_location;
                  $ret5->{$ip_info}{"hostname"}     = $device_nei;
                  $ret5->{$ip_info}{"interface"}    = $nei_interface;
                  $ret5->{$ip_info}{"mac"}          = $mac;
                  $ret5->{$ip_info}{"vlan"}         = $mac_vlan;
                  $ret5->{$ip_info}{"vpn_instance"} = $vpn_instance;
                  $ret5->{$ip_info}{"gate_device"}  = $device;
                }

                #判断MAC地址是否为 静态绑定 sticky
                elsif ( $mac_type =~ /sticky/
                  && $mac eq $mac_rev )
                {

                  #将解析到的结果写入数据结构
                  $ret4->{$ip_info}{"location"}     = $nei_location;
                  $ret4->{$ip_info}{"hostname"}     = $device_nei;
                  $ret4->{$ip_info}{"interface"}    = $nei_interface;
                  $ret4->{$ip_info}{"mac"}          = $mac;
                  $ret4->{$ip_info}{"vlan"}         = $mac_vlan;
                  $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
                  $ret4->{$ip_info}{"gate_device"}  = $device;
                }

                #进行逻辑判断，是否匹配当前ARP表项
                elsif ( $mac eq $mac_rev ) {

                  #将解析到的结果写入数据结构
                  $ret2->{$ip_info}{"location"}     = $nei_location;
                  $ret2->{$ip_info}{"hostname"}     = $device_nei;
                  $ret2->{$ip_info}{"interface"}    = $nei_interface;
                  $ret2->{$ip_info}{"mac"}          = $mac;
                  $ret2->{$ip_info}{"vlan"}         = $mac_vlan;
                  $ret2->{$ip_info}{"vpn_instance"} = $vpn_instance;
                  $ret2->{$ip_info}{"gate_device"}  = $device;
                }
              }
            }
          }

          #如果对端不支持邻居发现再查找本地MAC地址
          elsif ( not defined $device_nei ) {

            #查找设备本身ETH-TRUNK下的接口MAC
            my $dev_mac = $mac_info->{$device};

            #遍历设备本身的MAC地址信息，寻找能与当前ARP配对接口
            foreach my $dev_interface ( keys %{$dev_mac} ) {

              #获取当前邻居的MAC地址表
              my $dev_ret = $dev_mac->{$dev_interface};

              #判断MAC是否为 authen 类型
              my $mac_type = $dev_ret->{"type"};

              #遍历该接口下所有的MAC地址信息
              foreach my $mac_rev ( keys %{$dev_ret} ) {

                #如果非MAC地址则调整
                next unless $mac_rev =~ $mac_str;

                #获取 mac_vlan 地址
                my $mac_vlan = $dev_ret->{$mac_rev};

                #判断MAC地址是否为802.1X认证
                if ( $mac_type =~ /authen/
                  && $mac eq $mac_rev )
                {

                  #将解析到的结果写入数据结构
                  $ret5->{$ip_info}{"location"}     = $device_location;
                  $ret5->{$ip_info}{"hostname"}     = $device;
                  $ret5->{$ip_info}{"vlan"}         = $mac_vlan;
                  $ret5->{$ip_info}{"mac"}          = $mac;
                  $ret5->{$ip_info}{"interface"}    = $dev_interface;
                  $ret5->{$ip_info}{"vpn_instance"} = $vpn_instance;
                  $ret5->{$ip_info}{"gate_device"}  = $device;
                }

                #判断MAC地址是否为 静态绑定 sticky
                elsif ( $mac_type =~ /sticky/
                  && $mac eq $mac_rev )
                {

                  #将解析到的结果写入数据结构
                  $ret4->{$ip_info}{"location"}     = $device_location;
                  $ret4->{$ip_info}{"hostname"}     = $device;
                  $ret4->{$ip_info}{"vlan"}         = $mac_vlan;
                  $ret4->{$ip_info}{"mac"}          = $mac;
                  $ret4->{$ip_info}{"interface"}    = $dev_interface;
                  $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
                  $ret4->{$ip_info}{"gate_device"}  = $device;
                }

                #进行逻辑判断，是否匹配当前ARP表项
                elsif ( $mac eq $mac_rev ) {

                  #将解析到的结果写入数据结构
                  $ret2->{$ip_info}{"location"}     = $device_location;
                  $ret2->{$ip_info}{"hostname"}     = $device;
                  $ret2->{$ip_info}{"vlan"}         = $mac_vlan;
                  $ret2->{$ip_info}{"mac"}          = $mac;
                  $ret2->{$ip_info}{"interface"}    = $dev_interface;
                  $ret2->{$ip_info}{"vpn_instance"} = $vpn_instance;
                  $ret2->{$ip_info}{"gate_device"}  = $device;
                }
              }
            }
          }
        }

        #如果都没找到再次查找设备本身 MAC
        else {

          #遍历邻居的MAC地址信息，寻找能与当前ARP配对接口
          foreach my $dev_interface ( keys %{$device_mac} ) {

            #获取当前邻居的MAC地址表
            my $dev_ret = $device_mac->{$dev_interface};

            #判断MAC是否为 authen 类型
            my $mac_type = $dev_ret->{"type"};

            #遍历该接口下所有的MAC地址信息
            foreach my $mac_rev ( keys %{$dev_ret} ) {

              #如果非MAC地址则调整
              next unless $mac_rev =~ $mac_str;

              #获取 mac_vlan 地址
              my $mac_vlan = $dev_ret->{$mac_rev};

              #判断MAC地址是否为802.1X认证
              if ( $mac_type =~ /authen/ && $mac eq $mac_rev ) {

                #将解析到的结果写入数据结构
                $ret5->{$ip_info}{"location"}     = $device_location;
                $ret5->{$ip_info}{"hostname"}     = $device;
                $ret5->{$ip_info}{"interface"}    = $dev_interface;
                $ret5->{$ip_info}{"mac"}          = $mac;
                $ret5->{$ip_info}{"vlan"}         = $mac_vlan;
                $ret5->{$ip_info}{"vpn_instance"} = $vpn_instance;
                $ret5->{$ip_info}{"gate_device"}  = $device;
              }

              #判断MAC地址是否为 静态绑定 sticky
              elsif ( $mac_type =~ /sticky/
                && $mac eq $mac_rev )
              {

                #将解析到的结果写入数据结构
                $ret4->{$ip_info}{"location"}     = $device_location;
                $ret4->{$ip_info}{"hostname"}     = $device;
                $ret4->{$ip_info}{"interface"}    = $dev_interface;
                $ret4->{$ip_info}{"mac"}          = $mac;
                $ret4->{$ip_info}{"vlan"}         = $mac_vlan;
                $ret4->{$ip_info}{"vpn_instance"} = $vpn_instance;
                $ret4->{$ip_info}{"gate_device"}  = $device;
              }

              #进行逻辑判断，是否匹配当前ARP表项
              elsif ( $mac eq $mac_rev ) {

                #将解析到的结果写入数据结构
                $ret2->{$ip_info}{"location"}     = $device_location;
                $ret2->{$ip_info}{"hostname"}     = $device;
                $ret2->{$ip_info}{"interface"}    = $dev_interface;
                $ret2->{$ip_info}{"mac"}          = $mac;
                $ret2->{$ip_info}{"vlan"}         = $mac_vlan;
                $ret2->{$ip_info}{"vpn_instance"} = $vpn_instance;
                $ret2->{$ip_info}{"gate_device"}  = $device;
              }
            }
          }
        }

        #将未解析到的结果写入数据结构
        $ret6->{$ip_info}{"location"}     = $device_location;
        $ret6->{$ip_info}{"hostname"}     = $device;
        $ret6->{$ip_info}{"interface"}    = $self_interface;
        $ret6->{$ip_info}{"mac"}          = $mac;
        $ret6->{$ip_info}{"vlan"}         = $vlan;
        $ret6->{$ip_info}{"vpn_instance"} = $vpn_instance;
        $ret6->{$ip_info}{"gate_device"}  = undef;
      }
    }
  }

  #处理解析成功且出现在未解析ret6中的重复项，（设备无序）
  foreach my $ip ( keys %{$ret6} ) {

    #进行条件判断，如出现在ret1 ret2 ret4 ret5 中则剔除
    if ( exists $ret1->{$ip}
      || exists $ret2->{$ip}
      || exists $ret4->{$ip}
      || exists $ret5->{$ip} )
    {

      #如果之前解析过，则剔除该元素
      delete $ret6->{$ip};
    }
  }

  #处理解析成功且出现在未解析ret5中的重复项，（设备无序）
  foreach my $ip ( keys %{$ret5} ) {

    #进行条件判断，如出现在ret1 ret2 ret4中则剔除
    if ( exists $ret1->{$ip}
      || exists $ret2->{$ip}
      || exists $ret4->{$ip} )
    {

      #如果之前解析过，则剔除该元素
      delete $ret5->{$ip};
    }
  }

  #处理解析成功且出现在未解析ret5中的重复项，（设备无序）
  foreach my $ip ( keys %{$ret2} ) {

    #进行条件判断，如出现在ret1 ret4 ret5 中则剔除
    if ( exists $ret1->{$ip}
      || exists $ret4->{$ip}
      || exists $ret5->{$ip} )
    {

      #如果之前解析过，则剔除该元素
      delete $ret5->{$ip};
    }
  }

  #返回计算结果
  my $ret = [ $ret1, $ret2, $ret3, $ret4, $ret5, $ret6 ];
  return $ret;
}

#------------------------------------------------------------------------------
# 华为交换机配置解析函数入口 -- 实现 ARP MAC INTERFACE LLDP 配置发现 入参为文件夹
#------------------------------------------------------------------------------
sub info_parser {

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
      $rev = device_info($file);

      #获取解析对象主机名
      my $hostname = $rev->{"hostname"};

      #获取设备信息，将解析结果拆解到 函数 $ret
      $ret->{"arp_info"}{$hostname} = $rev->{"arp_info"};
      $ret->{"mac_info"}{$hostname} = $rev->{"mac_info"};
      $ret->{"nei_info"}{$hostname} = $rev->{"nei_info"};
      $ret->{"eth_info"}{$hostname} = $rev->{"eth_info"};
      $ret->{"location"}{$hostname} = $rev->{"location"};
    }
    else {
      print "$file not parsed \n";
    }
  }

  #返回计算结果
  return $ret;
}

#------------------------------------------------------------------------------
# 华为交换机ARP MAC LLDP INTERFACE 解析函数入口，入参为单个文件名
#------------------------------------------------------------------------------
sub device_info {
  my $file = shift;

  #固化ARP MAC NEIGHBOR INTERFACE 获取命令行
  my $arp_cmd = "dis arp";
  my $mac_cmd = "dis mac-address";
  my $nei_cmd = "dis lldp neighbor brief";
  my $eth_cmd = "dis interface brief";

  #捕捉命令行输出结果
  my $arp_rev = catch_cmd( $arp_cmd, $file );
  my $mac_rev = catch_cmd( $mac_cmd, $file );
  my $nei_rev = catch_cmd( $nei_cmd, $file );
  my $eth_rev = catch_cmd( $eth_cmd, $file );

  #计算mac和arp相关属性
  my $arp_ret  = device_arp($arp_rev);
  my $mac_ret  = device_mac($mac_rev);
  my $nei_ret  = device_nei($nei_rev);
  my $eth_ret  = device_eth($eth_rev);
  my $sysname  = device_sysname($nei_rev);
  my $location = device_location($nei_rev);

  #输出计算结果
  my $ret = {
    "arp_info" => $arp_ret,
    "mac_info" => $mac_ret,
    "nei_info" => $nei_ret,
    "eth_info" => $eth_ret,
    "hostname" => $sysname,
    "location" => $location,
  };

  return $ret;
}

#------------------------------------------------------------------------------
#交换机ARP地址解析用例
#IP ADDRESS      MAC ADDRESS    EXP(M) TYPE/VLAN      INTERFACE    VPN-INSTANCE
#------------------------------------------------------------------------------
#10.4.26.21      0433-8948-9b00        I               MEth0/0/0        MGMT
#------------------------------------------------------------------------------
sub device_arp {

  #接收切割的配置文件
  my $config = shift;

  #构造数据结构
  my $ret;

  #遍历元素，构造数据结构
  foreach my $cli ( @{$config} ) {

    #捕捉实际的 dis arp 输出命令
    #优先匹配较早版本的ARP格式
    if ( $cli
      =~ /^(?<ipaddr>(\d{1,3}\.){3}(\d{1,3}))\s+(?<mac>([0-9a-fA-F]{4}\-){2}[0-9a-fA-F]{4})\s+((?<exp_time>\d+)\s+)?(?<type>(I\s\-|D\-\d+))(\s+(?<interface>.*?))(\s+(?<vpn_instance>.*?))?$/
      )
    {
      #获取解析结果
      my $mac          = $+{mac};
      my $ipaddr       = $+{ipaddr};
      my $interface    = $+{interface};
      my $vpn_instance = $+{vpn_instance};
      my $exp_time     = $+{exp_time};

      #如果MAC为Incomplete
      if ( $mac =~ /Incomplete/i ) {

        #封装特定的数据结构
        $ret->{"incomplete"}{$interface}{$ipaddr}{"ipaddr"}       = $ipaddr;
        $ret->{"incomplete"}{$interface}{$ipaddr}{"mac"}          = "Incomplete";
        $ret->{"incomplete"}{$interface}{$ipaddr}{"exp_time"}     = $exp_time || "forever";
        $ret->{"incomplete"}{$interface}{$ipaddr}{"vlan"}         = undef;
        $ret->{"incomplete"}{$interface}{$ipaddr}{"interface"}    = $interface;
        $ret->{"incomplete"}{$interface}{$ipaddr}{"vpn_instance"} = $vpn_instance;

        #继续下一个迭代
        next;
      }

      #改写type
      my $type = $+{type};

      if ( $type && $type =~ /I/ ) {

        #设备本身接口地址
        $type = "self_ip";

      }
      elsif ( $type && $type =~ /D/ ) {

        #学习到的ARP
        $type = "dynamic";
      }

      #输出解析结果
      $ret->{$type}{$interface}{$ipaddr}{"ipaddr"}       = $ipaddr;
      $ret->{$type}{$interface}{$ipaddr}{"mac"}          = $mac;
      $ret->{$type}{$interface}{$ipaddr}{"exp_time"}     = $exp_time || "forever";
      $ret->{$type}{$interface}{$ipaddr}{"vlan"}         = undef;
      $ret->{$type}{$interface}{$ipaddr}{"interface"}    = $interface;
      $ret->{$type}{$interface}{$ipaddr}{"vpn_instance"} = $vpn_instance;
    }

    #捕捉数据中心CE系列交换机ARP条目
    elsif ( $cli
      =~ /^(?<ipaddr>(\d{1,3}\.){3}(\d{1,3}))\s+((?<mac>(([0-9a-fA-F]{4}\-){2}[0-9a-fA-F]{4}))\s+)?((?<mac>Incomplete)\s+)?((?<exp_time>\d+)\s+)?((?<type_vlan>(.*?)\s+))?((?<interface>.*?)\s+)?(?<vpn_instance>.*?)$/
      )
    {
      #获取解析结果
      my $mac          = $+{mac};
      my $ipaddr       = $+{ipaddr};
      my $interface    = $+{interface};
      my $vpn_instance = $+{vpn_instance};
      my $exp_time     = $+{exp_time};

      #分解type vlan数据
      my ( $type, $vlan ) = split( /\//, $+{type_vlan} );

      #如果MAC为Incomplete
      if ( $mac =~ /Incomplete/i ) {

        #封装特定的数据结构
        $ret->{"incomplete"}{$interface}{$ipaddr}{"ipaddr"}       = $ipaddr;
        $ret->{"incomplete"}{$interface}{$ipaddr}{"mac"}          = "Incomplete";
        $ret->{"incomplete"}{$interface}{$ipaddr}{"exp_time"}     = $exp_time || "forever";
        $ret->{"incomplete"}{$interface}{$ipaddr}{"vlan"}         = $vlan;
        $ret->{"incomplete"}{$interface}{$ipaddr}{"interface"}    = $interface;
        $ret->{"incomplete"}{$interface}{$ipaddr}{"vpn_instance"} = $vpn_instance;

        #继续下一个迭代
        next;
      }

      #改写type
      if ( $type && $type =~ /I/ ) {

        #设备本身接口地址
        $type = "self_ip";

      }
      elsif ( $type && $type =~ /D/ ) {

        #学习到的ARP
        $type = "dynamic";
      }

      #如果捕捉到 dynamic 的MGMT口则跳过
      next if $type eq "dynamic" && $interface =~ /MEth/i;

      #输出解析结果
      $ret->{$type}{$interface}{$ipaddr}{"ipaddr"}       = $ipaddr;
      $ret->{$type}{$interface}{$ipaddr}{"mac"}          = $mac;
      $ret->{$type}{$interface}{$ipaddr}{"exp_time"}     = $exp_time || "forever";
      $ret->{$type}{$interface}{$ipaddr}{"vlan"}         = $vlan;
      $ret->{$type}{$interface}{$ipaddr}{"interface"}    = $interface;
      $ret->{$type}{$interface}{$ipaddr}{"vpn_instance"} = $vpn_instance;
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
sub device_mac {

  #接收切割的配置文件
  my $config = shift;

  #初始化数据结构
  my $ret;

  #遍历元素，构造数据结构
  foreach my $cli ( @{$config} ) {

    #捕捉实际的 dis arp 输出命令
    if ( $cli =~ $mac_str ) {

      #实例化变量
      my ( $mac, $vlan_vsi_bd, $interface, $type ) = split( /\s+/, $cli );

      #抽取MAC对应的VLAN信息
      my ( $vlan, $vsi, $bd ) = split( /\//, $vlan_vsi_bd );

      #过滤非物理接口
      if ( $interface =~ /GE|Vlanif|Eth\d/i ) {

        #输出匹配信息 如果未命中VLAN则使用VXLAN的BD绑定
        if ( $vlan && $vlan ne '-' ) {
          $ret->{$interface}{$mac} = "VLAN/" . $vlan;
        }

        #检测VSI是否为空
        elsif ( $vsi && $vsi ne '-' ) {
          $ret->{$interface}{$mac} = "VSI/" . $vsi;
        }

        #检测BD是否为空
        elsif ( $bd && $bd ne '-' ) {
          $ret->{$interface}{$mac} = "BD/" . $bd;
        }
      }

      #如果不匹配上述格式则跳转下一个
      else {

        #继续下个数据迭代
        next;
      }

      #写入MAC地址类型 -- 动态还是静态MAC
      $ret->{$interface}{"type"} = $type;
    }
  }

  #返回输出结果
  return $ret;
}

#------------------------------------------------------------------------------
#交换机MAC地址解析用例  -- 交换机本身IP 为GE打头的接口
#<CC-DC1-NZX-SW702>dis lldp neighbor brief
#Local Interface         Exptime(s) Neighbor Interface      Neighbor Device
#------------------------------------------------------------------------------
#10GE1/0/1                      97  10GE1/0/18              CC-DC1-NZX-S1
#------------------------------------------------------------------------------
sub device_nei {

  #接收切割的配置文件
  my $config = shift;

  #初始化数据结构
  my $ret;

  #初略判断交换机版本 -- CE6855系列支持这种格式
  my $ce6855_later  = grep { /Neighbor Interface/ } @{$config};
  my $ce6855_before = grep { /Neighbor Intf/ } @{$config};

  #遍历元素，构造数据结构
  foreach my $cli ( @{$config} ) {

    #捕捉实际的 dis lldp neighbor brief 输出命令
    #用于匹配数据中心CE系列交换机输出
    if ( $ce6855_later && $cli =~ /eSpace|GE/ ) {

      #截取相关字段
      my ( $src_int, $exp_time, $dst_int, $neighbor ) = split( /\s+/, $cli );

      #设置跳转逻辑
      #next if $dst_int =~ $mac_str;

      #构造以接口为索引的哈希对象
      $ret->{$src_int}{"neighbor"}           = $neighbor;
      $ret->{$src_int}{"neighbor_interface"} = $dst_int;
    }

    #兼容早期非数据中心交换机
    elsif ( $ce6855_before && $cli =~ /eSpace|GE/ ) {

      #截取相关字段
      my ( $src_int, $neighbor, $dst_int, $exp_time ) = split( /\s+/, $cli );

      #设置跳转逻辑
      #next if $dst_int =~ $mac_str;

      #构造以接口为索引的哈希对象
      $ret->{$src_int}{"neighbor"}           = $neighbor;
      $ret->{$src_int}{"neighbor_interface"} = $dst_int;
    }
  }

  #返回输出结果
  return $ret;
}

#------------------------------------------------------------------------------
#交换机INTERFACE接口解析用例  -- 交换机ETH-TRUNK接口成员包含缩进
#dis interface brief
#Eth-Trunk0                 up       up        0.01%  0.01%       0          0
#  10GE1/0/1                up       up        0.01%  0.01%       0          0
#  10GE1/0/2                up       up        0.01%  0.01%       0          0
#------------------------------------------------------------------------------
sub device_eth {

  #接收切割的配置文件
  my $config = shift;

  #初始化接口eth-trunk解析结果
  my $ret;

  #初始化eth-trunk代码块命中状态
  my $matched;

  #抓取配置中ETH-TRUNK
  my $eth_trunk;

  foreach my $cli ( @{$config} ) {

    #捕捉eth-trunk代码块并设置命中状态
    if ( $cli =~ /^(?<eth_trunk>(Eth-Trunk\d+))/ ) {

      #将命中数据写入变量
      $eth_trunk = $+{eth_trunk};

      #初始化数据结构为匿名数组
      $ret->{$eth_trunk} = [];

      #改写命中状态
      $matched++;
    }

    #命中eth-trunk代码块进一步解析成员接口
    elsif ( $matched && $cli =~ /^\s{2}(?<interface>\w+(.*?))\s+/ ) {

      #获取捕捉的接口信息,早期版本存在BUG
      my $interface = $+{interface};
      $interface =~ s/GigabitEthernet/GE/i;

      #将成员接口写入eth-trunk对象
      push @{ $ret->{$eth_trunk} }, $interface;

    }
  }

  #返回输出结果
  return $ret;
}

#------------------------------------------------------------------------------
#获取设备的主机名信息
#------------------------------------------------------------------------------
sub device_sysname {

  #读取切片的配置信息
  my $config = shift;

  #初始化数据结构
  my $ret;

  #遍历配置信息
  foreach ( @{$config} ) {
    if (/<(?<hostname>.*?)>/) {

      #将命中数据写入变量
      $ret = $+{hostname};

      #找到即跳出
      last;
    }
  }

  #输出计算结果
  return $ret;
}

#------------------------------------------------------------------------------
#获取交换机的分布位置
#------------------------------------------------------------------------------
sub device_location {

  #读取切片的配置信息
  my $config = shift;

  #初始化数据结构
  my $ret;

  #抓取配置中主机名
  my $sysname = device_sysname($config);

  #遍历哈希
  foreach my $dc ( keys %dc_map ) {

    #检查是否命中数据字典
    if ( $sysname && $sysname =~ $dc ) {

      #匹配机房字典
      $ret = $dc_map{$dc};

      #找到即跳出
      last;
    }
  }

  #输出计算结果
  return $ret;
}

1;
