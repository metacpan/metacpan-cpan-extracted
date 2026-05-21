# Multi-Target Docker Support in [@Author::GETTY]

## Status

Draft — 2026-05-15

## Motivation

The current `[@Author::GETTY]` bundle supports a single Docker image via `docker_image` attribute with single `target`. This is insufficient for distributions like `App::karr` that need multiple Dockerfile targets per image (e.g., `runtime-root` and `runtime-user`).

## Design

### Docker Subsection Syntax

Distributions declare Docker configuration as nested subsections within `[@Author::GETTY]`:

```ini
name = App-karr

[@Author::GETTY]
docker_image = raudssus/karr

[@Author::GETTY::Docker]
target = runtime-root
tags = latest %v %m

[@Author::GETTY::Docker]
target = runtime-user
tags = user
local = 1
```

### Tag Templates

The `tags` attribute supports the following template variables:

| Variable | Description | Example |
|---|---|---|
| `%v` | Full version | `1.23.4` |
| `%m` | Major version (first component) | `1` |
| `%n` | Distribution name | `App-karr` |
| `%p` | Plugin name | `Docker` |

Default tags when none specified: `latest %v %m`

### Attribute Inheritance

The `[@Author::GETTY]` bundle-level attributes serve as defaults for all Docker subsections:

| Bundle Attribute | Docker Subsection Default |
|---|---|
| `docker_image` | image name |
| `docker_tags` | tags (space-separated string) |
| `docker_local` | local registry flag |

When a Docker subsection does not specify an attribute, it inherits from the parent bundle.

### Docker Subsection Attributes

Each `[@Author::GETTY::Docker]` subsection supports all `Dist::Zilla::Plugin::Docker::API` attributes:

| Attribute | Type | Description |
|---|---|---|
| `image` | Str | Docker image name (inherits from `docker_image` if unset) |
| `target` | Str | Dockerfile target stage (optional — only needed for multi-target Dockerfiles) |
| `tags` | Str | Build and release tags, space-separated (default: `latest %v %m`) |
| `local` | Bool | Use localhost:5000/ registry variant, disable push on release (default: inherited from bundle) |
| `build_tag` | ArrayRef | Tags applied during `dzil build` |
| `release_tag` | ArrayRef | Tags applied during `dzil release` |
| All other Docker::API attrs | | Passed directly to Docker::API plugin |

### Validation Rules

1. **Image inheritance** — If no `image` specified in subsection, inherits from parent bundle's `docker_image`
2. **No image duplication** — If subsection has no `image`, only one such subsection allowed per bundle (prevents ambiguity)
3. **Overlapping images error** — If two subsections specify different images, their image names must not overlap (e.g., `myapp` and `myapp-dev` conflict)
4. **Implicit local** — `local=1` is forced when:
   - No `docker_image` at bundle level AND
   - No `image` in subsection
   In other words: only the default-image case (dist-name fallback) gets `local=1`

### Default Behavior (No Explicit Image)

When `[@Author::GETTY]` has no `docker_image` attribute and subsections have no `image`:

- Default image = distribution name (lowercased, dashes replaced with underscores)
- `local=1` is forced (localhost:5000/ variant, no push on release)
- Default tags = `latest %v %m`

```ini
[@Author::GETTY]

[@Author::GETTY::Docker]
target = runtime-root
```

This would build image `app_karr` (from dist name `App-karr`), tagged `latest 0.001 0`, loaded locally only.

### Full Example

```ini
name = App-karr
author = Torsten Raudssus <getty@cpan.org>

[@Author::GETTY]
docker_image = raudssus/karr
docker_local = 0

[@Author::GETTY::Docker]
target = runtime-root
tags = latest %v %m

[@Author::GETTY::Docker]
target = runtime-user
tags = user
local = 1
```

Produces two Docker::API plugin instances:

| Instance | Image | Target | Tags | Local | Push |
|---|---|---|---|---|---|
| 1 | raudssus/karr | runtime-root | latest, 1.0.0, 1 | No | Yes |
| 2 | raudssus/karr | runtime-user | user | Yes | No |

### Implementation

The bundle's `configure` method:

1. Scans `zilla->plugins` for plugins with name matching `Author::GETTY::Docker`
2. Collects payload for each subsection
3. Validates image rules
4. Merges bundle-level defaults into each subsection payload
5. Creates one Docker::API plugin per subsection via `add_plugins`

### Backward Compatibility

- **Single `docker_image` at bundle level** — Still works, treated as single Docker::API instance
- **No Docker config** — Bundle behaves as before, no Docker::API plugins added
- **Old `docker_*` attributes** — Continue to work as bundle-level defaults

### Migration Path

Old dist.ini with manual run hooks:
```ini
run_after_build = docker build ... -t raudssus/karr:latest ...
run_after_release = docker push raudssus/karr:%v
```

New cleaner syntax:
```ini
[@Author::GETTY]
docker_image = raudssus/karr

[@Author::GETTY::Docker]
target = runtime-root
tags = latest %v %m
```

The bundle handles build tags, release tagging, push, and load automatically.