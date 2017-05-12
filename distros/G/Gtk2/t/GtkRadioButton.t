#
# $Id$
#

#########################
# GtkRadioButton Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 13;

ok( my $vbox = Gtk2::VBox->new(0, 5) );
# $win->add($vbox);

my $rdobtn;
ok( $rdobtn = Gtk2::RadioButton->new() );
$vbox->pack_start($rdobtn, 0, 0, 0);

ok( $rdobtn = Gtk2::RadioButton->new_from_widget($rdobtn) );
$vbox->pack_start($rdobtn, 0, 0, 0);

ok( $rdobtn = Gtk2::RadioButton->new_from_widget($rdobtn, "label") );
$vbox->pack_start($rdobtn, 0, 0, 0);

ok( $rdobtn = Gtk2::RadioButton->new(undef, "foo") );
$vbox->pack_start($rdobtn, 0, 0, 0);

ok( $rdobtn = Gtk2::RadioButton->new($rdobtn, "bar") );
$vbox->pack_start($rdobtn, 0, 0, 0);

ok( $rdobtn = Gtk2::RadioButton->new([ $rdobtn ], "bar2") );
$vbox->pack_start($rdobtn, 0, 0, 0);

ok( scalar(@{$rdobtn->get_group}) == 3 );
{
  # get_group() no memory leaks in arrayref return and array items
  my $x = Gtk2::RadioButton->new;
  my $y = Gtk2::RadioButton->new;
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

my $i;
my @rdobtns;
for( $i = 0; $i < 5; $i++ )
{
	$rdobtns[$i] = Gtk2::RadioButton->new(\@rdobtns, $i);
	$vbox->pack_start($rdobtns[$i], 0, 0, 0);
}

ok( scalar(@{$rdobtns[0]->get_group}) == 5 );

1;

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
