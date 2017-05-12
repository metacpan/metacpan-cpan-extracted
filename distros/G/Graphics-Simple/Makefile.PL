use ExtUtils::MakeMaker;

WriteMakefile(
NAME => 'Graphics::Simple',
VERSION_FROM => 'Simple.pm',
PM =>     {'Simple.pm' => '$(INST_LIBDIR)/Simple.pm',
	    'GnomeCanvas.pm' => '$(INST_LIBDIR)/Simple/GnomeCanvas.pm',
	    'Fig.pm' => '$(INST_LIBDIR)/Simple/Fig.pm',
	    'PostScript.pm' => '$(INST_LIBDIR)/Simple/PostScript.pm',
	    'PDLPlot.pm' => '$(INST_LIBDIR)/Simple/PDLPlot.pm',
	   },
dist => {
	COMPRESS => 'gzip -9', SUFFIX => 'gz'
},

);
