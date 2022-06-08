package Firewall::Policy::Designer::H3c;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
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

  #delete $self->searcherReportFwInfo->{parser};
  if ( $self->searcherReportFwInfo->type eq 'new' ) {
    $self->createRule;
  }
  elsif ( $self->searcherReportFwInfo->type eq 'modify' ) {
    $self->modifyRule;
  }
  elsif ( $self->searcherReportFwInfo->type eq 'ignore' ) {
    if ( defined $self->searcherReportFwInfo->action ) {
      my $param = $self->searcherReportFwInfo->action->{'new'};
      for my $type ( keys %{$param} ) {
        if ( $type eq 'natDst' or $type eq 'natSrc' ) {
          $self->createNat( $param->{$type}, $type );
        }
      }
    }
  }
  else {
    confess( "ERROR: searcherReportFwInfo->type(" . $self->searcherReportFwInfo->type . ") must be 'new' or 'modify'" );
  }
  if ( @{$self->commandText} > 0 ) {
    unshift @{$self->commandText}, 'sys';
    push @{$self->commandText}, 'save';
  }
  return join( '', map {"$_\n"} @{$self->commandText} );
} ## end sub design

sub createRule {
  my $self    = shift;
  my $action  = $self->searcherReportFwInfo->action->{'new'};
  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat($action);

=pod
    my $natString = '';
    $natString .= $nameMap->{natSrc}->[0]->{natStr} if defined $nameMap->{natSrc};
    $natString .= $nameMap->{natDst}->[0]->{natStr} if defined $nameMap->{natDst};
=cut

  my $scheduleName;
  my $schedule = $self->searcherReportFwInfo->{schedule};
  $scheduleName = $self->createSchedule($schedule) if $schedule->{enddate} ne 'always';
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my $objPolicyName = $self->getPolicyName( $fromZone, $toZone );
  my $objname;

  for my $obj_poli_name ( keys %{$objPolicyName->{obj}} ) {
    if (  $objPolicyName->{obj}{$obj_poli_name}{fromZone} eq $fromZone
      and $objPolicyName->{obj}{$obj_poli_name}{toZone} eq $toZone )
    {
      $objname = $obj_poli_name;
      last;
    }
  }
  my @commands;
  push @commands, "object-policy ip $objname";
  my $cmdStr
    = "rule pass source-ip "
    . ( shift @{$nameMap->{src}} )
    . " destination-ip "
    . ( shift @{$nameMap->{dst}} )
    . " service "
    . ( shift @{$nameMap->{srv}} );

  $cmdStr .= " time-range $scheduleName" if defined $scheduleName;
  push @commands, $cmdStr;
  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "rule XXX append source-ip $host";
      }

    }
    elsif ( $type eq 'dst' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "rule XXX append destination-ip $host";
      }

    }
    elsif ( $type eq 'srv' ) {
      for my $srv ( @{$nameMap->{$type}} ) {
        push @commands, "rule XXX append service $srv";
      }
    }

  } ## end for my $type ( keys %{$nameMap...})
  push @commands, "exit";
  $self->addToCommandText(@commands);
} ## end sub createRule

sub modifyRule {
  my $self    = shift;
  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat( $self->searcherReportFwInfo->action->{'add'} );
  if ( defined $self->searcherReportFwInfo->action->{'new'} ) {
    my $param = $self->searcherReportFwInfo->action->{'new'};
    for my $type ( keys %{$param} ) {
      if ( $type eq 'natDst' or $type eq 'natSrc' ) {
        $self->createNat( $param->{$type}, $type );

      }
    }
  }
  my $policyId = $self->searcherReportFwInfo->ruleObj->policyId;
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my $objPolicyName = $self->getPolicyName( $fromZone, $toZone );
  my $objname;
  for my $obj_poli_name ( keys %{$objPolicyName->{obj}} ) {
    if (  $objPolicyName->{obj}{$obj_poli_name}{fromZone} eq $fromZone
      and $objPolicyName->{obj}{$obj_poli_name}{toZone} eq $toZone )
    {
      $objname = $obj_poli_name;
      last;
    }
  }
  my @commands;
  push @commands, "object-policy ip $objname";
  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "rule $policyId append source-ip $host";
      }

    }
    elsif ( $type eq 'dst' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "rule $policyId append destination-ip $host";
      }

    }
    elsif ( $type eq 'srv' ) {
      for my $srv ( @{$nameMap->{$type}} ) {
        push @commands, "rule $policyId append service $srv";
      }

    }

  } ## end for my $type ( keys %{$nameMap...})

  push @commands, qq{exit};

  $self->addToCommandText(@commands);

} ## end sub modifyRule

