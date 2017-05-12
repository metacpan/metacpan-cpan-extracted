# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use Test::DZil;
use Test::Fatal;

my $NAME = 'Author::RWSTAUNER';
my $BNAME = "\@$NAME";
my $mod = "Dist::Zilla::PluginBundle::$NAME";
eval "require $mod" or die $@;

# get default MetaNoIndex hashref
my $noindex = (
  grep { ref($_) && $_->[0] =~ 'MetaNoIndex' }
      @{ init_bundle()->plugins }
)[0]->[-1];
delete $noindex->{':version'}; # but ignore this

my $noindex_dirs = $noindex->{directory};

# test attributes that change plugin configurations
my %default_exp = (
  'Test::Compile'         => {fake_home => 1},
  PodWeaver               => {config_plugin => $BNAME},
  AutoPrereqs             => {},
  MetaNoIndex             => {%$noindex, directory => [@$noindex_dirs]},
  'MetaProvides::Package' => {meta_noindex => 1},
  Authority               => {
    authority   => $mod->_default_authority,
    do_metadata => 1, do_munging => 1, locate_comment => 0
  },
  PruneDevelCoverDatabase => { match => '^(cover_db/.+)' },
  ReadmeAnyFromPod        => { phase => 'release', location => 'root', type => 'markdown', },
  'GitHubREADME::Badge'   => { phase => 'release', badges => [qw( travis coveralls cpants )], },
  CopyFilesFromRelease    => { filename => ['LICENSE'] },
);

