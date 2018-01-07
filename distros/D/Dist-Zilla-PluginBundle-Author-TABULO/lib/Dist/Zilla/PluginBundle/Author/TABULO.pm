use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::TABULO; # git description: v0.182-2-g48c9236
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A plugin bundle for distributions built by TABULO
# BASED_ON: Dist::Zilla::PluginBundle::Author::ETHER
# KEYWORDS: author bundle distribution tool

our $VERSION = '0.197';

use Moose;
with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

use Dist::Zilla::Util;
use Moose::Util::TypeConstraints qw(enum subtype where class_type);
use List::Util 1.45 qw(first any uniq none);
use Module::Runtime qw(require_module use_module);
use Devel::CheckBin 'can_run';
use Path::Tiny;
use CPAN::Meta::Requirements;
use Term::ANSIColor 'colored';
eval { +require Win32::Console::ANSI } if $^O eq 'MSWin32';
use Config;
use namespace::autoclean;

sub mvp_multivalue_args { qw(installer copy_file_from_release) }

# Note: no support yet for depending on a specific version of the plugin --
# but [PromptIfStale] generally makes that unnecessary
has installer => (
    isa => 'ArrayRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;

        return [ 'MakeMaker::Fallback', 'ModuleBuildTiny::Fallback' ]
            if not exists $self->payload->{installer};

        # remove 'none' from installer list
        return [ grep { $_ ne 'none' } @{ $self->payload->{installer} } ];
    },
    traits => ['Array'],
    handles => { installer => 'elements' },
);

has server => (
    is => 'ro', isa => enum([qw(github gitmo p5sagit catagits none)]),
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{server} // 'github' },
);

has surgical_podweaver => (
    is => 'ro', isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{surgical_podweaver} // 0 },
);

has airplane => (
    is => 'ro', isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $ENV{DZIL_AIRPLANE} || $_[0]->payload->{airplane} // 0 },
);

has copy_file_from_release => (
    isa => 'ArrayRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{copy_file_from_release} // [] },
    traits => ['Array'],
    handles => { copy_files_from_release => 'elements' },
);

around copy_files_from_release => sub {
    my $orig = shift; my $self = shift;
    sort(uniq($self->$orig(@_), qw(LICENCE LICENSE CONTRIBUTING ppport.h INSTALL)));
};

sub commit_files_after_release
{
    grep { -e } sort(uniq('README.md', 'README.pod', 'Changes', shift->copy_files_from_release));
}

has changes_version_columns => (
    is => 'ro', isa => subtype('Int', where { $_ > 0 && $_ < 20 }),
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{changes_version_columns} // 10 },
);

has licence => (
    is => 'ro', isa => 'Str',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $authority = $self->authority;
        $self->payload->{licence}
            // $self->payload->{license}
            # licenSe is US-only; known non-American authors will be treated appropriately.
            // ((any { $authority eq "cpan:$_" } qw(ETHER ABERGMAN AVAR BINGOS BOBTFISH CHANSEN CHOLET FLORA GETTY ILMARI JAWNSY JQUELIN LEONT LLAP MSTROUT NUFFIN PERIGRIN PHAYLON))
                ? 'LICENCE' : 'LICENSE');
    },
);

has authority => (
    is => 'ro', isa => 'Str',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;

        # we could warn about this, but then we'd have to change configs (and bump prereqs) for an awful lot of
        # distributions.
        return $self->payload->{'Authority.authority'}
            if exists $self->payload->{'Authority.authority'};

        $self->payload->{authority} // 'cpan:TABULO';
    },
);

has fake_release => (
    is => 'ro', isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $ENV{FAKE_RELEASE} || $_[0]->payload->{fake_release} // 0 },
);

# configs are applied when plugins match ->isa($key) or ->does($key)
my %extra_args = (
    'Dist::Zilla::Plugin::MakeMaker' => { 'eumm_version' => '0' },
    'Dist::Zilla::Plugin::ModuleBuildTiny' => { ':version' => '0.012', version_method => 'conservative', static => 'auto' },
    'Dist::Zilla::Plugin::MakeMaker::Fallback' => { ':version' => '0.012' },
    # default_jobs is no-op until Dist::Zilla 5.014
    'Dist::Zilla::Role::TestRunner' => { default_jobs => 9 },
    'Dist::Zilla::Plugin::ModuleBuild' => { mb_version => '0.28' },
    'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback' => { ':version' => '0.018', version_method => 'conservative', static => 'auto' },
);

# plugins that use the network when they run
sub _network_plugins
{
    qw(
        PromptIfStale
        Test::Pod::LinkCheck
        Test::Pod::No404s
        Git::Remote::Check
        CheckPrereqsIndexed
        CheckIssues
        UploadToCPAN
        Git::Push
    );
}

has _has_bash => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    default => sub { !!can_run('bash') },
);

# note this is applied to the plugin list in Dist::Zilla::Role::PluginBundle::PluginRemover,
# but we also need to use it here to be sure we are not adding configs that are only needed
# by plugins that will be subsequently removed.
has _removed_plugins => (
    isa => 'HashRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $remove = $self->payload->{ $self->plugin_remover_attribute } // [];
        my %removed; @removed{@$remove} = (!!1) x @$remove;
        \%removed;
    },
    traits => ['Hash'],
    handles => { _plugin_removed => 'exists', _removed_plugins => 'keys' },
);

# this attribute and its supporting code is a candidate to be extracted out into its own role,
# for re-use in other bundles
has _develop_suggests => (
    isa => class_type('CPAN::Meta::Requirements'),
    lazy => 1,
    default => sub { CPAN::Meta::Requirements->new },
    handles => {
        _add_minimum_develop_suggests => 'add_minimum',
        _develop_suggests_as_string_hash => 'as_string_hash',
    },
);

