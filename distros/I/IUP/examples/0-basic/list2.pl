# IUP::List example
#
# Creates a dialog with three frames, each one containing a list.
# The first is a simple list, the second one is a multiple list and the last one is a drop-down list.
# The second list has a callback associated.

use strict;
use warnings;

use IUP ':all';

sub list_cb {
  my ($self, $t, $i, $v) = @_;
  my $lbl = IUP->GetByName("my_LABEL");
  $lbl->TITLE($t);
  return IUP_DEFAULT;
}

sub edit_cb {
  my ($self, $c, $after) = @_;
  return IUP_DEFAULT unless $c;
  my $lbl = IUP->GetByName("my_LABEL");
  $lbl->TITLE($after);
  return IUP_DEFAULT;
}

sub btclose_cb {
  my $self = shift;
  return IUP_CLOSE;
}

sub bt_cb {
  my $self = shift;
  my $list = $self->{_LIST};
  IUP->Message("List", "Value=" . $list->VALUE);
  return IUP_DEFAULT;
}

sub getfocus_cb {
  my $self = shift;
  my $bt = $self->{_BUTTON};
  $bt->BGCOLOR("255 0 128");
  return IUP_DEFAULT;
}

sub killfocus_cb {
  my $self = shift;
  my $bt = $self->{_BUTTON};
  $bt->BGCOLOR(undef);
  return IUP_DEFAULT;
}

my $bt1 = IUP::Button->new( ACTION=>\&bt_cb, BGCOLOR=>"192 192 192", TITLE=>"Drop+Edit" );
my $bt2 = IUP::Button->new( ACTION=>\&bt_cb, BGCOLOR=>"192 192 192", TITLE=>"Drop" );
my $bt3 = IUP::Button->new( ACTION=>\&bt_cb, BGCOLOR=>"192 192 192", TITLE=>"List+Edit" );
my $bt4 = IUP::Button->new( ACTION=>\&bt_cb, BGCOLOR=>"192 192 192", TITLE=>"List" );

my $list1 = IUP::List->new( ACTION=>\&list_cb );
my $list2 = IUP::List->new( ACTION=>\&list_cb );
my $list3 = IUP::List->new( ACTION=>\&list_cb );
my $list4 = IUP::List->new( ACTION=>\&list_cb );

$list1->SetAttribute( 1=>'US$ 1000', 2=>'US$ 2000', 3=>'US$ 30000000', 4=>'US$ 4000', 5=>'US$ 5000', 6=>'US$ 6000', 7=>'US$ 7000',
                      EXPAND=>'HORIZONTAL', EDITBOX=>'YES', DROPDOWN=>'YES', VISIBLE_ITEMS=>5 );
$list2->SetAttribute( 1=>'R$ 1000', 2=>'R$ 2000', 3=>'R$ 3000', 4=>'R$ 4000', 5=>'R$ 5000', 6=>'R$ 6000', 7=>'R$ 7000',
                      EXPAND=>'HORIZONTAL', DROPDOWN=>'YES', VISIBLE_ITEMS=>5 );
$list3->SetAttribute( 1=>'Char A', 2=>'Char B', 3=>'Char CCCCC', 4=>'Char D', 5=>'Char F', 6=>'Char G', 7=>'Char H',
                      EXPAND=>'YES', EDITBOX=>'YES');
$list4->SetAttribute( 1=>'Number 1', 2=>'Number 2', 3=>'Number 3', 4=>'Number 4', 5=>'Number 5', 6=>'Number 6', 7=>'Number 7',
                      EXPAND=>'YES' );

#store some internal variables
$bt1->{_LIST} = $list1;
$bt2->{_LIST} = $list2;
$bt3->{_LIST} = $list3;
$bt4->{_LIST} = $list4;

$list1->{_BUTTON} = $bt1;
$list2->{_BUTTON} = $bt2;
$list3->{_BUTTON} = $bt3;
$list4->{_BUTTON} = $bt4;

#set callbacks
$list1->GETFOCUS_CB(\&getfocus_cb);
$list1->KILLFOCUS_CB(\&killfocus_cb);
$list2->GETFOCUS_CB(\&getfocus_cb);
$list2->KILLFOCUS_CB(\&killfocus_cb);
$list3->GETFOCUS_CB(\&getfocus_cb);
$list3->KILLFOCUS_CB(\&killfocus_cb);
$list4->GETFOCUS_CB(\&getfocus_cb);
$list4->KILLFOCUS_CB(\&killfocus_cb);

$list1->EDIT_CB(\&edit_cb);
$list3->EDIT_CB(\&edit_cb);

#$list3->READONLY("YES");

my $box1 = IUP::Vbox->new( [$list1, $bt1] );
my $box2 = IUP::Vbox->new( [$list2, $bt2] );
my $box3 = IUP::Vbox->new( [$list3, $bt3] );
my $box4 = IUP::Vbox->new( [$list4, $bt4] );

my $btok = IUP::Button->new( TITLE=>"OK", ACTION=>\&btclose_cb );
my $btcancel = IUP::Button->new( TITLE=>"Cancel", ACTION=>\&btclose_cb );

$btok->{_LIST1} = $list1;
$btok->{_LIST2} = $list2;
$btok->{_LIST3} = $list3;
$btok->{_LIST4} = $list4;

my $l = IUP::Label->new( name=>"my_LABEL", TITLE=>"", EXPAND=>"HORIZONTAL"); #note: using global element alias 'my_LABEL'
           
my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( [IUP::Hbox->new( [$box1, $box2, $box3, $box4] ), $l, $btok, $btcancel] ) );
$dlg->SetAttribute( MARGIN=>"10x10", GAP=>10, TITLE=>"IUP::List Example", DEFAULTENTER=>$btok, DEFAULTESC=>$btcancel );

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop();
