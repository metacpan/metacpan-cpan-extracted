package Firewall::Policy::Designer::Fortinet;

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
  #say dumper $self->searcherReportFwInfo;exit;
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

=pod
    if (@{$self->commandText} >0 ){
        push @{$self->commandText},'save';
    }
=cut

  my $parser = $self->searcherReportFwInfo->{parser};
  if ( defined $parser->{isvdom} and $parser->{isvdom} == 1 ) {
    unshift @{$self->commandText}, "edit $parser->{vdom}";
    unshift @{$self->commandText}, "config vdom";
  }
  push @{$self->commandText}, "end";
  return join( '', map {"$_\n"} @{$self->commandText} );
} ## end sub design

sub createRule {
  my $self   = shift;
  my $action = $self->searcherReportFwInfo->action->{'new'};

  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat($action);

=pod
    my $natString = '';
    $natString .= $nameMap->{natSrc}->[0]->{natStr} if defined $nameMap->{natSrc};
    $natString .= $nameMap->{natDst}->[0]->{natStr} if defined $nameMap->{natDst};
=cut

  my $schedule     = $self->searcherReportFwInfo->{schedule};
  my $scheduleName = 'always';
  $scheduleName = $self->createSchedule($schedule) if $schedule->{enddate} ne 'always';
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my @commands;
  my ( $srcStr, $dstStr, $srvStr, @natStr );

  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      $srcStr = "set srcaddr";
      for my $host ( @{$nameMap->{$type}} ) {
        $srcStr .= qq{ "$host"};
      }

    }
    elsif ( $type eq 'dst' ) {
      $dstStr = "set dstaddr";
      for my $host ( @{$nameMap->{$type}} ) {
        $dstStr .= qq{ "$host"};
      }

    }
    elsif ( $type eq 'srv' ) {
      $srvStr = "set service";
      for my $srv ( @{$nameMap->{$type}} ) {
        $srvStr .= qq{ "$srv"};
      }
    }
    elsif ( $type eq 'natSrc' ) {
      @natStr = @{$nameMap->{$type}};
    }

  } ## end for my $type ( keys %{$nameMap...})

  push @commands, "config firewall policy";
  push @commands, "edit 0";
  push @commands, qq{set srcintf "$fromZone"};
  push @commands, qq{set dstintf "$toZone"};
  push @commands, $srcStr;
  push @commands, $dstStr;
  push @commands, "set action accept";
  push @commands, qq{set schedule "$scheduleName"};
  push @commands, $srvStr;
  push @commands, @natStr if @natStr >= 1;
  push @commands, "next";
  push @commands, "end";

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
  my @commands;
  my @addMemeberCommands;
  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      $self->searcherReportFwInfo->ruleObj->content =~ /^\s*(?<srcStr>set\s+srcaddr.+")\s*$/mi;
      my $srcStr = $+{srcStr};
      for my $host ( @{$nameMap->{$type}} ) {
        $srcStr .= qq{ "$host"};
      }
      push @addMemeberCommands, $srcStr;

    }
    elsif ( $type eq 'dst' ) {
      $self->searcherReportFwInfo->ruleObj->content =~ /^\s*(?<dstStr>set\s+dstaddr.+")\s*$/mi;
      my $dstStr = $+{dstStr};
      for my $host ( @{$nameMap->{$type}} ) {
        $dstStr .= qq{ "$host"};
      }
      push @addMemeberCommands, $dstStr;

    }
    elsif ( $type eq 'srv' ) {
      $self->searcherReportFwInfo->ruleObj->content =~ /^\s*(?<srvStr>set\s+service.+")\s*$/mi;
      my $srvStr = $+{srvStr};
      for my $srv ( @{$nameMap->{$type}} ) {
        $srvStr .= qq{ "$srv"};
      }
      push @addMemeberCommands, $srvStr;

    }

  } ## end for my $type ( keys %{$nameMap...})
  if ( @addMemeberCommands == 0 ) {
    confess("ERROR: 需要增加的成员数量为0，这不可能!!!!!!");
  }

  push @commands, qq{config firewall policy};
  push @commands, qq{edit $policyId};
  push @commands, @addMemeberCommands;
  push @commands, qq{next};
  push @commands, qq{end};

  $self->addToCommandText(@commands);

} ## end sub modifyRule

