package FirewallController::Ruleman;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Try::Tiny;
use Encode;
use Data::Dumper;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::DBI::Pg;
use Firewall::Config::Audit;
use Firewall::Policy::FindIp;
use Firewall::Config::Ruleopti;
use Firewall::Policy::Searcher;

#use Firewall::FireFlow::FireflowControl;

#------------------------------------------------------------------------------
# 审计防火墙下每条策略
#------------------------------------------------------------------------------
sub AuditFw {
  my $self   = shift;
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 初始化 SQL 会话
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  try {
    my $fwId = $self->param('fwId');
    if ( not defined $fwId ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    else {
      my $auditFw     = Firewall::Config::Audit->new( dbi => $dbi );
      my $auditResult = $auditFw->auditFw($fwId);
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $auditResult
      };
    }
  }
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  $self->render( json => $result );
} ## end sub AuditFw

#------------------------------------------------------------------------------
# 审计具体的某条策略是否合规
#------------------------------------------------------------------------------
sub AuditPolicy {
  my $self   = shift;
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 初始化 SQL 会话
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  try {
    my $policy = $self->param('policy');
    if ( not defined $policy ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    else {
      my $auditFw     = Firewall::Config::Audit->new( dbi => $dbi );
      my $auditResult = $auditFw->auditPolicy($policy);
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $auditResult
      };
    }
  }
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  $self->render( json => $result );
} ## end sub AuditPolicy

#------------------------------------------------------------------------------
# 查询某个IP相关策略
#------------------------------------------------------------------------------
sub searchip {
  my $self   = shift;
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 初始化 SQL 会话
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  try {
    my $ipaddr = $self->param('ipaddr');
    my $srv    = $self->param('srv');
    if ( not defined $ipaddr ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    else {
      my $findIp   = Firewall::Policy::FindIp->new( dbi => $dbi );
      my $ruleInfo = $findIp->search( $ipaddr, $srv );
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $ruleInfo
      };
    }
  }
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  $self->render( json => $result );
} ## end sub searchip

#------------------------------------------------------------------------------
# 策略优化：冗余策略合并、无效策略删除
#------------------------------------------------------------------------------
sub ruleopti {
  my $self   = shift;
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 初始化 SQL 会话
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  try {
    my $fwId = $self->param('fwId');
    if ( not defined $fwId ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    else {
      my $ruleOpt = Firewall::Config::Ruleopti->new( dbi => $dbi );
      my $ret     = $ruleOpt->optirule($fwId);
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $ret
      };
    }
  }
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };

  $self->render( json => $result );
} ## end sub ruleopti

#------------------------------------------------------------------------------
# 策略申请前预处理：如已开通提示用户
#------------------------------------------------------------------------------
sub policyCheck {
  my $self   = shift;
  my $result = {
    status  => 'ok',
    type    => '',
    content => ''
  };

  # 初始化 SQL 会话
  my $dbi = Firewall::DBI::Pg->new( $self->app->config->{db}{main} );

  try {
    my $policyJson = $self->param('policy');
    if ( not defined $policyJson ) {
      $result = {
        status  => 'error',
        type    => 'text',
        content => "缺少输入参数 "
      };
    }
    else {
      my $ret;
      my $searcher       = Firewall::Policy::Searcher->new( dbi => $dbi );
      my $policy         = decode_json $policyJson;
      my $searcherReport = $searcher->search( {src => $policy->{src}, dst => $policy->{dst}, srv => $policy->{srv}} );

      if ( $searcherReport->state == 0 ) {
        if ( $searcherReport->comment =~ /^error4/i ) {
          $ret = {
            success => 1,
            block   => 0,
            policy  => []
          };
        }
        my $comment = $searcherReport->comment;
        $comment =~ s/(.+?)\s+at\s+.+/$1/s;
        $ret = {
          success => 0,
          block   => 1
        };
      }
      else {
        my $block = 0;
        my @havePolicy;
        for my $policyInfo ( @{$searcherReport->FwInfos} ) {
          if ( $policyInfo->{type} eq 'ignore' ) {
            push @havePolicy,
              {
              content => $policyInfo->{ruleObj}->{content},
              fwName  => $policyInfo->{fwName}
              };
          }
          else {
            $block = 1;
            push @havePolicy,
              {
              content => $policyInfo->{ruleObj}->{content},
              fwName  => $policyInfo->{fwName}
              };
          }
        }
        $ret = {
          success => 1,
          block   => $block,
          policy  => \@havePolicy
        };
      } ## end else [ if ( $searcherReport->...)]
      $result = {
        status  => 'ok',
        type    => 'json',
        content => $ret
      };
    } ## end else [ if ( not defined $policyJson)]
  }
  catch {
    $result = {
      status  => 'error',
      type    => 'text',
      content => $_
    };
  };
  $self->render( json => $result );
} ## end sub policyCheck

1;

