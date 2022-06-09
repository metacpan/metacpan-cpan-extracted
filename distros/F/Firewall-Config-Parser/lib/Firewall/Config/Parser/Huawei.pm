package Firewall::Config::Parser::Huawei;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Huawei 通用属性
#------------------------------------------------------------------------------
use Firewall::Config::Element::Address::Huawei;
use Firewall::Config::Element::AddressGroup::Huawei;
use Firewall::Config::Element::Service::Huawei;
use Firewall::Config::Element::ServiceGroup::Huawei;
use Firewall::Config::Element::Schedule::Huawei;
use Firewall::Config::Element::Rule::Huawei;
use Firewall::Config::Element::Route::Huawei;
use Firewall::Config::Element::Interface::Huawei;
use Firewall::Config::Element::Zone::Huawei;
use Firewall::Config::Element::NatPool::Huawei;
use Firewall::Config::Element::DynamicNat::Huawei;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Parser::Role 角色属性和方法
#------------------------------------------------------------------------------
with 'Firewall::Config::Parser::Role';

#------------------------------------------------------------------------------
# parse 是 Firewall::Config::Parser::Role 角色必须实现的方法
#------------------------------------------------------------------------------
sub parse {
  my $self = shift;

  # 初始化 ruleNum
  $self->{"ruleNum"} = 0;

  # 解析防火墙配置 element , 作为 nat 和 rule 规则解析依赖
  while ( defined( my $string = $self->nextUnParsedLine() ) ) {
    if    ( $self->isZone($string) )         { $self->parseZone($string) }
    elsif ( $self->isVersion($string) )      { $self->parseVersion($string) }
    elsif ( $self->isInterface($string) )    { $self->parseInterface($string) }
    elsif ( $self->isAddress($string) )      { $self->parseAddress($string) }
    elsif ( $self->isService($string) )      { $self->parseService($string) }
    elsif ( $self->isServiceGroup($string) ) { $self->parseServiceGroup($string) }
    elsif ( $self->isSchedule($string) )     { $self->parseSchedule($string) }
    elsif ( $self->isRoute($string) )        { $self->parseRoute($string) }
    elsif ( $self->isNatPool($string) )      { $self->parseNatPool($string) }

    #elsif ( $self->isActive($string)      ) { $self->setActive($string)         }
    else { $self->ignoreLine() }
  }

  # 添加接口路由和网络安全区
  $self->addRouteToInterface();
  $self->addZoneRange();

  # 跳转到配置首行，开始 nat 和 rule 配置解析
  $self->goToHeadLine();
  while ( defined( my $string = $self->nextUnParsedLine() ) ) {
    if    ( $self->isNat($string) )          { $self->parseNat($string) }
    elsif ( $self->isAddressGroup($string) ) { $self->parseAddressGroup($string) }
    elsif ( $self->isRule($string) )         { $self->parseRule($string) }
    else                                     { $self->ignoreLine() }
  }

  # 清空解析配置，加速内存回收
  $self->{"config"} = "";
} ## end sub parse

#------------------------------------------------------------------------------
# isVersion 判断防火墙版本配置代码块
#------------------------------------------------------------------------------
sub isVersion {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /Software\s+Version\s+\S+/i ) {
    return 1;
  }
}

#------------------------------------------------------------------------------
# parseVersion 解析防火墙版本配置代码块
#------------------------------------------------------------------------------
sub parseVersion {
  my ( $self, $string ) = @_;
  if ( $string =~ /Software\s+Version\s+(?<version>\S+)/i ) {
    $self->{"version"} = $+{version};
  }
}

#------------------------------------------------------------------------------
# isInterface 判断防火墙接口代码块
#------------------------------------------------------------------------------
sub isInterface {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^interface\s+\S+/i ) {
    $self->setElementType('interface');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getInterface 提取防火墙具体接口信息
#------------------------------------------------------------------------------
sub getInterface {
  my ( $self, $name ) = @_;
  return $self->getElement( 'interface', $name );
}

#------------------------------------------------------------------------------
# parseInterface 解析防火墙接口代码块
#------------------------------------------------------------------------------
sub parseInterface {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^interface\s+(?<name>\S+)/i ) {
    my $name   = $+{name};
    my $config = $string;

    # 检查是否之前已解析过 interface, 接口元素必须拥有接口名
    my $interface = $self->getInterface($name);
    if ( !$interface ) {
      $interface = Firewall::Config::Element::Interface::Huawei->new( "name" => $name );
      $self->addElement($interface);
    }

    # 解析接口下所有配置
    while ( $string = $self->nextUnParsedLine ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^#/ ) {
        last;
      }

      # 抓取三层接口 ip mask，改写接口为三层接口
      if ( $string =~ /ip\s+address\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
        $interface->{"ipAddress"}     = $+{ip};
        $interface->{"interfaceType"} = 'layer3';

        # 将点分十进制掩码（1.1.1.1）改为10进制（0-32）
        my $maskNum = Firewall::Utils::Ip->changeMaskToNumForm( $+{mask} );
        $interface->{"mask"} = $maskNum;

        # 添加接口路由，包含子网、掩码、出站接口和下一跳
        my $route = Firewall::Config::Element::Route::Huawei->new(
          "network"      => $+{ip},
          "mask"         => $maskNum,
          "dstInterface" => $name,
          "nextHop"      => $+{ip}
        );
        $self->addElement($route);
        $interface->addRoute($route);
      }

      # 拼接接口代码块
      $config .= "\n" . $string;
    } ## end while ( $string = $self->...)

    # 返回计算结果
    $interface->{"config"} = $config;
  } ## end if ( $string =~ /^interface\s+(?<name>\S+)/i)
} ## end sub parseInterface

#------------------------------------------------------------------------------
# isZone 判断防火墙安全区域代码块
#------------------------------------------------------------------------------
sub isZone {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /firewall\s+zone\s+\S+/i ) {
    $self->setElementType('zone');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getZone 获取防火墙具体的安全区域
#------------------------------------------------------------------------------
sub getZone {
  my ( $self, $name ) = @_;
  return $self->getElement( 'zone', $name );
}

#------------------------------------------------------------------------------
# getZone 获取防火墙具体的安全区域
#------------------------------------------------------------------------------
sub parseZone {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /firewall\s+zone\s+(?:name\s+)?(?<name>\S+)/i ) {
    my $name   = $+{name};
    my $config = $string;

    # 检查是否之前已解析过 zone, 接口元素必须拥有接口名
    my $zone = $self->getZone($name);
    if ( !$zone ) {
      $zone = Firewall::Config::Element::Zone::Huawei->new( "name" => $name, "fwId" => $self->fwId );
      $self->addElement($zone);
    }

    # 解析防火墙安全区域代码块
    while ( $string = $self->nextUnParsedLine ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^#/ ) {
        last;
      }

      # 抓取代码块关联的管理接口，并将解析到的安全区域关联到具体接口
      if ( $string =~ /add\s+interface\s+(?<name>\S+)/ ) {
        my $interface = $self->getInterface( $+{name} );
        $interface->{"zoneName"} = $name;
        $zone->addInterface($interface);
      }

      # 拼接网络安全区代码块
      $config .= "\n" . $string;
    }

    # 返回计算结果，每个解析对象都集成角色的config属性
    $zone->{"config"} = $config;
  } ## end if ( $string =~ /firewall\s+zone\s+(?:name\s+)?(?<name>\S+)/i)
} ## end sub parseZone

