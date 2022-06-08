package Firewall::Config::Dao::Parser;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Encode;
use Time::HiRes;
use Storable;

#------------------------------------------------------------------------------
# 继承 Firewall::Config::Dao::Role 方法属性
#------------------------------------------------------------------------------
with 'Firewall::Config::Dao::Role';

#------------------------------------------------------------------------------
# 定义 Firewall::Config::Dao::Parser 方法属性
#------------------------------------------------------------------------------
has parser => (
  is     => 'ro',
  does   => 'Firewall::Config::Parser::Role',
  writer => 'setParser',
);

#------------------------------------------------------------------------------
# 设置文件工作路径，缺省为 '/works/firewall/lib/' | 数据缓存 data
#------------------------------------------------------------------------------
has home => (
  is      => 'ro',
  isa     => 'Str',
  default => '/works/firewall/lib/'
);

#------------------------------------------------------------------------------
# getPluginObj 加载防火墙配置解析插件
#------------------------------------------------------------------------------
sub getPluginObj {
  my $self = shift;

  # 加载防火墙配置解析插件 => package
  my $pluginClassName = __PACKAGE__ . '::' . ( split( /::/, ref $self->parser ) )[-1];
  eval "use $pluginClassName";
  confess "ERROR: load plugin $pluginClassName failed: $@" if !!$@;

  # 实例化配置解析对象
  my $pluginObj = $pluginClassName->new(
    dbi    => $self->dbi,
    parser => $self->parser
  );

  # 返回计算结果
  return $pluginObj;
}

#------------------------------------------------------------------------------
# save 配置解析结果数据入库
#------------------------------------------------------------------------------
sub save {
  my $self = shift;

  # 检查对象是否继承 Firewall::Config::Parser::Role
  if ( @_ == 1 and $_[0]->does('Firewall::Config::Parser::Role') ) {

    # 绑定解析器、fwId
    $self->setParser( $_[0] );
    $self->setFwId( $_[0]->fwId );
  }

  # 加载解析对象 save 方法，实现数据入库
  my $pluginObj = $self->getPluginObj;
  $pluginObj->save;

  # 同时将结果 Storable 序列号存储
  $self->saveSerializedParser;
}

#------------------------------------------------------------------------------
# saveSerializedParser 配置解析结果序列化本地存储
#------------------------------------------------------------------------------
sub saveSerializedParser {
  my $self = shift;

  # 获取家目录，并初始化序列号文件夹
  my $home = $self->home;

  # my $data = 'Firewall/Config/Parser/data/';
  my $data = 'Caches/';
  mkdir( $data, 0755 ) or confess("ERROR: mkdir( $data, 0755 ) failed: $!") if not -d $data;

  # 序列化存储解析结果
  # 增加防火墙名称
  $home = $ENV{firewall_manager_home} . "/lib/" if exists $ENV{firewall_manager_home};
  my $path = $home . $data . $self->fwId;

  # 数据缓存
  Storable::store( $self->parser, $path );
}

#------------------------------------------------------------------------------
# loadParser 加载之前的解析结果，缓存防火墙快照
#------------------------------------------------------------------------------
sub loadParser {
  my ( $self, $fwId ) = @_;

  # 如果携带 fwId，则更新数据
  if ( defined $fwId ) {
    $self->setFwId($fwId);
  }

  # 获取家目录，并初始化序列号文件夹
  my $home = $self->home;

  # my $data = 'Firewall/Config/Parser/data/';
  my $data = 'Caches/';

  # mkdir($data, 0755) or confess("ERROR: mkdir( $data, 0755 ) failed: $!") if not -d $data;

  # 反序列化解析结构 | 支持临时的环境变量
  $home = $ENV{firewall_manager_home} . "/lib/" if exists $ENV{firewall_manager_home};

  # 增加防火墙名称
  my $path            = $home . $data . $self->fwId;
  my $parser          = Storable::retrieve($path);
  my $parserClassName = ref($parser);

  # 加载解析模块，加载异常则跳出
  eval "use $parserClassName";
  confess $@ if !!$@;

  # 返回计算结果
  return $parser;
}

