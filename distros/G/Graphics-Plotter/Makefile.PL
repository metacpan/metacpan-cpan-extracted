use ExtUtils::MakeMaker;
#
# point -L$prefix/lib to the place where the libplotter.so is
# i.e. set the prefix at the top of this file
#

my $prefix = '/usr/local';
my $DEFINE;

if ((not -r "/usr/local/include/X11/Xlib.h")
    and
    (not -r "/usr/include/X11/Xlib.h")
    and
    (not -r "/usr/X11R6/include/X11/Xlib.h")) {
    warn "X display is missing\n";
    $DEFINE = '-DX_DISPLAY_MISSING';
}

WriteMakefile(
    'CC'	=> 'g++',
    'LD'	=> 'g++',
    'OPTIMIZE'	=> '-O2',
    'NAME'	=> 'Graphics::Plotter',
    'VERSION_FROM' => 'Plotter.pm',
    'LIBS'	=> ["-L$prefix/lib -lplotter"],
    'DEFINE'	=> "$DEFINE",
    'INC'	=> "-I$prefix/include" # where I can find plotutils' plotter.h
);
