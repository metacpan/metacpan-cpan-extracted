# Realtime fixtures (k95)

`*.jsonl`: one JSON object per line. The first line describes the file; every other line is
`{"dir": "c2s"|"s2c", "frame": {...}}`, a client-to-server or server-to-client text frame.

**`speaches.jsonl` is recorded; the others are synthetic.** `speaches.jsonl` comes from a real speaches node (`xt/live/record-realtime`, audio shortened to three `append` frames, payloads cut to 16 characters). The rest: They are written by hand after OpenAI's realtime transcription
guide (2026-10-15) and were **not recorded from a live backend**: the plan's Task 0 asks for
recordings of the deployed vLLM and speaches nodes, which needs a live node. They stand for the
two client dialects (`session.update` with a `transcription` session, GA; and
`transcription_session.update`, beta) and for both usage shapes a `...completed` event may carry
(`type: tokens`, `type: duration`). What a deployed vLLM or speaches really accepts and sends --
the dialect, whether `...completed` has `usage` at all, the subprotocol -- is **open** until
someone records them (`websocat` against the node, audio truncated, no keys) and adds
`vllm.jsonl` / `speaches.jsonl` here.
