# Sibling location predicates vs `Geo::Location::Predicate`

The six sibling geocoders that need the "could this be a location?" rule - CA,
DataScienceToolkit, GeoApify, List, Postcodes and XYZ - are fuzzed against the
rule `Geo::Location::Predicate` holds (`_valid_location`), over randomly
generated scalars, references and `undef`.  They used to carry copies of it; they
now call it, so what this measures is that the call is the whole of their
answer.

The harness is
[scripts/location-predicate-fuzz.pl](scripts/location-predicate-fuzz.pl),
where it lives so that the scheduled job below and the distribution that owns the
rule release together.  It does not re-implement any predicate: it drives each
real `geocode()` with a user agent that dies the moment a lookup would be made,
so a verdict is "refused before the lookup" or "let through", and it never
touches the network.  It needs the six checkouts beside `Geo-Coder-Free` - the
layout this workspace has - finds them from its own path, and says so rather than
skipping when they are not there.  The run below is
`perl scripts/location-predicate-fuzz.pl --iterations 20000` with
the default seed (20261017), so it is reproducible.

## What it found

Nothing.  On this run all seven give the same verdict on every one of the 20,000
generated values and on every curated class: `undef`, `''`, `'0'`, digit strings
(ASCII and Unicode) and every reference are refused; anything with a non-digit in
it is let through.  There is no class where the six disagree with the rule or
with each other.

That was not true of the first run of this harness.  It found that the six
tested the *string* a reference turns into - `ARRAY(0x...)` contains a non-digit
- so every reference was accepted and a query was built from it, and that XYZ
was worse still: it handed `\@_` to `Params::Get`, whose two-element shorthand
only unwraps a plain string, so the predicate was shown `['location', $ref]` and
XYZ accepted even a reference that prints as digits or whose boolean is false.
Those findings are what the section below describes the fix for.

## What had to change

Each `geocode()` now asks the one rule and decides nothing itself:

    # What counts as a location is Geo::Location::Predicate's answer, not a
    # second copy of it here: undef and the empty string are nothing to look up, a
    # reference is not a location however it would print, and a string of digits is
    # what a numeric column holds when the wrong one has been read.
    if(!_could_be_a_location($location)) {
        Carp::croak('Usage: geocode(location => $location)')
            unless(defined($location) && length($location));
        Carp::croak('Usage: ', __PACKAGE__, ': invalid input to geocode(), ',
            ref($location) ? 'a reference is not a location' : $location);
    }

`Geo::Location::Predicate` is a distribution of its own, declared by each of
the six as a recommendation for runtime in its META rather than as a
prerequisite, and the rule is called by name rather than imported: an import
copies the code reference into the caller's package, and then a test could not
swap the rule for a spy to prove that it is the rule being consulted.  Each of
the six has one `_could_be_a_location()` that asks the rule when it is installed
- on the first call, not when the module loads - and falls back to refusing a
reference when it is not, so there is no inline digits test left anywhere and the
six cannot drift from the facade - or from each other - by editing one copy.  `Geo-Coder-Free/t/location-rule.t` scans the six
siblings' `lib/` for the rule's spellings with the same code it uses on its own,
and fails if one comes back; a copy was planted in `Geo::Coder::XYZ` to check
that the scan bites.

Five smaller things came with it:

- **XYZ** now passes `@_` to `Params::Get` rather than `\@_`, in `geocode()` and
  in `reverse_geocode()`, so the value reaches the checks instead of the argument
  list standing in for it.  `geocode([])`, which used to croak from `Params::Get`,
  now refuses the reference as it should.
- **A false boolean object** is refused for being a reference, not for being
  false.  DataScienceToolkit, GeoApify and XYZ used to reach `$location or croak`
  first, which gave a different message; the reference check now comes before that
  test, so all six refuse it the same way.
