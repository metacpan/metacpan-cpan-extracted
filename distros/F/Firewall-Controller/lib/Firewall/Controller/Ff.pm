package Firewall::Controller::Ff;

# 请求接口期间会主动建立 SQL 链接
#------------------------------------------------------------------------------
# 加载扩展模块方法属性
#------------------------------------------------------------------------------
use Mojo::Base 'Mojolicious::Controller';
use utf8;
use JSON;
use Try::Tiny;
use namespace::autoclean;
use Mojo::Util qw(dumper);

#------------------------------------------------------------------------------
# 加载插件模块方法属性，包括数据库连结、策略设计、策略下发和防火墙初始化功能
#------------------------------------------------------------------------------
use Firewall::DBI::Pg;
use Firewall::FireFlow::FWDesign;
use Firewall::FireFlow::FWDeploy;
use Firewall::Config::InitFirewall;
# use Firewall::FireFlow::FireflowControl;

#------------------------------------------------------------------------------
# Request 请求防火墙策略设计，必须传入工单号 [此处可以追加工单格式判断]
#------------------------------------------------------------------------------
sub Request {
  my $self = shift;
  # 初始化变量
  my $result;
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
        content => '缺少输入参数'
      };
    }
    # 进行防火墙策略设计
    else {
      my $fwDesigner   = Firewall::FireFlow::FWDesign->new( dbi => $dbi );
      my $designResult = $fwDesigner->designReqId($reqId);
      # 写入 result 标量
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $designResult
      };
    }
  }
  # 捕捉异常信息
  catch {
    print $_->to_string;
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_->to_string
    };
  };

  # 返回计算结果
  $self->render( json => $result );
}

#------------------------------------------------------------------------------
# Design 进行防火墙策略设计，必须传入 policyinfo 属性 | 用于策略查询功能
#------------------------------------------------------------------------------
sub Design {
  my $self = shift;

  # 初始化变量
  my $result;

  # 实例化 Pg 数据库对象
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试联机计算防火墙策略
  try {
    # 提取 policyinfo 并转换为 perl 数据结构
    my $rules = decode_json $self->param('policyinfo');

    # 检查请求参数是否携带 policys
    if ( not defined $rules ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    # 防火墙策略设计和数据入库
    else {
      my $fwDesigner   = Firewall::FireFlow::FWDesign->new( dbi => $dbi );
      my $designResult = $fwDesigner->designAndSave($rules);
      # 写入数据结构
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $designResult
      };
    }
  }
  # 捕捉异常信息
  catch {
    print $_->to_string;
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_->to_string
    };
  };

  # 返回计算结果
  $self->render( json => $result );
}

#------------------------------------------------------------------------------
# Deploy 防火墙策略下发，必须携带 taskid
#------------------------------------------------------------------------------
sub Deploy {
  my $self = shift;
  # 初始化变量
  my $result;

  # 实例化 Pg 数据库对象
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  # 尝试联机下发防火墙策略
  try {
    # 提取 taskId
    my $taskId = $self->param('taskId');

    # 检查 http 请求是否携带 taskid
    if ( not defined $taskId ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    # 查询 taskid 并进行防火墙策略下发
    else {
      my $fwDeploy  = Firewall::FireFlow::FWDeploy->new( dbi => $dbi );
      my $depResult = $fwDeploy->deploy($taskId);
      # 填充 result
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $depResult
      };
    }
  }
  # 捕捉异常信息
  catch {
    print $_->to_string;
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_->to_string
    };
  };

  # 返回计算结果
  $self->render( json => $result );
}

#------------------------------------------------------------------------------
# initFirewall 初始化防火墙，必须携带 jsonStr
#------------------------------------------------------------------------------
sub initFirewall {
  my $self = shift;

  # 初始化变量
  my $result;

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
      my $initFW     = Firewall::Config::InitFirewall->new( dbi => $dbi );
      my $initResult = $initFW->initFirewall($param);
      # 写入数据结构
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $initResult
      };
    }
  }
  # 捕捉异常信息
  catch {
    print $_->to_string;
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_->to_string
    };
  };

  # 返回计算结果
  $self->render( json => $result );
}

#------------------------------------------------------------------------------
# updateNetwork 更新网络信息，必须携带 fwId
#------------------------------------------------------------------------------
sub updateNetwork {
  my $self = shift;

  # 初始化变量
  my $result;

  # 实例化 Pg 数据库对象
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
      my $initFW     = Firewall::Config::InitFirewall->new( dbi => $dbi );
      my $initResult = $initFW->updateNetwork($fwId);
      # 填充数据结构
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $initResult
      };
    }
  }
  # 捕捉异常信息
  catch {
    print $_->to_string;
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_->to_string
    };
  };

  # 返回计算结果
  $self->render( json => $result );
}

1;

