package Firewall::Config::Audit;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Time::HiRes;
use JSON;
use POSIX;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Date;
use Firewall::Utils::Ip;
use Firewall::Config::Content::Static;
use Firewall::Config::Connector;
use Firewall::Config::Dao::Parser;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', );

#------------------------------------------------------------------------------
# 策略合规审计
#------------------------------------------------------------------------------
sub auditPolicy {
  my ( $self, $rule ) = @_;
  my $audiRule = $self->getAudiRule();
  my $policy   = decode_json $rule;
  my ( $srcset, $dstset, $srvset );
  $srcset = $self->changeReqAddrToSet( $policy->{src} );
  $dstset = $self->changeReqAddrToSet( $policy->{dst} );
  $srvset = Firewall::Utils::Set->new;

  for my $ports ( @{$policy->{srv}} ) {
    for my $srv ( @{$ports->{port}} ) {
      $srvset->mergeToSet( Firewall::Utils::Ip->new->getRangeFromService($srv) );
    }
  }
  my $audiPolicy = {srcset => $srcset, dstset => $dstset, srvset => $srvset};
  my $result     = $self->_audit( $audiPolicy, $audiRule );
  return $result;
}

#------------------------------------------------------------------------------
# 将地址对象转换为 Set 集合
#------------------------------------------------------------------------------
sub changeReqAddrToSet {
  my ( $self, $addrInfo ) = @_;
  my $set = Firewall::Utils::Set->new();

  for my $addrs ( @{$addrInfo} ) {
    for my $ipmask ( @{$addrs->{ip}} ) {
      my ( $ip, $mask ) = split( '/', $ipmask );
      ( $ip, $mask ) = ( '0.0.0.0', '0' ) if $ip =~ /any/i;
      $mask = 32 if not defined $mask;
      $set->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask ) );
    }
  }
  return $set;
}

