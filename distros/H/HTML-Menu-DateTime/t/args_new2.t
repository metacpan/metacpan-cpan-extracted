use strict;
use Test::More tests => 16;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new (
  date       => '19761204000000',
  less_years => 1,
  plus_years => 1,
  );


my ($s, $mi, $h, $d, $mo, $y) = ($ds->second_menu,
                                 $ds->minute_menu,
                                 $ds->hour_menu,
                                 $ds->day_menu, 
                                 $ds->month_menu, 
                                 $ds->year_menu);


ok( @{$s} == 60 , 'correct number of seconds');
ok( @{$mi} == 60 , 'correct number of minutes');
ok( @{$h} == 24 , 'correct number of hours');
ok( @{$d} == 31 , 'correct number of days');
ok( @{$mo} == 12 , 'correct number of months');
ok( @{$y} == 3 , 'correct number of years');

ok( defined $s->[0]{'selected'}, 'correct second selected');
ok( defined $mi->[0]{'selected'}, 'correct minute selected');
ok( defined $h->[0]{'selected'}, 'correct hour selected');
ok( defined $d->[3]{'selected'}, 'correct day selected');
ok( defined $mo->[11]{'selected'}, 'correct month selected');
ok( defined $y->[1]{'selected'}, 'correct year selected');

ok( $y->[0]->{'value'} == 1975 , 'correct year value');
ok( $y->[1]->{'value'} == 1976 , 'correct year value');
ok( $y->[2]->{'value'} == 1977 , 'correct year value');

