use ExtUtils::MakeMaker;
$Verbose = 1;

WriteMakefile(
	NAME   => 'Digest::FNV::fnvlib',
	SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	clean  => {'FILES' => 'libfnv$(LIBEEXT)'},
);

sub MY::top_targets {
'
all :: static
pure_all :: static
static ::       libfnv$(LIB_EXT)
libfnv$(LIB_EXT): $(O_FILES)
	$(AR) cr libfnv$(LIB_EXT) $(O_FILES)
	$(RANLIB) libfnv$(LIB_EXT)
';
}
