# How to add the shapereader library to a Perl XS module
#
# 1. Add the library to your Git project as a submodule.
#
#    git submodule add https://github.com/voegelas/shapereader.git
#
# 2. Include the header file into your .xs file.
#
#    #include "shapereader/shapereader.h"
#
# 3. Add the below settings to your dist.ini file.
#
#    [@Filter]
#    -bundle = @Basic
#    -remove = MakeMaker
#
#    [MakeMaker::Awesome]
#    WriteMakefile_arg = MYEXTLIB => 'shapereader/libshapereader$(LIB_EXT)'
#    delimiter = |
#    footer = |sub MY::postamble {
#    footer = |q{
#    footer = |$(MYEXTLIB): shapereader/Makefile
#    footer = |      cd shapereader && $(MAKE) $(PASSTHRU)
#    footer = |}
#    footer = |}
#
#    [Encoding]
#    encoding = bytes
#    match    = ^shapereader/tests/data/
#
#    [Prereqs / DevelopRequires]
#    Dist::Zilla = 0
#    Dist::Zilla::Plugin::MakeMaker::Awesome = 0.26

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

my @defines = qw(-DNDEBUG);

my $byteorder = $Config{byteorder};
if (!defined $byteorder) {
    warn "\$Config{byteorder} is undefined.\n";
    die "OS unsupported\n";
}

if ($byteorder == 4321 || $byteorder == 87654321) {
    push @defines, '-DWORDS_BIGENDIAN';
}
elsif (!($byteorder == 1234 || $byteorder == 12345678)) {
    warn "Unknown byte order: $byteorder\n";
    die "OS unsupported\n";
}

if (!defined $Config{d_longdbl}) {
    warn "long double is not available.\n";
    die "OS unsupported\n";
}

if (!defined $Config{d_longlong}) {
    warn "long long is not available.\n";
    die "OS unsupported\n";
}

if (!defined $Config{d_vsnprintf}) {
    warn "vsnprintf() is not available.\n";
    die "OS unsupported\n";
}

WriteMakefile(
    NAME   => 'shapereader',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {FILES => 'libshapereader$(LIB_EXT)'},
    DEFINE => join(q{ }, @defines),
);

sub MY::top_targets {
    q{
all :: static

pure_all :: static

static :: libshapereader$(LIB_EXT)

libshapereader$(LIB_EXT): $(O_FILES)
	$(AR) cr libshapereader$(LIB_EXT) $(O_FILES)
	$(RANLIB) libshapereader$(LIB_EXT)
};
}