#------------------------------------------------------------------------------
# isAddress 判断防火墙地址组代码块
#------------------------------------------------------------------------------
sub isAddress {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /ip\saddress-set\s(.*?)\stype\sobject/i ) {
    $self->setElementType('address');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getAddress 获取防火墙具体的地址组信息
#------------------------------------------------------------------------------
sub getAddress {
  my ( $self, $name ) = @_;
  return $self->getElement( 'address', $name );
}

#------------------------------------------------------------------------------
# parseAddress 解析防火墙地址组代码块
#------------------------------------------------------------------------------
sub parseAddress {
  my ( $self, $string ) = @_;

  # say dumper $string;

  # 正则匹配
  if ( $string =~ /ip\saddress-set\s(?<name>.*?)\stype\sobject(?:\svpn-instance\s(?<vpn>.*))?/i ) {
    my $name   = $+{name};
    my $config = $string;

    # 构造 params 哈希对象
    my %params;
    $params{"addrName"} = $+{name};
    $params{"vpn"}      = $+{vpn} if defined $+{vpn};

    # 检查是否之前已解析过，如果不存在则实例化地址组对象
    my $address = $self->getAddress($name);
    if ( !$address ) {
      $address = Firewall::Config::Element::Address::Huawei->new(%params);
      $self->addElement($address);
    }

    # 解析地址组下所有配置
    while ( $string = $self->nextUnParsedLine ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^#/ ) {
        last;
      }

      # 情况1：解析具体的单ip信息
      if ( $string =~ /address\s\d+\s(?<ip>\S+)\smask\s(?<mask>.*)$/i ) {
        my $ip   = $+{ip};
        my $mask = $+{mask};

        # 判断是否为点分10进制格式
        if ( $mask =~ /\./ ) {
          $mask = Firewall::Utils::Ip->changeMaskToNumForm($mask);
        }
        $address->addMember( {"ipmask" => "$ip/$mask"} );
      }

      # 情况2：解析具体的连续ip信息
      elsif ( $string =~ /address\s\d+\srange\s(?<range>\S+\s\S+)/ ) {
        $address->addMember( {"range" => $+{range}} );
      }

      # 情况3：解析地址组下再调用地址组的嵌套逻辑
      elsif ( $string =~ /address\s\d+\saddress-set\s(?<obj>.*)$/ ) {
        my $obj = $self->getAddress( $+{obj} );
        $address->addMember( {"obj" => $obj} ) if $obj;
      }

      # 静默该命令行
      elsif ( $string =~ /description/ ) {
      }

      # 其他命令则抛出异常
      else {
        $self->warn( "can't parse address" . $string );
      }

      # 拼接地址组代码块
      $config .= "\n" . $string;
    } ## end while ( $string = $self->...)

    # 返回计算结果，每个解析对象都集成角色的config属性
    $address->{"config"} = $config;
  } ## end if ( $string =~ /ip\saddress-set\s(?<name>.*?)\stype\sobject(?:\svpn-instance\s(?<vpn>.*))?/i)
} ## end sub parseAddress

#------------------------------------------------------------------------------
# isAddressGroup 判断防火墙地址组代码块
#------------------------------------------------------------------------------
sub isAddressGroup {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^ip\saddress-set\s(.*?)\stype\sgroup/i ) {
    $self->setElementType('addressGroup');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getAddressGroup 获取防火墙具体的地址组信息
#------------------------------------------------------------------------------
sub getAddressGroup {
  my ( $self, $name ) = @_;
  return $self->getElement( 'addressGroup', $name );
}

#------------------------------------------------------------------------------
# parseAddress 解析防火墙地址组代码块
#------------------------------------------------------------------------------
sub parseAddressGroup {
  my ( $self, $string ) = @_;

  # say dumper $string;

  # 正则匹配
  if ( $string =~ /ip\saddress-set\s(?<name>.*?)\stype\sgroup(?:\svpn-instance\s(?<vpn>.*))?/i ) {
    my $name   = $+{name};
    my $config = $string;

    # 构造 params 哈希对象
    my %params;
    $params{"addrName"} = $+{name};
    $params{"vpn"}      = $+{vpn} if defined $+{vpn};

    # 检查是否之前已解析过，如果不存在则实例化地址组对象
    my $address = $self->getAddressGroup($name);
    if ( !$address ) {
      $address = Firewall::Config::Element::Address::Huawei->new(%params);
      $self->addElement($address);
    }

    # 解析地址组下所有配置
    while ( $string = $self->nextUnParsedLine() ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^#/ ) {
        last;
      }

      # 情况1：解析具体的单ip信息
      if ( $string =~ /address\s\d+\s(?<ip>\S+)\smask\s(?<mask>.*)$/i ) {
        my $ip   = $+{ip};
        my $mask = $+{mask};

        # 判断是否为点分10进制格式
        if ( $mask =~ /\./ ) {
          $mask = Firewall::Utils::Ip->changeMaskToNumForm($mask);
        }
        $address->addMember( {"ipmask" => "$ip/$mask"} );
      }

      # 情况2：解析具体的连续ip信息
      elsif ( $string =~ /address\s\d+\srange\s(?<range>\S+\s\S+)/ ) {
        $address->addMember( {"range" => $+{range}} );
      }

      # 情况3：解析地址组下再调用地址组的嵌套逻辑
      elsif ( $string =~ /address\s\d+\saddress-set\s(?<obj>.*)$/ ) {
        my $obj = $self->getAddress( $+{obj} );
        $address->addMember( {"obj" => $obj} ) if $obj;
      }

      # 静默该命令行
      elsif ( $string =~ /description/ ) {
      }

      # 其他命令则抛出异常
      else {
        $self->warn( "can't parse address" . $string );
      }

      # 拼接地址组代码块
      $config .= "\n" . $string;
    } ## end while ( $string = $self->...)

    # say dumper $address;

    # 返回计算结果，每个解析对象都集成角色的config属性
    $address->{"config"} = $config;
  } ## end if ( $string =~ /ip\saddress-set\s(?<name>.*?)\stype\sgroup(?:\svpn-instance\s(?<vpn>.*))?/i)
} ## end sub parseAddressGroup

