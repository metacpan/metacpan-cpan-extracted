package Firewall::Config::Element::Schedule::Huawei;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Time::Local;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Schedule::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Schedule::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Schedule::Huawei 通用属性
#------------------------------------------------------------------------------
has startDate => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has endDate => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has day => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has startTime => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has endTime => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->schName );
}

#------------------------------------------------------------------------------
# 检查是否基于时间的策略
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 检查是否基于时间的策略
#------------------------------------------------------------------------------
sub isExpired {
  my ( $self, $time ) = @_;
  if ( defined $self->{isExpired} and not defined $time ) {
    return $self->{isExpired};
  }
  if ( $self->schType eq 'onetime' ) {
    $self->{isExpired} = $self->isEnable($time) ? 0 : 1;
  }
  else {
    $self->{isExpired} = 0;
  }
  return $self->{isExpired};
}

#------------------------------------------------------------------------------
# 检查策略是否启用
#------------------------------------------------------------------------------
sub isEnable {
  my ( $self, $time ) = @_;
  if ( defined $self->{isEnable} and not defined $time ) {
    return $self->{isEnable};
  }
  $time = $time // time();
  if ( not defined $self->{timeRange} ) {
    $self->createTimeRange;
  }
  $self->{isEnable} = 0;
  if ( not defined $self->{timeRange} ) {    # createTimeRange 失败
  }
  elsif ( $self->schType eq 'onetime' ) {
    if ( $time >= $self->{timeRange}{min} and $time <= $self->{timeRange}{max} ) {
      $self->{isEnable} = 1;
    }
  }
  elsif ( $self->schType eq 'recurring' ) {
    my ( $wday, $hour, $min ) = ( localtime($time) )[ 6, 2, 1 ];
    my $weekDay    = (qw/ sunday monday tuesday wednesday thursday friday saturday /)[$wday];
    my $hourAndMin = $hour . sprintf( "%02d", $min ) + 0;
    if ( exists( $self->{timeRange}{$weekDay} ) ) {
      if ( $hourAndMin >= $self->{timeRange}{$weekDay}{min} and $hourAndMin <= $self->{timeRange}{$weekDay}{max} ) {
        $self->{isEnable} = 1;
      }
    }
  }
  return $self->{isEnable};
} ## end sub isEnable

#------------------------------------------------------------------------------
# 创建时间区间
#------------------------------------------------------------------------------
sub createTimeRange {
  my $self = shift;
  if ( $self->schType eq 'onetime' ) {
    if ( defined $self->endDate ) {
      $self->{timeRange}{min} = defined $self->startDate ? $self->getSecondFromEpoch( $self->startDate ) : 0;
      $self->{timeRange}{max} = $self->getSecondFromEpoch( $self->endDate );
    }
  }
  elsif ( $self->schType eq 'recurring' ) {
    if ( defined $self->day and defined $self->startTime and defined $self->endTime ) {
      my ( $min, $max ) = ( $self->startTime, $self->endTime );
      $min =~ s/://;
      $max =~ s/://;
      my $range = {
        min => $min + 0,
        max => $max + 0
      };
      my @weekDays;
      if ( $self->day eq 'daily' ) {
        @weekDays = ( "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday" );
      }
      elsif ( $self->day eq 'working-day' ) {
        @weekDays = ( "monday", "tuesday", "wednesday", "thursday", "friday" );
      }
      elsif ( $self->day eq 'off-day' ) {
        @weekDays = ( "sunday", "saturday" );
      }
      else {
        @weekDays = split( '[\s+,]', $self->day );
      }
      for my $weekDay (@weekDays) {
        $self->{timeRange}{$weekDay} = $range;
      }
    } ## end if ( defined $self->day...)
  } ## end elsif ( $self->schType eq...)
} ## end sub createTimeRange

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ( $self, $string ) = @_;

  #23:59:59 2099/12/31
  #23:59:59 2099/12/31
  my ( $hour, $min, $sec, $year, $mon, $mday ) = split( '[\s+:/]', $string );
  my $second = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
  return $second;
}

#------------------------------------------------------------------------------
# 获取策略时效时间
#------------------------------------------------------------------------------
sub getEnddateStr {
  my $self = shift;
  my ( $hour, $min, $sec, $year, $mon, $mday ) = split( '[\s+:/]', $self->endDate );
  return $year . "-" . $mon . "-" . $mday . " " . $hour . ":" . $min;
}

__PACKAGE__->meta->make_immutable;
1;
