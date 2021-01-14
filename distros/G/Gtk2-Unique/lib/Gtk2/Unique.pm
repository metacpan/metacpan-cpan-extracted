package Gtk2::Unique;

=head1 NAME

Gtk2::Unique - (DEPRECATED) Use single instance applications

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

=head1 ABSTRACT

B<DEPRECATED> Perl bindings for the C library 'libunique'

=head1 DESCRIPTION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-unique

=item *

Upstream URL: https://gitlab.gnome.org/Archive/unique

=item *

Last upstream version: 1.1.6

=item *

Last upstream release date: 2009-11-12

=item *

Migration path for this module: Gtk3::Application

=item *

Migration module URL: https://metacpan.org/pod/Gtk3

=back

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

Copyright (C) 2009-2017 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use warnings;
use strict;
use base 'DynaLoader';

use Gtk2;

our $VERSION = '0.07';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

