package Dist::Zilla::PluginBundle::Author::TABULO;
### ex: set ft=perl noai ts=4 sw=4:

our $VERSION = '1.000011';

use 5.026; # Indented HEREDOC.
use Data::Printer qw(p np);
use Data::Printer qw(p np);
use List::Util qw(uniq);
use Module::Runtime qw(require_module use_module);
use Path::Tiny qw(path);
use PerlX::Maybe qw(maybe);

# our own modules
use Pod::Weaver::PluginBundle::Author::TABULO;
use Pod::Wordlist::Author::TABULO;
use Zest::Author::TABULO::MungersForHas qw(hm_tabulo);
use Zest::Author::TABULO::Util::List qw(flat uniq_sort_flat);
use Zest::Author::TABULO::Util::Mayhap qw(mayhap);
use Zest::Author::TABULO::Util::Dzil qw(grok_plugins);

use Moose;
with
  'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer',
  'Dist::Zilla::Role::PluginBundle::PluginRemover';
use namespace::clean;

#region #=== CONSTANTS ===

my %allowed_installers = (
    MakeMaker                   => 1,
    'MakeMaker::Awesome'        => 1,
    ModuleBuild                 => 1,
    ModuleBuildTiny             => 1,
    'ModuleBuildTiny::Fallback' => 1,
    );
my @allowed_installers = grep { $allowed_installers{$_} } sort keys %allowed_installers;
my @allowed_copy_modes = qw/Regenerate Release Build Build::Filtered None/;

my @allow_dirty = qw(dist.ini Changes);
my %boilerplate = (
    distmeta   => [qw(cpanfile Meta.yml META.json)],
    installer  => [qw(Build.PL Makefile.PL ppport.h)],
    readme     => [qw(README README.md README.mkdn README.pod)],
    readme_too => [qw(CODE_OF_CONDUCT CONTRIBUTING LICENCE LICENSE INSTALL)],
    );
my @boilerplate = uniq( sort map { @$_ } ( values %boilerplate ) );

my @never_gather = (
    @boilerplate, qw(
        TODO
        inc/ExtUtils/MakeMaker/Dist/Zilla/Develop.pm
      )
      );

my @prune_not = map { qr/"$_"/ } qw (
    \.travis\.yml
    \.perltidyrc
    .*/\.gitignore$
    .*/\.(git)?keep$
    );

#endregion CONSTANTS

#region: #=== ATTRIBUTES ===

##== DRY mungers for MooseX::MungeHas (see below)
use MooseX::MungeHas 'is_ro', \&hm_tabulo;

sub mvp_aliases {
    return +{
        auto_prereq        => 'auto_prereqs',
        exclude_filename   => 'exclude_filenames',
        regenerate         => 'copy',
        copy_from          => 'copy_mode',
        git_remote         => 'git_remotes',
        stopword           => 'stopwords',
        stopwords_file     => 'stopwords_files',
        stopwords_provider => 'stopwords_providers',
        wordlist           => 'stopwords_providers',
        wordlists          => 'stopwords_providers',
        };
}

##== Most of the below options were adapted from various sources,
##   such as: @DAGOLDEN, @DROLSKY, @ETHER, @KENTNL (MHRIP), @Starter, @Starter::Git

has archive_dir => (
    isa     => 'Str',
    default => 'releases',
    -doc    => <<~"__EOT__"
        Passed as the 'directory' option, to [ArchiveRelease] whose docs are quoted below:

        * The 'directory' [name] may begin with ~ (or ~user) to mean your (or some other user's) home directory.
        * If the directory doesn't exist, it will be created during the BeforeRelease phase.
        * All files inside this directory will be pruned from the distribution.
__EOT__
    );

has authority => (
    isa     => 'Str',
    default => 'cpan:TABULO',
    -doc    => "Specifies the x_authority field for PAUSE.",
    );

has auto_prereqs => (
    isa     => 'Bool',
    default => 1,
    -doc    => "Indicates whether or not to use [AutoPrereqs].",
    );

has auto_version => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Indicates whether or not to use [AutoVersion] instead of our standard plugins for version management.",
    );

has copy => (
    isa     => 'ArrayRef',
    default => sub { [] },
    -doc    =>
      "Additional files to copy (or regenerate) in addition to those that are already harvested by default. [May be repeated]. Note that the copying may be done from the build or the release, depending on the 'copy_mode' setting. See 'copy_mode'.",
      );

has copy_mode => (
    isa     => 'Maybe[Str]',
    default => 'Release',
    -doc    => "Determines the 'copy-mode' and hence ultimately the set of plugins used for that purpose. Possible values are  ["
      . join( ', ', @allowed_copy_modes )
      . "]. dzil 'regenerate' command will still work. ",
      );

has copy_not => (
    isa     => 'ArrayRef',
    default => sub { [] },
    -doc    => "Do NOT copy given file(s). [May be repeated].",
    );

has darkpan => (
    isa     => 'Bool',
    default => 0,
    -doc    => "For private code; uses [FakeRelease] and fills in dummy repo/bugtracker data.",
    );

has dist_genre => (
    isa     => 'Str',
    default => 'standard',
    -doc    => <<~"__EOT__"
        Specifies the 'genre' of the distro. Currently allowed values are: 'standard' (the default) and 'task'.

        This may be used in the future to associate a set behaviours/settings to given genres.

        Currently, the only distinction made is for the 'task' genre, which will result in [TaskWeaver] being used
        instead of [SurgicalPodWeaver].
__EOT__
    );

has exclude_filenames => (
    isa     => 'ArrayRef',
    default => sub { [] },
    -doc    => "Do NOT gather given file(s). [May be repeated].",
    );

has exclude_match => (
    isa     => 'ArrayRef',
    default => sub { [] },
    -doc    => "Do NOT gather file(s) that match the given pattern(s). [May be repeated].",
    );

has exec_dir => (
    isa     => 'Maybe[Str]',
    default => sub { $_[0]->installer =~ /Module::Build::Tiny/ ? 'script' : undef },
    -doc    =>
      "If defined, passed to [ExecDir] as its 'dir' option.  Defaults to 'script' when the installer is [Module::Build::Tiny],undef otherwise, which means the [ExecDir] default will be in effect, and that is 'bin' as of this writing.",
      );

