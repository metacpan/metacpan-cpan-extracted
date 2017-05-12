#!/usr/bin/perl -w
# vim: set filetype=perl :

# $Id$

use Gtk2::TestHelper tests => 41;

# we'll create some containers (windows and boxes are containers) and
# mess around with some of the methods to make sure they do things.

my $window = Gtk2::Window->new;
my $vbox = Gtk2::VBox->new;


is ($window->child_type, 'Gtk2::Widget', 'a window wants a widget');

# i think we'd know if $container->add didn't work
$window->add ($vbox);
ok (1, 'added a widget to the window');

$window->set_focus_child($vbox);
ok(1);

SKIP: {
	skip 'new 2.14 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	is ($window->get_focus_child, $vbox);
	$window->set_focus_child (undef);
	is ($window->get_focus_child, undef);
}

my $adjustment = Gtk2::Adjustment->new(0, 0, 100, 5, 10, 20);

$window->set_focus_vadjustment($adjustment);
is($window->get_focus_vadjustment, $adjustment);

$window->set_focus_hadjustment($adjustment);
is($window->get_focus_hadjustment, $adjustment);

$window->resize_children;
ok(1);

$window->set_border_width(10);
is($window->get_border_width, 10);

my $expose_event = Gtk2::Gdk::Event->new("expose");
$window->propagate_expose($vbox, $expose_event);

ok(1);

# child_type returns undef when no more children may be added
#ok (!defined ($window->child_type),
 #   'child_type returns undef when the container is full');
is ($window->get_child, $vbox,
    'the window\'s child is set');


is ($vbox->child_type, 'Gtk2::Widget', 'a box wants a widget');

$vbox->pack_start (Gtk2::Label->new ("one"), 1, 1, 0);

is ($vbox->child_type, 'Gtk2::Widget', 'a box is always hungry');

my $entry = Gtk2::Entry->new ();

# let's dump in a few more quickly
$vbox->pack_start (Gtk2::Button->new ("two"), 1, 1, 0);
$vbox->pack_start (Gtk2::ToggleButton->new ("three"), 1, 1, 0);
$vbox->pack_start (Gtk2::CheckButton->new ("four"), 1, 1, 0);
$vbox->pack_start ($entry, 1, 1, 0);

is_deeply ([$vbox->child_get ($entry, qw(expand fill pack-type padding position))],
           [1, 1, "start", 0, 4]);

$vbox->child_set ($entry, expand => 0, position => 2);
$vbox->child_set_property ($entry, fill => 0);

is_deeply ([$vbox->child_get_property ($entry, qw(expand fill pack-type padding position))],
           [0, 0, "start", 0, 2]);

my $label = Gtk2::Label->new ("Blub");

$vbox->add_with_properties ($label, pack_type => "end", position => 4);
is_deeply ([$vbox->child_get ($label, qw(pack-type position))],
           ["end", 4]);
$vbox->remove ($label);

my @children = $vbox->get_children;
is (scalar (@children), 5, 'we packed five children');

my @chain = $vbox->get_focus_chain;
is (scalar (@chain), 0, 'we have not set a focus chain');

# set focus chain to focusable children in reverse order
@chain = reverse map { $_->can_focus ? $_ : () } @children;
$vbox->set_focus_chain (@chain);
eq_array( [$vbox->get_focus_chain], \@chain, 'focus chain took');

$vbox->unset_focus_chain;
is_deeply([$vbox->get_focus_chain], []);

# togglebuttons suck.  wipe them out... all of them.
my $nremoved = 0;
$vbox->foreach (sub {
	if ('Gtk2::ToggleButton' eq ref $_[0]) {
		$vbox->remove ($_[0]);
		$nremoved++;
	}
	});
is ($nremoved, 1, 'removed one toggle');
@children = $vbox->get_children;
is (scalar (@children), 4, 'four children remain');

my $n_total = 0;
$vbox->forall (sub {
	isa_ok ($_[0], Gtk2::Widget::);
	$n_total++;
	});
is ($n_total, 4, 'forall walks all children');

is ($vbox->get_resize_mode, 'parent');
$vbox->set_resize_mode ('queue');
is ($vbox->get_resize_mode, 'queue');

$vbox->check_resize;
ok(1);

$vbox->set_reallocate_redraws(1);
ok(1);

#$window->show_all;
#Gtk2->main;

#------------------------------------------------------------------------------
# find_child_property()

is (Gtk2::Container->find_child_property('Gtk2-Perl-test-no-such-property'),
    undef,
    'find_child_property() no such child property');

is (eval { Gtk2::Container::find_child_property('Not::A::Container::Class',
						'propname'); 1 },
    undef,
    'find_child_property() Not::A::Container::Class croaks');

is (eval { Gtk2::Container::find_child_property('Gtk2::Widget',
						'propname'); 1 },
    undef,
    'find_child_property() Gtk2::Widget croaks');

{
  my $pspec = Gtk2::Box->find_child_property('expand');
  isa_ok ($pspec, 'Glib::Param::Boolean',
	  'find_child_property() "expand" is a boolean');

  require Scalar::Util;
  Scalar::Util::weaken($pspec);
  is ($pspec, undef, 'find_child_property() destroyed when weakened');
}

{
  my $hbox = Gtk2::HBox->new;
  my $pspec = $hbox->find_child_property('expand');
  isa_ok ($pspec, 'Glib::Param::Boolean',
	  'find_child_property() object method "expand" is a boolean');
}

#------------------------------------------------------------------------------
# list_child_properties()

# as of Gtk 2.20 the base Gtk2::Container class doesn't have any child
# properties, but don't assume that, so don't ask anything of @pspecs, just
# that list_child_properties() returns
my @pspecs = Gtk2::Container->list_child_properties;

is (eval { Gtk2::Container::list_child_properties('Not::A::Container::Class');
	   1 },
    undef,
    'list_child_properties() Not::A::Container::Class croaks');

is (eval { Gtk2::Container::list_child_properties('Gtk2::Widget');
	   1 },
    undef,
    'list_child_properties() Gtk2::Widget croaks');

{
  my @pspecs = Gtk2::Box->list_child_properties;
  cmp_ok (scalar(@pspecs), '>=', 2,
	  'list_child_properties() at least "expand" and "pack"');

  require Scalar::Util;
  foreach (@pspecs) {
    Scalar::Util::weaken($_);
  }
  my $all_undef = 1;
  foreach (@pspecs) {
    if ($_) { $all_undef = 0; }
  }
  is ($all_undef, 1, 'list_child_properties() pspecs destroyed when weakened');
}

{
  my $hbox = Gtk2::HBox->new;
  my @pspecs = $hbox->list_child_properties;
  cmp_ok (scalar(@pspecs), '>=', 2,
	  'list_child_properties() object method at least "expand" and "pack"');
}

__END__

Copyright (C) 2003-2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