sub checkAndCreateAddrOrSrvOrNat {
  my ( $self, $param ) = @_;
  my $nameMap;

  #如果要新建静态NAT，则对应ip不需要要建地址，直接使用MIP()形式
  my $requestNat = 0;
  for my $type ( keys %{$param} ) {
    if ( $type eq 'natDst' ) {
      $requestNat = 1;
    }
  }
  for my $type ( keys %{$param} ) {
    if ( $type eq 'natDst' or $type eq 'natSrc' ) {
      $nameMap->{$type} = $self->createNat( $param->{$type}, $type );
    }
    else {
      for my $addrOrSrv ( keys %{$param->{$type}} ) {
        if ( not defined $param->{$type}{$addrOrSrv} ) {
          my $func = "create" . ( ucfirst $type );    #createSrc, createDst, createSrv
          push @{$nameMap->{$type}}, $self->$func( $addrOrSrv, $requestNat );
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
    $natStrs = $self->createDyNat($dyNatInfo);
  }
  return $natStrs;
}

sub createStaticNat {
  my ( $self, $natInfo ) = @_;

=pod
config firewall vip
    edit "58.60.230.8-443"
        set extip 58.60.230.8
        set extintf "vlan-104-telcom"
        set portforward enable
        set mappedip 10.3.76.66
        set extport 443
        set mappedport 443
    next

=cut

  my $natIp         = $natInfo->{natInfo}{natIp};
  my $interfaceName = $natInfo->{natInfo}{interface};
  my @commands;
  push @commands, "config firewall vip";
  push @commands, qq{edit "vip$natIp"};
  push @commands, qq{set extip $natIp};
  push @commands, qq{extintf "$interfaceName"};
  push @commands, qq{set mappedip $natInfo->{realIp}};
  push @commands, "next";
  push @commands, "end";
  $self->addToCommandText(@commands);

}

sub createDyNat {
  my ( $self, $param ) = @_;
  for my $type ( keys %{$param} ) {
    for my $natIps ( values %{$param->{$type}} ) {
      my $natInfo = ( values %{$natIps} )[0]->{natInfo};
      if ( $type eq 'natSrc' ) {

        #not set nat ip default nat interface
        if ( not defined $natInfo->{natIp} ) {
          return ["set nat enable"];
        }
        else {
          my $poolName = $self->getOrCreatePool($natInfo);
          my @commands;
          push @commands, "set nat enable";
          push @commands, "set ippool enable";
          push @commands, qq{set poolname "$poolName"};
          return \@commands;
        }

      }
    } ## end for my $natIps ( values...)
  } ## end for my $type ( keys %{$param...})
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
config firewall ippool
    edit "210.21.236.[133-135]-proxyout"
        set endip 210.21.236.135
        set startip 210.21.236.133
    next
end
=cut

  my @commands;
  my $poolName = "Pool-$natIp";
  push @commands, "config firewall ippool";
  push @commands, qq{edit "$poolName"};
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
  push @commands, "set endip $endIp";
  push @commands, "set startip $startIp";
  push @commands, "next";
  push @commands, "end";
  $self->addToCommandText(@commands);
  return $poolName;

} ## end sub getOrCreatePool

sub createSrc {
  my ( $self, $addr, $requestNat ) = @_;
  return $self->createAddress( $addr, $requestNat );
}

sub createDst {
  my ( $self, $addr, $requestNat ) = @_;
  if ( defined $self->searcherReportFwInfo->action->{'new'} ) {
    my $param = $self->searcherReportFwInfo->action->{'new'};
    for my $type ( keys %{$param} ) {
      if ( $type eq 'natDst' ) {
        for ( keys %{$param->{$type}} ) {
          if ( $addr eq $_ ) {
            return "vip$addr";
          }
        }
      }
    }
  }
  return $self->createAddress( $addr, $requestNat );
}

sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

sub createAddress {
  my ( $self, $addr, $requestNat ) = @_;

=pod
config firewall address
edit "office"
set subnet 192.168.1.0 255.255.255.0
next
end
=cut

  my ( $ip, $mask ) = split( '/', $addr );
  my ( $addressName, $ipString, $ipMin, $ipMax );
  if ( not defined $mask ) {
    if ( $ip =~ /(\d+\.)(\d+\.)(\d+\.)(\d+)-(\d+)/ ) {
      $addressName = "Range_$ip";
      ( $ipMin, $ipMax ) = ( $1 . $2 . $3 . $4, $1 . $2 . $3 . $5 );
    }
  }
  elsif ( $mask == 32 ) {
    $ipString    = $ip;
    $addressName = "$ip/32";
  }
  elsif ( $mask == 0 ) {
    return 'ALL';
  }
  else {
    $ipString    = Firewall::Utils::Ip->new->getNetIpFromIpMask( $ip, $mask );
    $addressName = "$ipString/$mask";
  }
  my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask) if defined $mask;
  my @commands;
  push @commands, "config firewall address";
  push @commands, "edit \"$addressName\"";
  push @commands, "set subnet $ipString $maskString" if defined $mask;
  if ( defined $ipMin ) {
    push @commands, "set type iprange";
    push @commands, "set start-ip $ipMin";
    push @commands, "set end-ip $ipMax";
  }
  push @commands, "next";
  push @commands, "end";
  $self->addToCommandText(@commands);
  return $addressName;
} ## end sub createAddress

sub createService {
  my ( $self,     $srv )  = @_;
  my ( $protocol, $port ) = split( '/', $srv );
  $protocol = lc $protocol;
  return if $protocol ne 'tcp' and $protocol ne 'udp';

=pod
config firewall service custom
edit "QQ"
set protocol TCP/UDP/SCTP
set tcp-portrange 8000
set udp-portrange 4000-8000
next
end
=cut

  my ( $serviceName, $dstPort );
  if ( $protocol eq 'tcp' ) {
    if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
      $serviceName = $+{portMin} . "-" . $+{portMax};
      $dstPort     = $+{portMin} . "-" . $+{portMax};
    }
    elsif ( $port =~ /^\d+$/o ) {
      $serviceName = $port;
      $dstPort     = $port;
    }
    else {
      confess "ERROR: $port is not a port";
    }
  }
  elsif ( $protocol eq 'udp' ) {
    if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
      $serviceName = $+{portMin} . "-" . $+{portMax} . 'u';
      $dstPort     = $+{portMin} . "-" . $+{portMax};
    }
    elsif ( $port =~ /^\d+$/o ) {
      $serviceName = $port . "u";
      $dstPort     = $port;
    }
    else {
      confess "ERROR: $port is not a port";
    }
  }
  my @commands;
  push @commands, "config firewall service custom";
  push @commands, "edit \"$serviceName\"";
  push @commands, "set protocol TCP/UDP/SCTP";
  push @commands, "set $protocol-portrange $dstPort";
  push @commands, "next";
  push @commands, "end";
  $self->addToCommandText(@commands);
  return $serviceName;
} ## end sub createService

sub createSchedule {
  my ( $self, $schedule ) = @_;
  my @commands;
  my ( $syear, $smon, $sday, $shh, $smm ) = split( '[ :-]', $schedule->{startdate} ) if defined $schedule->{startdate};
  my ( $year,  $mon,  $day,  $hh,  $mm )  = split( '[ :-]', $schedule->{enddate} );

  push @commands, "config firewall schedule onetime";
  push @commands, "edit \"$year-$mon-$day\"";
  if ( defined $schedule->{startdate} ) {
    push @commands, "set start $shh:$smm $syear/$smon/$sday";

  }
  push @commands, "set end $hh:$mm $year/$mon/$day";
  push @commands, "next";
  push @commands, "end";
  $self->addToCommandText(@commands);
  return "$year-$mon-$day";

} ## end sub createSchedule

__PACKAGE__->meta->make_immutable;
1;
