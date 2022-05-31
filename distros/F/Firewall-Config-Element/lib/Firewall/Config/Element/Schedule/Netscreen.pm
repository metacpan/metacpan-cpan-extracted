package Firewall::Config::Element::Schedule::Netscreen;

use Moose;
use namespace::autoclean;
use Time::Local;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Schedule::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Schedule::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Schedule::Netscreen 通用属性
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

has weekday => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has startTime1 => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has endTime1 => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has startTime2 => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has endTime2 => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has description => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

=example
set scheduler "S_20120331" once start 10/10/2011 0:0 stop 3/31/2012 23:59
set scheduler "S20110630" recurrent friday start 10:00 stop 12:00 start 14:00 stop 16:00 comment "test"
=cut

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
  if ( $self->schType eq 'once' ) {
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
  elsif ( $self->schType eq 'once' ) {
    if ( $time >= $self->{timeRange}{min} and $time <= $self->{timeRange}{max} ) {
      $self->{isEnable} = 1;
    }
  }
  elsif ( $self->schType eq 'recurrent' ) {
    my ( $wday, $hour, $min ) = ( localtime($time) )[ 6, 2, 1 ];
    my $weekDay    = (qw/ sunday monday tuesday wednesday thursday friday saturday /)[$wday];
    my $hourAndMin = $hour . sprintf( "%02d", $min ) + 0;
    if ( exists( $self->{timeRange}{$weekDay} ) ) {
      for ( @{$self->{timeRange}{$weekDay}} ) {
        my ( $min, $max ) = ( $_->{min}, $_->{max} );
        if ( $hourAndMin >= $min and $hourAndMin <= $max ) {
          $self->{isEnable} = 1;
          last;
        }
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
  if ( $self->schType eq 'once' ) {
    if ( defined $self->startDate and defined $self->endDate ) {
      $self->{timeRange}{min} = $self->getSecondFromEpoch( $self->startDate );
      $self->{timeRange}{max} = $self->getSecondFromEpoch( $self->endDate );
    }
  }
  elsif ( $self->schType eq 'recurrent' ) {
    if ( defined $self->weekday and defined $self->startTime1 and defined $self->endTime1 ) {
      my @times = ( {min => $self->startTime1, max => $self->endTime1} );
      if ( defined $self->startTime2 and defined $self->endTime2 ) {
        push @times,
          {
          min => $self->startTime2,
          max => $self->endTime2
          };
      }
      for (@times) {
        my ( $min, $max ) = ( $_->{min}, $_->{max} );
        $min =~ s/://;
        $max =~ s/://;
        push @{$self->{timeRange}{$self->weekday}},
          {
          min => $min + 0,
          max => $max + 0
          };
      }
    } ## end if ( defined $self->weekday...)
  } ## end elsif ( $self->schType eq...)
} ## end sub createTimeRange

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ( $self, $string ) = @_;

  #3/31/2012 23:59
  my ( $mon, $mday, $year, $hour, $min ) = split( '[/ :]', $string );
  my $second = timelocal( 0, $min, $hour, $mday, $mon - 1, $year - 1900 );
  return $second;
}

#------------------------------------------------------------------------------
# 获取策略时效时间
#------------------------------------------------------------------------------
sub getEnddateStr {
  my $self = shift;
  my ( $mon, $mday, $year, $hour, $min ) = split( '[/ :]', $self->endDate );
  return $year . "-" . $mon . "-" . $mday . " " . $hour . ":" . $min;
}

__PACKAGE__->meta->make_immutable;
1;
