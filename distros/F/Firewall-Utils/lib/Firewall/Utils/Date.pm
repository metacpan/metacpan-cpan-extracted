package Firewall::Utils::Date;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Carp;
use Moose;
use namespace::autoclean;

sub getFormatedDate {
  my ( $self, @param ) = @_;
  my ( $format, $time );
  if ( defined $param[0] and $param[0] =~ /^\d+$/ ) {
    ( $time, $format ) = @param;
  }
  else {
    ( $format, $time ) = @param;
  }
  if ( not defined $format ) {
    $format = 'yyyy-mm-dd hh:mi:ss';
  }
  if ( not defined $time ) {
    $time = time();
  }
  my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time);
  my %timeMap = (
    yyyy => $year + 1900,
    mm   => $mon + 1,
    dd   => $mday,
    hh   => $hour,
    mi   => $min,
    ss   => $sec,
  );
  my %formatMap = (
    yyyy => '%04d',
    mm   => '%02d',
    dd   => '%02d',
    hh   => '%02d',
    mi   => '%02d',
    ss   => '%02d',
  );
  my $regex = '(' . join( '|', keys %timeMap ) . ')';
  my @times = map { $timeMap{$_} } ( $format =~ /$regex/g );
  if ( scalar(@times) == 0 ) {
    confess "ERROR: format string [$format]  has none valid charactors\n";
  }
  $format =~ s/$regex/$formatMap{$1}/g;
  my $formatedTime = sprintf( "$format", @times );
  return ($formatedTime);
} ## end sub getFormatedDate

__PACKAGE__->meta->make_immutable;
1;
