use strict;
use Test::More tests => 4;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}


eval {
  my $dt = HTML::Menu::DateTime->new;
  
  $dt->year_menu('a');
};


ok( $@ , "correctly dies on invalid input 'a'");


eval {
  my $dt = HTML::Menu::DateTime->new( '20051031114500' );
  
  $dt->start_year( 2002 );
  
  $dt->plus_years( 10 );
  
  $dt->year_menu([2005, 1995]);
};


ok( $@ , "correctly dies on out-of-bounds multiple select");


eval {
  my $dt = HTML::Menu::DateTime->new;
  
  $dt->dont_exist();
};


ok( $@ , "correctly dies on unknown method");