- **The digits guard** tests `$location`, the value that is actually sent, rather
  than `$params->{location}`.  It used to see a dereferenced scalar reference as
  `SCALAR(0x...)` and let `\'0044'` through while sending `0044`.
- **A scalar reference** is still dereferenced: `Params::Get` documents
  `foo(\'text')` as meaning the string, and all six now do it in every calling
  form, so `geocode(\'Ramsgate')` and `geocode(location => \'Ramsgate')` mean the
  same thing everywhere.  It is a way of passing a string, not a reference that
  reaches the rule.
- **The test** is `t/reference.t`, one file installed identically in all six
  distributions.  It finds the distribution it is running in from its `lib/`, so
  there is nothing to edit when it is copied, and it drives each module with a
  user agent that dies at the lookup.  Twenty-four subtests: six reference classes
  refused without reaching the lookup, a location still let through, digits still
  refused, both scalar-reference forms still passed through, and - when
  `Geo::Location::Predicate` is installed - the rule shown to refuse each class
  and then swapped for one that accepts, which proves the module really consults
  it rather than carrying its own answer.

The tests pass in each distribution with `Geo::Location::Predicate` installed.
With it hidden they still pass: the rule is a recommendation in each of the six,
not a prerequisite, so `t/reference.t` falls back to what a module can say alone
- a reference is refused - and skips the comparisons it cannot make, naming the
missing rule.  That is the behaviour the suites job below asks for, and a pass
with no skip is what it rejects: a gate that cannot tell the rule was gone is a
gate that is not reading it.

## The scheduled runs

The same question is asked on a schedule by eight jobs: one for the workspace,
one for the rule's own repository, and one for each of the six.  The workspace's
job first:
[.github/workflows/location-predicates.yml](.github/workflows/location-predicates.yml)
runs daily, on demand, and on every push and pull request to that distribution,
against a workspace of the eight checkouts - the rule's own checkout among them,
since the rule is a distribution of its own from 0.48.  It installs what the six
load and then runs

    perl scripts/location-predicate-fuzz.pl --iterations 20000 --check

The exit status is the verdict as well as the report, and it is the verdict on a
plain run: a sibling whose answer on any value - a scalar, a reference or `undef` -
differs from the rule's fails the harness, and the run names the class or the value
on both streams - the
Markdown report, which the job puts in its summary, and stderr, which stays in the
log.  Nothing has to be remembered to get that: the gate being the default is what
makes the harness usable as a regression check wherever it is run.  `--report`
(`--no-check`) is the explicit report-only form, for a caller that wants the table
and the exit status left at 0 - it labels the finding `REPORT` rather than `FAIL`
and says in the report that it was asked not to fail.  `--check` is still accepted
and is what the jobs below pass, at the call site, for a reader who should not have
to know which form is the default.

`--summary=FILE` writes the same run as JSON: the seed and the iteration count,
the rule that answered and the file it was loaded from, the siblings graded and
the ones `--sibling` left out, the verdict on every curated class for every
sibling, the counts the randomised run produced, and the gate's verdict with each
disagreement as a record giving the class or the value, the sibling, what it
said and what the rule said.  The report is a rendering of that data, and a
rendering is free to be reworded, so anything that has to assert what a run found
wants the data - which is why the test below reads this and not the Markdown.  It
is a file rather than a stream because stdout is the report: JSON appended to
Markdown is neither readable nor parseable.

The job then runs `prove -lr t/location-fuzz-doc.t`, which is the sample check
below: it has the eight checkouts, so the file runs there instead of skipping as it
does when this distribution is tested on its own.  A report that has changed
without the sample changing is a failure in the job that prints the report, rather
than a diff nobody sees until the next edit.

