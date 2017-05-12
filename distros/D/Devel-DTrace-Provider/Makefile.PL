use ExtUtils::MakeMaker;
use Config;

# Try to work out if DTrace is available.
my $dtrace = 0;
$dtrace = 1 if -f '/usr/include/sys/dtrace.h';

# We need to know the architecture of the Perl binary we'll link with.
# There's nothing that directly in %Config, as support for 64 bit
# integers in Perl doesn't necessarily indicate an amd64 build. 
# So, we figure it out from the symbols defined by the preprocessor.
#
my $cpp = $Config{cppsymbols};
my $arch;
if ($cpp =~ /__i386/) { # match __i386__ and __i386 for gcc and Sun CC.
    $arch = 'i386';
}
elsif ($cpp =~ /__x86_64__/) {
    $arch = 'x86_64';
}
else {
    die "Don't know which ARCH value to use for: $Config{archname}"
         if $dtrace;
}

# Extract the appropriate compiler from Perl - we should use the same
# compiler as Perl was built with and thus the extension will be built
# with.
my $cc = $Config{cc};

# Add a section to the Makefile to build libusdt as a dependency of
# the Perl extension, if DTrace appears to be available.
#
sub MY::postamble {
    if ($dtrace) {
        return <<"MAKE_FRAG";
\$(MYEXTLIB): libusdt/Makefile
	cd libusdt && CC=$cc ARCH=$arch \$(MAKE) all

MAKE_FRAG

    }
    else {
        return <<"MAKE_FRAG";
\$(MYEXTLIB): libusdt/Makefile
	\$(NOECHO) \$(NOOP)

MAKE_FRAG
    }
}

WriteMakefile(
    NAME          => 'Devel::DTrace::Provider',
    VERSION_FROM  => 'lib/Devel/DTrace/Provider.pm',
    ABSTRACT_FROM => 'lib/Devel/DTrace/Provider.pm',
    AUTHOR        => 'Chris Andrews <chris@nodnol.org>',
    INC           => '-Ilibusdt',
    MYEXTLIB      => 'libusdt/libusdt.a',
    OBJECT        => '$(O_FILES)',
    PREREQ_PM     => {
        'Sub::Install' => 0,
        'Sub::Exporter' => 0,
        'JSON' => 0
    },
    ($dtrace ? () : (NEEDS_LINKING => 0, SKIP => ['dynamic'])),
);
