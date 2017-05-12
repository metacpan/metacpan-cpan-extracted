use ExtUtils::MakeMaker;
$Verbose = 1;

WriteMakefile(
    NAME => 'Gzip::RandomAccess::libzran',
    SKIP => [qw(all test)],
    clean => {'FILES' => 'libzran${LIB_EXT}'},
);

sub MY::top_targets {
return <<'END'

all :: static

test ::

static :: libzran$(LIB_EXT)

libzran$(LIB_EXT): $(O_FILES)
	$(AR) cr libzran$(LIB_EXT) $(O_FILES)
	$(RANLIB) libzran$(LIB_EXT)

END
}
