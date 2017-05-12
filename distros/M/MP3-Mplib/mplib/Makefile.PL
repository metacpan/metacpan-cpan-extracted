use ExtUtils::MakeMaker;
#$Verbose = 1;
WriteMakefile(
    NAME   => 'MP3::Mplib::mplib',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {'FILES' => 'mplib$(LIBEEXT)'},
    test   => {'TESTS' => ''},
    OPTIMIZE => '-O3',
);

sub MY::top_targets {
    '
all :: static

static ::       mplib$(LIB_EXT)

mplib$(LIB_EXT): $(O_FILES)
	$(AR) cr mplib$(LIB_EXT) $(O_FILES)
	$(RANLIB) mplib$(LIB_EXT)

pure_all:
	
';
}


