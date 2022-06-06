package Firewall::Config::Element::Service::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Carp;
use Moose::Role;
use Mojo::Loader qw(load_class);
use Firewall::Config::Element::ServiceMeta::Role;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Service::Role 通用属性
#------------------------------------------------------------------------------
has srvName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has metas => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::ServiceMeta::Role]',
  default => sub { {} },
);

has dstPortRangeMap => (
  is      => 'ro',
  isa     => 'HashRef[Firewall::Utils::Set]',
  default => sub { {} },
);

has refnum => (
  is      => 'ro',
  isa     => 'Int',
  default => 0
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildRange',
);

#------------------------------------------------------------------------------
# getServiceClassName 获取服务端口名
#------------------------------------------------------------------------------
sub getServiceClassName {
  my $self = shift;
  return ref($self);
}

#------------------------------------------------------------------------------
# getServiceClassName 获取原始端口（预定义）名
#------------------------------------------------------------------------------
sub getServiceMetaClassName {
  my ( $self, $serviceClassName ) = @_;
  my $serviceMetaClassName = $serviceClassName // $self->getServiceClassName;
  $serviceMetaClassName =~ s/::Service::/::ServiceMeta::/o;
  return $serviceMetaClassName;
}

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
# https://metacpan.org/pod/Moose::Manual::Construction
# https://metacpan.org/pod/Moose::Object
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig             = shift;
  my $serviceClassName = shift;
  if ( @_ > 2 ) {
    my $serviceMetaClassName = $serviceClassName->getServiceMetaClassName($serviceClassName);

    #--------------------------------------------------------------------------
    # 尝试加载 serviceMetaClassName
    # https://metacpan.org/pod/Mojo::Loader#load_class
    #--------------------------------------------------------------------------
    if ( my $e = load_class $serviceMetaClassName) {
      die ref $e ? "Exception: $e" : "$serviceMetaClassName Not found!";
    }

    # 实例化 serviceMetaClassName
    my $metaObj = $serviceMetaClassName->new(@_);
    return $serviceClassName->$orig( @_, 'metas', {$metaObj->sign => $metaObj} );
  }
  else {
    return $serviceClassName->$orig(@_);
  }
};

#------------------------------------------------------------------------------
# Moose BUILD 用于对象创建后，进行属性检查逻辑
# https://metacpan.org/pod/Moose::Manual::Construction
#------------------------------------------------------------------------------
sub BUILD {
  my $self  = shift;
  my @metas = values %{$self->metas};
  for my $metaObj (@metas) {
    $self->mergeDstPortRangeMap($metaObj);
  }
}

#------------------------------------------------------------------------------
# diffAttr 具体实现功能推敲
#------------------------------------------------------------------------------
sub diffAttr {
  my $self = shift;

  my ( $obj, @attrs ) = @_;
  my @ERROR;
  for my $attr (@attrs) {
    if ( $self->$attr ne $obj->$attr ) {
      push @ERROR, "输入的$attr [" . $obj->$attr . "] 与已有的$attr [" . $self->$attr . "] 不同";
    }
  }

  # 返回计算结果
  return @ERROR;
}

#------------------------------------------------------------------------------
# diffAttr 具体实现功能推敲
#------------------------------------------------------------------------------
sub addMeta {
  my $self = shift;
  my $serviceClassName;
  my $serviceMetaClassName;
  eval { $serviceClassName     = $self->getServiceClassName };
  eval { $serviceMetaClassName = $self->getServiceMetaClassName };
  confess $@ if $@;
  if ( @_ == 1 and $_[0]->isa($serviceClassName) ) {
    my $serviceObj = $_[0];
    my @ERROR      = $self->diffAttr( $serviceObj, qw/ sign / );
    confess( 'ERROR: ' . join( ', ', @ERROR ) . ' 无法执行方法addMeta' ) if @ERROR;
    for my $metaObj ( values %{$serviceObj->metas} ) {
      if ( not defined $self->metas->{$metaObj->sign} ) {
        $self->metas->{$metaObj->sign} = $metaObj;
        $self->mergeDstPortRangeMap($metaObj);
      }
      else {
        warn "已存在 sign 为 " . $metaObj->sign . " 的 serviceMeta，无需再add";
      }
    }
  }
  else {
    my $metaObj;
    if ( @_ == 1 and $_[0]->isa($serviceMetaClassName) ) {
      $metaObj = $_[0];
    }
    else {
      $metaObj = $serviceMetaClassName->new(@_);
    }
    if ( not defined $self->metas->{$metaObj->sign} ) {
      $self->metas->{$metaObj->sign} = $metaObj;
      $self->mergeDstPortRangeMap($metaObj);
    }
    else {
      warn "已存在 sign 为 " . $metaObj->sign . " 的 serviceMeta，无需再add";
    }
  }
} ## end sub addMeta

#------------------------------------------------------------------------------
# 返回区间值
#------------------------------------------------------------------------------
sub mergeDstPortRangeMap {
  my ( $self, $metaObj ) = @_;
  my $protocol = $metaObj->protocol;
  if ( not defined $self->dstPortRangeMap->{$protocol} ) {
    $self->dstPortRangeMap->{$protocol} = Firewall::Utils::Set->new;
  }
  $self->dstPortRangeMap->{$protocol}->mergeToSet( $metaObj->dstPortRange );
}

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $range = Firewall::Utils::Set->new;
  my @metas = values %{$self->metas};
  for my $metaObj (@metas) {
    $range->mergeToSet( $metaObj->range );
  }
  return $range;

}

1;