# files that might be in the repository that should never be gathered
my @never_gather = grep { -e } qw(
    Makefile.PL ppport.h README.md README.pod META.json
    cpanfile TODO CONTRIBUTING LICENCE LICENSE INSTALL
    inc/ExtUtils/MakeMaker/Dist/Zilla/Develop.pm
);

sub BUILD
{
    my $self = shift;

    if ($self->airplane)
    {
        warn '[@Author::TABULO] ' . colored('building in airplane mode - plugins requiring the network are skipped, and releases are not permitted', 'yellow') . "\n";

        # doing this before running configure means we can be sure we update the removal list before
        # our _removed_plugins attribute is built.
        push @{ $self->payload->{ $self->plugin_remover_attribute } }, $self->_network_plugins;
    }
}

sub configure
{
    my $self = shift;

    warn '[@Author::TABULO] no "bash" executable found; skipping Run::AfterBuild command to update .ackrc', "\n"
        if not $INC{'Test/More.pm'} and not $self->_has_bash;

    # NOTE! since the working directory has not changed to $zilla->root yet,
    # if running this code via a different mechanism than dzil <command>, file
    # operations may be looking at the wrong directory! Take this into
    # consideration when running tests!

    my $has_xs = glob('*.xs') ? 1 : 0;
    warn '[@Author::TABULO] XS-based distribution detected.', "\n" if $has_xs;
    die '[@Author::TABULO] no Makefile.PL found in the repository root: this is not very nice for contributors!', "\n"
        if $has_xs and not -e 'Makefile.PL';

    # check for a bin/ that should probably be renamed to script/
    warn '[@Author::TABULO] ', colored('bin/ detected - should this be moved to script/, so its contents can be installed into $PATH?', 'bright_red'), "\n"
        if -d 'bin' and any { $_ eq 'ModuleBuildTiny' } $self->installer;

    warn '[@Author::TABULO] ', colored('You are using [ModuleBuild] as an installer, WTF?!', 'bright_red'), "\n"
        if any { $_->isa('Dist::Zilla::Plugin::ModuleBuild') }
            map { Dist::Zilla::Util->expand_config_package_name($_) } $self->installer;

    # this is better than injecting a perl prereq for 5.008, to allow MBT to
    # become more 5.006-compatible in the future without forcing the distribution to be re-released.
    die 'Module::Build::Tiny should not be used in distributions that are targeting perl 5.006!'
        if any { /ModuleBuildTiny/ } $self->installer
            and (not exists $self->payload->{'Test::MinimumVersion.max_target_perl'}
                 or $self->payload->{'Test::MinimumVersion.max_target_perl'} < '5.008');

    warn '[@Author::TABULO] ', colored('.git is missing and META.json is present -- this looks like a CPAN download rather than a git repository. You should probably run '
            . (-f 'Build.PL' ? 'perl Build.PL; ./Build' : 'perl Makefile.PL; make') . ' instead of using dzil commands!', 'yellow'), "\n"
        if not -d '.git' and -f 'META.json' and not $self->_plugin_removed('Git::GatherDir');

    # only set x_static_install using auto mode for ETHER's distributions
    # (for all other distributions, set explicitly to on or off)
    # Note that this is just the default; if a dist.ini changed these values, ConfigSlicer will apply it later
    my $static_install_mode = $self->payload->{'StaticInstall.mode'} // 'auto';
    my $static_install_dry_run = ($static_install_mode eq 'auto'
            and $self->authority ne 'cpan:ETHER') ? 1 : 0;

    warn '[@Author::TABULO] ', colored('server = ' . $self->server
            . ': recommend instead using server = github and GithubMeta.remote = '
            . $self->server . ' with a read-only mirror', 'yellow'), "\n"
        if $self->server ne 'github' and $self->server ne 'none';

    # method modifier will also apply default configs, compile develop prereqs
    $self->add_plugins(
        # VersionProvider
        # see [@Git::VersionManager]

        # BeforeBuild
        # [ 'EnsurePrereqsInstalled' ], # FIXME: use options to make this less annoying!
        [ 'PromptIfStale' => 'stale modules, build' => { phase => 'build', module => [ $self->meta->name ] } ],
        [ 'PromptIfStale' => 'stale modules, release' => { phase => 'release', check_all_plugins => 1, check_all_prereqs => 1 } ],

        # ExecFiles
        (-d ($self->payload->{'ExecDir.dir'} // 'script') || any { /^ExecDir\./ } keys %{ $self->payload })
            ? [ 'ExecDir'       => { dir => 'script' } ] : (),

        # Finders
        [ 'FileFinder::ByName'  => Examples => { dir => 'examples' } ],

        # Gather Files
        [ 'Git::GatherDir'      => { ':version' => '2.016', @never_gather ? ( exclude_filename => \@never_gather) : () } ],

        qw(MetaYAML MetaJSON Readme Manifest),
        [ 'License'             => { ':version' => '5.038', filename => $self->licence } ],
        [ 'GenerateFile::FromShareDir' => 'generate CONTRIBUTING' => { -dist => 'Dist-Zilla-PluginBundle-Author-TABULO', -filename => 'CONTRIBUTING', has_xs => $has_xs } ],
        [ 'InstallGuide'        => { ':version' => '1.200005' } ],

        [ 'Test::Compile'       => { ':version' => '2.039', bail_out_on_fail => 1, xt_mode => 1,
            script_finder => [qw(:PerlExecFiles @Author::TABULO/Examples)] } ],
        [ 'Test::NoTabs'        => { ':version' => '0.08', finder => [qw(:InstallModules :ExecFiles @Author::TABULO/Examples :TestFiles :ExtraTestFiles)] } ],
        [ 'Test::EOL'           => { ':version' => '0.17', finder => [qw(:InstallModules :ExecFiles @Author::TABULO/Examples :TestFiles :ExtraTestFiles)] } ],
        'MetaTests',
        [ 'Test::CPAN::Changes' => { ':version' => '0.012' } ],
        'Test::ChangesHasContent',
        [ 'Test::MinimumVersion' => { ':version' => '2.000003', max_target_perl => '5.006' } ],
        [ 'PodSyntaxTests'      => { ':version' => '5.040' } ],
        [ 'PodCoverageTests'    => { ':version' => '5.040' } ],
        [ 'Test::PodSpelling'   => { ':version' => '2.006003', stopwords => ['irc'], directories => [qw(examples lib script t xt)] } ],
        #[Test::Pod::LinkCheck]     many outstanding bugs
        ($ENV{CONTINUOUS_INTEGRATION} ? () : [ 'Test::Pod::No404s' => { ':version' => '1.003' } ] ),
        [ 'Test::Kwalitee'      => { ':version' => '2.10', filename => 'xt/author/kwalitee.t' } ],
        [ 'MojibakeTests'       => { ':version' => '0.8' } ],
        [ 'Test::ReportPrereqs' => { ':version' => '0.022', verify_prereqs => 1,
            version_extractor => ( ( any { $_ ne 'MakeMaker' } $self->installer ) ? 'Module::Metadata' : 'ExtUtils::MakeMaker' ),
            include => [ sort ( qw(autodie JSON::PP Sub::Name YAML), $self->_plugin_removed('PodCoverageTests') ? () : 'Pod::Coverage' ) ] } ],
        [ 'Test::Portability'   => { ':version' => '2.000007' } ],
        [ 'Test::CleanNamespaces' => { ':version' => '0.006' } ],


        # Munge Files
        [ 'Git::Describe'       => { ':version' => '0.004', on_package_line => 1 } ],
        [
            ($self->surgical_podweaver ? 'SurgicalPodWeaver' : 'PodWeaver') => {
                $self->surgical_podweaver ? () : ( ':version' => '4.005' ),
                -f 'weaver.ini' ? () : ( config_plugin => '@Author::TABULO' ),
                replacer => 'replace_with_comment',
                post_code_replacer => 'replace_with_nothing',
            }
        ],

        # Metadata
        $self->server eq 'github' ? [ 'GithubMeta' => { ':version' => '0.54', homepage => 0, issues => 0 } ] : (),
        [ 'AutoMetaResources'   => { 'bugtracker.rt' => 1,
              $self->server eq 'gitmo' ? ( 'repository.gitmo' => 1 )
            : $self->server eq 'p5sagit' ? ( 'repository.p5sagit' => 1 )
            : $self->server eq 'catagits' ? ( 'repository.catagits' => 1 )
            : ()
        } ],
        [ 'Authority'           => { ':version' => '1.009', authority => $self->authority, do_munging => 0 } ],
        [ 'MetaNoIndex'         => { directory => [ qw(t xt), grep { -d } qw(inc local perl5 fatlib examples share corpus demo) ] } ],
        [ 'MetaProvides::Package' => { ':version' => '1.15000002', finder => ':InstallModules', meta_noindex => 1, inherit_version => 0, inherit_missing => 0 } ],
        'MetaConfig',
        [ 'Keywords'            => { ':version' => '0.004' } ],
        ($Config{default_inc_excludes_dot} ? [ 'UseUnsafeInc' => { dot_in_INC => 0 } ] : ()),
        # [Git::Contributors]
        # [StaticInstall]

        # Register Prereqs
        # (MakeMaker or other installer)
        [ 'AutoPrereqs'         => { ':version' => '5.038' } ],
        [ 'Prereqs::AuthorDeps' => { ':version' => '0.006', relation => 'suggests' } ],
        [ 'MinimumPerl'         => { ':version' => '1.006', configure_finder => ':NoFiles' } ],
        [ 'Prereqs' => pluginbundle_version => {
                '-phase' => 'develop', '-relationship' => 'recommends',
                $self->meta->name => $self->VERSION,
            } ],
        ($self->surgical_podweaver ? [ 'Prereqs' => pod_weaving => {
                '-phase' => 'develop', '-relationship' => 'suggests',
                'Dist::Zilla::Plugin::SurgicalPodWeaver' => 0
            } ] : ()),

        # Install Tool (some are also Test Runners)
        $self->installer,   # options are set lower down, via %extra_args

        # we prefer this to run after other Register Prereqs plugins
        [ 'Git::Contributors'   => { ':version' => '0.029', order_by => 'commits' } ],

        # must appear after installers; also note that MBT::*'s static tweak is consequently adjusted, later
        [ 'StaticInstall'       => { ':version' => '0.005', mode => $static_install_mode, dry_run => $static_install_dry_run } ],

        # Test Runners (load after installers to avoid a rebuild)
        [ 'RunExtraTests'       => { ':version' => '0.024' } ],

        # After Build
        'CheckSelfDependency',

        ( $self->_has_bash ?
            [ 'Run::AfterBuild' => '.ackrc' => { ':version' => '0.038', quiet => 1, run => q{bash -c "test -e .ackrc && grep -q -- '--ignore-dir=.latest' .ackrc || echo '--ignore-dir=.latest' >> .ackrc; if [[ `dirname '%d'` != .build ]]; then test -e .ackrc && grep -q -- '--ignore-dir=%d' .ackrc || echo '--ignore-dir=%d' >> .ackrc; fi"} } ]
            : ()),
        [ 'Run::AfterBuild'     => '.latest' => { ':version' => '0.041', quiet => 1, fatal_errors => 0, eval => q!if ('%d' =~ /^%n-[.[:xdigit:]]+$/) { unlink '.latest'; symlink '%d', '.latest'; }! } ],


        # Before Release
        [ 'CheckStrictVersion'  => { decimal_only => 1 } ],
        'CheckMetaResources',
        'EnsureLatestPerl',

        # if in airplane mode, allow our uncommitted dist.ini edit which sets 'airplane = 1'
        [ 'Git::Check'          => 'initial check' => { allow_dirty => [ $self->airplane ? 'dist.ini' : '' ] } ],

        'Git::CheckFor::MergeConflicts',
        [ 'Git::CheckFor::CorrectBranch' => { ':version' => '0.004', release_branch => 'master' } ],
        [ 'Git::Remote::Check'  => { branch => 'master', remote_branch => 'master' } ],
        [ 'CheckPrereqsIndexed' => { ':version' => '0.019' } ],
        'TestRelease',
        [ 'Git::Check'          => 'after tests' => { allow_dirty => [''] } ],
        'CheckIssues',
        # (ConfirmRelease)

        # Releaser
        $self->fake_release
            ? do { warn '[@Author::TABULO] ', colored('FAKE_RELEASE set - not uploading to CPAN', 'yellow'), "\n"; 'FakeRelease' }
            : 'UploadToCPAN',

        # After Release
        ( $self->licence eq 'LICENSE' && -e 'LICENCE' ?
            [ 'Run::AfterRelease' => 'remove old LICENCE' => { ':version' => '0.038', quiet => 1, eval => q!unlink 'LICENCE'! } ]
            : ()),
        ( $self->licence eq 'LICENCE' && -e 'LICENSE' ?
            [ 'Run::AfterRelease' => 'remove old LICENSE' => { ':version' => '0.038', quiet => 1, eval => q!unlink 'LICENSE'! } ]
            : ()),
        ( -e 'README.md' ?
            [ 'Run::AfterRelease' => 'remove old READMEs' => { ':version' => '0.038', quiet => 1, eval => q!unlink 'README.md'! } ]
            : ()),

        [ 'CopyFilesFromRelease' => 'copy generated files' => { filename => [ $self->copy_files_from_release ] } ],
        [ 'ReadmeAnyFromPod'    => { ':version' => '0.142180', type => 'pod', location => 'root', phase => 'release' } ],
    );

    # plugins to do with calculating, munging, incrementing versions
    $self->add_bundle('@Git::VersionManager' => {
        'RewriteVersion::Transitional.global' => 1,
        'RewriteVersion::Transitional.fallback_version_provider' => 'Git::NextVersion',
        'RewriteVersion::Transitional.version_regexp' => '^v([\d._]+)(-TRIAL)?$',

        # for first Git::Commit
        commit_files_after_release => [ $self->commit_files_after_release ],
        # because of [Git::Check], only files copied from the release would be added -- there is nothing else
        # hanging around in the current directory
        'release snapshot.add_files_in' => ['.'],
        'release snapshot.commit_msg' => '%N-%v%t%n%n%c',

        'Git::Tag.tag_message' => 'v%v%t',

        # if the caller set bump_only_matching_versions, then this global setting falls on the floor automatically
        # because the bundle uses the non-Transitional plugin in that case.
        'BumpVersionAfterRelease::Transitional.global' => 1,

        'NextRelease.:version' => '5.033',
        'NextRelease.time_zone' => 'UTC',
        'NextRelease.format' => '%-' . ($self->changes_version_columns - 2) . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T',
    });

    $self->add_plugins(
        'Git::Push',
        $self->server eq 'github' ? [ 'GitHub::Update' => { ':version' => '0.40', metacpan => 1 } ] : (),
    );

    # install with an author-specific URL from PAUSE, so cpanm-reporter knows where to submit the report
    # hopefully the file is available at this location soonish after release!
    my ($username, $password) = $self->_pause_config;
    $self->add_plugins(
        [ 'Run::AfterRelease'   => 'install release' => { ':version' => '0.031', fatal_errors => 0, run => 'cpanm http://' . $username . ':' . $password . '@pause.perl.org/pub/PAUSE/authors/id/' . substr($username, 0, 1).'/'.substr($username,0,2).'/'.$username.'/%a' } ],
    ) if $username and $password;

    # halt release after pre-release checks, but before ConfirmRelease
    $self->add_plugins('BlockRelease') if $self->airplane;

    $self->add_plugins(
        [ 'Run::AfterRelease'   => 'release complete' => { ':version' => '0.038', quiet => 1, eval => [ qq{print "release complete!\\xa"} ] } ],
        # listed late, to allow all other plugins which do BeforeRelease checks to run first.
        'ConfirmRelease',
    );

    # if ModuleBuildTiny(::*) is being used, disable its static option if
    # [StaticInstall] is being run with mode=off or dry_run=1
    if (($static_install_mode eq 'off' or $static_install_dry_run)
        and any { /^ModuleBuildTiny/ } $self->installer)
    {
        my $mbt = Dist::Zilla::Util->expand_config_package_name('ModuleBuildTiny');
        my $mbt_spec = first { $_->[1] =~ /^$mbt/ } @{ $self->plugins };

        $mbt_spec->[-1]{static} = 'no';
    }

    # ensure that additional optional plugins are declared in prereqs
    $self->add_plugins(
        [ 'Prereqs' => 'prereqs for @Author::TABULO' =>
        { '-phase' => 'develop', '-relationship' => 'suggests',
          %{ $self->_develop_suggests_as_string_hash } } ]
    );

    # listed last, to be sure we run at the very end of each phase
    my $usr = $ENV{USER} // '';
    $self->add_plugins(
        [ 'VerifyPhases' => 'PHASE VERIFICATION' => { ':version' => '0.015' } ]
    ) if $usr =~ /^tabulo|ayhan$/i;
}

# determine develop prereqs, and apply default configs (respecting superclasses, roles)
around add_plugins => sub
{
    my ($orig, $self, @plugins) = @_;

    @plugins = grep {
        my $plugin = $_;
        my $plugin_package = Dist::Zilla::Util->expand_config_package_name($plugin->[0]);
        none {
             $plugin_package eq Dist::Zilla::Util->expand_config_package_name($_)   # match by package name
             or ($plugin->[1] and not ref $plugin->[1] and $plugin->[1] eq $_)      # match by moniker
        } $self->_removed_plugins
    } map { ref $_ ? $_ : [ $_ ] } @plugins;

    foreach my $plugin_spec (@plugins)
    {
        # these should never be added to develop prereqs
        next if $plugin_spec->[0] eq 'BlockRelease'     # temporary use during development
            or $plugin_spec->[0] eq 'VerifyPhases';     # only used by TABULO, not others

        my $plugin = Dist::Zilla::Util->expand_config_package_name($plugin_spec->[0]);
        require_module($plugin);

        push @$plugin_spec, {} if not ref $plugin_spec->[-1];
        my $payload = $plugin_spec->[-1];

        foreach my $module (grep { $plugin->isa($_) or $plugin->does($_) } keys %extra_args)
        {
            my %configs = %{ $extra_args{$module} };    # copy, not reference!

            # don't keep :version unless it matches the package exactly, but still respect the prereq
            $self->_add_minimum_develop_suggests($module => delete $configs{':version'})
                if exists $configs{':version'} and $module ne $plugin;

            # we don't need to worry about overwriting the payload with defaults, as
            # ConfigSlicer will copy them back over later on.
            @{$payload}{keys %configs} = values %configs;
        }

        # record develop prereq
        $self->_add_minimum_develop_suggests($plugin => $payload->{':version'} // 0);
    }

    return $self->$orig(@plugins);
};

around add_bundle => sub
{
    my ($orig, $self, $bundle, $payload) = @_;

    return if $self->_plugin_removed($bundle);

    my $package = Dist::Zilla::Util->expand_config_package_name($bundle);
    &use_module(
        $package,
        $payload && $payload->{':version'} ? $payload->{':version'} : (),
    );

    # default configs can be passed in directly - no need to consult %extra_args

    # record develop prereq of bundle only, not its components (it should do that itself)
    $self->_add_minimum_develop_suggests($package => $payload->{':version'} // 0);

    # allow config slices to propagate down from the user
    $payload = {
        %$payload,      # caller bundle's default settings for this bundle, passed to this sub
        # custom configs from the user, which may override defaults
        (map { $_ => $self->payload->{$_} } grep { /^(.+?)\.(.+?)/ } keys %{ $self->payload }),
    };

    # allow the user to say -remove = <plugin added in subbundle>, but also do not override
    # any removals that were passed into this sub directly.
    push @{$payload->{-remove}}, @{ $self->payload->{ $self->plugin_remover_attribute } }
        if $self->payload->{ $self->plugin_remover_attribute };

    return $self->$orig($bundle, $payload);
};

# return username, password from ~/.pause
sub _pause_config
{
    my $self = shift;

    my $file = path($ENV{HOME} // 'oops', '.pause');
    return if not -e $file;

    my ($username, $password) = map {
        my (undef, $val) = split ' ', $_; $val  # awk-style whitespace splitting
    } $file->lines;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::TABULO - A plugin bundle for distributions built by TABULO

=head1 VERSION

version 0.197

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::TABULO]

=head1 DESCRIPTION

=for stopwords TABULO DAGOLDEN ETHER KENTNL
=for stopwords GitHub
=for stopwords optimizations repo

This is the plug-in bundle that TABULO uses for his distributions whose starting
point was ETHER's.

It exists mostly because TABULO is very lazy and wants others to be using what
he's using if they want to be doing work on his modules, just like KENTNL
and many others, I suppose...

But since TABULO is probably even lazier than most folks; instead of starting his
bundle from scratch, he just shopped around to find a bundle that had the most
overlap with his taste or whatever; and then just slurped the whole thing,
even including its documentation which is what you see here and in the
related modules.:-)

Admittedly, the fact that TABULO was so late in migrating to dzil worked to his
advantage for this particular task at least, since by that time
the bold and the brave had already made delicious stuff!

Thank you ETHER!

Thank you, too, KENTNL and DAGOLDEN, as your plugin-bundles also seem to be quite
good sources of inspiration!

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

And now comes the rest of the documentation slurped right in from ETHER's GitHub
repo ... :-)

=head2 DESCRIPTION (at last)

This L<Dist::Zilla> plugin bundle is I<very approximately> equal to the
following F<dist.ini> (following the preamble), minus some optimizations:

    ;;; BeforeBuild
    [PromptIfStale / stale modules, build]
    phase = build
    module = Dist::Zilla::Plugin::Author::TABULO
    [PromptIfStale / stale modules, release]
    phase = release
    check_all_plugins = 1
    check_all_prereqs = 1


    ;;; ExecFiles
    [ExecDir]
    dir = script    ; only if script dir exists


    ;;; Finders
    [FileFinder::ByName / Examples]
    dir = examples


    ;;; Gather Files
    [Git::GatherDir]
    :version = 2.016
    exclude_filename = CONTRIBUTING
    exclude_filename = INSTALL
    exclude_filename = LICENCE
    exclude_filename = LICENSE
    exclude_filename = META.json
    exclude_filename = Makefile.PL
    exclude_filename = README.md
    exclude_filename = README.pod
    exclude_filename = TODO
    exclude_filename = cpanfile
    exclude_filename = inc/ExtUtils/MakeMaker/Dist/Zilla/Develop.pm
    exclude_filename = ppport.h

    [MetaYAML]
    [MetaJSON]
    [Readme]
    [Manifest]
    [License]
    :version = 5.038
    filename = LICENCE  ; for distributions where I have authority

    [GenerateFile::FromShareDir / generate CONTRIBUTING]
    -dist = Dist-Zilla-PluginBundle-Author-TABULO
    -filename = CONTRIBUTING
    has_xs = <dynamically-determined flag>
    [InstallGuide]
    :version = 1.200005

    [Test::Compile]
    :version = 2.039
    bail_out_on_fail = 1
    xt_mode = 1
    script_finder = :PerlExecFiles
    script_finder = Examples

    [Test::NoTabs]
    :version = 0.08
    finder = :InstallModules
    finder = :ExecFiles
    finder = Examples
    finder = :TestFiles
    finder = :ExtraTestFiles

    [Test::EOL]
    :version = 0.17
    finder = :InstallModules
    finder = :ExecFiles
    finder = Examples
    finder = :TestFiles
    finder = :ExtraTestFiles

    [MetaTests]
    [Test::CPAN::Changes]
    :version = 0.012
    [Test::ChangesHasContent]
    [Test::MinimumVersion]
    :version = 2.000003
    max_target_perl = 5.006
    [PodSyntaxTests]
    :version = 5.040
    [PodCoverageTests]
    :version = 5.040
    [Test::PodSpelling]
    :version = 2.006003
    stopwords = irc
    directory = examples
    directory = lib
    directory = script
    directory = t
    directory = xt

    ;[Test::Pod::LinkCheck]     many outstanding bugs
    [Test::Pod::No404s]
    :version = 1.003
    [Test::Kwalitee]
    :version = 2.10
    filename = xt/author/kwalitee.t
    [MojibakeTests]
    :version = 0.8
    [Test::ReportPrereqs]
    :version = 0.022
    verify_prereqs = 1
    version_extractor = Module::Metadata
    include = JSON::PP
    include = Pod::Coverage
    include = Sub::Name
    include = YAML
    include = autodie
    [Test::Portability]
    :version = 2.000007
    [Test::CleanNamespaces]
    :version = 0.006


    ;;; Munge Files
    [Git::Describe]
    :version = 0.004
    on_package_line = 1

    [PodWeaver] (or [SurgicalPodWeaver])
    :version = 4.005
    config_plugin = @Author::TABULO ; unless weaver.ini is present
    replacer = replace_with_comment
    post_code_replacer = replace_with_nothing


    ;;; Metadata
    [GithubMeta]    ; (if server = 'github' or omitted)
    :version = 0.54
    homepage = 0
    issues = 0

    [AutoMetaResources]
    bugtracker.rt = 1
    ; (plus repository.* = 1 if server = 'gitmo' or 'p5sagit')

    [Authority]
    :version = 1.009
    authority = cpan:TABULO
    do_munging = 0

    [MetaNoIndex]
    directory = corpus
    directory = demo
    directory = examples
    directory = fatlib
    directory = inc
    directory = local
    directory = perl5
    directory = share
    directory = t
    directory = xt

    [MetaProvides::Package]
    :version = 1.15000002
    finder = :InstallModules
    meta_noindex = 1
    inherit_version = 0
    inherit_missing = 0

    [MetaConfig]
    [Keywords]
    :version = 0.004

    ; if we are releasing with a new perl with -DDEFAULT_INC_EXCLUDES_DOT set
    [UseUnsafeInc]
    dot_in_INC = 0

    ;[Git::Contributors]    ; below
    ;[StaticInstall]        ; below


    ;;; Register Prereqs
    [AutoPrereqs]
    :version = 5.038
    [Prereqs::AuthorDeps]
    relation = suggests
    [MinimumPerl]
    :version = 1.006
    configure_finder = :NoFiles

    [Prereqs / prereqs for @Author::TABULO]
    -phase = develop
    -relationship = suggests
    ...all the plugins this bundle uses...

    [Prereqs / pluginbundle_version]
    -phase = develop
    -relationship = recommends
    Dist::Zilla::PluginBundle::Author::TABULO = <current installed version>


    ;;; Install Tool
    ; <specified installer(s)>

    [Git::Contributors]
    :version = 0.029
    order_by = commits

    [StaticInstall]
    :version = 0.005
    mode = auto
    dry_run = 1  ; only if authority is not ETHER


    ;;; Test Runner
    ; <specified installer(s)>
    [RunExtraTests]
    :version = 0.024
    default_jobs = 9


    ;;; After Build
    [CheckSelfDependency]

    [Run::AfterBuild / .ackrc]
    :version = 0.038
    quiet = 1
    run = bash -c "test -e .ackrc && grep -q -- '--ignore-dir=.latest' .ackrc || echo '--ignore-dir=.latest' >> .ackrc; if [[ `dirname '%d'` != .build ]]; then test -e .ackrc && grep -q -- '--ignore-dir=%d' .ackrc || echo '--ignore-dir=%d' >> .ackrc; fi"
    [Run::AfterBuild / .latest]
    :version = 0.041
    quiet = 1
    fatal_errors = 0
    eval = if ('%d' =~ /^%n-[.[:xdigit:]]+$/) { unlink '.latest'; symlink '%d', '.latest'; }


    ;;; Before Release
    [CheckStrictVersion]
    decimal_only = 1

    [CheckMetaResources]
    [EnsureLatestPerl]

    [Git::Check / initial check]
    allow_dirty =

    [Git::CheckFor::MergeConflicts]

    [Git::CheckFor::CorrectBranch]
    :version = 0.004
    release_branch = master

    [Git::Remote::Check]
    branch = master
    remote_branch = master

    [CheckPrereqsIndexed]
    :version = 0.019
    [TestRelease]
    [Git::Check / after tests]
    allow_dirty =
    [CheckIssues]
    ;(ConfirmRelease)


    ;;; Releaser
    [UploadToCPAN]


    ;;; AfterRelease
    [Run::AfterRelease / remove old LICENCE]    ; if switching from LICENCE -> LICENSE
    :version = 0.038
    quiet = 1
    eval = unlink 'LICENCE'

    [Run::AfterRelease / remove old LICENSE]    ; if switching from LICENSE -> LICENCE
    :version = 0.038
    quiet = 1
    eval = unlink 'LICENSE'

    [Run::AfterRelease / remove old READMEs]
    :version = 0.038
    quiet = 1
    eval = unlink 'README.md'

    [CopyFilesFromRelease / copy generated files]
    filename = CONTRIBUTING
    filename = INSTALL
    filename = LICENCE
    filename = LICENSE
    filename = ppport.h

    [ReadmeAnyFromPod]
    :version = 0.142180
    type = pod
    location = root
    phase = release

    ;;;;;; begin [@Git::VersionManager]

    ; this is actually a VersionProvider and FileMunger
    [RewriteVersion::Transitional]
    :version = 0.004
    global = 1
    fallback_version_provider = Git::NextVersion
    version_regexp = ^v([\d._]+)(-TRIAL)?$

    [CopyFilesFromRelease / copy Changes]
    filename = Changes

    [Git::Commit / release snapshot]
    :version = 2.020
    add_files_in = .
    allow_dirty = CONTRIBUTING
    allow_dirty = Changes
    allow_dirty = INSTALL
    allow_dirty = LICENCE
    allow_dirty = LICENSE
    allow_dirty = README.md
    allow_dirty = README.pod
    allow_dirty = ppport.h
    commit_msg = %N-%v%t%n%n%c

    [Git::Tag]
    tag_message = v%v%t

    [BumpVersionAfterRelease::Transitional]
    :version = 0.004
    global = 1

    [NextRelease]
    :version = 5.033
    time_zone = UTC
    format = %-8v  %{yyyy-MM-dd HH:mm:ss'Z'}d%{ (TRIAL RELEASE)}T

    [Git::Commit / post-release commit]
    :version = 2.020
    allow_dirty = Changes
    allow_dirty_match = ^lib/.*\.pm$
    commit_msg = increment $VERSION after %v release

    ;;;;;; end [@Git::VersionManager]

    [Git::Push]

    [GitHub::Update]    ; (if server = 'github' or omitted)
    :version = 0.40
    metacpan = 1

    [Run::AfterRelease / install release]
    :version = 0.031
    fatal_errors = 0
    run = cpanm http://URMOM:mysekritpassword@pause.perl.org/pub/PAUSE/authors/id/U/UR/URMOM/%a

    [Run::AfterRelease / release complete]
    :version = 0.038
    quiet = 1
    eval = print "release complete!\xa"

    ; listed late, to allow all other plugins which do BeforeRelease checks to run first.
    [ConfirmRelease]

    ; listed last, to be sure we run at the very end of each phase
    ; only performed if $ENV{USER} matches /^tabulo$/
    [VerifyPhases / PHASE VERIFICATION]
    :version = 0.015

=for Pod::Coverage configure mvp_multivalue_args

=for stopwords metacpan

The distribution's code is assumed to be hosted at L<github|http://github.com>;
L<RT|http://rt.cpan.org> is used as the issue tracker.
The home page in the metadata points to L<github|http://github.com>,
while the home page on L<github|http://github.com> is updated on release to
point to L<metacpan|http://metacpan.org>.
The version and other metadata is derived directly from the local git repository.

=head1 OPTIONS / OVERRIDES

=head2 version

Use C<< V=<version> >> in the shell to override the version of the distribution being built;
otherwise the version is incremented after each release, in the F<*.pm> files.

=head2 pod coverage

Subroutines can be considered "covered" for pod coverage tests by adding a
directive to pod (as many as you'd like),
as described in L<Pod::Coverage::TrustPod>:

    =for Pod::Coverage foo bar baz

=head2 spelling stopwords

=for stopwords Stopwords

Stopwords for spelling tests can be added by adding a directive to pod (as
many as you'd like), as described in L<Pod::Spell/ADDING STOPWORDS>:

    =for stopwords foo bar baz

See also L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling/stopwords>.

=head2 installer

=for stopwords ModuleBuildTiny

Available since 0.007.

The installer back-end(s) to use (can be specified more than once); defaults
to L<C<ModuleBuildTiny::Fallback>|Dist::Zilla::Plugin::ModuleBuildTiny::Fallback>
and L<C<MakeMaker::Fallback>|Dist::Zilla::Plugin::MakeMaker::Fallback>
(which generates a F<Build.PL> for normal use with no-configure-requires
protection, and F<Makefile.PL> as a fallback, containing an upgrade warning).
For toolchain-grade modules, you should only use F<Makefile.PL>-generating installers.

You can select other backends (by plugin name, without the C<[]>), with the
C<installer> option, or C<none> if you are supplying your own, as a separate
plugin(s).

Encouraged choices are:

=over 4

=item *

C<< installer = ModuleBuildTiny >>

=item *

C<< installer = MakeMaker >>

=item *

C<< installer = MakeMaker::Fallback >> (when used in combination with ModuleBuildTiny)

=item *

C<< installer = =inc::Foo >> (if no configs are needed for this plugin; e.g. subclassed from L<[MakeMaker::Awesome]|Dist::Zilla::Plugin::MakeMaker::Awesome>)

=item *

C<< installer = none >> (if you are providing your own elsewhere in the file, with configs)

=back

=head2 server

Available since 0.019.

If provided, must be one of:

=over 4

=item *

C<github>

(default)
metadata and release plugins are tailored to L<github|http://github.com>.

=item *

C<gitmo>

metadata and release plugins are tailored to
L<gitmo@git.moose.perl.org|http://git.moose.perl.org>.

=item *

C<p5sagit>

metadata and release plugins are tailored to
L<p5sagit@git.shadowcat.co.uk|http://git.shadowcat.co.uk>.

=item *

C<catagits>

metadata and release plugins are tailored to
L<catagits@git.shadowcat.co.uk|http://git.shadowcat.co.uk>.

=item *

C<none>

no special configuration of metadata (relating to repositories etc) is done --
you'll need to provide this yourself.

=back

=head2 airplane

Available since 0.053.

A boolean option that, when set, removes the use of all plugins that use the
network (generally for comparing metadata against PAUSE, and querying the
remote git server), as well as blocking the use of the C<release> command.
Defaults to false; can also be set with the environment variable C<DZIL_AIRPLANE>.

=head2 copy_file_from_release

Available in this form since 0.076.

A file, to be present in the build, which is copied back to the source
repository at release time and committed to git. Can be used more than
once. Defaults to:
F<LICENCE>, F<LICENSE>, F<CONTRIBUTING>, F<Changes>, F<ppport.h>, F<INSTALL>;
defaults are appended to, rather than overwritten.

=head2 surgical_podweaver

=for stopwords PodWeaver SurgicalPodWeaver

Available since 0.051.

A boolean option that, when set, uses
L<[SurgicalPodWeaver]|Dist::Zilla::Plugin::SurgicalPodWeaver> instead of
L<[PodWeaver]|Dist::Zilla::Plugin::SurgicalPodWeaver>, but with all the same
options. Defaults to false.

=head2 changes_version_columns

Available since 0.076.

An integer that specifies how many columns (right-padded with whitespace) are
allocated in F<Changes> entries to the version string. Defaults to 10.

=head2 licence (or license)

Available since 0.101.

A string that specifies the name to use for the license file.  Defaults to
C<LICENCE> for distributions where ETHER or any other known authors who prefer
C<LICENCE> have first-come permissions, or C<LICENSE> otherwise.
(The pod section for legal information is also adjusted appropriately.)

=head2 authority

Available since 0.117.

A string of the form C<cpan:PAUSEID> that references the PAUSE ID of the user who has primary ("first-come")
authority over the distribution and main module namespace. If not provided, it is extracted from the configuration
passed through to the L<[Authority]|Dist::Zilla::Plugin::Authority> plugin, and finally defaults to C<cpan:TABULO>.
It is presently used for setting C<x_authority> metadata and deciding which spelling is used for the F<LICENCE>
file (if the C<licence> configuration is not provided).

=head2 fake_release

=for stopwords UploadToCPAN FakeRelease

Available since 0.122.

A boolean option that, when set, removes L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN> from the plugin list
and replaces it with L<[FakeRelease]|Dist::Zilla::Plugin::FakeRelease>.
Defaults to false; can also be set with the environment variable C<FAKE_RELEASE>.

=for stopwords customizations

=head2 other customizations

This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.
(Note that even though some overridden values are inspected in this class,
they are still overlaid on top of whatever this bundle eventually decides to
pass - so what is in the F<dist.ini> always trumps everything else.)

Plugins are not loaded until they are actually needed, so it is possible to
C<--force>-install this plugin bundle and C<-remove> some plugins that do not
install or are otherwise problematic.

If a F<weaver.ini> is present in the distribution, pod is woven using it;
otherwise, the behaviour is as with a F<weaver.ini> containing the single line
C<[@Author::TABULO]> (see L<Pod::Weaver::PluginBundle::Author::TABULO>).

=head1 NAMING SCHEME

=for stopwords KENTNL

This distribution follows best practices for author-oriented plugin bundles; for more information,
see L<KENTNL's distribution|Dist::Zilla::PluginBundle::Author::KENTNL/NAMING-SCHEME>.

=head1 ORIGINAL AUTHOR

This distribution is based on L<Dist::Zilla::PluginBundle::Author::ETHER> by :

Karen Etheridge L<cpan:ETHER>

Thank you ETHER!

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver::PluginBundle::Author::TABULO>

=item *

L<Dist::Zilla::MintingProfile::Author::TABULO>

=item *

L<Dist::Zilla::PluginBundle::Git::VersionManager>

=item *

L<Dist::Zilla::PluginBundle::Author::ETHER> (original bundle by ETHER)

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Ayhan Ulusoy <tabulo@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Dave Rolsky Edward Betts Graham Knop Randy Stauner Roy Ivy III Сергей Романов

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Edward Betts <edward@4angle.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Roy Ivy III <rivy@cpan.org>

=item *

Сергей Романов <sromanov@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ayhan Ulusoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
