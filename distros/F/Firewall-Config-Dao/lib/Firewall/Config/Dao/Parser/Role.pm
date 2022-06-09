package Firewall::Config::Dao::Parser::Role;

#------------------------------------------------------------------------------
# 加载扩展插件
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use JSON;
use Storable qw(dclone);

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Date;
use Firewall::Utils::Ip;

#------------------------------------------------------------------------------
# 定义 Firewall::Config::Dao::Parser::Role 方法属性
#------------------------------------------------------------------------------
has dbi => (
  is       => 'ro',
  does     => 'Firewall::DBI::Role',
  required => 1,

  # 代理 Firewall::DBI::Role SQL 方法
  handles => [qw(select execute update insert delete batchExecute batchInsert)],
);

# 配置解析器
has parser => ( is => 'ro', does => 'Firewall::Config::Parser::Role', required => 1, );

#------------------------------------------------------------------------------
# fwId 获取防火墙 id
#------------------------------------------------------------------------------
sub fwId {
  my $self = shift;
  return $self->{parser}{fwId};
}

#------------------------------------------------------------------------------
# save 将解析的配置存储到数据库中 | DAO 数据模块入口函数
#------------------------------------------------------------------------------
sub save {
  my $self = shift;
  $self->saveZone;
  $self->saveInterface;
  $self->saveFwNetworkPrivate;
  $self->saveAddress;
  $self->saveService;
  $self->saveRoute;
  $self->saveRule;
  $self->saveNat;

  # 暂不支持
  # $self->saveSchedule;
}

#------------------------------------------------------------------------------
# saveZone 保存 parser 解析到网络区域对象
#------------------------------------------------------------------------------
sub saveZone {
  my $self = shift;

  # 定义表单
  my $tableName = 'fw_zone_state';

  # 初始化数据结构
  my ( $newZones, $oldZones );
  my $zoneExistsStatus = {new => {}, old => {}};

  # 遍历快照中的网络区域,写入 newZones 和 zoneExistsStatus
  for my $zoneObj ( values $self->{parser}{elements}{zone}->%* ) {
    my $zoneName = $zoneObj->{name};
    $newZones->{$zoneName} = undef;
    $zoneExistsStatus->{new}{$zoneName} = undef;
  }

  # 查询已有网络区域数据,写入 oldZones
  $oldZones = $self->select( column => ['zone'], table => $tableName, where => {fw_id => $self->{parser}{fwId}} )->all;

  # 寻找差量数据
  for my $zoneName ( map { $_->{zone} } $oldZones->@* ) {

    # 新旧zones均存在,则不是新的数据
    if ( exists $newZones->{$zoneName} ) {
      delete( $zoneExistsStatus->{new}{$zoneName} );
    }
    else {
      $zoneExistsStatus->{old}{$zoneName} = undef;
    }
  }

  # 根据网络区域状态更新数据
  if ( keys $zoneExistsStatus->{new}->%* > 0 ) {
    my $sql    = "insert into $tableName (fw_id, zone) values (?, ?)";
    my $params = [ map { [ $self->fwId, $_ ] } keys $zoneExistsStatus->{new}->%* ];
    $self->batchExecute( $params, $sql );
  }

  # 设置 state 为 0 代表停用状态
  if ( keys $zoneExistsStatus->{old}->%* > 0 ) {
    my $sql    = "update $tableName set state = 1 where fw_id = ? and zone = ?";
    my $params = [ map { [ $self->fwId, $_ ] } keys $zoneExistsStatus->{old}->%* ];
    $self->batchExecute( $params, $sql );
  }
}

#------------------------------------------------------------------------------
# saveInterface 保存 parser 解析到的接口对象
#------------------------------------------------------------------------------
sub saveInterface {
  my $self = shift;

  # 定义 SQL 语句
  my $sql
    = "insert into fw_interface (fw_id,interface_name,ipaddress,interface_range,zonename,config,type) values(?,?,?,?,?,?,?)
    ON CONFLICT(fw_id,interface_name) do update set config=EXCLUDED.config,interface_range = EXCLUDED.interface_range,ipaddress=EXCLUDED.ipaddress";

  # 初始化变量
  my $params;

  # 编辑快照解析到的接口对象
  for my $interface ( values $self->{parser}{elements}{interface}->%* ) {

    # 构造 SQL VALUES
    my @ints;

    # fw_id
    push @ints, $self->fwId;

    # interface_name
    push @ints, $interface->{name};

    # ipaddress
    if ( defined $interface->{ipAddress} ) {
      push @ints, $interface->{ipAddress} . "/" . $interface->{mask};
    }
    else {
      push @ints, "";
    }

    # interface_range
    push @ints, encode_json {mins => $interface->{range}{mins}, maxs => $interface->{range}{maxs}};

    # zone_name
    push @ints, $interface->{zoneName};

    # config
    push @ints, $interface->{config};

    # type
    push @ints, $interface->{interfaceType};

    # 将数据压入 $params
    push $params->@*, \@ints;
  }
  $self->batchExecute( $params, $sql );
}

