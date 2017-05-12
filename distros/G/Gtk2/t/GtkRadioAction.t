#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "Action-based menus are new in 2.4"],
	tests => 14, noinit => 1;


my @actions = (Gtk2::RadioAction->new (name => 'one', value => 0));
isa_ok ($actions[$#actions], 'Gtk2::RadioAction');
my $i = 1;
foreach (qw(two three four five)) {
	push @actions, Gtk2::RadioAction->new (group => $actions[$#actions],
	                                       name => $_,
	                                       value => $i++);
	isa_ok ($actions[$#actions], 'Gtk2::RadioAction');
}
my $group = $actions[0]->get_group;
push @actions, Gtk2::RadioAction->new (name => 'six', value => 5);
isa_ok ($actions[$#actions], 'Gtk2::RadioAction');
$actions[$#actions]->set_group ($group);
{
  # get_group() no memory leaks in arrayref return and array items
  my $x = Gtk2::RadioAction->new (name => 'x', value => 0);
  my $y = Gtk2::RadioAction->new (name => 'y', value => 0);
  $y->set_group($x);
  my $aref = $x->get_group;
  is_deeply($aref, [$x,$y]);
  require Scalar::Util;
  Scalar::Util::weaken ($aref);
  is ($aref, undef, 'get_group() array destroyed by weakening');
  Scalar::Util::weaken ($x);
  is ($x, undef, 'get_group() item x destroyed by weakening');
  Scalar::Util::weaken ($y);
  is ($y, undef, 'get_group() item y destroyed by weakening');
}

is ($actions[0]->get_current_value, 0);

if (Gtk2->CHECK_VERSION (2, 10, 0)) {
	$actions[0]->set_current_value (3);
} else {
	$actions[0]->set (value => 3);
}
is ($actions[0]->get_current_value, 3);

$actions[3]->set_active (TRUE);
ok (!$actions[0]->get_active);
ok ($actions[3]->get_active);

__END__

Copyright (C) 2003-2006, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