#------------------------------------------------------------------------------
# isService 判断防火墙服务端口组代码块
#------------------------------------------------------------------------------
sub isService {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^ip\sservice-set\s(.*?)\stype\sobject/ox ) {
    $self->setElementType('service');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getService 获取防火墙服务端口组具体信息
#------------------------------------------------------------------------------
sub getService {
  my ( $self, $serviceName ) = @_;
  return $self->getElement( 'service', $serviceName );
}

#------------------------------------------------------------------------------
# parseService 解析防火墙服务端口组代码块
#------------------------------------------------------------------------------
sub parseService {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^ip\s+service-set\s+(?<name>\S+)\s+type\s+object/i ) {
    my $name   = $+{name};
    my $config = $string;

    # 构造 params 哈希对象
    my %params;
    $params{"srvName"} = $name;

    # 检查是否之前已解析过
    my $service = $self->getService( $params{"name"} );

    # 解析服务端口组下所有配置
    while ( $string = $self->nextUnParsedLine ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^#/ ) {
        last;
      }

      # 抓取服务端口组明细条目
      if ( $string
        =~ /service\s\d+\sprotocol\s(?<proto>\S+)\s(source-port\s(?<srcport1>\d+)(\sto\s(?<srcport2>\d+))?\s)?destination-port\s(?<dstport1>\d+)(\sto\s(?<dstport2>\d+))?/ox
        )
      {
        # 捕捉协议、端口
        $params{"protocol"} = $+{proto};
        my $dstport = $+{dstport1};
        my $srcport = $+{srcport1} if defined $+{srcport1};

        # 判断是否连续端口区间值
        $srcport = "$+{srcport1}-$+{srcport2}" if defined $+{srcport2};
        $dstport = "$+{dstport1}-$+{dstport2}" if defined $+{dstport2};

        # 将解析端口信息写入哈希
        $params{"dstPort"} = $dstport;
        $params{"srcPort"} = $srcport if defined $srcport;

        # 将子端口成员加入元数据
        if ($service) {
          $service->addMeta(%params);
        }
        else {
          $service = Firewall::Config::Element::Service::Huawei->new(%params);
          $self->addElement($service);
        }
      } ## end if ( $string =~ ...)

      # 捕捉到 icmp 协议特殊处理
      elsif ( $string =~ /icmp/ ) {
        $params{"protocol"} = 'icmp';
        $params{"dstPort"}  = '1-65535';

        # 检查是否之前已解析过
        if ($service) {
          $service->addMeta(%params);
        }
        else {
          $service = Firewall::Config::Element::Service::Huawei->new(%params);
          $self->addElement($service);
        }
      }

      # 静默该命令行
      elsif ( $string =~ /description/ ) {
      }

      # 该代码块内其他命令行则抛出异常
      else {
        $self->warn( "can't parse service" . $string );
      }

      # 拼接服务端口代码块
      $config .= "\n" . $string;
    } ## end while ( $string = $self->...)

    # 返回计算结果，每个解析对象都集成角色的config属性
    $service->{"config"} = $config;
  } ## end if ( $string =~ /^ip\s+service-set\s+(?<name>\S+)\s+type\s+object/i)
} ## end sub parseService

#------------------------------------------------------------------------------
# getPreDefinedService 获取防火墙预定义服务端口信息
#------------------------------------------------------------------------------
sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Huawei->createSign($srvName);
  return ( $self->{"preDefinedService"}{$sign} );
}

#------------------------------------------------------------------------------
# isServiceGroup 判断防火墙服务端口组代码块
#------------------------------------------------------------------------------
sub isServiceGroup {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /ip\sservice-set\s(.*?)\stype\sgroup/oxi ) {
    $self->setElementType('serviceGroup');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getServiceGroup 获取防火墙指定服务端口组信息
#------------------------------------------------------------------------------
sub getServiceGroup {
  my ( $self, $srvGroupName ) = @_;
  return $self->getElement( 'serviceGroup', $srvGroupName );
}

#------------------------------------------------------------------------------
# parseServiceGroup 解析防火墙服务端口组代码块
#------------------------------------------------------------------------------
sub parseServiceGroup {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /ip\sservice-set\s(?<name>\S+)\stype\sgroup/i ) {
    my $config = $string;
    my $name   = $+{name};

    # 检查是否之前已解析过
    my $serGroup = $self->getServiceGroup($name);
    if ( !$serGroup ) {
      $serGroup = Firewall::Config::Element::ServiceGroup::Huawei->new( "srvGroupName" => $name );
      $self->addElement($serGroup);
    }

    # 解析防火墙服务端口组代码块内所有配置
    while ( $string = $self->nextUnParsedLine ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^#/ ) {
        last;
      }

      # 情况1：判断服务端口组下的服务端口组
      if ( $string =~ /service\s+\d+\s+service-set\s+(?<serName>\S+)/oxi ) {
        my $serName = $+{serName};

        # 检查是否之前已解析过或已存在该对象
        my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($serName);
        if ($obj) {
          $serGroup->addSrvGroupMember( $serName, $obj );
        }
      }

      # 拼接服务端口组代码块
      $config .= "\n" . $string;
    } ## end while ( $string = $self->...)

    # 返回计算结果，每个解析对象都集成角色的config属性
    $serGroup->{"config"} = $config;
  } ## end if ( $string =~ /ip\sservice-set\s(?<name>\S+)\stype\sgroup/i)
} ## end sub parseServiceGroup

#------------------------------------------------------------------------------
# getServiceOrServiceGroupFromSrvGroupMemberName 获取服务端口组成员信息
#------------------------------------------------------------------------------
sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName ) = @_;

  my $obj = $self->getPreDefinedService($srvGroupMemberName) // $self->getService($srvGroupMemberName)
    // $self->getServiceGroup($srvGroupMemberName);

  # 返回计算结果
  return $obj;
}

#------------------------------------------------------------------------------
# isSchedule 判断防火墙计划任务码块
#------------------------------------------------------------------------------
sub isSchedule {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /time-range\s+(?<name>\S+)/i ) {
    my $sch = $self->getSchedule( $+{name} );
    return 0 if defined $sch;
    $self->setElementType('schedule');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getSchedule 获取防火墙计划任务具体信息
#------------------------------------------------------------------------------
sub getSchedule {
  my ( $self, $schName ) = @_;
  return $self->getElement( 'schedule', $schName );
}

#------------------------------------------------------------------------------
# parseSchedule 解析防火墙计划任务代码块
#------------------------------------------------------------------------------
sub parseSchedule {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /time-range\s+(?<name>\S+)/i ) {
    my $name   = $+{name};
    my $config = $string;

    # 构建 params 哈希对象
    my %params;
    $params{"schName"} = $name;

    # 解析计划任务下所有配置
    my $schedule;
    while ( $string = $self->nextUnParsedLine ) {

      # 遇到 # 缩进符立即跳出代码块
      if ( $string =~ /^\s*#/ ) {
        last;
      }

      # 情况1：一次性时间调度任务
      if ( $string =~ /absolute-range\s(?<startdate>\S+\s\S+)\sto\s(?<enddate>\S+\s\S+)/oxi ) {
        $params{"schType"}   = 'onetime';
        $params{"startDate"} = $+{startdate} if defined $+{startdate};
        $params{"endDate"}   = $+{enddate};
        $schedule            = Firewall::Config::Element::Schedule::Huawei->new(%params);
        $self->addElement($schedule);
      }

      # 情况2：周期性时间调度任务
      elsif ( $string =~ /period-range\s(?<starttime>\S+)\sto\s(?<endtime>\S+)\s(?<day>.+)$/ ) {
        $params{"schType"}   = 'recurring';
        $params{"startTime"} = $+{starttime} if defined $+{starttime};
        $params{"endTime"}   = $+{endtime};
        $params{"day"}       = $+{day};
        $schedule            = Firewall::Config::Element::Schedule::Huawei->new(%params);
        $self->addElement($schedule);
      }

      # 其他命令则抛出异常
      else {
        $self->warn( "can't parse schedule " . $string );
      }

      # 拼接时间调度代码块
      $config .= "\n" . $string;
    } ## end while ( $string = $self->...)

    # 返回计算结果，每个解析对象都集成角色的config属性
    $schedule->{"config"} = $config;
  } ## end if ( $string =~ /time-range\s+(?<name>\S+)/i)
} ## end sub parseSchedule

