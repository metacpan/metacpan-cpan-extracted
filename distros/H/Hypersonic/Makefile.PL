use strict;
use warnings;
use ExtUtils::MakeMaker;

# Windows support is single-process / single-worker only and excludes
# Future/Pool (no fork(), no pthread/eventfd). The basic HTTP server
# works via Winsock + the select() event backend. See Changes 0.14
# for details. We no longer OS_UNSUPPORTED here; install proceeds.

# Check if Alien::OpenSSL is available for TLS support
my $has_alien_openssl = eval { require Alien::OpenSSL; 1 };

my %prereqs = (
    'XS::JIT' => '0.24',
    'Cpanel::JSON::XS' => '0',
);

# Recommended dependencies for better library detection (CPAN standard)
my %recommends = (
    'Devel::CheckLib'     => '0',   # CPAN standard for compile+link tests
    'ExtUtils::PkgConfig' => '0',   # Perl interface to pkg-config
);

# Add Alien::OpenSSL as optional dependency for TLS
if ($has_alien_openssl || $ENV{HYPERSONIC_TLS}) {
    $prereqs{'Alien::OpenSSL'} = '0';
}

WriteMakefile(
    NAME             => 'Hypersonic',
    VERSION_FROM     => 'lib/Hypersonic.pm',
    ABSTRACT         => 'A JIT HTTP server',
    AUTHOR           => 'LNATION',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM => \%prereqs,
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => \%recommends,
            },
        },
    },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hypersonic-* _hypersonic_cache' },
);

# Pure-Perl at install time; XS is JIT-compiled at run time by XS::JIT.
# Older MakeMaker versions otherwise emit a `cc ... Hypersonic.o -o
# .../Hypersonic.so` rule that fails because there's no Hypersonic.xs.
package MY;
sub dynamic     { '' }
sub dynamic_lib { '' }
sub dynamic_bs  { '' }
sub static      { '' }
sub static_lib  { '' }
