package Firewall::Policy::Designer::ClearPolicy::Netscreen;

#------------------------------------------------------------------------------
# 加载系统模块，辅助构造函数功能和属性
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Date;

has commandText => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

sub addToCommandText {
  my ( $self, @commands ) = @_;
  push( @{$self->commandText}, @commands );
}

sub design {
  my ( $self, $designReport ) = @_;
  if ( $designReport->{clearSrv} ) {

    #清理ip加port的策略
    return $self->design2($designReport);
  }
  else {

    #清理ip的所有策略
    return $self->design1($designReport);
  }
}

sub design1 {
  my ( $self, $designReport ) = @_;
  my $rules = $designReport->{rule};
  my @commandStr;
  for my $rule ( @{$rules} ) {

    if ( ref($rule) eq 'HASH' and defined $rule->{policyId} ) {
      if ( $rule->{memberCounter} == 1 ) {
        push @commandStr, "unset policy id $rule->{policyId}";
      }
      else {
        my $srcOrDstStr = $rule->{zone} eq $rule->{fromZone} ? "src-address" : "dst-address";
        my $comStr      = "set policy id $rule->{policyId}\n";
        $comStr .= "unset $srcOrDstStr $rule->{addrName}\n";
        $comStr .= "exit\n";
        push @commandStr, $comStr;
      }

    }
  } ## end for my $rule ( @{$rules...})

  my $realIpAndGroup = $designReport->{address}{realIp};
  if ( defined $realIpAndGroup ) {
    for my $addInfo ( values $realIpAndGroup ) {
      my $addName  = $addInfo->{name};
      my $zone     = $addInfo->{zone};
      my $addGroup = $addInfo->{addressGroup};
      if ( defined $addGroup ) {
        for my $gn ( keys $addGroup ) {
          push @commandStr, "unset group address $zone $addGroup remove $addName";

        }
      }

      push @commandStr, "unset address $zone $addName" if defined $addName;

    }
  }
  my $natIpAndGroup = $designReport->{address}{natIp};
  if ( defined $natIpAndGroup ) {

    for my $natInfo ( values $natIpAndGroup ) {
      my $addName   = $natInfo->{name};
      my $zone      = $natInfo->{zone};
      my $interface = $natInfo->{interface};
      my $addGroup  = $natInfo->{addressGroup};
      if ( defined $addGroup ) {
        for my $gn ( keys $addGroup ) {
          push @commandStr, "unset group address Global $addGroup remove $addName";

        }
      }
      if ( $addName =~ /MIP\((?<ip>.+)\)/ and defined $interface ) {
        push @commandStr, "unset interface $interface mip $+{ip}";
      }
    }

  } ## end if ( defined $natIpAndGroup)

  $self->addToCommandText(@commandStr);

  return \@commandStr;
} ## end sub design1

sub design2 {
  my ( $self, $designReport ) = @_;
  my $rules = $designReport->{rule};
  my @commandStr;
  for my $rule ( @{$rules} ) {
    if ( ref($rule) eq 'HASH' and defined $rule->{policyId} ) {
      if ( $rule->{srvContain} == 1 and $rule->{memberCounter} == 1 ) {
        push @commandStr, "unset policy id $rule->{policyId}";
      }
      elsif ( $rule->{srvContain} == 1 and $rule->{memberCounter} > 1 ) {

        my $comStr = "set policy id $rule->{policyId}\n";
        $comStr .= "unset dst-address $rule->{addrName}\n";
        $comStr .= "exit\n";
        push @commandStr, $comStr;
      }
      elsif ( $rule->{srvContain} == 0 and $rule->{memberCounter} == 1 ) {
        my $comStr = "set policy id $rule->{policyId}\n";
        for my $hitSrv ( @{$rule->{hitSrv}} ) {
          $comStr .= "unset service $hitSrv\n";
        }
        $comStr .= "exit\n";
        push @commandStr, $comStr;
      }
    } ## end if ( ref($rule) eq 'HASH'...)
  } ## end for my $rule ( @{$rules...})

  $self->addToCommandText(@commandStr);

  return \@commandStr;
} ## end sub design2

__PACKAGE__->meta->make_immutable;
1;
