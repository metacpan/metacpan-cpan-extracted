#
#
#

# regression test for custom widget handling.

use Test::More;
use Gtk2;
if (Gtk2->init_check) {
	plan tests => 15;
} else {
	plan skip_all => 'No DISPLAY';
}

use_ok ('Gtk2::GladeXML');

my $interface = '<glade-interface>
  <widget class="GtkWindow" id="window">
    <property name="visible">yes</property>

    <signal name="destroy" handler="on_window_destroy" />

    <child>
      <widget class="Custom" id="custom1">
        <property name="visible">True</property>
        <property name="creation_function">create_me</property>
        <property name="string1">string1</property>
        <property name="string2">string2, electric boogaloo</property>
        <property name="int1">42</property>
        <property name="int2">1138</property>
      </widget>
    </child>
  </widget>
</glade-interface>';

sub create_me {
	ok (1);
	use Data::Dumper;
	print Dumper(\@_);
	my ($glade, $creator, $name, $string1, $string2, $int1, $int2, $data)
		= @_;

	isa_ok ($glade, 'Gtk2::GladeXML');
	is ($creator, 'create_me', 'function name');
	is ($name, 'custom1');
	is ($string1, 'string1');
	is ($string2, 'string2, electric boogaloo');
	is ($int1, 42);
	is ($int2, 1138);

	# verify that complex user data made it through, alive
	is (ref($data), 'HASH');
	is ($data->{one}, 1);
	is ($data->{two}, 2);

	my $widget = Gtk2::Button->new;
	$widget->{something} = 'special';
	return $widget;
}

Gtk2::Glade->set_custom_handler (\&create_me, {one=>1, two=>2});

my $glade = Gtk2::GladeXML->new_from_buffer ($interface);
isa_ok ($glade, 'Gtk2::GladeXML');

my $custom1 = $glade->get_widget ('custom1');
isa_ok ($custom1, 'Gtk2::Button');
is ($custom1->{something}, 'special');
