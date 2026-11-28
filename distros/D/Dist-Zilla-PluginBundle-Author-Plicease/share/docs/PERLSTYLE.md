# Modern Perl Coding Guidelines

These guidelines define reusable defaults for new Perl projects. They should not generally be applied to older projects where preserving backward compatibility is preferred. Existing projects should retain their established Perl version baseline and compatibility conventions unless a deliberate decision is made to modernize them. Project-specific requirements and justified exceptions belong in `DESIGN.md`. The module recommendations below are conditional preferences, not a mandatory dependency list.

## Language baseline

Target Perl 5.42 or later. Use the following two-line preamble in modules and scripts (after any shebang or package declaration). Tests use the separate preamble specified below:

```perl
use v5.42;
use warnings;
```

The version declaration enables strictures and the corresponding feature bundle. Do not redundantly declare `use strict` or features already enabled by that bundle. Preserve modern language defaults, including disabled indirect object syntax.

Prefer the dotted version notation `v5.42` in Perl source. Use `use 5.042;` instead of `use v5.42;`, and the version `5.042` in prerequisite declarations or other version metadata, when doing so avoids warnings from Perl or tooling. Both notations specify the same minimum Perl version.

### Language features

Use the following features and idioms where appropriate:

| Feature or idiom | Intended use |
| --- | --- |
| `signatures` | Subroutine and method parameters |
| `postderef` (postfix dereferencing) | Clear dereferencing of arrays, hashes and other references |
| `postderef_qq` | Postfix dereferencing in interpolated strings |
| `module_true` | Omit the otherwise unnecessary trailing `1;` in modules |
| `say` | Line-oriented output |
| `state` | Persistent lexical variables |
| `try` | Structured exception handling using stable syntax |
| `current_sub` | Self-reference in anonymous subroutines via `__SUB__` |
| `isa` | Infix object type checks |

Only explicitly enable a feature if it is not already enabled by the `v5.42` bundle and requires an explicit declaration. Do not add feature declarations merely to advertise which features a file uses.

Prefer signatures to manual argument unpacking. Use postfix dereferencing where it improves readability. Use stable `try`/`catch` syntax; do not use experimental extensions. Avoid experimental language features, including native `class` syntax, and do not suppress experimental warnings to circumvent this policy.

## Testing

Use `Test2::V0` for tests in new projects. The standard test preamble is:

```perl
use v5.42;
use Test2::V0 -no_srand => 1;
```

An explicit `use warnings;` is unnecessary in this preamble because `Test2::V0` enables warnings. This follows the Author::Plicease minting profile. Explicitly disable Test2’s automatic random-number generator seeding with `-no_srand => 1`. Declare `Test2::V0` as a test prerequisite rather than a runtime prerequisite.

## Object systems

Prefer `Class::Tiny` when a lightweight object system is sufficient. Do not introduce an object system for code that does not need one.

A project may explicitly select `Moo` where its additional capabilities, such as read-only attributes, construction validation or lazy attributes, justify the dependency. Require version 2 or later to avoid the historical version 1 strictures behavior:

```perl
use Moo 2;
```

Declare the corresponding minimum version in distribution prerequisites. When using Moo, prefer read-only attributes unless mutation is part of the intended interface. Use signatures for methods where appropriate.

Document deviations from the default object system in `DESIGN.md`.

## Dependency selection

Introduce dependencies only when they serve a concrete project requirement. Prefer core Perl functionality when it is sufficient, clear and robust. When selecting CPAN dependencies, consider technical suitability, long-term maintainability, public issue tracking and opportunities for upstream collaboration.

### Preferred modules

| Purpose | Preference |
| --- | --- |
| Object system | `Class::Tiny` by default; `Moo` 2 or later when explicitly selected |
| Filesystem operations | `Path::Tiny` where appropriate |
| Output capture | `Capture::Tiny` where appropriate |
| Additional list utilities | `List::SomeUtils` rather than `List::MoreUtils` |
| Asynchronous I/O | `IO::Async` rather than `AnyEvent` |
| JSON encoding and decoding | `JSON::MaybeXS` rather than a direct dependency on `JSON::XS` |

Use `Path::Tiny` for path manipulation, file I/O and temporary files where it simplifies code and avoids filesystem corner cases. Use `Capture::Tiny` when capturing output from code or external commands rather than implementing output capture manually.

Prefer `JSON::MaybeXS` as the JSON abstraction layer. Its selection of an installed JSON backend is acceptable; avoid relying on a particular backend's implementation-specific API unless required.

### Upstream maintenance considerations

- **`REHSACK`**: Prefer alternative distributions where practical to reduce upstream collaboration and maintenance risks.
- **`MLEHMANN`**: Prefer alternative distributions where practical due to the lack of public bug trackers, which makes transparent issue reporting and collaborative maintenance more difficult.

These preferences apply primarily to direct dependencies. They are not blanket prohibitions against transitive dependencies or against using modules for which no reasonable alternative exists. Document necessary exceptions and their technical justification in `DESIGN.md`.

## Distribution management

Use `Dist::Zilla` with [`Dist::Zilla::PluginBundle::Author::Plicease`](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::Plicease) (`@Author::Plicease`) for distribution management.

Prefer the bundle's conventions to manually assembling equivalent plugins. Declare the Perl 5.42 baseline and actual prerequisites in the distribution configuration. Distinguish runtime prerequisites from testing, authoring and release requirements.

Keep ordinary development and testing possible from a checkout where practical, without requiring a distribution build for every change.

## Project integration

Keep this document project-independent. Project-specific architecture, selected dependencies, compatibility requirements and exceptions belong in `DESIGN.md`.

Where a repository includes `AGENTS.md`, direct contributors and coding agents to read both `PERLSTYLE.md` and `DESIGN.md`. Explicit project-specific decisions in `DESIGN.md` take precedence over the defaults in this document.
