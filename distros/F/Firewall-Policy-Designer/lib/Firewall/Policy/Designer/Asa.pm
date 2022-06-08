package Firewall::Policy::Designer::Asa;

#------------------------------------------------------------------------------
# 加载系统模块，辅助构造函数功能和属性
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::Utils::Set;
use Firewall::Policy::Searcher::Report::FwInfo;

has dbi => (
  is       => 'ro',
  does     => 'Firewall::DBI::Role',
  required => 1,
);

has searcherReportFwInfo => (
  is       => 'ro',
  isa      => 'Firewall::Policy::Searcher::Report::FwInfo',
  required => 1,
);

has commandText => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

sub addToCommandText {
  my ( $self, @commands ) = @_;
  push @{$self->commandText}, @commands;
}

sub design {
  my $self = shift;
  if ( $self->searcherReportFwInfo->type eq 'new' ) {
    $self->createRule;
  }
  elsif ( $self->searcherReportFwInfo->type eq 'modify' ) {
    $self->createRule;
  }
  elsif ( $self->searcherReportFwInfo->type eq 'ignore' ) {
    if ( defined $self->searcherReportFwInfo->action ) {
      my $natSrc = $self->searcherReportFwInfo->action->{'new'}{'natSrc'};
      my $natDst = $self->searcherReportFwInfo->action->{'new'}{'natDst'};
      if ( defined $natSrc ) {
        for ( values %{$natSrc} ) {
          my %natInfo;
          $natInfo{'natSrc'} = $_;
          $self->checkAndCreateNat( \%natInfo );
        }
      }
      if ( defined $natDst ) {
        for ( values %{$natDst} ) {
          my %natInfo;
          $natInfo{'natDst'} = $_;
          $self->checkAndCreateNat( \%natInfo );
        }
      }
    } ## end if ( defined $self->searcherReportFwInfo...)
  }
  else {
    confess "ERROR: searcherReportFwInfo->type(" . $self->searcherReportFwInfo->type . ") Wrong!";
  }
  return join( '', map {"$_\n"} @{$self->commandText} );
} ## end sub design

sub createRule {
  my $self = shift;

=example

  access-list inbond extended permit tcp 10.50.0.0 255.255.0.0 host 10.11.100.252 eq 1234 log
  access-list inbond extended permit ip host 10.35.174.100 host 10.11.100.37 log
  access-list inbond extended permit tcp host 10.33.21.85 host 10.11.100.154 eq 1433
  access-list inbond extended permit tcp object-group G_Pub_Terminal_Svr host 10.11.100.52 eq 3389 log
  access-list inbond extndd permt tcp host 10.15.103.67 host 10.11.100.61 object-group P_152

=cut

  my $natSrc = $self->searcherReportFwInfo->action->{new}{natSrc};
  my $natDst = $self->searcherReportFwInfo->action->{new}{natDst};

  if ( defined $natSrc or defined $natDst ) {
    if ( defined $natSrc ) {
      for ( values %{$natSrc} ) {
        my %natInfo;
        $natInfo{natSrc} = $_;
        $self->checkAndCreateNat( \%natInfo );
      }
    }
    if ( defined $natDst ) {
      for ( values %{$natDst} ) {
        my %natInfo;
        $natInfo{natDst} = $_;
        $self->checkAndCreateNat( \%natInfo );
      }
    }
  } ## end if ( defined $self->searcherReportFwInfo...)
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my @commands;
  my $aclName = $self->searcherReportFwInfo->parser->getZone($fromZone)->{aclName};
  my @srcs    = ( keys %{$self->searcherReportFwInfo->{action}{new}{src}} );
  my @dsts    = ( keys %{$self->searcherReportFwInfo->{action}{new}{dst}} );
  my @srvs    = ( keys %{$self->searcherReportFwInfo->{action}{new}{srv}} );
  my $srcGroup;
  my $dstGroup;

  #my $srvGroup;

  if ( @srcs > 3 ) {
    $srcGroup = $self->createAddrGroup( \@srcs );
  }
  if ( @dsts > 3 ) {
    $dstGroup = $self->createAddrGroup( \@dsts );
  }
  @srcs = ($srcGroup) if defined $srcGroup;
  @dsts = ($dstGroup) if defined $dstGroup;

  for my $src (@srcs) {
    for my $dst (@dsts) {
      for my $srv (@srvs) {
        my $srcCommand = $self->changeAddressToCommand($src);
        my $dstCommand = $self->changeAddressToCommand($dst);
        my ( $protocolCommand, $portCommand ) = $self->changeSrvToCommand($srv);
        push @commands, "access-list $aclName extended permit $protocolCommand $srcCommand $dstCommand $portCommand";
      }
    }
  }
  $self->addToCommandText(@commands);
} ## end sub createRule

