# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..48\n"; }
END {print "not ok 1\n" unless $loaded;}
use LEGO::Color;
use LEGO::Colors;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

# Test basic color getting
my $green = LEGO::Colors->get_color('green');
ok( defined($green),                2);
ok( $green->get_name()  eq 'Green', 3);
ok( $green->get_red()   == 0,       4);
ok( $green->get_green() == 130,     5);
ok( $green->get_blue()  == 74,      6);

# Test whitespace / cap normalization
my $pearl = LEGO::Colors->get_color('pEa rLLi ghT G Ray');
ok( defined($pearl),                           7);
ok( $pearl->get_name()  eq 'Pearl Light Gray', 8);
ok( $pearl->get_red()   == 135,                9);
ok( $pearl->get_green() == 135,                10);
ok( $pearl->get_blue()  == 133,                11);

# Testing failure return status
my $undef = LEGO::Colors->get_color('plop');
ok(!defined($undef), 12);

# Testing default system
my $red = LEGO::Colors->get_color(
	name     => 'red',
	'system' => 'default',
);
ok( defined($red),              13);
ok( $red->get_name()  eq 'Red', 14);
ok( $red->get_red()   == 189,   15);
ok( $red->get_green() == 56,    16);
ok( $red->get_blue()  == 38,    17);

# Testing peeron system
my $gray = LEGO::Colors->get_color(
	name     => 'grAy',
	'system' => 'peeron',
);
ok( defined($gray),                     18);
ok( $gray->get_name()  eq 'Light Gray', 19);
ok( $gray->get_red()   == 163,          20);
ok( $gray->get_green() == 161,          21);
ok( $gray->get_blue()  == 153,          22);

# Testing Bricklink system
my $lime = LEGO::Colors->get_color(
	name     => 'Li ME ',
	'system' => ' Br icKl INk',
);
ok( defined($lime),                     23);
ok( $lime->get_name()  eq 'Lime Green', 24);
ok( $lime->get_red()   == 158,          25);
ok( $lime->get_green() == 171,          26);
ok( $lime->get_blue()  == 5,            27);

# Testing color name inheritance
$red = LEGO::Colors->get_color(
	name     => 'darkred',
	'system' => 'bricklink',
);
ok( defined($red),                   28);
ok( $red->get_name()  eq 'Dark Red', 29);
ok( $red->get_red()   == 133,        30);
ok( $red->get_green() == 54,         31);
ok( $red->get_blue()  == 15,         32);

# Testing system name listing
my @systems = LEGO::Colors->get_all_system_names();
ok( @systems == 2,              33);
ok( $systems[0] eq 'Bricklink', 34);
ok( $systems[1] eq 'Peeron',    35);

# Testing default name mapping
my %default_names = LEGO::Colors->get_color_names_for_system();
ok( keys(%default_names) == 28,                   36);
ok( $default_names{'Purple'}     eq 'Purple',     37);
ok( $default_names{'Light Gray'} eq 'Light Gray', 38);

# Testing peeron name mapping
my %peeron_names = LEGO::Colors->get_color_names_for_system(
	'system' => 'peeRon',
);
ok( keys(%peeron_names) == 28,               39);
ok( $peeron_names{'Purple'}     eq 'Purple', 40);
ok( $peeron_names{'Light Gray'} eq 'Gray',   41);
ok( $peeron_names{'Dark Pink'}  eq 'DkPink', 42);

# Testing Bricklink name mapping
my %bricklink_names = LEGO::Colors->get_color_names_for_system(
	'system' => 'BRICKLINK',
);
ok( keys(%bricklink_names) == 28,                  43);
ok( $bricklink_names{'Purple'}     eq 'Purple',    44);
ok( $bricklink_names{'Dark Gray'}  eq 'Dark Gray', 45);
ok( $bricklink_names{'Lime Green'} eq 'Lime',      46);

# Test HTML code generation
ok( $green->get_html_code() eq '#00824A', 47);
ok( $red->get_html_code()   eq '#85360F', 48);
