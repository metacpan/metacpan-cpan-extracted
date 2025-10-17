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
    NAME                => 'Locale::Intl',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Locale/Intl.pm',
    ABSTRACT_FROM       => 'lib/Locale/Intl.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'parent'                => 0,
        'strict'                => 0,
        'warnings'              => 0,
        'Locale::Unicode'       => 'v0.3.11',
        'Locale::Unicode::Data' => 'v1.3.2',
        # Version compatible with perl v5.10
        'Wanted'                => 'v0.1.0',
    },
    TEST_REQUIRES =>
    {
        'lib'           => '0.63',
        'open'          => 0,
        'utf8'          => 0,
        'File::Find'    => 0,
        # Released 2017-11-30
        'Test::More'    => '1.302120',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.10.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Locale-Intl-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Locale-Intl.git',
                web         => 'https://gitlab.com/jackdeguest/Locale-Intl',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Locale-Intl/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

