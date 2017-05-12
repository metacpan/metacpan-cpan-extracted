#!/usr/bin/perl -w

# REQUIRES: Gnome Gtk
# TITLE: gnome-conf

use Gnome;

foreach my $prefix (qw(/panel)) {
	foreach my $s (Gnome::Config->sections($prefix)) {
		print "GOT section $s in prefix $prefix\n";
		my %values = Gnome::Config->section_contents("$prefix/$s");
		foreach (sort keys %values) {
			print "\t $_ -> $values{$_}\n";
		}
	}
}
my $val = Gnome::Config->get_int("/panel/Config/minimize_delay");
print "minimize_delay is $val\n";
Gnome::Config->set_int("/panel/Config/minimize_delay", $val+50);
Gnome::Config->sync;
my $newval = Gnome::Config->get_int("/panel/Config/minimize_delay");
print "minimize_delay is now $newval\n";
Gnome::Config->set_int("/panel/Config/minimize_delay", $val);
Gnome::Config->sync;
$newval = Gnome::Config->get_int("/panel/Config/minimize_delay");
die "Uhm: $newval != $val\n" unless $val == $newval;
print "minimize_delay set back to $val\n";
