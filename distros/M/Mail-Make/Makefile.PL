use strict;
use warnings;
use ExtUtils::MakeMaker;

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
    NAME                => 'Mail::Make',
    VERSION_FROM        => 'lib/Mail/Make.pm',
    ABSTRACT_FROM       => 'lib/Mail/Make.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'bytes'                 => 0,
        'constant'              => 0,
        'parent'                => 0,
        'strict'                => 0,
        'utf8'                  => 0,
        'warnings'              => 0,
        'Authen::SASL'          => '2.2000',
        'Data::UUID'            => '1.227',
        'Encode'                => '3.21',
        'Exporter'              => '5.77',
        'File::Which'           => '1.27',
        'IPC::Run'              => '20250809.0',
        'MIME::Base64'          => '3.16',
        'MIME::QuotedPrint'     => '3.16',
        'Module::Generic'       => 'v1.2.2',
        # SSL/StartTLS support; ships with Perl >= 5.22
        'Net::SMTP'             => '3.06',
        'URI::Escape::XS'       => '0.14',
    },
    TEST_REQUIRES =>
    {
        'lib'           => 0,
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'utf8'          => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.28.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Mail-Make-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Mail-Make.git',
                web         => 'https://gitlab.com/jackdeguest/Mail-Make',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Mail-Make/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
