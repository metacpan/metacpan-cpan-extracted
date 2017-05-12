use strict;
use Test::More tests => 5;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new;

$ds->less_years (0);
$ds->plus_years (2);

my $y = $ds->year_menu (1976);


ok( @{$y} == 3 , 'correct number of years');

ok( $y->[0]->{'value'} == (1976) , 'correct year value');
ok( $y->[2]->{'value'} == (1978) , 'correct year value');

ok( defined $y->[0]{'selected'}, 'correct year selected');