has fake_release => (
    isa     => 'Bool',
    default => 0,
    -doc    =>
      "Swaps [FakeRelease] for [UploadToCPAN]. Mostly useful for testing a dist.ini without risking a real release. Note that this can also be achieved by setting the FAKE_RELEASE environment variable (which will have precedence over this option).",
      );

has has_xs => (
    isa     => 'Bool',
    default => sub { glob('*.xs') ? 1 : 0 }, # @ETHER
    );

has hub => (
    isa     => 'Maybe[Str]',
    default => 'github',
    -doc    =>
      "The repository 'hub' provider. Currently, other than unsetting to undef, the only supported value, which is also the default, is 'github'. Other providers, such as 'gitlab' or 'bitbucket', may be supported in the future.",
      );

has git_remotes => (
    isa     => 'ArrayRef',
    default => sub { ['origin'] },
    -doc    => "Where to push after release.",
    );

has github_issues => (
    isa     => 'Str',
    default => 1,
    -doc    => "Whether or not to use github issue tracker.",
    );

has installer => (
    default => 'MakeMaker',
    -doc    => "The installer to employ. Currently, possible values are: [" . join( ', ', @allowed_installers ) . "].",
    );

has is_task => ( #DEPRECATED
    isa     => 'Bool',
    default => sub { ( $_[0]->dist_genre // '' ) =~ m/^task/i },
    -doc    => <<~"__EOT__"
        DEPRECATED. Prefer setting instead, like so:

        [\@Author::TABULO]
        dist_genre=task

        Identifies this distro as a 'task'.

        Currently, the only distinction is that, for a task, we use [TaskWeaver] instead of [SurgicalPodWeaver].
__EOT__
    );

has manage_versions => (
    isa     => 'Bool',                                                                                                               # adopted from @Starter (also dropping the 'd' in the name)
    default => 1,
    -doc    => "Whether or not to manage versioning, which means: providing, rewriting, bumping, munging \$VERSION in sources, ....",
    );

has no_archive => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit the [ArchiveRelease] plugin.",
    );

has no_copy => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Skip copying files from the build/release : ('Makefile.PL', 'cpanfile',' Meta.json', ...).",
    );

has no_coverage => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit PodCoverage tests -- which are actually done using [Test::Pod::Coverage::Configurable].",
    );

has no_critic => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit [Test::Perl::Critic] tests.",

    );

has no_git => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Bypass all git-dependent plugins.",
    );

has no_git_commit => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit [Git::Commit] and [Git::CommitBuild] and related [Git::Tag] operations.",
    );

has no_git_commit_build => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit [Git::CommitBuild] and related [Git::Tag] operations.",
    );


has no_git_push => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit [Git::Push].",
    );

has no_git_impact => (
    isa     => 'Bool',
    default => 0,
    -doc    => <<~"_EOT_"
Omit any [Git:*] plugins that may modify the vcs repository state, such as : [Git::Commit], [Git::CommitBuild], [Git::Tag], [Git::Push] and the like.
Git plugins that are read-only, such as [Git::GatherDir] or [Git::Check] shouldn't be effected by this option.
_EOT_
    );

has no_github => (
    isa     => 'Bool',
    default => sub { ( $_[0]->hub // '' ) !~ m/^github$/ },
    -doc    =>
      "Do not assume that the repository is backed by 'github', which currently means abstaining from using [GithubMeta] and feeding fake values to [MetaResources] and [Bugtracker] -- which you may separately override, by the way, thanks to our[\@Config::Slicer] role.",
      );

has no_minimum_perl => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit [Test::MinimumVersion] tests.",
    );

has no_pod_coverage => (
    isa     => 'Bool',
    default => sub { $_[0]->no_coverage // 0 },
    -doc    => "Skip [PodCoverage] tests -- Well, [Test::Pod::Coverage::Configurable] tests, actually.",
    );

has no_pod_spellcheck => (
    isa     => 'Bool',
    default => sub { $_[0]->no_spellcheck // 0 },
    -doc    => "Skip [Test::PodSpelling] tests.",
    );

has no_portability_check => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Skip [Test::Portability] tests.",
    );

has no_sanitize_version => (
    isa     => 'Bool',
    default => 0,
    -doc    => "When set => We won't prefer [RewriteVersion::Sanitized] over [RewriteVersion], which we normally do.",
    );

has no_spellcheck => (
    isa     => 'Bool',
    default => 0,
    -doc    => "Omit [Test::PodSpelling] tests.",
    );

has pod_coverage_class => (
    isa  => 'Maybe[Str]',
    -doc => "If defined, passed to [Test::Pod::Coverage::Configurable] as its 'class' option.",
    );

has pod_coverage_skip => (
    isa  => 'Maybe[ArrayRef]',
    -doc => "If defined, passed to [Test::Pod::Coverage::Configurable] as its 'skip' option.",
    );

has pod_coverage_trustme => (
    isa  => 'Maybe[ArrayRef]',
    -doc => "If defined, passed to [Test::Pod::Coverage::Configurable] as its 'trustme' option.",
    );

has pod_coverage_also_private => (
    isa  => 'Maybe[ArrayRef]',
    -doc => "If defined, passed to [Test::Pod::Coverage::Configurable] as its 'also_private' option.",
    );

has tag_format => (
    isa     => 'Str',
    default => 'repo-release-v%V%t',
    -doc    => <<~"__EOT__"
The tag format passed to [Git::Tag] after committing sources.
The default is 'repo-release-v%V%t', which may be prefixed by some other string.
The idea was copied from \@DAGOLDEN who chose something more robust than just the version number when parsing versions with a regex.
__EOT__
    );

has tag_format_dist => (
    isa     => 'Str',
    default => 'dist-release-v%V%t',
    -doc    => <<~"__EOT__"
The tag format passed to [Git::Tag] after committing the build.
The default is 'dist-release-v%V%t', which may be prefixed by some other string.
The idea was copied from \@DAGOLDEN who chose something more robust than just the version number when parsing versions with a regex.
__EOT__
    );

has stopwords => ( ## ALIAS: stopword
    isa     => 'ArrayRef',
    default => sub { [] },
    -doc    =>
      "Additional stopword(s) for Pod::Spell tests. [May be repeated]. See also: 'stopword_files' and 'wordlists' for alternative mechanisms of adding stopwords.",
      );

has stopwords_files => ( ## ALIAS: stopwords_file
    isa     => 'ArrayRef',
    default => sub { [ grep -e, qw(stopwords) ] },
    -doc    =>
      "File(s) that describe additional stopword(s) for Pod::Spell tests. [May be repeated]. See also: 'stopwords' and 'wordlists' for alternative mechanisms of adding stopwords.",
      );

has stopwords_providers => ( ## ALIAS: wordlist
    isa     => 'ArrayRef',
    default => sub { [q/Pod::Wordlist::Author::TABULO/] },
    -doc    => <<~"__EOT__"
Perl module(s) for contributing additional stopword(s) for spelling tests. [May be repeated].
Note that given module(s) would need to expose the same API as L<Pod::Wordlist>.
See also: 'stopwords' and 'stopword_files' for alternative mechanisms of adding stopwords.
__EOT__
    );

has version_regexp => (
    isa     => 'Str',
    default => '^(?:[-\w]+)?release-(.+)$',
    -doc    => "The version regex that corresponds to the 'tag_format'.",
    );

has weaver_config => (
    isa     => 'Str',
    default => '@Author::TABULO',
    -doc    => "Specifies a Pod::Weaver bundle to be used.",
    );


##== PRIVATE attributes
has _fake_release => (
    isa     => 'Bool',
    default => sub {
        exists $ENV{FAKE_RELEASE} ? !!$ENV{FAKE_RELEASE} : $_[0]->fake_release // 0 || $_[0]->darkpan;
    },
    -access => 'private',
    -doc    => "->fake_release (effective), also taking into account the \%ENV and other parameters.",
    );

has _stopwords => (
    traits  => ['Array'],
    isa     => 'ArrayRef',
    builder => '_build__stopwords',
    handles => {
        _all_stopwords => 'elements',
      },
    -access => 'private',
    -doc => "->stopwords (effective): also taking into account all valid sources: ->stopwords, ->stopwords_files, ->stopwords_providers, ...",
    );

has _harvested_files => (
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        _all_harvested_files   => 'elements',
        _add_harvested_files   => 'push',
        _clear_harvested_files => 'clear',
      },
    -access => 'private',
    -doc    =>
      "List of files that are effectively 'harvested', i.e. default candidates to be copied from the build/release. This list is dynamically built during bundle configuration.",
      );

has _installer_files => (
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [ $_[0]->installer =~ /MakeMaker/ ? 'Makefile.PL' : 'Build.PL' ] },
    -access => 'private',
    -doc    =>
      "List of files that are expected to be generated for the given installer. (e.g. : Makefile.PL, Build.PL, ...).  TODO: handle 'ppport.h' and equivalent.",
      );

