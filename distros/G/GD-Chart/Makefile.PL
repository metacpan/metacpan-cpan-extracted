use 5.008;
use ExtUtils::MakeMaker;

@LIBS = qw(-lgd -lpng);
$DEFS = "";

# Swiped from GD Makefile.PL

warn "You need to build gdchart with the same settings as libgd was built\n";
warn "with. Please answer the following questions:\n";
$with_jpeg = lc prompt('Build JPEG support?', 'y') eq 'y';
$with_ft = lc prompt('Build Freetype support?', 'y') eq 'y';
$with_xpm = lc prompt('Build XPM support?', 'y') eq 'y';

if($with_jpeg) {
	push @LIBS, "-ljpeg";
}
if($with_ft) {
	push @LIBS, "-lfreetype";
	$DEFS = "-DHAVE_LIBFREETYPE";
}
if($with_xpm) {
	push @LIBS, "-lXpm";
}

WriteMakefile(
    'NAME'		=> 'GD::Chart',
    'VERSION_FROM'      => 'Chart.pm',
    'LIBS'		=> [join(' ', @LIBS)],
    'INC'		=> "-Igdchart0.11.4dev",
    'DEFINE'		=> $DEFS,
    'OBJECT'		=> 'GDChart_wrap.o',
    'MYEXTLIB'		=> 'gdchart0.11.4dev/libgdc$(LIB_EXT)',
    'AUTHOR'		=> 'Richard Palmer (rdp@cpan.org)',
    'ABSTRACT'		=> 'Interface to gdchart graph drawing library',
    'dist'		=> {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
	                    'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
);

sub MY::postamble {
'
$(MYEXTLIB): gdchart0.11.4dev/Makefile
	cd gdchart0.11.4dev && $(MAKE) $(PASSTHRU) 
';
}
