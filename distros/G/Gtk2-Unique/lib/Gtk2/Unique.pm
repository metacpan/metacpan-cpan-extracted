package Gtk2::Unique;

=head1 NAME

Gtk2::Unique - Use single instance applications

=head1 SYNOPSIS

	use Gtk2 '-init';
	use Gtk2::Unique;
	
	my $COMMAND_FOO = 1;
	my $COMMAND_BAR = 2;
	
	my $app = Gtk2::UniqueApp->new(
		"org.example.UnitTets", undef,
		foo => $COMMAND_FOO,
		bar => $COMMAND_BAR,
	);
	
	
	if ($app->is_running) {
		# The application is already running, send it a message
		my ($text) = @ARGV ? @ARGV : ("Foo text here");
		$app->send_message_by_name('foo', text => $text);
	}
	else {
		# Create the single application instance and wait for other requests
		my $window = create_application_window($app);
		Gtk2->main();
	}
	
	
	sub create_application_window {
		my ($app) = @_;
		
		my $window = Gtk2::Window->new();
		my $label = Gtk2::Label->new("Waiting for a message");
		$window->add($label);
		$window->set_size_request(480, 120);
		$window->show_all();
		
		$window->signal_connect(delete_event => sub {
			Gtk2->main_quit();
			return TRUE;
		});
		
		# Watch the main window and register a handler that will be called each time
		# that there's a new message.
		$app->watch_window($window);
		$app->signal_connect('message-received' => sub {
			my ($app, $command, $message, $time) = @_;
			$label->set_text($message->get_text);
			return 'ok';
		});
	}

=head1 DESCRIPTION

Gtk2::Unique is a Perl binding for the C library libunique which provides a
way for writing single instance application. If you launch a single instance
application twice, the second instance will either just quit or will send a
message to the running instance.

For more information about libunique see:
L<http://live.gnome.org/LibUnique>.

=head1 BUGS & API

This is the first release of the module, some bugs can be expected to be found.
Furthermore, the Perl API is not yet frozen, if you would like to suggest some
changes please do so as fast as possible.

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use warnings;
use strict;
use base 'DynaLoader';

use Gtk2;

our $VERSION = '0.05';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