#------------------------------------------------------------------------------
# isRoute 判断防火墙路由代码块
#------------------------------------------------------------------------------
sub isRoute {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /ip\sroute-static/i ) {
    $self->setElementType('router');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

#------------------------------------------------------------------------------
# parseRoute 解析防火墙路由代码块
#------------------------------------------------------------------------------
sub parseRoute {
  my ( $self, $string ) = @_;
  if ( $string
    =~ /ip\sroute-static\s(vpn-instance\s(?<vpn>\S+)\s)?(?<net>\S+)\s(?<mask>\d+|\d+\.\d+\.\d+\.\d+)\s((?<dstint>[a-zA-Z]+\S+\d+)\s)?(vpn-instance\s(?<vpn1>\S+)\s*)?(?<nexthop>\d+\.\d+\.\d+\.\d+)?/oxi
    )
  {
    # 构造 params 哈希对象
    my %params;
    $params{"config"}       = $string;
    $params{"network"}      = $+{net};
    $params{"vpn"}          = $+{vpn}     if defined $+{vpn};
    $params{"dstvpn"}       = $+{vpn1}    if defined $+{vpn1};
    $params{"dstInterface"} = $+{dstint}  if defined $+{dstint};
    $params{"nextHop"}      = $+{nexthop} if defined $+{nexthop};

    # 转换点分十进制（1.1.1.1）mask为10进制格式（/24）
    my $mask = $+{mask};
    if ( $mask =~ /\d+\.\d+\.\d+\.\d+/ ) {
      $params{"mask"} = Firewall::Utils::Ip->new->changeMaskToNumForm($mask);
    }
    else {
      $params{"mask"} = $mask;
    }

    # 如果没有定义出站接口，则将本身ip置为出站接口、下一跳地址
    if ( not defined $params{"dstInterface"} ) {
      for my $interface ( values %{$self->{elements}{interface}} ) {
        if ( defined $interface->{ipAddress} ) {
          my $intSet     = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, $interface->mask );
          my $nextHopSet = Firewall::Utils::Ip->new->getRangeFromIpMask( $params{"nextHop"},    32 );
          if ( $intSet->isContain($nextHopSet) ) {
            $params{"dstInterface"} = $interface->name;
            last;
          }
        }
        else {
          next;
        }
      }
    }

    # 实例化接口路由组件
    my $route = Firewall::Config::Element::Route::Huawei->new(%params);
    $self->addElement($route);
  }
  else {
    $self->warn( "can't parse route " . $string );
  }
} ## end sub parseRoute

