package Dist::Zilla::PluginBundle::Author::MELO;

# ABSTRACT: MELO is lazy, this are his rules
our $VERSION = '0.012'; # VERSION
our $AUTHORITY = 'cpan:MELO'; # AUTHORITY

use strict;
use Moose;

## Use most recent versions at the time I wrote this -- I'll probably
## only update them if I really need a newer one
use Dist::Zilla 4.300002;
with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

use Dist::Zilla::Plugin::Authority 1.005              ();
use Dist::Zilla::Plugin::Bugtracker 1.111080          ();
use Dist::Zilla::Plugin::CheckChangesHasContent 0.003 ();
use Dist::Zilla::Plugin::CheckExtraTests 0.004        ();
use Dist::Zilla::Plugin::Clean 0.02                   ();
use Dist::Zilla::Plugin::Git::NextVersion ();
use Dist::Zilla::Plugin::InstallRelease 0.007 ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::MetaProvides::Package 1.12060501 ();
use Dist::Zilla::Plugin::MinimumPerl 1.003                ();
use Dist::Zilla::Plugin::NextRelease   ();
use Dist::Zilla::Plugin::OurPkgVersion ();
use Dist::Zilla::Plugin::PodWeaver     ();
use Dist::Zilla::Plugin::PrereqsClean  ();
use Dist::Zilla::Plugin::ReportVersions::Tiny 1.03 ();
use Dist::Zilla::Plugin::Repository 0.18           ();
use Dist::Zilla::Plugin::Test::Pod::No404s 1.001   ();
use Dist::Zilla::PluginBundle::Basic ();
use Dist::Zilla::PluginBundle::Git 1.112510       ();
use Dist::Zilla::PluginBundle::GitHub 0.30       ();
use Dist::Zilla::PluginBundle::TestingMania 0.014 ();
use Pod::Weaver::PluginBundle::Author::MELO ();

use List::Util qw(first);
use Method::Signatures 20111020;

# don't require it in case it won't install somewhere
my $spelling_tests = eval 'require Dist::Zilla::Plugin::Test::PodSpelling';

# cannot use $self->name for class methods
sub _bundle_name {
  my $class = @_ ? ref $_[0] || $_[0] : __PACKAGE__;
  join('', '@', ($class =~ /^.+::PluginBundle::(.+)$/));
}

# FIXME: add 'debug' option to enable ReportPhase

sub mvp_multivalue_args {qw( disable_tests )}

method _default_attributes {
  use Moose::Util::TypeConstraints 1.01;
  return {
    auto_prereqs  => [Bool            => 1],
    disable_tests => ['ArrayRef[Str]' => []],
    fake_release  => [Bool            => $ENV{DZIL_FAKERELEASE}],
    authority     => [Str             => 'cpan:MELO'],

    # cpanm will choose the best place to install
    install_command      => [Str  => 'cpanm -v -i .'],
    placeholder_comments => [Bool => 1],
    releaser             => [Str  => 'UploadToCPAN'],
    skip_plugins         => [Str  => ''],
    skip_prereqs         => [Str  => '^t::'],
    weaver_config        => [Str  => $self->_bundle_name],
    test_pod_links       => [Bool => 1],
    test_perl_critic     => [Bool => 0],
    test_report_versions => [Bool => 0],
  };
}

method _generate_attribute($key) {
  has $key => (
    is      => 'ro',
    isa     => $self->_default_attributes->{$key}[0],
    lazy    => 1,
    default => method() {
      return exists($self->payload->{$key})
      ? $self->payload->{$key}
      : $self->_default_attributes->{$key}[1];
    }
  );
  }

{

  # generate attributes
  __PACKAGE__->_generate_attribute($_) for keys %{ __PACKAGE__->_default_attributes };
}

