use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use Dist::Zilla::PluginBundle::Author::Plicease;
use Dist::Zilla::Plugin::Author::Plicease;
use Path::Tiny qw( tempdir );
use File::chdir;
use experimental qw( signatures );

# the bundle inspects the current directory, so each call runs
# configure from inside a fresh dist directory named My-Dist.
sub bundle ($payload = {}, $files = { Changes => "Revision history for {{\$dist->name}}\n" })
{
  my $dir = tempdir( CLEANUP => 1 )->child('My-Dist');
  $dir->mkpath;
  foreach my $name (keys %$files)
  {
    $dir->child($name)->parent->mkpath;
    $dir->child($name)->spew_utf8($files->{$name});
  }

  local $CWD = "$dir";

  my $stderr = '';
  my @plugins;
  {
    local *STDERR;
    open STDERR, '>', \$stderr or die "unable to redirect STDERR: $!";
    @plugins = Dist::Zilla::PluginBundle::Author::Plicease->bundle_config({
      name    => '@Author::Plicease',
      package => 'Dist::Zilla::PluginBundle::Author::Plicease',
      payload => $payload,
    });
  }

  note $stderr if $stderr;

  return (\@plugins, $stderr);
}

sub names ($plugins)
{
  [ map { $_->[0] =~ s{^\@Author::Plicease/}{}r } @$plugins ];
}

sub plugin ($plugins, $name)
{
  my @found = grep { $_->[0] eq "\@Author::Plicease/$name" } @$plugins;
  return undef unless @found;
  return $found[0];
}

sub args ($plugins, $name)
{
  my $plugin = plugin($plugins, $name);
  return $plugin ? $plugin->[2] : undef;
}

my $git = Dist::Zilla::Plugin::Author::Plicease->git;
my $archive = eval { require Dist::Zilla::Plugin::Libarchive; Dist::Zilla::Plugin::Libarchive->VERSION('0.03'); 1 }
  ? 'Libarchive'
  : 'ArchiveTar';

subtest 'defaults' => sub {

  my($plugins, $stderr) = bundle();

  is $stderr, '', 'no warnings';

  is(
    names($plugins),
    [
      qw( GatherDir PruneCruft ManifestSkip MetaYAML License ExecDir ShareDir ),
      'Author::Plicease::MakeMaker',
      qw( Manifest TestRelease PodWeaver NextRelease AutoPrereqs OurPkgVersion MetaJSON ),
      ($git ? qw( Git::Check Git::Commit Git::Tag Git::Push ) : ()),
      qw( MetaResources InstallGuide MinimumPerl ),
      'Author::Plicease::SpecialPrereqs',
      'ConfirmRelease',
      'Author::Plicease::ReadmeAnyFromPod',
      'ReadMePodInRoot',
      'Author::Plicease::NoUnsafeInc',
      $archive,
      'Author::Plicease::Cleaner',
    ],
    'plugin list',
  );

  is(
    plugin($plugins, 'Author::Plicease::MakeMaker')->[1],
    'Dist::Zilla::Plugin::Author::Plicease::MakeMaker',
    'default installer class',
  );

  is(
    args($plugins, 'GatherDir'),
    {
      exclude_filename => [qw( Makefile.PL Build.PL xt/release/changes.t xt/release/fixme.t )],
      exclude_match    => '^_build/',
    },
    'GatherDir',
  );

  is(
    args($plugins, 'NextRelease'),
    { format => '%-9v %{yyyy-MM-dd HH:mm:ss Z}d' },
    'NextRelease',
  );

  is(
    args($plugins, 'OurPkgVersion'),
    { underscore_eval_version => 1, no_critic => 1 },
    'OurPkgVersion',
  );

  is(
    args($plugins, 'MetaResources'),
    {
      'homepage'        => 'https://metacpan.org/pod/My::Dist',
      'bugtracker.web'  => 'https://github.com/plicease/My-Dist/issues',
      'repository.url'  => 'https://github.com/plicease/My-Dist.git',
      'repository.web'  => 'https://github.com/plicease/My-Dist',
      'repository.type' => 'git',
    },
    'MetaResources',
  );

  is args($plugins, 'MinimumPerl'), {}, 'MinimumPerl';
  is args($plugins, 'Author::Plicease::SpecialPrereqs'), {}, 'SpecialPrereqs';
  is args($plugins, 'Author::Plicease::Cleaner'), {}, 'Cleaner';

  is(
    args($plugins, 'Author::Plicease::ReadmeAnyFromPod'),
    { type => 'text', filename => 'README', location => 'build' },
    'README',
  );

  is(
    plugin($plugins, 'ReadMePodInRoot'),
    [
      '@Author::Plicease/ReadMePodInRoot',
      'Dist::Zilla::Plugin::Author::Plicease::ReadmeAnyFromPod',
      { type => 'gfm', filename => 'README.md', location => 'root' },
    ],
    'README.md',
  );

  if($git)
  {
    is args($plugins, 'Git::Check')->{allow_dirty},  [qw( dist.ini Changes README.md )], 'Git::Check allow_dirty';
    is args($plugins, 'Git::Commit')->{allow_dirty}, [qw( dist.ini Changes README.md )], 'Git::Commit allow_dirty';
    is args($plugins, 'Git::Tag'),  {}, 'Git::Tag';
    is args($plugins, 'Git::Push'), {}, 'Git::Push';
  }

};

