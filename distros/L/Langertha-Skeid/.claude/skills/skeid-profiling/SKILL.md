---
name: skeid-profiling
description: Use when profiling Skeid with Devel::NYTProf — profiling a running Mojolicious server, reading the result without being misled by the event loop, bench/nytprof-digest.pl.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

`bench/` answers *how much* Skeid costs. This answers *where* it goes. The two are different
questions and the second one is only worth asking once the first has found something: profile
after a benchmark has shown a path is expensive, not instead of one.

**`bench/nytprof-digest.pl` is not in the tree.** It was never committed; it survives only in
the stash (`git show 'stash@{0}^3:bench/nytprof-digest.pl'`), as do the 2026-08-15 reports this
skill quotes. Restore it to `bench/` before following the digest steps below; without it, read
the profile with `nytprofcsv` / `nytprofhtml` and set the event loop and compile time aside by
hand.

## Profiling a server, not a script

NYTProf profiles a process from start to exit. A server does not exit, so three things have to
be arranged or the run produces nothing usable.

```bash
cd /tmp/prof
NYTPROF="sigexit=int:addpid=1:file=$PWD/stream.out" MOJO_LOG_LEVEL=error \
  setsid nohup taskset -c 0 perl -d:NYTProf -I/path/to/lib /path/to/bin/skeid serve \
  --listen 127.0.0.1:18090 --config bench/skeid.bench.yaml > prof.log 2>&1 < /dev/null &

# one path at a time -- a mixed profile cannot answer "what does streaming cost"
taskset -c 2,3 bench/llmbench --port 18090 --requests 400 --concurrency 4 --tokens 64 --stream

PID=$(pgrep -u "$USER" -f '^perl -d:NYTProf' | head -1)
kill -INT "$PID"
until ! kill -0 "$PID" 2>/dev/null; do sleep 1; done   # 50 MB takes seconds to write
perl bench/nytprof-digest.pl stream.out.* --top 15
```

| | why |
|---|---|
| `sigexit=int` | without it, a signalled server dies with a truncated file and `inflate error -5` |
| **wait for the process to be gone** | the profile is written *during* shutdown; reading it early is the same truncation |
| `--workers` omitted | prefork means one file per worker, each with a fraction of the traffic |
| one traffic shape per run | streaming costs ~6× what JSON costs per request; mixing them averages away both |
| `taskset` | same pinning as the benchmark, so the two are talking about the same machine |
| 400+ requests | at ~120 requests the profile is mostly compile time |

Under NYTProf Skeid runs roughly 20× slower (TTFT 87 ms → 1.6 s). **Never quote an absolute
time from a profile.** Shares survive the distortion; milliseconds do not.

## Reading it: `bench/nytprof-digest.pl`

`nytprofhtml` produces megabytes of linked HTML — right for a browser, wrong for anyone who
wants the answer in one screen or in a context window. The digest prints cost by library, by
sub and by line, and it removes two things that otherwise dominate every server profile:

- **the event loop.** `EV::run` is a single call lasting the whole run — 205 s of a 232 s
  profile in the first run of this kind. It is time spent waiting on sockets, not time the code
  cost. The digest reports it separately as `waiting` and computes every share against the rest.
- **compile time.** `BEGIN` blocks, `Exporter::import`, `Eval::Closure` — paid once at boot,
  never on the request path, and large enough in a short profile to outrank everything real.

```
perl bench/nytprof-digest.pl nytprof.out            # library / sub / line, ranked
perl bench/nytprof-digest.pl nytprof.out --self skeid   # only our own code
perl bench/nytprof-digest.pl nytprof.out --json     # same data, machine-readable
perl bench/nytprof-digest.pl nytprof.out --keep-idle --keep-startup   # raw view
```

The library grouping is the first thing to read, because the usual finding is not "this sub is
slow" but "this cost is not ours":

```
active       38.360s of CPU in 9438 subs -- every share below is of this
waiting     128.091s in the event loop (idle, not cost)
startup       0.912s compiling and importing (paid once, excluded)

library          excl s   share        calls
mojo             31.611   82.4%      4087392
skeid             3.342    8.7%       295676
```

