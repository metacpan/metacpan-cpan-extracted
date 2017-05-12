use strict;
use Test::More tests => 11;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds1 = HTML::Menu::DateTime->new (
  date       => '0998-01-01',
  less_years => 1,
  plus_years => 1,
  );

my $ds2 = HTML::Menu::DateTime->new (
  date       => '09990101010101',
  less_years => 1,
  plus_years => 1,
  );

my $y1 = $ds1->year_menu;
my $y2 = $ds2->year_menu;


ok( @{$y1} == 3 , 'correct number of years');

ok( $y1->[0]->{'value'} == (997) , 'correct year value');
ok( $y1->[1]->{'value'} == (998) , 'correct year value');
ok( $y1->[2]->{'value'} == (999) , 'correct year value');

ok( defined $y1->[1]{'selected'}, 'correct year selected');


ok( @{$y2} == 3 , 'correct number of years');

ok( $y2->[0]->{'value'} == (998) , 'correct year value');
ok( $y2->[1]->{'value'} == (999) , 'correct year value');
ok( $y2->[2]->{'value'} == (1000) , 'correct year value');

ok( defined $y2->[1]{'selected'}, 'correct year selected');

