---
name: dkim2-spec-review
description: Issues and clarity suggestions for draft-ietf-dkim-dkim2-spec found during implementation and interop testing
type: project
---

# draft-ietf-dkim-dkim2-spec Review Notes

Issues found during implementation and interop testing.  Each issue is tagged
with the spec version where it was confirmed to still apply.

---

## Issues confirmed in draft-ietf-dkim-dkim2-spec-01

### 1. §8.1: Ambiguous antecedent in MI-skip condition

The sentence reads: "If hashing the message body or relevant header fields
does not give the same hash values as those recorded in the highest version
(m=) Message-Instance header field then a new Message-Instance header field
MUST be added and if they are the same a new Message-Instance header field
SHOULD NOT be added."

The phrase "if they are the same" has no clear antecedent — "they" could
refer to the body hash, the header hash, or both.  The full intent (skip
only when BOTH body hash AND header hash are unchanged) is only recoverable
by taking the logical inverse of the previous clause.

**Suggested fix:** Split into two sentences and name the subject explicitly:
"If BOTH hash values match those recorded in the existing Message-Instance
header field, a new Message-Instance header field SHOULD NOT be added."

### 2. §8.1: Spec does not require MI verification before diff computation

The spec describes how to compute a new Message-Instance header (the diff)
but does not say that an intermediary MUST verify the existing top MI before
using it as the diff baseline.  If an intermediary blindly computes a diff
against a tampered or invalid MI, the resulting chain is meaningless — the
new MI correctly records what changed, but "changed from what?" has no valid
answer.

**Suggested fix:** Add a normative requirement: "Before computing a new
Message-Instance header field at egress, the MTA SHOULD verify that the
highest-version existing Message-Instance header field's hash values match
the current message content.  If verification fails, the MTA SHOULD treat
the message as a fresh origination and add a new Message-Instance v=1."

### 3. §9/§10: Spec does not require the top DKIM2-Signature to cover the topmost MI

The verifier is expected to check each signature covers the headers that
existed when it was created.  But the spec does not explicitly require that
the highest-sequence DKIM2-Signature's m= tag equals the highest-version
Message-Instance header present.

If an intermediary adds a new MI header without adding a new DKIM2-Signature,
the message arrives with an uncovered MI at the top of the chain.  A verifier
that only checks "each signature covers the headers it declared" would pass
this message — but the topmost MI is not authenticated by anyone.

**Example:** MI v=1, MI v=2 present; DKIM2-Signature i=1 (m=1) only.
A verifier validating i=1's signing input (correctly including only MI v=1)
returns pass — but MI v=2 is entirely unauthenticated.

**Suggested fix:** Add a normative requirement in the verifier actions section:
"The highest-sequence DKIM2-Signature header field's m= value MUST equal the
number of Message-Instance header fields present.  If there are more
Message-Instance header fields than covered by the top DKIM2-Signature, the
verifier MUST return FAIL."

### 4. §5.2: MI computation ordering with Authentication-Results

The spec's header hash exclusion list (§5.2) includes Received, Return-Path,
Message-Instance, DKIM2-Signature, DKIM-Signature, and X-* / ARC-* prefixes.
It does not mention Authentication-Results.

The inbound milter must compute the MI hash over a message state that already
includes the Authentication-Results header it is about to insert.  Because the
milter protocol batches all header insertions (they are applied to the live
message only after the EOM callback returns), the milter must construct a
synthetic message string that prepends the AR header, compute MI over that
string, and then queue both AR and the MI for insertion.

The spec does not describe this ordering requirement.  Implementors must be
aware that the MI hash covers AR (it is not excluded) and must therefore be
computed in the correct order.

**Suggested clarification:** Add a note in §8.1 that an intermediary inserting
both an MI header and other transit headers (e.g. Authentication-Results) in
the same pass MUST compute the MI hash over a message state that includes all
headers that will be present in the delivered message.

### 5. §8.5: Signing input uses null (empty) string for signature values

The spec says (§8.5):

> "the signature value(s) within the (s=) value are set to the null string
> ("")."

This means `s=sel:alg:` with an empty string after the final colon.  Early
implementations of this code used `.` (a dot) as the placeholder, which
breaks interoperability: after `dkim2_canonicalize_sig_header` removes all
whitespace, `s=sel:alg:.` ≠ `s=sel:alg:`.

**Fixed in -01:** Both the Perl and Python implementations now use the empty
string per spec.  Verifiers must use empty string (not dot or any other
placeholder) when reconstructing the incomplete DKIM2-Signature header for
verification.  Note also that implementations MUST search for the `s=` tag
by looking for `;s=` (semicolon tag separator) rather than a bare `rfind("s=")`
since base64 signature values can contain the substring `s=`.

## spec-02: No normative guidance when outbound signer finds invalid intermediate MI

The spec describes how a signing MTA computes a diff Message-Instance header
(§8.1) but does not specify what a signer MUST or SHOULD do if the topmost
existing MI header does not match the current message content AND the signer
holds a snapshot for an earlier MI version.

In practice (observed at Fastmail during Mailman integration), an intermediate
MTA may add an incorrect MI header due to a bug (e.g., including
Authentication-Results in the header hash when the spec says to exclude it).
The outbound signer then finds:
  - MI v=1 (correct, snapshot available)
  - MI v=2 (invalid — wrong hashes, from a buggy upstream hop)

If the signer naively creates MI v=3 over this chain (computing a diff from
the v=1 snapshot), the resulting chain has a lie at v=2: it claims the message
had certain hashes at that point, which is false.  A verifier that only checks
the top MI would not detect this.

**Suggested fix:** Add a normative requirement in §8.1 (or a new subsection):
"If the existing topmost Message-Instance header field's hash values do not
match the current message content, and the signing MTA holds a valid snapshot
for an earlier Message-Instance version m=K, it MUST:
  (a) discard all Message-Instance header fields with m > K,
  (b) compute a new Message-Instance header field as a diff from the m=K
      snapshot to the current message state (this becomes the new m=K+1), and
  (c) log a warning that broken intermediate MI headers were discarded."

Our implementation (dkim2-milter.pl and DKIM2Sign.pm) follows this behaviour.

## spec-02: §11 vs JSON schema inconsistency for `z` body recipe step

spec-02 removed the `{"z": true}` body recipe step from the JSON schema
(changelog: "Removed the z body recipe since DSNs do not actually need this")
but §11 (DSN handling) still says:

> "If the message body has been truncated (rather than omitted altogether)
> then in order to allow verification of the DNS contents a Message-Instance
> header field MUST be added to the message with a body recipe containing a
> {"z": true} step."

The `MUST` in §11 and the removed schema entry are contradictory.
Our implementation ignores `z` steps if encountered (backward compat) and
does not generate them (since DSN truncation is not yet implemented).
This inconsistency should be raised with the spec authors.