A change to the rule itself is a pull request to the repository that holds it,
and a workflow only runs in the repository its event happened in, so
[Geo-Location-Predicate's copy](https://github.com/nigelhorne/Geo-Location-Predicate/blob/master/.github/workflows/location-predicates.yml)
carries the same job for that event: on a pull request there, the rule in the
branch is what the six are asked about, so a rule that disagrees with them fails
before the merge rather than on the next daily run of the other repository.  What
makes the branch's rule the one under test is the harness: it puts the eight
checkouts' `lib/` ahead of everything else on `@INC` and then refuses to run if
the file that loaded is not the rule's checkout, so a run cannot quietly grade
the six against an installed release - which is the one way this gate could pass
for the wrong reason.

Each of the six geocoders carries that job in its own repository too, told which
sibling it grades: `--sibling Geo-Coder-CA` there, and the same in the other five,
each on its own daily schedule, staggered so their failures do not arrive in one
minute.  The point is ownership rather than coverage: the drift this looks for is
a change in one of the six, so the distribution that would have to fix it should
hear about it in its own pipeline instead of on the next run of a repository it
does not ship - and a divergence in a sibling it does not ship must not turn its
job red.  `--sibling` takes either spelling - the distribution, which is what the
job's own checkout is called, or the module - and can be repeated, so one job can
grade two siblings where a pair is what changed.  A restricted run says so in its
report: it lists the sibling or siblings it graded and names the ones the flag
left out, so a green job in Geo-Coder-XYZ is a claim about `Geo::Coder::XYZ` and
about nothing else.  It is also cheaper than it sounds - the named siblings are
the only ones loaded and constructed, so that job installs one distribution's
prerequisites and none of the other five's, and a dependency one of them has gone
missing cannot fail it.

This is the half that catches drift rather than the shape of the code.
`Geo-Coder-Free/t/location-rule.t` reads the six siblings' source for the rule's
spellings and fails when one spells it out again, but it cannot see a sibling
that still calls the rule and yet no longer refuses what the rule refuses, or one
that has moved its predicate behind some other test.  Neither can it see a
sibling whose `geocode()` gets a different value from the one it passes on - the
`\@_` form that put `['location', $ref]` in front of the predicate is exactly
that - and a verdict is what the fuzz reads.  The run is also a register of what
the rule currently answers: the report names every class, so a change in the rule
with no change in the six shows up in the summary as a diff against the table in
this file.

A reference disagreement fails the job as well.  A reference is a value the rule
decides on like any other: the six refuse one for being a reference, so a copy
that accepts it has left the rule whatever the value would stringify to, and the
same question is asked of the digits, the empty string and `undef`.  The gate no
longer excludes the reference classes; `t/reference.t` in each sibling checks
that a reference is refused, and this run checks that each sibling still answers
what the rule answers when one is handed to its `geocode()`.  A verdict the
harness cannot read at all (`ERROR`) is not agreement with the rule and does fail
the job, which is the point of reporting it separately.

That the exit status does this is checked rather than assumed:
[t/location-predicates.t](t/location-predicates.t)
runs the harness on this workspace, where it has to pass, and again on a copy of
it with one sibling's guard replaced by a test of its own.  The copy in which a
string of digits is no longer refused has to fail and name the sibling, the class
and both verdicts; the copy in which a reference is accepted has to fail as well,
naming the sibling, the class and both verdicts.

What that file asserts on is the summary each run writes with `--summary`, not
the report it prints: the counts, the per-class verdicts and the gate's own
verdict are read as data.  A reworded report therefore no longer fails a test
that is about the rule, and a report that says something else no longer passes
one.  The two places it does read the report are there to check that the two
renderings are of the same run - the number on the gate line is the number in the
summary - and that stdout is still the report the job feeds its summary from.

## The six suites, and the rule taken away

[.github/workflows/geocoder-suites.yml](.github/workflows/geocoder-suites.yml)
runs on every push and pull request, weekly and on demand.  It assembles the same
eight checkouts and runs four things: each sibling's **whole suite** (`prove -lr
t` in `workspace/<dist>`, with the rule's `lib/` and this checkout's `lib/` first
on `@INC` so the rule under test is the one in the checkout and not a released
copy), the shared `t/reference.t`
in each of the six - after a byte comparison of the six copies, because "one file
installed identically in all six" is a claim about six files that only a
comparison can check - and the fuzz above with `--check`.

The fourth is a negative control, with `Geo::Location::Predicate` hidden by
`Devel::Hide`, and it asks two different things of the two halves: the six
`t/reference.t` files must pass, having skipped the comparisons they cannot
make, and the fuzz must fail.  The fuzz has no fallback - its whole question is
what the six answer compared with the rule - so a run that reports agreement
with a rule that is not there is one that is not reading it.
Hiding is not enough for the fuzz, because the harness puts the checkouts' `lib/`
directories on `@INC` itself and an `@INC` directory outranks the hook hiding
installs; for it the rule's file is also left out of a copy of the workspace, and
that copy must refuse to run rather than report that six modules agree with each
other about nothing.

The six suites are six jobs, one per sibling, and they run at the same time: a
sibling that fails is reported when it fails rather than after the five behind it
in a loop, which is the difference between knowing which of the six broke and
knowing only that one of them did.  Each of those jobs assembles only what its
sibling loads - this checkout, the rule's and its own - which was checked by
running all six suites against exactly those three checkouts.  The checks that
need all six at once - the byte comparison, the reference runs, the fuzz and the
negative control - are a second job that starts once the six have reported,
including when some of them have failed, and each of those checks reports on its
own account rather than the job stopping at the first failure.

Two details of the six that the jobs have to work around, both of which were
verified on this workspace rather than assumed:

- The checkouts carry `t/online.enabled`, the marker `Makefile.PL` writes when
the build machine has a network.  A suite that has one sends its tests to
geocode.xyz, which answers `403 Forbidden` to a runner; the marker is removed
before each suite runs, and those tests skip as they do on a machine with no
network.  Left in place the job would be graded on that endpoint's policy
against automated clients rather than on the rule.
- The six suites are run without `AUTHOR_TESTING`, so each distribution's author
tests (pod, critic, kwalitee, links) are that distribution's own CI's business.

## Limitations

- The predicate is a call to `_valid_location()` inside `geocode()`, so the
  harness crosses the guard chain by running the real method and stopping it at
  the network boundary.  A verdict is "refused before the lookup" or "let
  through"; it does not read the call out of the source and make it itself.
- `Geo::Coder::Postcodes` rejects some addresses *after* the location predicate
  ("Postcodes.io only supports towns, not full addresses").  That counts as the
  predicate accepting the value.
- `Geo::Coder::List` reports its `undef`/`''` rejection through its logger, and
  with no logger through `Carp::carp`.  Either way it returns before the lookup,
  which is what the harness records; only the diagnostic differs.
- The rule is consulted by name at run time, which is what lets `t/reference.t`
  swap it for a spy.  An import would capture the code reference once: it would
  still work, but a geocoder that imported it could not be tested that way, which
  is why the six call `Geo::Location::Predicate::_valid_location()` in full.
- `Geo::Coder::DataScienceToolkit->new(ua => $ua)`, the form its own POD shows,
  used to die in `Object::Configure` (`Not a HASH reference`), so the shared test
  built that distribution with `new()` and installed its user agent afterwards.
  The constructor takes its arguments as the hashref `configure()` wants now -
  `t/10-new.t` covers both spellings and a lookup through the agent it was given
  - so the shared test calls the documented form, handing the stub agent in as
  `ua`.  A constructor that rejects that call is now a finding rather than
  something the fallback hides: the test fails once, naming the module and
  repeating the constructor's own diagnostic, and only then falls back to a bare
  `new()` with the agent set directly, so the reference answers are still
  checked.  If the bare object cannot be built either, the file bails out with
  the same message instead of skipping.  Only Geo::Coder::GeoApify is given more
  than `ua`: its POD documents a required `apiKey`, and a `host` of localhost,
  which keeps a run that somehow used another agent off the service.
- The random generator covers scalars, numbers, `undef`, unblessed references
  and blessed references with `""`/`bool` overloads.  Tied variables, values
  whose string form changes between calls, locale-dependent `\d`, and objects
  overloading `qr` or `~~` were not fuzzed.
- The scheduled job is in `Geo-Coder-Free`, which owns the rule, and it checks
  out the six from their default branches.  A sibling that has drifted but not
  been pushed anywhere is not in it; a sibling that has been pushed is, without
  anything having to be pushed here.

## The run

What a run prints, verbatim, on this workspace at the seed above - the whole
report is Markdown, so the job puts it straight into its summary.  It is not
written here, or edited here: one command rewrites it from a real run,

    perl scripts/location-predicate-fuzz.pl --iterations 20000 --update-document

which replaces everything from `## Harness output` to the end of the file - or to
the next `## ` section, if one is added after it - with what that run printed,
and leaves the prose above it alone.  It writes nothing when the run fails, since
what is quoted below is a run that passes, and it says on stderr whether it
rewrote the file or found it already right.  A file name can be given
(`--update-document=PATH`) to write a copy instead.  So updating the sample after
a wording change is one command and cannot be done by hand:
`t/location-fuzz-doc.t`, which the workspace job runs, checks it with the same command,
compares the two byte for byte and names the first line that differs, and runs
`--update-document` on copies of this file - one with a table cell changed by
hand, which it has to put back, and one with a section added after the sample,
which it has to leave alone.  A sample that has drifted, or that someone has
edited, fails the suite instead of describing a run that no longer happens.

## Harness output

Six sibling geocoders, each asking `_valid_location()` from `geocode()`:

- `Geo::Coder::CA` - `Geo-Coder-CA/lib/Geo/Coder/CA.pm`
- `Geo::Coder::DataScienceToolkit` - `Geo-Coder-DataScienceToolkit/lib/Geo/Coder/DataScienceToolkit.pm`
- `Geo::Coder::GeoApify` - `Geo-Coder-GeoApify/lib/Geo/Coder/GeoApify.pm`
- `Geo::Coder::List` - `Geo-Coder-List/lib/Geo/Coder/List.pm`
- `Geo::Coder::Postcodes` - `Geo-Coder-Postcodes/lib/Geo/Coder/Postcodes.pm`
- `Geo::Coder::XYZ` - `Geo-Coder-XYZ/lib/Geo/Coder/XYZ.pm`

The reference rule is `Geo::Location::Predicate::_valid_location` (`Geo-Location-Predicate/lib/Geo/Location/Predicate.pm`).

Verdicts: `ACCEPT` means the predicate let the value through to the lookup (the stub user agent dies there, so no request is made); `REJECT` means it refused the value before that point.  The random seed is 20261017.

### Curated classes

| Input class | Predicate | Geo::Coder::CA | Geo::Coder::DataScienceToolkit | Geo::Coder::GeoApify | Geo::Coder::List | Geo::Coder::Postcodes | Geo::Coder::XYZ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| undef | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| empty string | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| zero | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| digits only | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| string with a non-digit | ACCEPT | ACCEPT | ACCEPT | ACCEPT | ACCEPT | ACCEPT | ACCEPT |
| unblessed reference | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| blessed reference, plain | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| blessed reference, stringifies to a location | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| blessed reference, stringifies to digits | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| blessed reference, false boolean, stringifies to a location | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| blessed reference, false boolean, stringifies to digits | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |

#### Where they disagree

- None: every curated class is answered the same way by the rule and every sibling under test.

### Randomised run

Generated 20000 values: 12058 scalars, 1965 undefs and 5977 references.

- Scalar/undef disagreements: 0.
- Reference disagreements: 0 distinct verdict patterns.
- Inter-sibling splits: 0 distinct verdict patterns.
- Unclassified errors: 0.

### Gate

- PASS: every sibling answers what the rule answers on every value.
