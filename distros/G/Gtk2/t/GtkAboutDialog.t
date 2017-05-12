#
# $Id$
#

#########################
# GtkAboutDialog Tests
# 	- rm
#########################

#########################

use strict;
use warnings;

use Gtk2::TestHelper tests => 34,
    at_least_version => [2, 6, 0, "GtkAboutDialog is new in 2.6"];

isa_ok (my $dialog = Gtk2::AboutDialog->new, 'Gtk2::AboutDialog',
	'Gtk2::AboutDialog->new');

$dialog->set_program_name ('AboutDialog');
is ($dialog->get_program_name, 'AboutDialog', '$dialog->set|get_program_name');

$dialog->set_program_name (undef);
# according to the docs, name falls back to g_get_application_name().
is ($dialog->get_program_name, Glib::get_application_name, 'fallback');

$dialog->set_version ('Ver: 1.2');
is ($dialog->get_version, 'Ver: 1.2', '$dialog->set|get_version');

$dialog->set_version (undef);
is ($dialog->get_version, undef);

$dialog->set_copyright ('2004');
is ($dialog->get_copyright, '2004', '$dialog->set|get_copyright');

$dialog->set_copyright (undef);
is ($dialog->get_copyright, undef);

$dialog->set_comments ('this is a comment');
is ($dialog->get_comments, 'this is a comment', '$dialog->set|get_comments');

$dialog->set_comments (undef);
is ($dialog->get_comments, undef);

$dialog->set_license ('LGPL');
is ($dialog->get_license, 'LGPL', '$dialog->set|get_license');

$dialog->set_license (undef);
is ($dialog->get_license, undef);

SKIP: {
	skip "new 2.8 stuff", 1
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	$dialog->set_wrap_license (TRUE);
	is ($dialog->get_wrap_license, TRUE);
}

$dialog->set_authors (qw/one two three/);
ok (eq_array ([$dialog->get_authors], [qw/one two three/]),
    '$dialog->set|get_authors');

$dialog->set_documenters (qw/two three four/);
ok (eq_array ([$dialog->get_documenters], [qw/two three four/]),
    '$dialog->set|get_documenters');

$dialog->set_artists (qw/three four five/);
ok (eq_array ([$dialog->get_artists], [qw/three four five/]),
    '$dialog->set|get_artists');

$dialog->set_translator_credits ('people');
is ($dialog->get_translator_credits, 'people',
    '$dialog->set|get_translator_credits');

$dialog->set_translator_credits (undef);
is ($dialog->get_translator_credits, undef);

$dialog->set_logo (undef);
is ($dialog->get_logo, undef, '$dialog->get_logo undef');

my $pb = Gtk2::Gdk::Pixbuf->new ('rgb', TRUE, 8, 61, 33);
$dialog->set_logo ($pb);
isa_ok ($dialog->get_logo, 'Gtk2::Gdk::Pixbuf', '$dialog->set|get_logo');

$dialog->set_logo_icon_name ('gtk-ok');
is ($dialog->get_logo_icon_name, 'gtk-ok',
    '$dialog->set|get_logo_icon_name');

SKIP: {
	skip "get_logo_icon_name is slightly broken in 2.6", 1
		unless Gtk2->CHECK_VERSION (2, 6, 1);

	$dialog->set_logo_icon_name (undef);
	is ($dialog->get_logo_icon_name, undef);
}

$dialog->set_email_hook (sub { warn @_; }, "urgs");
$dialog->set_email_hook (sub { warn @_; });

$dialog->set_url_hook (sub { warn @_; }, "urgs");
$dialog->set_url_hook (sub { warn @_; });

$dialog->set_website_label ('website');
is ($dialog->get_website_label, 'website', '$dialog->set|get_website_label');

$dialog->set_website_label (undef);
is ($dialog->get_website_label, undef);

$dialog->set_website ('http://gtk2-perl.sourceforge.net/');
is ($dialog->get_website, 'http://gtk2-perl.sourceforge.net/', 
    '$dialog->set|get_website');

$dialog->set_website (undef);
is ($dialog->get_website, undef);


# test out the Glib::Strv properties.  this is partially to make sure these
# work right for the dialog, and partially to test the functionality from
# Glib (there's nothing that can really test them in gobject).
$dialog->set (authors => 'me');
ok (eq_array ($dialog->get ('authors'), ['me']), 'authors property (scalar)');

my @authors = qw/me myself i/;
$dialog->set (authors => \@authors);
ok (eq_array ($dialog->get ('authors'), \@authors), 'authors property (array)');

$dialog->set (authors => undef);
ok (!$dialog->get ('authors'), 'authors property (undef)');

$dialog->set (documenters => []);
ok (!$dialog->get ('documenters'), 'documenters property (empty array)');

my @artists = qw/Leonardo Donatello Raphael Michelangelo/;
$dialog->set (artists => \@artists);
ok (eq_array ($dialog->get ('artists'), \@artists), 'artists property');


Gtk2->show_about_dialog (undef,
			 program_name => 'Foo',
			 version => '42',
			 authors => [qw/me myself i/],
			);


SKIP: {
	skip 'new 2.12 stuff', 4
		unless Gtk2->CHECK_VERSION (2, 12, 0);

	# Called 3 times
	$SIG{__WARN__} = sub { like shift, qr/Deprecation warning/; };

	$dialog->set_name ('AboutDialogAbout');
	is ($dialog->get_name, 'AboutDialogAbout', '$dialog->set|get_name');

	Gtk2->show_about_dialog (Gtk2::Window->new, name => 'AboutFoo');
}