sub checkAndCreateAddrOrSrvOrNat {
  my ( $self, $param ) = @_;
  my $nameMap;
  for my $type ( keys %{$param} ) {
    if ( $type eq 'natDst' or $type eq 'natSrc' ) {
      $nameMap->{$type} = $self->createNat( $param->{$type}, $type );
    }
    else {
      for my $addrOrSrv ( keys %{$param->{$type}} ) {
        if ( not defined $param->{$type}{$addrOrSrv} ) {
          my $func = "create" . ( ucfirst $type );    #createSrc, createDst, createSrv
          push @{$nameMap->{$type}}, $self->$func($addrOrSrv);
        }
        else {
          push @{$nameMap->{$type}}, $param->{$type}{$addrOrSrv}[0];
        }
      }
    }
  }
  return $nameMap;
} ## end sub checkAndCreateAddrOrSrvOrNat

sub createNat {
  my ( $self, $param, $type ) = @_;
  my $natStrs;
  my $dyNatInfo = {};
  for my $natInfo ( values %{$param} ) {
    if ( $natInfo->{natInfo}->{natType} eq 'static' ) {
      $self->createStaticNat($natInfo);
    }
    else {
      $dyNatInfo->{$type}{$natInfo->{natInfo}}{$natInfo->{realIp}} = $natInfo;
    }
  }
  if ( scalar( values %{$dyNatInfo} ) != 0 ) {
    $self->createDyNat($dyNatInfo);
  }
}

sub createStaticNat {
  my ( $self, $natInfo ) = @_;

=pod
nat static outbound 10.33.5.78 10.25.78.90
nat static outbound net-to-net 10.33.6.0 10.33.6.255 global 10.25.6.0 255.255.255.0
=cut

  my $natIp = $natInfo->{natInfo}{natIp};
  my @commands;
  push @commands, "nat static outbound $natInfo->{realIp} $natIp";
  $self->addToCommandText(@commands);

}

sub createDyNat {
  my ( $self, $param ) = @_;
  my $srcMap   = $self->searcherReportFwInfo->srcMap;
  my $dstMap   = $self->searcherReportFwInfo->dstMap;
  my $fromZone = $self->searcherReportFwInfo->fromZone;
  my $toZone   = $self->searcherReportFwInfo->toZone;
  my $parser   = $self->searcherReportFwInfo->parser;
  my @commands;
  for my $type ( keys %{$param} ) {

    for my $natIps ( values %{$param->{$type}} ) {
      my $natInfo       = ( values %{$natIps} )[0]->{natInfo};
      my $interfaceName = $natInfo->{interface};
      if ( $type eq 'natSrc' ) {

        #not set nat ip default nat interface
        if ( not defined $natInfo->{natIp} ) {
          my $aclName = $self->getAndCreatAclName();
          push @commands, "interface $interfaceName";
          push @commands, "nat outbound $aclName";
        }
        else {

          my $aclName = $self->getAndCreatAclName();

          #my $natIp = $natInfo->{natIp};
          my $ipPool = $self->getOrCreatePool($natInfo);
          push @commands, "interface $interfaceName";
          if ( $ipPool =~ /^\d+$/ ) {
            push @commands, "nat outbound $aclName address-group $ipPool" if $ipPool =~ /^\d+$/;
          }
          else {
            push @commands, "nat outbound $aclName address-group name $ipPool";
          }

        }

      }
      elsif ( $type eq 'natDst' ) {
        my $realIp = ( values %{$natIps} )[0]->{realIp};
        my $natIp  = $natInfo->{natIp};
        my ( $rIp, $rMask ) = split( '/', $realIp );
        my ( $nIp, $nMask ) = split( '/', $natIp );
        if ( not defined $rMask or $rMask == 32 ) {
          push @commands, "interface $interfaceName";
          push @commands, "nat server global $nIp inside $rIp";
        }
        else {
          my ( $rMin, $rMax ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $rIp, $rMask );
          my $rMinIp = Firewall::Utils::Ip->new->changeIntToIp($rMin);
          my $rMaxIp = Firewall::Utils::Ip->new->changeIntToIp($rMax);
          my ( $nMin, $nMax ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $nIp, $nMask );
          my $nMinIp = Firewall::Utils::Ip->new->changeIntToIp($rMin);
          my $nMaxIp = Firewall::Utils::Ip->new->changeIntToIp($rMax);
          push @commands, "interface $interfaceName";
          push @commands, "nat server global $nMinIp $nMaxIp inside $rMinIp $rMaxIp";
        }
      } ## end elsif ( $type eq 'natDst')
    } ## end for my $natIps ( values...)
  } ## end for my $type ( keys %{$param...})
  push @commands, qq{exit};
  $self->addToCommandText(@commands);
} ## end sub createDyNat

