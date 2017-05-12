#!/usr/bin/perl

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Sexy;

my $libsexy_url = 'http://osiris.chipx86.com/svn/osiris-misc/trunk/libsexy/';

sub url_activated_cb {
	my ($url_label, $url) = @_;

	my $escaped_url = quotemeta($url);
	my $cmd = "gnome-open ".$escaped_url;

	print "Executing ".$cmd."\n";
	system("$cmd &");
}

my $window = Gtk2::Window->new();
$window->show();
$window->set_title('Sexy URL Label Test');
$window->set_border_width(12);

$window->signal_connect('destroy' => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new();
$vbox->show();
$window->add($vbox);

my $url_label = Gtk2::Sexy::UrlLabel->new();
$url_label->show();
$vbox->pack_start($url_label, TRUE, TRUE, 0);
$url_label->set_line_wrap(TRUE);
$url_label->set_alignment(0.0, 0.0);
$url_label->set_markup(
		"This is a sample SexyUrlLabel. For the latest version, please ".
		"the <a href=\"". $libsexy_url . "\">SVN repository</a>. For a great ".
		"page about mornings and what you can do with them, see ".
		"<a href=\"http://www.destroymornings.com/\">DestroyMornings.com</a>."
);

$url_label->signal_connect(url_activated => \&url_activated_cb);

Gtk2->main;
