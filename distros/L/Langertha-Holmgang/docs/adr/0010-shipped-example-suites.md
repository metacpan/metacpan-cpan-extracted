# ADR 0010 — Example suites shipped under `share/suites`

- Status: accepted
- Date: 2026-11-06
- Source: k22; ADR 0003 (engine public, cases private), CONTEXT.md "Engine and cases apart"
- Tags: examples, sharedir, packaging

## Context

ADR 0003 promises a handful of small example suites to learn from, deliberately no real
measurement cases. They should ship in the CPAN distribution and be findable after
installation, so a user can lint and dry-run something without writing a suite first. The
choices below are the worker's (k22), not the maintainer's.

## Decision

- **Place.** Each example suite is a format 2 directory under `share/suites/<id>/`. The
  `[@Author::GETTY]` bundle's `@Basic` already carries `[ShareDir]`, which installs `share/`
  as the distribution's share directory (with `File::ShareDir::Install` as a configure
  requirement); `dist.ini` stays unchanged.
- **Finding them.** No helper and no new public name: after installation the directory is
  `File::ShareDir::dist_dir('Langertha-Holmgang')` plus `suites`; in a checkout it is
  `share/suites`. `File::ShareDir` becomes a runtime requirement so the documented lookup
  works. `holmgang lint <dir>/suites` lints all of them (a directory of suites is accepted
  since ADR 0009).
- **The set.** `demo-linux` (a `linux` device, `run_command` and `write_file`),
  `demo-lamp` (a world without devices, its one tool described by handlers) and
  `demo-haystack` (a message made by `generate`, `::Haystack`, with one planted line).
  Format 2 only; DSL examples follow the DSL (k18). Topic `demo`.
- **No example for an answer-world plugin.** The built-in answer world `kueche` gets no
  example suite: its domain is that of an existing measurement, and even an
  independently invented task there comes too close. A shipped example of a typed answer
  world (`Role::AnswerWorld`) would need a world of its own first.
- **Content.** Freely invented for this distribution — no scenario, prompt, host name,
  solution or seed taken from or modelled on cai-platform's or any private suite. Names
  use `example.org`/`example.net` and the RFC 5737/3849 documentation addresses.
- **Origin and license.** Each `suite.yaml` starts with a comment naming origin, author
  and license, and carries `license: Perl_5` and a `source` with the same.
- **Held by a test.** `t/share_suites.t` loads every shipped suite (lint is part of
  loading) and runs them through the command line: `mock-solution` passes every case,
  `mock-text` fails every case. It reads the `share/` next to `t/`, so it runs from the
  checkout and from the build directory, without a network.

## Consequences

- A change to a simulator or to lint that breaks an example suite fails this repo's tests.
- An example suite is public by design and therefore useless as a measurement; it must
  never be copied into a private suite as a real case.

**Amendment 2026-11-11 (k27).** A fourth example, `demo-sehen`: one case whose user message carries an image (`img/ablauf.png`, a three-step flow chart `START -> PRUEFEN -> ENDE`, 770×160 grey PNG drawn by a throw-away script for this distribution with its own 5×7 pixel font — nothing taken from cai-platform or any private suite), handed in through the answer world `sehen` (`Langertha::Holmgang::Sim::Sehen`, k27). Chosen by the worker in the overnight run because the card's acceptance asks for "Lint grün mit Beispiel-Suite (synthetisch, öffentlich unbedenklich)". This narrows "No example for an answer-world plugin": `sehen` is a world of its own, and the example is kept generic and trivial (an invented three-node chart, no receipt, table, chart or screenshot task, no wording of a real case), so it shows the shape of an image case without coming close to a measurement. `t/share_suites.t` holds it like the others; through the CLI the `mock-solution` mock passes it after the vision pre-check, which lets the mock through unmeasured (ADR 0006 amendment k27).

**Amendment 2026-11-11 (k43).** A fifth example, `demo-roost`: two cases in a typed answer world plugin of its own, `roost` (`Langertha::Holmgang::Sim::Roost`, `Role::AnswerWorld`) — an invented dragon roost with dragons, perches and a larder, tools `survey_roost`, `feed_dragon`, `move_dragon` (English, for an international audience). This closes "No example for an answer-world plugin": the world was built for the example, so no example is needed for `kueche`. The domain was chosen by the worker in the overnight run after reading only the titles of the private suites and the CONTEXT.md categories, to be unrelated to all of them (no operations, tool choice, mail/tickets, personal data, kitchen or image task). The world does not judge: a dragon eats whatever it is given and flies to a perch too small for it, so the rules alone grade and no answer hints at a fix. Each case has wrong solutions that lint proves fail. `t/share_suites.t` holds it like the others (5 suites, 7 cases).

**Amendment 2026-11-11 (k50).** A sixth example and the first in the case DSL, `demo-beacons`: a `suite.pl` (ADR 0007) whose three cases a `generate seed => 1066` block builds — an invented chain of hill beacons (six made-up hill names), one tool `light_beacon` described by a handler, each case asks to light two hills and leave the rest dark; wrong solutions (only the first, a third hill instead of the second) that lint proves fail. Chosen by the worker in the overnight run, after reading no private case: the domain is unrelated to the private categories and to the earlier examples (no operations, mail, personal data, kitchen or image task). The place rule above extends to it: an example suite directory holds `suite.yaml` with `cases/` **or** `suite.pl`; the origin/author/license comment heads `suite.pl` as it heads `suite.yaml`, and `license`/`source` are written with the keywords. `t/share_suites.t` holds it like the others (6 suites, 10 cases) and also checks that another seed (`Loader->seeds`) gives other cases and that its YAML export (k19) loads with the same digest. No exported YAML copy is shipped beside it: the export is what `holmgang export-yaml` writes, a second copy would only drift.
