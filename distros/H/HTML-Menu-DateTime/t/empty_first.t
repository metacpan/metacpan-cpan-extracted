use strict;
use Test::More tests => 12;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new (
  date        => '19761204000000',
  start_year  => 1975,
  end_year    => 1977,
  empty_first => 1,
  );


my ($s, $mi, $h, $d, $mo, $y) = ($ds->second_menu,
                                 $ds->minute_menu,
                                 $ds->hour_menu,
                                 $ds->day_menu, 
                                 $ds->month_menu, 
                                 $ds->year_menu);


ok( @{$y} == 4 , 'correct number of years');

ok( defined $s->[1]{'selected'}, 'correct second selected');
ok( defined $mi->[1]{'selected'}, 'correct minute selected');
ok( defined $h->[1]{'selected'}, 'correct hour selected');
ok( defined $d->[4]{'selected'}, 'correct day selected');
ok( defined $mo->[12]{'selected'}, 'correct month selected');
ok( defined $y->[2]{'selected'}, 'correct year selected');

is( $y->[0]->{'value'}, '' , 'correct year value');
is( $y->[1]->{'value'}, 1975 , 'correct year value');
is( $y->[2]->{'value'}, 1976 , 'correct year value');
is( $y->[3]->{'value'}, 1977 , 'correct year value');

