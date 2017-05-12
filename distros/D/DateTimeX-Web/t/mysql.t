use strict;
use warnings;
use Test::More qw(no_plan);
use DateTimeX::Web;

my $dtx = DateTimeX::Web->new(
  time_zone => 'UTC',
  on_error  => 'ignore'
);

my %args = (
  year   => 2000,
  month  => 5,
  day    => 6,
  hour   => 15,
  minute => 23,
  second => 44,
);

my $mysql_date = '2000-05-06';
my $mysql_time = '15:23:44';
my $mysql_datetime = "$mysql_date $mysql_time";

{
  my $dt = $dtx->from_mysql($mysql_datetime);

  ok defined $dt;
  is $dt->year   => $args{year};
  is $dt->month  => $args{month};
  is $dt->day    => $args{day};
  is $dt->hour   => $args{hour};
  is $dt->minute => $args{minute};
  is $dt->second => $args{second};
  is $dt->time_zone->name => 'UTC';
}

{
  my $dt = $dtx->from_mysql('2000-05-66 15:23:44');
  ok !defined $dt;
}

{
  my $str = $dtx->for_mysql( %args );
  is $str => $mysql_datetime;
}

{
  my $dt = $dtx->from( %args );

  is $dtx->format('mysql')->format_date($dt) => $mysql_date;
  is $dtx->format('mysql')->format_time($dt) => $mysql_time;
}

{
  my $dt = $dtx->format('mysql')->parse_date($mysql_date);
  ok defined $dt;
  is $dt->year  => $args{year};
  is $dt->month => $args{month};
  is $dt->day   => $args{day};
}