#------------------------------------------------------------------------------
# isNatPool 判断防火墙 NatPool 代码块
#------------------------------------------------------------------------------
sub isNatPool {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^\snat\saddress-group\s\S+|destination-nat\saddress-group\s\S+/ox ) {
    $self->setElementType('natPool');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

#------------------------------------------------------------------------------
# getNatPool 获取防火墙 NatPool 具体对象
#------------------------------------------------------------------------------
sub getNatPool {
  my ( $self, $name ) = @_;
  return $self->getElement( 'natPool', $name );
}

#------------------------------------------------------------------------------
# parseNatPool 解析防火墙 NatPool 代码块
#------------------------------------------------------------------------------
sub parseNatPool {
  my ( $self, $string ) = @_;

  # 初始化 poolIp 数组对象
  my @poolIp;

  # ipaddr 正则 pattern
  my $ipStr
    = qr/(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?)/;
  my $srcNat = qr/^\snat\s+address-group\s+(?<name>.*)$/;
  my $dstNat = qr/^\sdestination-nat\s+address-group\s+(?<name>.*)$/;

  # 构造 params 哈希对象
  my %params;

  # 情况1：捕捉 nat address-group 配置
  if ( $string =~ $srcNat ) {
    $params{"config"}       = $string;
    $params{"poolName"}     = $+{name};
    $params{"natDirection"} = 'source';
  }

  # 情况2： 捕捉 destination-nat address-group 配置
  elsif ( $string =~ $dstNat ) {
    $params{"config"}       = $string;
    $params{"poolName"}     = $+{name};
    $params{"natDirection"} = 'destination';
  }

  # 解析 NatPool 代码块下所有配置
  while ( $string = $self->nextUnParsedLine ) {

    # 遇到 # 缩进符立即跳出代码块，跳出前回退一个光标 cursor
    if ( $string =~ /^\s*#|$srcNat|$dstNat/ ) {
      $self->backtrackLine;
      last;
    }

    # 匹配 NatPool 模式
    if ( $string =~ /mode\s(?<mode>.+)$/ ) {
      $params{"mode"} = $+{mode};
    }

    # 情况1： section (0)? 1.1.1.1 1.1.1.2
    if ( $string =~ /section\s(\d+\s)?(?<poolIp>$ipStr\s+$ipStr)/ ) {
      push @poolIp, $+{poolIp};
    }

    # 情况2：智能pat
    if ( $string =~ /smart-nopat\s(?<ip>\S+)/ ) {
      push @poolIp, "$+{ip} $+{ip}";
    }

    # 拼接 NatPool 代码块
    $params{config} .= "\n" . $string;
  } ## end while ( $string = $self->...)

  # 实例化 NatPool 对象
  $params{"poolIp"} = \@poolIp;
  my $natPool = Firewall::Config::Element::NatPool::Huawei->new(%params);
  $self->addElement($natPool);
} ## end sub parseNatPool

#------------------------------------------------------------------------------
# isNat 判断防火墙 Nat 代码块
#------------------------------------------------------------------------------
sub isNat {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /^nat-policy|^nat\sserver/i ) {
    $self->setElementType('nat');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getStaticNat 获取静态 NAT
#------------------------------------------------------------------------------
sub getStaticNat {
  my ( $self, $ruleName ) = @_;
  my $nat = $self->getElement( 'staticNat', $ruleName );
}

#------------------------------------------------------------------------------
# getDynamicNat 获取动态 NAT
#------------------------------------------------------------------------------
sub getDynamicNat {
  my ( $self, $ruleName ) = @_;
  $self->getElement( 'dynamicNat', $ruleName );
}

#------------------------------------------------------------------------------
# isRoute 判断防火墙路由代码块
#------------------------------------------------------------------------------
sub parseNat {
  my ( $self, $string ) = @_;
  my $ipStr
    = qr/(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?)/;

  if ( $string =~ /^nat-policy|^nat\sserver/i ) {
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      if ( $string =~ /^\srule\s+name\s+(?<name>.*)$/ ) {
        my %params;
        $params{"ruleName"} = $+{name};
        $params{"config"}   = $string;

        my $dynamicNat = Firewall::Config::Element::DynamicNat::Huawei->new(%params);
        $self->addElement($dynamicNat);

        #
        while ( $string = $self->nextUnParsedLine ) {
          if ( $string =~ /^\srule\s+name\s+\S+|^\s*#/ ) {
            $self->backtrackLine;
            last;
          }
          $dynamicNat->{config} .= "\n" . $string;

          # 匹配源zone
          if ( $string =~ /source-zone\s+(?<szone>.*)/ ) {
            $dynamicNat->{"fromZone"} = $+{szone};
          }

          # 匹配目的zone
          elsif ( $string =~ /destination-zone\s+(?<dzone>.*)/ ) {
            $dynamicNat->{"toZone"} = $+{dzone};
          }

          # 匹配源地址
          elsif ( $string
            =~ /source-address\s+(?:(?<ip>$ipStr)\s+mask\s+(?<mask>$ipStr)|address-set\s+(?<setName>.*)|range\s+(?<range>$ipStr\s+$ipStr))/ox
            )
          {
            $dynamicNat->{"srcIpRange"} = Firewall::Utils::Set->new() if not defined $dynamicNat->{"srcIpRange"};

            # 情况1：匹配 单个地址或子网
            if ( defined $+{ip} ) {
              my $maskNum = Firewall::Utils::Ip->changeMaskToNumForm( $+{mask} );
              my $srcSet  = Firewall::Utils::Ip->getRangeFromIpMask( $+{ip}, $maskNum );
              $dynamicNat->{"srcIpRange"}->mergeToSet($srcSet);
            }

            # 情况2：匹配地址组
            if ( defined $+{setName} ) {
              my $addrSet = $self->getAddress( $+{setName} );
              $dynamicNat->{"srcIpRange"}->mergeToSet( $addrSet->range ) if defined $addrSet;
            }

            # 情况3：匹配地址段
            if ( defined $+{range} ) {
              my ( $ipMin, $ipMax ) = split( /\s+/, $+{range} );
              my $srcSet = Firewall::Utils::Ip->getRangeFromIpRange( $ipMin, $ipMax );
              $dynamicNat->{"srcIpRange"}->mergeToSet($srcSet);
            }
          } ## end elsif ( $string =~ ...)

          # 匹配源地址nat
          elsif ( $string =~ /action\s+(source-nat|nat)\s+address-group\s+(?<pool>.*)/ox ) {
            $dynamicNat->{"natDirection"} = 'source';
            my $poolName = $+{pool};
            my $pool     = $self->getNatPool($poolName);
            $dynamicNat->{"natSrcIpRange"} = $pool->{"poolRange"};
            $dynamicNat->{"dstIpRange"}    = Firewall::Utils::Set->new( 0, 4294967295 )
              if not defined $dynamicNat->{"dstIpRange"};    #any
            $dynamicNat->{"poolName"} = $poolName;

          }

          # 匹配源地址接口nat
          elsif ( $string =~ /action\s+source-nat\s+easy-ip/ox ) {
            $dynamicNat->{"natDirection"} = 'source';
            if ( defined $dynamicNat->{"natInterface"} ) {
              my $interface = $self->getInterface( $dynamicNat->{"natInterface"} );
              $dynamicNat->{"natSrcIpRange"}
                = Firewall::Utils::Ip->getRangeFromIpMask( $interface->{"ipAddress"}, '32' );
            }
            elsif ( defined $dynamicNat->{"toZone"} ) {
              my $toZone = $self->getZone( $dynamicNat->{"toZone"} );
              $dynamicNat->{"natSrcIpRange"} = Firewall::Utils::Set->new();
              for my $interface ( values %{$toZone->{"interfaces"}} ) {
                $dynamicNat->{"natSrcIpRange"}->mergeToSet( $interface->range );
              }
            }
            $dynamicNat->{"dstIpRange"} = Firewall::Utils::Set->new( 0, 4294967295 )
              if not defined $dynamicNat->{"dstIpRange"};    #any
          }

          # 匹配目的地址
          elsif ( $string
            =~ /destination-address\s+(?:(?<ip>$ipStr)\s+mask(?<mask>$ipStr)|address-set\s+(?<setName>.*)|range\s+(?<range>$ipStr\s+$ipStr))/ox
            )
          {
            $dynamicNat->{"natDstIpRange"} = Firewall::Utils::Set->new() if not defined $dynamicNat->{"natDstIpRange"};

            # 情况1：匹配单个地址或子网
            if ( defined $+{ip} ) {
              my $dstSet = Firewall::Utils::Ip->getRangeFromIpMask( $+{ip}, $+{mask} ) if defined $+{ip};
              $dynamicNat->{"natDstIpRange"}->mergeToSet($dstSet);
            }

            # 情况2：匹配地址组
            if ( defined $+{setName} ) {
              my $addrSet = $self->getAddress( $+{setName} );
              $dynamicNat->{"natDstIpRange"}->mergeToSet( $addrSet->range );
            }

            # 情况3：匹配地址段
            if ( defined $+{range} ) {
              my ( $ipMin, $ipMax ) = split( /\s+/, $+{range} );
              my $dstSet = Firewall::Utils::Ip->getRangeFromIpRange( $ipMin, $ipMax );
              $dynamicNat->{"natDstIpRange"}->mergeToSet($dstSet);
            }
          } ## end elsif ( $string =~ ...)

          # 匹配目的地址nat
          elsif ( $string
            =~ /action\s+destination-nat\s+(?:address\s+(?<ip>$ipStr)|address-group\s+(?<setName>.*?))(\s+(?<port>\d+))?/iox
            )
          {
            $dynamicNat->{"natDirection"} = 'destination';
            $dynamicNat->{"dstIpRange"}   = Firewall::Utils::Set->new() if not defined $dynamicNat->{"dstIpRange"};

            #  情况1：匹配单个地址或子网
            if ( defined $+{ip} ) {
              my $dstSet = Firewall::Utils::Ip->getRangeFromIpMask( $+{ip} );
              $dynamicNat->{"dstIpRange"}->mergeToSet($dstSet);
            }

            # 情况2：匹配地址组
            if ( defined $+{setName} ) {
              my $pool = $self->getNatPool( $+{setName} );
              $dynamicNat->{"poolName"} = $+{setName};
              $dynamicNat->{"dstIpRange"}->mergeToSet( $pool->{"poolRange"} );
            }

            # 情况3：匹配地址段
            if ( defined $+{port} ) {
              $dynamicNat->{"dstPort"}  = $+{port};
              $dynamicNat->{"srvRange"} = Firewall::Utils::Ip->getRangeFromService("tcp/$+{port}");
            }
          } ## end elsif ( $string =~ ...)

          # 目的地址静态na
          elsif ( $string
            =~ /action\sdestination-nat\sstatic\s(?<nattype>address-to-address|port-to-address)\s(?:address\s(?<ip>$ipStr)|address-group\s(?<setName>.*?))(\s(?<port>\d+))?/ox
            )
          {
            $dynamicNat->{"natDirection"} = 'destination';
            $dynamicNat->{"natType"}      = $+{nattype};
            $dynamicNat->{"dstIpRange"}   = Firewall::Utils::Set->new() if not defined $dynamicNat->{"dstIpRange"};

            # 情况1：匹配单个地址或子网
            if ( defined $+{ip} ) {
              my $dstSet = Firewall::Utils::Ip->getRangeFromIpMask( $+{ip} );
              $dynamicNat->{"dstIpRange"}->mergeToSet($dstSet);
            }

            # 情况2：匹配地址组
            if ( defined $+{setName} ) {
              my $pool = $self->getNatPool( $+{setName} );
              $dynamicNat->{"poolName"} = $+{setName};
              $dynamicNat->{"dstIpRange"}->mergeToSet( $pool->{"poolRange"} );
            }

            # 情况3：匹配地址段
            if ( defined $+{port} ) {
              $dynamicNat->{"dstPort"}  = $+{port};
              $dynamicNat->{"srvRange"} = Firewall::Utils::Ip->getRangeFromService("tcp/$+{port}");
            }
          } ## end elsif ( $string =~ ...)

          # 目的地址pat
          elsif ( $string
            =~ /action\sdestination-nat\sstatic\s(?<nattype>port-to-port|address-to-port)\s(?:address\s(?<ip>$ipStr)|address-group\s(?<setName>\S+))(\s(?<port1>\d+)\sto\s(?<port2>\d+))?/ox
            )
          {
            $dynamicNat->{"natDirection"} = 'destination';
            $dynamicNat->{"natType"}      = $+{nattype};
            $dynamicNat->{"dstIpRange"}   = Firewall::Utils::Set->new() if not defined $dynamicNat->{"dstIpRange"};

            # 情况1：匹配单个地址或子网
            if ( defined $+{ip} ) {
              my $dstSet = Firewall::Utils::Ip->getRangeFromIpMask( $+{ip} );
              $dynamicNat->{"dstIpRange"}->mergeToSet($dstSet);
            }

            # 情况2：匹配地址组
            if ( defined $+{setName} ) {
              my $pool = $self->getNatPool( $+{setName} );
              $dynamicNat->{"poolName"} = $+{setName};
              $dynamicNat->{"dstIpRange"}->mergeToSet( $pool->{"poolRange"} );
            }

            # 情况3：匹配地址段
            if ( defined $+{port1} ) {
              $dynamicNat->{dstPort}    = $+{port1} . "-" . $+{port2};
              $dynamicNat->{"srvRange"} = Firewall::Utils::Ip->getRangeFromService("tcp/$+{port1}-$+{port2}");
            }
          } ## end elsif ( $string =~ ...)

          # 接口nat -> 出方向
          elsif ( $string =~ /egress-interface\s+(?<interface>\S+)/ ) {
            $dynamicNat->{"natInterface"} = $+{interface};
          }
        } ## end while ( $string = $self->...)
      }
      elsif ( $string
        =~ /nat\s+server\s+(?<name>\S+)(\s+vpn-instance\s+(?<vpn>\S+))?(\s+zone\s+(?<zone>\S+))?(\s+protocol\s+(?<proto>\S+))?(\s+global\s+(?:(?<ip1>$ipStr)(\s+(?<ip2>$ipStr))?|interface\s+(?<int>\S+))(?:(?<gport1>\d+)(?<gport2>\d+)?)?(\s+inside\s+(?<inIp1>$ipStr)(\s+(?<inip2>$ipStr))?(?:(?<inport1>\d+)(?<inport2>\d+)?)? /iox
        )
      {
        my %params;
        $params{"ruleName"}     = $+{name};
        $params{"natDirection"} = "destination";
        $params{"fromZone"}     = $+{zone}  if defined $+{zone};
        $params{"proto"}        = $+{proto} if defined $+{proto};
        my $ip1 = $+{ip1};
        my $ip2 = $+{ip2};
        $ip2 = ( defined $ip2 ) ? $ip2 : $ip1;
        $params{"natDstIpRange"} = Firewall::Utils::Ip->getRangeFromIpRange( $ip1, $ip2 ) if defined $ip1;

        if ( defined $+{int} ) {
          my $interface = $self->getInterface( $+{int} );
          $params{"natDstIpRange"} = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{"ipAddress"}, 32 );
        }
        if ( defined $+{gport1} ) {
          my $gport1 = $+{gport1};
          my $gport2 = $+{gport2};
          $gport2 = $gport1;
          $params{"natSrvRange"} = Firewall::Utils::Ip->new->getRangeFromService("$+{proto}/$gport1-$gport2");

        }
        if ( defined $+{inport1} ) {
          my $inport1 = $+{inport1};
          my $inport2 = $+{inport2};
          $inport2 = $inport1;
          $params{"srvRange"} = Firewall::Utils::Ip->new->getRangeFromService("$+{proto}/$inport1-$inport2");

        }
        $params{"config"} = $string;
        my $dynamicNat = Firewall::Config::Element::DynamicNat::Huawei->new(%params);
        $self->addElement($dynamicNat);
      } ## end elsif ( $string =~ ...)
    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /^nat-policy|^nat\sserver/i)
} ## end sub parseNat

#------------------------------------------------------------------------------
# addRouteToInterface 添加路由到接口 -> rangeIP
#------------------------------------------------------------------------------
sub addRouteToInterface {
  my $self = shift;

  # 获取路由
  my $routeIndex = $self->elements->{"route"};

  # 遍历防火墙路由
  for my $route ( values %{$routeIndex} ) {

    # 情况1：静态路由，目前只分析静态路由
    if ( $route->type eq 'static' ) {

      # 情况1：路由条目有接口信息
      if ( defined $route->{"dstInterface"} ) {
        my $interface = $self->getInterface( $route->{"dstInterface"} );
        next unless defined $interface;
        $route->{"zoneName"} = $interface->{"zoneName"};
        $interface->addRoute($route);
      }

      # 情况2：路由条目无接口信息
      else {

        # 遍历防火墙所有的接口，过滤出三层接口用于路由匹配
        for my $interface ( values %{$self->elements->{"interface"}} ) {

          # 查找防火墙下三层接口
          if ( defined $interface->{"ipAddress"} ) {
            my $intset
              = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{"ipAddress"}, $interface->{"mask"} );
            my $routset = Firewall::Utils::Ip->new->getRangeFromIpMask( $route->{"nextHop"}, 32 );
            if ( $intset->isContain($routset) ) {
              $interface->addRoute($route);
              $route->{"zoneName"}     = $interface->{"zoneName"};
              $route->{"dstInterface"} = $interface->{"name"};
            }
          }
        }
      }
    } ## end if ( $route->type eq 'static')
  } ## end for my $route ( values ...)
} ## end sub addRouteToInterface

#------------------------------------------------------------------------------
# addZoneRange 添加路由到接口 -> rangeIP
#------------------------------------------------------------------------------
sub addZoneRange {
  my $self = shift;

  # 遍历防火墙下所有的 zone
  for my $zone ( values %{$self->elements->{"zone"}} ) {
    for my $interface ( values %{$zone->interfaces} ) {
      $zone->range->mergeToSet( $interface->range );
    }
  }
}

#------------------------------------------------------------------------------
# isRule 判断防火墙 rule 代码块
#------------------------------------------------------------------------------
sub isRule {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /security-policy/ ) {
    $self->setElementType('rule');
    return 1;
  }
  else {
    $self->setElementType();
  }
}

#------------------------------------------------------------------------------
# getRule 获取防火墙具体的 rule
#------------------------------------------------------------------------------
sub getRule {
  my ( $self, $ruleName ) = @_;
  my $nat = $self->getElement( 'rule', $ruleName );
}

#------------------------------------------------------------------------------
# parseRule 解析防火墙 rule 代码块
#------------------------------------------------------------------------------
sub parseRule {
  my ( $self, $string ) = @_;

  # 解析防火墙 rule 代码块
  while ( defined( $string = $self->nextUnParsedLine ) ) {

    # 遇到 # 缩进符立即跳出代码块
    if ( $string =~ /^\s*#/ ) {
      last;
    }

    # 遇到 rule name 即开始解析规则
    if ( $string =~ /\srule\s+name\s+\S+/i ) {
      $self->_parseRule($string);
    }
  }
}

#------------------------------------------------------------------------------
# _parseRule 解析防火墙访问控制规则，依赖源目地址、端口、安全区、时间调度
#------------------------------------------------------------------------------
sub _parseRule {
  my ( $self, $string ) = @_;

  # 正则匹配
  if ( $string =~ /\srule\s+name\s+(?<name>.*)$/i ) {

    # 截取 ruleName
    my $name    = $+{name};
    my $content = $string;
    my $config  = $string;

    # 抓取 ipaddr 正则
    my $ipt = '\d+\.\d+\.\d+\.\d+';

    # 构造 params 哈希对象
    my %params;
    $params{"ruleName"} = $name;
    $params{"content"}  = $content;
    $params{"ruleNum"}  = $self->{"ruleNum"}++;

    # rule 本身不存在递归调用，匹配规则即实例化规则对象
    my $rule = Firewall::Config::Element::Rule::Huawei->new(%params);
    $self->addElement($rule);

    # 设置访问控制 rule 元素的解析标记
    my ( $src, $dst, $srv, $fromZone, $toZone );

    # 解析防火墙 rule 代码块
    while ( $string = $self->nextUnParsedLine() ) {

      # 遇到 # 或 rule name 打头的配置即跳出代码块解析，并将鼠标回退上一行
      if ( $string =~ /^#|rule\s+name\s+\S+/ ) {
        $self->backtrackLine();
        last;
      }

      # 拼接 rule 代码块
      $rule->addContent( $string . "\n" );

      # 解析 rule action
      if ( $string =~ /action\s(?<action>.*)/ox ) {
        $rule->{"action"} = $+{action};
      }

      # 解析 rule source-zone，可能允许多个 zone 之间互访 -> fromZone 为标量
      if ( $string =~ /source-zone\s(?<srczone>.*)/ox ) {
        if ( defined $rule->{"fromZone"} ) {
          $rule->{"fromZone"} .= "," . $+{srczone};
        }
        else {
          $rule->{"fromZone"} = $+{srczone};
        }
        $fromZone = 1;
      }

      # 解析 rule destination-zone，可能允许多个 zone 直接互访 -> toZone 为标量
      if ( $string =~ /destination-zone\s+(?<dstzone>.*)/ox ) {
        if ( defined $rule->{"toZone"} ) {
          $rule->{"toZone"} .= "," . $+{dstzone};
        }
        else {
          $rule->{"toZone"} = $+{dstzone};
        }
        $toZone = 1;
      }

      # 解析 rule ipaddr 通信对，包括源目地址
      # 情况1： 地址对象为源目地址组
      if ( $string =~ /(?<srcOrDst>source-address|destination-address)\s+address-set\s+(?<addr>.*)/ox ) {
        if ( $+{srcOrDst} eq 'source-address' ) {
          $src = 1;
          my $addr = $+{addr};
          $self->addToRuleSrcAddressGroup( $rule, $addr, "addr" );
        }
        elsif ( $+{srcOrDst} eq 'destination-address' ) {
          $dst = 1;
          my $addr = $+{addr};
          $self->addToRuleDstAddressGroup( $rule, $addr, "addr" );
        }
      }

      # 情况2：地址对象为单ip格式，包括源目地址
      if ( $string
        =~ /(?<srcOrDst>source-address|destination-address)\s+(?<ip>$ipt)\s+(?:(?<maskNum>\d+)|mask\s+(?<maskStr>$ipt))/ox
        )
      {
        if ( $+{srcOrDst} eq 'source-address' ) {
          $src = 1;
          my $ipaddr = $+{ip};

          # 将子网掩码转换为10进制
          my $muskNum = $+{maskNum} if defined $+{maskNum};
          $muskNum = Firewall::Utils::Ip->changeMaskToNumForm( $+{maskStr} ) if defined $+{maskStr};

          # 拼接为子网掩码格式
          $ipaddr .= "/$muskNum";
          $self->addToRuleSrcAddressGroup( $rule, $ipaddr, "ipmask" );
        }
        elsif ( $+{srcOrDst} eq 'destination-address' ) {
          $dst = 1;
          my $ipaddr  = $+{ip};
          my $muskNum = $+{maskNum} if defined $+{maskNum};
          $muskNum = Firewall::Utils::Ip->changeMaskToNumForm( $+{maskStr} ) if defined $+{maskStr};
          $ipaddr .= "/$muskNum";
          $self->addToRuleDstAddressGroup( $rule, $ipaddr, "ipmask" );
        }
      } ## end if ( $string =~ ...)

      # 情况3：地址对象为连续ip格式，包括源目地址
      if ( $string =~ /(?<srcOrDst>source-address|destination-address)\srange\s(?<iprange>$ipt\s$ipt)/ox ) {
        if ( $+{srcOrDst} eq 'source-address' ) {
          $src = 1;
          $self->addToRuleSrcAddressGroup( $rule, $+{iprange}, "range" );
        }
        elsif ( $+{srcOrDst} eq 'destination-address' ) {
          $dst = 1;
          $self->addToRuleDstAddressGroup( $rule, $+{iprange}, "range" );
        }
      }

      # 解析 rule 服务端口信息
      # 情况1：匹配缺省的服务端口信息
      if ( $string =~ /service\s(?<srv>\S+$)/ox ) {
        $srv = 1;
        $self->addToRuleServiceGroup( $rule, $+{srv} );
      }

      # 情况2：匹配未定义端口组直接套用的端口信息
      if ( $string
        =~ /service\sprotocol\s(?<proto>\S+)\s(source-port\s(?<srcport1>\d+)(\sto\s(?<srcport2>\d+))?\s)?destination-port\s(?<dstport1>\d+)(\sto\s(?<dstport2>\d+))?/ox
        )
      {
        $srv = 1;

        # 捕捉协议、端口
        my $params;
        $params->{"srvName"}  = $name;
        $params->{"protocol"} = $+{proto};
        my $dstport = $+{dstport1};
        my $srcport = $+{srcport1} if defined $+{srcport1};

        # 判断是否连续端口区间值，构造 Firewall::Utils::Ip 数据结构
        $srcport = "$+{srcport1}-$+{srcport2}" if defined $+{srcport2};
        $dstport = "$+{dstport1}-$+{dstport2}" if defined $+{dstport2};

        # 将解析端口信息写入哈希
        $params->{"dstPort"} = $dstport;
        $params->{"srcPort"} = $srcport if defined $srcport;

        # 传递变量给到 addToRuleServiceGroup
        $self->addToRuleServiceGroup( $rule, $params );
      } ## end if ( $string =~ ...)

      # 解析 rule 时间调度
      if ( $string =~ /time-range\s(?<sch>\S+)/ox ) {
        my $schedule = $self->getSchedule( $+{sch} );
        if ( defined $schedule ) {
          $rule->setSchedule($schedule);
        }
        else {
          $self->warn("schName $+{sch} 不是 schedule\n");
        }
      }

      # if ($string =~ /disable/ox){

      #     $rule->{isDisable} = 'disable';
      # }

    } ## end while ( $string = $self->...)

    # rule 5元组状态判断，如果没解析到则设置缺省值
    if ( not defined $src ) {
      $self->addToRuleSrcAddressGroup( $rule, 'any', 'addr' );
    }
    if ( not defined $dst ) {
      $self->addToRuleDstAddressGroup( $rule, 'any', 'addr' );
    }
    if ( not defined $srv ) {
      $self->addToRuleServiceGroup( $rule, 'any' );
    }
    if ( not defined $fromZone ) {
      $rule->{fromZone} = 'any';
    }
    if ( not defined $toZone ) {
      $rule->{toZone} = 'any';
    }
  } ## end if ( $string =~ /\srule\s+name\s+(?<name>.*)$/i)
} ## end sub _parseRule

#------------------------------------------------------------------------------
# addToRuleSrcAddressGroup 将 obj name 实例化为 rule 下的 srcAddressGroup
#------------------------------------------------------------------------------
sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName, $type ) = @_;

  # 初始化 obj name 数据
  my $obj;
  my $name = $srcAddrName;

  # 情况1：类型为 addr， 实例化 ip 对象后加入成员数组
  if ( $type eq 'addr' ) {

    # 判断是否为大策略
    if ( defined $srcAddrName and $srcAddrName =~ /^(?:Any|all)$/io ) {

      # 检查是否之前已解析过，没有则初始化
      unless ( $obj = $self->getAddress($srcAddrName) ) {
        $obj = Firewall::Config::Element::Address::Huawei->new( "addrName" => $srcAddrName );
        $obj->addMember( {"ipmask" => '0.0.0.0/0'} );
        $self->addElement($obj);
      }
    }

    # 检查是否可以获取到地址对象
    elsif ( $obj = $self->getAddress($name) ) {
      $obj->{refnum} += 1;
    }

    # 否则抛出异常
    else {
      $self->warn("的 srcAddrName $srcAddrName 不是address 也不是 addressGroup\n");
    }
  } ## end if ( $type eq 'addr' )

  # 情况2：类型为单个 ip，实例化 ip 对象后加入成员数组
  elsif ( $type eq 'ipmask' ) {
    $obj = Firewall::Config::Element::Address::Huawei->new( "addrName" => $srcAddrName );
    $obj->addMember( {"ipmask" => "$srcAddrName"} );
  }

  # 情况3：类型为连续的多个 ip，实例化 ipRange 对象后加入成员数组
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '\s+', $name );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::Huawei->new( "addrName" => $ipmin . '-' . $ipmax );
    $obj->addMember( {"range" => "$srcAddrName"} );
  }

  # 将解析到的 源ip 关联到具体规则下
  $rule->addSrcAddressMembers( $name, $obj );
} ## end sub addToRuleSrcAddressGroup

