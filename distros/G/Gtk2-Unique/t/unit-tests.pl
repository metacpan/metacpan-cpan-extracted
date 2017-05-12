#!/usr/bin/perl

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::Unique;
use Data::Dumper;

my $COMMAND_FOO = 1;
my $COMMAND_BAR = 2;


# Use the bacon backend as it is the only that really works with unit tests.
# See t/UniqueApp.t for more details.
local $ENV{UNIQUE_BACKEND} = 'bacon';


exit main();


sub main {
	
	my $app = Gtk2::UniqueApp->new(
		"org.example.UnitTets", undef,
		foo => $COMMAND_FOO,
		bar => $COMMAND_BAR,
	);


	if ($app->is_running) {
		die "Application is already running";
	}


	# Create the single application instance and wait for other requests
	my $window = create_application($app);
	Gtk2->main();
	
	return 0;
}


#
# Called when the application needs to be created. This happens when there's no
# other instance running.
#
sub create_application {
	my ($app) = @_;

	# Standard window and windgets
	my $window = Gtk2::Window->new();
	$window->set_title("Gtk2::Unique - Unit Tests");
	$window->set_size_request(480, 240);
	my $textview = Gtk2::TextView->new();
	my $scroll = Gtk2::ScrolledWindow->new();
	my $buffer = $textview->get_buffer;

	# Widget packing
	$scroll->add($textview);
	$window->add($scroll);
	$window->show_all();

	# Widget signals
	$window->signal_connect(delete_event => sub {
		Gtk2->main_quit();
		return TRUE;
	});

	# Listen for new commands
	$app->watch_window($window);
	$app->signal_connect('message-received' => sub {
		my ($app, $command, $message, $time) = @_;
		
		my $text = Dumper($message->get);
		$buffer->insert($buffer->get_end_iter, "$command: $text\n");
		
		# The command FOO will succeed while the command BAR will fail
		return $command == $COMMAND_FOO ? 'ok' : 'invalid';
	});

	return $window;
}
