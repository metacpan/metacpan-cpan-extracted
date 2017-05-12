use strict;
use Test::More tests => 5;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new;

$ds->less_years (2);
$ds->plus_years (0);

my $y = $ds->year_menu (1976);


ok( @{$y} == 3 , 'correct number of years');

ok( $y->[0]->{'value'} == (1974) , 'correct year value');
ok( $y->[2]->{'value'} == (1976) , 'correct year value');

ok( defined $y->[2]{'selected'}, 'correct year selected');

