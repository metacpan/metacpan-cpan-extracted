#!/usr/bin/perl -w
use Gtk '-init';

$data = "Initial val";

Gtk->watch_add($data, 0, sub {
	print "\$data changed to '$_[0]'\n";
	Gtk->main_quit if $data eq 'quit';
	# get some noise
	$data = 'jumpy' unless $data eq 'jumpy';
	1;
});
# has a highter priority and gets called first
Gtk->watch_add($data, -100, sub {
	print "Another change handler for \$data\n";
});
{	
	@data2 = (1);
	my $id;
	$id = Gtk->watch_add($data2[0], 0, sub {
		print "\$data2 changed to $data2[0]\n";
		Gtk->watch_remove($id);
		1;
	});
	# try to be evil
	# undef @data2;
}
Gtk->timeout_add(250, sub {$data = "Yadda yadda";$data2[0]++;1});
Gtk->timeout_add(400, sub {$data = "Yappa yappa";0});
Gtk->timeout_add(600, sub {$data = "quit";0});

main Gtk;

