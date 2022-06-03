package Firewall::FireFlow::FWDesign;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use JSON;
use Carp;
use experimental "smartmatch";

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::DBI::Pg;
use Firewall::Utils::Set;
use Firewall::Policy::Searcher;
use Firewall::Policy::Designer;
use Firewall::FireFlow::RuleOptimize;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
has dbi => (
  is   => 'ro',
  does => 'Firewall::DBI::Role',
);

#------------------------------------------------------------------------------
# 根据工单生成脚本
#------------------------------------------------------------------------------
sub designReqId {
  my ( $self, $reqId ) = @_;

  # 查询 SQL
  my $sql     = "SELECT requestid,request_str FROM firewall_req WHERE requestid=$reqId";
  my $reqInfo = $self->dbi->execute($sql)->one;

  # 根据工单生成脚本
  my $param;
  $param->{reqId}    = $reqId;
  $param->{policies} = decode_json $reqInfo->{request_str};
  return $self->designAndSave($param);
}

#------------------------------------------------------------------------------
# 生成并保存配置
#------------------------------------------------------------------------------
sub designAndSave {
  my ( $self, $param ) = @_;

  # 绑定工单信息
  my $requestId = $param->{reqId};

  # 初始化策略优化对象
  my $rt = Firewall::FireFlow::RuleOptimize->new();

  # 实例化变量
  my %commands,;
  my $hadCommands;
  my $failCommand;

  my $policies = $rt->optimizeRule( $param->{policies} );
  for my $policy ( values %{$policies} ) {
    my $command = $self->_design($policy);
    if ( $command->{success} == 1 ) {
      for my $fwInfo ( @{$command->{commands}} ) {
        if ( defined $commands{$fwInfo->{fwId}} ) {
          map { $commands{$fwInfo->{fwId}}{commands} .= $_ . "\n" } @{$fwInfo->{commands}};
        }
        else {
          $commands{$fwInfo->{fwId}}{fwType}   = $fwInfo->{fwType};
          $commands{$fwInfo->{fwId}}{commands} = "";
          map { $commands{$fwInfo->{fwId}}{commands} .= $_ . "\n" } @{$fwInfo->{commands}};
        }
      }
      $hadCommands = $command->{hadPolicy} if defined $command->{hadPolicy};
    }
    else {
      my %policy;
      ${policy}{src} = $policy->{src};
      ${policy}{dst} = $policy->{dst};
      ${policy}{srv} = $policy->{srv};

      my $policyStr = encode_json \%policy;
      $failCommand = $policyStr unless defined $failCommand;
      $failCommand .= "$command->{reason}\n";
    }
  } ## end for my $policy ( values...)
  if ( defined $hadCommands ) {
    for my $fwName ( keys %{$hadCommands} ) {
      my $sql = "INSERT INTO firewall_havepolicy (requestid,fw_name,config) VALUES (:reqid,:fwName,:config)";
      $self->dbi->execute(
        $sql,
        { reqid  => $requestId,
          fwName => $fwName,
          config => $hadCommands->{$fwName}
        }
      );
    }
  }
  my $designed = 0;
  for my $fwId ( keys %commands ) {
    $designed = 1;
    my $sql    = "SELECT fw_name,manage_ip,autodeploy FROM fw_info WHERE fw_id = $fwId";
    my $fwInfo = $self->dbi->execute($sql)->one;
    $commands{$fwId}{fw_name}    = $fwInfo->{fw_name};
    $commands{$fwId}{manage_ip}  = $fwInfo->{manage_ip};
    $commands{$fwId}{autodeploy} = $fwInfo->{autodeploy};
    $commands{$fwId}{requestid}  = $requestId;
    $commands{$fwId}{fwId}       = $fwId;

    # 查询 sql
    $sql = "INSERT INTO firewall_task (requestid,manage_ip,fw_id,fw_name,fw_type,config,deploy_flag,save_date) VALUES
        (:requestid,:manage_ip,:fwId,:fw_name,:fwType,:commands,:autodeploy,now())";
    $self->dbi->execute( $sql, $commands{$fwId} );
  }
  if ( not defined $failCommand ) {
    if ( $designed == 1 ) {
      my $sql = "UPDATE firewall_req SET designstate = 1,nw_state=3,designdate = now() WHERE requestid = :reqid";
      $self->dbi->execute( $sql, {reqid => $requestId} );
    }
    else {
      my $sql = "UPDATE firewall_req SET designstate = 1,nw_state=7,designdate = now() WHERE requestid = :reqid";
      $self->dbi->execute( $sql, {reqid => $requestId} );
    }
    return {success => 1};
  }
  else {
    if ( $failCommand =~ /error4/ ) {
      if ( $designed == 1 ) {
        my $sql
          = "UPDATE firewall_req SET designstate = 1,nw_state=3,remark = :rmk,designdate = now() WHERE requestid = :reqid";
        $self->dbi->execute(
          $sql,
          { reqid => $requestId,
            rmk   => $failCommand
          }
        );
      }
      else {
        my $sql
          = "UPDATE firewall_req SET designstate = 1,nw_state=7,remark = :rmk,designdate = now() WHERE requestid = :reqid";
        $self->dbi->execute(
          $sql,
          { reqid => $requestId,
            rmk   => $failCommand
          }
        );
      }
      return {success => 1};
    }
    else {
      if ( $designed == 1 ) {
        my $sql
          = "UPDATE firewall_req SET designstate = 1,nw_state=3,remark = :rmk,designdate = now() WHERE requestid = :reqid";
        $self->dbi->execute(
          $sql,
          { reqid => $requestId,
            rmk   => $failCommand
          }
        );
      }
      else {
        my $sql
          = "UPDATE firewall_req SET designstate = 0,nw_state=2,remark = :rmk,designdate = now() WHERE requestid = :reqid";
        $self->dbi->execute(
          $sql,
          { reqid => $requestId,
            rmk   => $failCommand
          }
        );
        return {
          success => 0,
          reason  => $failCommand
        };
      }
    } ## end else [ if ( $failCommand =~ /error4/)]
  } ## end else [ if ( not defined $failCommand)]
} ## end sub designAndSave

