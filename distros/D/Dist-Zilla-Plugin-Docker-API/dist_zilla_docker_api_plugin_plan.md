# Implementation Plan: Dist::Zilla Docker Image Plugin using API::Docker

## Working name

Recommended CPAN distribution name:

```text
Dist-Zilla-Plugin-Docker-API
```

Recommended plugin namespace:

```text
Dist::Zilla::Plugin::Docker::API
```

Alternative if the module is specifically build-focused:

```text
Dist::Zilla::Plugin::Docker::Image
Dist::Zilla::Plugin::Docker::Build
```

My recommendation is `Docker::API` for the first public version because the important differentiator is not “can run Docker”, but “uses the Docker Engine API directly instead of shelling out to docker”.

---

## Core design principle

The plugin should treat a Docker image as a release artifact derived from the Dist::Zilla-built distribution, not as an arbitrary side-effect of the source checkout.

Default behavior should therefore be:

```text
Docker build context = Dist::Zilla build_root
```

That means the image is built from the files that Dist::Zilla actually generated: munged modules, generated Makefile.PL/Build.PL, generated META files, generated README, injected files, pruned files already removed, and so on.

The source checkout should still be supported as an explicit mode, but not as the default.

---

## Primary user story

The author wants this in `dist.ini`:

```ini
[Docker::API / local]
phase      = build
repository = ghcr.io/example/my-app
context    = build
file       = Dockerfile

tag = latest
tag = build-%v
tag = build-%g

push = 0
load = 1
```

And this for release:

```ini
[Docker::API / release]
phase      = release
repository = ghcr.io/example/my-app
context    = archive
file       = Dockerfile

tag = %v
tag = v%v
tag = latest

push = 1
load = 0
fail_if_tag_exists = 1
skip_latest_on_trial = 1
```

This gives two intentionally separate images policies:

```text
dzil build   -> local/dev image tags
dzil release -> versioned published image tags
```

---

## Why API::Docker makes sense

Using `API::Docker` is the right architecture for this plugin because:

1. The plugin can stay inside Perl and Dist::Zilla’s logging/error model.
2. No dependency on the Docker CLI binary.
3. No shell quoting bugs around tags, build args, paths, auth headers, labels, and contexts.
4. Easier unit tests with a fake Docker client.
5. Easier future support for remote Docker daemons over TCP or Unix sockets.
6. Structured Docker progress events can be parsed and rendered cleanly.
7. Build errors can become `log_fatal` with useful context instead of opaque command exit codes.

The plugin should not directly embed HTTP request logic. It should call a small adapter around `API::Docker`, so the plugin remains testable even if the Docker API client changes names or method shapes.

---

## High-level architecture

```text
Dist::Zilla::Plugin::Docker::API
  does Dist::Zilla::Role::Plugin
  does Dist::Zilla::Role::AfterBuild
  does Dist::Zilla::Role::BeforeRelease
  does Dist::Zilla::Role::Releaser
  does Dist::Zilla::Role::AfterRelease

Dist::Zilla::Plugin::Docker::API::Config
Dist::Zilla::Plugin::Docker::API::TagTemplate
Dist::Zilla::Plugin::Docker::API::Context
Dist::Zilla::Plugin::Docker::API::Client
Dist::Zilla::Plugin::Docker::API::Progress
Dist::Zilla::Plugin::Docker::API::Registry
Dist::Zilla::Plugin::Docker::API::Result
```

However, for maintainability I would implement the internals as role-like helper classes, not as one giant plugin file.

---

## Recommended object responsibilities

### `Dist::Zilla::Plugin::Docker::API`

Main Dist::Zilla plugin.

Responsibilities:

- Parse config.
- Decide whether this plugin instance should run in the current phase.
- Resolve tag templates.
- Resolve build context.
- Create Docker client adapter.
- Call preflight, build, tag, push.
- Report results through Dist::Zilla logger.

### `...::Config`