#------------------------------------------------------------------------------
# addToRuleDstAddressGroup 将 obj name 实例化为 rule 下的 dstAddressGroup
#------------------------------------------------------------------------------
sub addToRuleDstAddressGroup {
  my ( $self, $rule, $dstAddrName, $type ) = @_;

  # 初始化 obj name 标量
  my $obj;
  my $name = $dstAddrName;

  # 情况1：类型为 addr， 实例化 ip 对象后加入成员数组
  if ( $type eq 'addr' ) {

    # 判断是否为大策略，如果不存在地址对象则新建
    if ( defined $dstAddrName and $dstAddrName =~ /^(?:Any|all)$/io ) {
      unless ( $obj = $self->getAddress($dstAddrName) ) {
        $obj = Firewall::Config::Element::Address::Huawei->new( "addrName" => $dstAddrName );
        $obj->addMember( {"ipmask" => '0.0.0.0/0'} );
        $self->addElement($obj);
      }
    }

    # 检查是否存在调用关系
    elsif ( $obj = $self->getAddress($dstAddrName) ) {
      $obj->{refnum} += 1;
    }

    # 其他命令则抛出异常
    else {
      $self->warn("的 dstAddrName $dstAddrName 不是address 也不是 addressGroup\n");
    }
  } ## end if ( $type eq 'addr' )

  # 情况2：类型为单个 ip，实例化 ip 对象后加入成员数组
  elsif ( $type eq 'ip' ) {
    $obj = Firewall::Config::Element::Address::Huawei->new( "addrName" => $dstAddrName );
    $obj->addMember( {"ipmask" => "$dstAddrName"} );
  }

  # 情况3：类型为连续的多个 ip，实例化 ipRange 对象后加入成员数组
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '\s+', $dstAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::Huawei->new( "addrName" => $ipmin . '-' . $ipmax );
    $obj->addMember( {"range" => "$dstAddrName"} );
  }

  # 将解析到的 目的ip 关联到具体规则下
  $rule->addDstAddressMembers( $name, $obj );
} ## end sub addToRuleDstAddressGroup

