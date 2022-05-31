package Firewall::Policy::Designer::Srx;

use Carp;
use Moose;
use namespace::autoclean;

use Firewall::Utils::Date;
use Firewall::Policy::Searcher::Report::FwInfo;
use Mojo::Util qw(dumper);

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
    $self->modifyRule;
  }
  elsif ( $self->searcherReportFwInfo->type eq 'ignore' ) {
    if ( defined $self->searcherReportFwInfo->action ) {
      my $param = $self->searcherReportFwInfo->action->{'new'};
      for my $type ( keys %{$param} ) {
        if ( $type eq 'natDst' or $type eq 'natSrc' ) {
          $self->createNat( $param->{$type} );
        }
      }
    }
  }
  else {
    confess( "ERROR: searcherReportFwInfo->type(" . $self->searcherReportFwInfo->type . ") must be 'new' or 'modify'" );
  }
  if ( @{$self->commandText} > 0 ) {
    push @{$self->commandText}, 'commit check';
    push @{$self->commandText}, 'commit';
  }
  return join( '', map {"$_\n"} @{$self->commandText} );
} ## end sub design

sub createRule {
  my $self = shift;

  #先检查涉及到的 addr or srv 在防火墙上有没有已经存在的名字，没有就需要创建
  my $action  = $self->searcherReportFwInfo->action;
  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat( $action->{'new'} );

=example
set security policies from-zone l2-untrust to-zone l2-trust policy p409 match source-address host_10.39.100.252
set security policies from-zone l2-untrust to-zone l2-trust policy p409 match destination-address host_10.44.96.12
set security policies from-zone l2-untrust to-zone l2-trust policy p409 match application tcp_44441-44444
set security policies from-zone l2-untrust to-zone l2-trust policy p409 then permit

=cut

  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my @commands;
  my $randNum  = $$ || sprintf( '%05d', int( rand(99999) ) );
  my $ruleName = 'p_' . Firewall::Utils::Date->new->getFormatedDate('yyyymmdd_hhmiss') . "_$randNum";
  for my $type ( keys %{$nameMap} ) {
    push @commands,
      map {"set security policies from-zone $fromZone to-zone $toZone policy $ruleName match source-address $_"}
      @{$nameMap->{$type}}
      if $type eq 'src';
    push @commands,
      map {"set security policies from-zone $fromZone to-zone $toZone policy $ruleName match destination-address $_"}
      @{$nameMap->{$type}}
      if $type eq 'dst';
    push @commands,
      map {"set security policies from-zone $fromZone to-zone $toZone policy $ruleName match application $_"}
      @{$nameMap->{$type}}
      if $type eq 'srv';
  }
  push @commands, "set security policies from-zone $fromZone to-zone $toZone policy $ruleName then permit";
  $self->addToCommandText(@commands);
} ## end sub createRule

sub modifyRule {
  my $self = shift;

  #先检查涉及到的 addr or srv 在防火墙上有没有已经存在的名字，没有就需要创建
  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat( $self->searcherReportFwInfo->action->{'add'} );
  if ( $self->searcherReportFwInfo->action->{'new'} ) {
    $self->checkAndCreateAddrOrSrvOrNat( $self->searcherReportFwInfo->action->{'new'} );
  }
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my $ruleName = $self->searcherReportFwInfo->ruleObj->ruleName;

  my @commands;
  for my $type ( keys %{$nameMap} ) {
    push @commands,
      map {"set security policies from-zone $fromZone to-zone $toZone policy $ruleName match source-address $_"}
      @{$nameMap->{$type}}
      if $type eq 'src';
    push @commands,
      map {"set security policies from-zone $fromZone to-zone $toZone policy $ruleName match destination-address $_"}
      @{$nameMap->{$type}}
      if $type eq 'dst';
    push @commands,
      map {"set security policies from-zone $fromZone to-zone $toZone policy $ruleName match application $_"}
      @{$nameMap->{$type}}
      if $type eq 'srv';
  }

  $self->addToCommandText(@commands);

} ## end sub modifyRule

