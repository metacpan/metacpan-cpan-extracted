use strict;
use Test::More tests => 9;

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

my ($h, $d, $m, $y) = ($ds->hour_menu,
                       $ds->day_menu, 
                       $ds->month_menu, 
                       $ds->year_menu);


ok( @{$y} == 3 , 'correct number of years');

ok( defined $h->[$hour]{'selected'}, 'correct hour selected');
ok( defined $d->[$day-1]{'selected'}, 'correct day selected');
ok( defined $m->[$month-1]{'selected'}, 'correct month selected');
ok( defined $y->[1]{'selected'}, 'correct year selected');

ok( $y->[0]->{'value'} == $year-1 , 'correct year value');
ok( $y->[1]->{'value'} == $year , 'correct year value');
ok( $y->[2]->{'value'} == $year+1 , 'correct year value');