sub getOrCreatePool {
  my ( $self, $natInfo ) = @_;
  my $natIp = $natInfo->{natIp};
  my $natIpSet;
  if ( $natIp =~ /\d+\.\d+\.\d+\.\d+(\/\d+)?/ ) {
    my ( $ip, $mask ) = split( '/', $natIp );
    $mask     = 32 if not defined $mask;
    $natIpSet = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  }
  elsif ( $natIp =~ /\d+\.\d+\.\d+\.\d+\-\d+\.\d+\.\d+\.\d+/ ) {
    my ( $startIp, $endIp ) = split( '-', $natIp );
    $natIpSet = Firewall::Utils::Ip->new->getRangeFromIpRange( $startIp, $endIp );
  }
  my $natPools = $self->searcherReportFwInfo->parser->elements->natPool;
  for my $pool ( values %{$natPools} ) {
    if ( $pool->poolRange->isContain($natIpSet) ) {
      return $pool->poolName;
    }
  }

=pod
nat address-group name pool-10.22.34.56
 address 10.22.34.56 10.22.34.60
=cut

  my @commands;
  my $poolName = "Pool-$natIp";
  push @commands, "nat address-group name $poolName";
  my ( $startIp, $endIp );
  if ( $natIp =~ /\d+\.\d+\.\d+\.\d+(\/\d+)?/ ) {
    my ( $ip, $mask ) = split( '/', $natIp );
    $mask = 32 if not defined $mask;
    my ( $min, $max ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
    $startIp = Firewall::Utils::Ip->new->changeIntToIp($min);
    $endIp   = Firewall::Utils::Ip->new->changeIntToIp($max);
  }
  elsif ( $natIp =~ /\d+\.\d+\.\d+\.\d+\-\d+\.\d+\.\d+\.\d+/ ) {
    ( $startIp, $endIp ) = split( '-', $natIp );
  }
  push @commands, "address $startIp $endIp";
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return $poolName;

} ## end sub getOrCreatePool

sub createSrc {
  my ( $self, $addr ) = @_;
  return $self->createAddress($addr);
}

sub createDst {
  my ( $self, $addr ) = @_;
  return $self->createAddress($addr);
}

sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

sub createAddress {
  my ( $self, $addr ) = @_;

=pod
object-group ip address 10.22.22.22
 0 network host address 10.22.22.22
=cut

  my ( $ip, $mask ) = split( '/', $addr );
  my ( $addressName, $ipString, $ipMin, $ipMax );
  if ( not defined $mask ) {
    if ( $ip =~ /(\d+\.)(\d+\.)(\d+\.)(\d+)-(\d+)/ ) {
      ( $ipMin, $ipMax ) = ( $1 . $2 . $3 . $4, $1 . $2 . $3 . $5 );
      $addressName = "Range_$ip";
      $ipString    = "range $ipMin $ipMax";
    }
  }
  elsif ( $mask == 32 ) {
    $ipString    = "host address $ip";
    $addressName = "Host_$ip";
  }
  elsif ( $mask == 0 ) {
    return 'any';
  }
  else {
    my $subnetString = Firewall::Utils::Ip->new->getNetIpFromIpMask( $ip, $mask );
    my $maskString   = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
    $addressName = "Net_$subnetString/$mask";
    $ipString    = "subnet $subnetString $maskString";
  }
  my @commands;
  push @commands, "object-group ip address $addressName";
  push @commands, "network $ipString";
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return $addressName;
} ## end sub createAddress

sub createService {
  my ( $self,     $srv )  = @_;
  my ( $protocol, $port ) = split( '/', $srv );
  $protocol = lc $protocol;
  return if $protocol ne 'tcp' and $protocol ne 'udp';

=pod
object-group service tcp_4567
 0 service tcp destination eq 4567

=cut

  my ( $serviceName, $dstPort );
  if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
    $serviceName = uc($protocol) . "_" . $+{portMin} . "_" . $+{portMax};
    $dstPort     = "range $+{portMin} $+{portMax}";
  }
  elsif ( $port =~ /^\d+$/o ) {
    $serviceName = uc($protocol) . "_" . $port;
    $dstPort     = "eq $port";
  }
  else {
    confess "ERROR: $port is not a port";
  }

  my @commands;
  push @commands, "object-group service $serviceName";
  push @commands, "service $protocol destination $dstPort";
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return $serviceName;
} ## end sub createService