sub createAddrGroup {
  my ( $self, $addrs ) = @_;
  my $ippat     = '\d+\.\d+\.\d+\.\d+';
  my $parser    = $self->searcherReportFwInfo->parser;
  my $groupId   = sprintf( '%d', 100 + int( rand(10000) ) );
  my $groupName = "addrgroup" . $groupId;
  while ( defined $parser->getAddressGroup($groupName) ) {
    $groupName = "addrgroup" . sprintf( '%d', 100 + int( rand(10000) ) );
  }
  my @commands;
  my @addr;
  if ( $self->isNewVer ) {
    my $addrSet = Firewall::Utils::Set->new;
    for my $addr ( @{$addrs} ) {
      my ( $ip, $mask ) = split( '/', $addr );
      $addrSet->mergeToSet( Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask ) );
    }
    for ( my $i = 0; $i < $addrSet->length; $i++ ) {
      push @addr, Firewall::Utils::Ip->getIpMaskFromRange( $addrSet->mins->[$i], $addrSet->maxs->[$i] );
    }
    push @commands, "object-group network $groupName";
    for my $addr (@addr) {
      if ( $addr =~ /$ippat-$ippat/ ) {
        my $objName = $self->createObj($addr);
        push @commands, "network-object object $objName";
      }
      else {
        my ( $ip, $mask ) = split( '/', $addr );
        $mask = 32 if not defined $mask;
        if ( $mask == 32 ) {
          push @commands, "network-object host $ip";
        }
        else {
          my $maskStr = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
          push @commands, "network-object $ip $maskStr";
        }
      }
    }
    push @commands, "exit";
  }
  else {
    push @commands, "object-group network $groupName";
    for my $addr ( @{$addrs} ) {
      my ( $ip, $mask ) = split( '/', $addr );
      if ( $mask == 32 ) {
        push @commands, "network-object host $ip";
      }
      else {
        my $maskStr = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
        push @commands, "network-object $ip $maskStr";
      }
    }
    push @commands, "exit";
  }
  $self->addToCommandText(@commands);
  return $groupName;
} ## end sub createAddrGroup

sub createObj {
  my ( $self,  $addr )  = @_;
  my ( $ipMin, $ipMax ) = split( '-', $addr );
  my $objName = "range_$ipMin-$ipMax";
  my @commands;
  push @commands, "object network $objName";
  push @commands, "range $ipMin $ipMax";
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return $objName;
}

sub isNewVer {
  my $self    = shift;
  my $version = $self->searcherReportFwInfo->parser->{version};
  if ( defined $version ) {
    if ( $version =~ /(?<m>\d+)\.(?<p>\d+)/ ) {
      my $verNum   = $+{m} * 10 + $+{p};
      my $checkVer = ( $verNum >= 83 ) ? 1 : 0;
      return $checkVer;
    }
  }
  else {
    return;
  }
}

sub createSrvGroup {
  my ( $self, $addrs ) = @_;
  my $parser    = $self->searcherReportFwInfo->parser;
  my $groupId   = sprintf( '%d', 100 + int( rand(10000) ) );
  my $groupName = "servgroup" . $groupId;
  while ( defined $parser->getAddressGroup($groupName) ) {
    $groupName = "servgroup" . sprintf( '%d', 100 + int( rand(10000) ) );
  }
  my @commands;
}

sub CheckAndCreateNat {
  my ( $self, $param ) = @_;
  my @commands;
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  for my $type ( keys %{$param} ) {
    my $natIp   = $param->{$type}{natInfo}{natIp};
    my $natType = $param->{$type}{natInfo}{natType};
    my $realIp  = $param->{$type}->{realIp};
    my ( $ip, $mask ) = split( '/', $realIp );
    $mask = 32 if not defined $mask;
    my ( $mip, $mmask ) = split( '/', $natIp );
    $mmask = 32 if not defined $mmask;
    if ( $natType eq 'static' ) {

      if ( $mmask == 32 ) {
        push @commands, "object network obj-$ip";
        push @commands, "host $ip";
        push @commands, "nat ($toZone,$fromZone) static $mip" if $type eq 'natDst';
        push @commands, "nat ($fromZone,$toZone) static $mip" if $type eq 'natSrc';

        #push @commands, "exit";
      }
      else {
        my $mMaskStr = Firewall::Utils::Ip->new->changeMaskToIpForm($mmask);
        my $maskStr  = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
        push @commands, "object network obj-$mip";
        push @commands, "subnet $mip $mMaskStr";
        push @commands, "object network obj-$ip";
        push @commands, "subnet $ip $maskStr";
        push @commands, "nat ($toZone,$fromZone) static obj-$mip" if $type eq 'natDst';
        push @commands, "nat ($fromZone,$toZone) static obj-$mip" if $type eq 'natSrc';
      }
    }
    else {
      if ( $type eq 'natSrc' ) {
        my $mMaskStr = Firewall::Utils::Ip->new->changeMaskToIpForm($mmask);
        my $maskStr  = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
        push @commands, "object network obj-$mip";
        push @commands, "subnet $mip $mMaskStr" if $mmask != 32;
        push @commands, "host $mip "            if $mmask == 32;
        push @commands, "object network obj-$ip";
        push @commands, "subnet $ip $maskStr"                      if $mmask != 32;
        push @commands, "nat ($fromZone,$toZone) dynamic obj-$mip" if $type eq 'natSrc';
      }
    }
  } ## end for my $type ( keys %{$param...})
  $self->addToCommandText(@commands);
} ## end sub CheckAndCreateNat

