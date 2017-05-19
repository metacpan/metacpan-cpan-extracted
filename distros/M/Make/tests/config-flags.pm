# This is a -*-perl-*- script
#
# Set variables that were defined by configure, in case we need them
# during the tests.

%CONFIG_FLAGS = (
    AM_LDFLAGS   => '-rdynamic',
    AR           => 'ar',
    CC           => 'gcc',
    CFLAGS       => '-g -O2',
    CPP          => 'gcc -E',
    CPPFLAGS     => '-I/usr/local/include',
    GUILE_CFLAGS => '',
    GUILE_LIBS   => '',
    LDFLAGS      => '',
    LIBS         => ''
);

1;
