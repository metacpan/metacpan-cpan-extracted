use strict;
use Test::More tests => 20;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds = HTML::Menu::DateTime->new (
  minute_increment => 30,
  );


my $m1 = $ds->minute_menu;

ok( @$m1 == 2 , 'correct number of minutes');
ok( ${$m1}[0]->{label} eq '00' , 'correct minute label');
ok( ${$m1}[1]->{label} eq '30' , 'correct minute label');

ok( $ds->minute_increment() eq 30, 'minute_increment getter ok');


$ds->minute_increment (5);

my $m2 = $ds->minute_menu;

ok( @$m2 == 12 , 'correct number of minutes');
ok( ${$m2}[0]->{label} eq '00' , 'correct minute label');
ok( ${$m2}[11]->{label} eq '55' , 'correct minute label');

ok( $ds->minute_increment() eq 5, 'minute_increment getter ok');


$ds->minute_increment (10);

my $m3 = $ds->minute_menu;

ok( @$m3 == 6 , 'correct number of minutes');
ok( ${$m3}[0]->{label} eq '00' , 'correct minute label');
ok( ${$m3}[5]->{label} eq '50' , 'correct minute label');

ok( $ds->minute_increment() eq 10, 'minute_increment getter ok');


$ds->minute_increment (15);

my $m4 = $ds->minute_menu;

ok( @$m4 == 4 , 'correct number of minutes');
ok( ${$m4}[0]->{label} eq '00' , 'correct minute label');
ok( ${$m4}[3]->{label} eq '45' , 'correct minute label');

ok( $ds->minute_increment() eq 15, 'minute_increment getter ok');
ok( $ds->minute_increment() eq 15, "minute_increment getter with no args doesn't reset to default");


eval {
  my $dt = HTML::Menu::DateTime->new;
  
  $dt->minute_increment(0);
  
  $dt->minute_menu;
};


ok( $@ , "correctly dies on invalid input '0'");


eval {
  my $dt = HTML::Menu::DateTime->new;
  
  $dt->minute_increment(60);
  
  $dt->minute_menu;
};


ok( $@ , "correctly dies on invalid input '60'");

