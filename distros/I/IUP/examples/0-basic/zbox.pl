# IUP::Zbox example
#
# An application of a zbox could be a program requesting several entries from the user
# according to a previous selection. In this example, a list of possible layouts,
# each one consisting of an element, is presented, and according to the selected
# option the dialog below the list is changed.

use strict;
use warnings;

use IUP ':all';

my $fram = IUP::Frame->new( TITLE=>"List", child=>IUP::List->new( DROPDOWN=>'YES', 1=>'White', 2=>'Black', VALUE=>1) );
my $text = IUP::Text->new( VALUE=>"Enter your text here", EXPAND=>"YES" );
my $lbl  = IUP::Label->new( TITLE=>"This element is a label" );
my $btn  = IUP::Button->new( TITLE=>"This button does nothing" );
my $zbox = IUP::Zbox->new( child=>[$fram, $text, $lbl, $btn], ALIGNMENT=>"ACENTER", VALUE=>$fram );

my $list = IUP::List->new( items=>["frame", "text", "lbl", "btn"], VALUE=>"1"); #BEWARE: VALUE is 1-based
my $ilist = [ $fram, $text, $lbl, $btn ];

sub list_action {
  my ($self, $t, $o, $selected) = @_;
  if ( $selected == 1 ) {
    # Sets the value of the zbox to the selected element;
    $zbox->VALUE($ilist->[$o-1]); #BEWARE: VALUE attribute contains index value which is 1-based
  }
  return IUP_DEFAULT;
}

$list->ACTION(\&list_action);

my $frm = IUP::Frame->new( TITLE=>"Select an element", child=>
            IUP::Hbox->new( child=>[
              IUP::Fill->new(),
              $list,
              IUP::Fill->new(),
            ] )
          );

my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( "MARGIN", "7x7", child=>[$frm, $zbox] ), SIZE=>"QUARTER", TITLE=>"IupZbox Example" );
$dlg->ShowXY();

IUP->MainLoop;
