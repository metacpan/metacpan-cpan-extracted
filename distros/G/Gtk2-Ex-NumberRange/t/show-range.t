use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Ex::NumberRange;

use Gtk2::TestHelper tests => 74;

my $numberrange = Gtk2::Ex::NumberRange->new;
isa_ok($numberrange, "Gtk2::Ex::NumberRange");
my $changed = 0;
$numberrange->signal_connect('changed' =>
	sub {
		$changed++;
		print Dumper "here\n";
	}
);
ok(!$numberrange->get_model);

$numberrange->set_model(undef);
is($changed, 1);
ok(!$numberrange->get_model);

$numberrange->set_model([ '>', '100', 'and', '<', '179' ]);
is($changed, 2);
is (Dumper($numberrange->get_model), Dumper([ '>', '100', 'and', '<', '179' ]));

$numberrange->set_model(undef);
is($changed, 3);
ok(!$numberrange->get_model);

$numberrange->set_model([ '>', '100']);
is($changed, 4);
is (Dumper($numberrange->get_model), Dumper(['>', '100']));

$numberrange->set_model(undef);
is($changed, 5);
ok(!$numberrange->get_model);

ok($numberrange->{widget});

# Let us start poking inside the widget
$numberrange->set_model([ '>', '100', 'and', '<', '179' ]);
is($changed, 6);
is (Dumper($numberrange->get_model), Dumper(['>', '100', 'and', '<', '179']));

$numberrange->{joinercombo}->set_active(2);
is($changed, 7);
is(Dumper($numberrange->get_model), Dumper([ '>', '100', 'or', '<', '179' ]));

$numberrange->{joinercombo}->set_active(1);
is($changed, 8);
is(Dumper($numberrange->get_model), Dumper([ '>', '100', 'and', '<', '179' ]));

$numberrange->{joinercombo}->set_active(0);
is($changed, 9);
is(Dumper($numberrange->get_model), Dumper([ '>', '100']));

$numberrange->{joinercombo}->set_active(1);
is($changed, 10);
is(Dumper($numberrange->get_model), Dumper([ '>', '100', 'and', '<', '179']));

$numberrange->{joinercombo}->set_active(2);
is($changed, 11);
is(Dumper($numberrange->get_model), Dumper([ '>', '100', 'or', '<', '179']));

$numberrange->{joinercombo}->set_active(0);
is($changed, 12);
is(Dumper($numberrange->get_model), Dumper([ '>', '100']));

my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });
$window->signal_connect('realize' => \&visible_tests);
$window->add($numberrange->{widget});
$window->show_all;


sub visible_tests {
	full_model();
	half_model();
	incremental_1();
	incremental_2();
	$numberrange->set_model([ '>', '100']);
	is($changed, 22);
	is (Dumper($numberrange->get_model), Dumper([ '>', '100']));
}

sub full_model {
	$numberrange->set_model([ '>', '100', 'and', '<', '179' ]);
	is($changed, 13);
	is (Dumper($numberrange->get_model), Dumper(['>', '100', 'and', '<', '179']));
	

	ok ($numberrange->{commandcombo1}->get('visible'));
	ok ($numberrange->{entry1}->get('visible'));

	ok ($numberrange->{joinercombo}->get('visible'));
	
	ok ($numberrange->{commandcombo2}->get('visible'));
	ok ($numberrange->{entry2}->get('visible'));

	ok ($numberrange->{commandcombo1}->get('sensitive'));
	ok ($numberrange->{entry1}->get('sensitive'));

	ok ($numberrange->{joinercombo}->get('sensitive'));
	
	ok ($numberrange->{commandcombo2}->get('sensitive'));
	ok ($numberrange->{entry2}->get('sensitive'));
	return 0;
}

sub half_model {
	$numberrange->set_model([ '>', '100']);
	is($changed, 14);
	is (Dumper($numberrange->get_model), Dumper(['>', '100']));
	
	ok ($numberrange->{commandcombo1}->get('visible'));
	ok ($numberrange->{entry1}->get('visible'));
	
	ok ($numberrange->{joinercombo}->get('visible'));
	
	ok (!$numberrange->{commandcombo2}->get('visible'));
	ok (!$numberrange->{entry2}->get('visible'));
	
	ok ($numberrange->{commandcombo1}->get('sensitive'));
	ok ($numberrange->{entry1}->get('sensitive'));
	
	ok ($numberrange->{joinercombo}->get('sensitive'));
	
	ok ($numberrange->{commandcombo2}->get('sensitive'));
	ok ($numberrange->{entry2}->get('sensitive'));
}

sub incremental_1 {
	$numberrange->set_model(undef);
	is($changed, 15);

	ok ($numberrange->{commandcombo1}->get('visible'));
	ok ($numberrange->{entry1}->get('visible'));
	
	ok ($numberrange->{joinercombo}->get('visible'));
	
	ok (!$numberrange->{commandcombo2}->get('visible'));
	ok (!$numberrange->{entry2}->get('visible'));
	
	ok ($numberrange->{commandcombo1}->get('sensitive'));
	ok (!$numberrange->{entry1}->get('sensitive'));
	
	ok (!$numberrange->{joinercombo}->get('sensitive'));

	ok(!$numberrange->get_model);
	$numberrange->{commandcombo1}->set_active(0);
	is($changed, 16);
	is (Dumper($numberrange->get_model), Dumper(['>']));

	$numberrange->{commandcombo1}->set_active(1);
	is($changed, 17);
	is (Dumper($numberrange->get_model), Dumper(['>=']));

	$numberrange->{commandcombo1}->set_active(2);
	is($changed, 18);
	is (Dumper($numberrange->get_model), Dumper(['=']));

	$numberrange->{commandcombo1}->set_active(3);
	is($changed, 19);
	is (Dumper($numberrange->get_model), Dumper(['<=']));

	$numberrange->{commandcombo1}->set_active(4);
	is($changed, 20);
	is (Dumper($numberrange->get_model), Dumper(['<']));
}

sub incremental_2 {
	$numberrange->{commandcombo1}->set_active(0);
	is($changed, 21);
}