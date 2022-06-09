package Firewall::Policy::Designer::Netscreen;

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

has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', required => 1, );

has searcherReportFwInfo => ( is => 'ro', isa => 'Firewall::Policy::Searcher::Report::FwInfo', required => 1, );

has commandText => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] }, );

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
    push @{$self->commandText}, 'save';
  }
  return join( '', map {"$_\n"} @{$self->commandText} );
} ## end sub design

sub createRule {
  my $self = shift;

  #先检查涉及到的 addr or srv 在防火墙上有没有已经存在的名字，没有就需要创建
  my $action       = $self->searcherReportFwInfo->action->{'new'};
  my $schedule     = $self->searcherReportFwInfo->{schedule};
  my $scheduleStr  = '';
  my $scheduleName = $self->createSchedule($schedule) if $schedule->{enddate} ne 'always';
  $scheduleStr = " schedule \"$scheduleName\"" if defined $scheduleName;
  my $nameMap   = $self->checkAndCreateAddrOrSrvOrNat($action);
  my $natString = '';

  #实际可能有多组NAT,先考虑只有一组的情况
  $natString .= $nameMap->{natSrc}->[0]->{natStr} if defined $nameMap->{natSrc};
  $natString .= $nameMap->{natDst}->[0]->{natStr} if defined $nameMap->{natDst};

  #say dumper $nameMap;exit;

=example
set policy top from "V1-Untrust" to "V1-Trust"  "Host_10.31.180.11" "Host_10.31.92.22" "TCP_43477" permit log
set policy id XXX
set src-address "Host_10.8.37.27"
set src-address "Host_10.8.37.28"
set dst-address "Host_10.31.103.203"
set dst-address "Host_10.31.103.204"
set service "TCP_30379"
set service "UDP_30379"
exit
=cut

  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my @commands;

  push @commands,
      qq{set policy top from "$fromZone" to "$toZone" "}
    . ( shift @{$nameMap->{src}} ) . qq{" "}
    . ( shift @{$nameMap->{dst}} ) . qq{" "}
    . ( shift @{$nameMap->{srv}} ) . qq{" }
    . $natString
    . qq{ permit}
    . $scheduleStr;

  my @addMemeberCommands;
  for my $type ( keys %{$nameMap} ) {
    push @addMemeberCommands, map {qq{set src-address "$_"}} @{$nameMap->{$type}} if $type eq 'src';
    push @addMemeberCommands, map {qq{set dst-address "$_"}} @{$nameMap->{$type}} if $type eq 'dst';
    push @addMemeberCommands, map {qq{set service "$_"}} @{$nameMap->{$type}}     if $type eq 'srv';
  }
  if ( @addMemeberCommands != 0 ) {
    push @commands, qq{set policy id XXXXXX};
    push @commands, @addMemeberCommands;
    push @commands, qq{exit};
  }

  $self->addToCommandText(@commands);
} ## end sub createRule

sub modifyRule {
  my $self = shift;

  #先检查涉及到的 addr or srv 在防火墙上有没有已经存在的名字，没有就需要创建
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
    push @addMemeberCommands, map {qq{set src-address "$_"}} @{$nameMap->{$type}} if $type eq 'src';
    push @addMemeberCommands, map {qq{set dst-address "$_"}} @{$nameMap->{$type}} if $type eq 'dst';
    push @addMemeberCommands, map {qq{set service "$_"}} @{$nameMap->{$type}}     if $type eq 'srv';
  }
  if ( @addMemeberCommands == 0 ) {
    confess("ERROR: 需要增加的成员数量为0，这不可能!!!!!!");
  }

  push @commands, qq{set policy id $policyId};
  push @commands, @addMemeberCommands;
  push @commands, qq{exit};

  $self->addToCommandText(@commands);

} ## end sub modifyRule

sub checkAndCreateAddrOrSrvOrNat {
  my ( $self, $param ) = @_;
  my $nameMap;

  #如果要新建静态NAT，则对应ip不需要要建地址，直接使用MIP()形式
  my $requestNat = 0;
  for my $type ( keys %{$param} ) {
    if ( $type eq 'natDst' or $type eq 'natSrc' ) {
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

  #set interface "ethernet0/0" mip 10.37.175.74 host 192.168.188.238 netmask 255.255.255.255
  my $interface = $natInfo->{natInfo}{interface};
  my ( $natIp, undef ) = split( '/', $natInfo->{natInfo}{natIp} );
  my ( $realIp, $mask ) = split( '/', $natInfo->{realIp} );
  my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
  my @commands;
  push @commands, "set interface $interface mip $natIp host $realIp netmask $maskString";
  $self->addToCommandText(@commands);

}

sub createDyNat {
  my ( $self, $param ) = @_;
  my @natStrs;
  for my $type ( keys %{$param} ) {
    for my $natIps ( values %{$param->{$type}} ) {
      my ( $natDirection, $poolName, $natInfo );
      my @ips;
      $natInfo = ( values %{$natIps} )[0]->{natInfo};
      if ( $type eq 'natSrc' ) {

        #$natDirection = ' nat src dip-id';
        $natDirection = ' nat src ';
        $poolName     = $self->getOrCreatePool($natInfo);
        @ips          = keys %{$natIps};
      }
      else {
        $natDirection = ' nat dst ip' if $type eq 'natDst';
        $poolName     = ( split( '/', ( keys %{$natIps} )[0] ) )[0];
        push @ips, $natInfo->{natIp};
      }
      push @natStrs, {natStr => "$natDirection $poolName", ips => \@ips};
    } ## end for my $natIps ( values...)
  } ## end for my $type ( keys %{$param...})
  return \@natStrs;
} ## end sub createDyNat

sub getOrCreatePool {
  my ( $self, $natInfo ) = @_;
  my @commands;
  if ( not defined $natInfo->{natIp} ) {
    return "";
  }
  my $natIp         = $natInfo->{natIp};
  my $interfaceName = $natInfo->{interface};
  my ( $ip, $mask ) = split( '/', $natIp );
  my $interface = $self->searcherReportFwInfo->parser->getInterface($interfaceName);
  if ( $interface->ipAddress eq $ip ) {
    return "";
  }
  $mask = 32 if not defined $mask;
  my $natPoolSet = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  for my $natPool ( values %{$self->searcherReportFwInfo->parser->elements->natPool} ) {
    if ( $natPool->interfaceName eq $interfaceName and $natPool->poolRange->isEqual($natPoolSet) ) {
      return "dip-id " . $natPool->poolName;
    }
  }
  my $randNum = sprintf( '%d', 4 + int( rand(1019) ) );
  while ( defined $self->searcherReportFwInfo->parser->getNatPool($randNum) ) {
    $randNum = sprintf( '%d', 4 + int( rand(1019) ) );
  }
  my $ipmin    = Firewall::Utils::Ip->new->changeIntToIp( $natPoolSet->mins->[0] );
  my $ipmax    = Firewall::Utils::Ip->new->changeIntToIp( $natPoolSet->maxs->[0] );
  my $maskStr  = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
  my $intRange = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, $interface->mask );
  if ( $intRange->isContain($natPoolSet) ) {
    push @commands, "set interface $interfaceName dip $randNum $ipmin $ipmax";
  }
  else {
    push @commands, "set interface $interfaceName ext ip $ipmin $maskStr dip $randNum $ipmin $ipmax";
  }
  $self->addToCommandText(@commands);
  return "dip-id " . $randNum;
} ## end sub getOrCreatePool

sub createSrc {
  my ( $self, $addr, $requestNat ) = @_;
  return $self->createAddress( $self->searcherReportFwInfo->fromZone, $addr, $requestNat );
}

sub createDst {
  my ( $self, $addr, $requestNat ) = @_;
  return $self->createAddress( $self->searcherReportFwInfo->toZone, $addr, $requestNat );
}

sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

sub createAddress {
  my ( $self, $zoneName, $addr, $requestNat ) = @_;

  #set address "V1-Untrust" "Host_172.18.254.4" 172.18.254.4 255.255.255.255
  my ( $ip, $mask ) = split( '/', $addr );
  return 'any' if $ip =~ /any/i;
  $mask = 32   if not defined $mask;
  my ( $addressName, $ipString );
  if ( $zoneName ne 'Global' ) {
    if ( $mask == 32 ) {
      $ipString    = $ip;
      $addressName = "$ip/32";
    }
    elsif ( $mask == 0 ) {
      return 'any';

    }
    else {
      $ipString    = Firewall::Utils::Ip->new->getNetIpFromIpMask( $ip, $mask );
      $addressName = "$ipString/$mask";
    }
    my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
    my $command    = qq{set address "$zoneName" "$addressName" $ipString $maskString};
    $self->addToCommandText($command);
  }
  else {
    if ( $mask == 32 ) {
      my $addr = $self->searcherReportFwInfo->parser->getAddress( 'Global', "MIP($ip)" );
      if ( defined $addr or $requestNat ) {
        $addressName = "MIP($ip)";
      }
      else {
        $addressName = "$ip/32";
        my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
        my $command    = qq{set address "$zoneName" "$addressName" $ip $maskString};
        $self->addToCommandText($command);
      }
    }
    else {
      my $addr = $self->searcherReportFwInfo->parser->getAddress( 'Global', "MIP($ip/$mask)" );
      if ( defined $addr ) {
        $addressName = "MIP($ip/$mask)";
      }
      else {
        $ipString    = Firewall::Utils::Ip->new->getNetIpFromIpMask( $ip, $mask );
        $addressName = "$ipString/$mask";
        my $maskString = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
        my $command    = qq{set address "$zoneName" "$addressName" $ipString $maskString};
        $self->addToCommandText($command);
      }
    }

  } ## end else [ if ( $zoneName ne 'Global')]
  return $addressName;
} ## end sub createAddress

sub createService {
  my ( $self, $srv ) = @_;

  #set service "TCP-42282" protocol tcp src-port 0-65535 dst-port 42282-42282
  my ( $protocol, $port ) = split( '/', $srv );
  $protocol = lc $protocol;
  return if $protocol ne 'tcp' and $protocol ne 'udp';

  my ( $serviceName, $dstPort );
  if ( $protocol eq 'tcp' ) {
    if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
      $serviceName = $+{portMin} . "-" . $+{portMax};
      $dstPort     = $+{portMin} . "-" . $+{portMax};
    }
    elsif ( $port =~ /^\d+$/o ) {
      $serviceName = $port;
      $dstPort     = $port . "-" . $port;
    }
    else {
      confess "ERROR: $port is not a port";
    }
  }
  elsif ( $protocol eq 'udp' ) {
    if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
      $serviceName = $+{portMin} . "-" . $+{portMax} . "u";
      $dstPort     = $+{portMin} . "-" . $+{portMax};
    }
    elsif ( $port =~ /^\d+$/o ) {
      $serviceName = $port . "u";
      $dstPort     = $port . "-" . $port;
    }
    else {
      confess "ERROR: $port is not a port";
    }

  }
  my $command = qq{set service "$serviceName" protocol $protocol src-port 0-65535 dst-port $dstPort};
  $self->addToCommandText($command);
  return $serviceName;
} ## end sub createService

sub createSchedule {
  my ( $self, $schedule ) = @_;

  #set scheduler "2016-01-01" once start 1/1/2014 0:0 stop 1/5/2016 14:0

  my ( $syear, $smon, $sday, $shh, $smm ) = split( '[ :-]', $schedule->{startdate} ) if defined $schedule->{startdate};
  if ( not defined $schedule->{startdate} ) {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime( time() );
    $syear = $year + 1900;
    $smon  = $mon + 1;
    $sday  = $mday;
    $shh   = $hour;
    $smm   = $min;
  }
  my ( $year, $mon, $day, $hh, $mm ) = split( '[ :-]', $schedule->{enddate} );
  my $schName = "$year-$mon-$day";
  my $command = qq{set scheduler "$schName" once start $smon/$sday/$syear $shh:$smm stop $mon/$day/$year $hh:$mm};
  $self->addToCommandText($command);
  return $schName;

} ## end sub createSchedule

__PACKAGE__->meta->make_immutable;
1;