sub createSchedule {
  my ( $self, $schedule ) = @_;
  my @commands;

  # time-range gdfgs from 17:43 1/8/2018 to 17:44 2/22/2018
  my ( $syear, $smon, $sday, $shh, $smm ) = split( '[ :-]', $schedule->{startdate} ) if defined $schedule->{startdate};
  my ( $year,  $mon,  $day,  $hh,  $mm )  = split( '[ :-]', $schedule->{enddate} );
  push @commands, "time-range $year-$mon-$day from $shh:$smm $smon/$sday/$syear to $hh:$mm $mon/$day/$year ";
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return "$year-$mon-$day";

}

sub getPolicyName {
  my ( $self, $fromZone, $toZone ) = @_;
  my $zonePair = $self->searcherReportFwInfo->{parser}->{zonePair};
  return $zonePair;
}

sub getAndCreatAclName {
  my $self   = shift;
  my $srcMap = $self->searcherReportFwInfo->srcMap;
  my $dstMap = $self->searcherReportFwInfo->dstMap;
  my $parser = $self->searcherReportFwInfo->parser;
  my $srcSet = Firewall::Utils::Set->new();
  my $dstSet = Firewall::Utils::Set->new();
  for my $address ( keys %{$srcMap} ) {
    my ( $ip, $mask ) = split( '/', $address );
    $srcSet->mergeToSet( Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask ) );
  }
  for my $address ( keys %{$dstMap} ) {
    my ( $ip, $mask ) = split( '/', $address );
    $dstSet->mergeToSet( Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask ) );
  }

  my %flag;
  for my $rule ( values %{$parser->elements->{rule}} ) {
    if ( $rule->ruleType eq 'ACL' and not defined $rule->{fromZone} ) {
      if ( $rule->srcAddressGroup->range->isEqual($srcSet) and $rule->dstAddressGroup->range->isEqual($dstSet) ) {
        return $rule->aclName;

      }
      if ( $rule->aclName =~ /^\d+$/o ) {
        $flag{$rule->aclName} = 1;
      }
    }

  }
  my @commands;
  my $aclName;
  $aclName = sprintf( '%d', 3000 + int( rand(999) ) );
  while ( defined $flag{$aclName} ) {
    $aclName = sprintf( '%d', 3000 + int( rand(999) ) );
  }
  push @commands, "acl advanced $aclName";
  for my $srcaddr ( keys %{$srcMap} ) {
    for my $dstaddr ( keys %{$dstMap} ) {
      my ( $srcip, $srcmask ) = split( '/', $srcaddr );
      my $srcmaskForm = Firewall::Utils::Ip->new->changeMaskToIpForm($srcmask);
      my $srcwildMask = Firewall::Utils::Ip->new->changeWildcardToMaskForm($srcmaskForm);
      $srcwildMask = 0 if $srcwildMask eq '0.0.0.0';
      my ( $dstip, $dstmask ) = split( '/', $dstaddr );
      my $dstmaskForm = Firewall::Utils::Ip->new->changeMaskToIpForm($dstmask);
      my $dstwildMask = Firewall::Utils::Ip->new->changeWildcardToMaskForm($dstmaskForm);
      $dstwildMask = 0 if $dstwildMask eq '0.0.0.0';
      push @commands, "rule permit ip source $srcip $srcwildMask destination $dstip $dstwildMask";
    }
  }
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return $aclName;

=pod
    my $aclName;
    my @flag;

    for my $rule (values %{$self->searcherReportFwInfo->parser->elements->{rule}}){
        if ($rule->ruleType eq 'ACL'){
            $flag[$rule->aclName] = 1;
        }
    }

    $aclName = sprintf('%d', 100+int(rand(9899)));
    while (defined $flag[$aclName]){
        $aclName = sprintf('%d', 100+int(rand(9899)));
    }
    return $aclName;
=cut

} ## end sub getAndCreatAclName

__PACKAGE__->meta->make_immutable;
1;
