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
    NAME                => 'Markdown::Parser',
    VERSION_FROM        => 'lib/Markdown/Parser.pm',
    ABSTRACT_FROM       => 'lib/Markdown/Parser.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PL_FILES            => {},
    PREREQ_PM           => {
        'strict'            => 0,
        'warnings'          => 0,
        'parent'            => '0.238',
        'vars'              => 0,
        'CSS::Object'       => 'v0.2.0',
        'HTML::Object'      => 'v0.6.0',
        'Module::Generic'   => 'v1.1.3',
    	'POSIX'             => '1.53_01',
    	'Regexp::Common::Markdown' => 'v0.1.8',
        'URI'               => '5.21',
    },
    TEST_REQUIRES       => {
        'File::Find'        => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Markdown-Parser-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Markdown-Parser.git',
                web         => 'https://gitlab.com/jackdeguest/Markdown-Parser',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Markdown-Parser/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