subtest 'MetaResources overrides' => sub {

  my($plugins) = bundle({
    'bugtracker.web'  => 'https://example.com/issues',
    'repository.url'  => 'https://example.com/repo.git',
    'repository.web'  => 'https://example.com/repo',
    'repository.type' => 'hg',
  });

  is(
    args($plugins, 'MetaResources'),
    hash {
      field 'bugtracker.web'  => 'https://example.com/issues';
      field 'repository.url'  => 'https://example.com/repo.git';
      field 'repository.web'  => 'https://example.com/repo';
      field 'repository.type' => 'hg';
      etc;
    },
    'each override is used for its own key',
  );

};

subtest 'github / irc / homepage' => sub {

  my($plugins) = bundle({
    github_user => 'PerlFFI',
    github_repo => 'Other-Repo',
    irc         => 'irc://irc.perl.org/#native',
    homepage    => 'https://example.com',
    default_branch => 'main',
    workflow    => [qw( static linux )],
  });

  is(
    args($plugins, 'MetaResources'),
    {
      'homepage'        => 'https://example.com',
      'bugtracker.web'  => 'https://github.com/PerlFFI/Other-Repo/issues',
      'repository.url'  => 'https://github.com/PerlFFI/Other-Repo.git',
      'repository.web'  => 'https://github.com/PerlFFI/Other-Repo',
      'repository.type' => 'git',
      'x_IRC'           => 'irc://irc.perl.org/#native',
      'x_twitter'       => 'https://fosstodon.org/@PerlFFI',
    },
    'MetaResources',
  );

  is(
    args($plugins, 'ReadMePodInRoot'),
    {
      type           => 'gfm',
      filename       => 'README.md',
      location       => 'root',
      default_branch => 'main',
      github_user    => 'PerlFFI',
      github_repo    => 'Other-Repo',
      workflow       => [qw( static linux )],
    },
    'README.md',
  );

  is(
    args($plugins, 'Author::Plicease::ReadmeAnyFromPod'),
    { type => 'text', filename => 'README', location => 'build', default_branch => 'main' },
    'README',
  );

};

subtest 'release_tests' => sub {

  my($plugins) = bundle({
    release_tests => 1,
    diag          => [ '+Foo::Bar' ],
    diag_preamble => [ '| 1;' ],
    test2_v0      => 1,
  });

  is(
    plugin($plugins, 'Author::Plicease::Tests'),
    [
      '@Author::Plicease/Author::Plicease::Tests',
      'Dist::Zilla::Plugin::Author::Plicease::Tests',
      {
        diag          => [ '+Foo::Bar' ],
        diag_preamble => [ '| 1;' ],
        test2_v0      => 1,
      },
    ],
    'Tests plugin',
  );

  my $names = names($plugins);
  my($tests_index)   = grep { $names->[$_] eq 'Author::Plicease::Tests' } 0..$#$names;
  my($resource_index) = grep { $names->[$_] eq 'MetaResources' } 0..$#$names;
  is $tests_index, $resource_index+1, 'Tests comes after MetaResources';

};

