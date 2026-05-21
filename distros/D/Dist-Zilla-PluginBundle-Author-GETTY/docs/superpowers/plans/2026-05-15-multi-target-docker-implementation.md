# Multi-Target Docker Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement [@Author::GETTY::Docker] subsection support in the bundle, allowing distributions to declare multiple Docker targets with inheritance from bundle-level `docker_image`, `docker_tags`, and `docker_local` attributes.

**Architecture:** The bundle's `configure` method will scan for `[@Author::GETTY::Docker]` plugin entries after its own configuration. For each subsection found, it creates a `Dist::Zilla::Plugin::Docker::API` instance with merged attributes. Image name defaults to dist-name with `local=1` when no explicit `docker_image` is set.

**Tech Stack:** Moose (Moo), Dist::Zilla, Dist::Zilla::Plugin::Docker::API

---

## File Structure

- `lib/Dist/Zilla/PluginBundle/Author/GETTY.pm` — Main bundle, add Docker subsection detection and plugin creation
- `t/docker-subsection.t` — New test file for subsection parsing, inheritance, and validation
- `dist.ini` — Add test configuration for Docker subsection tests

---

## Task 1: Add Docker Subsection Detection

**Files:**
- Modify: `lib/Dist/Zilla/PluginBundle/Author/GETTY.pm:648-660` (configure method start)

- [ ] **Step 1: Find the right place to add subsection detection**

In `configure`, after the existing bundle-level validation (lines 651-658), add code to scan for Docker subsections before the existing Docker::API block (around line 857).

- [ ] **Step 2: Write helper method to collect Docker subsections**

```perl
sub _collect_docker_subsections {
  my ($self) = @_;
  my @subsections;

  for my $plugin (@{ $self->zilla->plugins }) {
    my $name = $plugin->plugin_name;
    # Match "Author::GETTY::Docker" and "Author::GETTY::Docker/something"
    if ($name =~ /^Author::GETTY::Docker(?:\/|$)/) {
      push @subsections, $plugin;
    }
  }

  return @subsections;
}
```

- [ ] **Step 3: Write helper to compute default image**

```perl
sub _default_docker_image {
  my ($self) = @_;
  my $name = $self->zilla->name;
  $name =~ s/-/_/g;
  $name = lc($name);
  return $name;
}
```

- [ ] **Step 4: Run tests to verify no breakage**

