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
    NAME                => 'Locale::Unicode::Data',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Locale/Unicode/Data.pm',
    ABSTRACT_FROM       => 'lib/Locale/Unicode/Data.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => 
    {
        # available in perl v5.10
        'strict'                => 0,
        'vars'                  => 0,
        'version'               => 0,
        'warnings'              => 0,
        'warnings::register'    => 0,
        # 2010-04-29
        'DBI'                   => '1.611',
        # Foreign key constraints since SQLite v3.6.19 (2009-10-14)
        # DBD::SQLite 1.27 (2009-11-23)
        # utf8 auto decoding from version 1.68 (2021-07-22)
        'DBD::SQLite'           => '1.27',
        # 2008-03-12
        'Encode'                => '2.24',
        # 2007-12-24
        'File::Spec'            => '3.2501',
        # 2007-12-19
        'JSON'                  => '2.00',
        'Locale::Unicode'       => 'v0.3.8',
        'Scalar::Util'          => 0,
        # 2004-11-05
        # 'URI::file'             => '4.19',
        # Version compatible with perl v5.10
        'Want'                  => '0.17',
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
    # 2007-12-18
    MIN_PERL_VERSION    => 'v5.10',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Locale-Unicode-Data-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Locale-Unicode-Data.git',
                web         => 'https://gitlab.com/jackdeguest/Locale-Unicode-Data',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Locale-Unicode-Data/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