#------------------------------------------------------------------------------
# saveNat 保存 parser 解析到的地址转换对象
#------------------------------------------------------------------------------
sub saveNat {
  my $self = shift;

  # 保存之前删除历史数据
  $self->delete( where => {fw_id => $self->{parser}{fwId}}, table => "fw_nat_table" );

  # 定义 sql 插入语句
  my $sql
    = "insert into fw_nat_table (fw_id,rule_id_name,src_range,dst_range,srv_range,nat_src_range,nat_dst_range,nat_srv_range,nat_interface,
    from_zone,to_zone,natDirection,nat_type,config) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

  # 初始化变量
  my $params;

  # 查询防火墙快照中的静态地址转换
  for my $staticNat ( values $self->{parser}{elements}{staticNat}->%* ) {

    # 构造 SQL VALUES
    my @nat;

    # fw_id
    push @nat, $self->{parser}{fwId};

    # rule_id_name
    push @nat, $staticNat->{ruleName};

    # src_range 封装为 json 对象
    push @nat, encode_json {mins => $staticNat->{realIpRange}{mins}, maxs => $staticNat->{realIpRange}{maxs}};

    # 静态地址转换的 dst_range srv_range 为空
    push @nat, undef;
    push @nat, undef;

    # nat_src_range
    push @nat, encode_json {mins => $staticNat->{natIpRange}{mins}, maxs => $staticNat->{natIpRange}{maxs}};

    # 静态地址转换的 nat_dst_range srv_dst_range 为空
    push @nat, undef;
    push @nat, undef;

    # nat_interface
    push @nat, $staticNat->{natInterface};

    # from_zone
    push @nat, $staticNat->{realZone};

    # to_zone
    push @nat, $staticNat->{natZone};

    # natDirection
    push @nat, 'bidirection';

    # nat_type
    push @nat, 'static';

    # config
    push @nat, $staticNat->{config};

    # 将数据压入 params
    push $params->@*, \@nat;
  }

  for my $dyNat ( values $self->{parser}{elements}{dynamicNat}->%* ) {

    # 构造 SQL VALUES
    my @nat;

    # fw_id
    push @nat, $self->{parser}{fwId};

    # rule_id_name
    push @nat, $dyNat->{ruleName};

    # src_range | 动态地址转换包括源地址和目的地址两个方向，该值可能不存在
    push @nat,
      defined $dyNat->{srcIpRange}
      ? encode_json {mins => $dyNat->{srcIpRange}{mins}, maxs => $dyNat->{srcIpRange}{maxs}}
      : undef;

    # dst_range | 动态地址转换包括源地址和目的地址两个方向，该值可能不存在
    push @nat,
      defined $dyNat->{dstIpRange}
      ? encode_json {mins => $dyNat->{dstIpRange}{mins}, maxs => $dyNat->{dstIpRange}{maxs}}
      : undef;

    # srv_range | 动态地址转换包括源地址和目的地址两个方向，该值可能不存在
    push @nat,
      defined $dyNat->srvRange
      ? encode_json {mins => $dyNat->{srvRange}{mins}, maxs => $dyNat->{srvRange}{maxs}}
      : undef;

    # nat_src_range | 动态地址转换包括源地址和目的地址两个方向，该值可能不存在
    push @nat,
      defined $dyNat->{natSrcIpRange}
      ? encode_json {mins => $dyNat->{natSrcIpRange}{mins}, maxs => $dyNat->{natSrcIpRange}{maxs}}
      : undef;

    # nat_dst_range | 动态地址转换包括源地址和目的地址两个方向，该值可能不存在
    push @nat,
      defined $dyNat->{natDstIpRange}
      ? encode_json {mins => $dyNat->{natDstIpRange}{mins}, maxs => $dyNat->{natDstIpRange}{maxs}}
      : undef;

    # nat_srv_range | 动态地址转换包括源地址和目的地址两个方向，该值可能不存在
    push @nat,
      defined $dyNat->{natSrvRange}
      ? encode_json {mins => $dyNat->{natSrvRange}{mins}, maxs => $dyNat->{natSrvRange}{maxs}}
      : undef;

    # nat_interface
    push @nat, $dyNat->{natInterface};

    # from_zone
    push @nat, $dyNat->{fromZone};

    # to_zone
    push @nat, $dyNat->{toZone};

    # natDirection
    push @nat, $dyNat->{natDirection};

    # nat_type
    push @nat, 'dynamic';

    # config
    push @nat, $dyNat->{config};

    # 将数据压入 params
    push $params->@*, \@nat;
  }
  $self->batchExecute( $params, $sql );
}

