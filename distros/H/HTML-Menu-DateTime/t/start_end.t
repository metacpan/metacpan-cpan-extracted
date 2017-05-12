use strict;
use Test::More tests => 16;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new (
  start_year => 1975,
  end_year   => 1977,
  );


my $y1 = $ds->year_menu (1975);
my $y2 = $ds->year_menu (1976);
my $y3 = $ds->year_menu (1977);


ok( @{$y1} == 3 , 'correct number of years');
ok( @{$y2} == 3 , 'correct number of years');
ok( @{$y3} == 3 , 'correct number of years');

ok( defined $y1->[0]{'selected'}, 'correct year selected');
ok( defined $y2->[1]{'selected'}, 'correct year selected');
ok( defined $y3->[2]{'selected'}, 'correct year selected');

ok( $y1->[0]->{'value'} == 1975 , 'correct year value');
ok( $y1->[1]->{'value'} == 1976 , 'correct year value');
ok( $y1->[2]->{'value'} == 1977 , 'correct year value');

ok( $y2->[0]->{'value'} == 1975 , 'correct year value');
ok( $y2->[1]->{'value'} == 1976 , 'correct year value');
ok( $y2->[2]->{'value'} == 1977 , 'correct year value');

ok( $y3->[0]->{'value'} == 1975 , 'correct year value');
ok( $y3->[1]->{'value'} == 1976 , 'correct year value');
ok( $y3->[2]->{'value'} == 1977 , 'correct year value');