## What the first run found (2026-08-15, streamed and JSON separately)

| | JSON path | streaming path |
|---|---|---|
| CPU per request | 14.4 ms | 95.9 ms |
| Mojolicious | 67.6% | 82.4% |
| Skeid's own code | 14.3% | 8.7% |
| `Mojo::EventEmitter::emit` calls per request | 37 | **627** |

A streamed request costs six times what a JSON one costs, and the reason is visible in the call
counts: every one of the 64 upstream chunks is parsed, emitted and written individually, so
`Mojo::Message::parse`, `Mojo::Server::Daemon::_write` and `emit` are each called tens of
thousands of times. Skeid's own hottest code is the upstream chunk handler in
`Proxy.pm` (~4% of the streaming path) — which is the right place for it to be.

**The conclusion to draw from a result like that is not "optimise Skeid's translator".** It is
that the remaining cost lives in per-chunk framework work, and the only lever that moves it is
doing fewer, larger writes — which trades against inter-token latency, a number `llmbench`
does not report yet (only TTFT and total). Measure both sides before touching it.

## Reading patterns — what each shape means

The numbers below are shares of *active* CPU (i.e. not the event loop and not startup), not
absolute seconds.

| Finding | Shape | Likely cause | Likely fix |
|---|---|---|---|
| `mojo` share >70%, `skeid` <15% | Framework dominated | Most of the request path is per-chunk emit/parse/write | Look at write buffering; check whether you're doing more `headers->header($n => $v)` calls than you need |
| `skeid` share >40%, hot sub in `Proxy.pm` or `Protocol/Anthropic/Stream.pm` | Translator dominated | A per-chunk operation in Skeid's path that runs every emit | Move it out of the chunk loop, or batch |
| One sub at >30% in isolation | Single hotspot | A naive O(n²) over headers / messages / tokens | Replace with a single-pass pass; cache the result |
| `calls` per request >100 on a sub that should run once per request | Loop amplification | A loop that re-invokes framework code per item | Pre-resolve once, reuse the resolved value |
| `idle_s` > 80% of total and `active_s` small | Server-bound, not CPU-bound | The CPU is waiting on fakellm or the network; NYTProf makes the wait last longer but the active cost is the same | This is not a finding — it is a healthy profile under load |
| Big jump in one bucket between JSON and stream profiles | Mode-specific cost | Something only the streaming path pays | Compare the line-level output of both profiles; the line that appears in stream and not in JSON is the candidate |

## Comparing before/after

A profile is an opinion about where the cost is; it becomes useful when you can answer "did
this change move the cost?". Run two profiles, diff the buckets:

```bash
# baseline
perl bench/nytprof-digest.pl nytprof-before.out --json > before.json
# apply the change, run again
perl bench/nytprof-digest.pl nytprof-after.out --json > after.json
python3 - <<'PY'
import json
b = {x['name']: x for x in json.load(open('before.json'))['buckets']}
a = {x['name']: x for x in json.load(open('after.json'))['buckets']}
for k in sorted(set(b) | set(a)):
    bs, as_ = b.get(k, {}).get('share', 0), a.get(k, {}).get('share', 0)
    delta = (as_ - bs) * 100
    print(f'{k:10s}  before {bs*100:5.1f}%  after {as_*100:5.1f}%  Δ {delta:+5.1f}pp')
PY
```

Bucket deltas in percentage points are stable under NYTProf's distortion; absolute seconds
are not. The question to ask after a change is "did this bucket get smaller, by how many pp,
and did anything else get bigger?". If `skeid` shrank and `mojo` grew, you traded framework
work for your work — sometimes the right answer, sometimes a step sideways; the numbers
answer.

## Discipline

Same as the benchmark rules: one profiling run at a time, `taskset`, bind to localhost, clean
up the process you started. Profiles are large — write them to the scratchpad, never into the
repo, and delete them when the finding is written down.