#------------------------------------------------------------------------------
# saveRule 保存 parser 解析到的防火墙策略对象
#------------------------------------------------------------------------------
sub saveRule {
  my $self = shift;

  # 插入数据之前删除历史数据
  $self->delete( where => {fw_id => $self->fwId}, table => "fw_rule" );

  # 定义 SQL 语句
  my $sql
    = "insert into fw_rule (fw_id,rule_id_name,rule_num,from_zone,to_zone,source_addr,destination_addr,service,rule_action,rule_state,expire_date,src_set,dst_set,srv_set,config,other,rule_sign,src_range,dst_range,srv_range) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

  # 初始化变量
  my $params;

  # 遍历解析到的防火墙策略
  for my $rule ( values $self->{parser}{elements}{rule}->%* ) {

    # 构造 SQL VALUES
    my @rules;

    # fw_id
    push @rules, $self->fwId;

    # rule_id_name
    push @rules, $rule->{sign};

    # rule_num
    push @rules, $rule->{ruleNum};

    # from_zone
    push @rules, $rule->{fromZone};

    # to_zone
    push @rules, $rule->{toZone};

    my @src = keys $rule->srcAddressMembers->%*;
    my @dst = keys $rule->dstAddressMembers->%*;
    my @srv = keys $rule->serviceMembers->%*;

    # source_addr
    push @rules, encode_json \@src;

    # destination_addr
    push @rules, encode_json \@dst;

    # service
    push @rules, encode_json \@srv;

    # rule_action
    push @rules, $rule->{action};

    # rule_state
    if ( $rule->{isDisable} eq 'enable' ) {
      push @rules, 1;
    }
    else {
      push @rules, 0;
    }

    # expire_date
    if ( defined $rule->{schedule} and $rule->{schedule}->schType eq 'onetime' ) {
      push @rules, $rule->{schedule}->getEnddateStr;
    }
    else {
      push @rules, undef;
    }

    # src_set
    push @rules, encode_json {mins => $rule->srcAddressGroup->range->mins, maxs => $rule->srcAddressGroup->range->maxs};

    # dst_set
    push @rules, encode_json {mins => $rule->dstAddressGroup->range->mins, maxs => $rule->dstAddressGroup->range->maxs};

    # srv_set
    push @rules, encode_json {mins => $rule->serviceGroup->range->mins, maxs => $rule->serviceGroup->range->maxs};

    # config
    push @rules, $rule->{content};

    # other
    if ( defined $rule->{fromInterface} or defined $rule->{toInterface} ) {
      my %hash;
      $hash{fromInterface} = $rule->{fromInterface} if defined $rule->{fromInterface};
      $hash{toInterface}   = $rule->{toInterface}   if defined $rule->{toInterface};
      push @rules, \%hash;
    }
    else {
      push @rules, undef;
    }

    # rule_sign
    push @rules, $rule->{sign};

    # src_range
    my @src_range;
    for ( my $i = 0; $i < $rule->srcAddressGroup->range->mins->@*; $i++ ) {
      push @src_range,
        "[" . $rule->srcAddressGroup->range->mins->[$i] . "," . $rule->srcAddressGroup->range->maxs->[$i] . "]";
    }
    push @rules, \@src_range;

    # dst_range
    my @dst_range;
    for ( my $i = 0; $i < $rule->dstAddressGroup->range->mins->@*; $i++ ) {
      push @dst_range,
        "[" . $rule->dstAddressGroup->range->mins->[$i] . "," . $rule->dstAddressGroup->range->maxs->[$i] . "]";
    }
    push @rules, \@dst_range;

    # srv_range
    my @srv_range;
    for ( my $i = 0; $i < $rule->serviceGroup->range->mins->@*; $i++ ) {
      push @srv_range,
        "[" . $rule->serviceGroup->range->mins->[$i] . "," . $rule->serviceGroup->range->maxs->[$i] . "]";
    }
    push @rules, \@srv_range;

    # 将数据压入 params
    push $params->@*, \@rules;
  }
  $self->batchExecute( $params, $sql );
}

