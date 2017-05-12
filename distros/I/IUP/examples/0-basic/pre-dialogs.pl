# IUP::Expander example

use strict;
use warnings;

use IUP ':all';

sub ColorDlg_cb {
  my $d = IUP::ColorDlg->new(TITLE=>"Color dialog title", SHOWCOLORTABLE=>1);
  $d->Popup;
  return IUP_DEFAULT;
}

sub FileDlg_cb {
  my $d = IUP::FileDlg->new();
  $d->Popup;
  return IUP_DEFAULT;
}

sub FontDlg_cb {
  my $d = IUP::FontDlg->new();
  $d->Popup;
  return IUP_DEFAULT;
}

sub MessageDlg_cb {
  my $d = IUP::MessageDlg->new(DIALOGTYPE=>"ERROR", TITLE=>"IUP::MessageDlg - Error!", VALUE=>"This is an error message");
  $d->Popup;
  return IUP_DEFAULT;
}

sub ProgressDlg_cb {
  my $d = IUP::ProgressDlg->new(TITLE=>"Progress dialog title", CANCEL_CB=> sub { warn "cancel\n"; shift->Hide; });
  $d->Popup;
  return IUP_DEFAULT;
}

my $hbox = IUP::Hbox->new(MARGIN=>"10x10", child=>[
        IUP::Fill->new(),
        IUP::Button->new(PADDING=>"5x5", TITLE=>"ColorDlg",    ACTION=>\&ColorDlg_cb),
        IUP::Button->new(PADDING=>"5x5", TITLE=>"FileDlg",     ACTION=>\&FileDlg_cb),
        IUP::Button->new(PADDING=>"5x5", TITLE=>"FontDlg",     ACTION=>\&FontDlg_cb),
        IUP::Button->new(PADDING=>"5x5", TITLE=>"MessageDlg",  ACTION=>\&MessageDlg_cb),
        IUP::Button->new(PADDING=>"5x5", TITLE=>"ProgressDlg", ACTION=>\&ProgressDlg_cb),
        IUP::Fill->new(),
]);

# Shows dialog in the center of the screen
my $dlg  = IUP::Dialog->new( child=>$hbox, TITLE=>"IUP pre-defined dialogs" );
$dlg->ShowXY (IUP_CENTER, IUP_CENTER);
IUP->MainLoop;