subtest 'installer' => sub {

  subtest 'custom' => sub {
    my($plugins) = bundle({ installer => 'ModuleBuildTiny' });
    ok plugin($plugins, 'ModuleBuildTiny'), 'has ModuleBuildTiny';
    ok !plugin($plugins, 'Author::Plicease::MakeMaker'), 'no MakeMaker';
  };

  subtest 'ModuleBuild' => sub {
    my($plugins, $stderr) = bundle({ installer => 'ModuleBuild', mb_class => 'Foo::MB', mb_version => '0.42' });
    is args($plugins, 'ModuleBuild'), { mb_class => 'Foo::MB', mb_version => '0.42' }, 'mb_ args passed';
    like $stderr, qr/please migrate off of Module::Build/, 'warning';
  };

  subtest 'inc/My/ModuleBuild.pm' => sub {
    my($plugins, $stderr) = bundle({}, {
      Changes                 => "",
      'inc/My/ModuleBuild.pm' => "package My::ModuleBuild;\n1;\n",
    });
    is args($plugins, 'ModuleBuild'), { mb_class => 'My::ModuleBuild' }, 'ModuleBuild with mb_class';
    ok !plugin($plugins, 'Author::Plicease::MakeMaker'), 'no MakeMaker';
    like $stderr, qr/please migrate off of Module::Build/, 'warning';
  };

  subtest 'Alien' => sub {
    like dies { bundle({ installer => 'Alien' }) }, qr/\[Alien\] no longer supported as an installer/, 'dies';
  };

};

subtest 'unsupported keys' => sub {

  foreach my $key (qw( travis_status travis_com travis_base travis_image_base appveyor travis_user appveyor_user ))
  {
    like dies { bundle({ $key => 1 }) }, qr/no longer supports: $key$/, "$key dies";
  }

  like dies { bundle({ travis_user => 1, appveyor => 1 }) }, qr/no longer supports: appveyor travis_user$/, "multiple keys";

};

subtest 'version_plugin' => sub {

  my($plugins) = bundle({ version_plugin => 'PkgVersion::Block' });
  ok plugin($plugins, 'PkgVersion::Block'), 'has PkgVersion::Block';
  ok !plugin($plugins, 'OurPkgVersion'), 'no OurPkgVersion';

  ($plugins) = bundle({ underscore_eval_version => 0 });
  is args($plugins, 'OurPkgVersion'), { underscore_eval_version => 0, no_critic => 1 }, 'underscore_eval_version';

};

subtest 'prereq options' => sub {

  my($plugins) = bundle({
    perl     => '5.020',
    upgrade  => [ 'Foo::Bar = 1.00' ],
    preamble => [ '| 1;' ],
    win32    => 0,
  });

  is args($plugins, 'MinimumPerl'), { perl => '5.020' }, 'MinimumPerl';
  is(
    args($plugins, 'Author::Plicease::SpecialPrereqs'),
    { upgrade => [ 'Foo::Bar = 1.00' ], preamble => [ '| 1;' ], win32 => 0 },
    'SpecialPrereqs',
  );

};

subtest 'no_readme' => sub {

  my($plugins) = bundle({ no_readme => 1 });
  ok !plugin($plugins, 'Author::Plicease::ReadmeAnyFromPod'), 'no README';
  ok !plugin($plugins, 'ReadMePodInRoot'), 'no README.md';

};

subtest 'readme_from' => sub {

  my($plugins) = bundle({ readme_from => 'lib/Foo.pod' });
  is args($plugins, 'Author::Plicease::ReadmeAnyFromPod')->{source_filename}, 'lib/Foo.pod', 'README';
  is args($plugins, 'ReadMePodInRoot')->{source_filename}, 'lib/Foo.pod', 'README.md';

};

subtest 'copy_mm / copy_mb' => sub {

  my($plugins) = bundle({ copy_mm => 1 });
  is args($plugins, 'CopyFilesFromBuild'), { copy => [ 'Makefile.PL' ] }, 'copy_mm';

  ($plugins) = bundle({ copy_mb => 1 });
  is args($plugins, 'CopyFilesFromBuild'), { copy => [ 'Build.PL' ] }, 'copy_mb';

};

