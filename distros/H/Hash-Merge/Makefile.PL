use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

my %RUN_DEPS = (
    'Clone::Choose' => 0.008,
    'Scalar::Util'  => 0,
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => '6.64',
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More' => 0.90,
);

if (-d 'Sandbox')
{
    unless (grep { $_ eq '.' } @INC)
    {
        use lib '.';
    }
    eval "use Sandbox::Tumble ();";
    $@ and die $@;
    eval "use File::Path ();";
    File::Path->import;
    -d 't/Auto'     and rmtree('t/Auto');
    -d 't/Clone'    and rmtree('t/Clone');
    -d 't/Storable' and rmtree('t/Storable');
    -d 't/ClonePP'  and rmtree('t/ClonePP');
    Sandbox::Tumble->tumble(qw(t));
}

WriteMakefile1(
    MIN_PERL_VERSION => '5.008001',
    META_MERGE       => {
        'meta-spec'    => {version => 2},
        dynamic_config => 1,
        resources      => {
            repository => 'https://github.com/perl5-utils/Hash-Merge',
            license    => 'http://dev.perl.org/licenses/',
        },
        resources => {
            homepage   => 'https://metacpan.org/release/Hash-Merge',
            repository => {
                url  => 'https://github.com/perl5-utils/Hash-Merge.git',
                web  => 'https://github.com/perl5-utils/Hash-Merge',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Merge',
                mailto => 'hash-merge@rt.cpan.org',
            },
            license => 'http://dev.perl.org/licenses/',
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Module::CPANTS::Analyse'             => '0.96',
                    'Test::Kwalitee'                      => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                    'Test::Spelling'                      => 0,
                    'Test::Perl::Critic'                  => 0,
                    'Test::PerlTidy'                      => 0,
                    'Test::WriteVariants'                 => '0.014',
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build => {
                requires => {%BUILD_DEPS},
            },
            test => {
                requires => {%TEST_DEPS},
                suggests => {
                    'Clone'     => 0.10,
                    'Clone::PP' => 0,
                    'Storable'  => 0
                }
            },
            runtime => {
                requires => {
                    %RUN_DEPS,
                    perl => '5.8.1',
                },
            },
        },
    },
    NAME          => 'Hash::Merge',
    VERSION_FROM  => 'lib/Hash/Merge.pm',
    ABSTRACT_FROM => 'lib/Hash/Merge.pm',
    LICENSE       => 'perl',
    AUTHOR        => [
        q{Michael K. Neylon <mneylon-pm@masemware.com>},
        q{Daniel Muey <dmuey@cpan.org>},
        q{Jens Rehsack <rehsack@cpan.org>},
        q{Stefan Hermes <hermes@cpan.org>},
    ],
    PREREQ_PM          => \%RUN_DEPS,
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    test               => {TESTS => join(' ', 't/*.t', 'xt/*.t', 't/Auto/*.t', 't/Clone/*.t', 't/Storable/*.t', 't/ClonePP/*.t')},
    (-d 'Sandbox' ? (realclean => {FILES => join(' ', 't/Auto', 't/Clone', 't/Storable', 't/ClonePP', 'M*.bak')}) : ()),
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if (exists($params{EXTRA_META}));
    die "License not specified"    if (!exists($params{LICENSE}));
    $params{TEST_REQUIRES}
      and $eumm_version < 6.6303
      and $params{BUILD_REQUIRES} = {%{$params{BUILD_REQUIRES} || {}}, %{delete $params{TEST_REQUIRES}}};
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{BUILD_REQUIRES}
      and $eumm_version < 6.5503
      and $params{PREREQ_PM} = {%{$params{PREREQ_PM} || {}}, %{delete $params{BUILD_REQUIRES}}};
    ref $params{AUTHOR}
      and "ARRAY" eq ref $params{AUTHOR}
      and $eumm_version < 6.5702
      and $params{AUTHOR} = join(", ", @{$params{AUTHOR}});
    delete $params{CONFIGURE_REQUIRES}    if ($eumm_version < 6.52);
    delete $params{MIN_PERL_VERSION}      if ($eumm_version < 6.48);
    delete $params{META_MERGE}            if ($eumm_version < 6.46);
    delete $params{META_ADD}{prereqs}     if ($eumm_version < 6.58);
    delete $params{META_ADD}{'meta-spec'} if ($eumm_version < 6.58);
    delete $params{META_ADD}              if ($eumm_version < 6.46);
    delete $params{LICENSE}               if ($eumm_version < 6.31);
    delete $params{AUTHOR}                if ($] < 5.005);
    delete $params{ABSTRACT_FROM}         if ($] < 5.005);
    delete $params{BINARY_LOCATION}       if ($] < 5.005);

    # more or less taken from Moose' Makefile.PL
    if ($params{CONFLICTS})
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ($params{PREREQ_FATAL} and not $ok);
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ }
          keys %ENV;
        unless ($cpan_smoker
            || $ENV{PERL_MM_USE_DEFAULT}
            || $ENV{SQL_STATEMENT_WARN_UPDATE})
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
