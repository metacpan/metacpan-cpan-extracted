#!perl

use strict;
use warnings;

require 5.008_001;

BEGIN
{
    unless (grep { $_ eq "." } @INC)
    {
        use lib ".";
    }
}

use inc::latest 'Capture::Tiny';
use inc::latest 'Config::AutoConf';

if (inc::latest->can("write"))
{
    inc::latest->write("inc");
    for my $mod (inc::latest->loaded_modules)
    {
        inc::latest->bundle_module($mod, "inc");
    }
}

use ExtUtils::MakeMaker;

use inc::Config::AutoConf::LMU ();

inc::Config::AutoConf::LMU->_set_argv(@ARGV);    # XXX hack because we cannot construct for global use
inc::Config::AutoConf::LMU->check_lmu_prerequisites();
inc::Config::AutoConf::LMU->write_config_h("LMUconfig.h");

if (-d "Sandbox")
{
    eval "use Sandbox::Tumble ();";
    $@ and die $@;
    eval "use File::Path ();";
    File::Path->import;
    -d 't/xs' and rmtree('t/xs');
    Sandbox::Tumble->tumble(qw(t));
}

# Should we build the XS version?
my %RUN_DEPS = (
    'XSLoader' => "0.22",
);
my %BUNDLE_CONFIGURE_DEPS = (
    'inc::latest'      => '0.500',
    'Config::AutoConf' => '0.315',
);
my %CONFIGURE_DEPS = (
    'Carp'                => 0,
    'ExtUtils::MakeMaker' => 0,
    'File::Basename'      => 0,
    'File::Copy'          => 0,
    'File::Path'          => 0,
    'File::Spec'          => 0,
    'IPC::Cmd'            => 0,
    'base'                => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Storable'   => 0,
    'Test::More' => 0.96,
);
my @XS_FILES = qw(XS.xs);

my $conflictMsg = <<EOCM;
***
    This version of %s conflicts with
    the version of module %s (%s) you have installed.

    It's strongly recommended that you update it after
    installing this version of %s.
***
EOCM

my $selfConflictMsg = <<EOSCM;
***
    This version of %s conflicts with
    the version of %s (%s) you have installed.

    It's strongly recommended that you carefully read
    the Changes file and test your application with
    this version before finally upgrading.

    See local::lib how to do it easily.
***
EOSCM

WriteMakefile1(
    META_MERGE => {
        'meta-spec' => {version => 2},
        resources   => {
            homepage   => 'https://metacpan.org/release/List-MoreUtils-XS',
            repository => {
                url  => 'https://github.com/perl5-utils/List-MoreUtils-XS.git',
                web  => 'https://github.com/perl5-utils/List-MoreUtils-XS',
                type => 'git',
            },
            bugtracker => {
                web    => 'https://rt.cpan.org/Dist/Display.html?Name=List-MoreUtils-XS',
                mailto => 'bug-List-MoreUtils-XS@rt.cpan.org',
            },
            license => 'apache_2_0',
        },
        prereqs => {
            develop => {
                requires => {
                    "Test::CPAN::Changes"                 => 0,
                    "Test::CheckManifest"                 => 0,
                    "Module::CPANTS::Analyse"             => "0.96",
                    "Test::Kwalitee"                      => 0,
                    "Test::Perl::Critic"                  => 0,
                    "Test::PerlTidy"                      => 0,
                    "Test::Pod"                           => 0,
                    "Test::Pod::Coverage"                 => 0,
                    "Test::Pod::Spelling::CommonMistakes" => 0,
                    "Test::Spelling"                      => 0,
                }
            },
            configure => {
                requires   => {%CONFIGURE_DEPS},
                recommends => {%BUNDLE_CONFIGURE_DEPS},
            },
            build => {requires => {%BUILD_DEPS}},
            test  => {
                requires   => {%TEST_DEPS},
                recommends => {'Test::LeakTrace' => 0}
            },
            runtime => {
                requires => {%RUN_DEPS},
            },
        },
    },
    NAME         => 'List::MoreUtils::XS',
    ABSTRACT     => 'Provide the stuff missing in List::Util in XS',
    VERSION_FROM => 'lib/List/MoreUtils/XS.pm',
    AUTHOR       => [
        'Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>',
        'Adam Kennedy <adamk@cpan.org>',
        'Jens Rehsack <rehsack@cpan.org>'
    ],
    LICENSE            => 'apache_2_0',
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    PREREQ_PM          => \%RUN_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    XS                 => {map { (my $tgt = $_) =~ s/\.xs$/\.c/; $_ => $tgt; } @XS_FILES},
    MAGICXS            => 1,
    INC                => "-I.",
    (-d "Sandbox" ? (realclean => {FILES => "inc/latest* inc/inc_* t/xs config.log LMUconfig.h M*.bak"}) : ()),
    depend => {'$(FIRST_MAKEFILE)' => '$(VERSION_FROM)'},
    test   => {TESTS               => join(' ', 't/*.t', 't/xs/*.t', 'xt/*.t')},
    # Otherwise 'cxinc' isn't defined
    ($] < 5.012 ? (DEFINE => '-DPERL_EXT') : (),),
);

sub CheckConflicts
{
    my %params    = @_;
    my %conflicts = %{$params{CONFLICTS}};
    my $found     = 0;

    while (my ($module, $version) = each(%conflicts))
    {
        undef $@;
        eval "require $module";
        next if $@;
        my $installed = eval "\$" . $module . "::VERSION";
        if ($installed le $version)
        {
            ++$found;
            my $warning =
              (0 == index($module, $params{NAME}, 0))
              ? sprintf($selfConflictMsg, $params{NAME}, $module, $installed)
              : sprintf($conflictMsg, $params{NAME}, $module, $installed, $params{NAME});
            warn $warning;
        }
    }

    return !$found;
}

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
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ($cpan_smoker || $ENV{PERL_MM_USE_DEFAULT})
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
