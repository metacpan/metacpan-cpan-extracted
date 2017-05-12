use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Ex::DateRange;

use Gtk2::TestHelper tests => 76;

my $daterange = Gtk2::Ex::DateRange->new;
isa_ok($daterange, "Gtk2::Ex::DateRange");
my $changed = 0;
$daterange->signal_connect('changed' =>
	sub {
		$changed++;
		print Dumper "here\n";
	}
);
ok(!$daterange->get_model);

$daterange->set_model(undef);
is($changed, 1);
ok(!$daterange->get_model);

$daterange->set_model([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]);
is($changed, 2);
is (Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]));

$daterange->set_model(undef);
is($changed, 3);
ok(!$daterange->get_model);

$daterange->set_model([ 'after', '1965-03-12']);
is($changed, 4);
is (Dumper($daterange->get_model), Dumper(['after', '1965-03-12']));

$daterange->set_model(undef);
is($changed, 5);
ok(!$daterange->get_model);

ok($daterange->{widget});

# Let us start poking inside the widget
$daterange->set_model([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]);
is($changed, 6);
is (Dumper($daterange->get_model), Dumper(['after', '1965-03-12', 'and', 'before', '1989-02-14']));

$daterange->{joinercombo}->set_active(2);
is($changed, 7);
is(Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12', 'or', 'before', '1989-02-14' ]));

$daterange->{joinercombo}->set_active(1);
is($changed, 8);
is(Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]));

$daterange->{joinercombo}->set_active(0);
is($changed, 9);
is(Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12']));

$daterange->{joinercombo}->set_active(1);
is($changed, 10);
is(Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12', 'and']));

$daterange->{joinercombo}->set_active(2);
is($changed, 11);
is(Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12', 'or']));

$daterange->{joinercombo}->set_active(0);
is($changed, 12);
is(Dumper($daterange->get_model), Dumper([ 'after', '1965-03-12']));

my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });
$window->signal_connect('realize' => \&visible_tests);
$window->add($daterange->{widget});
$window->show_all;


sub visible_tests {
	full_model();
	half_model();
	incremental_1();
	incremental_2();
}

sub full_model {
	$daterange->set_model([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]);
	is($changed, 13);
	is (Dumper($daterange->get_model), Dumper(['after', '1965-03-12', 'and', 'before', '1989-02-14']));
	

	ok ($daterange->{commandcombo1}->get('visible'));
	ok ($daterange->{datelabelbox1}->get('visible'));
	ok (!$daterange->{calendar1}->get('visible'));
	

	ok ($daterange->{joinercombo}->get('visible'));
	

	ok ($daterange->{commandcombo2}->get('visible'));
	ok ($daterange->{datelabelbox2}->get('visible'));
	ok (!$daterange->{calendar2}->get('visible'));
	

	ok ($daterange->{commandcombo1}->get('sensitive'));
	ok ($daterange->{datelabelbox1}->get('sensitive'));
	

	ok ($daterange->{joinercombo}->get('sensitive'));
	

	ok ($daterange->{commandcombo2}->get('sensitive'));
	ok ($daterange->{datelabelbox2}->get('sensitive'));
	return 0;
}

sub half_model {
	$daterange->set_model([ 'after', '1965-03-12']);
	is($changed, 14);
	is (Dumper($daterange->get_model), Dumper(['after', '1965-03-12']));
	
	ok ($daterange->{commandcombo1}->get('visible'));
	ok ($daterange->{datelabelbox1}->get('visible'));
	ok (!$daterange->{calendar1}->get('visible'));
	
	ok ($daterange->{joinercombo}->get('visible'));
	
	ok (!$daterange->{commandcombo2}->get('visible'));
	ok (!$daterange->{datelabelbox2}->get('visible'));
	ok (!$daterange->{calendar2}->get('visible'));
	
	ok ($daterange->{commandcombo1}->get('sensitive'));
	ok ($daterange->{datelabelbox1}->get('sensitive'));
	
	ok ($daterange->{joinercombo}->get('sensitive'));
	
	ok ($daterange->{commandcombo2}->get('sensitive'));
	ok ($daterange->{datelabelbox2}->get('sensitive'));
}

sub incremental_1 {
	$daterange->set_model(undef);
	is($changed, 15);

	ok ($daterange->{commandcombo1}->get('visible'));
	ok ($daterange->{datelabelbox1}->get('visible'));
	ok (!$daterange->{calendar1}->get('visible'));
	
	ok ($daterange->{joinercombo}->get('visible'));
	
	ok (!$daterange->{commandcombo2}->get('visible'));
	ok (!$daterange->{datelabelbox2}->get('visible'));
	ok (!$daterange->{calendar2}->get('visible'));
	
	ok ($daterange->{commandcombo1}->get('sensitive'));
	ok (!$daterange->{datelabelbox1}->get('sensitive'));
	
	ok (!$daterange->{joinercombo}->get('sensitive'));

	ok(!$daterange->get_model);
	$daterange->{commandcombo1}->set_active(0);
	is($changed, 16);
	is (Dumper($daterange->get_model), Dumper(['before']));

	$daterange->{commandcombo1}->set_active(1);
	is($changed, 17);
	is (Dumper($daterange->get_model), Dumper(['after']));

	$daterange->{commandcombo1}->set_active(2);
	is($changed, 18);
	is (Dumper($daterange->get_model), Dumper(['on or after']));

	$daterange->{commandcombo1}->set_active(3);
	is($changed, 19);
	is (Dumper($daterange->get_model), Dumper(['on or before']));
}

sub incremental_2 {
	$daterange->{commandcombo1}->set_active(0);
	is($changed, 20);
}