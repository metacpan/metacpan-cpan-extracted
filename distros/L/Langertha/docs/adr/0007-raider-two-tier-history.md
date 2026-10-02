# ADR 0007 — Raider keeps two histories: a never-compressed session archive and an auto-compressed working history

- Status: accepted
- Date: 2026-06-26
- Tags: raider, history, compression, embeddings, context

## Context

A long-running autonomous agent (`Langertha::Raider`) accumulates context that outgrows the
model's window. Two needs pull in opposite directions:

- The next LLM turn needs a *small* prompt, so the agent must shed old turns to stay under the
  context limit.
- The agent — and any audit or recall over what happened — needs the *complete* record,
  including the intermediate tool calls and tool results, so nothing can be thrown away.

Intermediate tool-call traffic (assistant tool-request messages plus their results) bloats
the token count fastest and rarely needs to be re-sent verbatim on the next turn.

A single history list cannot satisfy both: compress it and recall breaks; keep it whole and
the prompt grows unbounded.

## Decision

Keep two separate stores with different lifecycles.

1. **`history` — the working conversation.** Only user messages and final assistant *text*
   responses (intermediate tool-request / tool-result messages are deliberately **not**
   persisted here — `Raider.pm:97-100`). This is what feeds the next prompt. It is
   **auto-compressed**: when `max_context_tokens` is set and prompt usage exceeds
   `context_compress_threshold` (default `0.75`), `compress_history_f` summarizes it via the
   LLM — optionally a cheaper `compression_engine` — and replaces the working history with the
   summary (`Raider.pm:821-852`). Cleared by `clear_history` / `reset`.

2. **`session_history` — the full chronological archive.** ALL messages, including tool calls
   and results. **Never auto-compressed.** Persists across `clear_history` and `reset`; only
   cleared by hand via `$raider->session_history([])` (`Raider.pm:215-227`). A compression
   event is itself recorded as a marker entry in this archive, so the lossless record shows
   where the lossy working history was summarized.

3. **Recall over the archive is semantic.** `_push_session_history` fires-and-forgets an
   embedding per archived message — via an explicit `embedding_engine`, or the main `engine`
   if it composes `Role::Embedding`, unless `no_session_embeddings` is set
   (`Raider.pm:1228-1272`). `_query_session_history` ranks entries by cosine similarity
   (`_cosine_similarity`) and returns the top matches, falling back to a text grep when no
   embedding engine is available (`Raider.pm:1139-1175`). This recall is exposed to the model
   as the `raider_session_history` self-tool (ADR 0008).

## Rationale

Separating the two stores resolves the conflict cleanly: compression operates only on the
working history that feeds the prompt, so the prompt stays bounded, while the archive stays
lossless for audit and recall. Conflating them would force a choice between an unbounded
prompt and an unrecoverable history — exactly the trade-off the two-tier model avoids.

Embedding search is what makes a lossless, ever-growing archive *useful* at scale: the agent
retrieves the relevant slice of a large history without re-reading all of it into the prompt.
Fire-and-forget embedding keeps the hot path cheap; cosine ranking with a graceful grep
fallback means recall *degrades* (to substring match) rather than *breaks* when no embedder is
present.

## Consequences

- Compression is opt-in — it only runs when `max_context_tokens` is set. By default nothing is
  summarized and nothing is lost.
- The archive grows unbounded by design; trimming it is a manual, explicit act, never
  automatic.
- Recall quality tracks the embedding engine. With none configured (and none auto-detected),
  recall is substring grep over the archive.
- Embedding is best-effort: a failed `simple_embedding` pushes an `undef` slot so the archive
  and the embedding list stay index-aligned, and that entry is simply skipped during semantic
  ranking.
- Cross-link: ADR 0008 (the self-tools that expose `raider_session_history`, `raider_pause`,
  `raider_ask_user`, … to the model).