Normalized immutable config object.

Should contain:

```perl
repository
phase
context
file
tags
build_args
labels
platforms
push
load
pull
no_cache
rm
force_rm
target
network_mode
fail_if_tag_exists
skip_latest_on_trial
allow_dirty
registry_auth_stash
client_class
```

### `...::TagTemplate`

Template expansion.

Suggested variables:

```text
%n  Dist name, e.g. My-App
%v  Dist version
%t  Trial suffix, e.g. -TRIAL or empty
%g  short git SHA if available
%G  full git SHA if available
%b  git branch if available
%d  Dist::Zilla build root
%o  source/root directory
%a  release archive path if available
%p  plugin name
```

Suggested helper behavior:

```text
repository = ghcr.io/example/my-app
tag = %v
=> ghcr.io/example/my-app:1.23
```

If `tag` already contains a slash and colon and looks like a full image reference, allow it.

### `...::Context`

Build context resolver.

Supported modes:

```text
build    -> tar stream of build_root
source   -> tar stream of zilla root
archive  -> release tarball
path:X   -> explicit local path
```

Default should be:

```text
context = build
```

For release builds, recommended:

```text
context = archive
```

because that proves the image came from the exact release artifact.

### `...::Client`

Thin adapter around `API::Docker`.

The plugin should only call methods on this adapter, never raw Docker HTTP.

Expected adapter surface:

```perl
my $client = Dist::Zilla::Plugin::Docker::API::Client->new(
  docker => API::Docker->new(...),
  logger => $self->log,
);

my $result = $client->build_image(
  context_tar => $tar_fh_or_scalar,
  dockerfile  => $file,
  tags        => \@image_refs,
  labels      => \%labels,
  buildargs   => \%build_args,
  platform    => $platform,
  target      => $target,
  pull        => $pull,
  nocache     => $no_cache,
  rm          => $rm,
  forcerm     => $force_rm,
);

$client->tag_image(
  source => $image_id_or_ref,
  target => $image_ref,
);

$client->push_image(
  image_ref => $image_ref,
  auth      => $auth,
);

$client->inspect_image($image_ref);
$client->image_exists_locally($image_ref);
$client->remote_tag_exists($image_ref); # optional registry helper
```

### `...::Progress`

Docker build/push endpoints return streaming progress records. The plugin should parse these and forward:

```text
stream/status/progress -> log_debug or log
errorDetail/error      -> log_fatal
aux.ID                 -> captured image ID
```

Important: do not treat HTTP 200 alone as success. Docker build/push can return a successful HTTP response while the stream contains an error event. The adapter must parse the stream completely.

### `...::Registry`

Optional helper for remote tag preflight.

Responsibilities:

- Parse image reference into registry/repository/tag.
- Check whether a tag already exists.
- Provide auth headers if needed.
- Support `fail_if_tag_exists`.

First version can make this feature optional or best-effort. Local Docker Engine push can work without implementing full Registry API checks.

---

## Dist::Zilla phase mapping

### `phase = build`

Implemented via `AfterBuild`.

Runs after Dist::Zilla has written the generated distribution files into `build_root`.

Behavior:

```text
- resolve context from build_root by default
- build image
- tag using build tags
- do not push by default
- load/store locally by default if the Docker backend supports it
```

Default tags for build mode:

```ini
tag = latest
tag = build-%v
```

### `phase = release`

Implemented via release workflow roles.

Recommended split:

```text
BeforeRelease -> preflight only
Releaser      -> build + push image artifact
AfterRelease  -> summary/logging only
```

Behavior:

```text
- verify Docker daemon available
- verify auth if push enabled
- verify release tags are allowed
- verify tags do not already exist if configured
- build from archive or build_root
- push version tags
- optionally push latest only for stable releases
- emit digest/image-id summary
```

Default tags for release mode:

```ini
tag = %v
tag = v%v
```

`latest` should never be implicit for release. It should require explicit config.