#------------------------------------------------------------------------------
# 策略生成脚本主函数
#------------------------------------------------------------------------------
sub _design {
  my ( $self, $policy ) = @_;
  my $commands = $self->getCommands( $policy->{src}, $policy->{dst}, $policy->{srv}, $policy->{sch} );
  if ( $commands->{success} == 1 ) {
    return $commands;
  }
  else {
    my $exception = $commands->{reason};
    if ( $exception =~ /error0/ ) {
      return {
        success => 0,
        reason  => "需要联系管理员处理,$exception"
      };
    }
    elsif ( $exception =~ /error1/ ) {
      return {
        success => 0,
        reason  => "请确认ip是否正确,$exception"
      };
    }
    elsif ( $exception =~ /error2/ ) {
      return {
        success => 0,
        reason  => $exception
      };
    }
    elsif ( $exception =~ /error4/ ) {
      return {
        success => 0,
        reason  => "$exception"
      };
    }
    elsif ( $exception =~ /error5/ ) {
      return {
        success => 0,
        reason  => $exception
      };
    }
    elsif ( $exception =~ /error6/ ) {
      return {
        success => 0,
        reason  => $exception
      };
    }
    elsif ( $exception =~ /error9/ ) {
      return {
        success => 0,
        reason  => $exception
      };
    }
    else {
      return {
        success => 0,
        reason  => $exception
      };
    }
  } ## end else [ if ( $commands->{success...})]
} ## end sub _design