#------------------------------------------------------------------------------
# 审计防火墙下所有策略是否合规
#------------------------------------------------------------------------------
sub auditFw {
  my ( $self, $fw_id ) = @_;
  my $dbi    = $self->dbi;
  my $dao    = Firewall::Config::Dao::Parser->new( dbi => $dbi );
  my $parser = $dao->loadParser($fw_id);
  my $class  = ref($parser);
  eval("use $class;");
  my @rules    = values %{$parser->{elements}->{rule}};
  my $audiRule = $self->getAudiRule();
  my %ruleAudit;

  for my $rule (@rules) {
    next if $rule->{isDisable} eq 'disable';
    my $srcset = $rule->{srcAddressGroup}->range;
    my $dstset = $rule->{dstAddressGroup}->range;
    my $srvset = $rule->{serviceGroup}->range;
    my $policy = {srcset => $srcset, dstset => $dstset, srvset => $srvset};
    my $result = $self->_audit( $policy, $audiRule );
    $ruleAudit{$rule->{sign}} = $result if @{$result} > 0;
  }

  my $params;
  for my $rule ( keys %ruleAudit ) {
    my @rule;
    push @rule,      $parser->fwId;
    push @rule,      $rule;
    push @rule,      encode_json $ruleAudit{$rule};
    push @{$params}, \@rule;
  }
  $dbi->delete( where => {fw_id => $parser->fwId}, table => "fw_rule_risk_report" );
  my $sql = "insert into fw_rule_risk_report (fw_id,rule_id_name,risk_id) values (?,?,?)";
  $dbi->batchExecute( $params, $sql );
  return {success => 1};
}

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub _audit {
  my ( $self, $policy, $audiRule ) = @_;
  my @hitRule;
  for my $audiRuleInfo ( @{$audiRule} ) {
    my $hit          = 0;
    my $audiRelation = $audiRuleInfo->{contentSet}{relation};
    my %type;
    $type{src}  = 'srcset';
    $type{dst}  = 'dstset';
    $type{port} = 'srvset';
    my %action
      = ( eq => 'isEqual', neq => 'notEqual', scontain => 'isBelong', contain => 'isContain', cross => 'interSet' );
    if ( $audiRelation eq 'and' ) {
      for my $rule ( @{$audiRuleInfo->{contentSet}{content}} ) {
        my $func = $action{$rule->{relation}};
        if ( $func eq 'interSet' ) {
          my $setObj = $policy->{$type{$rule->{type}}}->interSet( $rule->{range} );
          if ( $setObj->length ) {
            $hit = 1;
          }
          else {
            $hit = 0;
            last;
          }
        }
        else {
          if ( $policy->{$type{$rule->{type}}}->$func( $rule->{range} ) ) {
            $hit = 1;
          }
          else {
            $hit = 0;
            last;
          }
        }
      }
    }
    elsif ( $audiRelation eq 'or' ) {
      for my $rule ( @{$audiRuleInfo->{contentSet}{content}} ) {
        my $func = $action{$rule->{relation}};
        if ( $policy->{$type{$rule->{type}}}->$func( $rule->{range} ) ) {
          $hit = 1;
          last;
        }
        else {
          $hit = 0;
        }
      }
    }
    if ( !!$hit ) {
      push @hitRule, $audiRuleInfo->{id};
    }
  }
  return \@hitRule;
}

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub _audit_bak {
  my ( $self, $policy, $audiRule ) = @_;
  my @hitRule;
  for my $audiRuleInfo ( @{$audiRule} ) {
    my $hit = 0;
    for my $rule ( @{$audiRuleInfo->{contentSet}} ) {
      if ( ( $rule->{type} eq 'src' or $rule->{type} eq 'dst' ) and $rule->{relation} eq 'contain' ) {
        if ( $rule->{type} eq 'src' ) {
          if ( $policy->{srcset}->isContain( $rule->{range} ) ) {
            $hit = 1;
          }
          else {
            $hit = 0;
            next;
          }
        }
        elsif ( $rule->{type} eq 'dst' ) {
          if ( $policy->{dstset}->isContain( $rule->{range} ) ) {
            $hit = 1;
          }
          else {
            $hit = 0;
            next;
          }
        }
      }
      elsif ( $rule->{type} eq 'port' and $rule->{relation} eq 'contain' ) {
        if ( $policy->{srvset}->isContain( $rule->{range} ) ) {
          $hit = 1;
        }
        else {
          $hit = 0;
          next;
        }
      }
    }
    if ($hit) {
      push @hitRule, $audiRuleInfo->{id};
    }
  }
  return \@hitRule;
}

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub getAudiRule {
  my $self     = shift;
  my $sql      = "select * from fw_compliance_risks";
  my $ruleInfo = $self->dbi->execute($sql)->all;
  for my $audiRuleInfo ( @{$ruleInfo} ) {
    my $audiRuleRef = decode_json $audiRuleInfo->{content};
    my $audiRule    = decode_json $audiRuleRef->{content};
    $audiRuleRef->{content}     = $audiRule;
    $audiRuleInfo->{contentSet} = $audiRuleRef;
    for my $rule ( @{$audiRule} ) {
      my $set = Firewall::Utils::Set->new();
      if ( $rule->{type} eq 'src' or $rule->{type} eq 'dst' ) {
        for my $ipmask ( @{$rule->{content}} ) {
          my ( $ip, $mask ) = split( '/', $ipmask );
          ( $ip, $mask ) = ( '0.0.0.0', '0' ) if $ip =~ /any/i;
          $mask = 32 if not defined $mask;
          $set->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask ) );
        }
      }
      elsif ( $rule->{type} eq 'port' ) {
        for my $srv ( @{$rule->{content}} ) {
          $set->mergeToSet( Firewall::Utils::Ip->new->getRangeFromService($srv) );
        }
      }
      $rule->{range} = $set;
    }
  }
  return $ruleInfo;
}

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub getRuleSrvSet {
  my ( $self, $portMap ) = @_;
  my $retSet = Firewall::Utils::Set->new;
  for my $proto ( keys %{$portMap} ) {
    if ( $proto eq '0' or $proto =~ /any/i ) {
      return Firewall::Utils::Set->new( 0, 16777215 );
    }
    elsif ( $proto =~ /tcp|udp|icmp|\d+/i ) {
      my $protoNum;
      if ( $proto =~ /tcp/i ) {
        $protoNum = 6;
      }
      elsif ( $proto =~ /udp/i ) {
        $protoNum = 17;
      }
      elsif ( $proto =~ /icmp/i ) {
        $protoNum = 1;
      }
      elsif ( $proto =~ /\d+/i ) {
        $protoNum = $proto;
      }
      my $min     = ( $protoNum << 16 );
      my $tempSet = Firewall::Utils::Set->new;
      $tempSet->mergeToSet( $portMap->{$proto} );
      for ( my $i = 0; $i < $tempSet->length; $i++ ) {
        $tempSet->mins->[$i] += $min;
        $tempSet->maxs->[$i] += $min;
      }
      $retSet->mergeToSet($tempSet);
    }
  }
  return $retSet;
}

__PACKAGE__->meta->make_immutable;
1;

