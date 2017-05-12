#!perl

use strict;
use warnings;

use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile1(
    NAME       => 'ExtUtils::BundleMaker',
    LICENSE           => 'perl',
    AUTHOR       => q{Jens Rehsack <rehsack@cpan.org>},
    VERSION_FROM => 'lib/ExtUtils/BundleMaker.pm',
    ABSTRACT_FROM => 'lib/ExtUtils/BundleMaker.pm',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                url  => 'git://github.com/rehsack/ExtUtils-BundleMaker.git',
                web  => 'https://github.com/rehsack/ExtUtils-BundleMaker',
                type => 'git',
            },
            license    => ['http://dev.perl.org/licenses/'],
            bugtracker => {
                web    => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-BundleMaker',
                mailto => 'bug-extutils-bundlemaker@rt.cpan.org',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                },
            },
            runtime => {
                requires => {
                    'File::Basename'       => 0,
                    'File::Path'           => 0,
                    'File::Slurp'          => 0,
                    'File::Spec'           => 0,
                    'MetaCPAN::Client'     => 0,
                    'Moo'                  => 0,
                    'MooX::Options'        => '4.000',
                    'MooX::ConfigFromFile' => 0,
                    'Module::CoreList'     => '2.99',
                    'Module::Runtime'      => 0,
                    'Params::Util'         => 0,
                    'version'              => 0,
                },
                recommends => {
                    'CHI'                    => 0,
                    'HTTP::Tiny::Mech'       => 0,
                    'MetaCPAN::Client'       => '1.003000',
                    'WWW::Mechanize::Cached' => 0,
                },
            },
            test => {
                requires => {
                    'Module::Runtime'     => 0,
                    'Test::Directory'     => 0,
                    'Test::More'          => '0.90',
                    'Test::WriteVariants' => '0.005',
                },
                suggests => {
                    'Config::AutoConf'   => '0.27',
                    'ExtUtils::CBuilder' => '0.280216'
                },
            },
        },
    },
    test           => { TESTS => 't/*.t xt/*.t' },
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if ( exists( $params{EXTRA_META} ) );
    die "License not specified"    if ( !exists( $params{LICENSE} ) );
    if ( $params{TEST_REQUIRES} and ( $eumm_version < 6.6303 ) )
    {
        if ( $params{BUILD_REQUIRES} )
        {
            $params{BUILD_REQUIRES} = { %{ $params{BUILD_REQUIRES} }, %{ $params{TEST_REQUIRES} } };
        }
        else
        {
            $params{BUILD_REQUIRES} = delete $params{TEST_REQUIRES};
        }
    }
    if ( $params{BUILD_REQUIRES} and ( $eumm_version < 6.5503 ) )
    {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES}    if ( $eumm_version < 6.52 );
    delete $params{MIN_PERL_VERSION}      if ( $eumm_version < 6.48 );
    delete $params{META_MERGE}            if ( $eumm_version < 6.46 );
    delete $params{META_ADD}{prereqs}     if ( $eumm_version < 6.58 );
    delete $params{META_ADD}{'meta-spec'} if ( $eumm_version < 6.58 );
    delete $params{META_ADD}              if ( $eumm_version < 6.46 );
    delete $params{LICENSE}               if ( $eumm_version < 6.31 );
    delete $params{AUTHOR}                if ( $] < 5.005 );
    delete $params{ABSTRACT_FROM}         if ( $] < 5.005 );
    delete $params{BINARY_LOCATION}       if ( $] < 5.005 );

    # more or less taken from Moose' Makefile.PL
    if ( $params{CONFLICTS} )
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ( $params{PREREQ_FATAL} and not $ok );
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ( $cpan_smoker || $ENV{PERL_MM_USE_DEFAULT} )
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