sub configure_ok {
  my ($config, $exp, $desc, $class) = @_;

subtest $desc => sub {
  my $checked = {};
  $exp = { %default_exp, %$exp };

  my @plugins = @{init_bundle($config, $class)->plugins};

  foreach my $plugin ( @plugins ){
    my ($moniker, $name, $payload) = @$plugin;
    my ($plugname) = ($moniker =~ m#([^/]+)$#);

    my $matched = exists $exp->{$plugname} ? $plugname : exists $exp->{$name} ? $name : next;
    if( exists $exp->{$matched} ){
      delete $payload->{':version'}; # ignore any versions in comparison
      is_deeply($payload, $exp->{$matched}, "expected configuration for $matched")
        or diag explain [$payload, $matched, $exp->{$matched}];
      ++$checked->{$matched};
    }
  }
  is_deeply { map { $_ => 1 } keys %$exp }, $checked, 'all tests ran';
};

}

configure_ok {}, {}, 'default configuration';

configure_ok
  { 'placeholder_comments' => 1, authority => 'no:body', },
  { Authority => {
      %{ $default_exp{Authority} },
      authority      => 'no:body',
      locate_comment => 1,
    }
  },
  'placeholder_comments and authority change Authority attributes';

configure_ok
  { 'PruneFiles.match' => 'fudge' },
  { map { ("Prune$_" => {match => 'fudge'}) } qw(CodeStatCollection DevelCoverDatabase) },
  'config-slice on plugin class adds attribute to each instance';

configure_ok
  { 'PruneDevelCoverDatabase.match' => 'fudge' },
  {  PruneDevelCoverDatabase => {match => 'fudge'} },
  'config-slice on plugin name affects single instance';

configure_ok
  { 'AutoPrereqs.skip'     => 'Goober'   },
  {  AutoPrereqs => { skip => 'Goober' } },
  'config-slice AutoPrereqs.skip (instead of custom attribute)';

configure_ok
  { 'MetaNoIndex.directory'  => 'goober' },
  {  MetaNoIndex => {%$noindex, directory => [@$noindex_dirs, 'goober']} },
  'config-slice MetaNoIndex.directory adds dir to list';

configure_ok
  { 'Test::Compile.fake_home' => 0 },
  { 'Test::Compile' => { fake_home => 0 } },
  'config-slice to keep from setting Test::Compile.fake_home';

configure_ok
  { 'Test::Portability.options' => 'test_one_dot=0' },
  { 'Test::Portability' => {options => 'test_one_dot=0'} },
  'config-slice Test::Portability.options';

{
  my $readmes = sub {
    my $phase = shift;
    return {
      ReadmeAnyFromPod      => { %{ $default_exp{ReadmeAnyFromPod} }, phase => $phase },
      'GitHubREADME::Badge' => { %{ $default_exp{'GitHubREADME::Badge'} }, phase => $phase },
    };
  };

  configure_ok
    {},
    $readmes->('release'),
    'readme plugins default config';

  configure_ok
    { readme_phase => 'build' },
    $readmes->('build'),
    'readme plugins changed with dist.ini';

  local $ENV{DZIL_README_PHASE} = 'build';
  configure_ok
    {},
    $readmes->('build'),
    'readme plugins changed with env';
}

configure_ok
  { 'MetaProvides::Package.meta_noindex' => 0 },
  { 'MetaProvides::Package' => {meta_noindex => 0} },
  'config-slice to disable MetaProvides::Package.meta_noindex';

configure_ok
  {
    weaver_config => '@Default',
    'MetaNoIndex.directory[]' => 'arr',
  },
  {
    PodWeaver   => { config_plugin => '@Default' },
    MetaNoIndex => { %$noindex, directory => [@$noindex_dirs, 'arr'] },
  },
  'override weaver_config and config-slice array append with bracket syntax';

configure_ok
  { copy_files => [ ' S47-19J.txt  Triplicate' ] },
  { CopyFilesFromRelease => { filename => [qw( LICENSE S47-19J.txt Triplicate )] } },
  'copy space-separated list of files';

{
  package ## no critic (Package)
    Dist::Zilla::PluginBundle::Author::TeddyTheWonderLizard;

  use Moose;
  extends $mod;

  main::configure_ok
    {},
    {
      Authority => {
        %{ $default_exp{Authority} },
        authority      => 'cpan:TeddyTheWonderLizard',
      },
      PodWeaver => { config_plugin => '@Author::TeddyTheWonderLizard' },
    },
    'authority and weaver_config set from class name',
    __PACKAGE__;
}

# test attributes that alter which plugins are included
{
  my $bundle = init_bundle({});
  my $test_name = 'expected plugins included';

  my $has_ok = sub {
    ok( has_plugin($bundle, @_), "expected plugin included: $_[0]");
  };
  my $has_not = sub {
    ok(!has_plugin($bundle, @_), "plugin expectedly not found: $_[0]");
  };
  &$has_ok('PodWeaver');
  &$has_ok('PodWeaver');
  &$has_ok('AutoPrereqs');
  &$has_ok('Test::Compile');
  &$has_ok('CheckExtraTests');
  &$has_not('FakeRelease');
  &$has_ok('UploadToCPAN');
  &$has_ok('Test::Compile');
  &$has_ok('PkgVersion');

  $bundle = init_bundle({placeholder_comments => 1});
  &$has_ok('OurPkgVersion');
  &$has_not('PkgVersion');

  $bundle = init_bundle({auto_prereqs => 0});
  &$has_not('AutoPrereqs');

  removed_attribute_ok(skip_prereqs => 'AutoPrereqs.skip');

  $bundle = init_bundle({fake_release => 1});
  &$has_ok('FakeRelease');
  &$has_not('UploadToCPAN');

  $bundle = init_bundle({is_task => 1});
  &$has_ok('TaskWeaver');
  &$has_not('PodWeaver');

  $bundle = init_bundle({releaser => 'Goober'});
  &$has_ok('Goober');
  &$has_not('UploadToCPAN');

subtest 'skip_plugins uses /x' => sub {
  $bundle = init_bundle({skip_plugins => '\b( Test::Compile | ExtraTests | GenerateManifestSkip )$'});
  &$has_not('Test::Compile');
  &$has_not('ExtraTests');
  &$has_not('GenerateManifestSkip', 1);
};

  subtest 'skip_plugins works on bundles, too' => sub {
    $bundle = init_bundle({skip_plugins => '@TestingMania'});
    &$has_not('Test::Compile');

    $bundle = init_bundle({skip_plugins => '@Blah'});
    &$has_ok('Test::Compile');
  };

  $bundle = init_bundle({'-remove' => [qw(Test::Compile ExtraTests)]});
  &$has_not('Test::Compile');
  &$has_not('ExtraTests');
  &$has_ok('Test::NoTabs');

  removed_attribute_ok(disable_tests => '-remove');

  $bundle = init_bundle({});
  &$has_ok('MakeMaker');
  &$has_not('ModuleBuild');
  &$has_not('DualBuilders');

  removed_attribute_ok(builder => '-remove');

  # We can remove the 'builder' config if it's easy to swap builders another way.
  $bundle = init_bundle({'-remove' => ['MakeMaker']});
  &$has_not('MakeMaker');

  $bundle = init_bundle({open_source => 0});
  is $bundle->releaser, '', 'no releaser if not open_source';
  &$has_not('UploadToCPAN');
  &$has_ok('Test::Compile');
  &$has_ok('Test::MinimumVersion');
  &$has_ok('PodSyntaxTests');
  &$has_not('Test::PerlCritic');
  &$has_not('CheckChangesHasContent');
  &$has_not('Test::ChangesHasContent');
  &$has_not('CheckPrereqsIndexed');
  &$has_not('AutoMetaResources');
  &$has_not('GithubMeta');
  &$has_not('ReadmeAnyFromPod');

  $bundle = init_bundle({open_source => 0, releaser => 'CatOutOfTheBag'});
  is $bundle->releaser, 'CatOutOfTheBag', 'custom releaser with open_source';
  &$has_not('UploadToCPAN');
}

# test releaser
foreach my $releaser (
  [{},                                        'UploadToCPAN'],
  [{fake_release => 1},                       'FakeRelease'],
  [{releaser => ''},                           undef],
  [{releaser => 'No_Op_Releaser'},            'No_Op_Releaser'],
  # fake_release wins
  [{releaser => 'No_Op_Releaser', fake_release => 1}, 'FakeRelease'],
){
  my ($config, $exp) = @$releaser;
  releaser_is(new_dzil($config), $exp);
  # env always overrides
  local $ENV{DZIL_FAKERELEASE} = 1;
  releaser_is(new_dzil($config), 'FakeRelease');
}

done_testing;

# helper subs
sub has_plugin {
  my ($bundle, $plug, $by_name) = @_;
  # default to plugin module, but allow searching by name
  my $index = $by_name ? 0 : 1;
  # should use List::Util::any
  scalar grep { $_->[$index] =~ /\b($plug)$/ } @{$bundle->plugins};
}
sub new_dzil {
  return Builder->from_config(
    { dist_root => 'corpus' },
    { add_files => {
        'source/dist.ini' => simple_ini([$BNAME => @_]),
      }
    },
  );
}

sub init_bundle {
  my ($payload, $class) = @_;
  $class ||= $mod;

  # compatible with non-easy bundles
  my @plugins = $class->bundle_config({name => $BNAME, payload => $payload || {}});

  # return object with ->plugins method for convenience/sanity
  my $bundle = $class->new(name => $BNAME, payload => $payload || {}, plugins => \@plugins);

  isa_ok($bundle, $class);
  return $bundle;
}

sub releaser_is {
  my ($dzil, $exp) = @_;
  my @releasers = @{ $dzil->plugins_with(-Releaser) };

  if( !defined($exp) ){
    is(scalar @releasers, 0, 'no releaser');
  }
  else {
    is(scalar @releasers, 1, 'single releaser');
    like($releasers[0]->plugin_name, qr/\b$exp$/, "expected releaser: $exp");
  }
}

sub removed_attribute_ok {
  my ($old, $new) = @_;
  like
    exception {
      init_bundle({$old => 'anything'});
    },
    qr/no longer supports '$old'.+use '$new' instead/ms,
    "attribute '$old' removed in favor of '$new'";
}
