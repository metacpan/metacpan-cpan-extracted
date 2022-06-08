package Firewall::Config::Parser::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;

#------------------------------------------------------------------------------
# 加载 Firewall::Policy::Element 通用属性
#------------------------------------------------------------------------------
use Firewall::Policy::Element::Service;
use Firewall::Policy::Element::Source;
use Firewall::Policy::Element::Destination;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Parser 通用属性
#------------------------------------------------------------------------------
use Firewall::Config::Element::Role;
use Firewall::Config::Parser::Elements;
use Firewall::Config::Parser::Report;

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Role 通用属性
#------------------------------------------------------------------------------
has fwId => (
  is      => 'ro',
  isa     => 'Int',
  builder => '_buildFwId',
  writer  => 'setFwId',
);

#------------------------------------------------------------------------------
# does 要求该属性包含 Firewall::Config::Content::Role
# https://metacpan.org/pod/distribution/Moose/lib/Moose/Manual/Attributes.pod
#------------------------------------------------------------------------------
has config => (
  is       => 'ro',
  does     => 'Firewall::Config::Content::Role',
  required => 1,
  writer   => 'setConfig',
  handles  => {
    nextUnParsedLine => 'nextUnParsedLine',
    backtrackLine    => 'backtrack',
    ignoreLine       => 'ignore',
    getUnParsedLines => 'getUnParsedLines',
    lineNumber       => 'cursor',
    goToHeadLine     => 'goToHead',
  },
);

has preDefinedService => (
  is       => 'ro',
  does     => 'HashRef[Firewall::Config::Element::Service::Role]',
  required => 1,
);

has elements => (
  is      => 'ro',
  isa     => 'Firewall::Config::Parser::Elements',
  default => sub { Firewall::Config::Parser::Elements->new },
  handles => {
    addElement => 'addElement',
  },
);

has report => (
  is      => 'ro',
  isa     => 'Firewall::Config::Parser::Report',
  default => sub { Firewall::Config::Parser::Report->new },
);

has elementType => (
  is      => 'ro',
  isa     => 'Str|Undef',
  default => undef,
  writer  => 'setElementType',
);

has ruleIndex => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Role 通用属性
#------------------------------------------------------------------------------
sub getElement {
  my ( $self, $elementType, @params ) = @_;
  confess "ERROR: number of params must bigger then 0" if @params == 0;
  my $sign = Firewall::Config::Element::Role->createSign(@params);
  $self->elements->getElement( $elementType, $sign );
}

#------------------------------------------------------------------------------
# 获取防火墙 id
#------------------------------------------------------------------------------
sub _buildFwId {
  my $self = shift;
  return $self->config->fwId;
}

#------------------------------------------------------------------------------
# 定义告警函数
#------------------------------------------------------------------------------
sub warn {
  my ( $self, $message ) = @_;
  $message .= "\n" if $message !~ /\n$/o;
  warn '[' . $self->elementType . ':' . $self->config->cursor . '] ' . $message;
}

#------------------------------------------------------------------------------
# 加载该角色必须实现的方法
#------------------------------------------------------------------------------
requires 'parse';

#------------------------------------------------------------------------------
# 当 parse 函数带输入参数时，检查输入参数，并更新 config 和 fwId
# https://stackoverflow.com/questions/22557427/perl-moose-augment-vs-around
#------------------------------------------------------------------------------
around 'parse' => sub {
  my $orig = shift;
  my $self = shift;
  if ( @_ == 1 and $_[0]->does('Firewall::Config::Content::Role') ) {
    $self->setConfig( $_[0] );
    $self->setFwId( $_[0]->fwId );
  }
  $self->$orig(@_);
  $self->createReport;
  return $self->elements;
};

#------------------------------------------------------------------------------
# 输出配置解析报告
#-----------------------------------------------------------------------------
sub createReport {
  my $self = shift;

  # 遍历防火墙访问控制策略
  for my $rule ( values %{$self->elements->{rule}} ) {

    # 跳转标记为 ignore 配置行
    next if $rule->ignore;

    # 解析防火墙策略源目地址对象
    $self->report->source->{$rule->sign} = Firewall::Policy::Element::Source->new(
      fwId     => $self->fwId,
      ruleSign => $rule->sign,
      ranges   => $rule->srcAddressGroup->range
    );
    $self->report->destination->{$rule->sign} = Firewall::Policy::Element::Destination->new(
      "fwId"     => $self->fwId,
      "ruleSign" => $rule->sign,
      "ranges"   => $rule->dstAddressGroup->range
    );

    # 解析防火墙策略服务端口对象
    for my $protocol ( keys %{$rule->serviceGroup->dstPortRangeMap} ) {
      $self->report->service->{$rule->sign}{$protocol} = Firewall::Policy::Element::Service->new(
        "fwId"     => $self->fwId,
        "ruleSign" => $rule->sign,
        "protocol" => $protocol,
        "ranges"   => $rule->serviceGroup->dstPortRangeMap->{$protocol}
      );
    }
  } ## end for my $rule ( values %...)
} ## end sub createReport

1;