sub addToRuleServiceGroup {
  my ( $self, $rule, $srvName ) = @_;

  # 情况1：传递过来的 srvName 为匿名哈希引用，用来匹配 rule 下直接调用的端口
  if ( ref $srvName eq "HASH" ) {

    # 取出 params变量
    my $serName  = $srvName->{"srvName"};
    my $srcPort  = $srvName->{"srcPort"};
    my $dstPort  = $srvName->{"dstPort"};
    my $protocol = $srvName->{"protocol"};

    # 拼接 srvMember 变量
    my $srvMember = $protocol . "/" . $dstPort;

    # 实例化华为防火墙端口服务组对象
    my $serviceGroup = Firewall::Config::Element::ServiceGroup::Huawei->new(
      "fwId"         => $self->fwId,
      "srvGroupName" => $srvMember // '_service_'
    );

    # 检查是否为 ip 大策略
    $srvMember = 'ipAny' if $protocol =~ /ip/i;
    my $obj = Firewall::Config::Element::Service::Huawei->new(
      "fwId"     => $self->fwId,
      "srvName"  => $srvMember,
      "srcPort"  => $srcPort,
      "dstPort"  => $dstPort,
      "protocol" => $protocol
    );

    # 添加代码块内的
    $serviceGroup->addSrvGroupMember( $srvMember, $obj );

    #say dumper $serviceGroup;

    # 将解析到的 端口成员 关联到 rule
    $rule->addServiceMembers( $srvMember, $serviceGroup );

  } ## end if ( ref $srvName eq "HASH")

  # 情况2：传递过来的 srvName 为标量
  else {
    if ( my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($srvName) ) {
      $obj->{"refnum"} += 1;
      $rule->addServiceMembers( $srvName, $obj );
    }
    else {
      $self->warn("的 srvName $srvName 不是 service 不是 preDefinedService 也不是 serviceGroup\n");
    }
  }

} ## end sub addToRuleServiceGroup

__PACKAGE__->meta->make_immutable;
1;
