use v5.10.1;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $module_name = 'Eval::Reversible';
my $module_file = 'lib/Eval/Reversible.pm';
my $dist_name   = 'Eval-Reversible';

# Standard boilerplate WriteMakefile args
my %WriteMakefileArgs = (
    NAME          => $module_name,
    DISTNAME      => $dist_name,
    VERSION_FROM  => $module_file,
    ABSTRACT_FROM => $module_file,
    AUTHOR        => 'Grant Street Group <developers@grantstreet.com>',
    LICENSE       => 'artistic_2',

    MIN_PERL_VERSION => '5.10.1',

    # Use a sane version of EUMM that supports *_REQUIRES
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },

    META_MERGE => {
        # Tells EUMM these properties are for CPAN::Meta::Spec v2
        'meta-spec' => { version => 2 },

        # GitHub links
        resources => {
            bugtracker => {
                web => "https://github.com/GrantStreetGroup/$dist_name/issues",
            },
            homepage   => "https://github.com/GrantStreetGroup/$dist_name",
            repository => {
                type => 'git',
                url  => "https://github.com/GrantStreetGroup/$dist_name.git",
                web  => "https://github.com/GrantStreetGroup/$dist_name",
            }
        },
        x_authority => 'cpan:GSG',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => "$dist_name-*" },
    test  => { TESTS => 't/*.t' },
);

# Per-dist customizations
%WriteMakefileArgs = (
    %WriteMakefileArgs,
    PREREQ_PM     => {
        # Start from "scan-perl-prereqs --pretty lib"

        'Moo'                    => '2.00',  # sane minimum baseline
        'MooX::HandlesVia'       => 0,
        'Scalar::Util'           => '1.25',  # sane minimum baseline
        'Types::Standard'        => '1.00',  # sane minimum baseline
        'namespace::clean'       => 0,
    },
    TEST_REQUIRES => {
        # Start from "scan-perl-prereqs --pretty t"

        'Test2::Bundle::More'     => 0,
        'Test2::Tools::Exception' => 0,
    },
);

# Other prereqs not in *_REQUIRES (https://metacpan.org/pod/CPAN::Meta::Spec#Prereq-Spec)
$WriteMakefileArgs{META_MERGE}{prereqs} = {
    develop => {
        requires => {
            'perl'                          => '5.10.1',
            'Module::Metadata'              => '1.00',    # sane minimum baseline
            'Perl::PrereqScanner'           => '1.023',   # sane minimum baseline
            'Pod::Markdown'                 => 0,
            'Pod::Markdown::Github'         => 0,
            'Pod::Readme'                   => 'v1.1.2',  # sane minimum baseline
            'Test2::Suite'                  => 0,
            'Test::CPAN::Changes'           => 0,
            'Test::Pod'                     => '1.51',    # sane minimum baseline
            'Test::Pod::Coverage'           => '1.10',    # sane minimum baseline
            'Test::Strict'                  => 0,
            'Test::Version'                 => '2.00',    # sane minimum baseline
        },
    },
};

WriteMakefile(%WriteMakefileArgs);

# Custom Makefile additions
package MY;

sub postamble {
    my $self = shift;
    return join("\n",
        '# The first line works around https://github.com/naturalist/pod-markdown-github/issues/7',
        'devdeps :',
        "\t".'cpanm --notest Pod::Markdown::Github',
        "\t".'cpanm --with-develop --installdeps .',
        '',
        'readme :',
        "\t".'$(PERLRUN) -MPod::Readme -e "Pod::Readme->new( input_file => \'$(VERSION_FROM)\', translate_to_file => \'README\',    translation_class => \'Pod::Simple::Text\'     )->run"',
        "\t".'$(PERLRUN) -MPod::Readme -e "Pod::Readme->new( input_file => \'$(VERSION_FROM)\', translate_to_file => \'README.md\', translation_class => \'Pod::Markdown::Github\' )->run"',
        '',
        'prove :',
        "\t".'prove -lr t/',
        '',
        'authorprove :',
        "\t".'AUTHOR_TESTING=1 prove -lr t/ xt/',
        '',
        'authortest :: TEST_FILES += xt/*.t',
        'authortest :: FULLPERLRUN := AUTHOR_TESTING=1 $(FULLPERLRUN)',
        'authortest :: test',
        '',
        'predist :: devdeps manifest readme authorprove',
    );
}

