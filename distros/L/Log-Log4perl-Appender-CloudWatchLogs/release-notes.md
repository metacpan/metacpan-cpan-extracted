# Release Notes — Log-Log4perl-Appender-CloudWatchLogs 1.0.7

## Overview

This release renames the primary appender module from
`Log::Log4perl::Appender::CloudWatch` to
`Log::Log4perl::Appender::CloudWatchLogs`, aligns dependency
declarations with the renamed upstream API package, trims redundant
sub-package entries from the dependency list, adds a `prune-streams`
command and refreshes the build-system infrastructure throughout.

---

## Breaking Changes

### Module Renamed

`Log::Log4perl::Appender::CloudWatch` has been **renamed** to
`Log::Log4perl::Appender::CloudWatchLogs`.

Any existing Log::Log4perl configuration that references the old
appender class name must be updated:

```ini
# Before
log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatch

# After
log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
```

The old module file (`lib/Log/Log4perl/Appender/CloudWatch.pm.in`)
and its associated test (`t/00-log-log4perl-appender-cloudwatch.t`)
have been **removed**. The replacement test file is
`t/00-log-log4perl-appender-cloudwatchlogs.t`.

---

## What's New

### `prune-streams` command

Delete log streams whose last event is older than the specified age.

```
aws-logs -g group-name prune-streams older-than
```

### Non-CPAN Dependency Support

This distribution now depends on
`Amazon::API::CloudWatchLogs >= 1.43.90`, which is published on the
OpenBedrock CPAN-compatible repository rather than on CPAN itself.

- The distribution now ships `cpanfile.darkpan` and `cpanm.darkpan`
  to identify the dependencies that must be obtained from the
  OpenBedrock repository at `https://cpan.openbedrock.net/orepan2`.
- `README.md` now contains a full **NON-CPAN DEPENDENCIES** section
  with installation instructions for both `cpm` and `cpanm`,
  including guidance on using
  [DarkPAN::Resolver::SQLite](https://metacpan.org/pod/DarkPAN::Resolver::SQLite)
  and information on provenance verification.
- `buildspec.yml` has been updated to include `cpanfile.darkpan` and
  `cpanm.darkpan` as extra distribution files.

#### Recommended installation with `cpm`

```bash
cpm install \
  --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
  Log-Log4perl-Appender-CloudWatchLogs
```

#### Installation with `cpanm`

```bash
cpanm --mirror https://cpan.openbedrock.net/orepan2 --mirror-only \
  < cpanm.darkpan
```

---

## Dependency Changes

| Package | Before | After | Notes |
|---|---|---|---|
| `Amazon::API::CloudWatchLogs` | `2.1.13` (exact) | `>= 1.43.90` | Version constraint relaxed to a minimum |
| `CLI::Simple::Constants` | `2.0.1` | *(removed)* | Included transitively via `CLI::Simple` |
| `CLI::Simple::Utils` | `2.0.1` | *(removed)* | Included transitively via `CLI::Simple` |

The `cpanfile` has been updated to reflect these changes.

---

## Build System Changes

### `Makefile` / Infrastructure

- Added support for `DARKPAN_REQUIRES` and `DARKPAN_URL` variables to
  enable automatic generation of `cpanfile.darkpan` and
  `cpanm.darkpan` during the build.
- Added `cpanfile.runtime` target (runtime-only `cpanfile` derived
  from `requires`), separate from the full `cpanfile` that includes
  test dependencies.
- The `local` target now tracks installation state via a
  `local/.installed` sentinel file, avoiding redundant reinstalls.
- Dependency scanning (`requires.raw`, `test-requires.scan`) now
  includes `local/lib/perl5` on `PERL5LIB` so locally installed
  modules are visible during scanning.
- Test dependency reconciliation now filters out modules already
  provided by the distribution itself (via a new `provides` target).
- `find-files` macro extended to accept an optional fourth filename
  pattern, allowing `*.t` and `*.p[ml]` to be collected together for
  the `TESTS` variable.
- `TARBALL_ORDER_ONLY_PREREQS` variable added for injecting
  order-only prerequisites on the tarball target without affecting
  dependency tracking.
- `extra-files` generation now validates that listed files are tracked
  by Git (`git ls-files --error-unmatch`) and supports an
  `extra-files.skip` exclusion list.
- `extra-files.mk` is now always included (except during bootstrap
  builds) rather than soft-included with `-include`.
- `PERL5LIB` is now explicitly set when invoking `cpan-maker` during
  the tarball build step.
- `.includes/publish.mk` is now included unconditionally at the end of
  the `Makefile`.

### `.includes/local.mk`

- Runtime and test dependencies are now installed in separate `cpm`
  passes using `cpanfile.runtime` and `test-requires.cpanfile`
  respectively.
- When no `CPAN_INSTALLER` is set the `local/lib/perl5` directory is
  still created so builds do not fail.
- Installation is gated on the `local/.installed` sentinel file.

### `.includes/perl.mk`

- Syntax and POD checking output is now more informative, printing
  `Checking SYNTAX...`, `Checking POD...`, and `OK` messages inline
  using `echo -n` for a single-line status format.
- Tidiness and perlcritic checks similarly now print
  `Checking TIDINESS...` and `Checking PERLCRITIC...` inline with an
  `OK` suffix on success.
- Perlcritic output is now suppressed from `stdout` during normal runs
  (`>/dev/null 2>&1`), reducing noise in CI logs.
- `LOCAL_PREREQ` now references `local/.installed` instead of `local`.

### `.includes/update.mk`

- Managed file lists split into `MANAGED_MK_FILES` (`.mk` includes)
  and `MANAGED_FILES` (non-Makefile managed files such as
  `Makefile.txt` and `gitignore`).
- New managed files added: `bootstrap.mk`, `publish.mk`, `update.mk`,
  `upgrade.mk`.

### `.gitignore`

Added the following patterns:

```
**/*.bak
**/*.log
**/*.pod
**/*.tmp
**/.\#*
**/\#*
cpanfile.*
!cpanfile.darkpan
test-requires.cpanfile
test-requires.scan
```

Note that `cpanfile.darkpan` is explicitly **un-ignored** so it can be
committed to the repository.

---

## Documentation Changes

- `README.md` updated throughout to reference
  `Log::Log4perl::Appender::CloudWatchLogs` (previously `CloudWatch`).
- New **NON-CPAN DEPENDENCIES** section added to `README.md` covering:
  - OpenBedrock repository location and rationale
  - `cpanfile.darkpan` / `cpanm.darkpan` usage
  - `cpm` installation with `DarkPAN::Resolver::SQLite`
  - `cpanm` installation caveats and limitations
  - Provenance and signature verification
- Fixed a typo in the `SEE ALSO` section: `Amazon::API:Help` →
  `Amazon::API::Help`.

---

## Repository

- Homepage: <http://github.com/rlauer6/Log-Log4perl-Appender-CloudWatchLogs.git>
- Bug tracker: <http://github.com/rlauer6/Log-Log4perl-Appender-CloudWatchLogs/issues>