### `phase = after_release`

Optional.

Use this only for post-release work, such as:

```text
- write docker-release.json
- print digest summary
- create provenance/SBOM later
- cleanup temp build context
```

---

## Avoiding duplicate builds during `dzil release`

`dzil release` performs a build internally. Therefore a naive `AfterBuild` plugin can accidentally run during both plain build and release build.

The plugin must prevent this.

Recommended policy:

```text
An instance with phase=build runs only for explicit build/test-like commands.
An instance with phase=release runs only during release.
```

Implementation detail:

- If Dist::Zilla exposes a release-state flag, use it.
- If not, mirror the technique used by phase-aware plugins such as Run.
- Worst-case, provide a user-facing escape hatch:

```ini
run_if_release = 0
run_no_release = 1
```

But the public API should prefer:

```ini
phase = build
phase = release
```

not low-level booleans.

---

## Config schema v0.001

Minimum useful config:

```ini
[Docker::API]
repository = ghcr.io/example/my-app
tag = latest
```

Expanded config:

```ini
[Docker::API / local]
phase = build
repository = ghcr.io/example/my-app
context = build
file = Dockerfile

tag = latest
tag = build-%v
tag = sha-%g

build_arg = DIST_NAME=%n
build_arg = DIST_VERSION=%v
build_arg = RELEASE_STATUS=%r

label = org.opencontainers.image.title=%n
label = org.opencontainers.image.version=%v
label = org.opencontainers.image.revision=%G

push = 0
load = 1
pull = 1
no_cache = 0
rm = 1
force_rm = 1
```

Release config:

```ini
[Docker::API / release]
phase = release
repository = ghcr.io/example/my-app
context = archive
file = Dockerfile

tag = %v
tag = v%v
tag = latest

push = 1
load = 0
fail_if_tag_exists = 1
skip_latest_on_trial = 1
```

---

## Tag policy

Rules:

1. `tag` is repeatable.
2. Tags are templates.
3. Tags are normalized into full image refs.
4. `latest` is never added implicitly.
5. Trial releases must not update `latest` unless explicitly forced.
6. Release tags should be immutable by default.
7. Build tags may be mutable by default.

Recommended defaults:

```text
phase=build:
  push = 0
  tag  = latest

phase=release:
  push = 1
  tag  = %v
  fail_if_tag_exists = 1
  skip_latest_on_trial = 1
```

Tag examples:

```ini
tag = %v                    ; 1.234
tag = v%v                   ; v1.234
tag = latest                ; latest
tag = trial-%v              ; trial-1.234-TRIAL
tag = build-%v              ; build-1.234
tag = sha-%g                ; sha-a1b2c3d
```

---

## Context policy

### `context = build`

Best default. Builds from Dist::Zilla-generated tree.

Pros:

- Matches generated distribution.
- Includes generated files.
- Excludes pruned source files.
- Good for local build and smoke testing.

Cons:

- Not necessarily byte-identical to release archive if archive plugins mutate after build.

### `context = archive`

Best for release.

Pros:

- Image is derived from the exact release artifact.
- Strong reproducibility story.
- Easy to explain.

Cons:

- Dockerfile must be present inside the archive, or plugin must create a temporary context that includes both archive contents and Dockerfile.

### `context = source`

Escape hatch.

Pros:

- Allows app-style Dockerfiles that depend on repo files not shipped to CPAN.

Cons:

- Can accidentally build unreleased files.
- Can include `.git`, local cruft, unpruned files.

Should require explicit opt-in.

---

## Dockerfile handling

Default:

```ini
file = Dockerfile
```

Resolution rules:

1. If `context=build`, Dockerfile is expected in build_root.
2. If `context=archive`, Dockerfile is expected in archive contents.
3. If Dockerfile is outside the chosen context, plugin can either:
   - fail with a clear message, or
   - create a synthetic temp context that injects the Dockerfile.

For v0.001, fail clearly. Add synthetic context later.