#------------------------------------------------------------------------------
# saveRoute 保存 parser 解析到的路由对象
#------------------------------------------------------------------------------
sub saveRoute {
  my $self = shift;

  # 插入数据之前删除历史数据
  $self->delete( where => {fw_id => $self->fwId}, table => "fw_route" );

  # 定义 SQL 语句
  my $sql
    = "insert into fw_route (fw_id,network,mask,nexthop,network_range,distance,priority,type,config,dstInterface,other,network_set) values(?,?,?,?,?,?,?,?,?,?,?,?)";

  # 初始化变量
  my $params;

  # 遍历解析到的路由条目
  for my $route ( values $self->{parser}{elements}{route}->%* ) {

    # 构造 SQL VALUES
    my @route;

    # fw_id
    push @route, $self->fwId;

    # network
    push @route, $route->{network};

    # mask
    push @route, $route->{mask};

    # nexthop
    push @route, $route->{nextHop};

    # network_range
    push @route, encode_json {maxs => $route->range->maxs, mins => $route->range->mins,};

    # distance
    push @route, $route->{distance};

    # priority
    push @route, $route->{priority};

    # type
    push @route, $route->{type};

    # config
    push @route, $route->{config};

    # dstInterface
    push @route, undef;

    # other
    if ( defined $route->{srcInterface} or defined $route->{srcRange} or defined $route->{routeInstance} ) {
      my %hash;

      # 路由关联源接口
      $hash{srcInterface} = $route->{srcInterface} if defined $route->{srcInterface};

      # 路由关联 srcRange
      $hash{srcRange} = {mins => $route->srcRange->mins, maxs => $route->srcRange->maxs} if defined $route->{srcRange};

      # 路由关联 routeInstance
      $hash{routeInstance} = $route->{routeInstance} if defined $route->{routeInstance};
      push @route, encode_json \%hash;
    }
    else {
      push @route, undef;
    }

    # network_set
    my @network_set;
    for ( my $i = 0; $i < $route->range->mins->@*; $i++ ) {
      push @network_set, "[" . $route->range->mins->[$i] . "," . $route->range->maxs->[$i] . "]";
    }
    push @route, \@network_set;

    # 将数据压入 params
    push $params->@*, \@route;
  }
  $self->batchExecute( $params, $sql );
}

#------------------------------------------------------------------------------
# saveService 保存 parser 解析到的服务端口对象
#------------------------------------------------------------------------------
sub saveService {
  my $self = shift;

  # 插入数据之前删除历史数据
  $self->delete( where => {fw_id => $self->fwId}, table => "fw_service" );

  # 定义 SQL 语句
  my $sql = "insert into fw_service (fw_id,service_name,ref_num,config,service_set,service_range) values(?,?,?,?,?,?)
    ON CONFLICT(fw_id,service_name) do update set config=EXCLUDED.config,service_set=EXCLUDED.service_set";

  # 初始化变量
  my $params;

  # 遍历解析到的服务端口对象
  for my $serv ( values $self->{parser}{elements}{service}->%* ) {

    # 构造 SQL VALUES
    my @serv;

    # fw_id
    push @serv, $self->fwId;

    # service_name
    push @serv, $serv->{srvName};

    # ref_num
    push @serv, $serv->{refnum};

    # config
    push @serv, $serv->{config};

    # service_set
    push @serv, encode_json {mins => $serv->range->mins, maxs => $serv->range->maxs};

    # service_range
    my @service_range;
    for ( my $i = 0; $i < $serv->range->mins->@*; $i++ ) {
      push @service_range, "[" . $serv->range->mins->[$i] . "," . $serv->range->maxs->[$i] . "]";
    }
    push @serv, \@service_range;

    # 将数据压入 $params
    push $params->@*, \@serv;
  }
  $self->batchExecute( $params, $sql );
}

