package Firewall::Config::Element::Schedule::Asa;

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

=example
time-range S_20091130
 absolute start 00:00 01 November 2009 end 23:59 30 November 2009
time-range S20090926
 absolute end 23:59 26 September 2009
time-range S_20091131
 periodic daily 11:00 to 14:00
time-range S_20091132
 periodic Monday Thursday 11:30 to 14:00
time-range S_20091133
 periodic weekdays 11:00 to 14:00
time-range S_20091134
 periodic weekend 11:00 to 14:00

trange mode commands/options:
  Friday     Friday
  Monday     Monday
  Saturday   Saturday
  Sunday     Sunday
  Thursday   Thursday
  Tuesday    Tuesday
  Wednesday  Wednesday
  daily      Every day of the week
  weekdays   Monday thru Friday
  weekend    Saturday and Sunday
=cut

#------------------------------------------------------------------------------
# Firewall::Config::Element::Schedule::Asa 通用属性
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

has periodic => (
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
sub isExpired {
  my ( $self, $time ) = @_;
  if ( defined $self->{isExpired} and not defined $time ) {
    return $self->{isExpired};
  }
  if ( $self->schType eq 'absolute' ) {
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
  elsif ( $self->schType eq 'absolute' ) {
    if ( $time >= $self->{timeRange}{min} and $time <= $self->{timeRange}{max} ) {
      $self->{isEnable} = 1;
    }
  }
  elsif ( $self->schType eq 'periodic' ) {
    my ( $wday, $hour, $min ) = ( localtime($time) )[ 6, 2, 1 ];
    my $weekDay    = (qw/ Sunday Monday Tuesday Wednesday Thursday Friday Saturday /)[$wday];
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
  if ( $self->schType eq 'absolute' ) {
    if ( defined $self->endDate ) {
      $self->{timeRange}{min} = defined $self->startDate ? $self->getSecondFromEpoch( $self->startDate ) : 0;
      $self->{timeRange}{max} = $self->getSecondFromEpoch( $self->endDate );
    }
  }
  elsif ( $self->schType eq 'periodic' ) {
    if ( defined $self->periodic and defined $self->startTime and defined $self->endTime ) {
      my ( $min, $max ) = ( $self->startTime, $self->endTime );
      $min =~ s/://;
      $max =~ s/://;
      my $range = {
        min => $min + 0,
        max => $max + 0
      };
      my @weekDays;
      if ( $self->periodic eq 'daily' ) {
        @weekDays = qw/ Sunday Monday Tuesday Wednesday Thursday Friday Saturday /;
      }
      elsif ( $self->periodic eq 'weekdays' ) {
        @weekDays = qw/ Monday Tuesday Wednesday Thursday Friday /;
      }
      elsif ( $self->periodic eq 'weekend' ) {
        @weekDays = qw/ Sunday Saturday /;
      }
      else {
        @weekDays = split( /\s+/, $self->periodic );
      }
      for my $weekDay (@weekDays) {
        $self->{timeRange}{$weekDay} = $range;
      }
    } ## end if ( defined $self->periodic...)
  } ## end elsif ( $self->schType eq...)
} ## end sub createTimeRange

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ( $self, $string ) = @_;

  #00:00 01 November 2009
  my %MON = (
    January   => 1,
    February  => 2,
    March     => 3,
    April     => 4,
    May       => 5,
    June      => 6,
    July      => 7,
    August    => 8,
    September => 9,
    October   => 10,
    November  => 11,
    December  => 12,
  );
  my ( $hour, $min, $mday, $mon, $year ) = split( '[ :]', $string );
  $mon = $MON{$mon};
  my $second = timelocal( 0, $min, $hour, $mday, $mon - 1, $year - 1900 );
  return $second;
} ## end sub getSecondFromEpoch

__PACKAGE__->meta->make_immutable;
1;