sub checkAndCreateNat {
  my ( $self, $param ) = @_;
  if ( $self->isNewVer ) {
    $self->CheckAndCreateNat($param);
    return;
  }
  my $parser = $self->searcherReportFwInfo->parser;
  my ( $srcMap,   $dstMap ) = ( $self->searcherReportFwInfo->srcMap,   $self->searcherReportFwInfo->dstMap );
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my @commands;
  my $aclName;
  for my $type ( keys %{$param} ) {
    if ( $type eq 'natSrc' ) {
      my $natIp      = $param->{$type}{natInfo}{natIp};
      my $natType    = $param->{$type}{natInfo}{natType};
      my $realIp     = $param->{$type}->{realIp};
      my $srcCommand = $self->changeAddressToCommand($realIp);

      #Searcher中出现的aclname没有检查fromZone，可能会有些问题
      $aclName = $self->getAclName( $natIp, $type, $fromZone, $toZone );
      if ( defined $aclName ) {
        for my $dst ( keys %{$dstMap} ) {
          my $dstCommand = $self->changeAddressToCommand($dst);
          push @commands, "access-list $aclName extended permit ip $srcCommand $dstCommand";
        }
      }
      else {

        #新定义一个动态NAT.
        my $aclName = $self->createAclName;
        for my $dst ( keys %{$dstMap} ) {
          my $dstCommand = $self->changeAddressToCommand($dst);
          push @commands, "access-list $aclName extended permit ip $srcCommand $dstCommand";
        }

        #检查是否已有对应的pool;
        my $poolName = $self->getPoolName( $toZone, $natIp );
        if ( not defined $poolName ) {
          $poolName = $self->createPoolName;

          #global (outside) 123 172.16.18.100
          my ( $ip, $mask ) = split( '/', $natIp );
          $mask = 32 if not defined $mask;
          my $pool;
          if ( $mask == 32 ) {
            $pool = $ip;
          }
          else {
            my $maskStr = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
            $pool = $ip . ' netmask ' . $maskStr;
          }
          push @commands, "global ($toZone) $poolName $pool";
        }
        push @commands, "nat ($fromZone) $poolName access-list $aclName";
      } ## end else [ if ( defined $aclName )]
      $self->addToCommandText(@commands);
    }
    elsif ( $type eq 'natDst' ) {
      my $natIp  = $param->{$type}{natInfo}{natIp};
      my $realIp = $param->{$type}->{realIp};
      $aclName = $self->getAclName( $natIp, $type, $fromZone, $toZone );
      my $srcCommand = $self->changeAddressToCommand($realIp);
      if ( defined $aclName ) {
        for my $dst ( keys %{$srcMap} ) {
          my $dstCommand = $self->changeAddressToCommand($dst);
          push @commands, "access-list $aclName extended permit ip $srcCommand $dstCommand";
        }
      }
      else {

        #目标nat,使用静态nat方式
        my $aclName = $self->createAclName;
        for my $dst ( keys %{$srcMap} ) {
          my $dstCommand = $self->changeAddressToCommand($dst);
          $natIp =~ s/\/32//;
          push @commands, "access-list $aclName extended permit ip $srcCommand $dstCommand";
        }
        push @commands, "static ($toZone,$fromZone) $natIp access-list $aclName";
      }
      $self->addToCommandText(@commands);
    } ## end elsif ( $type eq 'natDst')
  } ## end for my $type ( keys %{$param...})
} ## end sub checkAndCreateNat

sub createDynamicNat {

}

sub createStaticNat {

}

sub getPoolName {
  my ( $self, $toZone, $natIp ) = @_;
  my $parser = $self->searcherReportFwInfo->parser;
  my $poolName;
  my ( $ip, $mask ) = split( '/', $natIp );
  my $natIpSet = Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask );
  for my $natPool ( values %{$parser->elements->natPool} ) {
    if ( $natPool->zone eq $toZone and $natPool->poolRange->isContain($natIpSet) ) {
      $poolName = $natPool->poolName;
    }
  }
  return $poolName;
}

