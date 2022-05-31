package Firewall::Config::Dao::PredefinedService::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 Firewall::Config::Element::Service::Role 方法属性
#------------------------------------------------------------------------------
use Firewall::Config::Element::Service::Role;

#------------------------------------------------------------------------------
# 定义 Dao::PredefinedService::Role 方法属性
#------------------------------------------------------------------------------
has dbi => (
  is       => 'ro',
  does     => 'Firewall::DBI::Role',
  required => 1,
  handles  => [qw(select execute update insert delete batchExecute)],
);

has preDefinedService => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Service::Role]',
  default => sub { {} },
  writer  => 'setPreDefinedService',
);

has 'preDefinedServiceTableName' => (
  is      => 'ro',
  isa     => 'Str',
  builder => '_buildPreDefinedServiceTableName',
);

#------------------------------------------------------------------------------
# 明确继承 Dao::PredefinedService::Role 对象需要实现的方法
#------------------------------------------------------------------------------
requires '_buildPreDefinedServiceTableName';
requires 'vendor';

#------------------------------------------------------------------------------
# 具体实现 createService 方法
#------------------------------------------------------------------------------
sub createService {
  my ( $self, $param ) = @_;
  my ( $fwId, $srvName, $protocol, $srcPort, $dstPort )
    = @{$param}{qw/fwId srvName protocol srcPort dstPort/};
  # 实例化服务端口对象
  my $vendor       = $self->vendor;
  my $vendorPlugin = 'Firewall::Config::Element::Service::' . $vendor;
  eval("use $vendorPlugin");
  confess "Error Can not load plugin $vendorPlugin" if $@;
  my $service = $vendorPlugin->new(
    fwId     => $fwId,
    srvName  => $srvName,
    protocol => lc $protocol,
    srcPort  => $srcPort,
    dstPort  => $dstPort
  );
  # 防护计算结果
  return $service;
}

#------------------------------------------------------------------------------
# 加载 Dao::PredefinedService::Role 预定义服务端口
#------------------------------------------------------------------------------
sub load {
  my ( $self, $fwId ) = @_;

  # 入参检查 $fwId
  confess "ERROR: 必须传递具体的 fwId" if not defined $fwId;

  # 查询预定义端口表
  my $preDefinedService;
  my $services
    = $self->dbi->select( [qw/srv_name protocol src_port dst_port/], table => $self->preDefinedServiceTableName )->all;

  # 遍历预定义服务端口查询结果
  for my $item ( @{$services} ) {
    # 构造$param数据结构
    my $param = {fwId => $fwId};
    # 抽取查询结果内的属性，赋值给$param
    @{$param}{qw/srvName protocol srcPort dstPort/} = @{$item}{qw/srv_name protocol src_port dst_port/};

    # 返回对象 sign 标记
    my $service = $self->createService($param);

    # 抓取预定义的服务端口信息
    if ( exists $preDefinedService->{$service->sign} ) {
      $preDefinedService->{$service->sign}->addMeta($service);
    }
    else {
      $preDefinedService->{$service->sign} = $service;
    }
  }

  # 关联上预定义的服务端口信息
  $self->setPreDefinedService($preDefinedService);

  # 返回计算结果
  return $self->preDefinedService;
}

1;
