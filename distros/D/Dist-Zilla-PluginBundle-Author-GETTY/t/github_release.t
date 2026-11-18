#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use IPC::Cmd qw(can_run);

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
plan skip_all => "Pithub not available"
  unless eval { require Pithub::Repos::Releases; require Pithub::Repos::Releases::Assets; 1 };

# The parent, GitHub::CreateRelease, creates the release published and only
# then uploads the tarball, so a failed upload leaves a release without its
# tarball that is already visible (and, with nothing marked, "latest"). The
# subclass creates a draft, uploads, and publishes only when the upload
# worked. Nothing here talks to a network: Config::Identity and Pithub are
# replaced with recorders.

my $CLASS = 'Dist::Zilla::Plugin::Author::GETTY::GitHubRelease';

# Stands in for the Binary plugin (built in a later task) without defining
# its package: only ->isa matters to make_latest.
{
  package T::FakeBinary;
  sub isa { $_[1] eq 'Dist::Zilla::Plugin::Author::GETTY::Binary' || UNIVERSAL::isa(@_) }
}

# Minimal fake of what Pithub returns: ->code and ->content.
{
  package T::Res;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub code    { $_[0]{code} }
  sub content { $_[0]{content} }
}

sub new_zilla {
  my $tempdir  = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->child('lib')->mkpath;
  $dist_dir->child('dist.ini')->spew(<<'CONF');
name = Foo
version = 1.0
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test
CONF
  $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n1;\n");
  return Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { tempdir_root => $tempdir, chrome => Dist::Zilla::Chrome::Term->new },
  );
}

my $tzil = new_zilla();

sub plugin {
  my (%args) = @_;
  require_ok_class();
  return $CLASS->new(
    plugin_name => 'GitHubRelease',
    zilla       => $tzil,
    repo        => 'foo',
    repo_owner  => 'bar',
    notes_from  => 'GitHub::CreateRelease',
    add_checksum => 0,
    %args,
  );
}

sub require_ok_class {
  (my $f = "$CLASS.pm") =~ s{::}{/}g;
  require $f;
}

