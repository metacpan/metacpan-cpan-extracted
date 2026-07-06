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
    NAME                => 'HTML::Object',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/HTML/Object.pm',
    ABSTRACT_FROM       => 'lib/HTML/Object.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => 
    {
        'constant'                      => 0,
        'curry'                         => '1.001000',
        'overload'                      => 0,
        'parent'                        => 0,
        'strict'                        => 0,
        'vars'                          => 0,
        'warnings'                      => 0,
        'warnings::register'            => 0,
        'Config'                        => 0,
        'CSS::Object'                   => 'v0.2.1',
        'Data::UUID'                    => '1.226',
        'DateTime::Format::Lite'        => 'v0.1.3',
        'DateTime::Format::Unicode'     => 'v0.3.0',
        'DateTime::Lite'                => 'v0.7.3',
        'DateTime::Locale::FromCLDR'    => 'v0.8.7',
        # 'Devel::Confess'                => '0.009004',
        'Digest::MD5'                   => '2.58',
        'Encode'                        => '3.08',
        'Exporter'                      => '5.74',
        'Filter::Util::Call'            => '1.64',
        'HTML::Parser'                  => '3.85',
        'HTML::Selector::XPath'         => '0.28',
        'JSON'                          => '4.10',
        'List::Util'                    => '1.56',
        'Locale::Unicode'               => 'v0.4.3',
        'Locale::Unicode::Data'         => 'v1.8.6',
        'Module::Generic'               => 'v1.6.2',
        'POSIX'                         => 0,
        'Promise::Me'                   => 'v0.6.0',
        'Scalar::Util'                  => '1.60',
        'Time::HiRes'                   => '1.9764',
        'URI'                           => '5.28',
        'Wanted'                        => 'v0.1.2',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'Test::More'        => '1.302162',
        # Version under perl v5.16.0
        'Test::Pod'         => '1.52',
        'File::Find'        => 0,
        'File::Spec'        => 0,
        'HTML::Entities'    => '3.76',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'HTML-Object-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:deguest/HTML-Object.git',
                web         => 'https://gitlab.com/deguest/HTML-Object',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/deguest/HTML-Object/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
