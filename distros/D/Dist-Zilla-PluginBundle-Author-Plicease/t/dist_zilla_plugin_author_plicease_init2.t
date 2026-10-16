use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use File::Spec;
use Path::Tiny qw( path tempdir );
use experimental qw( signatures );

# never talk to github, and keep any git commits from depending on the
# user's git configuration
$ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_NO_GITHUB} = 1;
$ENV{GIT_CONFIG_GLOBAL}   = File::Spec->devnull;
$ENV{GIT_CONFIG_NOSYSTEM} = 1;
$ENV{GIT_AUTHOR_NAME}     = $ENV{GIT_COMMITTER_NAME}  = 'Test User';
$ENV{GIT_AUTHOR_EMAIL}    = $ENV{GIT_COMMITTER_EMAIL} = 'test@example.com';
delete $ENV{V};

sub mint ($name, $config = {}, $responses = {})
{
  my $root = tempdir( CLEANUP => 1 );
  $root->child('config.ini')->spew_utf8('');

  my %config = (
    abstract => 'An abstract for testing',
    github   => 0,
    %$config,
  );

  $root->child('profiles/test')->mkpath;
  $root->child('profiles/test/profile.ini')->spew_utf8(
    "[Author::Plicease::Init2 / :DefaultModuleMaker]\n",
    map { "$_ = $config{$_}\n" } sort keys %config,
  );

  my $tzil = Minter->_new_from_profile(
    [ Default => 'test' ],
    { name => $name },
    { global_config_root => "$root", tempdir_root => undef },
  );

  $tzil->chrome->set_response_for($_ => $responses->{$_}) for keys %$responses;

  $tzil->mint_dist;

  my $plugin = $tzil->plugin_named(':DefaultModuleMaker');

  return ($tzil, $plugin, path($tzil->tempdir)->child('mint'));
}

subtest 'basic' => sub {

  my($tzil, $plugin, $mint) = mint('Foo-Bar');

  isa_ok $plugin, 'Dist::Zilla::Plugin::Author::Plicease::Init2';

  is $plugin->perl_version, '5.042', 'default perl version';
  is $plugin->type_dzil,  0,     'not dzil';
  is $plugin->type_alien, 0,     'not alien';
  is $plugin->type_app,   undef, 'not app';
  is $plugin->workflow, [qw( static linux )], 'default workflows';
  is $plugin->irc, undef, 'no irc';

  ok -f $mint->child($_), "has $_" for qw(
    dist.ini
    .gitattributes
    .gitignore
    .vscode/settings.json
    author.yml
    Changes
    perlcriticrc
    t/foo_bar.t
    xt/author/critic.t
    .github/workflows/static.yml
    .github/workflows/linux.yml
    lib/Foo/Bar.pm
  );

  ok !-e $mint->child($_), "does not have $_" for qw(
    alienfile
    .github/workflows/windows.yml
    .github/workflows/macos.yml
    .github/workflows/cygwin.yml
    .github/workflows/msys2-mingw.yml
  );

  my $pm = $mint->child('lib/Foo/Bar.pm')->slurp_utf8;
  note $pm;
  like $pm, qr/^package Foo::Bar;/m,                    'package';
  like $pm, qr/^use v5\.42;/m,                         'use v5.42';
  like $pm, qr/^# ABSTRACT: An abstract for testing$/m, 'abstract';

  my $ini = $mint->child('dist.ini')->slurp_utf8;
  note $ini;
  like $ini, qr/^name\s+= Foo-Bar$/m,          'name';
  like $ini, qr/^release_tests\s+= 1$/m,        'release_tests';
  like $ini, qr/^github_user\s+= uperl$/m,      'github_user';
  like $ini, qr/^default_branch\s+= main$/m,    'default_branch';
  like $ini, qr/^workflow\s+= static$/m,        'workflow static';
  like $ini, qr/^workflow\s+= linux$/m,         'workflow linux';
  unlike $ini, qr/^irc/m,                       'no irc';
  unlike $ini, qr/SetScriptShebang/,            'not an app';

  like $mint->child('t/foo_bar.t')->slurp_utf8, qr/^use Foo::Bar;/m, 'test uses module';
  like $mint->child('.gitignore')->slurp_utf8,  qr/^Foo-Bar-\*$/m,   'gitignore';

  SKIP: {
    skip 'test requires Git::Wrapper', 1 unless eval { require Git::Wrapper; 1 };
    ok -d $mint->child('.git'), 'created git repository';
  }

};

subtest 'prompts' => sub {

  my($tzil, $plugin, $mint) = mint('Foo-Bar', {}, {
    'workflow static?'       => 'n',
    'workflow windows?'      => 'y',
    'workflow msys2-mingw?'  => 'y',
    'irc?'                   => 'y',
    'github user/org'        => 'plicease',
    'Minimum required Perl (min: 5.016, old: 5.022, def: 5.042 (default), or an explicit Perl version)' => [ 'bogus', '5.36.1' ],
  });

  is $plugin->workflow, [qw( linux windows msys2-mingw )], 'workflows';
  is $plugin->irc, 'irc://irc.perl.org/#native', 'irc';
  is $plugin->perl_version, '5.036001', 'perl version';

  my $ini = $mint->child('dist.ini')->slurp_utf8;
  note $ini;
  like $ini, qr/^github_user\s+= plicease$/m, 'github_user';
  like $ini, qr/^irc\s+= irc:\/\/irc\.perl\.org\/#native$/m, 'irc';
  unlike $ini, qr/^workflow\s+= static$/m, 'no static workflow';

  ok -f $mint->child(".github/workflows/$_.yml"),  "has $_ workflow"     for qw( linux windows msys2-mingw );
  ok !-e $mint->child(".github/workflows/$_.yml"), "no $_ workflow"      for qw( static macos cygwin );

};

