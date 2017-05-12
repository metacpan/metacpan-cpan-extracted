use strict;
use Test::More tests => 23;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new (
  date       => '19780605040302',
  less_years => 1, 
  plus_years => 1,
  );

my ($s1, $mi1, $h1, $d1, $mo1, $y1) = ($ds->second_menu,
                                       $ds->minute_menu,
                                       $ds->hour_menu,
                                       $ds->day_menu, 
                                       $ds->month_menu, 
                                       $ds->year_menu);

my ($s2, $mi2, $h2, $d2, $mo2, $y2) = ($ds->second_menu ('-1'),
                                       $ds->minute_menu ('-1'),
                                       $ds->hour_menu ('-1'),
                                       $ds->day_menu ('-1'), 
                                       $ds->month_menu ('-1'), 
                                       $ds->year_menu ('-1'));

my ($s3, $mi3, $h3, $d3, $mo3, $y3) = ($ds->second_menu ('+1'),
                                       $ds->minute_menu ('+1'),
                                       $ds->hour_menu ('+1'),
                                       $ds->day_menu ('+1'), 
                                       $ds->month_menu ('+1'), 
                                       $ds->year_menu ('+1'));


ok( @{$y1} == 3 , 'correct number of years');

ok( defined $s1->[2]{'selected'}, 'correct second selected');
ok( defined $mi1->[3]{'selected'}, 'correct minute selected');
ok( defined $h1->[4]{'selected'}, 'correct hour selected');
ok( defined $d1->[4]{'selected'}, 'correct day selected');
ok( defined $mo1->[5]{'selected'}, 'correct month selected');
ok( defined $y1->[1]{'selected'}, 'correct year selected');

ok( $y1->[0]->{'value'} == 1977 , 'correct year value');
ok( $y1->[1]->{'value'} == 1978 , 'correct year value');
ok( $y1->[2]->{'value'} == 1979 , 'correct year value');

ok( defined $s2->[1]{'selected'}, 'correct second selected');
ok( defined $mi2->[2]{'selected'}, 'correct minute selected');
ok( defined $h2->[3]{'selected'}, 'correct hour selected');
ok( defined $d2->[3]{'selected'}, 'correct day selected');
ok( defined $mo2->[4]{'selected'}, 'correct month selected');
ok( defined $y2->[1]{'selected'}, 'correct year selected');

ok( defined $s3->[3]{'selected'}, 'correct second selected');
ok( defined $mi3->[4]{'selected'}, 'correct minute selected');
ok( defined $h3->[5]{'selected'}, 'correct hour selected');
ok( defined $d3->[5]{'selected'}, 'correct day selected');
ok( defined $mo3->[6]{'selected'}, 'correct month selected');
ok( defined $y3->[1]{'selected'}, 'correct year selected');

