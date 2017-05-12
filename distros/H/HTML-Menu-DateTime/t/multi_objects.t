use strict;
use Test::More tests => 32;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

### DATE OBJECT 1

my $o1 = HTML::Menu::DateTime->new (date => '19760302000000');

$o1->start_year (1975);
$o1->end_year (1977);

my ($s1, $mi1, $h1, $d1, $mo1, $y1) = ($o1->second_menu,
                                       $o1->minute_menu,
                                       $o1->hour_menu,
                                       $o1->day_menu, 
                                       $o1->month_menu, 
                                       $o1->year_menu);

### DATE OBJECT 2

my $o2 = HTML::Menu::DateTime->new (date => '19800605010101');

$o2->start_year (1978);
$o2->end_year (1981);

my ($s2, $mi2, $h2, $d2, $mo2, $y2) = ( $o2->second_menu,
                                        $o2->minute_menu,
                                        $o2->hour_menu,
                                        $o2->day_menu, 
                                        $o2->month_menu, 
                                        $o2->year_menu);

### TEST OBJECT 1

ok( @{$s1} == 60 , 'correct number of seconds');
ok( @{$mi1} == 60 , 'correct number of minutes');
ok( @{$h1} == 24 , 'correct number of hours');
is( @{$d1}, 31, 'correct number of days');
is( @{$mo1}, 12, 'correct number of months');
is( @{$y1}, 3 , 'correct number of years');

ok( defined $s1->[0]{'selected'}, 'correct second selected');
ok( defined $mi1->[0]{'selected'}, 'correct minute selected');
ok( defined $h1->[0]{'selected'}, 'correct hour selected');
ok( defined $d1->[1]{'selected'}, 'correct day selected');
ok( defined $mo1->[2]{'selected'}, 'correct month selected');
ok( defined $y1->[1]{'selected'}, 'correct year selected');

ok( $y1->[0]->{'value'} == 1975 , 'correct year value');
ok( $y1->[1]->{'value'} == 1976 , 'correct year value');
ok( $y1->[2]->{'value'} == 1977 , 'correct year value');

### TEST OBJECT 2

ok( @{$s2} == 60 , 'correct number of seconds');
ok( @{$mi2} == 60 , 'correct number of minutes');
ok( @{$h2} == 24 , 'correct number of hours');
is( @{$d2}, 31, 'correct number of days');
is( @{$mo2}, 12, 'correct number of months');
is( @{$y2}, 4 , 'correct number of years');

ok( defined $s2->[1]{'selected'}, 'correct second selected');
ok( defined $mi2->[1]{'selected'}, 'correct minute selected');
ok( defined $h2->[1]{'selected'}, 'correct hour selected');
ok( defined $d2->[4]{'selected'}, 'correct day selected');
ok( defined $mo2->[5]{'selected'}, 'correct month selected');
ok( defined $y2->[2]{'selected'}, 'correct year selected');

ok( $y2->[0]->{'value'} == 1978 , 'correct year value');
ok( $y2->[1]->{'value'} == 1979 , 'correct year value');
ok( $y2->[2]->{'value'} == 1980 , 'correct year value');
ok( $y2->[3]->{'value'} == 1981 , 'correct year value');