#------------------------------------------------------------------------------
# _buildFwId 具体实现继承 Firewall::Config::Dao::Role 橘色的约束方法
#------------------------------------------------------------------------------
sub _buildFwId {
  my $self = shift;
  return $self->parser->fwId;
}

=head3 saveSerializedParser

  sub saveSerializedParser {
    my $self = shift;
    my $tableName = 'fw_conf';
    my $serializedParser = Storable::freeze($self->parser);
    $self->execute("update $tableName set serialized_parser = :serializedParser where fw_id = :fwId",
                    {serializedParser => $serializedParser, fwId => $self->fwId},
                    bind_type => [serializedParser => DBI::SQL_BLOB]); #注意这里 bind_type 是绑在变量名 serializedParser 上，而非字段名 serialized_parser 上
  }
  #DBI::SQL_BINARY,DBI::SQL_BLOB
  sub loadParser {
    my ($self, $fwId) = @_;
    if ( defined $fwId ) {
        $self->setFwId( $fwId );
    }
    my $tableName = 'fw_conf';

  my $result = $self->execute("select serialized_parser from $tableName where fw_id = :fwId", {fwId => $self->fwId})->one;
  confess("ERROR: get serializedParser(fwId: $fwId) from fw_conf failed!,可能使用了checkpoint,ASA8.3以上版本等工具不支持防火墙的私网地址，或数据库有问题请联系管理员处理") if not defined $result;
  my $serializedParser = $result->{SERIALIZED_PARSER};
  confess("ERROR: there is none column named SERIALIZED_PARSER in table $tableName") if not defined $serializedParser;
  my $parser = Storable::thaw( $serializedParser );

  my $parserClassName = ref($parser);
  eval("use $parserClassName;");
  confess("ERROR: import class $parserClassName failed: $@") if $@;
  #加载外部路由
  $parserClassName =~ /Firewall::Config::Parser::(?<fwtype>\S+)$/;
  my $fwType = $+{fwtype};
  my $routeExtras = $self->execute("select network,mask,zone from FW_NETWORK_Extra where fw_id = :fwId", {fwId => $self->fwId})->all;
  if (@{$routeExtras}>0){
    my $className = "Firewall::Config::Element::Route::$fwType";
    eval ("use Firewall::Config::Element::Route::$fwType");
    confess("ERROR: import class Firewall::Config::Element::Route::$fwType failed: $@") if $@;
    for my $row (@{$routeExtras}){
      my $route;
      my $className = "Firewall::Config::Element::Route::$fwType";
      eval( "\$route = new $className(fwId =>\$self->fwId,network =>'$row->{NETWORK}',mask =>$row->{MASK},zoneName=>'$row->{ZONE}',routeInstance=>'default');");
      confess("ERROR: new Route failed: $@") if $@;
      $parser->addElement($route);
    }
  }
  $self->setParser($parser);
  return $parser;
}

=cut

#------------------------------------------------------------------------------
# around 钩子函数，用于计算配置解析所需时常
#------------------------------------------------------------------------------
if ( $ENV{DEBUG} ) {

  # 遍历抓取各函数解析所需时常
  for my $func (qw(lock unLock saveSerializedParser loadParser)) {
    around $func => sub {

      # around 固定入参格式 (class, instance, params)
      my $orig = shift;
      my $self = shift;

      # 开始计时器
      my $start = sprintf( "%d.%06d", Time::HiRes::gettimeofday );
      print "$func start at $start\n";

      # 加载模块并解析配置完成，计时结束
      my $result = $self->$orig(@_);
      my $end    = sprintf( "%d.%06d", Time::HiRes::gettimeofday );
      print "$func end at $end\n";
      print "$func spend:" . ( $end - $start ) . "\n\n";

      # 返回计算结果
      return $result;
    };
  }
}

__PACKAGE__->meta->make_immutable;
1;