subtest 'allow_dirty' => sub {

  skip_all 'test requires git and Dist::Zilla::Plugin::Git' unless $git;

  my($plugins) = bundle({ allow_dirty => [ 'foo.txt' ] });
  is args($plugins, 'Git::Check')->{allow_dirty},  [qw( dist.ini Changes README.md foo.txt )], 'Git::Check';
  is args($plugins, 'Git::Commit')->{allow_dirty}, [qw( dist.ini Changes README.md foo.txt )], 'Git::Commit';

};

subtest 'clean' => sub {

  my($plugins) = bundle({ clean => [ '*.o' ], clean_keep => [ 'foo' ] });
  is args($plugins, 'Author::Plicease::Cleaner'), { clean => [ '*.o' ], clean_keep => [ 'foo' ] }, 'Cleaner';

};

subtest 'clean / clean_keep multiple values from dist.ini' => sub {

  # bundle_config above skips the dist.ini parsing, which is where
  # multi-value options are handled, so load a real dist.ini here.
  my $tzil;
  {
    local *STDERR;
    open STDERR, '>', \my $stderr or die "unable to redirect STDERR: $!";
    $tzil = Builder->from_config(
      { dist_root => 'corpus/DZT' },
      {
        tempdir_root => undef,
        add_files    => {
          'source/dist.ini' => simple_ini(
            {},
            [ '@Author::Plicease' => {
              clean      => [ '*.o', '/roger' ],
              clean_keep => [ '^corpus', '^share' ],
            } ],
          ),
        },
      },
    );
  }

  my($cleaner) = grep { $_->isa('Dist::Zilla::Plugin::Author::Plicease::Cleaner') } $tzil->plugins->@*;
  is $cleaner->clean,      [ '*.o', '/roger' ],     'clean';
  is $cleaner->clean_keep, [ '^corpus', '^share' ], 'clean_keep';

};

subtest 'run scripts' => sub {

  subtest 'maint/run-' => sub {
    my($plugins, $stderr) = bundle({}, {
      Changes => '',
      map { ("maint/run-$_.pl" => "1;\n") } qw( before_build before_release release test after_build after_release ),
    });

    is $stderr, '', 'no warnings';

    is args($plugins, 'Run::BeforeBuild'),   { run => '%x maint/run-before_build.pl     --name %n --version %v' }, 'Run::BeforeBuild';
    is args($plugins, 'Run::AfterBuild'),    { run => '%x maint/run-after_build.pl      --name %n --version %v --dir %d' }, 'Run::AfterBuild';
    is args($plugins, 'Run::AfterRelease'),  { run => '%x maint/run-after_release.pl    --name %n --version %v --dir %d --archive %a' }, 'Run::AfterRelease';
    ok plugin($plugins, $_), "has $_" for qw( Run::BeforeRelease Run::Release Run::Test );
  };

  subtest 'inc/run/' => sub {
    my($plugins, $stderr) = bundle({}, {
      Changes                   => '',
      'inc/run/before_build.pl' => "1;\n",
    });

    like $stderr, qr{please rename inc/run/before_build\.pl to maint/run-before_build\.pl}, 'rename warning';
    is args($plugins, 'Run::BeforeBuild'), { run => '%x inc/run/before_build.pl     --name %n --version %v' }, 'Run::BeforeBuild';
  };

};

subtest 'warnings' => sub {

  subtest 'no Changes' => sub {
    my(undef, $stderr) = bundle({}, {});
    like $stderr, qr/no Changes file/, 'warning';
  };

  subtest 'Changes with extra }' => sub {
    my(undef, $stderr) = bundle({}, { Changes => "{{\$NEXT}}}\n" });
    like $stderr, qr/Please fix extra \} in Changes template/, 'warning';
  };

  subtest 'Test2::V0 without -no_srand' => sub {
    my(undef, $stderr) = bundle({}, {
      Changes     => '',
      't/bad.t'   => 'use ' . "Test2::V0;\n",
      't/good.t'  => "use Test2::V0 -no_srand => 1;\n",
    });
    like   $stderr, qr{t/bad\.t has Test2::V0 without -no_srand}, 'warning for bad.t';
    unlike $stderr, qr{t/good\.t},                                'no warning for good.t';
  };

};

done_testing;
