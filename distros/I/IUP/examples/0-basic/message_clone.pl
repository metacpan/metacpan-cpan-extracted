use strict;
use warnings;

use IUP ':all';

sub myMessage {
  my ($tit, $msg) = @_;
  my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new(
                                       child=>[
                                         IUP::Label->new(TITLE=>$msg, EXPAND=>"Yes"),
                                         IUP::Button->new(TITLE=>"OK", PADDING=>"5x5", ACTION=>sub{return IUP_CLOSE}),
                                       ],
                                       MARGIN=>"10x10", 
                                       GAP=>"10",
                                       ALIGNMENT=>"ACENTER",
                              ), TITLE=>$tit );
  $dlg->Popup(10, 10);
  $dlg->Destroy();
}

my $tit = "Hi!";
my $msg = "This is Antonio's window";
myMessage($tit,$msg);