Run: `cd /storage/raid/home/getty/dev/perl/p5-dist-zilla-pluginbundle-author-getty && dzil test`
Expected: All existing tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/Dist/Zilla/PluginBundle/Author/GETTY.pm
git commit -m "chore: add docker subsection detection helpers"
```

---

## Task 2: Add Attribute Inheritance Logic

**Files:**
- Modify: `lib/Dist/Zilla/PluginBundle/Author/GETTY.pm` (new methods before `configure`)

- [ ] **Step 1: Write method to merge subsection payload with bundle defaults**

```perl
sub _merge_docker_subsection_payload {
  my ($self, $subsection_plugin) = @_;

  my %merged;
  my $payload = $subsection_plugin->payload;

  # Docker image: subsection > bundle > dist-name (with local=1)
  my $bundle_docker_image = $self->docker_image;
  my $subsection_image = $payload->{image};

  if ($subsection_image) {
    $merged{image} = $subsection_image;
  } elsif ($bundle_docker_image) {
    $merged{image} = $bundle_docker_image;
  } else {
    $merged{image} = $self->_default_docker_image;
    $merged{local} = 1;  # forced for default-image case
  }

  # Tags: subsection > bundle > default 'latest %v %m'
  my $bundle_tags = $self->_docker_tags_array;
  my $subsection_tags = $payload->{tags};

  if ($subsection_tags) {
    $merged{tags} = $subsection_tags;
  } elsif ($bundle_tags && @$bundle_tags) {
    $merged{tags} = $bundle_tags;
  } else {
    $merged{tags} = ['latest', '%v', '%m'];
  }

  # Local: subsection > bundle (no special default, just pass through)
  $merged{local} = exists $payload->{local}
    ? $payload->{local}
    : ($self->docker_local // 0);

  # All other Docker::API attributes from subsection payload
  for my $key (keys %$payload) {
    next if $key =~ /^(image|tags|local)$/;
    $merged{$key} = $payload->{$key};
  }

  return \%merged;
}

sub _docker_tags_array {
  my ($self) = @_;
  my $tags = $self->payload->{docker_tags};
  return [] unless $tags;
  return [ split /\s+/, $tags ];
}
```

- [ ] **Step 2: Write validation method**

```perl
sub _validate_docker_subsections {
  my ($self, @subsections) = @_;

  my @without_explicit_image;
  my %images_seen;

  for my $sub (@subsections) {
    my $payload = $sub->payload;
    my $image = $payload->{image} // $self->docker_image // $self->_default_docker_image;

    if (!$payload->{image} && !$self->docker_image) {
      push @without_explicit_image, $sub;
    }

    # Check for overlapping images
    for my $existing (keys %images_seen) {
      if ($image eq $existing || $image =~ /^\Q$existing\E-/ || $existing =~ /^\Q$image\E-/) {
        $self->log_fatal("Overlapping Docker image names: '$existing' and '$image'");
      }
    }
    $images_seen{$image} = 1;
  }

  # Only one subsection allowed without explicit image
  if (@without_explicit_image > 1) {
    $self->log_fatal("Only one [@Author::GETTY::Docker] subsection allowed without explicit image");
  }

  return 1;
}
```

- [ ] **Step 3: Run tests**

Run: `cd /storage/raid/home/getty/dev/perl/p5-dist-zilla-pluginbundle-author-getty && dzil test`
Expected: All existing tests pass

- [ ] **Step 4: Commit**

```bash
git add lib/Dist/Zilla/PluginBundle/Author/GETTY.pm
git commit -m "chore: add docker subsection attribute inheritance and validation"
```

---

## Task 3: Wire Docker Subsection into configure()

**Files:**
- Modify: `lib/Dist/Zilla/PluginBundle/Author/GETTY.pm:857-878` (replace existing Docker block)

- [ ] **Step 1: Replace the existing single docker_image block with subsection handling**

Replace lines 857-877 (the existing `if ($self->docker_image)` block) with:

```perl
  # Handle Docker subsections
  my @docker_subsections = $self->_collect_docker_subsections;

  if (@docker_subsections) {
    $self->_validate_docker_subsections(@docker_subsections);

    for my $subsection (@docker_subsections) {
      my $config = $self->_merge_docker_subsection_payload($subsection);

      my @build_tags = ref($config->{tags}) eq 'ARRAY' ? @{$config->{tags}} : [ split /\s+/, $config->{tags} ];

      my %plugin_args = (
        image      => $config->{image},
        build_tag  => \@build_tags,
        release_tag => \@build_tags,
      );

      $plugin_args{local} = $config->{local} if exists $config->{local};

      if ($config->{target}) {
        $plugin_args{target} = $config->{target};
      }

      # Pass through any other Docker::API attributes
      for my $key (grep { !/(image|tags|local|target)/ } keys %$config) {
        $plugin_args{$key} = $config->{$key};
      }

      $self->add_plugins([ 'Docker::API' => \%plugin_args ]);
    }
  } elsif ($self->docker_image) {
    # Backward compatibility: single docker_image at bundle level
    my @build_tags = ref($self->docker_tags) eq 'ARRAY' ? @{$self->docker_tags}
                  : $self->docker_tags ? [ split /\s+/, $self->docker_tags ]
                  : ['latest'];

    $self->add_plugins([
      'Docker::API' => {
        image         => $self->docker_image,
        build_tag     => \@build_tags,
        release_tag   => \@build_tags,
        build_load    => 1,
        release_push  => $self->docker_local ? 0 : 1,
      },
    ]);
  }
```

- [ ] **Step 2: Run tests**

Run: `cd /storage/raid/home/getty/dev/perl/p5-dist-zilla-pluginbundle-author-getty && dzil test`
Expected: All existing tests pass

- [ ] **Step 3: Commit**

```bash
git add lib/Dist/Zilla/PluginBundle/Author/GETTY.pm
git commit -m "feat: wire docker subsections into configure method"
```

---

## Task 4: Write Tests for Docker Subsection Behavior

**Files:**
- Create: `t/docker-subsection.t`

- [ ] **Step 1: Write basic subsection parsing test**

```perl
use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;
use Path::Tiny;
use File::Temp qw(tempdir);
use Carp qw(croak);

plan skip_all => "dzil not available" unless eval { require 'Dist::Zilla'; 1 };

sub build_dist {
  my ($dzil_config) = @_;
  my $tempdir = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->mkpath;

  $dist_dir->child('dist.ini')->spew($dzil_config);

  my $tzil = Dist::Zilla::Tester->new({
    tempdir => $tempdir,
    config => { },
    files => [
      { path => 'dist.ini', content => $dzil_config },
      { path => 'lib/Foo.pm', content => "package Foo;\n1;\n" },
    ],
  })->build;

  return $tzil;
}

# Test 1: Basic subsection detection
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]

