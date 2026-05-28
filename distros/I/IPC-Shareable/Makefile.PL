use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my $ccflags  = $Config{ccflags};
my $lddlflags = $Config{lddlflags};

# On macOS, system cc may target a different architecture than Perl was
# built for (e.g. x86_64 perlbrew under Rosetta on Apple Silicon).
# uname -m lies under Rosetta; use sysctl instead.
if ($^O eq 'darwin') {
    my $arm64_native = `sysctl -n hw.optional.arm64 2>/dev/null`;
    chomp $arm64_native;
    if ($arm64_native && $ccflags !~ /arm64/ && $ccflags !~ /-arch/) {
        $ccflags   .= ' -arch x86_64';
        $lddlflags .= ' -arch x86_64';
    }
}

my $have_cc = system(qq(echo 'int main(void){return 0;}' | $Config{cc} $ccflags -xc - -o /dev/null 2>/dev/null)) == 0;

my @xs_args;
if ($have_cc) {
    @xs_args = (XS => { 'Shareable.xs' => 'Shareable.c' });
}
else {
    @xs_args = (XS => {}, C => [], PL_FILES => {});
}

WriteMakefile(
    NAME              => 'IPC::Shareable',
    VERSION_FROM      => 'lib/IPC/Shareable.pm',
    CCFLAGS           => $ccflags,
    LDDLFLAGS         => $lddlflags,
    ($] >= 5.010 ?
      (ABSTRACT_FROM  => 'lib/IPC/Shareable.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => [],
    DEFINE            => '',
    INC               => '',
    @xs_args,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/ipc-shareable/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/ipc-shareable.git',
                web => 'https://github.com/stevieb9/ipc-shareable',
            },
        },
    },
    MIN_PERL_VERSION   => 5.010,
    LICENSE => 'perl_5',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.72,
    },
    BUILD_REQUIRES => {
        'IPC::Semaphore' => 0,
        'Mock::Sub'      => 0,
        'Test::More'       => 0.98,
        'Test::SharedFork' => 0.35,
    },
    PREREQ_PM    => {
        'Class::Struct' => 0,
        'Digest::MD5'   => 0,
        'JSON'          => 0,
        'Scalar::Util'  => 0,
        'Storable'      => 0.607,
        'String::CRC32' => 0,
    },
);

# Strip macOS extended attributes and AppleDouble metadata from dist
# tarballs (LIBARCHIVE.xattr.* headers cause warnings on Linux tar).
sub MY::postamble {
    return $^O eq 'darwin' ? "TARFLAGS = --no-mac-metadata -cvf\n" : '';
}