#------------------------------------------------------------------------------
# saveAddress 保存 parser 解析到的地址对象
#------------------------------------------------------------------------------
sub saveAddress {
  my $self = shift;

  # 插入数据之前删除历史数据
  $self->delete( where => {fw_id => $self->fwId}, table => "fw_address" );

  # 定义 SQL 语句
  my $sql
    = "insert into fw_address (fw_id,addr_name,ref_num,config,address_set,address_range,other) values(?,?,?,?,?,?,?)
    ON CONFLICT(fw_id,addr_name) do update set config=EXCLUDED.config,address_set=EXCLUDED.address_set,address_range=EXCLUDED.address_range,other=EXCLUDED.other";

  # 初始化变量
  my $params;

  # 遍历解析到的地址对象
  for my $addr ( values $self->{parser}{elements}{address}->%* ) {

    # 构造 SQL VALUES
    my @addr;

    # fw_id
    push @addr, $self->fwId;

    # addr_name
    push @addr, $addr->{addrName};

    # ref_num
    push @addr, $addr->{refnum};

    # config
    push @addr, $addr->{config};

    # address_set
    push @addr, encode_json {mins => $addr->range->mins, maxs => $addr->range->maxs};

    # address_range
    my @address_range;
    for ( my $i = 0; $i < $addr->range->mins->@*; $i++ ) {
      push @address_range, "[" . $addr->range->mins->[$i] . "," . $addr->range->maxs->[$i] . "]";
    }
    push @addr, \@address_range;

    # other
    push @addr, encode_json {zone => $addr->{zone}};

    # 压入数据到 $params
    push $params->@*, \@addr;
  }

  # 遍历地址组对象
  for my $addrG ( values $self->{parser}{elements}{addressGroup}->%* ) {

    # 构造 SQL VALUES
    my @addr;

    # fw_id
    push @addr, $self->fwId;

    # addr_name
    push @addr, $addrG->{addrGroupName};

    # ref_num
    push @addr, $addrG->{refnum};

    # config
    push @addr, $addrG->{config};

    # address_set
    push @addr, encode_json {mins => $addrG->range->mins, maxs => $addrG->range->maxs};

    # address_range
    my @address_range;
    for ( my $i = 0; $i < $addrG->range->mins->@*; $i++ ) {
      push @address_range, "[" . $addrG->range->mins->[$i] . "," . $addrG->range->maxs->[$i] . "]";
    }
    push @addr, \@address_range;

    # other
    push @addr, encode_json {zone => $addrG->{zone}};

    # 将数据压入 $params
    push $params->@*, \@addr;
  }
  $self->batchExecute( $params, $sql );
}

#------------------------------------------------------------------------------
# updateNetwork 抽象批量更新大网、私网接口
#------------------------------------------------------------------------------
sub updateNetwork {
  my ( $self, $zones, @tables ) = @_;

  # 如果传入的非哈希引用则自动修正
  confess "网络区域必须是哈希引用"  if not ref $zones eq 'HASH' || not defined $zones;
  confess "必须提供至少一个表单数据" if scalar @tables == 0;

  # 遍历表单批量更新数据
  foreach my $table (@tables) {

    # 异常拦截
    confess "数据表不匹配，请整体填写" if $table !~ /fw_network_main|fw_network_private/i;

    # 定义 SQL 语句
    my $sql = "insert into $table (fw_id,zone,addr_range,addr_min,addr_max) values(?,?,?,?,?)";

    # 初始化变量
    my $params;

    # 插入数据之前删除历史数据
    $self->delete( where => {fw_id => $self->fwId}, table => $table );

    # 遍历防火墙网络区域
    foreach my $zone ( keys $zones->%* ) {

      # 这里的变量基于 Set 顺序一致
      my $addrIprange = $zones->{$zone}->addrIpRange;
      my $mins        = $zones->{$zone}->mins;
      my $maxs        = $zones->{$zone}->maxs;

      # COPY 复刻副本
      my $copy_addrIprange = dclone $addrIprange;
      my $copy_mins        = dclone $mins;
      my $copy_maxs        = dclone $maxs;

      # 遍历 addrIprange 数组
      while ( $copy_addrIprange->@* ) {

        # 初始化变量 @zone
        my @zone;

        # fw_id
        push @zone, $self->fwId;

        # zone
        push @zone, $zone;

        # addr_range
        push @zone, pop $copy_addrIprange->@*;

        # addr_min
        push @zone, pop $copy_mins->@*;

        # addr_max
        push @zone, pop $copy_maxs->@*;

        # 将数据压入 params
        push $params->@*, \@zone;
      }
    }

    # 插入快照数据
    $self->batchExecute( $params, $sql );
  }
}

