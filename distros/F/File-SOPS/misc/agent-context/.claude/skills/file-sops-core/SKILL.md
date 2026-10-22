---
name: file-sops-core
description: "Load before editing File::SOPS — the pure-Perl Mozilla SOPS implementation: AAD and path derivation, MAC ordering, type detection, Go-compatible value serialization."
---

# File::SOPS — core

Pure-Perl implementation of the Mozilla SOPS encrypted-file format, byte-compatible with the Go
reference implementation (`github.com/getsops/sops`). Interop is the whole product: every design
choice here exists because Go does it that way. Everything is `Moo` + `namespace::clean`; the public
API is class methods on `File::SOPS`.

## Module map

| Module | Owns |
|---|---|
| `File::SOPS` | public API (`encrypt`/`decrypt`/`encrypt_file`/`decrypt_file`/`extract`/`rotate`), tree walk, path→AAD, MAC |
| `File::SOPS::Encrypted` | one `ENC[...]` value — parse, encrypt, decrypt, type (de)serialization |
| `File::SOPS::Metadata` | the `sops:` section — backends, mac, lastmodified, version, encryption rules |
| `File::SOPS::Backend::Age` | data-key encryption via `Crypt::Age` (the only backend implemented) |
| `File::SOPS::Format::{YAML,JSON}` | parse/serialize, split off and re-attach the `sops:` section |

## The wire format

`ENC[AES256_GCM,data:<b64>,iv:<b64>,tag:<b64>,type:<str|int|float|bool|bytes>]` — parsed and matched
by one regex in `File::SOPS::Encrypted` (`$ENC_REGEX`, anchored). `is_encrypted` and `parse` share it
— keep them sharing it.

## Invariants that interop depends on

Break any of these and the file still *looks* fine, still round-trips through this library's own
tests, and fails against the real `sops` binary.

1. **AAD is the path, colon-joined, with a trailing colon.** `database:password:` for
   `{database}{password}`. Empty path → empty AAD.
2. **Arrays do not contribute a path component.** Every element of an array shares the *parent's*
   path — no index. `_encrypt_tree`/`_decrypt_tree`/`_build_enc_path_mapping` all implement this;
   they must stay in agreement.
3. **The IV is 32 bytes**, not the AES-GCM-conventional 12. SOPS-Go uses a 32-byte nonce. (`=attr
   iv` in the POD said 12 for two releases; it now says 32 and explains why. Do not "correct" either
   back.)
4. **Booleans serialize Go-style titlecase**: `True` / `False` — on the wire *and* in the bytes fed
   to the MAC digest. Never `1`/`0`, never lowercase.
