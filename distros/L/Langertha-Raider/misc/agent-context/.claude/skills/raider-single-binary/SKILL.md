---
name: raider-single-binary
description: Use when touching raider's standalone binary — scripts/build-binary.sh, verify-binary.sh, check-binary-libs.sh, the release-binaries workflow — or when adding a dependency, an engine, a plugin or anything loaded by name that must work packed; also when the packed raider hangs, segfaults, dies with "Unrecognized character \x7F", "Can't locate … in @INC", "did not return a true value", or code starts perl via $^X. PAR::Packer / pp.
---

# raider as a single binary

The binary is a PAR::Packer (`pp`) build of `bin/raider`. `scripts/build-binary.sh`
is the recipe and comments every module it forces in and why — read it, don't
duplicate it. This skill is what the script can't tell you: how packed raider
fails, and the rules for changing anything it carries.

**`pp` exiting 0 proves nothing.** A missing module only shows at runtime, often
only on one code path. A change is done when `scripts/verify-binary.sh <binary>`
prints `verify: OK`, and for a release-shaped build `scripts/check-binary-libs.sh`
passes too.

## Symptom → cause

| Packed raider does this | Cause | Fix |
|---|---|---|
| Hangs forever on the first HTTP request (no error) | A module loaded **by name inside a Future chain** is missing — `IO::Async::Internals::Connector`, `IO::Async::SSL`. Net::Async::HTTP 0.50 then leaks the host's connection slot; every later request to that host waits forever | Force it with `-M` (`IO::Async::**` is already a glob). Unpacked, the same class of failure is caught by `Langertha::Raider::ConnectCheck` |
| Segfault on a JSON call after startup | `attributes` missing: Cpanel::JSON::XS's XS boot dies half-way | `-M attributes` (present — don't drop it) |
| `Can't locate X.pm in @INC` at runtime | X is loaded by string (`require_module`, `use_module`, Moose `with` strings, `Types::Standard` parametrised types, OpenAPI vocabularies) | Add `-M X` or `-M 'X::**'`; re-run verify |
| `… did not return a true value` | pp's PodStrip cut a module whose POD is interleaved with code (`=attr`/`=method`) | `PAR_VERBATIM=1` must stay on the pp call |
| `Unrecognized character \x7F` | Something ran `perl <binary>` — `$^X` is **not** a perl interpreter inside the binary | Ask `Langertha::Raider::Binary::packed_binary()` first (below) |
| Binary starts fine on the build box, dies elsewhere: `libfoo.so: cannot open` | An XS module linked a lib of the build image | Build in `perl:5.40-bookworm` (the workflow does); `check-binary-libs.sh` names the culprit |
| `File::ShareDir … Could not find` | A share tree not packed with `-a "<dir>;lib/auto/share/dist/<Dist>"` | Add the `-a`; verify step 3 byte-compares `share/` |

## Rules when changing what raider carries

- **New dependency or new runtime-loaded module** (engine, plugin, role by
  string, `require` in a code path): add it to build-binary.sh with a one-line
  comment *why it loads by name*, then prove it in verify-binary.sh — step 3
  loads every packed `Langertha::*` module; anything outside that namespace
  needs a real code path in steps 5/6 (the offline raid against the fake
  endpoint, hall + ACP).
- **Name modules, don't glob `Langertha::**`.** A glob searches all of `@INC`
  and drags in sibling dists (Langertha::Knarr) and stale `Langertha::Raider*`
  files of older core releases. The script builds the list from `lib/` and
  core's `.packlist`.
- **An optional extra that links a system lib** (Brotli, LibIDN, libxml2 via
  WebSearch's Yandex provider, Term::ReadLine::Gnu → libreadline) stays out
  with `-X`. The documented runtime set is `libssl libcrypto`; growing it means
  changing `RUNTIME_LIBS` in check-binary-libs.sh **and** the README's Binary
  section (the workflow greps README for each lib in backticks).
- **Code that starts perl or raider** goes through
  `Langertha::Raider::Binary::packed_binary()`: packed, it returns the
  executable (re-exec raider with it directly — Hall does); a perl for
  `perl_eval`/`perl_check`/`perl_cpanm` comes from `File::Which` on `PATH`,
  and none found is a clear tool error. The signal is `$INC{'PAR.pm'}` **and**
  `PAR_PROGNAME` — the env var alone is inherited by child perls.

## Building

```bash
# local, against the dev Langertha (the installed one is usually stale)
RAIDER_BIN_EXTRA_INC=$HOME/dev/langertha/lib RAIDER_BIN_OUT=/tmp/raider scripts/build-binary.sh
scripts/verify-binary.sh /tmp/raider
```

A dev-box build links whatever the host perl was built with (libbz2, libz,
libzstd here) — `check-binary-libs.sh` failing on those locally is expected,
and such a build is never handed out. Release builds come only from the
`release-binaries` workflow (bookworm container, x86_64 + aarch64), which needs
the `cpanfile`'s Langertha floor to be on CPAN.

Background on pp mechanics and the staticperl/FatPacker dead ends:
`~/dev/karr/.claude/skills/karr-single-binary/` (same recipe family).
