# IUP::List example
#
# Creates a dialog with three frames, each one containing a list.
# The first is a simple list, the second one is a multiple list and the last one is a drop-down list.
# The second list has a callback associated.

use strict;
use warnings;

use IUP ':all';

# Creates a list and sets items, initial item and size;
my $list = IUP::List->new( items=>["Gold", "Silver", "Bronze", "None"], VALUE=>4, SIZE=>"EIGHTHxEIGHTH" );

# Creates frame with simple list and sets its title;
my $frm_medal = IUP::Frame->new( child=>$list, TITLE=>"Best medal" );

# Creates a list and sets its items, multiple selection, initial items and size;
my $list_multiple = IUP::List->new( items=>['100m dash', 'Long jump', 'Javelin throw', '110m hurdlers', 'Hammer throw', 'High jump'],
                                    MULTIPLE=>'YES', VALUE=>'+--+--', SIZE=>'EIGHTHxEIGHTH' );

# Creates frame with multiple list and sets its title;
my $frm_sport = IUP::Frame->new( child=>$list_multiple, TITLE=>'Competed in' );

# Creates a list and sets its items, dropdown and amount of visible items;
my $list_dropdown = IUP::List->new( items=>['Less than US$ 1000', 'US$ 2000', 'US$ 5000', 'US$ 10000', 'US$ 20000', 'US$ 50000', 'More than US$ 100000'],
                                    DROPDOWN=>'YES', VISIBLE_ITEMS=>5 );

# Creates frame with dropdown list and sets its title;
my $frm_prize = IUP::Frame->new( child=>$list_dropdown, TITLE=>'Prizes won' );

# Creates a dialog with the the frames with three lists and sets its title;
my $dlg = IUP::Dialog->new( child=>IUP::Hbox->new( [$frm_medal, $frm_sport, $frm_prize] ), TITLE=>'IUP::List Example' );

# Shows dialog in the center of the screen;
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

sub cb_list_multiple {
  my ($self, $t, $i, $v) = @_;
  if ( $v == 0 ) {
    $self->{_STATE}='deselected'; # xxxTODO some best practice about strong user data into IUP object
  }
  else {
    $self->{_STATE}='selected';
  }
  IUP->Message('Competed in', "Item $i - $t - " . $self->{_STATE});
  return IUP_DEFAULT;
}

$list_multiple->ACTION(\&cb_list_multiple);

IUP->MainLoop;
