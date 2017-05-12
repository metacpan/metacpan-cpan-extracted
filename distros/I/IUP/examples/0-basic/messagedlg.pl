# IUP::MessageDlg example

use strict;
use warnings;

use IUP ':all';

my $dlg = IUP::MessageDlg->new( DIALOGTYPE=>"ERROR", TITLE=>"IUP::MessageDlg - Error!", VALUE=>"This is an error message" );

$dlg->Popup();
$dlg->Destroy();
