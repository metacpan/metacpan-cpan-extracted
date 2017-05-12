use strict;
use Test::More tests => 19;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new;

$ds->less_years (1);
$ds->plus_years (2);

my ($s, $mi, $h, $d, $mo, $y) = ($ds->second_menu (0),
                                 $ds->minute_menu (0),
                                 $ds->hour_menu (0),
                                 $ds->day_menu (4), 
                                 $ds->month_menu (12), 
                                 $ds->year_menu (1976));


ok( @{$s} == 60 , 'correct number of seconds');
ok( @{$mi} == 60 , 'correct number of minutes');
ok( @{$h} == 24 , 'correct number of hours');
ok( @{$d} == 31 , 'correct number of days');
ok( @{$mo} == 12 , 'correct number of months');
ok( @{$y} == 4 , 'correct number of years');

ok( defined $s->[0]{'selected'}, 'correct second selected');
ok( defined $mi->[0]{'selected'}, 'correct minute selected');
ok( defined $h->[0]{'selected'}, 'correct hour selected');
ok( defined $d->[3]{'selected'}, 'correct day selected');
ok( defined $mo->[11]{'selected'}, 'correct month selected');
ok( defined $y->[1]{'selected'}, 'correct year selected');

ok( $y->[0]->{'value'} == 1975 , 'correct year value');
ok( $y->[1]->{'value'} == 1976 , 'correct year value');
ok( $y->[2]->{'value'} == 1977 , 'correct year value');
ok( $y->[3]->{'value'} == 1978 , 'correct year value');

ok( $ds->less_years() == 1, 'less_years getter ok');
ok( $ds->plus_years() == 2, 'plus_years getter ok');

