use ExtUtils::MakeMaker;
WriteMakefile(
	NAME	=> 'GD::Chart::gdchart',
	SKIP	=> [qw(all static static_lib dynamic dynamic_lib)],
	DEFINE  => $DEFS,
	LIBS    => [join(' ', @LIBS)],
	clean	=> {'FILES' => 'libgdc$(LIB_EXT)'},
);

sub MY::top_targets {
	'
all :: static

pure_all :: static

static :: libgdc$(LIB_EXT)

libgdc$(LIB_EXT): $(O_FILES)
	$(AR) cr libgdc$(LIB_EXT) $(O_FILES)
	$(RANLIB)  libgdc$(LIB_EXT)
';
}

sub MY::post_constants {
	"\nLIBS = $Config::Config{libs}\n"
}
