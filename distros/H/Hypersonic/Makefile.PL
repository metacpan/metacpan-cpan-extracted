use strict;
use warnings;
use ExtUtils::MakeMaker;

# Check if Alien::OpenSSL is available for TLS support
my $has_alien_openssl = eval { require Alien::OpenSSL; 1 };

my %prereqs = (
    'XS::JIT' => '0.08',
    'Cpanel::JSON::XS' => '0',
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
    },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hypersonic-* _hypersonic_cache' },
);
