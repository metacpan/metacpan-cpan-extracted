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

# The C parsing engine is optional: without a compiler, or with PUREPERL_ONLY=1 (or the
# environment variable PERL_ONLY), the distribution installs in pure Perl.
my $pure_perl = grep( /^PUREPERL_ONLY=1$/, @ARGV ) || $ENV{PERL_ONLY} ? 1 : 0;
@ARGV = grep( !/^PUREPERL_ONLY=/, @ARGV );
my $has_cc;
if( !$pure_perl )
{
    $has_cc = eval
    {
        require ExtUtils::CBuilder;
        ExtUtils::CBuilder->new( quiet => 1 )->have_compiler;
    };
    if( !$has_cc )
    {
        warn( "No C compiler found: Locale::Unicode::RBNF will be installed in pure Perl.\n" );
        $pure_perl = 1;
    }
}

my %WriteMakefileArgs = (
    NAME                => 'Locale::Unicode::RBNF',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Locale/Unicode/RBNF.pm',
    ABSTRACT_FROM       => 'lib/Locale/Unicode/RBNF.pm',
    PL_FILES            => {},
    LICENSE             => 'perl_5',
    INSTALLDIRS         => ( $] < 5.011 ? 'perl' : 'site' ),
    MIN_PERL_VERSION    => 'v5.10.1',
    PREREQ_PM           => {
        # Core modules
        'parent'                => 0,
        'strict'                => 0,
        'vars'                  => 0,
        'warnings'              => 0,
        'Exporter'              => '5.57',
        'File::Spec'            => 0,
        'Locale::Unicode'       => 'v0.4.6',
        'Math::BigInt'          => 0,
        'POSIX'                 => 0,
        'Scalar::Util'          => '1.19',
        'Unicode::Normalize'    => 0,
        'Unicode::UCD'          => 0,
        'XSLoader'              => 0,
        # Version compatible with perl v5.10
        'Wanted'                => 'v0.1.2',
        'XML::LibXML'           => '1.70',
    },
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'   => '6.64',
        'ExtUtils::CBuilder'    => 0,
    },
    TEST_REQUIRES       => {
        'lib'                   => '0',
        'open'                  => '0',
        'utf8'                  => '0',
        'Test::More'            => '0.98',
    },
    ( $has_cc
        ? (
            XS      => { 'Locale-Unicode-RBNF.xs' => 'Locale-Unicode-RBNF.c' },
            OBJECT  => 'Locale-Unicode-RBNF$(OBJ_EXT)',
        )
        : ()
    ),
    INC     => '-I.',
    # Do not recurse into subdirectories
    DIR     => [],
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean   => { FILES => 'Locale-Unicode-RBNF-* Locale-Unicode-RBNF.c Locale-Unicode-RBNF$(OBJ_EXT)' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        no_index       =>
        {
            directory => [ 't' ],
        },
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:deguest/Locale-Unicode-RBNF.git',
                web         => 'https://gitlab.com/deguest/Locale-Unicode-RBNF',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/deguest/Locale-Unicode-RBNF/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
