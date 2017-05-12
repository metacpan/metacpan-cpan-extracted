# $Id: Carp.pm,v 1.5 2005/09/23 11:02:41 jodrell Exp $
package Gtk2::Ex::Carp;

=pod

=head1 NAME

Gtk2::Ex::Carp - GTK+ friendly C<die()> and C<warn()> functions.

=head1 SYNOPSIS

	use Gtk2::Ex::Carp;

	# these override the standard Perl functions:

	warn('i told you not to push that button!');

	die('an ignominious death');


	# new functions for showing extended error information:

	# like warn(), but shows a dialog with extra information
	# in an expandable text entry:
	worry($SHORT_MESSAGE, $EXTENDED_INFORMATION);

	# like worry(), but fatal:
	wail($SHORT_MESSAGE, $EXTENDED_INFORMATION);
	
=head1 DESCRIPTION

This module exports four functions, of which two override the standard
C<die()> and C<warn()> functions, and two which allow for extended error
reporting. When called, these functions display a user-friendly message
dialog window.

The C<die()> function in this module actually replaces the core C<die()>
function, so any modules you've loaded may die will use former instead
of the latter. C<die()> will also print the error message to C<STDERR> and
will exit the program (with the appropriate exit code) when the dialog is
dismissed.

The C<warn()> function will also print a message to C<STDERR>, but will
allow the program to continue running when the dialog is dismissed.

=head2 EXTRA FUNCTIONS

The C<worry()> and C<wail()> functions behave just like C<warn()> and
C<die()>, respectively, except that they allow you to provide additional
information. A second argument, which can contain additional error information,
is used to fill a text box inside an expander.

=head2 HANDLING GLIB EXCEPTIONS

This module also installs C<warn()> as a Glib exception handler. Any unhandled
exceptions will be presented to the user in a warning dialog.

=head2 PROGRAM FLOW

Note that all the functions in this module create dialogs and use the C<run()>
method, so that the standard Glib main loop is blocked until the user responds
to the dialog.

=head1 LOCALISATION ISSUES

The dialogs that are created use the standard GNOME layout, with a bold
"title" label above the main message. The text for these labels is taken
from two package variables that may be altered to suit your needs:

	$Gtk2::Ex::Carp::FATAL_ERROR_MESSAGE		= 'Fatal Error';
	$Gtk2::Ex::Carp::WARNING_ERROR_MESSAGE		= 'Warning';
	$Gtk2::Ex::Carp::EXTENDED_EXPANDER_LABEL	= 'Details:';

However, if the C<Locale::gettext> module is available on the system, and your
application uses it, these variables will be automagically translated, as long
as these default values are translated in your .mo files.

=head1 SEE ALSO

L<Gtk2>, L<Carp>, L<Locale::gettext>

=head1 AUTHOR

Gavin Brown (gavin dot brown at uk dot com)

=head1 COPYRIGHT

(c) 2005 Gavin Brown. All rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.   

=cut

use Carp;
use Gtk2 -init; # init just in case
use Gtk2::Pango;
use Exporter;
use File::Spec;
use base qw(Exporter);
use vars qw($VERSION @EXPORT $FATAL_ERROR_MESSAGE $WARNING_ERROR_MESSAGE $EXTENDED_EXPANDER_LABEL);
no warnings;
use strict;

our $VERSION			= '0.01';
our @EXPORT			= qw(die warn wail worry);
our $FATAL_ERROR_MESSAGE	= 'Fatal Error';
our $WARNING_ERROR_MESSAGE	= 'Warning';
our $EXTENDED_EXPANDER_LABEL	= 'Details:';

BEGIN {
	# nicked from CGI::Carp:
	*CORE::GLOBAL::die = \&__PACKAGE__::die;

	eval {
		require Locale::gettext;
	};
	if (defined($Locale::gettext::VERSION)) {
		$FATAL_ERROR_MESSAGE		= Locale::gettext::gettext($FATAL_ERROR_MESSAGE);
		$WARNING_ERROR_MESSAGE		= Locale::gettext::gettext($WARNING_ERROR_MESSAGE);
		$EXTENDED_EXPANDER_LABEL	= Locale::gettext::gettext($EXTENDED_EXPANDER_LABEL);
	}

	Glib->install_exception_handler(\&warn);
}

# nicked from CGI::Carp:
sub id {
	my $level			= shift;
	my ($pack, $file, $line, $sub)	= caller($level);
	my ($dev, $dirs, $id)		= File::Spec->splitpath($file);
	return ($file, $line, $id);
}

