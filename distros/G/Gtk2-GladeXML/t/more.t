#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/t/more.t,v 1.1 2004/09/15 03:30:57 muppetman Exp $
#
# we don't require Gtk2 any newer than 1.000, so don't assume we have
# Gtk2::TestHelper available.

#
# various tests for most of the API of the module.
#
# do as i say, not as i do.  this code is trying to verify invariants
# and test that things work; you don't typically want to write app code
# that works like this.
#

use Test::More;
use Gtk2;

if (Gtk2->init_check) {
	plan tests => 26;
} else {
	plan skip_all => 'No DISPLAY';
}

use_ok ('Gtk2::GladeXML');


my $interface = '<glade-interface>
  <widget class="GtkWindow" id="window">
    <property name="visible">yes</property>

    <signal name="destroy" handler="on_window_destroy" />

    <child>
      <widget class="GtkVBox" id="vbox">
        <child>
          <widget class="GtkButton" id="button">
            <property name="can_default">yes</property>
            <property name="visible">yes</property>
	    <property name="label">Clicky</property>
	
	    <signal name="clicked" handler="on_button_clicked" />
	    <signal name="clicked" handler="after_button_clicked" after="yes" />
	  </widget>
	</child>

	  <!-- several more to test get_prefix() -->
        <child><widget class="GtkButton" id="foo_1"></widget></child>
        <child><widget class="GtkButton" id="foo_2"></widget></child>
        <child><widget class="GtkButton" id="foo_3"></widget></child>
        <child><widget class="GtkButton" id="foo_4"></widget></child>
      </widget>
    </child>
  </widget>
</glade-interface>';

my $glade = Gtk2::GladeXML->new_from_buffer ($interface);
isa_ok ($glade, 'Gtk2::GladeXML');


my $button = $glade->get_widget ('button');
isa_ok ($button, 'Gtk2::Button');
is ($button->get_name, 'button');

# harumph.  glade_get_widget_name() is mapped to Gtk2::Widget::get_name.
is ($button->get_widget_name, $button->get_name);

# the glade-created widgets know to what tree they belong.
is ($button->get_widget_tree, $glade);


# get_widget_prefix() does name matching to fetch widgets.
# it looks like the list returned from libglade is backwards; we
# won't rely on that since it's easy to sort in perl.
my @foos = sort { $a->get_name cmp $b->get_name }
			$glade->get_widget_prefix ('foo');
is (scalar (@foos), 4, 'expect 4 foo_* widgets');
is ($foos[0]->get_name, 'foo_1');
is ($foos[1]->get_name, 'foo_2');
is ($foos[2]->get_name, 'foo_3');
is ($foos[3]->get_name, 'foo_4');



# signal_autoconnect() uses a callback to do the actual connecting;
# we'll supply a dummy callback that doesn't actually do anything,
# just tests that it calls the callback the right number of times.
my @handlers = sort map {
	s/^.*handler="//;
	s/".*$//;
	$_
} grep { /handler=/ } split /\n/, $interface;
use Data::Dumper;
my %handlers = ();
$glade->signal_autoconnect (sub {
	$handlers{$_[0]} ++;
	ok(1, "asked to connect $_[0] to $_[2] on ".$_[1]->get_name);
});
is_deeply ([sort keys %handlers], \@handlers);


# now test some actual connections.  i want all of the handlers to do the
# same thing, so i'm creating the handlers on the fly; this is kinda evil
# and you should not try this at home.
my $package = 'FluffyBunny';
my @ran = ();
sub make_handler {
	my $name = $_[0];
	*{$name} = sub { ok(1, "$name called"); push @ran, $name; }
}
foreach (@handlers) {
	make_handler ($_);                # in package main
	make_handler ($package."::".$_);  # in $package
	make_handler ($_."_all");         # for signal_autoconnect_all
}

$glade->signal_autoconnect_from_package ($package);
$glade->signal_autoconnect_from_package; # should default to main

# connect to specific handlers.
$glade->signal_autoconnect_all (
	on_button_clicked => 'on_button_clicked_all',
	after_button_clicked => 'after_button_clicked_all',
	on_window_destroy => sub {ok(1, 'all-connected'); },
);


# this should result in all of the connected handlers running:
is(scalar(@ran), 0);
$button->clicked;
# this is to verify that the after ones ran after the non-after ones.
is_deeply (\@ran, [ qw(FluffyBunny::on_button_clicked
		       on_button_clicked
		       on_button_clicked_all
		       FluffyBunny::after_button_clicked
		       after_button_clicked
		       after_button_clicked_all)]);

$glade->get_widget ('window')->destroy;
