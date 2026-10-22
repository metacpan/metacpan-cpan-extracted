---
name: file-sops-hazards
description: "Use when a File::SOPS change touches the sops binary, the UTF-8 encoding, the .sops.yaml creation rules or a file write — the measured 1325-vs-1107 test gap, the UTF-8 flag history of ADR 0003, the config-search divergence and the _replace_file semantics."
---

# File::SOPS — hazards

The format, the invariants and the MAC live in `file-sops-core`. The house rules are in
`.claude/rules/file-sops-rules.md`. This skill carries the traps: the ones that cost a release
rather than a test.

## A missing binary silently subtracts assertions

`t/04-interop.t` round-trips in both directions (Perl→sops, sops→Perl), YAML and JSON, types,
unicode, nested structures. It finds a binary via `$SOPS_BIN`, then `PATH`, then `/tmp/sops`, and only
skips when none of the three yields one. A `$SOPS_BIN` that is set but not executable is a hard
failure, not a fall-through to something nobody chose.

`t/04-interop.t` is no longer the only file that drives the binary — most files added since `t/34`
do — so a missing binary quietly subtracts hundreds of assertions from the whole suite, not twenty
from one file. Measured 2026-08-22: **1325 tests with the binary, 1107 without**, and the run
reports `All tests successful` either way. That gap is the entire compatibility proof, and it does not
announce itself. `ls -l /tmp/sops` before you believe a green run.

This is exactly how two releases shipped a library whose every YAML file sops rejected.

If a binary is missing, `maint/fetch-sops` installs the pinned version (needs a Go toolchain). A
release without a real interop run is a release of untested compatibility claims.

## RE2 is not Perl's regex dialect

The two regex rules (`unencrypted_regex`, `encrypted_regex`) are matched in RE2's dialect, not
Perl's (ADR 0048/0051). Three cases:

- A pattern RE2 cannot compile matches *nothing* on the **read** path — sops discards the compile
  error, so that answer is reproducible and is reproduced — and is refused on the **write** path,
  where handing a caller "matches nothing" for `encrypted_regex` would put every secret on disk in
  plaintext at exit 0.
- A pattern both dialects compile and read *differently* (`\v`, `\Q`, `\E`) is refused everywhere:
  there is no sops answer to reproduce.
- A pattern Perl cannot compile at all (`(?U)`) is refused everywhere too.

## The measured type ladder

Verified against sops 3.13.3: bare `false` → `type:bool`, but quoted `"false"`, `"true"`, `"1"`,
`"0"`, `"007"`, `"1.50"` are all `type:str`. Perl's own literals set the same flags, so `5432` is int
and `'5432'` is str for a structure passed straight to `encrypt`.

## What the encryption rule decides

ADR 0049 (since 0.003) made the rule, not the leaf's text, decide what a leaf *is* — in both
directions. Before that, decryption was driven purely by whether a leaf matched `ENC[...]`; that
asymmetry held for most of this distribution's life and is now out of date. Two consequences, both
measured against sops and both caller-visible:

- A leaf the rule **excludes** is a literal value whatever it spells. An `ENC[...]` string there is
  *not* decrypted, and the digest covers that text rather than the value behind it — so a document
  whose rule excludes an encrypted leaf fails its own MAC, exactly as sops fails it (exit 51).
- A leaf the rule **selects** must be encrypted; a bare one is refused at its path (sops: exit 25).
  Four shapes stay bare because sops leaves them alone: an `undef`, an empty string, a comment, and
  an empty list or mapping.

## Three traps in the MAC walk

- The decrypt side used to scrape `ENC[...]` strings out of the raw text with a regex; that could not
  see unencrypted values and so could not place them.
- Excluding the metadata MAC by matching `mac:` in text used to swallow any user key ending in
  `mac`; it is done structurally now, by dropping the `sops` branch.
- Hashing a value after Perl's numeric conversion is what made `'007'` hash as `007` on write and `7`
  on read.
- The encrypt side depends on the emitters sorting keys: `YAML::XS::Dump` sorts, `File::SOPS::Format::JSON`
  sets `canonical => 1`. A serializer that emits insertion order breaks verification for self-produced
  files, and the failure surfaces as `MAC verification failed`, nowhere near the cause.

## The UTF-8 flag story (ADR 0003)

The rule in `file-sops-core` — encode unconditionally, never read the flag — exists because both
halves were flag-guarded once and both were bugs; the AAD half landed a release earlier.

Measured with an unflagged `"caf\x{e9}"`:

- an **unencrypted** value went into the document as UTF-8 and into the digest as Latin-1, so
  `sops -d` reported `MAC mismatch`;
- an **encrypted** one was self-consistent — invisible from inside Perl — but came back out of
  `sops -d` as `!!binary Y2Fm6Q==` instead of `café`.

**The cost, accepted deliberately:** a caller passing UTF-8 *bytes* is now double-encoded. The
emitters were already doing that to such a caller's unencrypted values, so it was never a whole
guarantee — see ADR 0003 for why the ambiguity can only be resolved once, and the same way,
everywhere.

## `.sops.yaml` creation rules

`creation_rules_for` exists now. Two things about it are easy to get wrong:

- `path_regex` matches the path relative to the **config file's directory**, not the absolute path;
- the search for the config runs upward from the **file's** directory, where sops searches upward
  from the **working directory**.

The second is a deliberate divergence and the only one in this distribution that can change *who can
read a secret* — it is pinned in `t/04-interop.t`, which asserts both behaviours side by side, and is
open for the maintainer to confirm or revert.

## Every write goes through `_replace_file`

`encrypt_in_place` and `edit` do exist. **Every** method that writes a file now goes through
`_replace_file` — temp file next to the target, then `rename` — so a failure part-way leaves the
original intact (this closed a real bug: `encrypt_file`, `decrypt_file` and `rotate`, which used to
open the target with `>` and check neither the `print` nor the `close`).

The cost is a new inode: hard links keep the old content, and replacing a file needs write permission
on the *directory*. A target that exists and is not a regular file (`/dev/stdout`, a fifo) is written
through directly instead.

## `edit` is not `sops edit`

`edit` re-encrypts under a **new data key**, where `sops edit` keeps the existing one, which is why
it refuses the same foreign-key-material documents `rotate` refuses.

## Where the rest of the conventions live

- the format, the invariants and the MAC — `file-sops-core`
- house style, `$VERSION`, cpanfile pinning — `getty-perl-core`, `getty-perl-moo`
- POD — `getty-perl-pod`
- the house rules — `.claude/rules/file-sops-rules.md`
