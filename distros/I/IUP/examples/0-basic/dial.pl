# IUP::Dial example

use strict;
use warnings;

use IUP ':all';

my $lbl_h = IUP::Label->new( TITLE=>"h: 0", SIZE=>"80x10" );
my $lbl_v = IUP::Label->new( TITLE=>"v: 0", SIZE=>"80x10" );

my $dial_v = IUP::Dial->new( TYPE=>"VERTICAL", SIZE=>"40x100");
my $dial_h = IUP::Dial->new( TYPE=>"HORIZONTAL", SIZE=>"100x20", DENSITY=>0.3);

sub v_mousemove_cb {
  my ($self, $a) = @_;
  $lbl_v->TITLE(sprintf "v: %.8f", $a);
  return IUP_DEFAULT;
}

sub h_mousemove_cb {
  my ($self, $a) = @_;
  $lbl_h->TITLE(sprintf "h: %.8f", $a);
  return IUP_DEFAULT;
}

$dial_v->MOUSEMOVE_CB(\&v_mousemove_cb);
$dial_h->MOUSEMOVE_CB(\&h_mousemove_cb);

my $dlg = IUP::Dialog->new( TITLE=>"IUP::Dial", child=>
    IUP::Vbox->new( MARGIN=>"5x5", GAP=>"5", child=>[
        IUP::Vbox->new( child=>[ IUP::Frame->new( TITLE=>"vertical", child=>$dial_v),
                                 IUP::Frame->new( TITLE=>"horizontal", child=>$dial_h) ] ),
        IUP::Vbox->new( child=>[ $lbl_v, $lbl_h ] ),
    ] ) );

$dlg->ShowXY(IUP_CENTER,IUP_CENTER);

IUP->MainLoop;
