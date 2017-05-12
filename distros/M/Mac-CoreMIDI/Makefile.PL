use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mac::CoreMIDI',
    VERSION_FROM => 'lib/Mac/CoreMIDI.pm',    # finds $VERSION
    PREREQ_PM    => {Test::More => 0},        # e.g., Module::Name => 1.1
    (
        $] >= 5.005 ?
          ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Mac/CoreMIDI.pm',          # retrieve abstract from module
            AUTHOR => 'Christian Renz <crenz@web42.com>') :
          ()),

#    LDDLFLAGS         => '-bundle -flat_namespace -undefined suppress -framework CoreMIDI -framework CoreServices',
    LDDLFLAGS =>
'-bundle -flat_namespace -undefined dynamic_lookup -framework CoreMIDI -framework CoreServices',
    LIBS   => [],       # e.g., '-lm'
    DEFINE => '',       # e.g., '-DHAVE_SOMETHING'
    INC    => '-I.',    # e.g., '-I. -I/usr/include/other'
                        # Un-comment this if you add C files to link with later:
    OBJECT => '$(O_FILES)',    # link all the C files too
);
