#!perl

use strict;
use warnings;
use Gtk2::TestHelper tests => 35;
use Test::Exception;
use Gtk2::Notify -init, $0;

ginterfaces_ok('Gtk2::Notify');

my $w = Gtk2::Window->new;
my $n = Gtk2::Notify->new('foo', 'bar', '', $w);

isa_ok($n, 'Gtk2::Notify');

my @methods = qw(
        add_action
        attach_to_widget
        clear_actions
        clear_hints
        close
        set_category
        set_hint_byte
        set_hint_byte_array
        set_hint_double
        set_hint_int32
        set_hint_string
        set_icon_from_pixbuf
        set_timeout
        set_urgency
        show
        update
);

for my $method (@methods) {
    ok( $n->can($method), "can $method" );
}

lives_ok(sub {
        $n->clear_actions;
}, 'clear_actions without existing actions');

lives_ok(sub {
        $n->add_action('foo', 'Foo', sub {
            1;
        }, 42);
}, 'add_action');

{
    my $nw = Gtk2::Window->new;
    lives_ok(sub {
            $n->attach_to_widget($nw);
    }, 'attach_to_widget');
    lives_ok(sub {
            $n->attach_to_widget($w);
    }, 'attach_to_widget');
}

lives_ok(sub {
        $n->clear_actions;
}, 'clear_actions with existing actions');

lives_ok(sub {
        $n->set_category('foo');
}, 'set_category');

lives_ok(sub {
        $n->clear_hints;
}, 'clear_hins without existing hints');

lives_ok(sub {
        $n->set_hint_double(foo => 4.2);
}, 'set_hint_double');

lives_ok(sub {
        $n->set_hint_int32(foo => 42);
}, 'set_hint_int32');

lives_ok(sub {
        $n->set_hint_string(foo => 'bar');
}, 'set_hint_string');

{
    my $pixbuf = Gtk2::Gdk::Pixbuf->new('rgb', 0, 8, 5, 5);
    lives_ok(sub {
            $n->set_icon_from_pixbuf($pixbuf);
    }, 'set_icon_from_pixbuf');
}

lives_ok(sub {
        $n->set_timeout(20);
}, 'set_timeout');

lives_ok(sub {
        $n->set_urgency('critical');
}, 'set_urgency');

lives_ok(sub {
        $n->close;
}, 'close before show');

$w->show_all;

lives_ok(sub {
        $n->show;
}, 'show');

lives_ok(sub {
        $n->close;
}, 'close after show');

ok( $n->update('bar', 'foo', ''), 'update' );
