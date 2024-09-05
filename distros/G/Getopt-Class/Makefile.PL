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
    NAME                => 'Getopt::Class',
    VERSION_FROM        => 'lib/Getopt/Class.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'A class based approach for options of Getopt::Long',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'strict'            => 0,
        'vars'              => 0,
        'warnings'          => 0,
        'parent'            => 0,
        'Clone'             => '0.46',
        'DateTime'          => '1.51',
        'DateTime::Format::Strptime' => '1.76',
        # 'Devel::Confess'=> '0.009004',
        'Getopt::Long'      => '0.44',
        'Module::Generic'   => 'v0.37.5',
		# 'Nice::Try'		=> 'v1.3.5',
        'Scalar::Util'      => '1.54',
    	'Tie::Hash'         => '1.05',
    },
    TEST_REQUIRES       =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 5.6.0,
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Getlong-Class-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Getopt-Class.git',
                web         => 'https://gitlab.com/jackdeguest/Getopt-Class',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Getopt-Class/issues',
                mailto      => 'cpan-bug@deguest.jp',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
