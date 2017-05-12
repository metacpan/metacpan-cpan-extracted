#!/usr/bin/perl -w
# vim: set ft=perl :

use strict;
use Gtk2::TestHelper
  tests => 28,
  at_least_version => [2, 10, 0, "GtkLinkButton is new in 2.10"];

my $button;

my $url = "http://google.com/";

$button = Gtk2::LinkButton->new ($url);
isa_ok ($button, 'Gtk2::LinkButton');
isa_ok ($button, 'Gtk2::Button');
is ($button->get_uri, $url);
is ($button->get_label, $url);  # interesting

$button = Gtk2::LinkButton->new ($url, "a label");
isa_ok ($button, 'Gtk2::LinkButton');
isa_ok ($button, 'Gtk2::Button');
is ($button->get_uri, $url);
is ($button->get_label, "a label");

$button = Gtk2::LinkButton->new_with_label ($url, "a label");
isa_ok ($button, 'Gtk2::LinkButton');
isa_ok ($button, 'Gtk2::Button');
is ($button->get_uri, $url);
is ($button->get_label, "a label");

# this also works...
$button = Gtk2::LinkButton->new_with_label ($url);
isa_ok ($button, 'Gtk2::LinkButton');
isa_ok ($button, 'Gtk2::Button');
is ($button->get_uri, $url);
is ($button->get_label, $url);  # interesting

$url = "http://www.gnome.org/";
$button->set_uri ($url);
is ($button->get_uri, $url);

sub hook {
	my ($widget, $link, $data) = @_;
	is ($widget, $button);
	is ($link, $url);
	isa_ok ($data, 'HASH');
	is ($data->{whee}, "woo hoo");
}

$button->set_uri_hook (\&hook, { whee => "woo hoo" });
$button->clicked;

$button->set_uri_hook (undef);

{ my $saw_data;
  sub hook2 {
    $saw_data = $_[-1];
    $_[-1]++;
  }
  $button->set_uri_hook (\&hook2, 100);
  $button->clicked;
  is ($saw_data, 100, 'initial userdata');
  $button->clicked;
  is ($saw_data, 101, 'incremented once');
  $button->clicked;
  is ($saw_data, 102, 'incremented twice');

  $button->set_uri_hook (undef);
}

{ my $userdata = [ 'something' ];
  sub hook3 {
    $_[-1] = undef;
  }
  $button->set_uri_hook (\&hook3, $userdata);
  require Scalar::Util;
  Scalar::Util::weaken ($userdata);
  is_deeply ($userdata, [ 'something' ],
             'still alive when first weakened'); 
  $button->clicked;
  is ($userdata, undef, 'then gone when hook zaps its last arg'); 

  $button->set_uri_hook (undef);
}

{ my $saw_data;
  sub hook4 {
    $button->set_uri_hook (undef);
    $saw_data = $_[-1];
  }
  $button->set_uri_hook (\&hook4, [ 'hello' ]);
  $button->clicked;
  is_deeply ($saw_data, [ 'hello' ],
             'userdata still ok when hook disconnects itself'); 
}

SKIP: {
	skip 'new 2.14 stuff', 1
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	$button->set_visited (TRUE);
	is ($button->get_visited, TRUE);
}
