use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	NAME   => 'Image::TestJPG::mydatasrc',
#	SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	clean  => {'FILES' => 'libmydatasrc$(LIBEEXT)'},
);

sub MY::top_targets {
'
all :: static

pure_all :: static

static ::	libmydatasrc$(LIB_EXT)

libmydatasrc$(LIB_EXT): $(O_FILES)
	$(AR) cr libmydatasrc$(LIB_EXT) $(O_FILES)
	$(RANLIB) libmydatasrc$(LIB_EXT)
';
}