5. **The type comes from the scalar, never from its text** — `Encrypted->detect_type`:
   `JSON::PP::Boolean` → bool; public `SVf_IOK` → int; public `SVf_NOK` → float; else str. SOPS types
   a value by what the *parser* returned, and YAML::XS and Cpanel::JSON::XS both preserve the SV's
   string-vs-number distinction, so a quoted scalar is a string end to end. Perl's own literals set
   the same flags, so `5432` is int and `'5432'` is str for a structure passed straight to `encrypt`.
   Decided in **ADR 0002**; read it before changing any of this.

   Two things follow, and both are load-bearing:
   - **Do not pattern-match a value's text anywhere.** `looks_like_number`, `/^\d+$/` and `$v eq
     'true'` are all the defect this replaced. And do not read the *private* `SVp_IOK`/`SVp_NOK`:
     those are set by merely reading a string numerically, so a caller's `if ($h{port} > 1024)` would
     retype the document.
   - **A numeric plaintext is canonical, not the source spelling.** Go re-derives the digest input
     from the type, so `007` under `type:int` must be written `7` and `1.50` under `type:float` must
     be written `1.5` (`strconv.Itoa` / `strconv.FormatFloat(v,'f',-1,64)`, the latter reimplemented
     in `Encrypted::_float_bytes`). Writing the source spelling makes `sops -d` reject the whole
     file. A *string* is always written verbatim.

   **There is now ONE ladder and ONE conversion**, `Encrypted->detect_type` and
   `Encrypted->value_to_bytes`; `SOPS::_value_to_bytes` delegates and `SOPS::_detect_type_for_mac`
   is gone. Keep it that way — a second copy is how this distribution produces files that verify
   against themselves and against nothing else.
6. **`bool` deserializes to `JSON::PP::Boolean`** (`JSON->true` / `JSON->false`), not to `1`/`0`, so
   that YAML::XS (with `$YAML::XS::Boolean = 'JSON::PP'`) and JSON::MaybeXS emit real `true`/`false`
   on re-serialization. A plain `1` here silently degrades every bool in the file to an int on the
   next write.
7. **Empty and undefined leaf values are not encrypted** — they serialize as `''`.
8. **Everything hashed or encrypted is UTF-8 bytes, encoded UNCONDITIONALLY** — `_aad_bytes` for the
   AAD, `_utf8_bytes` for the value. Neither reads Perl's UTF-8 flag, and **nothing here may start
   reading it**. Below U+0100 that flag is storage, not meaning: `"caf\x{e9}"` may be held as one
   byte or as two, Perl considers both the same string, and `YAML::XS::Dump` /
   `JSON::MaybeXS(utf8 => 1)` write both to the file as `caf\xc3\xa9`. Anything consulting the flag
   disagrees with the bytes our own emitter wrote, and the document fails *its own* MAC on the read.

   The one exemption is `type:bytes`, which is not text: no encode in, no decode out — and the
   *only* way a caller can say that an unflagged scalar really is bytes, since Perl does not make
   that distinction. ADR 0003 and the measured failures behind this rule are in `file-sops-hazards`.
9. **The API boundary is characters, the wire is UTF-8 bytes, and the library encodes exactly
   once.** Keys, values, `extract` paths and everything `decrypt` returns are character strings. Two
   documented exceptions come back as bytes rather than being mangled: `type:bytes` (SOPS's binary
   type) and a `type:str` whose plaintext is not valid UTF-8.

## The MAC — and its ordering dependency

The MAC is a SHA-512 over the **plaintext values only** (no keys, no paths), uppercase hex, then
itself AES-GCM-encrypted with **`lastmodified` as AAD** and stored as an `ENC[...]` string in the
`sops:` section.

**Every value goes into the digest, encrypted or not** — matching the Go reference — unless
`mac_only_encrypted` is set, which switches to encrypted values only behind a 32-byte
`MACOnlyEncryptedInitialization` prefix that keeps the two settings' digests apart. That prefix
appears nowhere but the reference source.

Both directions funnel through `_mac_digest`; only the leaf collection and the order differ. Encrypt
takes the live tree and sorts keys (`sort keys %$node`); decrypt walks the parsed tree in parallel,
in an order-preserving reparse (YAML::PP, `PRESERVE_ORDER`).

Perl hash order is randomized and the MAC is order-dependent, so the decrypt side must recover order
from the document. **ADR 0001** records why YAML::PP supplies order and nothing else — values still
come from the real tree, and YAML::XS / JSON::MaybeXS remain the parsers and emitters. The metadata
MAC is excluded structurally by dropping the `sops` branch, not by matching `mac:` in text.

**The encrypt side depends on the emitters sorting keys** — `YAML::XS::Dump` sorts,
`File::SOPS::Format::JSON` sets `canonical => 1`; `t/05-format-key-order.t` pins it, and the failure
mode is in `file-sops-hazards`.

**What a leaf contributes is the authenticated plaintext**, from `File::SOPS::Encrypted::decrypt_bytes`,
with only the bool titlecase rule applied — never a re-serialization.

Verification **fails closed**: a missing, malformed or undecryptable MAC dies. Callers that need the
old lax behaviour pass `ignore_mac => 1` to `decrypt`, `decrypt_file`, `extract` or `rotate` — data
that is decrypted but *not authenticated*, there mainly to rescue files damaged by the pre-0.003
boolean bugs.

## Metadata section

`to_hash` always emits `kms`, `gcp_kms`, `azure_kv`, `hc_vault`, `age`, `pgp` — empty arrays
included, because Go expects the keys to exist. Optional fields (`lastmodified`, `mac`, `version`,
the encryption-rule fields) are emitted only when defined; `version` defaults to `3.7.3`.

Encryption rules: `unencrypted_suffix` (default `_unencrypted`) marks keys that are **not encrypted
but still hashed into the MAC**; `encrypted_suffix`, `unencrypted_regex` and `encrypted_regex` are
the other three. `should_encrypt_key` answers for one key, `should_encrypt_path` for a whole path —
the second is the one the walks ask.

**The rule decides what a leaf *is*, in both directions (ADR 0049, since 0.003).** `_encrypt_tree`
and `_decrypt_tree` both consult `should_encrypt_path`, and the leaf's own text gets no vote —
anything you remember about ENC-driven decryption is out of date. A leaf the rule **excludes** is a
literal value whatever it spells; a leaf the rule **selects** must be encrypted. The measured
consequences and the exit codes are in `file-sops-hazards`.

Because both walks now ask the same predicate, a path component one adds and the other does not is a
document this library writes and then cannot read — that is why `_adds_no_path_component` exists and
why every walk that builds a path goes through it.

**The two regex rules are matched in RE2's dialect, not Perl's (ADR 0048/0051)** — a pattern RE2
cannot compile matches *nothing* on the read path and is refused on the write path.
`file-sops-hazards` has the three cases and what each one costs.

## What exists and what does not

Every backend other than age — PGP, KMS, GCP KMS, Azure KV, Vault — is **not implemented**: the
metadata fields exist and round-trip, the encryption does not, and that gap is **parked on a
maintainer decision**. All four format handlers exist: YAML, JSON, ENV/dotenv and INI, the last two
since 2026-08-21. `CLAUDE.md` describes a little more than exists — a roadmap, not the code.

## Verification — read this before saying "tests pass"

```bash
prove -lr t/   # recursive; -r matters if subdirs ever appear
```

`dzil test` runs the same suite, recursively by construction. **`t/04-interop.t` is the only test that
proves compatibility with SOPS** — it round-trips in both directions (Perl→sops, sops→Perl) and skips
without a `sops` binary, so "All tests successful" proves nothing about what sops accepts. Check the
run, not the summary: the resolution order, the measured gap and `maint/fetch-sops` are in
`file-sops-hazards`. Quote the binary and version the run used when you claim compatibility.

## Where the rest of the conventions live

- the traps around the binary, the type ladder, the UTF-8 flag, the encryption rule, the RE2 dialect
  and the file replacement — `file-sops-hazards`
- house style, POD and the house rules — `getty-perl-core`, `getty-perl-moo`, `getty-perl-pod`,
  `.claude/rules/file-sops-rules.md`
