use Gtk2::TestHelper tests => 22;

no warnings;

BEGIN { use_ok('Gtk2::Phat'); }

my $adjustment = Gtk2::Adjustment->new(0, -300, 300, 5, 10, 10);

my @sliders;
push @sliders, Gtk2::Phat::VFanSlider->new_with_range(0, -100, 100, 1);
push @sliders, Gtk2::Phat::HFanSlider->new_with_range(0, -100, 100, 1);
push @sliders, Gtk2::Phat::VFanSlider->new($adjustment);
push @sliders, Gtk2::Phat::HFanSlider->new($adjustment);

is( @sliders, 4, 'constructors 1' );

for my $slider (@sliders) {
	$slider->set_value(43);
	is( $slider->get_value(), 43, 'set/get value' );

	$slider->set_range(-200, 200);
	ok( $slider->get_range() == (-200, 200), 'set/get range' );

	my $adj = Gtk2::Adjustment->new(0, -10, 10, 1, 2, 2);
	$slider->set_adjustment($adj);
	ok( $slider->get_adjustment() == $adj, 'set/get adjustment' );

	$slider->set_inverted(TRUE);
	is( $slider->get_inverted(), TRUE, 'set/get inverted 1' );
	$slider->set_inverted(FALSE);
	is( $slider->get_inverted(), FALSE, 'set/get inverted 2' );
}
