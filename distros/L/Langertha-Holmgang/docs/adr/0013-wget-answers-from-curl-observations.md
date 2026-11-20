# ADR 0013 — wget is answered from a case's curl observations

- Status: accepted
- Date: 2026-11-19
- Source: the maintainer, 2026-11-19 ("make the local HTTP answers"); the gaps and calls recorded
  in the runs of 2026-11-03, 2026-11-18 and 2026-11-19
- Tags: world, observations, linux, http, fairness

## Context

Cases describe what a local application answers over HTTP by an observation on `curl`
(`match: { command: '\A\s*curl\b…:8001' }`). On the simulated Debian `curl` is not installed
unless the case says so, and models reach for `wget`. The observation did not match, the call
went to the simulator, and the simulator — which knows no listener for that service — answered
"Connection refused" for a service the case's own journal shows running. That is not a gap but a
wrong answer, and it sends a model after a fault that is not there. Twenty cases of the measured
suites answer `curl` this way and not `wget`.

## Decision

- A `wget` no observation matches is tried once more as the `curl` it stands for
  (`curl -s [-k] [-H '…'] URL`). If an observation answers that, `wget` gets the same answer in
  its own words.
- **Only where the answer follows from the body:** the document goes to standard output
  (`-O-`, `-qO-`, `-O -`, `--output-document=-`). `-q`, timeouts, tries, `--header` and
  `--no-check-certificate` are understood; a pipe after it filters the body.
- **In wget's words.** A curl error in the observation's output becomes wget's: 7 "Connection
  refused", 28 "Connection timed out", 6 "unable to resolve host address", 22 "ERROR nnn". A
  body that is an error page (`<title>502 Bad Gateway</title>`) is "ERROR 502: Bad Gateway." —
  wget prints no body for a status from 400 on. Silent with `-q`, and failed.
- **Untouched:** `-S`, `--spider`, `-O FILE` and a plain `wget URL` (the answer needs a status
  line or writes a file, and an observation never changes the state), `--post-data`, any
  option this does not know, a command with `;`, `&&` or a redirection, and every `wget` an
  observation of its own answers.

`Langertha::Holmgang::World::_observe_wget`.

## Consequences

- A case author writes the HTTP answer once, for `curl`; both clients get it. A new case needs
  no second observation for `wget`.
- The forms left out still go to the simulator and can still get its wrong "Connection
  refused" where a service has no `listen`. The remedy there is in the case: give the service
  `listen` and, where it matters, an `http` entry on the device.
- A body that is an error but carries no `<title>4xx/5xx …</title>` is shown as a success.

## Not decided

- Deriving listeners (`ss -tlnp`, a bare connection probe) from the observations of a case.
