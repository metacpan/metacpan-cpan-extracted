# ADR 0072 — The age-stanza count is capped on the read path, and that divergence from sops is accepted as a limit

- Status: accepted
- Date: 2026-09-19
- Resolves k199
- Records the divergence that shipped in k192 (the backend cap) and k194
  (`max_stanzas` threaded through the public decrypt API)
- Precedent: ADR 0007 (the config-search divergence), ADR 0064–0066 (read-path
  refusals) — the same "diverge from sops on purpose, and put the reason and the
  escape hatch on record" shape
- **Moves no wire bytes.** The cap is a non-mutating read-path guard: it reads
  the length of the `sops.age` list and compares. MAC, AAD, encrypted value
  bytes and the whole encrypt path are unchanged (`encrypt_data_key` is
  untouched). What shipped in k192/k194 is the guard and its `max_stanzas` knob,
  pinned by `t/83` and `t/84`; what this ADR adds is the record that the
  resulting refusal is a deliberate divergence, not a bug.

## Context

CVE-2026-85783: an age header carries one recipient stanza per recipient, and
decrypting the data key tries each stanza — an X25519 scalar multiplication —
before the header is authenticated. sops imposes no ceiling on how many entries
a document's `sops.age` list carries, and age/Crypt::Age before 0.004 imposed
none on the stanzas within a single header. A hostile document could present an
unbounded count in either dimension and force the reader through unbounded
scalar multiplications on every decrypt attempt.

Crypt::Age 0.004 closes the inner dimension: it caps the recipient stanzas
within one header at 128 by default and refuses before authenticating. k192
closes the outer one here — File::SOPS caps the number of `sops.age` entries it
will attempt at 64 by default, refusing (`croak`) before the first stanza is
decrypted. k194 exposes that ceiling as `max_stanzas` on `decrypt` and, through
it, `decrypt_file`/`extract`/`rotate`/`edit`; the default is applied once, in
the backend (`$args{max_stanzas} // 64`).

The consequence is a read-path divergence. `sops -d` has no equivalent cap, so a
document with more than 64 age recipients that sops decrypts is refused here
unless the caller raises `max_stanzas`. This is the same class as the
divergences this repo records rather than hides: a document the reference
accepts, refused here on purpose, with the reason and the workaround named.

## What is verified

- The guard fires on the entry count **before** any `Crypt::Age->decrypt` call:
  `t/83` mocks `Crypt::Age::decrypt` to die if reached and confirms an
  over-limit document never reaches it — zero scalar multiplications on refusal.
- The refusal is loud (a `croak`) and leaks nothing: the message carries only
  the two integers (count, limit), not recipients or `enc` blobs (`t/83`).
- Absence of the argument is byte-identical to the pre-k192 path
  (`max_stanzas // 64`), and all five public entry points refuse and raise
  consistently: `t/84`.
- The cap does not disturb the wire: full interop against sops 3.13.3
  round-trips both directions (`t/04-interop.t`; the whole suite is green with
  the binary present, 86 files / 1464 tests).
- 64 is a conservative ceiling for real documents: the corpus contains no
  document with more than 64 real recipients; only `t/83` and `t/84` synthesise
  over-limit counts from cheap dummy entries.

## Decision

Accept the cap, and the divergence it creates, as a limit. A document presenting
more than 64 `sops.age` entries is refused before decryption; a caller who
legitimately carries more recipients passes `max_stanzas => N`. The default
lives in one place (`File::SOPS::Backend::Age`), the public API forwards it
unchanged, and `undef` restores the historical behaviour exactly. The
two-dimensional amplification of the CVE — unbounded entries × unbounded
per-header stanzas — is now bounded × bounded (identities is caller-controlled).

## Consequences

- A >64-recipient document that `sops -d` accepts is refused here by default.
  This is a deliberate divergence, now on record; a reader who hits it has this
  ADR and the `max_stanzas` knob rather than only a code comment.
- The default is not range-validated in the backend: `max_stanzas => 0` or a
  negative refuses every non-empty document, and a non-numeric value numifies to
  0 with a warning. The failure direction is fail-closed (it over-refuses, never
  under-refuses), so it is safe; a clearer "must be a positive integer" croak is
  a possible follow-up, not a correctness fix.
- "stanza" here names an entry in `sops.age`; age and Crypt::Age reserve it for
  a recipient block within one header. Both layers expose a cap (File::SOPS 64
  entries, Crypt::Age 128 per-header stanzas) — the POD defines the File::SOPS
  sense, but the naming collision is on record.
- No MAC, AAD, encrypted wire byte, parser, emitter or type-ladder decision
  moves. Reverting the divergence means raising or removing the default cap, not
  rediscovering why it exists.