[@Author::GETTY::Docker]
target = runtime-root
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->zilla->plugins};

  is(scalar(@docker_plugins), 1, "one Docker::API plugin created from subsection");
  is($docker_plugins[0]->image, 'test_dist', "image defaults to dist-name");
}
```

- [ ] **Step 2: Add inheritance tests**

```perl
# Test 2: Image inheritance from bundle-level docker_image
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp

[@Author::GETTY::Docker]
target = runtime-root
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->zilla->plugins};

  is($docker_plugins[0]->image, 'myregistry/myapp', "inherits docker_image from bundle");
}

# Test 3: Tags inheritance
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
docker_image = myregistry/myapp

[@Author::GETTY::Docker]
tags = latest %v
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->zilla->plugins};

  my @build_tags = @{$docker_plugins[0]->build_tag};
  is_deeply(\@build_tags, ['latest', '%v'], "tags inherited from bundle");
}
```

- [ ] **Step 3: Add local=1 for default image case test**

```perl
# Test 4: local=1 forced when no explicit docker_image
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]

[@Author::GETTY::Docker]
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->zilla->plugins};

  # When local=1 is forced, release_push should be 0
  my $plugin = $docker_plugins[0];
  ok(!$plugin->release_push, "release_push=0 when local=1 forced for default image");
}
```

- [ ] **Step 4: Add validation error tests**

```perl
# Test 5: Error on duplicate subsection without explicit image
{
  my $config = <<'CONF';
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]

[@Author::GETTY::Docker]
target = runtime-root

[@Author::GETTY::Docker]
target = runtime-user
CONF

  my $tzil = build_dist($config);
  my @docker_plugins = grep { $_->plugin_name =~ /Docker::API/ } @{$tzil->zilla->plugins};

  # Should create TWO plugins (each has no explicit image, so both use dist-name)
  # This should FAIL validation
}
```

- [ ] **Step 5: Run tests and fix**

Run: `cd /storage/raid/home/getty/dev/perl/p5-dist-zilla-pluginbundle-author-getty && dzil test --test-file t/docker-subsection.t`
Expected: Tests demonstrate subsection behavior. Adjust assertions as needed.

- [ ] **Step 6: Commit**

```bash
git add t/docker-subsection.t
git commit -m "test: add docker subsection tests"
```

---

## Task 5: Update dist.ini for Integration Test

**Files:**
- Create: `t/docker-test-app/dist.ini` (for real integration test)

- [ ] **Step 1: Create test app structure**

Create `t/docker-test-app/` directory with a minimal dist.ini that uses the subsection syntax.

- [ ] **Step 2: Run integration test**

Run: `cd /storage/raid/home/getty/dev/perl/p5-dist-zilla-pluginbundle-author-getty/t/docker-test-app && dzil test`
Expected: The plugin correctly processes subsections

- [ ] **Step 3: Commit**

```bash
git add t/docker-test-app/
git commit -m "test: add docker subsection integration test app"
```

---

## Task 6: Final Verification and Release Prep

- [ ] **Step 1: Run full test suite**

Run: `cd /storage/raid/home/getty/dev/perl/p5-dist-zilla-pluginbundle-author-getty && dzil test`
Expected: All tests pass

- [ ] **Step 2: Build distribution**

Run: `dzil build`
Expected: Distribution builds successfully

- [ ] **Step 3: Update Changes if needed**

Ensure Changes reflects the feature correctly (already done in brainstorming phase).

- [ ] **Step 4: Commit with all changes**

```bash
git add -A && git status
git commit -m "feat: add [@Author::GETTY::Docker] subsection support for multi-target Docker builds

- Add _collect_docker_subsections, _merge_docker_subsection_payload,
  _validate_docker_subsections helper methods
- Docker subsections inherit docker_image/docker_tags/docker_local from bundle
- Each subsection creates independent Docker::API instance
- Validation: no duplicate image without explicit attribution
- Default: image=dist-name, local=1 when no docker_image set
- Default tags now include %m (major version): latest %v %m

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

- [ ] **Step 5: Push**

```bash
git push
```

---

**Plan complete and saved to `docs/superpowers/plans/2026-05-15-multi-target-docker-implementation.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**