#------------------------------------------------------------------------------
# updateStaticNatToNetwork 抽象自动绑定 NAT 网段到大网数据表单
#------------------------------------------------------------------------------
sub updateStaticNatToNetwork {
  my $self = shift;

  # 初始化变量
  my $params;
  my $table = 'fw_network_main';

  # 定义 SQL 语句
  my $sql = "insert into $table (fw_id,zone,addr_range,addr_min,addr_max) values(?,?,?,?,?)";

  # 查询防火墙快照中的静态地址转换
  for my $staticNat ( values $self->{parser}{elements}{staticNat}->%* ) {

    # 这里的变量基于 Set 顺序一致
    my $mins = $staticNat->natIpRange->mins;
    my $maxs = $staticNat->natIpRange->maxs;

    # COPY 复刻副本 | 深度复刻、互不影响
    my $copy_mins = dclone $mins;
    my $copy_maxs = dclone $maxs;

    # 遍历 $mins 数组
    while ( $copy_mins->@* ) {

      # 初始化变量 @network
      my @network;

      # 转换为 ipSet 集合 | 数据准备
      my $min        = pop $copy_mins->@*;
      my $max        = pop $copy_maxs->@*;
      my $ipMin      = Firewall::Utils::Ip->new->changeIntToIp($min);
      my $ipMax      = Firewall::Utils::Ip->new->changeIntToIp($max);
      my $addr_range = $ipMin . "-" . $ipMax;

      # fw_id | 数据填充阶段
      push @network, $self->fwId;

      # zone
      push @network, $staticNat->{realZone};

      # 填充 addr_range
      push @network, $addr_range;

      # addr_min
      push @network, $min;

      # addr_max
      push @network, $max;

      # 将数据压入 params
      push $params->@*, \@network;
    }
    $self->batchExecute( $params, $sql );
  }
}

#------------------------------------------------------------------------------
# saveFwNetworkPrivate 保存 parser 解析到的大网、私网对象
#------------------------------------------------------------------------------
sub saveFwNetworkPrivate {
  my $self = shift;

  # 获取防火墙标识
  my $fw_id = $self->fwId;

  # 定义 SQL 语句并及时查询
  my $select = "select is_nat,networkupdatemode from fw_info where fw_id = $fw_id";
  my $fwInfo = $self->dbi->execute($select)->one;

  # 如果更新模式为手动更新则不做处理 | networkupdatemode = 2 代表手工
  if ( $fwInfo->{networkupdatemode} == 2 ) {
    return;
  }

  # 非 NAT 防火墙，只需要维护大网信息
  if ( $fwInfo->{is_nat} == 0 ) {

    # 调用批量更新的抽象接口
    eval {
      my $zones = $self->{parser}{elements}{zone};
      $self->updateNetwork( $zones, 'fw_network_main' );
    };

    # confess "批量更新防火墙大网、私网期间捕捉异常：$@" if defined $@;
  }

  # 防火墙支持 NAT
  if ( $fwInfo->{is_nat} > 0 ) {
    my $sql      = "select * from fw_zone_state where fw_id = $fw_id";
    my $zoneInfo = $self->dbi->execute($sql)->all;

    # 遍历防火墙相关网络区域
    my ( @protected, @unProtected, @unUse );
    for my $zone ( $zoneInfo->@* ) {
      if ( defined $zone->{is_protected_zone} ) {
        if ( $zone->{is_protected_zone} == 1 ) {
          push @protected, $zone->{zone};
        }
        elsif ( $zone->{is_protected_zone} == 0 ) {
          push @unProtected, $zone->{zone};
        }
      }
      else {
        push @unUse, $zone->{zone};
      }
    }

    # 没有定义包含和非保护的网络区域
    if ( @protected == 0 && @unProtected == 0 ) {

      # 向大网、私网表插入数据
      eval {
        my $zones = $self->{parser}{elements}{zone};
        $self->updateNetwork( $zones, 'fw_network_private', 'fw_network_main' );
      };

      # confess "批量更新防火墙大网、私网期间捕捉异常：$@" if defined $@;
    }
    else {
      my $zoneIndex = $self->{parser}->{elements}->{zone};
      my $protectedZone;
      my $unprotectedZone;

      # 过滤快照关联的 zone 信息
      map { $protectedZone->{$_}   = $zoneIndex->{$_} } grep { exists $zoneIndex->{$_} } @protected;
      map { $unprotectedZone->{$_} = $zoneIndex->{$_} } grep { exists $zoneIndex->{$_} } @unProtected;

      # 定义本地数据字典
      my %tables = ( fw_network_private => $protectedZone, fw_network_main => $unprotectedZone );

      # 向大网、私网表插入数据
      foreach my $table ( keys %tables ) {
        $self->updateNetwork( $tables{$table}, $table );
      }
    }

    # 将静态地址转换的数据填充到大网表单 | 此处为补丁数据，不需要向前面删除数据
    $self->updateStaticNatToNetwork;
  }
}

