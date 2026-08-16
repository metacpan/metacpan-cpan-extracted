# CLAUDE.md — Kubernetes::REST

Perl REST client for the Kubernetes API. Moo + `LWP::UserAgent` (or `HTTP::Tiny`); the typed
objects it sends and returns come from `IO::K8s`. Every API method runs through one
three-step pipeline — build request → hand to the pluggable IO backend → check and inflate
the response — which is what makes a different transport a drop-in.

Build and test: `dzil build`, `dzil test`, `dzil clean`. While iterating: `prove -lr t/`
(**`-r` is required** — plain `prove -l t/` is not recursive). The suite is mock-driven and
needs no cluster. Never `dzil release` without explicit permission; this distribution is
co-maintained (`authority = cpan:JLMARTIN`).

## The neighbourhood

This distribution is one of four that ship together, and a surprising share of bugs
reported here are owned by one of the others:

| Repo | Owns |
|---|---|
| `../io-k8s-p5` — `IO::K8s` | The object model: classes, field names, types, serialization. A wrong or missing field is a bug **there**. |
| `../p5-net-async-kubernetes` — `Net::Async::Kubernetes` | The async transport. It consumes this client's public pipeline seam (`build_path`, `prepare_request`, `check_response`, `inflate_object`, `inflate_list`, `process_watch_chunk`, `process_log_chunk`) and never calls `list`/`get`/`watch` — treat those seven as published API. |
| `../kubernetes-rest-deprecated` — `Kubernetes-REST-Deprecated` | Tombstones for removed API. Anything removed here gets its redirect stub over there, plus a `Changes` bullet naming the new failure mode. |

`bin/kube_client` and `bin/kube_watch` are the shipped CLI entry points, built on
`MooX::Cmd` + `MooX::Options` under `lib/Kubernetes/REST/CLI/`.
`Kubernetes::REST::Example` is a POD-only tutorial (~1100 lines) whose examples must stay
runnable against the shipped API.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lanes and this repo's hazards are in `.claude/rules/kubernetes-rest-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` or `bin/` | `kubernetes-rest-worker` (default) |
| Write or extend tests in `t/` | `kubernetes-rest-test-writer` |
| POD, on the core, the backends or the CLI | `kubernetes-rest-doc-writer` |
| Pre-release audit | `kubernetes-rest-release-checker` |

The agents carry their conventions via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live in `.claude/skills/` —
`kubernetes-rest-core` holds the distribution internals, `perl-kubernetes-rest` the
consumer-facing API, `perl-kubernetes-classes` the IO::K8s object model. Work is tracked on
the local `karr` board.
