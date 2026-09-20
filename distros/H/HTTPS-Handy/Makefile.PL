use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

my %args = (
    'NAME'      => q{HTTPS::Handy},
    'VERSION'   => q{1.01},
    'ABSTRACT'  => q{A tiny HTTPS/1.0 server, TLS included, in pure Perl},
    'PREREQ_PM' => {
        'Carp' => '0',
        'IO::Socket' => '0',
        'POSIX' => '0',
    },
    'AUTHOR'    => q{ina <ina.cpan@gmail.com>},
);

# Install bin/*.pl as executables (EUMM creates .bat wrappers on Win32).
# A dist without a bin/ directory is unaffected.
if (-d 'bin') {
    local *BINDIR;
    if (opendir(BINDIR, 'bin')) {
        $args{EXE_FILES} =
            [map { "bin/$_" } sort grep { /\.pl\z/ && -f "bin/$_" } readdir(BINDIR)];
        closedir(BINDIR);
    }
}

# LICENSE was introduced in ExtUtils::MakeMaker 6.31 (2006).
# Passing it to older versions produces an "is not a known parameter" warning
# without failing, but we suppress the noise by checking the version.
if ($ExtUtils::MakeMaker::VERSION >= 6.31) {
    $args{LICENSE} = q{perl};
}

# CONFIGURE_REQUIRES was introduced in ExtUtils::MakeMaker 6.52.  Older
# versions ignore an unknown parameter with a warning, so it is passed
# only when it is understood; the generated META files carry the same
# information for every toolchain.
if ($ExtUtils::MakeMaker::VERSION >= 6.52) {
    $args{CONFIGURE_REQUIRES} = {
        'ExtUtils::MakeMaker' => '5.4302',
    };
}

# MIN_PERL_VERSION (6.48) and META_MERGE (6.46) arrived together in the
# same EUMM release cycle; guard them under the higher threshold (6.48)
# so both are always either present or absent.
if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $args{MIN_PERL_VERSION} = q{5.00503};
    $args{META_MERGE} = {
        'meta-spec' => { version => 2 },
        'resources' => {
            'license'    => [ 'http://dev.perl.org/licenses/' ],
        },
        'provides' => {
            'HTTPS::Handy' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::BigInt' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::ChaCha' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::Crypt' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::EC' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::Input' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::RSA' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::TLS' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            },
            'HTTPS::Handy::X509' => {
                'file'    => 'lib/HTTPS/Handy.pm',
                'version' => '1.01',
            }
        },
    };
}

WriteMakefile(%args);

__END__
