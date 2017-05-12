use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'ForexConnect::ForexConnectWrapper',
    SKIP => [qw(all static static_lib dynamic dynamic_lib)],
    clean => {'FILES' => 'libForexConnectWrapper$(LIB_EXT)'},
    INC     => "-I$ENV{FXCONNECT_HOME}/include",
    LIBS    => ["-L$ENV{FXCONNECT_HOME}/lib -lForexConnect -lfxmsg"],
    'CC'                => 'g++',
    'LD'                => '$(CC)',
);

sub MY::top_targets {
'
    all :: static
    pure_all :: static
    static :: libForexConnectWrapper$(LIB_EXT)
    libForexConnectWrapper$(LIB_EXT): $(O_FILES)
			$(AR) cr libForexConnectWrapper$(LIB_EXT) $(O_FILES)
			$(RANLIB) libForexConnectWrapper$(LIB_EXT)
';
}