#------------------------------------------------------------------------------
# saveSchedule 保存 parser 解析到计划任务对象
#------------------------------------------------------------------------------
sub saveSchedule {
  my $self = shift;
  my $columnMap
    = [qw/fw_id sch_name sch_type start_date end_date weekday start_time1 end_time1 start_time2 end_time2 description/];
}

#------------------------------------------------------------------------------
# getFwName 获取防火墙设备名
#------------------------------------------------------------------------------
sub getFwName {
  my $self = shift;

  # 查询 fw_info 下防火墙名，只返回一条结果
  my $tableName = 'fw_info';
  my $raw       = $self->select( column => ['fw_name'], table => $tableName, where => {fw_id => $self->fwId} )->one;

  # 检查是否成功返回查询结果
  if ( not defined $raw ) {
    confess "ERROR: 表 $tableName 中没有 fw_id 为 $self->fwId 的行";
  }
  elsif ( not defined $raw->{FW_NAME} ) {
    confess "ERROR: 表 $tableName 中 fw_id 为 $self->fwId 的行 的字段 FW_NAME 的值为空";
  }

  # 返回计算结果
  return $raw->{fw_name};
}

#------------------------------------------------------------------------------
# lock 设置防火墙表结构状态
#------------------------------------------------------------------------------
sub lock {
  my $self = shift;

  # 锁定防火墙 fw_conf 表状态
  my $fwName    = $self->getFwName();
  my $tableName = 'fw_conf';
  my $isLocking = $self->select( column => ['is_parsing'], table => $tableName, where => {fw_id => $self->fwId} )->one;

  # 检查是否成功返回查询结果
  if ( not defined $isLocking ) {
    confess "ERROR: 设备 $self->fwId $fwName 在 表 $tableName 中的 is_parsing 字段不存在";
  }
  elsif ( $isLocking->{is_parsing} == 0 ) {
    $self->execute(
      "UPDATE $tableName SET is_parsing = 1, parse_start_time = :parse_start_time WHERE fw_id = :fw_id",
      {parse_start_time => Firewall::Utils::Date->new->getLocalDate, fw_id => $self->fwId}
    );
  }
  else {
    confess "ERROR: 设备 $self->fwId :$fwName 的配置被锁了，无法对其进行处理";
  }

  # 查询 fw_conf 表状态
  my $result = $self->select( column => ['is_parsing'], table => $tableName, where => {fw_id => $self->fwId} )->one;

  # 检查是否成功返回查询结果
  if ( not defined $result ) {
    confess "ERROR: 表 $tableName 中 没有 fw_id 为  $self->fwId 的行，加锁失败";
  }
  elsif ( $result->{is_parsing} != 1 ) {
    confess "ERROR: 表 $tableName 中 fw_id 为 $self->fwId 的行 的字段 is_parsing 的值未能更新为 1，加锁失败";
  }
}

#------------------------------------------------------------------------------
# unLock 解锁防火墙解析状态
#------------------------------------------------------------------------------
sub unLock {
  my $self = shift;

  # 设置 fw_conf is_parsing 状态
  my $tableName = 'fw_conf ';
  $self->execute(
    "UPDATE $tableName SET is_parsing = 0, parse_end_time = :parse_end_time WHERE fw_id = :fw_id",
    {parse_end_time => Firewall::Utils::Date->new->getLocalDate, fw_id => $self->fwId}
  );
}

1;