has _plugins => (
    traits  => ['Array'],
    isa     => 'ArrayRef',
    builder => '_build_plugins',
    -access => 'private',
    -doc    => "The roster on which we prepare our plugin configuration.",
    );

has _target_branches => (
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        _all_target_branches   => 'elements',
        _add_target_branches   => 'push',
        _clear_target_branches => 'clear',
      },
    -access => 'private',
    -doc    =>
      "List of branches that will become targets for [Git::Push]",
      );

#region: BUILDARGS and co: copied/adapted from: @DROLSKY

my @array_params = grep { !/^_/ } map { $_->name }
  grep {
      $_->has_type_constraint
      && ( $_->type_constraint->is_a_type_of('ArrayRef') || $_->type_constraint->is_a_type_of('Maybe[ArrayRef]') )
  } __PACKAGE__->meta->get_all_attributes;

sub mvp_multivalue_args {
    return @array_params;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    my %args = ( %{ $p->{payload} }, %{$p} );

    for my $key (@array_params) {
        if ( $args{$key} && !ref $args{$key} ) {
            $args{$key} = [ delete $args{$key} ];
        }

        # $args{$key} //= [];
    }

    return \%args;
};

#endregion @DROLSKY


#region #== ATTRIBUTE BUILDERS ==

sub _build__stopwords {
    my $self = shift;

    my @teachers;
    push @teachers, map { require_module $_ ? $_ : () } @{ $self->stopwords_providers };
    push @teachers, map { path($_) // () } @{ $self->stopwords_files };
    push @teachers, join( ' ', @{ $self->stopwords // [] } );

    my $lexicon = Pod::Wordlist::Author::TABULO->new();
    $lexicon->learn_stopwords_from(@teachers);
    return [ sort keys %{ $lexicon->wordlist } ];
}

#endregion

#region #== DYNAMIC ATTRIBUTES (recomputed on each call) ==
sub _all_git_remotes {
    my $self  = shift;
    uniq ( split( ' ', join( ' ',
        grep { defined $_ && $_ }
        flat $self->git_remotes
    )))
}

sub _files_to_copy { # from build (or release)
    my $self    = shift;
    my @include = uniq(
        sort @{ $self->_harvested_files },
        @{ $self->copy }, # extras requested via "dist.ini"
        @_                # extras requested via passed arguments
        );
    my @exclude = uniq( sort( @{ $self->copy_not } ) );
    my @res     = grep {
        my $item = $_; not grep { $item eq $_ } @exclude
    } @include;
    [ uniq( sort(@res) ) ];
}

sub _allow_dirty_on_release_commit {
    my @res = uniq_sort_flat(
        @allow_dirty,
        $boilerplate{readme}, # Readme.* may be directly harvested under dist-root/ (not copied from build/)
        $_[0]->_files_to_copy,
        @_                    # extras requested via passed arguments
        );
    [ grep -e, @res ];
}

sub _files_to_exclude { # files that might be in the repository, but that should not be gathered
    [ uniq_sort_flat( @never_gather, $_[0]->_files_to_copy, $_[0]->exclude_filenames ) ];
}

#endregion DYNAMIC ATTRIBUTES

#endregion ATTRIBUTES

#region: #== UTILITY METHODS ==

sub payload_item {
    my ( $self, $key ) = (@_);
    exists $self->payload->{$key} ? $self->payload->{$key} : undef;
}

#endregion (UTILITY METHODS)


#region: #=== MEAT ===

sub configure {
    my $self = shift;
    $self->_check;
    $self->add_plugins( @{ $self->_plugins } );
}

sub _check {
    my $self = shift;
    my $name = $self->name;

    # check: installer support status
    my $installer = $self->installer;
    die "Unsupported installer $installer\n"
      unless $allowed_installers{$installer};
    return 1;
}

sub _build_plugins {
    my ($self) = @_;
    my @plugins;
    for my $p ( $self->_prepare_plugins ) {

        # CODE references are OK (though that would rarely be needed)
        push @plugins, ref $p eq 'CODE' ? $p->($self) : $p;
    }
    [@plugins];
}

sub _plug__CopyFiles {
    my ($self) = @_;

    my @plugins;
    my sub plugin { push @plugins, grok_plugins(@_) }

    my @files_to_copy = flat $self->_files_to_copy;
    my $no_copy       = $self->no_copy;

    for ( $self->copy_mode // () ) {
        last unless @files_to_copy;
        if ( $no_copy || m/Regenerate$/i ) {
            plugin 'Regenerate' => { filename => [@files_to_copy] }; # Allows `dzil regenerate` (no copying during normal flows)
            last;
        }
        if (m/Release$/i) {
            plugin 'CopyFilesFromRelease'       => { filename => [@files_to_copy] };
            plugin 'Regenerate::AfterReleasers' => { plugin   => $self->name . '/CopyFilesFromRelease' };
        } elsif (m/Build::?Filtered$/i) {
            plugin 'CopyFilesFromBuild::Filtered' => { copy => [@files_to_copy] };
        } elsif (m/Build$/i) {
            plugin 'CopyFilesFromBuild' => { copy => [@files_to_copy] };
        } elsif (m/(^|none)$/i) {

            # Noop.
        } else {
            die "Illegal file-copy mode: '$_'";
        }
    }
    @plugins;
}

sub _plug__Weaver {
    my ($self) = @_;
    $self->is_task
      ? 'TaskWeaver'
      : [
          'SurgicalPodWeaver' => {
              maybe
              config_plugin      => $self->weaver_config,
              replacer           => 'replace_with_comment',
              post_code_replacer => 'replace_with_nothing',
          }
          ];
}

sub _plug__GitCommit__sourcesAsReleased {
    # Commit sources and generated files (as released) + tag the release
    my ($self, $label) = (shift, shift // 'sourcesAsReleased');
    return if $self->no_git || $self->no_git_impact || $self->no_git_commit;

    (
        [ "Git::Commit/$label" => {
            add_files_in => '/', # add harvested files (README.md, LICENSE, ..) upon initial creation.
            mayhap
            allow_dirty => $self->_allow_dirty_on_release_commit,
            commit_msg => 'v%V%n%n%c', # differs from @DAGOLDEN
            }
        ],

        [ "Git::Tag/$label" => { tag_format => $self->tag_format } ],
    )
}

sub _plug__GitCommit__sourcesAfterBump {
    # Commit the change-log (just stamped) and perl sources (where $VERSION has just been bumped)
    my ($self, $label) = (shift, shift // 'sourcesAfterBump');
    return if $self->no_git || $self->no_git_impact || $self->no_git_commit;

    [
        "Git::Commit/$label" => {
            commit_msg => "After release: bump \$VERSION and timestamp Changes",
            ## and also commit files copied from the build/release
            allow_dirty_match => '^(lib|bin|script)', # Possibly bumped $VERSION in actual perl sources by [BumpVersionAfterRelease]
            allow_dirty => [
                qw/Changes/,             # modified by ['NextRelease']
                $self->_installer_files, # Possibly bumped '$VERSION in 'Makefile.PL' or 'Build.PL'
            ],

        }
    ]
}

sub _plug__GitCommitBuild__toBuildBranch {
    my ($self, $label) = (shift, shift // 'toBuildBranch');
    return if $self->no_git || $self->no_git_impact || $self->no_git_commit || $self->no_git_commit_build;

    (
        [ "Git::CommitBuild/$label" => {  branch => 'build/%b', multiple_inheritence => 1 }]
    )
}

sub _plug__GitCommitBuild__toReleaseBranch {
    my ($self, $label) = (shift, shift // 'toReleaseBranch');
    return if $self->no_git || $self->no_git_impact || $self->no_git_commit || $self->no_git_commit_build;

    my $branch = 'release/cpan';
    $self->_add_target_branches($branch);

    (
    ["Git::CommitBuild/$label" => { branch => '', release_branch => $branch,  multiple_inheritence => 1 } ],
    ["Git::Tag/$label"  => { branch => $branch, tag_format => $self->tag_format_dist } ],
    )
}

sub _plug__GitPush {
    my ($self, $label) = (shift, shift // '');
    return if $self->no_git || $self->no_git_impact || $self->no_git_push;

    my @targets;
    my @branches = uniq( $self->_all_target_branches );
    for my $remote ( $self->_all_git_remotes ) {
        push @targets, "$remote";
        for my $branch (@branches) {
            next unless $branch // '';
            push @targets, "$remote refs/heads/$branch:refs/heads/$branch",
        }
    }

    [ 'Git::Push' => { push_to => \@targets, remotes_must_exist => 0 } ]
}

sub _prepare_plugins {
    my ($self) = @_;
    my @plugins;
    my sub plugin  { push @plugins, grok_plugins(@_) }
    my sub harvest { $self->_add_harvested_files(@_) }
    $self->_clear_harvested_files;


    my $auto_version  = $self->auto_version;
    my $darkpan       = $self->darkpan;
    my $no_git        = $self->no_git;
    my $no_github     = $self->no_github || $self->no_git || $self->darkpan;
    my $no_versioning = !!!$self->manage_versions;

    # decide on some mutually exclusive alternatives
    my $gatherer = $no_git // 0 ? 'GatherDir' : 'Git::GatherDir';
    my $versioner =
        $self->auto_version             ? 'AutoVersion'
      : $self->no_sanitize_version // 0 ? 'RewriteVersion'
      :                                   'RewriteVersion::Sanitized';


    ##=== EARLY birds
    plugin 'NameFromDirectory'; # src: @Milla
    plugin $versioner;          # XXX: I don't know why @DAGOLDEN lists this so early...

    ##=== file gatherers
    plugin $gatherer => {
        mayhap
          exclude_filename => $self->_files_to_exclude,
        mayhap
          exclude_match => $self->exclude_match,
        include_dotfiles => 1, # PruneCruft should take care of pruning dotfiles (w/ possible exceptions)
        };

    ##=== file pruners
    plugin 'PruneCruft' => { maybe except => @prune_not ? [@prune_not] : undef, };

    plugin 'PruneFiles' => { filename => ['README.pod'] }; # Otherwise: MakeMaker will try to install it!
    plugin 'ManifestSkip';

    ###== file mungers
    plugin 'InsertCopyright';
    plugin 'PkgVersion' if $self->auto_version // 0;       # [TAU] : XXX: Consider: OurPkgVersion (which doesn't add lines)
    plugin $self->_plug__Weaver;

    ##=== file generators
    ## --except Meta* and Manifest which are postponed until the latest possible moment
    ## XXX: Readme generation needs to come after POD weaving (which munges POD, obviously...)
    plugin 'Pod2Readme'; #   We don't really need to harvest the plain-text README into dist-root, since we will have README.md
    plugin 'License'      and harvest 'LICENSE';
    plugin 'InstallGuide' and harvest 'INSTALL';
    plugin 'ReadmeAnyFromPod / MarkdownInBuild' => {
        type     => 'markdown',
        filename => 'README.md',
        location => 'build',    # 'root',
        phase    => 'build',
      }
      and harvest 'README.md';

    ##=== author tests
    plugin 'Test::Compile' => {
        xt_mode   => 1,
        fake_home => 1
        };
    plugin 'Test::MinimumVersion' => { max_target_perl => '5.026' }
      unless $self->no_minimum_perl;
    plugin 'Test::ReportPrereqs';

    ##== harvested xt/ tests
    plugin 'Test::Perl::Critic'
      unless $self->no_critic;
    plugin 'MetaTests';
    plugin 'PodSyntaxTests';
    plugin 'Test::PodSpelling' => { mayhap stopwords => $self->_stopwords, }
      unless $self->no_pod_spellcheck;

    plugin 'Test::Pod::Coverage::Configurable' => {
        maybe
          class => $self->pod_coverage_class,
        mayhap
          skip => $self->pod_coverage_skip,
        mayhap
          trustme => $self->pod_coverage_trustme,
        mayhap also_private => $self->pod_coverage_also_private,
      }
      unless $self->no_pod_coverage;


    plugin 'Test::Portability' => { options => "test_one_dot = 0" }
      unless $self->no_portability_check;

    plugin 'Test::Version';
    plugin 'Test::Kwalitee';
    plugin 'MojibakeTests';
    plugin 'Test::EOL';

    ##=== meta
    plugin 'Authority' => {
        authority  => $self->authority,
        do_munging => 0,
        };
    plugin 'CopyrightYearFromGit' => { continuous_year => 1 }
      unless $no_git;

    plugin 'Keywords';
    plugin 'MinimumPerl';
    plugin 'AutoPrereqs' => { skip => "^t::lib" }
      if $self->auto_prereqs;
    plugin 'PrereqsFile' if -e 'prereqs.yml' || -e 'prereqs.json';
    plugin 'MetaNoIndex' => {
        directory => [ sort( qw(t xt), qw(corpus demo eg examples fatlib local inc perl5 share) ) ],
        'package' => [qw/DB/],
        };
    plugin 'MetaProvides::Package' => { # MUST come AFTER MetaNoIndex
        meta_noindex => 1,

        # maybe inherit_version => ( $no_versioning ? 0 : undef ),
        };
    plugin 'GithubMeta' => {
        remote       => [qw(origin github)],
        maybe issues => $self->github_issues || undef,
      }
      unless $no_github;

    plugin 'Bugtracker' => {            # fake out Pod::Weaver::Section::Support (if needed)
        mailto    => '',
        maybe web => ( $self->darkpan ? "http://localhost/" : undef ),
      }
      if $no_github || !$self->github_issues;

    plugin 'MetaResources' => {         # fake out Pod::Weaver::Section::Support (if needed)
        'repository.url' => "http://localhost/",
        'repository.web' => "http://localhost/",
      }
      if $no_github;

    plugin 'Git::Contributors' unless $no_git;
    plugin 'Prereqs::AuthorDeps' if $self->auto_prereqs;
    plugin 'RemovePrereqs::Provided';   # Must come after MetaProvides
    plugin 'PrereqsClean';
    plugin 'MetaYAML' and harvest 'Meta.yml';
    plugin 'MetaJSON' and harvest 'Meta.json';
    plugin 'CPANFile' and harvest 'cpanfile';

    ##=== build system, INSTALLER, ..., Manifest
    plugin 'ExecDir' => { maybe dir => $self->exec_dir, };
    plugin 'ShareDir';                  # core
    plugin $self->installer and harvest( flat $self->_installer_files );
    plugin 'PromptIfStale' => {         # are we up to date?
        modules           => [ qw/Dist::Zilla/, __PACKAGE__ ],
        check_all_plugins => 1,
        };
    plugin 'Manifest';                  # core.  -- must come after all harvested files

    ##=== BEFORE RELEASE: extra tests (src: @Starter, @DAGOLDEN)
    ## MUST come before test/confirm for before-release verification
    plugin 'Git::CheckFor::CorrectBranch' unless $no_git;
    plugin 'Git::Check' => { allow_dirty => [@allow_dirty] } unless $no_git;
    plugin 'CheckMetaResources';
    plugin 'CheckPrereqsIndexed';
    plugin 'CheckChangesHasContent';
    plugin 'ConsistentVersionTest';
    plugin 'CheckStrictVersion';
    plugin 'CheckVersionIncrement'
      unless $self->_fake_release;
    plugin 'Test::CheckManifest';
    plugin 'RunExtraTests' => { default_jobs => 9 };

    ##== test/confirm release (just before releaser)
    plugin 'TestRelease';
    plugin 'ConfirmRelease';

    ##=== release
    plugin( $self->_fake_release ? 'FakeRelease' : 'UploadToCPAN' ); # core

    ##=== AFTER release
    plugin $self->_plug__CopyFiles; ## Copy files (from the release/build to the repo)
    plugin $self->_plug__GitCommit__sourcesAsReleased unless $self->no_git || $self->no_git_impact;
    plugin 'NextRelease' => { ## stamp the change-log and bump $VERSION (in all source files)
        ## 'NextRelease' marks the release in the change-log (but also does munging earlier).
        ##  It is placed here to get the ordering right with git actions.
        time_zone => 'UTC',
        format    => '%-20{-TRIAL}V    %{yyyy-MM-dd HH:mm:ssZZZZZ VVV}d %P'
      }
      unless $no_versioning;

    plugin 'BumpVersionAfterRelease' ## Bump $VERSION (after the release) directly on source files (in lib/)!
      unless $no_versioning || $auto_version;

    unless ($self->no_git || $self->no_git_impact) {
        plugin $self->_plug__GitCommit__sourcesAfterBump;
        plugin $self->_plug__GitCommitBuild__toBuildBranch;
        plugin $self->_plug__GitCommitBuild__toReleaseBranch;
        plugin $self->_plug__GitPush;
    }

    plugin 'ArchiveRelease' => { directory => $self->archive_dir } unless $self->no_archive || !$self->archive_dir;

    @plugins;
}

#endregion: MEAT


__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n] cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto
metadata placeholders metacpan

=head1 NAME

Dist::Zilla::PluginBundle::Author::TABULO - A Dist::Zilla plugin bundle à la TABULO

=head1 VERSION

version 1.000011

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::TABULO]

=head1 DESCRIPTION

This is the dzil plug-in bundle that TABULO intends to use for his distributions.

It exists mostly because TABULO is very lazy, like many other folks out there.

But since TABULO is probably even lazier than most folks; instead of starting his
bundle from scratch, he just shopped around to find a few bundles that had the most
overlap with his taste or whatever; and then just slurped stuff,
even including some documentation which is what you will eventually see here and in the
related modules.:-)

Admittedly, the fact that TABULO was so late in migrating to dzil worked to his
advantage for this particular task at least, since by that time
the bold and the brave had already made delicious stuff!

As such, it is heavily inspired by (and in some places outright copied from) several others such as:
@DAGOLDEN, @DBOOK, @DROLSKY, @ETHER, @KENTNL, @RJBS, @Starter, @Starter::Git, @YANICK.

(Thank you, folks!).

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

Also note that the early versions of this module had much more in common with that of @ETHER, and tried to keep a compatible interface. This is no longer the case. So some stuff will break, and hence the bump of major version. But you weren't really using this for your distros anyway, right?

And here comes the rest of the documentation -- some of which slurped from the several original sources cited above ... :-)

=head2 OVERVIEW

Using this plugin bundle (with its default options) is roughly equivalent to the following content in C<dist.ini>.

    ...

    [NameFromDirectory]

    [RewriteVersion::Sanitized]

    [Git::GatherDir]
    exclude_filename = Build.PL
    exclude_filename = CODE_OF_CONDUCT
    exclude_filename = CONTRIBUTING
    exclude_filename = INSTALL
    exclude_filename = LICENCE
    exclude_filename = LICENSE
    exclude_filename = META.json
    exclude_filename = Makefile.PL
    exclude_filename = Meta.yml
    exclude_filename = README
    exclude_filename = README.md
    exclude_filename = README.mkdn
    exclude_filename = README.pod
    exclude_filename = TODO
    exclude_filename = cpanfile
    exclude_filename = inc/ExtUtils/MakeMaker/Dist/Zilla/Develop.pm
    exclude_filename = ppport.h
    include_dotfiles = 1

    [PruneCruft]
    except = (?^u:"\.travis\.yml")
    except = (?^u:"\.perltidyrc")
    except = (?^u:".*/\.gitignore$")
    except = (?^u:".*/\.(git)?keep$")

    [PruneFiles]
    filename = README.pod

    [ManifestSkip]

    [InsertCopyright]

    [SurgicalPodWeaver]
    config_plugin = @Author::TABULO
    post_code_replacer = replace_with_nothing
    replacer = replace_with_comment

    [Pod2Readme]

    [License]

    [InstallGuide]

    [ReadmeAnyFromPod / ReadmeAnyFromPod/MarkdownInBuild]
    filename = README.md
    location = build
    phase = build
    type = markdown

    [Test::Compile]
    fake_home = 1
    xt_mode = 1

    [Test::MinimumVersion]
    max_target_perl = 5.026

    [Test::ReportPrereqs]

    [Test::Perl::Critic]

    [MetaTests]

    [PodSyntaxTests]

    [Test::PodSpelling]

    [Test::Pod::Coverage::Configurable]

    [Test::Portability]
    options = test_one_dot = 0

    [Test::Version]

    [Test::Kwalitee]

    [MojibakeTests]

    [Test::EOL]

    [Authority]
    authority = cpan:TABULO
    do_munging = 0

    [CopyrightYearFromGit]
    continuous_year = 1

    [Keywords]

    [MinimumPerl]

    [AutoPrereqs]
    skip = ^t::lib

    [PrereqsFile]

    [MetaNoIndex]
    directory = corpus
    directory = demo
    directory = eg
    directory = examples
    directory = fatlib
    directory = inc
    directory = local
    directory = perl5
    directory = share
    directory = t
    directory = xt
    package = DB

    [MetaProvides::Package]
    meta_noindex = 1

    [GithubMeta]
    issues = 1
    remote = origin
    remote = github

    [Git::Contributors]

    [Prereqs::AuthorDeps]

    [RemovePrereqs::Provided]

    [PrereqsClean]

    [MetaYAML]

    [MetaJSON]

    [CPANFile]

    [ExecDir]

    [ShareDir]

    [MakeMaker]

    [PromptIfStale]
    check_all_plugins = 1
    modules = Dist::Zilla
    modules = @Author::TABULO

    [Manifest]

    [Git::CheckFor::CorrectBranch]

    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = Changes

    [CheckMetaResources]

    [CheckPrereqsIndexed]

    [CheckChangesHasContent]

    [ConsistentVersionTest]

    [CheckStrictVersion]

    [CheckVersionIncrement]

    [Test::CheckManifest]

    [RunExtraTests]
    default_jobs = 9

    [TestRelease]

    [ConfirmRelease]

    [UploadToCPAN]

    [CopyFilesFromRelease]
    filename = INSTALL
    filename = LICENSE
    filename = Makefile.PL
    filename = Meta.json
    filename = Meta.yml
    filename = README.md
    filename = cpanfile

    [Regenerate::AfterReleasers]
    plugin = @Author::TABULO/CopyFilesFromRelease

    [Git::Commit / Git::Commit/sourcesAsReleased]
    add_files_in = /
    allow_dirty = Changes
    allow_dirty = INSTALL
    allow_dirty = LICENSE
    allow_dirty = Makefile.PL
    allow_dirty = Meta.json
    allow_dirty = Meta.yml
    allow_dirty = README.md
    allow_dirty = cpanfile
    commit_msg = v%V%n%n%c

    [Git::Tag / Git::Tag/sourcesAsReleased]
    tag_format = release-%v

    [NextRelease]
    format = %-20{-TRIAL}V    %{yyyy-MM-dd HH:mm:ssZZZZZ VVV}d %P
    time_zone = UTC

    [BumpVersionAfterRelease]

    [Git::Commit / Git::Commit/sourcesAfterBump]
    allow_dirty = Changes
    allow_dirty = ARRAY(0x7fd7767bf1e0)
    allow_dirty_match = ^(lib|bin|script)
    commit_msg = After release: bump $VERSION and timestamp Changes

    [Git::CommitBuild / Git::CommitBuild/toBuildBranch]
    branch = build/%b
    multiple_inheritence = 1

    [Git::CommitBuild / Git::CommitBuild/toReleaseBranch]
    branch =
    multiple_inheritence = 1
    release_branch = release/cpan

    [Git::Tag / Git::Tag/toReleaseBranch]
    branch = release/cpan
    tag_format = release-%v

    [Git::Push]
    push_to = origin
    push_to = origin refs/heads/release/cpan:refs/heads/release/cpan
    remotes_must_exist = 0

    [ArchiveRelease]
    directory = releases

=head1 ATTRIBUTES

=head2 archive_dir

Reader: archive_dir

Type: Str

Additional documentation: Passed as the 'directory' option, to [ArchiveRelease] whose docs are quoted below:

* The 'directory' [name] may begin with ~ (or ~user) to mean your (or some other user's) home directory.
* If the directory doesn't exist, it will be created during the BeforeRelease phase.
* All files inside this directory will be pruned from the distribution.
 Default: 'releases'

=head2 authority

Reader: authority

Type: Str

Additional documentation: Specifies the x_authority field for PAUSE. Default: 'cpan:TABULO'

=head2 auto_prereqs

Reader: auto_prereqs

Type: Bool

Additional documentation: Indicates whether or not to use [AutoPrereqs]. Default: '1'

=head2 auto_version

Reader: auto_version

Type: Bool

Additional documentation: Indicates whether or not to use [AutoVersion] instead of our standard plugins for version management. Default: '0'

=head2 copy

Reader: copy

Type: ArrayRef

Additional documentation: Additional files to copy (or regenerate) in addition to those that are already harvested by default. [May be repeated]. Note that the copying may be done from the build or the release, depending on the 'copy_mode' setting. See 'copy_mode'.

=head2 copy_mode

Reader: copy_mode

Type: Maybe[Str]

Additional documentation: Determines the 'copy-mode' and hence ultimately the set of plugins used for that purpose. Possible values are  [Regenerate, Release, Build, Build::Filtered, None]. dzil 'regenerate' command will still work.  Default: 'Release'

=head2 copy_not

Reader: copy_not

Type: ArrayRef

Additional documentation: Do NOT copy given file(s). [May be repeated].

=head2 darkpan

Reader: darkpan

Type: Bool

Additional documentation: For private code; uses [FakeRelease] and fills in dummy repo/bugtracker data. Default: '0'

=head2 dist_genre

Reader: dist_genre

Type: Str

Additional documentation: Specifies the 'genre' of the distro. Currently allowed values are: 'standard' (the default) and 'task'.

This may be used in the future to associate a set behaviours/settings to given genres.

Currently, the only distinction made is for the 'task' genre, which will result in [TaskWeaver] being used
instead of [SurgicalPodWeaver].
 Default: 'standard'

=head2 exclude_filenames

Reader: exclude_filenames

Type: ArrayRef

Additional documentation: Do NOT gather given file(s). [May be repeated].

=head2 exclude_match

Reader: exclude_match

Type: ArrayRef

Additional documentation: Do NOT gather file(s) that match the given pattern(s). [May be repeated].

=head2 exec_dir

Reader: exec_dir

Type: Maybe[Str]

Additional documentation: If defined, passed to [ExecDir] as its 'dir' option.  Defaults to 'script' when the installer is [Module::Build::Tiny],undef otherwise, which means the [ExecDir] default will be in effect, and that is 'bin' as of this writing.

=head2 fake_release

Reader: fake_release

Type: Bool

Additional documentation: Swaps [FakeRelease] for [UploadToCPAN]. Mostly useful for testing a dist.ini without risking a real release. Note that this can also be achieved by setting the FAKE_RELEASE environment variable (which will have precedence over this option). Default: '0'

=head2 git_remotes

Reader: git_remotes

Type: ArrayRef

Additional documentation: Where to push after release.

=head2 github_issues

Reader: github_issues

Type: Str

Additional documentation: Whether or not to use github issue tracker. Default: '1'

=head2 has_xs

Reader: has_xs

Type: Bool

=head2 hub

Reader: hub

Type: Maybe[Str]

Additional documentation: The repository 'hub' provider. Currently, other than unsetting to undef, the only supported value, which is also the default, is 'github'. Other providers, such as 'gitlab' or 'bitbucket', may be supported in the future. Default: 'github'

=head2 installer

Reader: installer

Additional documentation: The installer to employ. Currently, possible values are: [MakeMaker, MakeMaker::Awesome, ModuleBuild, ModuleBuildTiny, ModuleBuildTiny::Fallback]. Default: 'MakeMaker'

=head2 is_task

Reader: is_task

Type: Bool

Additional documentation: DEPRECATED. Prefer setting instead, like so:

[@Author::TABULO]
dist_genre=task

Identifies this distro as a 'task'.

Currently, the only distinction is that, for a task, we use [TaskWeaver] instead of [SurgicalPodWeaver].

=head2 manage_versions

Reader: manage_versions

Type: Bool

Additional documentation: Whether or not to manage versioning, which means: providing, rewriting, bumping, munging $VERSION in sources, .... Default: '1'

=head2 name

Reader: name

Type: Str

This attribute is required.

=head2 no_archive

Reader: no_archive

Type: Bool

Additional documentation: Omit the [ArchiveRelease] plugin. Default: '0'

=head2 no_copy

Reader: no_copy

Type: Bool

Additional documentation: Skip copying files from the build/release : ('Makefile.PL', 'cpanfile',' Meta.json', ...). Default: '0'

=head2 no_coverage

Reader: no_coverage

Type: Bool

Additional documentation: Omit PodCoverage tests -- which are actually done using [Test::Pod::Coverage::Configurable]. Default: '0'

=head2 no_critic

Reader: no_critic

Type: Bool

Additional documentation: Omit [Test::Perl::Critic] tests. Default: '0'

=head2 no_git

Reader: no_git

Type: Bool

Additional documentation: Bypass all git-dependent plugins. Default: '0'

=head2 no_git_commit

Reader: no_git_commit

Type: Bool

Additional documentation: Omit [Git::Commit] and [Git::CommitBuild] and related [Git::Tag] operations. Default: '0'

=head2 no_git_commit_build

Reader: no_git_commit_build

Type: Bool

Additional documentation: Omit [Git::CommitBuild] and related [Git::Tag] operations. Default: '0'

=head2 no_git_impact

Reader: no_git_impact

Type: Bool

Additional documentation: Omit any [Git:*] plugins that may modify the vcs repository state, such as : [Git::Commit], [Git::CommitBuild], [Git::Tag], [Git::Push] and the like.
Git plugins that are read-only, such as [Git::GatherDir] or [Git::Check] shouldn't be effected by this option.
 Default: '0'

=head2 no_git_push

Reader: no_git_push

Type: Bool

Additional documentation: Omit [Git::Push]. Default: '0'

=head2 no_github

Reader: no_github

Type: Bool

Additional documentation: Do not assume that the repository is backed by 'github', which currently means abstaining from using [GithubMeta] and feeding fake values to [MetaResources] and [Bugtracker] -- which you may separately override, by the way, thanks to our[@Config::Slicer] role.

=head2 no_minimum_perl

Reader: no_minimum_perl

Type: Bool

Additional documentation: Omit [Test::MinimumVersion] tests. Default: '0'

=head2 no_pod_coverage

Reader: no_pod_coverage

Type: Bool

Additional documentation: Skip [PodCoverage] tests -- Well, [Test::Pod::Coverage::Configurable] tests, actually.

=head2 no_pod_spellcheck

Reader: no_pod_spellcheck

Type: Bool

Additional documentation: Skip [Test::PodSpelling] tests.

=head2 no_portability_check

Reader: no_portability_check

Type: Bool

Additional documentation: Skip [Test::Portability] tests. Default: '0'

=head2 no_sanitize_version

Reader: no_sanitize_version

Type: Bool

Additional documentation: When set => We won't prefer [RewriteVersion::Sanitized] over [RewriteVersion], which we normally do. Default: '0'

=head2 no_spellcheck

Reader: no_spellcheck

Type: Bool

Additional documentation: Omit [Test::PodSpelling] tests. Default: '0'

=head2 payload

Reader: payload

Type: HashRef

This attribute is required.

=head2 plugins

Reader: plugins

Type: ArrayRef

=head2 pod_coverage_also_private

Reader: pod_coverage_also_private

Type: Maybe[ArrayRef]

Additional documentation: If defined, passed to [Test::Pod::Coverage::Configurable] as its 'also_private' option.

=head2 pod_coverage_class

Reader: pod_coverage_class

Type: Maybe[Str]

Additional documentation: If defined, passed to [Test::Pod::Coverage::Configurable] as its 'class' option.

=head2 pod_coverage_skip

Reader: pod_coverage_skip

Type: Maybe[ArrayRef]

Additional documentation: If defined, passed to [Test::Pod::Coverage::Configurable] as its 'skip' option.

=head2 pod_coverage_trustme

Reader: pod_coverage_trustme

Type: Maybe[ArrayRef]

Additional documentation: If defined, passed to [Test::Pod::Coverage::Configurable] as its 'trustme' option.

=head2 stopwords

Reader: stopwords

Type: ArrayRef

Additional documentation: Additional stopword(s) for Pod::Spell tests. [May be repeated]. See also: 'stopword_files' and 'wordlists' for alternative mechanisms of adding stopwords.

=head2 stopwords_files

Reader: stopwords_files

Type: ArrayRef

Additional documentation: File(s) that describe additional stopword(s) for Pod::Spell tests. [May be repeated]. See also: 'stopwords' and 'wordlists' for alternative mechanisms of adding stopwords.

=head2 stopwords_providers

Reader: stopwords_providers

Type: ArrayRef

Additional documentation: Perl module(s) for contributing additional stopword(s) for spelling tests. [May be repeated].
Note that given module(s) would need to expose the same API as L<Pod::Wordlist>.
See also: 'stopwords' and 'stopword_files' for alternative mechanisms of adding stopwords.

=head2 tag_format

Reader: tag_format

Type: Str

Additional documentation: The tag format passed to [Git::Tag] after committing sources.
The default is 'repo-release-v%V%t', which may be prefixed by some other string.
The idea was copied from @DAGOLDEN who chose something more robust than just the version number when parsing versions with a regex.
 Default: 'repo-release-v%V%t'

=head2 tag_format_dist

Reader: tag_format_dist

Type: Str

Additional documentation: The tag format passed to [Git::Tag] after committing the build.
The default is 'dist-release-v%V%t', which may be prefixed by some other string.
The idea was copied from @DAGOLDEN who chose something more robust than just the version number when parsing versions with a regex.
 Default: 'dist-release-v%V%t'

=head2 version_regexp

Reader: version_regexp

Type: Str

Additional documentation: The version regex that corresponds to the 'tag_format'. Default: '^(?:[-\w]+)?release-(.+)$'

=head2 weaver_config

Reader: weaver_config

Type: Str

Additional documentation: Specifies a Pod::Weaver bundle to be used. Default: '@Author::TABULO'

=for Pod::Coverage configure mvp_aliases payload_item

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/tabulon-perl/p5-Dist-Zilla-PluginBundle-Author-TABULO/issues>.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/tabulon-perl/p5-Dist-Zilla-PluginBundle-Author-TABULO>

  git clone https://github.com/tabulon-perl/p5-Dist-Zilla-PluginBundle-Author-TABULO.git

=head1 CONTRIBUTOR

=for stopwords Tabulo

Tabulo <dev-git.perl@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2022 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: A Dist::Zilla plugin bundle à la TABULO

#region pod


#endregion pod