sub getAclName {
  my ( $self, $natIp, $type, $fromZone, $toZone ) = @_;
  my $aclName;
  my $parser = $self->searcherReportFwInfo->parser;
  my $srcMap = $self->searcherReportFwInfo->srcMap;
  my $dstMap = $self->searcherReportFwInfo->dstMap;
  my $srcSet = Firewall::Utils::Set->new();
  my $dstSet = Firewall::Utils::Set->new();
  my ( $ip, $mask ) = split( '/', $natIp );
  my $natIpSet = Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask );

  for my $address ( keys %{$srcMap} ) {
    my ( $ip, $mask ) = split( '/', $address );
    $srcSet->mergeToSet( Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask ) );
  }
  for my $address ( keys %{$dstMap} ) {
    my ( $ip, $mask ) = split( '/', $address );
    $dstSet->mergeToSet( Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask ) );
  }
  if ( $type eq 'natSrc' ) {
    for my $staticNat ( values %{$parser->elements->staticNat} ) {
      if (  $staticNat->natZone eq $toZone
        and $staticNat->realZone eq $fromZone
        and $staticNat->natIpRange->isContain($natIpSet) )
      {
        $aclName = $staticNat->aclName;
        last;
      }
    }
    return $aclName if defined $aclName;

    #如果没有找到则继续查找动态NAT;
    for my $dynamicNat ( values %{$parser->elements->dynamicNat} ) {
      if (  $dynamicNat->toZone eq $toZone
        and $dynamicNat->fromZone eq $fromZone
        and $dynamicNat->natSrcRange->isContain($natIpSet) )
      {
        $aclName = $dynamicNat->aclName;
        last;
      }
    }
    return $aclName;
  }
  elsif ( $type eq 'natDst' ) {
    for my $staticNat ( values %{$parser->elements->staticNat} ) {
      if (  $staticNat->natZone eq $fromZone
        and $staticNat->realZone eq $toZone
        and $staticNat->natIpRange->isContain($natIpSet) )
      {
        $aclName = $staticNat->aclName;
        last;
      }
    }
    return $aclName if defined $aclName;

    #如果没有找到则继续查找动态NAT;
    for my $dynamicNat ( values %{$parser->elements->dynamicNat} ) {
      if (  $dynamicNat->toZone eq $toZone
        and $dynamicNat->fromZone eq $fromZone
        and defined $dynamicNat->{natDstRang}
        and $dynamicNat->natDstRange->isContain($natIpSet) )
      {
        $aclName = $dynamicNat->aclName;
        last;
      }
    }
    return $aclName;
  } ## end elsif ( $type eq 'natDst')
} ## end sub getAclName

sub createPoolName {
  my $self = shift;
  my $poolName;
  $poolName = sprintf( '%d', 100 + int( rand(9899) ) );
  while ( defined $self->searcherReportFwInfo->parser->getNatPool($poolName) ) {
    $poolName = sprintf( '%d', 100 + int( rand(9899) ) );
  }
  return $poolName;
}

sub createAclName {
  my $self = shift;
  my $aclName;
  my @flag;
  for my $rule ( values %{$self->searcherReportFwInfo->parser->elements->{rule}} ) {
    if ( $rule->aclName =~ /^\d+$/o ) {
      $flag[ $rule->aclName ] = 1;
    }
  }
  $aclName = sprintf( '%d', 100 + int( rand(9899) ) );
  while ( defined $flag[$aclName] ) {
    $aclName = sprintf( '%d', 100 + int( rand(9899) ) );
  }
  return $aclName;
}

sub changeAddressToCommand {
  my ( $self, $address ) = @_;
  my $result;
  my $ippat = '\d+\.\d+\.\d+\.\d+';
  if ( $address =~ /$ippat/ ) {
    my ( $ip, $mask ) = split( '/', $address );
    $mask = 32 if not defined $mask;
    if ( lc $ip eq 'any' ) {
      $result = 'any';
    }
    else {
      if ( $mask == 32 ) {
        $result = "host $ip";
      }
      else {
        my $maskStr = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
        $result = "$ip $maskStr";
      }
    }
  }
  elsif ( $address =~ /addrgroup/ ) {
    $result = "object-group $address";
  }
  return $result;
} ## end sub changeAddressToCommand

sub changeSrvToCommand {
  my ( $self,     $srv )  = @_;
  my ( $protocol, $port ) = split( '/', $srv );
  my $portCommand;
  if ( lc $protocol eq 'any' ) {
    $protocol    = 'ip';
    $portCommand = '';
  }
  else {
    if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
      $portCommand = "range $+{portMin} $+{portMax}";
    }
    elsif ( $port =~ /^\d+$/o ) {
      $portCommand = "eq $port";
    }
    else {
      confess "ERROR: $port is not a port";
    }
  }
  return ( $protocol, $portCommand );
} ## end sub changeSrvToCommand

__PACKAGE__->meta->make_immutable;
1;
