# IUP::Text (single line) example

use strict;
use warnings;

use IUP ':all';

sub cb_text_k_any {
  my ($self, $c) = @_;
  return IUP_CLOSE if $c == K_cQ;
  return IUP_DEFAULT;
}

my $text = IUP::Text->new( VALUE=>"Write a text, press Ctrl-Q to exit",
                           EXPAND=>"HORIZONTAL",
                           K_ANY=>\&cb_text_k_any );

my $dlg = IUP::Dialog->new( child=>$text, TITLE=>"IUP::Text", SIZE=>"QUARTERxQUARTER" );

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

$text->SetFocus();

IUP->MainLoop;
