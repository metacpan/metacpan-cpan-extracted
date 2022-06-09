package Firewall::Policy::Designer::ClearPolicy::Asa;

#------------------------------------------------------------------------------
# 加载系统模块，辅助构造函数功能和属性
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Date;
use Firewall::Utils::Ip;

has commandText => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] }, );

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
    if ( ref($rule) eq 'HASH' ) {
      push @commandStr, "no $rule->{content}";
    }
  }
  my $realIpAndGroup = $designReport->{address}{realIp};
  if ( defined $realIpAndGroup ) {
    for my $address ( keys $realIpAndGroup ) {
      my $addInfo = $realIpAndGroup->{$address};
      my ( $ip, $mask ) = split( '/', $address );
      my $maskStr     = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
      my $commandTemp = '';
      if ( $mask == 32 ) {
        $commandTemp = "no network-object host $ip\n";
      }
      else {
        $commandTemp = "no network-object $ip $maskStr\n";
      }
      my $addGroup = $addInfo->{addressGroup} if defined $addInfo->{addressGroup};
      for my $addGroupInfo ( values $addGroup ) {
        my $addGroupName = $addGroupInfo->{groupName};
        my $commandStr   = "object-group network $addGroupName\n";
        $commandStr .= $commandTemp;
        $commandStr .= "exit";
        push @commandStr, $commandStr;
      }
    } ## end for my $address ( keys ...)
  } ## end if ( defined $realIpAndGroup)
  my $natIpAndGroup = $designReport->{address}{natIp};
  if ( defined $natIpAndGroup ) {
    for my $address ( keys $natIpAndGroup ) {
      my $addInfo = $natIpAndGroup->{$address};
      my ( $ip, $mask ) = split( '/', $address );
      my $maskStr     = Firewall::Utils::Ip->new->changeMaskToIpForm($mask);
      my $commandTemp = '';
      if ( $mask == 32 ) {
        $commandTemp = "no network-object host $ip\n";
      }
      else {
        $commandTemp = "no network-object $ip $maskStr\n";
      }
      my $addGroup = $addInfo->{addressGroup} if defined $addInfo->{addressGroup};
      for my $addGroupInfo ( values $addGroup ) {
        my $addGroupName = $addGroupInfo->{groupName};
        my $commandStr   = "object-group network $addGroupName\n";
        $commandStr .= $commandTemp;
        $commandStr .= "exit";
        push @commandStr, $commandStr;
      }
    } ## end for my $address ( keys ...)
  } ## end if ( defined $natIpAndGroup)
  $self->addToCommandText(@commandStr);
  return \@commandStr;
} ## end sub design1

sub design2 {
  my ( $self, $designReport ) = @_;
  my $rules = $designReport->{rule};
  my @commandStr;
  for my $rule ( @{$rules} ) {
    if ( ref($rule) eq 'HASH' ) {
      if ( $rule->{srvContain} == 1 and $rule->{memberCounter} == 1 ) {
        push @commandStr, "no $rule->{content}";
      }
    }
  }
  $self->addToCommandText(@commandStr);
  return \@commandStr;
}

__PACKAGE__->meta->make_immutable;
1;
