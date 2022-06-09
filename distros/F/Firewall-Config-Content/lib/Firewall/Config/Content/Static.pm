package Firewall::Config::Content::Static;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use Encode;
use Digest::MD5;
use Firewall::Utils::Date;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义 Content::Static 通用属性
#------------------------------------------------------------------------------
has config => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1, );

has confContent => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_buildConfContent', );

has cursor => ( is => 'ro', isa => 'Int', default => 0, );

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Content::Role 角色属性和方法约束
#------------------------------------------------------------------------------
with 'Firewall::Config::Content::Role';

#------------------------------------------------------------------------------
# 改写 confSign 属性并设置懒加载，提供构建方法
#------------------------------------------------------------------------------
has '+confSign' => ( required => 0, lazy => 1, builder => '_buildConfSign', );

has '+timestamp' => ( required => 0, lazy => 1, builder => '_buildTimestamp', );

#------------------------------------------------------------------------------
# 配置文件哈希方法
#------------------------------------------------------------------------------
sub _buildConfSign {
  my $self = shift;
  return Digest::MD5::md5_hex( join( "\n", @{$self->config} ) );
}

#------------------------------------------------------------------------------
# 加载设备配置方法
#------------------------------------------------------------------------------
sub _buildConfContent {
  my $self    = shift;
  my $content = join( "\n", @{$self->config} );
  return $content;
}

#------------------------------------------------------------------------------
# 生成配置时间戳
#------------------------------------------------------------------------------
sub _buildTimestamp {
  my $self = shift;
  return Firewall::Utils::Date->new->getFormatedDate();
}

#------------------------------------------------------------------------------
# 生成配置解析标志位，为每行配置设置初始状态为0
#------------------------------------------------------------------------------
sub _buildLineParsedFlags {
  my $self = shift;
  return ( [ map {0} ( 1 .. @{$self->config} ) ] );
}

#------------------------------------------------------------------------------
# 跳转 Head 头部函数，引入游标的概念
#------------------------------------------------------------------------------
sub goToHead {
  my $self = shift;
  $self->{cursor} = 0;
}

#------------------------------------------------------------------------------
# 跳转 nextLine 函数，跳转下一行
#------------------------------------------------------------------------------
sub nextLine {
  my $self = shift;
  my $result;
  if ( $self->cursor < scalar( @{$self->config} ) ) {
    $result = $self->config->[ $self->cursor ];
    $self->{cursor}++;
  }
  return $result;
}

#------------------------------------------------------------------------------
# 获取上一行游标号，非设备配置具体内容
#------------------------------------------------------------------------------
sub prevLine {
  my $self = shift;
  if ( $self->{cursor} > 0 ) {
    $self->{cursor}--;
    return 1;
  }
  else {
    warn "ERROR: prevLine failed, because cursor on the head\n";
    return;
  }
}

#------------------------------------------------------------------------------
# 获取后续非解析配置
#------------------------------------------------------------------------------
sub nextUnParsedLine {
  my $self = shift;
  my $result;

  # 跳转到未解析配置所在行
  while ( $self->cursor < scalar( @{$self->config} ) and $self->getParseFlag == 1 ) {
    $self->{cursor}++;
  }

  # 判断配置是否存在未解析配置
  if ( $self->cursor < scalar( @{$self->config} ) ) {

    # 写入解析到的配置行
    $result = $self->config->[ $self->cursor ];

    # 跳转空白行
    while ( not defined $result or $result =~ /^\s*$/ ) {

      # 设置解析成功标签，并自增游标号
      $self->setParseFlag;
      $self->{cursor}++;

      # 再次判断是否已成功解析，解析成功后自增游标号
      while ( $self->cursor < scalar( @{$self->config} ) and $self->getParseFlag == 1 ) {
        $self->{cursor}++;
      }
      if ( $self->cursor < scalar( @{$self->config} ) ) {
        $result = $self->config->[ $self->cursor ];
      }
      else {
        return;
      }
    }

    # 设置解析状态标志位，并自增游标号
    $self->setParseFlag;
    $self->{cursor}++;
  }

  # 取出首尾空白字符串
  chomp $result if ( defined $result );

  #并解码为utf8
  return decode( 'utf8', $result );
} ## end sub nextUnParsedLine

#------------------------------------------------------------------------------
# 回退游标位，返回上一个游标号
#------------------------------------------------------------------------------
sub backtrack {
  my $self = shift;
  if ( $self->{cursor} > 0 ) {
    $self->{cursor}--;
    $self->setParseFlag(0);
    return 1;
  }
  else {
    warn "ERROR: backtrack failed, because cursor on the head\n";
    return;
  }
}

#------------------------------------------------------------------------------
# 忽略逻辑
#------------------------------------------------------------------------------
sub ignore {
  my $self = shift;
  $self->backtrack and $self->nextLine;
}

#------------------------------------------------------------------------------
# 获取所有未解析过的配置行
#------------------------------------------------------------------------------
sub getUnParsedLines {
  my $self          = shift;
  my $unParsedLines = join( '',
    map { $self->config->[$_] } grep { $self->{lineParsedFlags}->[$_] == 0 } ( 0 .. scalar( @{$self->config} ) - 1 ) );
  return $unParsedLines;
}

#------------------------------------------------------------------------------
# 获取配置数组解析状态码
#------------------------------------------------------------------------------
sub getParseFlag {
  my $self = shift;
  if ( $self->cursor >= 0 and $self->cursor < scalar( @{$self->config} ) ) {
    return $self->{lineParsedFlags}->[ $self->cursor ];
  }
  else {
    return;
  }
}

#------------------------------------------------------------------------------
# 设置解析状态标志位
#------------------------------------------------------------------------------
sub setParseFlag {
  my ( $self, $flag ) = @_;
  if ( $self->cursor >= 0 and $self->cursor < scalar( @{$self->config} ) ) {
    $self->{lineParsedFlags}->[ $self->cursor ] = $flag // 1;
    return 1;
  }
  else {
    return;
  }
}

__PACKAGE__->meta->make_immutable;
1;