subtest 'perl version' => sub {

  foreach my $test (
    [ '5.008'    => 'Default.pm', qr/^use 5\.008;/m, ''                         ],
    [ '5.016'    => 'P5014.pm',   qr/^use true;/m,   ''                         ],
    [ '5.020'    => 'P5020.pm',   qr/^use experimental qw\( postderef signatures \);/m, 'postderef signatures' ],
    [ '5.026'    => 'P5020.pm',   qr/^use experimental qw\( signatures \);/m,           'signatures' ],
    [ '5.032'    => 'P5020.pm',   qr/^use experimental qw\( isa signatures \);/m,       'isa signatures' ],
    [ '5.034'    => 'P5020.pm',   qr/^use experimental qw\( isa signatures try \);/m,   'isa signatures try' ],
    [ '5.036'    => 'P5020.pm',   qr/^use experimental qw\( defer try \);/m,            'defer try' ],
    [ '5.042'    => 'P5042.pm',   qr/^use v5\.42;/m, 'defer try'                ],
  ) {
    my($version, $template, $re, $experimental) = @$test;

    subtest "$version ($template)" => sub {
      my($tzil, $plugin, $mint) = mint('Foo-Bar', { perl_version => $version });
      is $plugin->experimental, $experimental, 'experimental';
      my $pm = $mint->child('lib/Foo/Bar.pm')->slurp_utf8;
      note $pm;
      like $pm, $re, 'module content';
    };
  }

  foreach my $test (
    [ '5.30'    => '5.030'    ],
    [ '5.30.2'  => '5.030002' ],
  ) {
    my($v, $expected) = @$test;
    local $ENV{V} = $v;
    my($tzil, $plugin, $mint) = mint('Foo-Bar');
    is $plugin->perl_version, $expected, "V=$v";
  }

  foreach my $test (
    [ min   => '5.016' ],
    [ old   => '5.022' ],
    [ def   => '5.042' ],
    [ 5.024 => '5.024' ],
  ) {
    my($answer, $expected) = @$test;
    my($tzil, $plugin, $mint) = mint('Foo-Bar', {}, {
      'Minimum required Perl (min: 5.016, old: 5.022, def: 5.042 (default), or an explicit Perl version)' => $answer,
    });
    is $plugin->perl_version, $expected, "answer $answer";
  }

};

subtest 'dzil' => sub {

  my($tzil, $plugin, $mint) = mint('Dist-Zilla-Plugin-Foo');

  is $plugin->type_dzil, 1, 'is dzil';
  is $plugin->perl_version, '5.022', 'perl version';

  my $pm = $mint->child('lib/Dist/Zilla/Plugin/Foo.pm')->slurp_utf8;
  note $pm;
  like $pm, qr/^package Dist::Zilla::Plugin::Foo;/m, 'package';
  like $pm, qr/^use Moose;/m,                        'uses Moose';
  like $pm, qr/^use experimental qw\( postderef signatures \);/m, 'experimental';

  ok -f $mint->child('t/dist_zilla_plugin_foo.t'), 'has test';

};

subtest 'alien' => sub {

  my($tzil, $plugin, $mint) = mint('Alien-libfoo');

  is $plugin->type_alien, 1, 'is alien';
  ok -f $mint->child('alienfile'), 'has alienfile';

  my $pm = $mint->child('lib/Alien/libfoo.pm')->slurp_utf8;
  note $pm;
  like $pm, qr/^use base qw\( Alien::Base \);/m, 'is an Alien::Base';

  foreach my $name (qw( Alien-Build-Plugin-Foo Alien-Base-Foo Alien-Role-Foo Alien-libfoo-Bar ))
  {
    my($tzil, $plugin) = mint($name);
    is $plugin->type_alien, 0, "$name is not alien";
  }

};

subtest 'app' => sub {

  my($tzil, $plugin, $mint) = mint('App-foo');

  is $plugin->type_app, 'foo', 'is app';

  ok -f $mint->child($_), "has $_" for qw(
    bin/foo
    lib/App/foo.pm
    lib/App/foo/Command.pm
    lib/App/foo/Command/foo.pm
  );

  like $mint->child('bin/foo')->slurp_utf8,                   qr/^App::foo->run;/m,                         'bin';
  like $mint->child('lib/App/foo.pm')->slurp_utf8,            qr/^use App::Cmd::Setup -app;/m,              'app';
  like $mint->child('lib/App/foo/Command.pm')->slurp_utf8,    qr/^package App::foo::Command;/m,             'command';
  like $mint->child('lib/App/foo/Command/foo.pm')->slurp_utf8, qr/^package App::foo::Command::foo;/m,       'command impl';

  my $ini = $mint->child('dist.ini')->slurp_utf8;
  note $ini;
  like $ini, qr/^\[SetScriptShebang\]$/m, 'SetScriptShebang';
  like $ini, qr/^\[CommentOut\]$/m,       'CommentOut';

};

subtest 'include_tests = 0' => sub {

  my($tzil, $plugin, $mint) = mint('Foo-Bar', { include_tests => 0 });

  like $mint->child('dist.ini')->slurp_utf8, qr/^release_tests\s+= 0$/m, 'release_tests';

};

done_testing;
