package Firewall::Config::Dao::Role;

use Moose::Role;
use Carp;
use Firewall::Utils::Date;

#------------------------------------------------------------------------------
# 继承 Firewall::DBI::Role 通用属性，引入 dbi 模块并加载其方法
#------------------------------------------------------------------------------
has dbi => (
  is       => 'ro',
  does     => 'Firewall::DBI::Role',
  required => 1,
  handles  => [qw(select execute update insert delete batchExecute batchInsert)],
);

#------------------------------------------------------------------------------
# 防火墙 fwId 查询主键
#------------------------------------------------------------------------------
has fwId => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  builder => '_buildFwId',
  writer  => 'setFwId',
);

#------------------------------------------------------------------------------
# 继承 Dao::Role 的角色，必须实现的方法
#------------------------------------------------------------------------------
requires '_buildFwId';

#------------------------------------------------------------------------------
# 定义设备 getFwName 通用属性
#------------------------------------------------------------------------------
sub getFwName {
  my $self      = shift;
  my $tableName = 'fw_info';
  my $raw       = $self->select(
    column => ['FW_NAME'],
    table  => $tableName,
    where  => {fw_id => $self->fwId}
  )->one;

  # 判断是否成功返回查询结果
  if ( not defined $raw ) {
    confess "ERROR: 表 $tableName 中没有 fw_id 为 $self->fwId 的行";
  }
  elsif ( not defined $raw->{FW_NAME} ) {
    confess "ERROR: 表 $tableName 中 fw_id 为 $self->fwId 的字段 FW_NAME 值为空";
  }

  # 返回查询结果
  return $raw->{FW_NAME};
}

#------------------------------------------------------------------------------
# 设备配置解析加锁
#------------------------------------------------------------------------------
sub lock {
  my $self      = shift;
  my $fwName    = $self->getFwName;
  my $tableName = 'fw_conf';
  my $isLocking = $self->select(
    column => ['is_parsing'],
    table  => $tableName,
    where  => {fw_id => $self->fwId}
  )->one;

  # 判断是否成功返回查询结果
  if ( not defined $isLocking ) {
    confess "ERROR: 设备 " . $self->fwId . ":$fwName 在 表 $tableName 中的 is_parsing 字段不存在";
  }
  elsif ( $isLocking->{is_parsing} == 0 ) {
    $self->execute(
      "UPDATE $tableName SET is_parsing = 1, parse_start_time = :parse_start_time WHERE fw_id = :fw_id",
      { parse_start_time => Firewall::Utils::Date->new->getLocalDate(),
        fw_id            => $self->fwId
      }
    );
  }
  else {
    confess "ERROR: 设备 " . $self->fwId . ":$fwName 的配置被锁了，无法对其进行处理";
  }

  # 再次查询
  my $result = $self->select(
    column => ['is_parsing'],
    table  => $tableName,
    where  => {fw_id => $self->fwId}
  )->one;
  if ( not defined $result ) {
    confess "ERROR: 表 $tableName 中 没有 fw_id 为 " . $self->fwId . " 的行，加锁失败";
  }
  elsif ( $result->{is_parsing} != 1 ) {
    confess "ERROR: 表 $tableName 中 fw_id 为 " . $self->fwId . " 的行 的字段 is_parsing 的值未能更新为 1，加锁失败";
  }
}

#------------------------------------------------------------------------------
# 解锁表单并设置时间戳
#------------------------------------------------------------------------------
sub unLock {
  my $self      = shift;
  my $tableName = 'fw_conf';
  $self->execute(
    "UPDATE $tableName SET is_parsing = 0, parse_end_time = :parse_end_time WHERE fw_id = :fw_id",
    { parse_end_time => Firewall::Utils::Date->new->getLocalDate(),
      fw_id          => $self->fwId
    }
  );
}

1;
