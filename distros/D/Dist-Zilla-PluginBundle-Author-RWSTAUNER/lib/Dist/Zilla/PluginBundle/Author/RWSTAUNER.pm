# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-PluginBundle-Author-RWSTAUNER
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::RWSTAUNER;
# git description: v6.001-1-gc3c24a5

our $AUTHORITY = 'cpan:RWSTAUNER';
$Dist::Zilla::PluginBundle::Author::RWSTAUNER::VERSION = '6.002';
# ABSTRACT: RWSTAUNER's Dist::Zilla config

use Moose;
use List::Util qw(first); # core
use Moose::Util::TypeConstraints 1.01;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::Config::Slicer
  Dist::Zilla::Role::PluginBundle::PluginRemover
);
# Dist::Zilla::Role::DynamicConfig is not necessary: payload is already dynamic

# don't require it in case it won't install somewhere
my $spelling_tests = eval { require Dist::Zilla::Plugin::Test::PodSpelling; };

# cannot use $self->name for class methods
sub _bundle_name {
  my $class = @_ ? ref $_[0] || $_[0] : __PACKAGE__;
  join('', '@', ($class =~ /^.+::PluginBundle::(.+)$/));
}

sub mvp_multivalue_args { qw(
  copy_files
) }

sub _config {
  my ($self, $key, $default) = @_;
  exists $self->payload->{$key} ? $self->payload->{$key} : $default;
}

has authority => (
  is         => 'ro',
  isa        => 'Str',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(authority => $_[0]->_default_authority);
  },
);

sub _default_authority {
  (ref($_[0]) || $_[0]) =~ /Author::(\w+)/ ? 'cpan:'.$1 : undef;
}

has auto_prereqs => (
  is         => 'ro',
  isa        => 'Bool',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(auto_prereqs => 1);
  }
);

has copy_files => (
  is         => 'ro',
  isa        => 'ArrayRef[Str]',
  lazy       => 1,
  default    => sub {
    [ qw( LICENSE ),
      map { /(\S+)/g } @{ $_[0]->_config(copy_files => []) } ]
  },
);

has fake_release => (
  is         => 'ro',
  isa        => 'Bool',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(fake_release => $ENV{DZIL_FAKERELEASE});
  }
);

has install_command => (
  is         => 'ro',
  isa        => 'Str',
  lazy       => 1,
  default    => sub {
    # cpanm will choose the best place to install
    $_[0]->_config(install_command => 'cpanm -v -i .');
  }
);

has is_task => (
  is         => 'ro',
  isa        => 'Bool',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(is_task => 0);
  }
);

has max_target_perl => (
  is         => 'ro',
  isa        => 'Str',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(max_target_perl => '5.008');
  }
);

has open_source => (
  is         => 'ro',
  isa        => 'Bool',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(open_source => 1);
  }
);

has placeholder_comments => (
  is         => 'ro',
  isa        => 'Bool',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(placeholder_comments => 0);
  }
);

has releaser => (
  is         => 'ro',
  isa        => 'Str',
  lazy       => 1,
  default    => sub {
    $_[0]->_config('releaser', $_[0]->open_source ? 'UploadToCPAN' : '');
  },
);

has readme_phase => (
  is         => 'ro',
  isa        => 'Str',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(readme_phase => $ENV{DZIL_README_PHASE} || 'release');
  }
);

has skip_plugins => (
  is         => 'ro',
  isa        => 'Maybe[Regexp]',
  lazy       => 1,
  default    => sub {
    my $skip = $_[0]->_config(skip_plugins => '');
    return $skip ? qr/$skip/x : undef;
  }
);

has use_git_bundle => (
  is         => 'ro',
  isa        => 'Bool',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(use_git_bundle => 1);
  }
);

has weaver_config => (
  is         => 'ro',
  isa        => 'Str',
  lazy       => 1,
  default    => sub {
    $_[0]->_config(weaver_config => $_[0]->_bundle_name);
  }
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $attr = $class->$orig(@args);

  # removed attributes
  my %removed = (
    builder       => '-remove',
    disable_tests => '-remove',
    skip_prereqs  => 'AutoPrereqs.skip',
  );
  while( my ($old, $new) = each %removed ){
    if( exists $attr->{payload}{ $old } ){
      die "$class no longer supports '$old'.\n  Please use '$new' instead.\n";
    }
  }
  return $attr;
};

