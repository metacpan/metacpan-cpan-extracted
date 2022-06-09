package Firewall::Policy::Designer::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::Policy::Searcher::Report::FwInfo;

has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', required => 1, );

has searcherReportFwInfo => ( is => 'ro', isa => 'Firewall::Policy::Searcher::Report::FwInfo', required => 1, );

has commandText => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] }, );

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
    unshift @{$self->commandText}, 'configure mode';
    push @{$self->commandText}, 'save';
  }
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

  my $scheduleName;
  my $schedule = $self->searcherReportFwInfo->{schedule};
  $scheduleName = $self->createSchedule($schedule) if $schedule->{enddate} ne 'always';
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my @commands;
  push @commands, "rule top";
  push @commands, "action permit";
  push @commands, qq{src-zone "$fromZone"};
  push @commands, qq{dst-zone "$toZone"};

  for my $type ( keys %{$nameMap} ) {

    if ( $type eq 'src' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, qq{src-addr "$host"};
      }

    }
    elsif ( $type eq 'dst' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, qq{dst-addr "$host"};
      }

    }
    elsif ( $type eq 'srv' ) {
      for my $srv ( @{$nameMap->{$type}} ) {
        push @commands, qq{service "$srv"};
      }
    }

  } ## end for my $type ( keys %{$nameMap...})
  push @commands, qq{schedule "$scheduleName"} if defined $scheduleName;
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
  my @commands;
  push @commands, "rule $policyId";
  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, qq{src-addr "$host"};
      }

    }
    elsif ( $type eq 'dst' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, qq{dst-addr "$host"};
      }

    }
    elsif ( $type eq 'srv' ) {
      for my $srv ( @{$nameMap->{$type}} ) {
        push @commands, qq{service "$srv"};
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
bnatrule id 1 virtual ip 10.1.1.2/32 real ip 192.168.20.2/32
=cut

  my $natIp = $natInfo->{natInfo}{natIp};
  my @commands;
  push @commands, "nat";
  push @commands, "bnatrule virtual ip $natIp real ip $natInfo->{realIp}";
  push @commands, "exit";
  $self->addToCommandText(@commands);

}

sub createDyNat {
  my ( $self, $param ) = @_;
  my @commands;
  for my $type ( keys %{$param} ) {
    for my $natIps ( values %{$param->{$type}} ) {
      my $natInfo = ( values %{$natIps} )[0]->{natInfo};
      if ( $type eq 'natSrc' ) {

        #not set nat ip default nat interface
        if ( not defined $natInfo->{natIp} ) {
          push @commands, "nat";
          for my $natIp ( keys %{$natIps} ) {
            push @commands, qq{snatrule from "$natIp" to "Any" service "Any" trans-to eif-ip mode dynamicport};
          }
        }
        else {
          push @commands, "nat";
          for my $natIp ( keys %{$natIps} ) {
            my $nat = $natInfo->{natIp};
            push @commands, qq{snatrule from "$natIp" to "Any" service "Any" trans-to $nat mode dynamicport};
          }

        }

      }
      elsif ( $type eq 'natDst' ) {
        push @commands, "nat";
        for my $natIp ( keys %{$natIps} ) {
          my $nat = $natInfo->{natIp};
          push @commands, qq{dnatrule from "Any" to "$nat" service "Any" trans-to "$natIp"};
        }

      }
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
  my ( $self, $addr ) = @_;
  return $self->createAddress($addr);
}

sub createDst {
  my ( $self, $addr ) = @_;
  if ( defined $self->searcherReportFwInfo->action->{'new'} ) {
    my $param = $self->searcherReportFwInfo->action->{'new'};
    for my $type ( keys %{$param} ) {
      if ( $type eq 'natDst' ) {
        for ( keys %{$param->{$type}} ) {
          if ( $addr eq $_ ) {
            return "vip_$addr";
          }
        }
      }
    }
  }
  return $self->createAddress($addr);
}

sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

sub createAddress {
  my ( $self, $addr ) = @_;

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
    $addressName = "Host_$ip";
  }
  elsif ( $mask == 0 ) {
    return 'any';
  }
  else {
    $ipString    = Firewall::Utils::Ip->new->getNetIpFromIpMask( $ip, $mask );
    $addressName = "Net_$ipString/$mask";
  }
  my @commands;
  push @commands, qq{address "$addressName"};
  push @commands, "ip $ipString/$mask"  if defined $mask;
  push @commands, "range $ipMin $ipMax" if defined $ipMin;
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
config firewall service custom
edit "QQ"
set protocol TCP/UDP/SCTP
set tcp-portrange 8000
set udp-portrange 4000-8000
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
  if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
    $serviceName = uc($protocol) . "_" . $+{portMin} . "_" . $+{portMax};
    $dstPort     = $+{portMin} . "-" . $+{portMax};
  }
  elsif ( $port =~ /^\d+$/o ) {
    $serviceName = uc($protocol) . "_" . $port;
    $dstPort     = $port;
  }
  else {
    confess "ERROR: $port is not a port";
  }

  my @commands;
  push @commands, "service \"$serviceName\"";
  push @commands, "$protocol dst-port  $dstPort";
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return $serviceName;
} ## end sub createService

sub createSchedule {
  my ( $self, $schedule ) = @_;
  my @commands;
  my ( $syear, $smon, $sday, $shh, $smm ) = split( '[ :-]', $schedule->{startdate} ) if defined $schedule->{startdate};
  my ( $year,  $mon,  $day,  $hh,  $mm )  = split( '[ :-]', $schedule->{enddate} );

  push @commands, "schedule \"$year-$mon-$day\"";
  if ( defined $schedule->{startdate} ) {
    push @commands, "absolute start $smon/$sday/$syear $shh:$smm end $mon/$day/$year $hh:$mm";

  }
  else {
    push @commands, "absolute end $mon/$day/$year $hh:$mm";
  }
  push @commands, "exit";
  $self->addToCommandText(@commands);
  return "$year-$mon-$day";
} ## end sub createSchedule

__PACKAGE__->meta->make_immutable;
1;

