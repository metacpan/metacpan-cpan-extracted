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
    NAME                => 'Locale::Unicode',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Locale/Unicode.pm',
    ABSTRACT_FROM       => 'lib/Locale/Unicode.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => 
    {
        # available in perl v5.10
        'overload'              => '1.06',
        'strict'                => 0,
        'vars'                  => 0,
        'warnings'              => 0,
        'warnings::register'    => 0,
        'Scalar::Util'          => 0,
        # Version compatible with perl v5.10
        'Want'                  => '0.17',
    },
    TEST_REQUIRES =>
    {
        'lib'           => '0.63',
        'DateTime::Locale' => 0,
        # Released 2017-11-30
        'Test::More'    => '1.302120',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.10',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Locale-Unicode-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Locale-Unicode.git',
                web         => 'https://gitlab.com/jackdeguest/Locale-Unicode',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Locale-Unicode/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
