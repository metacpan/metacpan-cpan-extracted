use 5.20.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mail::DKIM2',
    AUTHOR           => 'Bron Gondwana <brong@fastmailteam.com>',
    VERSION_FROM     => 'lib/Mail/DKIM2.pm',
    ABSTRACT         => 'DKIM2 signing and verification for email',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.20.0',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },

    BUILD_REQUIRES => {
        'Test::More'  => '0.96',
    },

    PREREQ_PM => {
        'Algorithm::Diff'                        => '0',
        'Carp'                                   => '0',
        'CryptX'                                 => '0.060',
        'Email::MIME'                            => '0',
        'Exporter'                               => '0',
        'File::Path'                             => '0',
        'JSON'                                   => '0',
        'List::Util'                             => '0',
        'MIME::Base64'                           => '0',
        'Net::DNS'                               => '0',
    },

    TEST_REQUIRES => {
        'Path::Tiny'      => '0',
        'Test::More'      => '0.96',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    # dkim2-milter
                    'Sendmail::PMilter' => '1.28',   # 1.27 never answered MAIL FROM:<>
                    # dkim2-split-lmtp
                    'Net::SMTP'   => '0',
                    'Sys::Syslog' => '0',
                    # the authentication_milter handlers
                    'Mail::Milter::Authentication' => '0',
                    'Mail::AuthenticationResults'  => '0',
                },
            },
            test => {
                recommends => {
                    'Test::Pod'           => '1.22',
                    'Test::Pod::Coverage' => '1.08',
                    # t/turscar.t, when the dkim2tests submodule is present.
                    'TOML::Parser'        => '0',
                },
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/dkim2wg/interop.git',
                web  => 'https://github.com/dkim2wg/interop',
            },
            bugtracker => {
                web => 'https://github.com/dkim2wg/interop/issues',
            },
        },
    },

    EXE_FILES => [
        'bin/dkim2sign',
        'bin/dkim2verify',
        'bin/dkim2-milter',
        'bin/dkim2-split-lmtp',
    ],

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mail-DKIM2-*' },
);
