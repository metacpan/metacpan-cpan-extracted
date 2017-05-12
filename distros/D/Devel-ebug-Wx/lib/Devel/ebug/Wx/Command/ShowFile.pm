package Devel::ebug::Wx::Command::ShowFile;

use strict;
use Devel::ebug::Wx::Plugin qw(:plugin);

use Wx qw(:id);

sub commands : Command {
    return
      ( view_menu => { tag      => 'view',
                       label    => 'View',
                       priority => 500,
                      },
        showfile  => { sub      => \&show_file,
	               menu     => 'view',
                       label    => 'Show file',
                       priority => 100,
                       },
        );
}

sub show_file {
    my( $wx ) = @_;
    my $files = [ $wx->ebug->filenames ];
    my $dlg = Wx::SingleChoiceDialog->new
      ( $wx, "File to display", "Choose a file", $files );

    if( $dlg->ShowModal == wxID_OK ) {
        $wx->code_display_service->show_code_for_file( $dlg->GetStringSelection );
    }

    $dlg->Destroy;
}

1;
