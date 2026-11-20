# ADR 0011 — A sandbox for real programs the simulator does not model

- Status: accepted
- Date: 2026-11-19
- Source: the maintainer, 2026-11-19 ("pull software in: a simulated world in which we overlay
  the decisive points ourselves"; Docker for a start); the first full run with the `holmgang`
  CLI (2026-11-18), ADR 0002 (deterministic grading at the end state)
- Tags: simulators, sandbox, docker, sim_gap, determinism

## Context

The Linux simulator models every command in Perl. A real program it does not model is a
`sim_gap`: an empty answer, and a case that then fails is `uncertain`. In the first full run a
gap was hit in about one repetition in four of three operations suites. Almost all of them were
the same few programs: `python3 -c` (49 of 80 gap calls in six suites), `awk` scripts past the
filter grammar, `perl -e`. A model that reaches for Python to edit a JSON file or to compute a
value does nothing wrong, and no amount of Perl will model Python.

The house rule so far: a simulator touches nothing but its state, because it executes model
output and delegating to the host would run that output for real.

## Decision

- **A sandbox is an optional backend, not a simulator.** `Langertha::Holmgang::Simulators`
  carries an optional `sandbox`; it reaches a simulator in the call's context. The Linux
  simulator hands it exactly the command that would otherwise be a gap. The simulated shell
  stays: pipes, redirections, variables, chains and every modelled command are the
  simulator's, and only the one unmodelled program runs for real, with the input the
  simulated pipe gives it.
- **The simulation overlays, the sandbox fills in.** The sandbox never answers for something
  the simulation knows better. A command goes there only when the program is on a fixed list
  of interpreters and text tools (`python3`, `perl`, `awk`, `sed`, `jq`, `sort` …) or a script
  of the device with such an interpreter, runs as root on the device itself, and names nothing
  only the simulation knows: no other process, no network or database client, no `/proc`,
  `/sys`, `/run`, no account or disk query, no file the state only describes by its size, no
  file the simulator derives. Anything else stays the gap it was.
  (`Langertha::Holmgang::Sim::Linux`, "SANDBOX".)
- **Never the host.** `Langertha::Holmgang::Sandbox::Docker` runs the program in a container
  made for the call and removed after it: no network, all capabilities dropped but the three
  that unpacking files as root needs, no new privileges, bounded memory, processes and time,
  **no host directory mounted**. The device's files go in as a tar stream and the result comes
  back as one. The house rule changes from "no shell-out" to: a simulator leaves its state only
  through a sandbox handed to it, never by itself and never onto the host.
- **Opt-in per run, never in loading.** `holmgang run --sandbox docker|podman
  [--sandbox-image IMAGE]`. No loader, lint or test registry has a sandbox: a case loads,
  lints and replays the same with and without Docker, and a reference solution must still
  pass without any gap. Format 2 is untouched (ADR 0004).
- **What comes back.** Output (standard output and error in one text), exit status, and the
  files that changed, appeared or went away, written into the device's state — so the end
  state is graded as always (ADR 0002). A program missing from the image, a result past the
  bounds or a container that does not start leaves the gap, with the reason in its text.
  Nothing is ever guessed.
- **The clock and the name are the simulation's.** The image carries libfaketime; the program
  sees the simulation's time and the device's host name.
- **Marked in the report.** A call whose programs ran for real carries `sandbox: N`; the
  report's `generator.sandbox` names runtime, image and image id. Both fields exist only when
  a sandbox was used, so a report without one is byte-for-byte what it was (ADR 0006).
- **The image.** `share/sandbox/Dockerfile`: Debian 12 with the listed programs, tag
  `langertha-holmgang-sandbox:1`.

## Consequences

- Determinism now also rests on the image. The same image id gives the same output; a rebuilt
  image may not. A run names the id; comparing runs across image ids is comparing across
  simulator versions.
- A run with a sandbox and one without are different measurements: a model that used Python
  got an answer in one and an empty line in the other. Reports say which it was.
- The call blocks its process for the life of the container (about 0.4 s here). With
  `--concurrency` above 1 the other slots wait that long.
- Known limits, deliberately left as gaps: programs that probe the network (`python3` with
  `socket`, `urllib`), `openssl s_client`, `wget`/`curl` against simulated services, version
  queries of programs the image does not carry (`node -v`, `promtool --version`). They belong
  in the simulator or in a later step (real services behind the simulated ones).
- A program that would fail on the simulated device for a reason only the simulation knows —
  a full disk, a read-only mount — succeeds in the sandbox. Cases built on such a condition
  should keep the affected path out of reach (a file described by its size already is).
- Measured on the calls of the 2026-11-18 run, replayed against the same cases: 80 gap calls
  without the sandbox, 38 with it; repetitions with at least one gap 24 → 13. What remains is
  the list above.

## Not decided

- Real services (PostgreSQL, a Kubernetes API server) behind the simulated commands, and real
  `git`/`openssl` instead of their Perl models. This ADR covers only the fallback for gaps.
- Whether lint may ever use a sandbox, so that a reference solution could use Python.
- bubblewrap or another runtime without a daemon.
