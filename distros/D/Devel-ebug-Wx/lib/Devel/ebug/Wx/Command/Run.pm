package Devel::ebug::Wx::Command::Run;

use strict;
use Devel::ebug::Wx::Plugin qw(:plugin);

sub commands : Command {
    return
      ( run_menu => { tag      => 'run',
                      label    => 'Run',
                      priority => 200,
                      },
        next     => { sub      => sub { $_[0]->ebug->next },
                      key      => 'Alt-N',
                      menu     => 'run',
                      label    => 'Next',
                      priority => 20,
                      },
        step     => { sub      => sub { $_[0]->ebug->step },
                      key      => 'Alt-S',
                      menu     => 'run',
                      label    => 'Step',
                      priority => 20,
                      },
        return   => { sub      => sub { $_[0]->ebug->return },
                      key      => 'Alt-U',
                      menu     => 'run',
                      label    => 'Return',
                      priority => 20,
                      },
        run      => { sub      => sub { $_[0]->ebug->run },
                      key      => 'Alt-R',
                      menu     => 'run',
                      label    => 'Run',
                      priority => 10,
                      },
        restart  => { sub      => \&restart,
                      menu     => 'run',
                      label    => 'Restart',
                      priority => 30,
                      },
        );
}

sub restart {
    my( $wx ) = @_;

    $wx->ebug->reload_program;
}

1;
