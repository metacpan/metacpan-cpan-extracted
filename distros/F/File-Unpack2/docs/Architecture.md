# File::Unpack2 Architecture

This document explains how the unpacker works and, more importantly, *why* it is built the way it is. It is
meant to be read start to finish by someone new to the project — most likely someone working their way into
[Cavil](https://github.com/openSUSE/cavil) — before they open the source. It talks about concepts, not
functions or line numbers.

## Why this exists

Cavil reviews the licensing of software by scanning source code for the text of known licenses. Before it can
scan anything, it has to get the text *out* of whatever a package happens to be: a tarball, an RPM, a zip
inside a tarball inside an RPM, a PDF, an office document. `File::Unpack2` is the component that does that. Its
one job is to take an arbitrary input and expose as much readable payload as possible as ordinary files on
disk, so the rest of Cavil can read them.

That single goal — *expose everything readable* — explains most of the design decisions below. Unpacking goes
as deep as it can rather than stopping at the first layer; it identifies files by content so it is not fooled
by names; and when one file cannot be unpacked it is logged and skipped rather than aborting the whole run,
because a distribution has thousands of files and one bad apple must not sink the batch.

## Identify by content, not by name

The first thing done to any file is to determine its mime type, and this is deliberately *not* based on the
file's suffix. Source packages are full of files whose names lie — a `.bin` that is really a zip, a `.gz` with
no extension at all, a shell script with an archive glued onto the end. Trusting the suffix would miss real
payload and waste effort on the wrong helper.

Detection is layered because no single engine is enough. The primary source is `libmagic` (via
`File::LibMagic`), the same engine as the `file` command, which returns a mime type, a charset and a
free-text description. The freedesktop `shared-mime-info` database (via `File::MimeInfo::Magic`) is consulted
where libmagic is weak. And a thin layer of the module's own logic handles cases that carry no reliable magic
of their own — most importantly raw LZMA, which is almost content-free at the start of the stream. The
human-readable description is cross-checked against the mime type, so a file that libmagic mislabels can be
caught and corrected before the wrong helper runs. The two magic libraries are loaded lazily; only mime
detection needs them, and the module degrades gracefully if one is missing.

## Dispatch to mime helpers

Once a file's type is known, unpacking it is delegated to a **mime helper** for that type. A helper is just
"the thing that knows how to open this kind of file". Common formats are covered by **built-in helpers**:
entries baked into the module that wrap the standard command line tools — `tar`, `xz`/`lzcat`, `unzip`,
`rpm2cpio` piped into `cpio`, `7z`, `unrar`, `cabextract`, `ar` for `.deb`, `pdftotext`/`pdfimages` for PDFs,
and so on. Each entry pairs a mime-type pattern with a suffix hint and the command (with redirections and
pipelines) to run.

The built-ins cover the archive and compression formats a distribution is made of. For anything else, the
**extension mechanism** lets a consumer teach File::Unpack2 a new format without changing the module.

### Extending: two ways to add a helper

- **Programmatically**, with the `mime_helper` method: register a command for a mime type, using `%(src)s`,
  `%(destfile)s` and friends as placeholders that are filled in at call time. This is how a consumer adds a
  format it cares about; Cavil, for instance, registers a `zstd` helper this way at startup.
- **From a directory**, with the `mime_helper_dir` method (or the `FILE_UNPACK2_HELPER_DIR` environment
  variable, or the `helper_dir` constructor argument): every executable in the directory is registered as a
  helper, named after the mime type it handles. Nothing is scanned unless a directory is explicitly configured.

The naming convention ties a helper to its type. A helper's name (or the `mime_helper` pattern) is the mime
type with `/` written as `=` (filesystems dislike `/` in names), and an `x-` or `ANY+` prefix after the `=` is
treated as implicit — so `application=x-debian-package` handles `application/x-debian-package`. When several
registered helpers could match, the most specific wins: an exact name beats one with wildcards, a wildcard
*after* the `=` beats one before it, and a more-recently-added helper takes precedence. This lets a consumer
override a built-in simply by registering a helper of the same name.

### Writing a mime helper

A directory helper is an ordinary executable — a few lines of shell is typical. It is invoked with its working
directory already set to a fresh, empty output directory, and it is handed six arguments:

```
$1  source path        the file to unpack (absolute)
$2  suggested name     a destination name the helper may use
$3  destination dir    the output directory (also the current working directory)
$4  mime type          as detected
$5  description         libmagic's human-readable description
$6  config dir          a directory holding a JSON dump of the unpacker's config
```

Its job is to place the unpacked contents into the current directory, using *relative* paths only. It signals
success with exit status zero; a non-zero exit is recorded as an error against that one file, and unpacking
continues elsewhere. A helper that determines the file is already as unpacked as it can be may symlink the
suggested name to the source to say "take it as is", which stops recursion into it. Because the contract is
this small, and because it is the same whether the helper is built in, registered by `mime_helper`, or found
in a directory, adding format support is cheap. Both registration styles are demonstrated end to end in
`t/12-mime-helper.t`.

## Recursion: peeling every layer

Unpacking is recursive. After a helper runs, every file it produced is itself fed back through the same
identify-and-dispatch process, so nested archives are peeled apart layer by layer until nothing left looks
unpackable. This is the "aggressive" part, and it is what makes the tool useful to Cavil: the interesting
license text is often several layers down.

Recursion needs a floor. Some inputs — whether malicious or merely pathological — unpack into something that
unpacks into something forever. The module caps the descent at a fixed depth (50 levels): by then it is far
more likely that a loop has been hit than that a package legitimately nests that deeply, so the descent stops
and the situation is logged. A caller can also request a single level only ("one shot"), which is the default
for the command line tool unless its name contains `deep`.

Output is laid out to mirror the input. Each archive unpacks into a subdirectory named after it; the exact
naming rule adapts to how many files came out (a single-file archive does not get a wrapping directory), and
collisions are avoided by appending a `._` suffix. Temporary working directories used while a helper runs are
given an obvious `_fu_` prefix and cleaned up afterwards.

## Surviving hostile input

Cavil feeds this code every file in a distribution, which in practice includes binaries, deliberately
malformed samples that security tools ship as test data, and archive "bombs" engineered to exhaust disk,
memory, or time. The guiding rule is the same one the rest of Cavil follows: no single input, however hostile,
may hang or crash the run or take down the machine. Several independent safeguards enforce this, and they are
layered on purpose — each catches a failure mode the others miss.

- **Output size ceiling.** A per-file maximum size (backed by the `RLIMIT_FSIZE` resource limit via
  `BSD::Resource`, and inherited by child helpers) stops a compressed sparse file or a decompression bomb from
  filling the disk. Files that hit the ceiling are silently truncated and the fact is recorded in the log.
- **Total-work caps.** Optional limits on the total number of files and the total number of bytes produced by
  a single top-level run stop a "many small files" bomb that stays under the per-file ceiling but explodes in
  aggregate.
- **No-progress stall watchdog.** While a helper runs, the module watches the file descriptors of the whole
  helper process family and measures whether any of them are actually advancing — reading input or writing
  output. A helper that has genuinely wedged (a deadlocked pipe, a cyclic-hardlink tar spinning in `stat`, a
  wait on a fifo that will never be fed) makes no progress, and after a configurable stall timeout it is
  killed. Streaming to a pipe still counts as progress, so a legitimately slow but working helper is not killed
  by mistake.
- **Absolute per-helper timeout.** Some bombs are cleverer: they *always* make a little progress, so the stall
  watchdog never fires, but they never finish. An opt-in absolute wall-clock limit per helper catches these
  "slow bombs" regardless of progress.
- **Reliable child cleanup.** When a helper family must be killed, each helper runs in its own process group so
  the whole family can be reaped together. As a belt-and-braces measure, where the platform supports it, each
  helper is also armed with `PR_SET_PDEATHSIG` so the kernel kills it automatically the instant its parent
  worker dies — important when Cavil restarts a worker mid-unpack. This safeguard is optional and simply
  skipped on systems that do not expose the necessary syscall number.
- **Decoder memory limits.** The `xz`/`lzma` helpers are always invoked with a memory limit on decompression,
  so a maliciously-crafted stream cannot make the decoder itself allocate unbounded memory.
- **Free-space awareness.** The unpacker can be told a minimum amount of free filesystem space to keep, and
  warn (or stop) rather than run the disk dry.

The caps that could interfere with normal use (the total-work limits and the absolute helper timeout) are
off by default and opted into by the caller; the stall watchdog and the size ceiling are on by default because
they only ever fire on genuinely stuck or runaway work.

## Isolation

Helpers are not fully trusted to stay inside their sandbox. They are run with their working directory set into
the destination tree, and — because a buggy or hostile helper might try to write with an absolute path or
climb out with `..` — the unpacker can lock down the parent of the working directory while the helper runs, so
files created outside the intended location are refused rather than scattered across the filesystem. By default
the unpacked tree is created user-readable only (`0700`/`0400`); a `world_readable` option relaxes this to the
usual `0755`/`0444` when the output is meant to be shared.

## The log

Everything the unpacker does is recorded to a log, which is the machine-readable record Cavil consumes. The
default format is JSON: a prolog describes the run, then one line is appended for each file produced — its
name mapped to a hash carrying its mime type, size and related information — and an epilog closes the run,
including any counters for files that were skipped (excluded by pattern, or because they were symlinks, fifos,
sockets, or hit a cap) and any errors from individual helpers. A plainer human-readable listing format is also
available for command line use. Paths in the log are, by default, written relative to the destination (or the
input), which keeps the log stable regardless of where the run happened.

## How it fits into Cavil

Cavil runs File::Unpack2 as the first stage of processing a package: unpack the source into a working tree,
then hand that tree to the license scanner ([`Cavil::Matcher`](https://github.com/openSUSE/cavil-matcher)).
The two halves have complementary jobs — this one is responsible for *getting to* the text, robustly and
completely, and the matcher is responsible for *understanding* it. The design priorities here follow from that
role: completeness (descend everywhere, extract everything), robustness (never let one file break the batch),
and operational cleanliness (install automatically, run unattended, and refuse to be turned into a
denial-of-service by a hostile package).

## How to work on it

The behaviour is pinned by the test suite under `t/`. Alongside the ordinary tests of mime detection, helper
dispatch, subdirectory layout and logging, there is an adversarial suite that throws malformed archives,
stalling helpers and bombs at the unpacker and asserts that the caps, the stall watchdog and the absolute
timeout all do their job — and, just as importantly, that a legitimately slow-but-progressing helper is *not*
killed. That suite is the contract: if you change the unpacking or hardening behaviour, it should tell you.

The public Perl API (`new`, `unpack`, `mime`, `mime_helper`, `mime_helper_dir`, `find_mime_helper`, `list`,
`minfree`, …) is documented in the module's own POD (`perldoc File::Unpack2`). Adding support for a format is
usually a helper registration rather than a code change — see "Extending" above; changing *policy* — the caps,
the recursion limit, the detection layering — is a change to the module itself, and belongs together with a
test in the adversarial suite that demonstrates the new behaviour.
