use strict;
use warnings;

use Test::More;
if ($ENV{RUN_MAINTAINER_TESTS}) {
    plan 'tests' => 6;
} else {
    plan 'skip_all' => 'Module maintainer tests';
}

SKIP: {
    if (! eval 'use Test::Pod 1.26; 1') {
        skip('Test::Pod 1.26 required for testing POD', 1);
    }

    pod_file_ok('lib/Math/Random/MT/Auto.pm');
    pod_file_ok('lib/Math/Random/MT/Auto/Range.pm');
}

SKIP: {
    if (! eval 'use Test::Pod::Coverage 1.08; 1') {
        skip('Test::Pod::Coverage 1.08 required for testing POD coverage', 1);
    }

    pod_coverage_ok('Math::Random::MT::Auto',
                    {
                        'trustme' => [
                            qr/^(?:array|as_string|bool)$/,
                        ],
                        'private' => [
                            qr/^(import|bootstrap)$/,
                            qr/^_/
                        ]
                    }
    );

    pod_coverage_ok('Math::Random::MT::Auto::Range',
                    {
                        'trustme' => [
                            qr/^(?:array|as_string|bool)$/,
                        ],
                        'private' => [
                            qr/^_/,
                        ]
                    }
    );
}

SKIP: {
    if (! eval 'use Test::Spelling; 1') {
        skip('Test::Spelling required for testing POD spelling', 1);
    }
    if (system('aspell help >/dev/null 2>&1')) {
        skip("'aspell' required for testing POD spelling", 1);
    }
    set_spell_cmd('aspell list --lang=en');
    add_stopwords(<DATA>);
    pod_file_spelling_ok('lib/Math/Random/MT/Auto.pm', 'MRAM POD spelling');
    pod_file_spelling_ok('lib/Math/Random/MT/Auto/Range.pm', 'MRMA::Range POD spelling');
    unlink("/home/$ENV{'USER'}/en.prepl", "/home/$ENV{'USER'}/en.pws");
}

exit(0);

__DATA__

Cokus's
FreeBSD
Hedden
HotBits
MSWin32
Makoto
Mersenne
Nishimura
OO
OSs
OpenBSD
PRNG
PRNGs
Programmatically
QUICKSTART
RPNG
RandomNumbers.info
RandomNumbers.info's
SRCS
Solaris
Takuji
Wikipedia
XP
XSLoader
cpan
erlang
gaussian
irand
poisson
pseudorandom
src
0xFFFFFFFF
MERCHANTABILITY
Matsumoto
Redistributions
optimizations
selectable
situ

Arg
PRNG's
subclasses

__END__