# main
after configure => sub {

  # TODO: converting this to a anonymous method using Method::Signatures
  # triggers a bug
  # "my" variable $skip masks earlier declaration in same statement at
  # lib/Dist/Zilla/PluginBundle/Author/MELO.pm line 92, <GEN1> line 11.
  my ($self) = @_;

  my @plugins_to_skip = ($self->skip_plugins);
  push @plugins_to_skip, 'Test::Perl::Critic'   unless $self->test_perl_critic;
  push @plugins_to_skip, 'Test::Pod::LinkCheck' unless $self->test_pod_links;

  my $skip_re = join('|', grep {$_} @plugins_to_skip);
  $skip_re = qr/$skip_re/;

  my $dynamic = $self->payload;

  # sneak this config in behind @TestingMania's back
  $dynamic->{'Test::Compile.fake_home'} = 1
    unless first {/Test::Compile\W+fake_home/} keys %$dynamic;

  my $plugins = $self->plugins;

  my $i = -1;
  while (++$i < @$plugins) {
    my $spec = $plugins->[$i] or next;

    # NOTE: $conf retains its reference (modifications alter $spec)
    my ($name, $class, $conf) = @$spec;

    # ignore the prefix (@Bundle/Name => Name) (DZP::Name => Name)
    my ($alias) = ($name =~ m#([^/]+)$#);

    # exclude any plugins that match 'skip_plugins'
    if ($skip_re) {

      # match on full name or plugin class (regexp should use \b not \A)
      if ($name =~ $skip_re || $class =~ $skip_re) {
        $self->log("Skipping plugin $name");
        splice(@$plugins, $i, 1);
        redo;
      }
    }
  }
  if ($ENV{DZIL_BUNDLE_DEBUG}) {
    eval {
      require Data::Dumper;
      $self->log(Data::Dumper::Dumper($self->plugins));
    };
    warn $@ if $@;
  }
};


method configure {

  $ENV{SKIP_POD_LINKCHECK} = 1 unless exists $ENV{SKIP_POD_LINKCHECK};
  $ENV{SKIP_POD_NO404S} = 1 unless exists $ENV{SKIP_POD_NO404S};

  $self->add_bundle('GitHub' => { metacpan => 1 });

  $self->add_plugins(

    # provide version
    'Git::NextVersion',

    # gather and prune
    $self->_generate_manifest_skip,
    $self->_generate_travis_yml,
    'GatherDir',
    [PruneCruft => { except => ['\.travis.yml'] }],
    'ManifestSkip',

    # this is just for github
    # TODO: still not sure this is a good idea - if metacpan.org used that on
    # the distribution homepage, I would include them on my dists...
    [PruneFiles => 'PruneRepoMetaFiles' => { match => '^(README.(pod|mm?d))$' }],

    # munge files
    [ Authority => {
        authority      => $self->authority,
        do_munging     => 1,
        do_metadata    => 1,
        locate_comment => $self->placeholder_comments,
      }
    ],
    [ NextRelease => {

        # w3cdtf
        time_zone => 'UTC',
        format    => q[%-9v %{yyyy-MM-dd'T'HH:mm:ss'Z'}d],
      }
    ],

    # We prefer OurPkgVersion, code should not jump around
    ($self->placeholder_comments ? 'OurPkgVersion' : 'PkgVersion'),

    # Weaver
    ['PodWeaver' => { config_plugin => $self->weaver_config }],

    # generated distribution files
    qw(
      License
      Readme
      ),
  );

  $self->add_plugins([AutoPrereqs => $self->config_slice({ skip_prereqs => 'skip' })])
    if $self->auto_prereqs;

  $self->add_plugins(
    [ MetaNoIndex => {

        # could use grep { -d $_ } but that will miss any generated files
        directory => [qw(corpus examples inc share t xt)],
        namespace => [qw(Local t::lib)],
        'package' => [qw(DB)],
      }
    ],
    [    # AFTER MetaNoIndex
      'MetaProvides::Package' => { meta_noindex => 1 }
    ],

    qw(
      MinimumPerl
      MetaConfig
      MetaYAML
      MetaJSON
      ),

    # Make sure we use a sane version of Test::More, always
    [ Prereqs => 'TestMoreWithSubtests' => {
        -phase       => 'test',
        -type        => 'requires',
        'Test::More' => '0.98'
      }
    ],

    # build system -- MakeMaker works for me, nuf said
    qw(
      ExecDir
      ShareDir
      MakeMaker
      ),
  );

  ## Testing
  $self->add_plugins('ReportVersions::Tiny') if $self->test_report_versions;
  $self->add_plugins('Test::Pod::No404s')    if $self->test_pod_links and !$ENV{DZIL_FIRST_RELEASE};

  if ($spelling_tests) {
    $self->add_plugins('Test::PodSpelling');
  }
  else {
    $self->log("Test::PodSpelling Plugin failed to load.  Pleese dunt mayke ani misteaks.\n");
  }

  $self->add_bundle('@TestingMania' => $self->config_slice({ disable_tests => 'disable' }));

  $self->add_plugins(

    # manifest: must come after all generated files
    'Manifest',

    # before release
    qw(
      CheckExtraTests
      CheckChangesHasContent
      TestRelease
      ConfirmRelease
      ),
  );

  # release
  my $releaser = $self->fake_release ? 'FakeRelease' : $self->releaser;
  $self->add_plugins($releaser)
    if $releaser;

  #### Git power

  ## Commit build and releases to a separate branch
  $self->add_plugins(
    [ 'Git::CommitBuild' => {
        branch  => 'build/%b',
        message => 'Build results of %h (on %b)',

        release_branch  => 'releases',
        release_message => 'Release v%v (based on %h)',
      }
    ]
  );

  ## Make sure we push all the right branches
  $self->add_bundle(
    '@Git' => { push_to => ['origin', 'origin build/master:build/master', 'origin releases:releases'] });

  $self->add_plugins([InstallRelease => { install_command => $self->install_command }])
    if $self->install_command;

  # This should be onf of the last plugins for its phase: cleanup
  # prereqs a bit
  $self->add_plugins('PrereqsClean');

  ## Cleanup workdir
  $self->add_plugins('Clean');
}


# As of Dist::Zilla 4.102345 pluginbundles don't have log and log_fatal methods
foreach my $method (qw(log log_fatal)) {
  unless (__PACKAGE__->can($method)) {
    no strict 'refs';    ## no critic (NoStrict)
    *$method =
      $method =~ /fatal/
      ? sub { die($_[1]) }
      : sub { warn("[${\$_[0]->_bundle_name}] $_[1]") };
  }
}

method _generate_manifest_skip {

  # include a default MANIFEST.SKIP for the tests and/or historical reasons
  return [
    GenerateFile => 'GenerateManifestSkip' => {
      filename    => 'MANIFEST.SKIP',
      is_template => 1,
      content     => <<'EOF_MANIFEST_SKIP',

\B\.git\b
\B\.gitignore$
^.prove/
^.proverc$
^[\._]build
^blib/
^_build/
^cover_db/
^Makefile$
\bpm_to_blib$
^MYMETA\.
^.DS_Store$

EOF_MANIFEST_SKIP
    }
  ];
}

method _generate_travis_yml {

  # include a .travis.yml: required if we want to smoke our build/* and
  # releases branches
  return [
    GenerateFile => 'GenerateTravisCfg' => {
      filename => '.travis.yml',
      content  => <<EOF_TRAVIS_CFG,
language: perl
perl:
  - "5.16"
  - "5.14"
  - "5.12"
  - "5.10"
EOF_TRAVIS_CFG
    }
  ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=for :stopwords Pedro Melo ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::PluginBundle::Author::MELO - MELO is lazy, this are his rules

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    # dist.ini
    [@Author::MELO]

=head1 DESCRIPTION

This is the way MELO is building his dists, using L<Dist::Zilla> and in
particular L<Dist::Zilla::Role::PluginBundle::Easy>.

I'm still working through all the kinks so don't expect nothing stable
until this B<warning> disappears.

This Bundle was forked from
L<Dist::Zilla::PluginBundle::Author::RWSTAUNER>.

=head1 RATIONALE

These are the facts about my code that I would like the bundle to take
advantage off, or enforce, on all my dists:

=over 4

=item I use git

This means that the release process should tag and push each new release
to my remote repositories.

=item I use Github for code and issue/bug tracking

Although I keep my code on several remote repositories, Github is the
public face for my code, and the official location of the main
repository for it.

I also like the integration between the code tools and the issue
tracker, and the new issue dashboard, so I prefer to use Github Issues
as my prefered bugtracker for all my modules.

I still track whatever is sent to RT, but I'll most likely move the
ticket over to Issues and link the two.

=item Better to test as much as possible locally before shipping

Catching a typo or a bug before shipping is much better than receiving
the FAIL CPAN Testers report, so I enable a I<lot> of Author and
Release tests.

=back

=head1 CONFIGURATION

Possible options and their default values:

    auto_prereqs         = 1  ; enable AutoPrereqs
    disable_tests        =    ; corresponds to @TestingMania.disable
    fake_release         = 0  ; if true will use FakeRelease instead of 'releaser'
    authority            = 'cpan:MELO' ; to make D::Z::P::Authority happy
    install_command      = cpanm -v -i . (passed to InstallRelease)
    placeholder_comments = 1 ; use '# VERSION' and '# AUTHORITY' comments
    releaser             = UploadToCPAN
    skip_plugins         =    ; default empty; a regexp of plugin names to exclude
    skip_prereqs         =  '^t::'  ; ignores t::* packages; corresponds to AutoPrereqs.skip
    weaver_config        = @Author::MELO
    test_pod_links       = 1  ; Pod::Links and Pod::No404s enabled
    test_perl_critic     = 0  ; No Perl::Critic by default
    test_report_versions = 0  ; No ReportVersions::Tiny by default

The C<fake_release> option also respects C<$ENV{DZIL_FAKERELEASE}>.

The C<release> option can be set to an alternate releaser plugin
or to an empty string to disable adding a releaser.
This can make it easier to include a plugin that requires configuration
by just ignoring the default releaser and including your own normally.

B<NOTE>:
This bundle consumes L<Dist::Zilla::Role::PluginBundle::Config::Slicer>
so you can also specify attributes for any of the bundled plugins.
The option should be the plugin name and the attribute separated by a dot:

    [@Author::MELO]
    AutoPrereqs.skip = Bad::Module

B<Note> that this is different than

    [@Author::MELO]
    [AutoPrereqs]
    skip = Bad::Module

which will load the plugin a second time.
The first example actually alters the plugin configuration
as it is included by the Bundle.

See L<Config::MVP::Slicer/CONFIGURATION SYNTAX> for more information.

If your situation is more complicated you can use the C<skip_plugins>
attribute to have the Bundle ignore that plugin
and then you can add it yourself:

    [MetaNoIndex]
    directory = one-dir
    directory = another-dir

    [@Author::MELO]
    skip_plugins = MetaNoIndex

=head1 EQUIVALENT F<dist.ini>

This bundle is roughly equivalent to:

  [Git::NextVersion]      ; autoincrement version from last tag

  ; choose files to include (dzil core [@Basic])
  [GatherDir]             ; everything under top dir
  [PruneCruft]            ; default stuff to skip
  [ManifestSkip]          ; custom stuff to skip
  ; use PruneFiles to specifically remove ^(dist.ini)$
  ; use PruneFiles to specifically remove ^(README.pod)$ (just for github)

  ; munge files
  [Authority]             ; inject $AUTHORITY into modules
  do_metadata = 1         ; default
  [NextRelease]           ; simplify maintenance of Changes file
  ; use W3CDTF format for release timestamps (for unambiguous dates)
  time_zone = UTC
  format    = %-9v %{yyyy-MM-dd'T'HH:mm:ss'Z'}d
  [OurPkgVersion]         ; inject $VERSION (use PkgVersion if 'placeholder_comments' == 0)
  [Prepender]             ; add header to source code files

  [PodWeaver]             ; munge POD in all modules
  config_plugin = @Author::MELO
  ; 'weaver_config' can be set to an alternate Bundle

  ; generate files
  [License]               ; generate distribution files (dzil core [@Basic])
  [Readme]

  ; metadata
  [Bugtracker]            ; include bugtracker URL and email address (uses RT)
  [Repository]            ; determine git information (if -e ".git")
  [GithubMeta]            ; overrides [Repository] if repository is on github

  [AutoPrereqs]
  ; disable with 'auto_prereqs = 0'

  [MetaNoIndex]           ; encourage CPAN not to index:
  directory = corpus
  directory = examples
  directory = inc
  directory = share
  directory = t
  directory = xt
  namespace = Local
  namespace = t::lib
  package   = DB

  [MetaProvides::Package] ; describe packages included in the dist
  meta_noindex = 1        ; ignore things excluded by above MetaNoIndex

  [MinimumPerl]           ; automatically determine Perl version required

  [MetaConfig]            ; include Dist::Zilla info in distmeta (dzil core)
  [MetaYAML]              ; include META.yml (v1.4) (dzil core [@Basic])
  [MetaJSON]              ; include META.json (v2) (more info than META.yml)

  [Prereqs / TestRequires]
  Test::More = 0.96       ; recent Test::More (including proper working subtests)

  [ExtraTests]            ; build system (dzil core [@Basic])
  [ExecDir]               ; include 'bin/*' as executables
  [ShareDir]              ; include 'share/' for File::ShareDir

  [MakeMaker]             ; create Makefile.PL

  ; generate t/ and xt/ tests
  [ReportVersions::Tiny]  ; show module versions used in test reports
  [@TestingMania]         ; *Lots* of dist tests
  [Test::PodSpelling]     ; spell check POD (if installed)

  [Manifest]              ; build MANIFEST file (dzil core [@Basic])

  ; actions for releasing the distribution (dzil core [@Basic])
  [CheckChangesHasContent]
  [TestRelease]           ; run tests before releasing
  [ConfirmRelease]        ; are you sure?
  [UploadToCPAN]
  ; see CONFIGURATION for alternate Release plugin configuration options

  [@Git]                  ; use Git bundle to commit/tag/push after releasing
  [InstallRelease]        ; install the new dist (using 'install_command')

=head1 ENVIRONMENT

We use a lot of modules and plugins and some of them can enable or
disable features based on environment variables. I've copied some of the
more useful ones to here.

=over 4



=back

= DZIL_FAKERELEASE

Enable to skip the release to CPAN as the final step of a C<< dzil release >> run.

= DZIL_FIRST_RELEASE

If true, it disables tests that will fail on a first release of a
module. One example is L<Test::Pod::No404s>, because before the first
release most of the links will not exist yet.

= SKIP_POD_LINKCHECK

Set to false to activate the L<Test::Pod::LinkCheck> module.

If not present or true, we skip it. There is no way at the moment to use
extra attributes of L<Test::Pod::LinkCheck> (to disable the remote CPAN
checks for example) via the current
L<Dist::Zilla::Plugin::Test::Pod::LinkCheck>.

= SKIP_POD_NO404S

Set to false to activate the L<Test::Pod::No404s> module.

If not present or true, we skip it. We keep getting a "This shouldn't
happen" exception inside L<Text::Wrap>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Role::PluginBundle::Easy>

=item *

L<Dist::Zilla::Role::PluginBundle::Config::Slicer>

=item *

L<Pod::Weaver>

=back

=for Pod::Coverage log log_fatal mvp_multivalue_args

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::PluginBundle::Author::MELO

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Author-MELO>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-PluginBundle-Author-MELO>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-PluginBundle-Author-MELO>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::PluginBundle::Author::MELO>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-Author-MELO>

=back

=head2 Email

You can email the author of this module at C<MELO at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at L<https://github.com/melo/Dist-Zilla-PluginBundle-Author-Melo/issues>. You will be automatically notified of any progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/melo/Dist-Zilla-PluginBundle-Author-Melo>

  git clone git://github.com/melo/Dist-Zilla-PluginBundle-Author-Melo.git

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
