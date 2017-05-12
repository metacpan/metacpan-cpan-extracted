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

my $wwwc_date = '2000-05-06';
my $wwwc_time = '15:23:44';
my $wwwc_datetime = $wwwc_date.'T'.$wwwc_time;

{
  my $dt = $dtx->from_wwwc($wwwc_datetime);

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
  my $dt = $dtx->from_wwwc('2000-05-66T15:23:44');
  ok !defined $dt;
}

{
  my $str = $dtx->for_wwwc( %args );
  like $str => qr/^$wwwc_datetime/;  # ignore timezone part
}

{
  my $dt = $dtx->from( %args );

  is $dtx->format('wwwc')->format_date($dt) => $wwwc_date;
}

{
  my $dt = $dtx->from_wwwc($wwwc_date);
  ok defined $dt;
  is $dt->year  => $args{year};
  is $dt->month => $args{month};
  is $dt->day   => $args{day};
}
