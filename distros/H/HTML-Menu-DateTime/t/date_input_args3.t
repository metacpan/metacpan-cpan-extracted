use strict;
use Test::More tests => 10;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}


eval {
  my $dt = HTML::Menu::DateTime->new('0000-05-25');
  
  $dt->year_menu;
};

ok( $@ , "correctly dies on invalid year '0000'");


eval {
  my $dt = HTML::Menu::DateTime->new;
  
  $dt->year_menu(0);
};

ok( $@ , "correctly dies on invalid year '0'");


eval {
  HTML::Menu::DateTime->new('2005-5-24');
};

ok( $@ , 'correctly dies on incorrect date');


eval {
  my $dt = HTML::Menu::DateTime->new(
    date       => '2005-05-24',
    start_year => 2006,
    );
  
  $dt->year_menu;
};

ok( $@ , "correctly dies on start_year after selected year");


eval {
  my $dt = HTML::Menu::DateTime->new(
    date     => '2020-05-24',
    end_year => 2010,
    );
  
  $dt->year_menu;
};

ok( $@ , "correctly dies on end_year before selected year");


eval {
  my $dt = HTML::Menu::DateTime->new(
    date       => '2005-05-24',
    less_years => 5,
    );
  
  $dt->year_menu([2003, 2005]);
};

ok( $@ , "correctly dies on less_years with multiple select");


eval {
  my $dt = HTML::Menu::DateTime->new(
    date       => '2005-05-24',
    plus_years => 5,
    );
  
  $dt->year_menu([2005, 2007]);
};

ok( $@ , "correctly dies on plus_years with multiple select");


eval {
  my $dt = HTML::Menu::DateTime->new(
    date       => '0001-05-24',
    less_years => 2,
    );
  
  $dt->year_menu;
};

ok( $@ , "correctly dies on start year not >= 0");


eval {
  my $dt = HTML::Menu::DateTime->new(
    start_year => 2005,
    end_year   => 2004,
    );
  
  $dt->year_menu;
};

ok( $@ , "correctly dies on end_year before start_year");

