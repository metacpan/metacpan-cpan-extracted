package Firewall::FireFlow::RuleOptimize;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub optimizeRule {
  my ( $self, $rules ) = @_;
  $rules = &changeRuleToSet($rules);
  my $targetRules;
  for my $rule ( @{$rules} ) {
    $targetRules = &optimize( $rule, $targetRules );
  }
  return $targetRules;
}

#------------------------------------------------------------------------------
# changeRuleToSet
#------------------------------------------------------------------------------
sub changeRuleToSet {
  my $rules = shift;
  for my $rule ( @{$rules} ) {
    my $srcSet = Firewall::Utils::Set->new;
    my $dstSet = Firewall::Utils::Set->new;
    my $serSet = Firewall::Utils::Set->new;

    # 将rule源地址转换为set
    for my $ips ( @{$rule->{src}} ) {
      for ( @{$ips->{ip}} ) {
        my ( $ip, $mask ) = split( "/", $_ );
        $srcSet->mergeToSet( Firewall::Utils::Set->new( Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask ) ) );
      }
    }
    $rule->{srcSet} = $srcSet;

    # 将rule目的地址转换为set
    for my $ips ( @{$rule->{dst}} ) {
      for ( @{$ips->{ip}} ) {
        my ( $ip, $mask ) = split( "/", $_ );
        $dstSet->mergeToSet( Firewall::Utils::Set->new( Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask ) ) );
      }
    }
    $rule->{dstSet} = $dstSet;

    # 将rule服务端口转换为set
    for my $srvs ( @{$rule->{srv}} ) {
      for ( @{$srvs->{port}} ) {
        my ( $pro, $port ) = split( "/", $_ );
        my $proNum;
        $proNum = 100000 if lc $pro eq 'tcp';
        $proNum = 200000 if lc $pro eq 'udp';
        my ( $portMin, $portMax ) = split( "-", $port );
        $portMax = $portMin if not defined $portMax;
        $serSet->mergeToSet( Firewall::Utils::Set->new( ( $proNum + $portMin ), ( $proNum + $portMax ) ) );
      }
    }
    $rule->{serSet} = $serSet;
  }
  return $rules;
}

#------------------------------------------------------------------------------
# 策略优化
#------------------------------------------------------------------------------
sub optimize {
  my $rule        = shift;
  my $targetRules = shift;

  if ( not defined $targetRules ) {
    $targetRules->{$rule} = $rule;
    return $targetRules;
  }
  for ( keys %{$targetRules} ) {
    my $ruleCMP = $targetRules->{$_};
    my $CMP     = {
      equal              => [],
      containButNotEqual => [],
      belongButNotEqual  => [],
      other              => []
    };

    # 比较运算，并封装数据到CMP哈希表中
    my $srcCMP = $rule->{srcSet}->compare( $ruleCMP->{srcSet} );
    push @{$CMP->{$srcCMP}}, 'src';
    my $dstCMP = $rule->{dstSet}->compare( $ruleCMP->{dstSet} );
    push @{$CMP->{$dstCMP}}, 'dst';
    my $serCMP = $rule->{serSet}->compare( $ruleCMP->{serSet} );
    push @{$CMP->{$serCMP}}, 'ser';

    # 将CMP运算结果条件判断
    if ( ( @{$CMP->{equal}} + @{$CMP->{belongButNotEqual}} == 3 )
      or ( @{$CMP->{equal}} + @{$CMP->{containButNotEqual}} == 3 )
      or @{$CMP->{equal}} == 2 )
    {
      $ruleCMP->{srcSet}->mergeToSet( $rule->{srcSet} );
      $ruleCMP->{dstSet}->mergeToSet( $rule->{dstSet} );
      $ruleCMP->{serSet}->mergeToSet( $rule->{serSet} );

      # 源地址
      if ( $srcCMP eq 'other' ) {
        @{$ruleCMP->{src}} = ( @{$ruleCMP->{src}}, @{$rule->{src}} );
      }
      elsif ( $srcCMP eq 'containButNotEqual' ) {
        $ruleCMP->{src} = $rule->{src};
      }

      # 目的地址
      if ( $dstCMP eq 'other' ) {
        @{$ruleCMP->{dst}} = ( @{$ruleCMP->{dst}}, @{$rule->{dst}} );
      }
      elsif ( $dstCMP eq 'containButNotEqual' ) {
        $ruleCMP->{dst} = $rule->{dst};
      }

      # 服务端口
      if ( $serCMP eq 'other' ) {
        @{$ruleCMP->{srv}} = ( @{$ruleCMP->{srv}}, @{$rule->{srv}} );
      }
      elsif ( $serCMP eq 'containButNotEqual' ) {
        $ruleCMP->{srv} = $rule->{srv};
      }

      # 移除处理完毕的策略
      delete( $targetRules->{$_} );
      return &optimize( $ruleCMP, $targetRules );
    }
  }
  $targetRules->{$rule} = $rule;
  return $targetRules;
}

__PACKAGE__->meta->make_immutable;
1;
