package Firewall::Config::Dao::Config;

#------------------------------------------------------------------------------
#  加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Text::Diff;

#------------------------------------------------------------------------------
#  继承 Firewall::Config::Dao::Role 的角色需要实现 required 方法
#------------------------------------------------------------------------------
with 'Firewall::Config::Dao::Role';

#------------------------------------------------------------------------------
# 定义 'Firewall::Config::Content::Role' 方法属性
#------------------------------------------------------------------------------
has conf => ( is => 'ro', does => 'Firewall::Config::Content::Role', required => 1, );

#------------------------------------------------------------------------------
# 具体实现 _buildFwId 方法 | 生成 fwId
#------------------------------------------------------------------------------
sub _buildFwId {
  my $self = shift;
  return $self->conf->fwId;
}

#------------------------------------------------------------------------------
# 保存设备配置到数据库
#------------------------------------------------------------------------------
sub save {
  my $self = shift;

  # 初始化变量
  my $fwConfTable          = 'fw_conf';
  my $fwConfigHistoryTable = 'fw_config_history';
  my $fwId                 = $self->fwId;
  my $isConfigChanged      = $self->isConfigChanged;

  # 配置状态改变逻辑判断
  if ( $isConfigChanged == 2 ) {

    # 新增配置，同时存储到历史配置、配置快照两张表
    $self->execute(
      "INSERT INTO $fwConfTable (fw_id, conf_sign, conf_content, check_time, modify_time) VALUES (:fwId, :confSign, :confContent,:checkTime,:modifyTime)",
      { fwId        => $fwId,
        confSign    => $self->conf->confSign,
        confContent => $self->conf->confContent,
        checkTime   => $self->conf->timestamp,
        modifyTime  => $self->conf->timestamp
      }
    );

    # 同时将配置改变写入 fw_config_history
    my $sql
      = "INSERT INTO $fwConfigHistoryTable (fw_id,config,update_date,compare_report) VALUES (:id,:config,now(),:report)";
    $self->execute( $sql, {id => $self->fwId, config => $self->conf->confContent, report => 'new config'} );
  }

  # 已有配置但发生变化，现在修改,先拿到diff情况
  elsif ( $isConfigChanged == 1 ) {

    # 老配置存储再数据库中
    my $sql = "SELECT conf_content FROM fw_conf WHERE fw_id = $fwId";
    my $old = $self->execute($sql)->one->{conf_content};

    # 切割新老配置为数组
    my $oldConfig = [ split( /\n/, defined $old ? $old : "" ) ];
    my $newConfig = [ split( /\n/, $self->conf->confContent ) ];

    # 比对新老配置结果
    my $compareReport = diff( $oldConfig, $newConfig, {STYLE => "Context"} );

    # 将配置变化写入 fw_config_history | 此处为差量配置
    $sql
      = "INSERT INTO $fwConfigHistoryTable (fw_id,config,update_date,compare_report) VALUES (:id,:config,now(),:report)";
    $self->execute( $sql, {id => $self->fwId, config => $self->conf->confContent, report => $compareReport} );

    # 更新配置到 fw_conf
    $self->execute(
      "UPDATE $fwConfTable SET conf_sign = :confSign, conf_content = :confContent, check_time = :checkTime, modify_time = :modifyTime WHERE fw_id = :fwId",
      { fwId        => $fwId,
        confSign    => $self->conf->confSign,
        confContent => $self->conf->confContent,
        checkTime   => $self->conf->timestamp,
        modifyTime  => $self->conf->timestamp
      }
    );
  }

  # 已有配置且未发生变化，只修改访问时间
  else {
    $self->execute( "UPDATE $fwConfTable SET check_time = :checkTime WHERE fw_id = :fwId",
      {fwId => $fwId, checkTime => $self->conf->timestamp} );

    # 更新历史配置信息
    my $sql
      = "INSERT INTO $fwConfigHistoryTable (fw_id,config,update_date,compare_report) VALUES (:id,:config,now(),:report)";
    $self->execute( $sql, {id => $self->fwId, config => $self->conf->confContent, report => "no change"} );
  }

  # 返回配置变更比对结果
  return $isConfigChanged;
}

#------------------------------------------------------------------------------
# 检索配置哈希值判断是否发生变化：新增配置、配置变动、未发生变化
#------------------------------------------------------------------------------
sub isConfigChanged {
  my $self = shift;

  # 初始化变量
  my $tableName = 'fw_conf';
  my $raw       = $self->select( column => ['conf_sign'], table => $tableName, where => {fw_id => $self->fwId} )->one;

  # 查表无配置即代表为新增配置
  if ( !defined $raw ) {
    return 2;
  }

  # 已有配置且发生变化
  elsif ( $raw->{conf_sign} ne $self->conf->confSign ) {
    return 1;
  }

  # 已有配置且未发生变化
  else {
    return 0;
  }
}

__PACKAGE__->meta->make_immutable;
1;
