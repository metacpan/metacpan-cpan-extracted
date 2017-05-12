use strict;
use Test::More tests => 16;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

my $ds1 = HTML::Menu::DateTime->new;

my $ds2 = HTML::Menu::DateTime->new (
  month_format => 'decimal',
  );

my $ds3 = HTML::Menu::DateTime->new (
  month_format => 'short',
  );

my $mo1 = $ds1->month_menu;
my $mo2 = $ds2->month_menu;
my $mo3 = $ds3->month_menu;

ok( ${$mo1}[0]->{label} eq 'January' , 'correct month label');
ok( ${$mo2}[0]->{label} eq '01' ,      'correct month label');
ok( ${$mo3}[0]->{label} eq 'Jan' ,     'correct month label');

ok( $ds1->month_format() eq 'long',    'month_format getter ok');
ok( $ds2->month_format() eq 'decimal', 'month_format getter ok');
ok( $ds3->month_format() eq 'short',   'month_format getter ok');

$ds1->month_format('decimal');
$ds2->month_format('long');
$ds3->month_format('long');

my $mo5 = $ds1->month_menu;
my $mo6 = $ds2->month_menu;
my $mo7 = $ds3->month_menu;

ok( ${$mo5}[1]->{label} eq '02' ,       'correct month label');
ok( ${$mo6}[1]->{label} eq 'February' , 'correct month label');
ok( ${$mo7}[2]->{label} eq 'March'    , 'correct month label');

ok( $ds1->month_format() eq 'decimal', 'month_format getter ok');
ok( $ds2->month_format() eq 'long',    'month_format getter ok');
ok( $ds3->month_format() eq 'long',    'month_format getter ok');

ok( $ds1->month_format() eq 'decimal', "month_format getter with no args doesn't reset to default");
ok( $ds2->month_format() eq 'long',    "month_format getter with no args doesn't reset to default");
ok( $ds3->month_format() eq 'long',    "month_format getter with no args doesn't reset to default");

