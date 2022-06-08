package Firewall::Policy::Designer::Neteye;

#------------------------------------------------------------------------------
# 加载项目模块
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
  if ( @{$self->commandText} > 0 ) {
    unshift @{$self->commandText}, 'configure mode';
    push @{$self->commandText}, 'save config';
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
  my $randNum  = sprintf( '%05d', int( rand(99999) ) );
  my $ruleName = 'p_' . Firewall::Utils::Date->new->getFormatedDate('yyyymmdd_hhmiss') . "_$randNum";
  push @commands,
      "policy access $ruleName $fromZone object "
    . ( shift @{$nameMap->{src}} )
    . " $toZone object "
    . ( shift @{$nameMap->{dst}} )
    . " protocol-object "
    . ( shift @{$nameMap->{srv}} )
    . " permit enable";

  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "policy access $ruleName sourceip object $host";
      }

    }
    elsif ( $type eq 'dst' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "policy access $ruleName desip object $host";
      }

    }
    elsif ( $type eq 'srv' ) {
      for my $srv ( @{$nameMap->{$type}} ) {
        push @commands, "policy access $ruleName protocol protocol-object $srv";
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
  my @commands;
  for my $type ( keys %{$nameMap} ) {
    if ( $type eq 'src' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "policy access $policyId sourceip object $host";
      }

    }
    elsif ( $type eq 'dst' ) {
      for my $host ( @{$nameMap->{$type}} ) {
        push @commands, "policy access $policyId desip object $host";
      }

    }
    elsif ( $type eq 'srv' ) {
      for my $srv ( @{$nameMap->{$type}} ) {
        push @commands, "policy access $policyId protocol protocol-object $srv";
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
policy mip policy_name before_trans_ipaddress after_trans_ipaddress
=cut

  my $natIp   = $natInfo->{natInfo}{natIp};
  my $natName = "nat_" . $natIp;
  my @commands;
  push @commands, "policy mip $natName $natInfo->{realIp} $natIp enable";
  $self->addToCommandText(@commands);

}

sub createDyNat {
  my ( $self, $param ) = @_;
  my @commands;
  for my $type ( keys %{$param} ) {
    for my $natIps ( values %{$param->{$type}} ) {
      my $natInfo   = ( values %{$natIps} )[0]->{natInfo};
      my $interface = $natInfo->{interface};
      if ( $type eq 'natSrc' ) {

        #not set nat ip default nat interface
        if ( not defined $natInfo->{natIp} ) {
          my $iplist   = "";
          my $poliName = sprintf( '%d', 100 + int( rand(9899) ) );
          for my $natIp ( keys %{$natIps} ) {
            my ( $ip, $mask ) = split($natIp);
            $mask = 32 if not defined $mask;
            if ( $mask == 32 ) {
              $iplist .= "," . $ip;
            }
            else {
              my ( $min, $max ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
              my $ipRange
                = Firewall::Utils::Ip->new->changeIntToIp($min) . "-" . Firewall::Utils::Ip->new->changeIntToIp($max);
              $iplist .= "," . $ipRange;
            }

          }
          $iplist =~ s/^,//;
          push @commands, "policy snat_$poliName iplist $iplist interface $interface";

        }
        else {
          my $iplist = "";
          my $nat    = $natInfo->{natIp};
          my ( $natIp, $natMask ) = split( '/', $nat );
          $natMask = 32 if not defined $natMask;
          my $poliName = sprintf( '%d', 100 + int( rand(9899) ) );
          my $natIpList;
          if ( $natMask == 32 ) {
            $natIpList = $natIp;
          }
          else {
            my ( $min, $max ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, $natMask );
            my $ipRange
              = Firewall::Utils::Ip->new->changeIntToIp($min) . "-" . Firewall::Utils::Ip->new->changeIntToIp($max);
            $natIpList = $ipRange;
          }
          for my $natIp ( keys %{$natIps} ) {
            my ( $ip, $mask ) = split($natIp);
            $mask = 32 if not defined $mask;
            if ( $mask == 32 ) {
              $iplist .= "," . $ip;
            }
            else {
              my ( $min, $max ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
              my $ipRange
                = Firewall::Utils::Ip->new->changeIntToIp($min) . "-" . Firewall::Utils::Ip->new->changeIntToIp($max);
              $iplist .= "," . $ipRange;
            }
          }
          push @commands, "policy snat_$poliName iplist $iplist iplist $natIpList";
        } ## end else [ if ( not defined $natInfo...)]

      }
      elsif ( $type eq 'natDst' ) {
        my $poliName = sprintf( '%d', 100 + int( rand(9899) ) );

        for my $natIp ( keys %{$natIps} ) {
          my $nat = $natInfo->{natIp};
          push @commands, "policy dnat_$poliName $nat $natIp enable";
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
  return $self->createAddress($addr);
}

sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

sub createAddress {
  my ( $self, $addr ) = @_;

=pod
 object ipaddr acs_app 172.30.202.80
 object ipaddr ap_ip 172.18.113.100-172.18.113.102
 object ipaddr chaowang subnet 172.30.202.38 255.255.255.255
=cut

  my ( $ip,          $mask ) = split( '/', $addr );
  my ( $addressName, $ipString );
  if ( not defined $mask ) {
    if ( $ip =~ /(\d+\.)(\d+\.)(\d+\.)(\d+)-(\d+)/ ) {
      $addressName = "range_$ip";
      $ipString    = $ip;
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
    my $netIp = Firewall::Utils::Ip->new->getNetIpFromIpMask( $ip, $mask );
    $addressName = "Net_$netIp/$mask";
    my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
    $ipString = "subnet $netIp $maskString";
  }
  my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
  my @commands;
  push @commands, "object ipaddr $addressName $ipString";
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
 object service DNS udp 1-65535 53
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
  push @commands, "object service $serviceName $protocol 1-65535 $dstPort";
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
