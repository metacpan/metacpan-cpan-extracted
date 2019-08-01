#!perl

use strict;
use warnings;

use 5.008;

BEGIN
{
    unless (grep { $_ eq "." } @INC)
    {
        use lib ".";
    }
}

use inc::latest 'Capture::Tiny';
use inc::latest 'Config::AutoConf';

unless (-f "META.yml")
{
    if (inc::latest->can("write"))
    {
        inc::latest->write("inc");
        for my $mod (inc::latest->loaded_modules)
        {
            inc::latest->bundle_module($mod, "inc");
        }
    }
    eval <<EOEC;
use Devel::PPPort;
Devel::PPPort::WriteFile("ppport.h");
EOEC
}

use File::Basename ('dirname');
use ExtUtils::Constant;
use ExtUtils::MakeMaker;

use lib 'inc';
use Config::AutoConf::Log4cplus ();

Config::AutoConf::Log4cplus->_set_argv(@ARGV);    # XXX hack because we cannot construct for global use
Config::AutoConf::Log4cplus->check_log4cplus_prerequisites or die <<EOD;
*****************************************************
Your Perl installation is unable to build loadable XS
modules.

Please verify the way your Perl has been configured
and built and check your C compiler support.

For details what went wrong, check config.log
*****************************************************
EOD

Config::AutoConf::Log4cplus->check_liblog4cplus() or die <<EOD;
*************************************************************
Couldn't find log4cplus (at least version 2.0.0)
which is required for this module.

For details what went wrong, check config.log

To obtain it, go to
    https://sourceforge.net/projects/log4cplus/
or install the appropriate package for your operating system.
*************************************************************
EOD

Config::AutoConf::Log4cplus->check_log4cplus_header or die <<EOD;
*************************************************************
Couldn't find development files for log4cplus (at least
version 2.0.0) which is required for this module.

For details what went wrong, check config.log

To obtain it, go to
    https://sourceforge.net/projects/log4cplus/
or install the appropriate package for your operating system.
*************************************************************
EOD

my $xsfile   = "Log4cplus.xs";
my $config_h = File::Spec->catfile(dirname($xsfile), 'LLCconfig.h');
Config::AutoConf::Log4cplus->write_config_h("LLCconfig.h");
_write_constants();

my %RUN_DEPS = (
    'XSLoader' => "0.22",
);
my %BUNDLE_CONFIGURE_DEPS = (
    'inc::latest'      => '0.500',
    'Config::AutoConf' => '0.315',
);
my %CONFIGURE_DEPS = (
    'Capture::Tiny'       => '0.06',
    'Carp'                => 0,
    'Config::AutoConf'    => '0.308',
    'ExtUtils::MakeMaker' => 0,
    'ExtUtils::CBuilder'  => '0.27',
    'ExtUtils::Constant'  => '0.21',
    'File::Basename'      => 0,
    'File::Copy'          => 0,
    'File::Path'          => 0,
    'File::Spec'          => 0,
    'IPC::Cmd'            => 0,
    'parent'              => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Capture::Tiny'  => '0.06',
    'Cwd'            => 0,
    'File::Basename' => 0,
    'File::Spec'     => 0,
    'FindBin'        => 0,
    'Test::More'     => 0.96,
);
my @XS_FILES = ($xsfile);

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
            homepage   => 'https://metacpan.org/release/Lib-Log4cplus',
            repository => {
                url  => 'https://github.com/rehsack/Lib-Log4cplus.git',
                web  => 'https://github.com/rehsack/Lib-Log4cplus',
                type => 'git',
            },
            bugtracker => {
                web    => 'https://rt.cpan.org/Dist/Display.html?Name=Lib-Log4cplus',
                mailto => 'bug-Lib-Log4cplus@rt.cpan.org',
            },
            license => 'perl_5',
        },
        prereqs => {
            develop => {
                requires => {
                    "Devel::PPPort"                       => 0,
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
    NAME               => 'Lib::Log4cplus',
    ABSTRACT_FROM      => 'lib/Lib/Log4cplus.pm',
    VERSION_FROM       => 'lib/Lib/Log4cplus.pm',
    AUTHOR             => ['Jens Rehsack <rehsack@cpan.org>'],
    LICENSE            => 'apache_2_0',
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    PREREQ_PM          => \%RUN_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    XS                 => {map { (my $tgt = $_) =~ s/\.xs$/\.c/; $_ => $tgt; } @XS_FILES},
    MAGICXS            => 1,
    INC                => join(" ", @{Config::AutoConf::Log4cplus->_get_instance()->{extra_preprocess_flags}}),
    LIBS               => join(" ",
        @{Config::AutoConf::Log4cplus->_get_instance()->{extra_link_flags}},
        map { "-l$_" } @{Config::AutoConf::Log4cplus->_get_instance()->{extra_libs}}),
    (-f "META.yml" ? () : (realclean => {FILES => "inc/latest* inc/inc_* M*.bak ppport.h"})),
    clean  => {FILES               => "Lib-Log4cplus-* *.o LLCconfig.h const-*.inc config.log"},
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

sub _write_constants
{
    my @names = (
        qw(FATAL_LOG_LEVEL ERROR_LOG_LEVEL WARN_LOG_LEVEL INFO_LOG_LEVEL),
        qw(DEBUG_LOG_LEVEL TRACE_LOG_LEVEL),
        qw(OFF_LOG_LEVEL ALL_LOG_LEVEL NOT_SET_LOG_LEVEL),
    );
    my %alias = (
        EMERGENCY_LOG_LEVEL => "FATAL_LOG_LEVEL",
        EMERG_LOG_LEVEL     => "FATAL_LOG_LEVEL",
        PANIC_LOG_LEVEL     => "FATAL_LOG_LEVEL",
        CRITICAL_LOG_LEVEL  => "(L4CP_ERROR_LOG_LEVEL+L4CP_FATAL_LOG_LEVEL)/2",
        WARNING_LOG_LEVEL   => "WARN_LOG_LEVEL",
        NOTICE_LOG_LEVEL    => "(L4CP_INFO_LOG_LEVEL+L4CP_WARN_LOG_LEVEL)/2",
        BASIC_LOG_LEVEL     => "INFO_LOG_LEVEL+1",
    );

    my $c_const  = File::Spec->catfile(dirname($xsfile), 'const-c.inc');
    my $xs_const = File::Spec->catfile(dirname($xsfile), 'const-xs.inc');

    # Write constants as wanted for Lib::Log4cplus
    open(my $c_fh, ">", $c_const) or die("Cannot open $c_const for writing: $!");
    foreach my $name (@names)
    {
        print $c_fh "#define $name (L4CP_$name)\n";
    }
    foreach my $name (sort { $alias{$a} cmp $alias{$b} or $a cmp $b } keys %alias)
    {
        my $aliased = "(" eq substr($alias{$name}, 0, 1) ? $alias{$name} : "L4CP_$alias{$name}";
        print $c_fh "#define $name ($aliased)\n";
    }
    ExtUtils::Constant::WriteConstants(
        NAME         => 'Lib::Log4cplus',
        NAMES        => [@names, keys %alias],
        DEFAULT_TYPE => 'IV',
        C_FH         => $c_fh,
        XS_FILE      => $xs_const,
    );
    close($c_fh);

    return;
}

1;
