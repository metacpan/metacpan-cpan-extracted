use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);
use Carp qw(croak);

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };

sub build_dist {
  my ($dzil_config, %opts) = @_;
  my $tempdir = $opts{tempdir} // tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->mkpath;

  $dist_dir->child('dist.ini')->spew($dzil_config);
  $dist_dir->child('lib', 'Foo.pm')->parent->mkpath;
  $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n1;\n");

  my $tzil = Dist::Zilla::Tester->from_config({
    dist_root => "$dist_dir",
  }, {
    tempdir_root => $tempdir,
    chrome => Dist::Zilla::Chrome::Term->new,
  });

  return $tzil;
}

# Test 1: Basic subsection detection - single Docker subsection with target
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp

[@Author::GETTY::Docker / runtime-root]
target = runtime-root
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->plugins};

  is(scalar(@docker_plugins), 1, "one Docker::API plugin created from subsection");
  is($docker_plugins[0]->image, 'myregistry/myapp', "image inherited from bundle docker_image");
  is($docker_plugins[0]->target, 'runtime-root', "target from subsection");
}

# Test 2: Tags inheritance from bundle-level docker_tags
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp
docker_tags = latest %v

[@Author::GETTY::Docker / runtime-root]
target = runtime-root
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->plugins};

  is(scalar(@docker_plugins), 1, "one Docker::API plugin created");
  my @build_tags = @{$docker_plugins[0]->tag};
  is_deeply(\@build_tags, ['latest', '%v'], "tags inherited from bundle docker_tags");
}

# Test 3: Subsection overrides tags
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp
docker_tags = latest %v

[@Author::GETTY::Docker / runtime-root]
target = runtime-root
tags = user %v
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->plugins};

  my @build_tags = @{$docker_plugins[0]->tag};
  is_deeply(\@build_tags, ['user', '%v'], "tags overridden by subsection");
}

# Test 4: Subsection without image (neither in subsection nor in parent) must croak
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]

[@Author::GETTY::Docker / runtime-root]
target = runtime-root
CONF

  my $err;
  eval { build_dist($config); 1 } or $err = $@;
  like(
    $err // '',
    qr/needs either `image = \.\.\.` in this subsection or `docker_image = \.\.\.`/,
    "subsection without image and no parent docker_image is fatal",
  );
}

# Test 5: Explicit image in subsection
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp

[@Author::GETTY::Docker / runtime-root]
image = other-registry/otherapp
target = runtime-root
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->plugins};

  is($docker_plugins[0]->image, 'other-registry/otherapp', "image from subsection, not bundle");
}

# Test 6: Multiple subsections with different targets
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp

[@Author::GETTY::Docker / runtime-root]
target = runtime-root
tags = latest %v

[@Author::GETTY::Docker / runtime-user]
target = runtime-user
tags = user
local = 1
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->plugins};

  is(scalar(@docker_plugins), 2, "two Docker::API plugins created from subsections");

  my @sorted = sort { ($a->target // '') cmp ($b->target // '') } @docker_plugins;
  is($sorted[0]->target, 'runtime-root', "first plugin has runtime-root target");
  is($sorted[0]->image, 'myregistry/myapp', "first plugin uses bundle image");
  is($sorted[1]->target, 'runtime-user', "second plugin has runtime-user target");
  is($sorted[1]->image, 'myregistry/myapp', "second plugin inherits bundle image");
}

# Test 7: Subsections without image AND no parent docker_image must croak
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]

[@Author::GETTY::Docker / runtime-root]
target = runtime-root

[@Author::GETTY::Docker / runtime-user]
target = runtime-user
CONF

  my $err;
  eval { build_dist($config); 1 } or $err = $@;
  like(
    $err // '',
    qr/needs either `image = \.\.\.` in this subsection or `docker_image = \.\.\.`/,
    "two image-less subsections also fail with the same message",
  );
}

done_testing;