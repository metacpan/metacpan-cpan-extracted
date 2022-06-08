package Firewall::Policy::Designer::ClearPolicy::Srx;

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

#set security policies from-zone l2-trust to-zone l2-untrust policy old-130 match source-address Host_10.33.104.61
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

#清理所有ip策略
sub design1 {
  my ( $self, $designReport ) = @_;
  my $rules = $designReport->{rule};
  my @commandStr;
  for my $rule ( @{$rules} ) {

    if ( ref($rule) eq 'HASH' and defined $rule->{addrName} ) {
      if ( $rule->{memberCounter} == 1 ) {
        push @commandStr,
          "delete security policies from-zone $rule->{fromZone} to-zone $rule->{toZone} policy $rule->{ruleName}";
      }
      else {
        my $srcOrDstStr = $rule->{zone} eq $rule->{fromZone} ? "source-address" : "destination-address";
        push @commandStr,
          "delete security policies from-zone $rule->{fromZone} to-zone $rule->{toZone} policy $rule->{ruleName} match $srcOrDstStr $rule->{addrName}";
      }

    }
  }
  my $realIpAndGroup = $designReport->{address}{realIp};
  if ( defined $realIpAndGroup ) {
    for my $addInfo ( values $realIpAndGroup ) {
      my $addName  = $addInfo->{name};
      my $zone     = $addInfo->{zone};
      my $addGroup = $addInfo->{addressGroup};
      if ( defined $addGroup ) {
        for my $gn ( keys $addGroup ) {
          push @commandStr, "delete security zones security-zone $zone address-book address-set $gn address $addName";

        }
      }
      push @commandStr, "delete security zones security-zone $zone address-book address $addName";

    }
  }

  $self->addToCommandText(@commandStr);
  return \@commandStr;

} ## end sub design1

sub design2 {
  my ( $self, $designReport ) = @_;
  my $rules = $designReport->{rule};
  my @commandStr;
  for my $rule ( @{$rules} ) {
    if ( ref($rule) eq 'HASH' and defined $rule->{addrName} ) {
      if ( $rule->{srvContain} == 1 and $rule->{memberCounter} == 1 ) {
        push @commandStr,
          "delete security policies from-zone $rule->{fromZone} to-zone $rule->{toZone} policy $rule->{ruleName}";
      }
      elsif ( $rule->{srvContain} == 1 and $rule->{memberCounter} > 1 ) {
        push @commandStr,
          "delete security policies from-zone $rule->{fromZone} to-zone $rule->{toZone} policy $rule->{ruleName} match destination-address $rule->{addrName}";
      }
      elsif ( $rule->{srvContain} == 0 and $rule->{memberCounter} == 1 ) {
        for my $hitSrv ( @{$rule->{hitSrv}} ) {
          push @commandStr,
            "delete security policies from-zone $rule->{fromZone} to-zone $rule->{toZone} policy $rule->{ruleName} match application $hitSrv";
        }

      }

    }
  } ## end for my $rule ( @{$rules...})
  $self->addToCommandText(@commandStr);
  return \@commandStr;
} ## end sub design2

__PACKAGE__->meta->make_immutable;
1;
