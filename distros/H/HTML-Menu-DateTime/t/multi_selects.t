use strict;
use Test::More tests => 22;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new;

$ds->start_year (1975),
$ds->end_year (1977);

my ($s, $mi, $h, $d, $mo, $y) = ($ds->second_menu ([0,8]),
                                 $ds->minute_menu ([0,7]),
                                 $ds->hour_menu ([0,6]),
                                 $ds->day_menu ([1,4]), 
                                 $ds->month_menu ([2,12]), 
                                 $ds->year_menu ([1976,1977]));


ok( @{$s}  == 60 , 'correct number of seconds');
ok( @{$mi} == 60 , 'correct number of minutes');
ok( @{$h}  == 24 , 'correct number of hours');
ok( @{$d}  == 31 , 'correct number of days');
ok( @{$mo} == 12 , 'correct number of months');
ok( @{$y}  == 3 , 'correct number of years');

ok( defined $s->[0]{'selected'}, 'correct second selected');
ok( defined $s->[8]{'selected'}, 'correct second selected');

ok( defined $mi->[0]{'selected'}, 'correct minute selected');
ok( defined $mi->[7]{'selected'}, 'correct minute selected');

ok( defined $h->[0]{'selected'}, 'correct hour selected');
ok( defined $h->[6]{'selected'}, 'correct hour selected');

ok( defined $d->[0]{'selected'}, 'correct day selected');
ok( defined $d->[3]{'selected'}, 'correct day selected');

ok( defined $mo->[1]{'selected'}, 'correct month selected');
ok( defined $mo->[11]{'selected'}, 'correct month selected');

ok( defined $y->[1]{'selected'}, 'correct year selected');
ok( defined $y->[2]{'selected'}, 'correct year selected');

ok( $y->[0]->{'value'} == 1975 , 'correct year value');
ok( $y->[1]->{'value'} == 1976 , 'correct year value');
ok( $y->[2]->{'value'} == 1977 , 'correct year value');

