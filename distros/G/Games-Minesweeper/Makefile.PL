use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    dist        => {
                    PREOP       => 'chmod -R u=rwX,go=rX . ;',
                    COMPRESS    => 'gzip -9v',
                    SUFFIX      => '.gz',
                   },

    PREREQ_PM   => {
                    Gtk2                => 1.043,
                    AnyEvent            => 0,
                    SDL                 => 0,
                    SDL::Mixer          => 0,
                    File::HomeDir       => 0,
                   },
    EXE_FILES   => [ qw(bin/minesweeper) ],
    PM          => { 
          'lib/Games/Minesweeper.pm' => '$(INST_LIBDIR)/Minesweeper.pm',

          'images/mine-0.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-0.png',
          'images/mine-1.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-1.png',
          'images/mine-2.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-2.png',
          'images/mine-3.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-3.png',
          'images/mine-4.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-4.png',
          'images/mine-5.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-5.png',
          'images/mine-6.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-6.png',
          'images/mine-7.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-7.png',
          'images/mine-8.png'                    => '$(INST_LIBDIR)/Minesweeper/images/mine-8.png',
          'images/mine-flag.png'                 => '$(INST_LIBDIR)/Minesweeper/images/mine-flag.png',
          'images/mine-hidden.png'               => '$(INST_LIBDIR)/Minesweeper/images/mine-hidden.png',
          'images/mine.png'                      => '$(INST_LIBDIR)/Minesweeper/images/mine.png',
          'images/mine-red.png'                  => '$(INST_LIBDIR)/Minesweeper/images/mine-red.png',
          'images/mine-wrong.png'                => '$(INST_LIBDIR)/Minesweeper/images/mine-wrong.png',
          'images/smile_happy.png'               => '$(INST_LIBDIR)/Minesweeper/images/smile_happy.png',
          'images/smile_ohno.png'                => '$(INST_LIBDIR)/Minesweeper/images/smile_ohno.png',
          'images/smile.png'                     => '$(INST_LIBDIR)/Minesweeper/images/smile.png',
          'images/smile_stress.png'              => '$(INST_LIBDIR)/Minesweeper/images/smile_stress.png',
          
          'sounds/mouse_press.wav'               => '$(INST_LIBDIR)/Minesweeper/sounds/mouse_press.wav',
          'sounds/mouse_release.wav'             => '$(INST_LIBDIR)/Minesweeper/sounds/mouse_release.wav',
          'sounds/game_over.wav'                 => '$(INST_LIBDIR)/Minesweeper/sounds/game_over.wav',
          'sounds/win.wav'                       => '$(INST_LIBDIR)/Minesweeper/sounds/win.wav',

                   },
    NAME              => 'Games::Minesweeper',
    VERSION_FROM      => 'lib/Games/Minesweeper.pm', # finds $VERSION
);
