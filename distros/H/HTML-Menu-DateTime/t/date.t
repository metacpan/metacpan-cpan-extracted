use strict;
use Test::More tests => 59;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}


my $ds1 = HTML::Menu::DateTime->new (
  date => '1976-12-04',
  less_years => 1,
  plus_years => 1,
  );


my $ds2 = HTML::Menu::DateTime->new (
  date => '19780401010101',
  less_years => 2,
  plus_years => 2,
  );


my $ds3 = HTML::Menu::DateTime->new ('2001-01-01');

my $ds4 = HTML::Menu::DateTime->new ('2002-02-02 02:02:02');

my $ds5 = HTML::Menu::DateTime->new ('03:03:03');

my $ds6 = HTML::Menu::DateTime->new ('2004');

my $ds7 = HTML::Menu::DateTime->new ('200501');

my $ds8 = HTML::Menu::DateTime->new ('20060202');

my $ds9 = HTML::Menu::DateTime->new ('2007030303');

my $ds10 = HTML::Menu::DateTime->new ('200804040404');

###

my ($d1, $m1, $y1) = ($ds1->day_menu, $ds1->month_menu, $ds1->year_menu);

my ($s2, $mi2, $h2, $d2, $mo2, $y2) = ($ds2->second_menu,
                                       $ds2->minute_menu,
                                       $ds2->hour_menu,
                                       $ds2->day_menu, 
                                       $ds2->month_menu, 
                                       $ds2->year_menu);

my ($d3, $m3, $y3) = ( $ds3->day_menu, $ds3->month_menu, $ds3->year_menu);

my ($s4, $mi4, $h4, $d4, $mo4, $y4) = ($ds4->second_menu,
                                       $ds4->minute_menu,
                                       $ds4->hour_menu,
                                       $ds4->day_menu, 
                                       $ds4->month_menu, 
                                       $ds4->year_menu);

my ($s5, $m5, $h5) = ( $ds5->second_menu, $ds5->minute_menu, $ds5->hour_menu);

my $y6 = $ds6->year_menu;

my ($m7, $y7) = ( $ds7->month_menu, $ds7->year_menu);

my ($d8, $m8, $y8) = ( $ds8->day_menu, $ds8->month_menu, $ds8->year_menu);

my ($h9, $d9, $m9, $y9) = ($ds9->hour_menu,
                           $ds9->day_menu, 
                           $ds9->month_menu, 
                           $ds9->year_menu);

my ($mi10, $h10, $d10, $mo10, $y10) = ($ds10->minute_menu,
                                       $ds10->hour_menu,
                                       $ds10->day_menu, 
                                       $ds10->month_menu, 
                                       $ds10->year_menu);

###

ok( @{$y1} == 3 , 'correct number of years');

ok( defined $d1->[3]{'selected'}, 'correct day selected');
ok( defined $m1->[11]{'selected'}, 'correct month selected');
ok( defined $y1->[1]{'selected'}, 'correct year selected');

ok( $y1->[0]->{'value'} == 1975 , 'correct year value');
ok( $y1->[1]->{'value'} == 1976 , 'correct year value');
ok( $y1->[2]->{'value'} == 1977 , 'correct year value');

###

ok( @{$y2} == 5 , 'correct number of years');

ok( defined $s2->[1]{'selected'}, 'correct second selected');
ok( defined $mi2->[1]{'selected'}, 'correct minute selected');
ok( defined $h2->[1]{'selected'}, 'correct hour selected');
ok( defined $d2->[0]{'selected'}, 'correct day selected');
ok( defined $mo2->[3]{'selected'}, 'correct month selected');
ok( defined $y2->[2]{'selected'}, 'correct year selected');

ok( $y2->[0]->{'value'} == 1976 , 'correct year value');
ok( $y2->[2]->{'value'} == 1978 , 'correct year value');
ok( $y2->[4]->{'value'} == 1980 , 'correct year value');


###

ok( @{$y3} == 11 , 'correct number of years');

ok( defined $d3->[0]{'selected'}, 'correct day selected');
ok( defined $m3->[0]{'selected'}, 'correct month selected');
ok( defined $y3->[5]{'selected'}, 'correct year selected');

ok( $y3->[5]->{'value'} == 2001 , 'correct year value');


###

ok( @{$y4} == 11 , 'correct number of years');

ok( defined $s4->[2]{'selected'}, 'correct second selected');
ok( defined $mi4->[2]{'selected'}, 'correct minute selected');
ok( defined $h4->[2]{'selected'}, 'correct hour selected');
ok( defined $d4->[1]{'selected'}, 'correct day selected');
ok( defined $mo4->[1]{'selected'}, 'correct month selected');
ok( defined $y4->[5]{'selected'}, 'correct year selected');

ok( $y4->[5]->{'value'} == 2002 , 'correct year value');


###

ok( defined $s5->[3]{'selected'}, 'correct second selected');
ok( defined $m5->[3]{'selected'}, 'correct minute selected');
ok( defined $h5->[3]{'selected'}, 'correct hour selected');


###

ok( @{$y6} == 11 , 'correct number of years');

ok( defined $y6->[5]{'selected'}, 'correct year selected');

ok( $y6->[5]->{'value'} == 2004 , 'correct year value');


###

ok( @{$y7} == 11 , 'correct number of years');

ok( defined $m7->[0]{'selected'}, 'correct month selected');
ok( defined $y7->[5]{'selected'}, 'correct year selected');

ok( $y7->[5]->{'value'} == 2005 , 'correct year value');


###

ok( @{$y8} == 11 , 'correct number of years');

ok( defined $d8->[1]{'selected'}, 'correct day selected');
ok( defined $m8->[1]{'selected'}, 'correct month selected');
ok( defined $y8->[5]{'selected'}, 'correct year selected');

ok( $y8->[5]->{'value'} == 2006 , 'correct year value');


###

ok( @{$y9} == 11 , 'correct number of years');

ok( defined $h9->[3]{'selected'}, 'correct hour selected');
ok( defined $d9->[2]{'selected'}, 'correct day selected');
ok( defined $m9->[2]{'selected'}, 'correct month selected');
ok( defined $y9->[5]{'selected'}, 'correct year selected');

ok( $y9->[5]->{'value'} == 2007 , 'correct year value');


###

ok( @{$y10} == 11 , 'correct number of years');

ok( defined $mi10->[4]{'selected'}, 'correct minute selected');
ok( defined $h10->[4]{'selected'}, 'correct hour selected');
ok( defined $d10->[3]{'selected'}, 'correct day selected');
ok( defined $mo10->[3]{'selected'}, 'correct month selected');
ok( defined $y10->[5]{'selected'}, 'correct year selected');

ok( $y10->[5]->{'value'} == 2008 , 'correct year value');





