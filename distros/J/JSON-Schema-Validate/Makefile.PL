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
    NAME                => 'JSON::Schema::Validate',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/JSON/Schema/Validate.pm',
    ABSTRACT_FROM       => 'lib/JSON/Schema/Validate.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'overload'          => 0,
        'strict'            => 0,
        'utf8'              => 0,
        'warnings'          => 0,
        'vars'              => 0,
        'DateTime'          => 0,
        'DateTime::Duration'=> 0,
        'Encode'            => 0,
        'JSON'              => 0,
        'List::Util'        => 0,
        'Scalar::Util'      => 0,
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'JSON-Schema-Validate-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/JSON-Schema-Validate.git',
                web         => 'https://gitlab.com/jackdeguest/JSON-Schema-Validate',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/JSON-Schema-Validate/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

