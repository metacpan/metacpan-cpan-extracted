use strict;
use warnings;

use 5.008003;

use Config;
use ExtUtils::MakeMaker;

my %RUN_DEPS = (
    'Carp'           => 0,
    'Cwd'            => $^O eq 'darwin' ? '3' : '3.12',
    'File::Basename' => 0,
    'File::Path'     => '2.01',
    'File::Spec'     => $^O eq 'darwin' ? '3' : '3.12',
    'File::Temp'     => '0.19',
    'File::Which'    => '0.05',
    # Dependencies for specific platforms
    ### Use variable twice to avoid a warning
    (
             $MacPerl::Version and $MacPerl::Version
          or $^O eq 'darwin'   and _check_old_mac_os_x()
    ) ? ('Mac::Files' => 0) : ($^O eq 'darwin' ? ('Mac::SystemDirectory' => '0.04') : ()),
    ($^O eq 'MSWin32') ? ('Win32' => '0.31') : (),
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
    'POSIX'               => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More' => 0.90,
);

WriteMakefile1(
    MIN_PERL_VERSION => '5.008003',
    META_ADD         => {
        'meta-spec' => {version => 2},
        resources   => {
            homepage   => 'https://metacpan.org/release/File-HomeDir',
            repository => {
                url  => 'https://github.com/perl5-utils/File-HomeDir.git',
                web  => 'https://github.com/perl5-utils/File-HomeDir',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=File-HomeDir',
                mailto => 'bug-File-HomeDir@rt.cpan.org',
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
                    'Test::Perl::Critic'                  => 0,
                    'Test::PerlTidy'                      => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                    'Test::Spelling'                      => 0,
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build   => {requires => {%BUILD_DEPS}},
            test    => {requires => {%TEST_DEPS}},
            runtime => {
                requires => {
                    %RUN_DEPS,
                    perl => '5.8.3',
                },
            },
        },
    },
    NAME               => 'File::HomeDir',
    VERSION_FROM       => 'lib/File/HomeDir.pm',
    ABSTRACT_FROM      => 'lib/File/HomeDir.pm',
    LICENSE            => 'perl',
    AUTHOR             => q{Adam Kennedy <adamk@cpan.org>},
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    PREREQ_PM          => \%RUN_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    test               => {TESTS => 't/*.t xt/*.t'},
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

    WriteMakefile(%params);
}

sub _check_old_mac_os_x
{
    local $@;
    $Config{ptrsize} == 8 and return;
    return eval {
        require POSIX;
        my $release = (POSIX::uname())[2];
        my ($major) = split qr{ [.] }smx, $release;
        # 'old' means before darwin 8 = Mac OS 10.4 = Tiger
        $major < 8;
    };
}