#------------------------------------------------------------------------------
# 根据三元组生成策略
#------------------------------------------------------------------------------
sub getCommands {
  my ( $self, $src, $dst, $srv, $sch ) = @_;

  my $dbi = $self->dbi;
  my @fwCommands;
  $dbi->dbi->dbh->{LongReadLen} = 70_000_000;

  # 联机查询是否命中防火墙
  my $searcher       = Firewall::Policy::Searcher->new( dbi => $dbi );
  my $searcherReport = $searcher->search( {src => $src, dst => $dst, srv => $srv, sch => $sch} );

  # say dumper keys %{$searcherReport->{FwInfos}[0]->{parser}{report}};
  if ( $searcherReport->state == 0 ) {
    my $comment = $searcherReport->comment;
    $comment =~ s/(.+?)\s+at\s+.+/$1/s;
    return {
      success => 0,
      reason  => $comment
    };
  }

  # say dumper $searcherReport;
  # 实例化策略设计对象
  my $designer = Firewall::Policy::Designer->new(
    searcherReport => $searcherReport,
    dbi            => $dbi
  );
  my $designInfos = $designer->design;

  my %havePolicy;
  for my $designInfo ( @{$designInfos} ) {
    my $commandStr = '';
    my @existCommands;
    for my $df ( @{$designInfo->{policyContents}} ) {
      if ( defined $df->{exist}{content} ) {
        if ( $commandStr !~ /$df->{exist}{content}/ ) {
          push @existCommands, $_ for ( split( '\n', $df->{exist}{content} ) );
          $commandStr = \@existCommands;
        }
      }
    }
    if ( $commandStr ne '' ) {
      if ( not defined $havePolicy{$designInfo->{fwName}} ) {
        $havePolicy{$designInfo->{fwName}} = $commandStr;
      }
      else {
        if ( $havePolicy{$designInfo->{fwName}} !~ /$commandStr/ ) {
          $havePolicy{$designInfo->{fwName}} .= $commandStr;
        }
      }
    }
    my %fwCommand;
    $fwCommand{fwType} = $designInfo->{fwType};
    my $fwName = $designInfo->{fwName};
    my $ip;
    if ( $fwName =~ /.+\((?<ip>.+)\)\s*/ ) {
      $ip = $+{ip};
    }
    $fwCommand{ip}   = $ip;
    $fwCommand{fwId} = $designInfo->{fwId};
    my @commands;
    my $policyContents = $designInfo->{policyContents};
    if ( $designInfo->{policyState} ne 'allExist' ) {
      for my $commandInfo ( @{$policyContents} ) {
        if ( defined $commandInfo->{new}{content} and $commandInfo->{new}{content} ne '' ) {
          push @commands, $_ for ( split( '\n', $commandInfo->{new}{content} ) );
        }
      }
    }
    else {
      next;
    }
    $fwCommand{commands} = \@commands;
    push @fwCommands, \%fwCommand;
  } ## end for my $designInfo ( @{...})
  return {
    success   => 1,
    commands  => \@fwCommands,
    hadPolicy => \%havePolicy
  };
} ## end sub getCommands

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub design {
  my ( $self, $param ) = @_;
  my $requestId = $param->{reqId};
  my $policies  = $param->{policies};

  my %commands;
  my $failCommand = "";
  for my $policy ( @{$policies} ) {
    my $command = $self->_design($policy);
    if ( $command->{success} == 1 ) {
      for my $fwInfo ( @{$command->{commands}} ) {
        if ( defined $commands{$fwInfo->{fwId}} ) {
          map { $commands{$fwInfo->{fwId}}{commands} .= $_ . "\n" } @{$fwInfo->{commands}};
        }
        else {
          $commands{$fwInfo->{fwId}}{fwType}   = $fwInfo->{fwType};
          $commands{$fwInfo->{fwId}}{commands} = "";
          map { $commands{$fwInfo->{fwId}}{commands} .= $_ . "\n" } @{$fwInfo->{commands}};
        }
      }
    }
    else {
      my %policy;
      ${policy}{src} = $policy->{src};
      ${policy}{dst} = $policy->{dst};
      ${policy}{srv} = $policy->{srv};
      $failCommand .= "$command->{reason}\n";
    }
  } ## end for my $policy ( @{$policies...})
  say "finished req $requestId";
} ## end sub design

__PACKAGE__->meta->make_immutable;
1;

