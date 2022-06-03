package FirewallController::Ff;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Try::Tiny;
# use Encode;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::DBI::Pg;
use Firewall::Config::Initialize;
use Firewall::FireFlow::FWDesign;
use Firewall::FireFlow::FWDeploy;

#use Firewall::FireFlow::FireflowControl;

#------------------------------------------------------------------------------
# Request 请求防火墙策略设计
#------------------------------------------------------------------------------
sub Request {
  my $self = shift;

  # 构造 result 数据结构
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 实例化 Pg 实例
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试进行策略设计
  try {
    my $reqId = $self->param('reqId');

    # 检查请求参数是否携带 reqId
    if ( not defined $reqId ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }

    # 进行防火墙策略设计
    else {
      my $fd           = Firewall::FireFlow::FWDesign->new( dbi => $dbi );
      my $designResult = $fd->designreqid($reqId);

      # 写入 result 标量
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $designResult
      };
    }
  } ## end try

  # 捕捉异常信息
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  # 返回计算结果
  $self->render( json => $result );
} ## end sub Request

#------------------------------------------------------------------------------
# Design 进行防火墙策略设计
#------------------------------------------------------------------------------
sub Design {
  my $self = shift;

  # 构造 result 数据结构
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 实例化 Pg
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试联机计算防火墙策略
  try {

    # 提取 policyinfo 并转换为 perl 数据结构
    my $policies = decode_json $self->param('policyinfo');

    # 检查请求参数是否携带 $policies
    if ( not defined $policies ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }

    # 防火墙策略设计和数据入库
    else {
      my $fd           = Firewall::FireFlow::FWDesign->new( dbi => $dbi );
      my $designResult = $fd->designAndSave($policies);

      # 写入数据结构
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $designResult
      };
    }
  } ## end try

  # 捕捉异常信息
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  # 返回计算结果
  $self->render( json => $result );
} ## end sub Design

#------------------------------------------------------------------------------
# Deploy 防火墙策略下发
#------------------------------------------------------------------------------
sub Deploy {
  my $self = shift;

  # 构造 result 数据结构
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 实例化 Pg
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试联机下发防火墙策略
  try {

    # 提取 taskId
    my $taskId = $self->param('taskId');

    # 检查 http 请求是否携带 taskId
    if ( not defined $taskId ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }

    # 查询 taskId 并进行防火墙策略下发
    else {
      my $fd        = Firewall::FireFlow::FWDeploy->new( dbi => $dbi );
      my $depResult = $fd->deploy($taskId);

      # 填充 result
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $depResult
      };
    }
  } ## end try

  # 捕捉异常信息
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  # 返回计算结果
  $self->render( json => $result );
} ## end sub Deploy

#------------------------------------------------------------------------------
# initFirewall 初始化防火墙，数据入库操作
#------------------------------------------------------------------------------
sub initFirewall {
  my $self = shift;

  # 构造 result 数据结构
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 实例化 Pg
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试联机初始化防火墙
  try {

    # 检查 http 请求是否携带 jsonStr
    my $json  = $self->param('jsonStr');
    my $param = decode_json $json;

    if ( not defined $json ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }

    # 进行防火墙初始化
    else {
      my $initFW     = Firewall::Config::Initialize->new( dbi => $dbi );
      my $initResult = $initFW->initFirewall($param);

      # 写入数据结构
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $initResult
      };
    }
  } ## end try

  # 捕捉异常信息
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  # 返回计算结果
  $self->render( json => $result );
} ## end sub initFirewall

#------------------------------------------------------------------------------
# updateNetwork 更新网络信息
#------------------------------------------------------------------------------
sub updateNetwork {
  my $self = shift;

  # 构造 result 数据结构
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 实例化 Pg
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试联机更新防火墙
  try {

    # 检查 http 请求是否携带 fwId
    my $fwId = $self->param('fwId');

    if ( not defined $fwId ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }

    # 更新防火墙
    else {
      my $initFW     = Firewall::Config::Initialize->new( dbi => $dbi );
      my $initResult = $initFW->updateNetwork($fwId);

      # 填充数据结构
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $initResult
      };
    }
  } ## end try

  # 捕捉异常信息
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  # 返回计算结果
  $self->render( json => $result );
} ## end sub updateNetwork

1;

