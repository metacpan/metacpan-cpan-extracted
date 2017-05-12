use strict;
use Test::More tests => 195;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new (
  date       => '19761204000000',
  start_year => 1975,
  end_year   => 1977,
  no_select  => 1,
  );


my ($s1, $mi1, $h1, $d1, $mo1, $y1) = ($ds->second_menu,
                                       $ds->minute_menu,
                                       $ds->hour_menu,
                                       $ds->day_menu, 
                                       $ds->month_menu, 
                                       $ds->year_menu);


ok( @{$y1} == 3 , 'correct number of years');

for (1 .. scalar @{$s1}) {
  ok( ! defined $s1->[$_]{'selected'}, 'second not selected');
}

for (1 .. scalar @{$mi1}) {
  ok( ! defined $mi1->[$_]{'selected'}, 'minute not selected');
}

for (1 .. scalar @{$h1}) {
  ok( ! defined $h1->[$_]{'selected'}, 'hour not selected');
}

for (1 .. scalar @{$d1}) {
  ok( ! defined $d1->[$_]{'selected'}, 'day not selected');
}

for (1 .. scalar @{$mo1}) {
  ok( ! defined $mo1->[$_]{'selected'}, 'month not selected');
}

for (1 .. scalar @{$y1}) {
  ok( ! defined $y1->[$_]{'selected'}, 'year not selected');
}

ok( $y1->[0]->{'value'} == 1975 , 'correct year value');
ok( $y1->[1]->{'value'} == 1976 , 'correct year value');
ok( $y1->[2]->{'value'} == 1977 , 'correct year value');

