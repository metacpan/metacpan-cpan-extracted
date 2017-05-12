#  IUP::Text (multiline) example
#
#  Shows a multiline that ignores the treatment of the 'g' key, canceling its effect.

use strict;
use warnings;

use IUP ':all';

my $ml = IUP::Text->new( MULTILINE=>"YES", EXPAND=>"YES", VALUE=>"I ignore the 'g' key!", BORDER=>"YES" );

sub cb_action {
  my ($self, $c, $after) = @_;
  if ( $c == K_g ) {
    return IUP_IGNORE;
  }
  else {
    return IUP_DEFAULT;;
  }
}

$ml->ACTION(\&cb_action);

my $dlg = IUP::Dialog->new( child=>$ml, TITLE=>"IupMultiline", SIZE=>"QUARTERxQUARTER" );
$dlg->Show();

IUP->MainLoop;
