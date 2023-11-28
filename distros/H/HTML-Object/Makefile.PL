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
        'constant'              => '1.33',
        'curry'                 => '1.001000',
        'overload'              => '1.30',
        'parent'                => 0,
        'strict'                => 0,
        'vars'                  => 0,
        'warnings'              => 0,
        'warnings::register'    => 0,
        'Config'                => 0,
        'CSS::Object'           => 'v0.1.5',
        'Data::UUID'            => '1.226',
        'DateTime::Format::Strptime' => '1.79',
        'Devel::Confess'        => '0.009004',
        'Digest::MD5'           => '2.58',
        'Encode'                => '3.08',
        'Exporter'              => '5.74',
        'Filter::Util::Call'    => '1.60',
        'HTML::Parser'          => '3.76',
        'HTML::Selector::XPath' => '0.26',
        'JSON'                  => '4.05',
        'List::Util'            => '1.56',
        'Module::Generic'       => 'v0.32.4',
        'POSIX'                 => 0,
        'Promise::Me'           => 'v0.4.7',
        'Scalar::Util'          => '1.60',
        'Time::HiRes'           => '1.9764',
        'URI'                   => '5.10',
        'Want'                  => '0.29',
    },
    TEST_REQUIRES =>
    {
        'lib'           => '0.65',
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'DateTime'      => '1.55',
        'File::Find'    => 0,
        'File::Spec'    => '3.78',
        'HTML::Entities'    => '3.76',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'HTML-Object-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/HTML-Object.git',
                web         => 'https://gitlab.com/jackdeguest/HTML-Object',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/HTML-Object/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