# Runs $code with the identity and Pithub calls recorded in order; returns
# the call list. %code gives the status codes of asset and update.
sub with_mocks {
  my ($code, %status) = @_;
  my @calls;
  no warnings qw(redefine once);
  local *Config::Identity::load_check = sub { (login => 'bar', token => 'secret') };
  local *Pithub::Repos::Releases::create = sub {
    my ($self, %a) = @_;
    push @calls, ['create', \%a];
    return T::Res->new(code => 201, content => { id => 42 });
  };
  local *Pithub::Repos::Releases::Assets::create = sub {
    my ($self, %a) = @_;
    push @calls, ['asset', \%a];
    return T::Res->new(code => $status{asset} // 201, content => {});
  };
  local *Pithub::Repos::Releases::update = sub {
    my ($self, %a) = @_;
    push @calls, ['update', \%a];
    return T::Res->new(code => $status{update} // 200, content => {});
  };
  $code->();
  return @calls;
}

sub run_create {
  my ($plugin, %status) = @_;
  my $err;
  my @calls = with_mocks(sub {
    local $@;
    eval {
      $plugin->_create_release('v1.0', 'main', 'Version v1.0', 'the notes',
        'Foo-1.0.tar.gz', 'TARBALL-BYTES');
      1;
    } or $err = $@;
  }, %status);
  return ($err, @calls);
}

# creates_as_draft_then_publishes
{
  my ($err, @calls) = run_create(plugin());
  is $err, undef, 'creates_as_draft_then_publishes: no error';
  is_deeply [map { $_->[0] } @calls], [qw(create asset update)],
    'creates_as_draft_then_publishes: create, upload, then publish';
  is ${ $calls[0][1]{data}{draft} }, 1, 'the release is created as a draft';
  is $calls[0][1]{data}{tag_name}, 'v1.0', 'create keeps the tag';
  is $calls[0][1]{data}{target_commitish}, 'main', 'create keeps the branch';
  is $calls[0][1]{data}{name}, 'Version v1.0', 'create keeps the title';
  is $calls[0][1]{data}{body}, 'the notes', 'create keeps the notes';
  is $calls[1][1]{name}, 'Foo-1.0.tar.gz', 'the tarball is uploaded under its file name';
  is $calls[1][1]{release_id}, 42, 'the upload goes to the created release';
  is $calls[1][1]{data}, 'TARBALL-BYTES', 'the tarball content is uploaded';
  is $calls[2][1]{release_id}, 42, 'the publish goes to the created release';
  is_deeply $calls[2][1]{data}, { draft => \0, make_latest => 'true' },
    'publish un-drafts the release and marks it latest (no binaries declared)';
}

# make_latest follows the declared binaries, and can be set
{
  my $fake = bless {}, 'T::FakeBinary';
  no warnings qw(redefine once);
  local *Dist::Zilla::plugins = sub { [ $fake ] };
  my $p = plugin();
  ok !$p->make_latest, 'make_latest_false_with_binaries: default is false when a Binary plugin is present';
  my ($err, @calls) = run_create($p);
  is $err, undef, 'make_latest_false_with_binaries: no error';
  is_deeply $calls[2][1]{data}, { draft => \0, make_latest => 'false' },
    'make_latest_false_with_binaries: publish sends make_latest false';
}
{
  my $p = plugin();
  ok $p->make_latest, 'make_latest_default_true: default is true without a Binary plugin';
  my $q = plugin(make_latest => 0);
  my ($err, @calls) = run_create($q);
  is $calls[2][1]{data}{make_latest}, 'false',
    'make_latest_explicit_false: an explicit false wins over the default';
}

# failed_upload_dies_and_never_publishes
{
  my ($err, @calls) = run_create(plugin(), asset => 422);
  like $err, qr/could not attach Foo-1\.0\.tar\.gz.*draft release left in place/s,
    'failed_upload_dies_and_never_publishes: dies naming the file and the draft';
  ok !(grep { $_->[0] eq 'update' } @calls),
    'failed_upload_dies_and_never_publishes: never publishes';
}

# failed_publish_dies
{
  my ($err, @calls) = run_create(plugin(), update => 500);
  like $err, qr/could not publish the GitHub release/,
    'failed_publish_dies: dies when the publish is not answered with 200';
}

# parent_still_calls_create_release_with_six_args
{
  my $dir = tempdir(CLEANUP => 1);
  my $cwd = getcwd();
  my $tarball = path($dir, 'Foo-1.0.tar.gz');
  $tarball->spew('TARBALL-BYTES');
SKIP: {
    skip 'git binary not available', 3 unless can_run('git');
    for my $args (
      [qw(init -q)],
      ['-c','user.email=t@t.de','-c','user.name=T','commit','-q','--allow-empty','-m','init'],
      ['-c','user.email=t@t.de','-c','user.name=T','tag','-a','-m','v1.0','v1.0'],
    ) {
      system('git', '-C', $dir, @$args) == 0 or die "git @$args failed: $?";
    }
    my $p = plugin();
    my @seen;
    {
      no warnings qw(redefine once);
      no strict 'refs';
      local *{"${CLASS}::_create_release"} = sub { push @seen, [@_] };
      chdir $dir or die $!;
      my $ok = eval { $p->after_release("$tarball"); 1 };
      my $e = $@;
      chdir $cwd or die $!;
      ok $ok, 'parent_still_calls_create_release_with_six_args: after_release runs' or diag $e;
    }
    is scalar(@seen), 1, 'parent_still_calls_create_release_with_six_args: _create_release entered exactly once';
    is scalar(@{ $seen[0] || [] }) - 1, 6,
      'parent_still_calls_create_release_with_six_args: six arguments after $self';
  }
}

# bundle_uses_subclass
{
  my $tempdir  = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->child('lib')->mkpath;
  $dist_dir->child('dist.ini')->spew(<<'CONF');
name = Foo
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
no_github = 0
no_github_release = 0
CONF
  $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n# ABSTRACT: t\n1;\n");
  my $bt = Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { tempdir_root => $tempdir, chrome => Dist::Zilla::Chrome::Term->new },
  );
  my @plugins = @{ $bt->plugins };
  ok( (grep { $_->isa($CLASS) } @plugins), 'bundle_uses_subclass: the subclass is in the plugin list');
  ok(!(grep { ref($_) eq 'Dist::Zilla::Plugin::GitHub::CreateRelease' } @plugins),
    'bundle_uses_subclass: the parent is no longer used directly');
}

done_testing;
