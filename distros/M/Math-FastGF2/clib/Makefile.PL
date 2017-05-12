use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	      NAME   => 'Math::fastgf2',
	      SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	      clean  => {'FILES' => 'libfastgf2$(LIB_EXT)'},
	     );

sub MY::top_targets {
'
all :: static

pure_all :: static

static ::       libfastgf2$(LIB_EXT)

libfastgf2$(LIB_EXT): FastGF2.o Matrix.o
	$(AR) cr libfastgf2$(LIB_EXT) FastGF2.o Matrix.o
	$(RANLIB) libfastgf2$(LIB_EXT)

';
}