# Alter configuration after setup.
after configure => sub {
  my ($self) = @_;

  # TODO: accept this from ENV
  my $skip = $self->skip_plugins;

  my $dynamic = $self->payload;
  # sneak this config in behind @TestingMania's back
  $dynamic->{'Test::Compile.fake_home'} = 1
    unless first { /Test::Compile\W+fake_home/ } keys %$dynamic;

  my $plugins = $self->plugins;

  my $i = -1;
  while( ++$i < @$plugins ){
    my $spec = $plugins->[$i] or next;
    # NOTE: $conf retains its reference (modifications alter $spec)
    my ($name, $class, $conf) = @$spec;

    # ignore the prefix (@Bundle/Name => Name) (DZP::Name => Name)
    my ($alias)   = ($name  =~ m#([^/]+)$#);
    my ($moniker) = ($class =~ m#^(?:Dist::Zilla::Plugin(?:Bundle)?::)?(.+)$#);

    # exclude any plugins that match 'skip_plugins'
    if( $skip ){
      # match on full name or plugin class (regexp should use \b not \A)
      if( $name =~ $skip || $class =~ $skip ){
        splice(@$plugins, $i, 1);
        redo;
      }
    }
  }
  if ( $ENV{DZIL_BUNDLE_DEBUG} ) {
    eval {
      require YAML::Tiny; # dzil requires this
      $self->log( YAML::Tiny::Dump( $self->plugins ) );
    };
    warn $@ if $@;
  }
};

around add_bundle => sub {
  my ($orig, $self, $name, @args) = @_;
  return if $self->skip_plugins && $self->skip_plugins =~ $name;
  $self->$orig($name, @args);
};

# Configure plugins.
sub configure {
  my ($self) = @_;

  $self->log_fatal("you must not specify both weaver_config and is_task")
    if $self->is_task and $self->weaver_config ne $self->_bundle_name;

  $self->add_plugins(

  # provide version
    #'Git::DescribeVersion',
    'Git::NextVersion',

  # gather and prune
    $self->_generate_manifest_skip,
    [ GatherDir => { exclude_filename => [ @{ $self->copy_files } ] } ],
    qw(
      PruneCruft
      ManifestSkip
    ),
    # Devel::Cover db does not need to be packaged with distribution
    [ PruneFiles => 'PruneDevelCoverDatabase' => { match => '^(cover_db/.+)' } ],
    # Code::Stat report
    [ PruneFiles => 'PruneCodeStatCollection' => { match => '^codestat\.out' } ],
    # generated tags file... useful for development but noisy to commit
    [ PruneFiles => 'PruneTags' => { match => '^tags$' } ],

    # We could specify default binary files
    # but I can't think of any that are commonly included in dists.
    # I don't mind being explicit if the case is rare.
    #[ Encoding => 'DefaultBinaryFiles' =>
      #{ encoding => 'binary', match => '\.(?x: tar\.(gz|bz2) | sqlite | jpg )$' }],

  # munge files
    # Do PkgVersion first so other mungers don't eat the blank line after package.
    ($self->placeholder_comments ? 'OurPkgVersion' : 'PkgVersion'),
    [
      Authority => {
        ':version'     => '1.005', # accepts any non-whitespace + locate_comment
        authority      => $self->authority,
        do_munging     => 1,
        do_metadata    => 1,
        locate_comment => $self->placeholder_comments,
      }
    ],
    [
      NextRelease => {
        # w3cdtf
        time_zone => 'UTC',
        format => q[%-9V %{yyyy-MM-dd'T'HH:mm:ss'Z'}d],
      }
    ],
    'Git::Describe',
    [
      Prepender => {
        ':version' => '1.112280', # 'skip' attribute
        # don't prepend to tests
        skip => '^x?t/.+',
      }
    ],
    ( $self->is_task
      ?  'TaskWeaver'
      # TODO: detect weaver.ini and skip 'config_plugin'?
      : [ 'PodWeaver' => { config_plugin => $self->weaver_config } ]
    ),

  # generated distribution files
    qw(
      License
      Readme
    ),
  );

  $self->add_plugins(
    [
      # Generate README in repo root for github.
      ReadmeAnyFromPod => {
        ':version' => '0.142180', # 'phase'
        type       => 'markdown', # L<> to metacpan
        location   => 'root',
        phase      => $self->readme_phase,
      }
    ],
    [
      # ... and add status badges to it.
      'GitHubREADME::Badge' => {
        ':version' => '0.16', # 'phase', svg
        phase      => $self->readme_phase,
        badges     => [qw(
          travis
          coveralls
          cpants
        )],
      }
    ],
    [ CopyFilesFromRelease => { filename => [ @{ $self->copy_files } ] } ],

  # metadata
    [
      AutoMetaResources => {
        'bugtracker.rt' => 1,
        # Currently GithubMeta sets the homepage and this conflicts.
        #'homepage' => 'http://metacpan.org/release/%{dist}',
      }
    ],
    [ GithubMeta => { ':version' => '0.10' } ],
    [ 'Git::Contributors' ],
  ) if $self->open_source;

  $self->add_plugins('AutoPrereqs')
    if $self->auto_prereqs;

  $self->add_plugins(
#   [ 'MetaData::BuiltWith' => { show_uname => 1 } ], # currently DZ::Util::EmulatePhase causes problems
    [
      MetaNoIndex => {
        ':version' => 1.101130,
        # could use grep { -d $_ } but that will miss any generated files
        directory => [
          # By default skip all directories that PAUSE skips:
          't',        # skip "t" - libraries in ./t are test libraries!
          'xt',       # skip "xt" - libraries in ./xt are author test libraries!
          'inc',      # skip "inc" - libraries in ./inc are usually install libraries
          'local',    # skip "local" - somebody shipped his carton setup!
          'perl5',    # skip 'perl5" - somebody shipped her local::lib!
          'fatlib',   # skip 'fatlib' - somebody shipped their fatpack lib!
          # Also skip a few other directories commonly used for other things.
          'corpus',   # Documentation and/or test data.
          'examples', # Example
          'share',    # File::ShareDir... misc files distributed with release.
        ],
        namespace => [qw(Local t::lib)],
        'package' => [qw(DB)],
      }
    ],
    [   # AFTER MetaNoIndex
      'MetaProvides::Package' => {
        ':version'   => '1.14000001',
        meta_noindex => 1
      }
    ],

    [ MinimumPerl => { ':version' => '1.003' } ],
    qw(
      MetaConfig
      MetaYAML
      MetaJSON
    ),

# I prefer to be explicit about required versions when loading, but this is a handy example:
#    [
#      Prereqs => 'TestMoreWithSubtests' => {
#        -phase => 'test',
#        -type  => 'requires',
#        'Test::More' => '0.96'
#      }
#    ],

  # build system
    qw(
      ExecDir
      ShareDir
      MakeMaker
    ),
  );

  $self->add_plugins(
  # generated t/ tests
    [ 'Test::ReportPrereqs' => { ':version' => '0.004' } ], # include/exclude
  );

  # generated xt/ tests
    # Test::Pod::Spelling::CommonMistakes ?
      #Test::Pod::No404s # removed since it's rarely useful

  if ( $spelling_tests ) {
    $self->add_plugins('Test::PodSpelling');
  }
  else {
    $self->log("Test::PodSpelling Plugin failed to load.  Pleese dunt mayke ani misteaks.\n");
  }

  # TestingMania is primarily code/dist quality checks.
  if( $self->open_source ){
    # NOTE: A newer TestingMania might duplicate plugins if new tests are added
    $self->add_bundle('@TestingMania' => {
      ':version'      => '0.22', # max_target_perl, Test::NoTabs
      max_target_perl =>     $self->max_target_perl,
    });
  }
  # These are for your own protection.
  else {
    $self->add_plugins(
      qw(
        Test::Compile
        Test::MinimumVersion
        PodSyntaxTests
      ),
    );
  }

  $self->add_plugins(
  # manifest: must come after all generated files
    'Manifest',

  # before release
    qw(
      CheckExtraTests
    ),
  );

  $self->add_plugins(
    [ CheckChangesHasContent => { ':version' => '0.006' } ], # version-TRIAL
    qw(
      CheckMetaResources
      CheckPrereqsIndexed
    )
  ) if $self->open_source;

  $self->add_plugins(
    qw(
      TestRelease
    ),
  );

  # defaults: { tag_format => '%v', push_to => [ qw(origin) ] }
  $self->add_bundle('@Git' => {
    ':version' => '2.004', # improved changelog parsing
    allow_dirty => [
      qw(Changes README.mkdn README.pod),
      @{ $self->copy_files }
    ],
    commit_msg  => 'v%v%t%n%n%c'
  })
    if $self->use_git_bundle;

  $self->add_plugins(
    qw(
      ConfirmRelease
    ),
  );

  # release
  my $releaser = $self->fake_release ? 'FakeRelease' : $self->releaser;
  # ignore releaser if it's set to empty string
  $self->add_plugins($releaser)
    if $releaser;

  $self->add_plugins(
    [ InstallRelease => { ':version' => '0.006', install_command => $self->install_command } ]
  )
    if $self->install_command;

}

# As of Dist::Zilla 4.102345 pluginbundles don't have log and log_fatal methods
foreach my $method ( qw(log log_fatal) ){
  unless( __PACKAGE__->can($method) ){
    no strict 'refs'; ## no critic (NoStrict)
    *$method = $method =~ /fatal/
      ? sub { die($_[1]) }
      : sub { warn("[${\$_[0]->_bundle_name}] $_[1]") };
  }
}

sub _generate_manifest_skip {
  # include a default MANIFEST.SKIP for the tests and/or historical reasons
  return [
    GenerateFile => 'GenerateManifestSkip' => {
      filename => 'MANIFEST.SKIP',
      is_template => 1,
      content => <<'EOF_MANIFEST_SKIP',

\B\.git\b
\B\.gitignore$
^[\._]build
^blib/
^(Build|Makefile)$
\bpm_to_blib$
^MYMETA\.
^cover_db/

EOF_MANIFEST_SKIP
    }
  ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS RWSTAUNER's PluginBundle cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan

=head1 NAME

Dist::Zilla::PluginBundle::Author::RWSTAUNER - RWSTAUNER's Dist::Zilla config

=head1 VERSION

version 6.002

=head1 SYNOPSIS

  # dist.ini

  [@Author::RWSTAUNER]

=head1 DESCRIPTION

This is an Author
L<Dist::Zilla::PluginBundle|Dist::Zilla::Role::PluginBundle::Easy>
that I use for building my distributions.

=for Pod::Coverage configure
log log_fatal

=head1 CONFIGURATION

Possible options and their default values:

  authority      = cpan:RWSTAUNER
  auto_prereqs   = 1  ; enable AutoPrereqs
  copy_files     =    ; space-separated list of additional files to copy from build
  fake_release   = 0  ; if true will use FakeRelease instead of 'releaser'
  install_command = cpanm -v -i . (passed to InstallRelease)
  is_task        = 0  ; set to true to use TaskWeaver instead of PodWeaver
  open_source    = 1  ; include plugins for cpan/meta/repo/xt/change log, etc
  placeholder_comments = 0 ; use '# VERSION' and '# AUTHORITY' comments
  releaser       = UploadToCPAN
  skip_plugins   =    ; default empty; a regexp of plugin names to exclude
  weaver_config  = @Author::RWSTAUNER

The C<fake_release> option also respects C<$ENV{DZIL_FAKERELEASE}>.

B<NOTE>:
This bundle consumes L<Dist::Zilla::Role::PluginBundle::Config::Slicer>
so you can also specify attributes for any of the bundled plugins.
The option should be the plugin name and the attribute separated by a dot:

  [@Author::RWSTAUNER]
  AutoPrereqs.skip = Bad::Module

B<Note> that this is different than

  [@Author::RWSTAUNER]
  [AutoPrereqs]
  skip = Bad::Module

which will load the plugin a second time.
The first example actually alters the plugin configuration
as it is included by the Bundle.

See L<Config::MVP::Slicer/CONFIGURATION SYNTAX> for more information.

If your situation is more complicated you can use the C<-remove> attribute
(courtesy of L<Dist::Zilla::Role::PluginBundle::PluginRemover>)
to have the Bundle ignore that plugin
and then you can add it yourself:

  [MetaNoIndex]
  directory = one-dir
  directory = another-dir
  [@Author::RWSTAUNER]
  -remove = MetaNoIndex

C<-remove> can be specified multiple times.

Alternatively you can use the C<skip_plugins> attribute (only once)
which is a regular expression that matches plugin name or package.

  [@Author::RWSTAUNER]
  skip_plugins = MetaNoIndex|SomethingElse

=head1 ROUGHLY EQUIVALENT

This bundle is roughly equivalent to the following (generated) F<dist.ini>:

  [Git::NextVersion]

  [GenerateFile / GenerateManifestSkip]
  content     = \B\.git\b
  content     = \B\.gitignore$
  content     = ^[\._]build
  content     = ^blib/
  content     = ^(Build|Makefile)$
  content     = \bpm_to_blib$
  content     = ^MYMETA\.
  content     = ^cover_db/
  filename    = MANIFEST.SKIP
  is_template = 1

  [GatherDir]
  exclude_filename = LICENSE

  [PruneCruft]
  [ManifestSkip]

  [PruneFiles / PruneDevelCoverDatabase]
  match = ^(cover_db/.+)

  [PruneFiles / PruneCodeStatCollection]
  match = ^codestat\.out

  [PruneFiles / PruneTags]
  match = ^tags$

  [PkgVersion]

  [Authority]
  :version       = 1.005
  authority      = cpan:RWSTAUNER
  do_metadata    = 1
  do_munging     = 1
  locate_comment = 0

  [NextRelease]
  format    = %-9V %{yyyy-MM-dd'T'HH:mm:ss'Z'}d
  time_zone = UTC

  [Git::Describe]

  [Prepender]
  :version = 1.112280
  skip     = ^x?t/.+

  [PodWeaver]
  config_plugin = @Author::RWSTAUNER

  [License]
  [Readme]

  [ReadmeAnyFromPod]
  :version = 0.142180
  location = root
  phase    = release
  type     = markdown

  [GitHubREADME::Badge]
  :version = 0.16
  badges   = travis
  badges   = coveralls
  badges   = cpants
  phase    = release

  [CopyFilesFromRelease]
  filename = LICENSE

  [AutoMetaResources]
  bugtracker.rt = 1

  [GithubMeta]
  :version = 0.10

  [Git::Contributors]
  [AutoPrereqs]

  [MetaNoIndex]
  :version  = 1.10113
  directory = t
  directory = xt
  directory = inc
  directory = local
  directory = perl5
  directory = fatlib
  directory = corpus
  directory = examples
  directory = share
  namespace = Local
  namespace = t::lib
  package   = DB

  [MetaProvides::Package]
  :version     = 1.14000001
  meta_noindex = 1

  [MinimumPerl]
  :version = 1.003

  [MetaConfig]
  [MetaYAML]
  [MetaJSON]
  [ExecDir]
  [ShareDir]
  [MakeMaker]

  [Test::ReportPrereqs]
  :version = 0.004

  [Test::PodSpelling]

  [@TestingMania]
  :version        = 0.22
  max_target_perl = 5.008

  [Manifest]
  [CheckExtraTests]

  [CheckChangesHasContent]
  :version = 0.006

  [CheckMetaResources]
  [CheckPrereqsIndexed]
  [TestRelease]

  [@Git]
  :version    = 2.004
  allow_dirty = Changes
  allow_dirty = README.mkdn
  allow_dirty = README.pod
  allow_dirty = LICENSE
  commit_msg  = v%v%t%n%n%c

  [ConfirmRelease]
  [UploadToCPAN]

  [InstallRelease]
  :version        = 0.006
  install_command = cpanm -v -i .

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Role::PluginBundle::Easy>

=item *

L<Dist::Zilla::Role::PluginBundle::Config::Slicer>

=item *

L<Dist::Zilla::Role::PluginBundle::PluginRemover>

=item *

L<Pod::Weaver>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::PluginBundle::Author::RWSTAUNER

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Author-RWSTAUNER>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-pluginbundle-author-rwstauner at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-PluginBundle-Author-RWSTAUNER>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-PluginBundle-Author-RWSTAUNER>

  git clone https://github.com/rwstauner/Dist-Zilla-PluginBundle-Author-RWSTAUNER.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Sergey Romanov

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Sergey Romanov <complefor@rambler.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
