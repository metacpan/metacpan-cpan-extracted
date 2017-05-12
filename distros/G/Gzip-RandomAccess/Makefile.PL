use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Gzip::RandomAccess',
    VERSION_FROM => 'lib/Gzip/RandomAccess.pm',
    LIBS => ['-lz'],
    DEFINE => '',
    INC => '',
    MYEXTLIB => 'libzran/libzran$(LIB_EXT)',
    dist => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz'},
    PREREQ_PM => {
        'version' => 0,
        'Test::More' => '0.47',
    },
);

sub MY::postamble {
return <<'END'
$(MYEXTLIB): libzran/Makefile
	cd libzran && $(MAKE) $(PASTHRU)
END
}
