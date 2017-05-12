use strict;
use constant TEST_COUNT => 19;
use Test::More tests => TEST_COUNT;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

SKIP: {
  eval { require DateTime::Locale };
  
  skip("DateTime::Locale not installed", TEST_COUNT-1) if $@;
  
  my $ds1 = HTML::Menu::DateTime->new (
    locale => 'en_BG',
    );
  
  my $ds2 = HTML::Menu::DateTime->new (
    month_format => 'decimal',
    locale       => 'en_BG',
    );
  
  my $ds3 = HTML::Menu::DateTime->new (
    month_format => 'short',
    locale       => 'en_BG',
    );
  
  my $mo2 = $ds1->month_menu;
  my $mo3 = $ds2->month_menu;
  my $mo4 = $ds3->month_menu;
  
  ok( ${$mo2}[0]->{label} eq 'January', 'correct month label');
  ok( ${$mo3}[0]->{label} eq '01',      'correct month label');
  ok( ${$mo4}[0]->{label} eq 'Jan',     'correct month label');
  
  $ds1->month_format('decimal');
  $ds2->month_format('long');
  $ds3->month_format('long');
  
  my $mo5 = $ds1->month_menu;
  my $mo6 = $ds2->month_menu;
  my $mo7 = $ds3->month_menu;
  
  ok( ${$mo5}[1]->{label} eq '02',       'correct month label');
  ok( ${$mo6}[1]->{label} eq 'February', 'correct month label');
  ok( ${$mo7}[2]->{label} eq 'March',    'correct month label');
  
  ok( $ds1->locale() eq 'en_BG', 'locale getter ok');
  ok( $ds2->locale() eq 'en_BG', 'locale getter ok');
  ok( $ds3->locale() eq 'en_BG', 'locale getter ok');
  
  
  # change locale
  $ds1->locale('de');
  $ds2->locale('de');
  $ds3->locale('de');
  
  $ds3->month_format('short');
  
  my $mo8  = $ds1->month_menu;
  my $mo9  = $ds2->month_menu;
  my $mo10 = $ds3->month_menu;
  
  ok( ${$mo8}[0]->{label} eq '01',     'correct month label');
  ok( ${$mo9}[0]->{label} eq 'Januar', 'correct month label');
  ok( ${$mo10}[2]->{label} eq 'Mrz',   'correct month label');
  
  ok( $ds1->locale() eq 'de', 'locale getter ok');
  ok( $ds2->locale() eq 'de', 'locale getter ok');
  ok( $ds3->locale() eq 'de', 'locale getter ok');
  
  ok( $ds1->locale() eq 'de', "locale getter with no args doesn't reset to default");
  ok( $ds2->locale() eq 'de', "locale getter with no args doesn't reset to default");
  ok( $ds3->locale() eq 'de', "locale getter with no args doesn't reset to default");
}
