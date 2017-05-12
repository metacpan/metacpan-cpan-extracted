use Gtk2::TestHelper tests => 11;

no warnings;

BEGIN { use_ok('Gtk2::Phat'); }

ok( my $b = Gtk2::Phat::SliderButton->new_with_range(5, 0, 10, 1, "%d"), 'constructor 1' );

my $adj = Gtk2::Adjustment->new(5, 0, 10, 1, 2, 2);
ok( $b = Gtk2::Phat::SliderButton->new($adj, "%d"), 'constructor 2' );

$b->set_value(3);
is( $b->get_value(), 3, 'set/get value' );

$b->set_range(-5, 5);
ok( $b->get_range() == (-5, 5), 'set/get range' );

my $adj2 = Gtk2::Adjustment->new(0, -20, 20, 1, 2, 3);
$b->set_adjustment($adj2);
ok( $b->get_adjustment() == $adj2, 'set/get adjustment' );

$b->set_increment(4, 10);
ok( (4, 10) == $b->get_increment(), 'set/get increment' );

$b->set_format(1, 'prefix', 'postfix');
my @format = $b->get_format();
is($format[0], 1, 'set/get format');
is($format[1], 'prefix', 'set/get format');
is($format[2], 'postfix', 'set/get format');

$b->set_threshold(10);
is( $b->get_threshold(), 10, 'set/get threshold' );