sub checkAndCreateAddrOrSrvOrNat {
  my ( $self, $param ) = @_;
  my $nameMap;
  for my $type ( keys %{$param} ) {
    if ( $type eq 'natDst' or $type eq 'natSrc' ) {
      $self->createNat( $param->{$type}, $type );
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

  #set security nat static rule-set dmz_static_nat rule host_172_29_16_1 match destination-address 172.29.16.1/32
  #set security nat static rule-set dmz_static_nat rule host_172_29_16_1 then static-nat prefix 10.11.100.97/32

  my $natName = 'host_' . join( '_', ( split( /[\.\/]/, $natInfo->{natInfo}{natIp} ) )[ 0, 1, 2, 3 ] );
  my @commands;
  my $realIp  = $natInfo->{realIp};
  my $ruleSet = $natInfo->{ruleSet};
  my $natIp   = $natInfo->{natInfo}{natIp};
  if ( defined $ruleSet ) {
    push @commands, "set security nat static rule-set $ruleSet rule $natName match destination-address $natIp";
    push @commands, "set security nat static rule-set $ruleSet rule $natName then static-nat prefix $realIp";
    $self->addToCommandText(@commands);
  }
  else {
    push @commands, "set security nat static rule-set static-nat rule $natName match destination-address $natIp";
    push @commands, "set security nat static rule-set static-nat rule $natName then static-nat prefix $realIp";
    $self->addToCommandText(@commands);
  }
} ## end sub createStaticNat

=example
set security nat source pool srcnat_pool_3 address 202.69.21.46/32 to 202.69.21.46/32
set security nat source rule-set dmz_untrust from zone dmz
set security nat source rule-set dmz_untrust to zone untrust
set security nat source rule-set dmz_untrust rule rule21 match source-address 172.28.40.47/32
set security nat source rule-set dmz_untrust rule rule21 match source-address 172.28.40.181/32
set security nat source rule-set dmz_untrust rule rule21 match destination-address 220.196.52.117/32
set security nat source rule-set dmz_untrust rule rule21 then source-nat pool srcnat_pool_3

set security nat destination pool dstnat_pool_10 address 172.28.40.47/32
set security nat destination pool dstnat_pool_23 address 172.28.32.75/32
set security nat destination pool dstnat_pool_23 address port 80

set security nat destination rule-set untrust_dmz from zone untrust
set security nat destination rule-set untrust_dmz rule rule22 match source-address 220.196.52.117/32
set security nat destination rule-set untrust_dmz rule rule22 match destination-address 202.69.21.46/32
set security nat destination rule-set untrust_dmz rule rule22 match destination-port 8807
set security nat destination rule-set untrust_dmz rule rule22 then destination-nat pool dstnat_pool_10

set security nat destination rule-set untrust_dmz rule rule23 match destination-address 202.69.21.114/32
set security nat destination rule-set untrust_dmz rule rule23 match destination-port 80
set security nat destination rule-set untrust_dmz rule rule23 then destination-nat pool dstnat_pool_23
=cut

sub createDyNat {
  my ( $self, $param ) = @_;
  my @commands;
  my ( $fromZone, $toZone ) = ( $self->searcherReportFwInfo->fromZone, $self->searcherReportFwInfo->toZone );
  my $srvMap = $self->searcherReportFwInfo->srvMap;
  for my $type ( keys %{$param} ) {
    for my $natIps ( values %{$param->{$type}} ) {
      my ( $natDirection, $ruleSet, $ruleName, $poolName, $natInfo );
      $natDirection = 'source'      if $type eq 'natSrc';
      $natDirection = 'destination' if $type eq 'natDst';
      $natInfo      = ( values %{$natIps} )[0]->{natInfo};
      $ruleSet      = ( values %{$natIps} )[0]->{ruleSet};
      my $randNum = sprintf( '%05d', int( rand(99999) ) );
      $ruleName = "rule_$randNum";
      if ( not defined $ruleSet ) {
        $ruleSet = $fromZone . '_' . $toZone;
        push @commands, "set security nat $natDirection rule-set $ruleSet from zone $fromZone";
        push @commands, "set security nat $natDirection rule-set $ruleSet to zone $toZone";

      }
      else {
        while ( defined $self->searcherReportFwInfo->parser->getDynamicNat( $ruleSet, $ruleName ) ) {
          $randNum  = sprintf( '%05d', int( rand(99999) ) );
          $ruleName = "rule_$randNum";
        }
      }

      if ( $type eq 'natSrc' ) {
        $poolName = $self->getOrCreatePool( $type, $natIps );
        for my $natIp ( keys %{$natIps} ) {
          push @commands, "set security nat source rule-set $ruleSet rule $ruleName match source-address $natIp";

        }
        if ( defined $natInfo->{natOption} and $natInfo->{natOption} =~ /d/ ) {
          for my $dstIp ( keys %{$self->searcherReportFwInfo->dstMap} ) {
            push @commands, "set security nat source rule-set $ruleSet rule $ruleName match destination-address $dstIp"
              if $dstIp ne '0.0.0.0/0';
          }
        }
        push @commands, "set security nat source rule-set $ruleSet rule $ruleName then source-nat $poolName";
      }
      elsif ( $type eq 'natDst' ) {

        #需要做端口NAT，可能存在多端口情况，每个端口都需要一套NAT策略
        if ( defined $natInfo->{natOption} and $natInfo->{natOption} =~ /p/ ) {
          for my $portInfo ( values %{$self->searcherReportFwInfo->srvMap} ) {
            $poolName = $self->getOrCreatePool( $type, $natIps, $portInfo );
            $randNum  = sprintf( '%05d', int( rand(99999) ) );
            $ruleName = "rule_$randNum";
            while ( defined $self->searcherReportFwInfo->parser->getDynamicNat( $ruleSet, $ruleName ) ) {
              $randNum  = sprintf( '%05d', int( rand(99999) ) );
              $ruleName = "rule_$randNum";
            }

            if ( defined $natInfo->{natOption} and $natInfo->{natOption} =~ /s/ ) {
              for my $srcIp ( keys %{$self->searcherReportFwInfo->srcMap} ) {
                push @commands,
                  "set security nat destination rule-set $ruleSet rule $ruleName match source-address $srcIp"
                  if $srcIp ne '0.0.0.0/0';
              }
            }
            push @commands,
              "set security nat destination rule-set $ruleSet rule $ruleName match destination-address $natInfo->{natIp}";
            my $natPort = $portInfo->{origin};
            $natPort = $portInfo->{natPort} if defined $portInfo->{natPort};
            my ( $pro, $port ) = split( '/', $natPort );
            push @commands,
              "set security nat destination rule-set $ruleSet rule $ruleName match destination-port $port";
            push @commands,
              "set security nat destination rule-set $ruleSet rule $ruleName then destination-nat $poolName";
          } ## end for my $portInfo ( values...)
        }
        else {
          $poolName = $self->getOrCreatePool( $type, $natIps );
          $randNum  = sprintf( '%05d', int( rand(99999) ) );
          $ruleName = "rule_$randNum";
          while ( defined $self->searcherReportFwInfo->parser->getDynamicNat( $ruleSet, $ruleName ) ) {
            $randNum  = sprintf( '%05d', int( rand(99999) ) );
            $ruleName = "rule_$randNum";
          }

          if ( defined $natInfo->{natOption} and $natInfo->{natOption} =~ /s/ ) {
            for my $srcIp ( keys %{$self->searcherReportFwInfo->srcMap} ) {
              push @commands,
                "set security nat destination rule-set $ruleSet rule $ruleName match source-address $srcIp"
                if $srcIp ne '0.0.0.0/0';
            }
          }
          push @commands,
            "set security nat destination rule-set $ruleSet rule $ruleName match destination-address $natInfo->{natIp}";
          push @commands,
            "set security nat destination rule-set $ruleSet rule $ruleName then destination-nat $poolName";

        } ## end else [ if ( defined $natInfo->...)]

      } ## end elsif ( $type eq 'natDst')

    } ## end for my $natIps ( values...)
  } ## end for my $type ( keys %{$param...})
  $self->addToCommandText(@commands) if @commands != 0;

} ## end sub createDyNat

sub getOrCreatePool {
  my ( $self, $type, $natIps, $portInfo ) = @_;
  my $poolName;
  my $natInfo = ( values %{$natIps} )[0]->{natInfo};
  my $poolIp;
  if ( $type eq 'natSrc' ) {
    if ( defined $natInfo->{natIp} ) {
      $poolIp = $natInfo->{natIp};
    }
    else {
      return "interface";
    }

  }
  $poolIp = $natInfo->{natIp} if $type eq 'natSrc';
  my $natPools = $self->searcherReportFwInfo->parser->elements->natPool;

  #say dumper $self->searcherReportFwInfo->srvMap;exit;
  $poolIp = $natInfo->{natIp}                  if $type eq 'natSrc';
  $poolIp = ( values %{$natIps} )[0]->{realIp} if $type eq 'natDst';
  $poolIp =~ s/$/\/32/ if $poolIp !~ /\//;
  my ( $ip, $mask ) = split( '/', $poolIp );
  my $poolRange = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  my @commands;
  if ( $type eq 'natSrc' ) {

    for my $pool ( values %{$natPools} ) {
      if ( $pool->natDirection eq 'source' and $pool->poolRange->isEqual($poolRange) ) {
        return "pool " . $pool->poolName;
      }
    }

    #没找到已有pool,新建
    # set security nat source pool srcnat_pool_3 address 202.69.21.46/32 to 202.69.21.46/32
    my $randNum = sprintf( '%05d', int( rand(99999) ) );
    $poolName = "srcnat_pool_$randNum";
    while ( defined $self->searcherReportFwInfo->parser->getNatPool($poolName) ) {
      $randNum  = sprintf( '%05d', int( rand(99999) ) );
      $poolName = "srcnat_pool_$randNum";
    }
    push @commands, "set security nat source pool $poolName address $poolIp to $poolIp";

  }
  elsif ( $type eq 'natDst' ) {
    for my $pool ( values %{$natPools} ) {
      if ( $pool->natDirection eq 'destination' and $pool->poolRange->isEqual($poolRange) ) {
        if ( defined $portInfo ) {
          if ( defined $pool->poolPort and $pool->poolPort eq $portInfo->{origin} ) {
            return "pool " . $pool->poolName;
          }
        }
        else {
          return "pool " . $pool->poolName;
        }
      }
    }

    #没有找到pool,需要新建
    #set security nat destination pool dstnat_pool_23 address 172.28.32.75/32
    #set security nat destination pool dstnat_pool_23 address port 80
    my $randNum = sprintf( '%05d', int( rand(99999) ) );
    $poolName = "dstnat_pool_$randNum";
    while ( defined $self->searcherReportFwInfo->parser->getNatPool($poolName) ) {
      $randNum  = sprintf( '%05d', int( rand(99999) ) );
      $poolName = "dstnat_pool_$randNum";
    }
    push @commands, "set security nat destination pool $poolName address $poolIp";
    if ( defined $portInfo ) {
      my ( $pro, $port ) = split( '/', $portInfo->{origin} );
      push @commands, "set security nat destination pool $poolName address port $port";
    }

  } ## end elsif ( $type eq 'natDst')
  $self->addToCommandText(@commands) if @commands != 0;
  return "pool " . $poolName;
} ## end sub getOrCreatePool

sub createSrc {
  my ( $self, $addr ) = @_;
  return $self->createAddress( $self->searcherReportFwInfo->fromZone, $addr );
}

sub createDst {
  my ( $self, $addr ) = @_;
  return $self->createAddress( $self->searcherReportFwInfo->toZone, $addr );
}

sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

sub createAddress {
  my ( $self, $zoneName, $addr ) = @_;

  #set security zones security-zone l2-untrust address-book address host_10.35.194.90 10.35.194.90/32
  my ( $ip, $mask ) = split( '/', $addr );
  my ( $addressName, $ipString, $ipMin, $ipMax );
  if ( not defined $mask ) {
    if ( $ip =~ /(\d+\.)(\d+\.)(\d+\.)(\d+)-(\d+)/ ) {
      ( $ipMin, $ipMax ) = ( $1 . $2 . $3 . $4, $1 . $2 . $3 . $5 );
      $addressName = "Range_$ip";
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

  my $command = "set security zones security-zone $zoneName address-book address $addressName $ipString/$mask"
    if defined $mask;
  $command
    = "set security zones security-zone $zoneName address-book address $addressName range-address $ipMin to $ipMax"
    if defined $ipMin;
  $self->addToCommandText($command);
  return $addressName;
} ## end sub createAddress

sub createService {
  my ( $self, $srv ) = @_;

=services
set applications application tcp_8080 term tcp_8080 protocol tcp
set applications application tcp_8080 term tcp_8080 source-port 0-65535
set applications application tcp_8080 term tcp_8080 destination-port 8080-8080
=cut

  my ( $protocol, $port ) = split( '/', $srv );
  $protocol = lc $protocol;
  return if $protocol ne 'tcp' and $protocol ne 'udp';

  my ( $serviceName, $dstPort );
  if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
    $serviceName = uc($protocol) . "_" . $+{portMin} . "-" . $+{portMax};
    $dstPort     = $+{portMin} . "-" . $+{portMax};
  }
  elsif ( $port =~ /^\d+$/o ) {
    $serviceName = uc($protocol) . "_" . $port;
    $dstPort     = $port . "-" . $port;
  }
  else {
    confess "ERROR: $port is not a port";
  }
  my @commands;
  push @commands, "set applications application $serviceName term $serviceName protocol $protocol";
  push @commands, "set applications application $serviceName term $serviceName source-port 0-65535";
  push @commands, "set applications application $serviceName term $serviceName destination-port $dstPort";

  # my $command = qq{set service "$serviceName" protocol $protocol src-port 0-65535 dst-port $dstPort};
  $self->addToCommandText(@commands);
  return $serviceName;
} ## end sub createService

__PACKAGE__->meta->make_immutable;
1;
