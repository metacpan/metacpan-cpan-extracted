use strict;
use Test::More tests => 17;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my ($hour, $day, $month, $year) = (localtime(time))[2..5];
$month += 1;
$year  += 1900;

my $ds = HTML::Menu::DateTime->new (
  less_years => 1, 
  plus_years => 1,
  );

my ($h1, $d1, $m1, $y1) = ($ds->hour_menu,
                           $ds->day_menu, 
                           $ds->month_menu, 
                           $ds->year_menu);

my ($h2, $d2, $m2, $y2) = ($ds->hour_menu ('-1'),
                           $ds->day_menu ('-1'), 
                           $ds->month_menu ('-1'), 
                           $ds->year_menu ('-1'));

my ($h3, $d3, $m3, $y3) = ($ds->hour_menu ('+1'),
                           $ds->day_menu ('+1'), 
                           $ds->month_menu ('+1'), 
                           $ds->year_menu ('+1'));

my $todo = 'Haven\'t worked out logic for wrap-around selections';

### Note: we don't test the second_menu() and minute_menu() methods 
### in the (unlikely) case of a second's lapse between our calling 
### localtime(time) and the module calling it

ok( @{$y1} == 3 , 'correct number of years');

ok( defined $h1->[$hour]{'selected'}, 'correct hour selected');
ok( defined $d1->[$day-1]{'selected'}, 'correct day selected');
ok( defined $m1->[$month-1]{'selected'}, 'correct month selected');
ok( defined $y1->[1]{'selected'}, 'correct year selected');

ok( $y1->[0]->{'value'} == $year-1 , 'correct year value');
ok( $y1->[1]->{'value'} == $year , 'correct year value');
ok( $y1->[2]->{'value'} == $year+1 , 'correct year value');

TODO: {
  local $TODO = $todo if $hour == 0;
  
  ok( defined $h2->[$hour-1]{'selected'}, 'correct hour selected');
}

TODO: {
  local $TODO = $todo if $day == 1;
  
  ok( defined $d2->[$day-2]{'selected'}, 'correct day selected');
}

TODO: {
  local $TODO = $todo if $month == 1;
  
  ok( defined $m2->[$month-2]{'selected'}, 'correct month selected');
}

ok( defined $y2->[1]{'selected'}, 'correct year selected');

TODO: {
  local $TODO = $todo if $hour == 23;
  
  ok( defined $h3->[$hour+1]{'selected'}, 'correct hour selected');
}

TODO: {
  local $TODO = $todo if $day == 31;
  
  ok( defined $d3->[$day]{'selected'}, 'correct day selected');
}

TODO: {
  local $TODO = $todo if $month == 12;
  
  ok( defined $m3->[$month]{'selected'}, 'correct month selected');
}

ok( defined $y3->[1]{'selected'}, 'correct year selected');

