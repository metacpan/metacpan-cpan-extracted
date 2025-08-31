use ExtUtils::MakeMaker;
use strict;
use warnings;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'HTTP::Promise',
    VERSION_FROM        => 'lib/HTTP/Promise.pm',
    ABSTRACT_FROM       => 'lib/HTTP/Promise.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'constant'              => 0,
        'parent'                => 0,
        'strict'                => 0,
        'warnings'              => 0,
        'Cookie'                => 'v0.3.5',
        'CryptX'                => '0.078',
        'Cwd'                   => 0,
        'Data::UUID'            => '1.226',
        'DateTime'              => '1.59',
        'DateTime::Format::Strptime' => '1.79',
        'DateTime::TimeZone'    => '2.60',
        'Encode'                => '3.19',
        'Errno'                 => 0,
        'Fcntl'                 => 0,
        # 'File::MMagic::XS'      => '0.09008',
        'File::MMagic'          => '1.30',
        'HTTP::Parser2::XS'     => '0.01',
        'HTTP::XSHeaders'       => '0.400005',
        'IO::File'              => 0,
        'JSON'                  => '4.10',
        'JSON::XS'              => '4.03',
        'Module::Generic'       => 'v1.0.4',
        # 'Nice::Try'             => 'v1.3.4',
        'Promise::Me'           => 'v0.6.0',
        'Regexp::Common'        => '2017060201',
        'Scalar::Util'          => '1.63',
        'Socket'                => '2.037',
        # URI::Fast is great, but only supports simple protocols
        # 'URI::Fast'             => '0.55',
        'Symbol'                => 0,
        'Time::HiRes'           => '1.9764',
        'URI'                   => '5.21',
        'URI::Encode::XS'       => '0.11',
        'URI::Escape::XS'       => '0.14',
        'URL::Encode::XS'       => '0.03',
        'Wanted'                => 'v0.1.0',
    },
    TEST_REQUIRES =>
    {
        'lib'           => 0,
        # 'Test::HTTP::MockServer' => 'v0.0.1',
        # 'Test::HTTP::LocalServer' => '0.74',
        # 'HTTP::Daemon'  => '6.14',
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'Test2::IPC'    => '1.302190',
        'Test2::V0'     => '0.000145',
        'utf8'          => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'HTTP-Promise-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/HTTP-Promise.git',
                web         => 'https://gitlab.com/jackdeguest/HTTP-Promise',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/HTTP-Promise/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
