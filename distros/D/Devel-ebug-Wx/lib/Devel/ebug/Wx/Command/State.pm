package Devel::ebug::Wx::Command::State;

use strict;

use Wx qw(:filedialog);
use File::Basename qw(basename dirname);

sub register_commands {
    return
      ( save_state => { sub      => \&save_program_state,
                        menu     => 'file',
                        label    => 'Save state',
                        priority => 100,
                        },
        load_state => { sub      => \&load_program_state,
                        menu     => 'file',
                        label    => 'Load state',
                        priority => 100,
                        },
        );
}

my $FILE;
my $wildcards = join '|', ( 'ebug_wx state files (*.ebug_wx)' => '*.ebug_wx',
                            'All files'                       => '*.*',
                            );

sub _get_file {
    my( $wx, $action ) = @_;

    my $flags = $action eq 'load' ? wxFD_OPEN|wxFD_FILE_MUST_EXIST :
                                    wxFD_SAVE;
    $flags ||= wxFD_CHANGE_DIR;
    if( !$FILE ) {
        my $script = $wx->ebug->script;
        my( $volume, $dir, $file ) = File::Spec->splitpath( $script );
        $file =~ s/\.\w+$/.ebug_wx/;
        $FILE = File::Spec->catpath( $volume, $dir, $file );
    }
    my( $dirname, $filename ) = ( dirname( $FILE ), basename( $FILE ) );
    my $new_file = Wx::FileSelector( "Choose a saved profile", $dirname,
                                     $filename, "ebug_wx", $wildcards,
                                     $flags, $wx );
    $FILE = $new_file if $new_file;
    return $new_file ? 1 : 0;
}

sub load_program_state {
    my( $wx ) = @_;

    return unless _get_file( $wx );
    $wx->service_manager->maybe_call_method( 'load_program_state', $FILE );
}

sub save_program_state {
    my( $wx ) = @_;

    return unless _get_file( $wx );
    $wx->service_manager->maybe_call_method( 'save_program_state', $FILE );
    $wx->configuration_service->flush( $FILE );
}

1;