# nicked from CGI::Carp:, checks to see if the error was raised in an eval()
# context. In this case we want to croak so that the developer can catch the
# exception:
sub in_eval { Carp::longmess =~ /eval \{/ }

sub exit_ok {
	exit($! == 0 ? ($? >> 8) : (($? >> 8) == 0 ? 255 : 1));
}

sub die {
	my $message = join('', @_);
	chomp($message);

	if (in_eval) {
		Carp::croak($message);

	} else {
		my ($file, $line, $id) = id(1);
		printf(STDERR "%s at %s line %d\n", $message, $file, $line);
		_mkdialog('error', $FATAL_ERROR_MESSAGE, sprintf("%s\n\nFile %s, line %d", $message, $file, $line), \&exit_ok)->run;

	}

	return 1;
}

sub warn {
	my $message = join('', @_);
	chomp($message);
	my ($file, $line, $id) = id(1);
	printf(STDERR "%s at %s line %d\n", $message, $file, $line);
	_mkdialog('warning', $WARNING_ERROR_MESSAGE, sprintf("%s\n\nFile %s, line %d", $message, $file, $line), sub { shift()->destroy })->run;

	return 1;
}

sub worry {
	my ($error, $extended) = @_;
	_extended_dialog(
		'warning',
		$WARNING_ERROR_MESSAGE,
		$error,
		$extended,
		sub { shift()->destroy },
	);
	return 1;
}

sub wail {
	my ($error, $extended) = @_;
	_extended_dialog(
		'error',
		$FATAL_ERROR_MESSAGE,
		$error,
		$extended,
		\&exit_ok,
	);
	return 1;
}

sub _extended_dialog {
	my ($type, $title, $error, $extended, $callback) = @_;
	chomp($extended);
	my ($file, $line, $id) = id(2);
	my $dialog = Gtk2::Ex::Carp::ExtendedErrorDialog->new(
		$type,
		$title,
		$error,
		sprintf("%s\nFile %s line %d", $extended, $file, $line),
	);
	$dialog->signal_connect('response',	$callback);
	$dialog->signal_connect('close',	$callback);
	$dialog->signal_connect('delete_event',	$callback);
	$dialog->run;
}

sub _mkdialog {
	my ($type, $primary, $secondary, $callback) = @_;

	my $dialog = Gtk2::MessageDialog->new(
		undef,
		'modal',
		$type,
		'ok',
		'',
	);
	$dialog->set_markup(sprintf('<span size="large" weight="bold">%s</span>', $primary));
	$dialog->format_secondary_text($secondary);
	$dialog->signal_connect('response',	$callback);
	$dialog->signal_connect('close',	$callback);
	$dialog->signal_connect('delete_event',	$callback);

	return $dialog;
}

package Gtk2::Ex::Carp::ExtendedErrorDialog;
use Gtk2;
use base qw(Gtk2::Dialog);
use strict;

sub new {
	my ($package, $type, $title, $message, $extended) = @_;

	my $textview = Gtk2::TextView->new;
	$textview->modify_font(Gtk2::Pango::FontDescription->from_string('monospace'));
	$textview->get_buffer->set_text($extended);
	$textview->set_editable(0);

	my $scrwin = Gtk2::ScrolledWindow->new;
	$scrwin->set_policy('automatic', 'automatic');
	$scrwin->set_shadow_type('in');
	$scrwin->add($textview);

	my $expander = Gtk2::Expander->new;
	$expander->set_label($Gtk2::Ex::Carp::EXTENDED_EXPANDER_LABEL);
	$expander->add($scrwin);

	my $primary_label = Gtk2::Label->new;
	$primary_label->set_use_markup(1);
	$primary_label->set_markup(sprintf('<span weight="bold" size="large">%s</span>', $title));
	$primary_label->set_justify('left');
	$primary_label->set_alignment(0, 0);

	my $secondary_label = Gtk2::Label->new;
	$secondary_label->set_text($message);
	$secondary_label->set_selectable(1);
	$secondary_label->set_line_wrap(1);
	$secondary_label->set_justify('left');
	$secondary_label->set_alignment(0, 0);

	my $vbox = Gtk2::VBox->new;
	$vbox->set_spacing(12);
	$vbox->pack_start($primary_label, 0, 0, 0);
	$vbox->pack_start($secondary_label, 0, 0, 0);
	$vbox->pack_start($expander, 0, 0, 0);

	my $image = Gtk2::Image->new_from_stock('gtk-dialog-'.$type, 'dialog');
	$image->set_alignment(0, 0);

	my $hbox = Gtk2::HBox->new;
	$hbox->set_border_width(6);
	$hbox->set_spacing(12);
	$hbox->pack_start($image, 0, 0, 0);
	$hbox->pack_start($vbox, 1, 1, 0);
	$hbox->show_all;

	my $dialog = Gtk2::Dialog->new;
	$dialog->set_size_request(400, -1);
	$dialog->set_resizable(0);
	$dialog->set_position('center');
	$dialog->set_modal(1);
	$dialog->set_title($title);
	$dialog->add_button('gtk-ok', 'ok');
	$dialog->vbox->add($hbox);

	$expander->signal_connect('activate', sub { $dialog->set_size_request(400, -1) });

	bless($dialog, $package);

	return $dialog;
}

1;