Suggested error:

```text
Dockerfile 'Dockerfile' is not present in Docker build context 'archive'.
Either include it in the distribution or set context=source.
```

---

## API::Docker integration details

The plugin should depend on an adapter, not the raw client directly.

Example:

```perl
package Dist::Zilla::Plugin::Docker::API::Client;

use Moose;

has docker => (
  is       => 'ro',
  required => 1,
);

sub build_image {
  my ($self, %arg) = @_;

  # Adapter maps normalized plugin args to API::Docker method calls.
  # It must consume the full streaming response and return a Result object.
}

sub push_image {
  my ($self, %arg) = @_;

  # Must consume the whole push stream and detect errorDetail.
}

sub tag_image {
  my ($self, %arg) = @_;
}

1;
```

The adapter allows tests like:

```perl
my $fake = t::lib::FakeDockerClient->new;
my $zilla = Builder->from_config(... client_class => ref $fake ...);
```

---

## Result object

```perl
package Dist::Zilla::Plugin::Docker::API::Result;

use Moose;

has image_id => (is => 'ro');
has tags     => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] });
has pushed   => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] });
has digest   => (is => 'ro');
has warnings => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] });

1;
```

`AfterRelease` can print this as:

```text
Docker image built: sha256:...
Tagged: ghcr.io/example/my-app:1.234, ghcr.io/example/my-app:v1.234
Pushed: ghcr.io/example/my-app:1.234
Digest: ghcr.io/example/my-app@sha256:...
```

---

## Error model

Use Dist::Zilla logging, not `die` directly except through `log_fatal`.

Fatal errors:

```text
- Docker daemon unavailable
- Dockerfile missing
- context cannot be packed
- tag template expands to invalid ref
- release tag already exists and fail_if_tag_exists=1
- trial release would update latest and skip_latest_on_trial=0 not set
- build stream contains errorDetail
- push stream contains errorDetail
```

Warnings:

```text
- context=source used during release
- latest used during release
- git SHA unavailable but %g used
- remote tag existence check unsupported for selected registry
```

---

## Authentication strategy

Support three layers:

### 1. Let Docker daemon use existing auth

Default for v0.001.

```ini
push = 1
```

No explicit credentials. The Docker daemon/client auth config handles registry credentials.

### 2. Dist::Zilla stash

Later:

```ini
registry_auth = %DockerHub
```

or:

```ini
registry_auth_stash = DockerHub
```

### 3. Environment

```text
DOCKER_USERNAME
DOCKER_PASSWORD
DOCKER_REGISTRY
DOCKER_AUTH_CONFIG
```

This is useful for CI.

---

## Preflight checks

Before release, run:

```text
- can connect to Docker daemon
- Docker API version is usable
- selected Dockerfile exists in selected context
- at least one release tag exists
- no release tag already exists if fail_if_tag_exists=1
- auth is available if push=1 and explicit auth configured
- latest is skipped for trial if skip_latest_on_trial=1
```

Preflight should not build the image. It only validates that release is likely safe.

---

## Metadata labels

Support repeatable `label` config:

```ini
label = org.opencontainers.image.title=%n
label = org.opencontainers.image.version=%v
label = org.opencontainers.image.revision=%G
label = org.opencontainers.image.source=%o
```

Also support default labels behind a flag:

```ini
oci_labels = 1
```

Default labels when enabled:

```text
org.opencontainers.image.title
org.opencontainers.image.version
org.opencontainers.image.revision
org.opencontainers.image.created
org.opencontainers.image.source
```

---

## Build args

Support repeatable build args:

```ini
build_arg = DIST_NAME=%n
build_arg = DIST_VERSION=%v
build_arg = DIST_TRIAL=%T
```

Do not automatically pass secrets as build args. Build args are not a secret mechanism.

---

## Multi-platform support

For v0.001, keep this single-platform unless `API::Docker` already exposes the required BuildKit behavior cleanly.

