use strict;
use warnings;
use Test::More qw(no_plan);
use DateTimeX::Web;

my %args = (
  year   => 2005,
  month  => 12,
  day    => 25,
);

my $date = '2005-12-25';

{
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->parse('%Y-%m-%d', $date);
  ok defined $dt;
  is $dt->year  => $args{year};
  is $dt->month => $args{month};
  is $dt->day   => $args{day};
}