Config for later:

```ini
platform = linux/amd64
platform = linux/arm64
```

But important caveat:

- Docker Engine classic image build and Buildx/BuildKit multi-platform publishing are not identical.
- If the Engine API path cannot produce manifest lists cleanly, multi-platform should be explicitly marked experimental.
- Do not fake multi-platform support by just looping platforms unless the result is pushed as a manifest list.

---

## Test plan

### Unit tests

Use fake Docker adapter.

Test:

```text
- tag template expansion
- build context selection
- trial skips latest
- release fails if tag exists
- build phase does not run release policy
- release phase does not run build policy
- errorDetail in build stream is fatal
- errorDetail in push stream is fatal
- labels/build_args templates expand
- invalid image refs fail early
```

### Dist::Zilla integration tests

Use `Test::DZil`.

Cases:

```text
- basic dist builds image from build_root
- generated Makefile.PL exists in context
- pruned files are not in context
- release plugin receives archive path
- trial release does not tag latest
- release creates expected tag list
```

### Optional live tests

Gate behind env var:

```text
DZIL_DOCKER_LIVE_TESTS=1
```

Live tests can use local registry:

```text
registry:2 on localhost:5000
```

Test:

```text
- build image
- tag image
- push image
- inspect pushed image
```

---

## Suggested implementation milestones

### v0.001: Local build

- `phase=build`
- `context=build|source`
- repeatable `tag`
- `repository`
- `file`
- `build_arg`
- `label`
- `push=0`
- fake-client tests

### v0.002: Release build + push

- `phase=release`
- `BeforeRelease` preflight
- `Releaser` build/push
- `context=archive`
- `fail_if_tag_exists`
- `skip_latest_on_trial`
- push stream parsing

### v0.003: Polish and CI usability

- registry auth from env/stash
- digest capture
- `docker-release.json`
- better progress rendering
- local registry live tests

### v0.004: Advanced build features

- cache_from/cache_to if supported
- platform if safely supported
- target stage
- network mode
- provenance/SBOM hooks if the API path supports them

---

## Minimal skeleton

```perl
package Dist::Zilla::Plugin::Docker::API;

use Moose;
with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::AfterBuild';
with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::Releaser';
with 'Dist::Zilla::Role::AfterRelease';

has phase => (
  is      => 'ro',
  isa     => 'Str',
  default => 'build',
);

has repository => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has tag => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { ['latest'] },
);

sub after_build {
  my ($self, $arg) = @_;

  return unless $self->phase eq 'build';

  my $build_root = $arg->{build_root};
  $self->_build_image(build_root => $build_root);
}

sub before_release {
  my ($self, $archive) = @_;

  return unless $self->phase eq 'release';

  $self->_preflight_release(archive => $archive);
}

sub release {
  my ($self, $archive) = @_;

  return unless $self->phase eq 'release';

  $self->_build_image(archive => $archive, push => 1);
}

sub after_release {
  my ($self, $archive) = @_;

  return unless $self->phase eq 'release';

  $self->_log_release_summary;
}

__PACKAGE__->meta->make_immutable;
1;
```

This skeleton is intentionally incomplete: the important part is the lifecycle shape.

---

## Recommended default behavior

```text
Plain dzil build:
  build Docker image locally
  tag latest unless configured otherwise
  do not push

Trial dzil release:
  build release image
  tag version/trial tags
  do not update latest
  push only explicit non-latest tags

Stable dzil release:
  preflight
  build from archive if configured
  tag version tags
  optionally tag latest if explicit
  push
  log digest
```

---

## Key product decision

Do not make this a general replacement for Docker CLI.

Make it a Dist::Zilla-native image publication plugin.

That means the killer feature is not:

```text
Run docker build from dzil
```

The killer feature is:

```text
Build and publish Docker images from the same generated artifact Dist::Zilla releases, with correct release semantics, tag policies, trial handling, and structured Docker API errors.
```

