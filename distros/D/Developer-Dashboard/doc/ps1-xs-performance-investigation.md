# d2 ps1 XS Performance Investigation

## Decision

No `d2 ps1` Perl routine was converted to XS. Cold and warmed command-level
measurements against the installed 6.03 baseline were effectively unchanged.
The measured speed ratios ranged from 0.982x to 1.027x, which is within run
noise and far below the requested 2x threshold. The profile also showed that
the dominant costs are not a single expensive Perl routine suitable for an
API-preserving XS replacement.

## Expected outcome

An XS candidate must preserve the existing `Developer::Dashboard::*` API and
prompt output, pass parity tests, and produce a repeatable improvement. A
candidate is worth retaining only if profiling attributes enough elapsed time
to it to make the overall `d2 ps1` command at least twice as fast as 6.03.
Otherwise, keep the pure-Perl implementation and record why the conversion is
not justified.

## Runtime paths examined

The command enters through `d2`, passes through the thin `dashboard`
switchboard, and is handed to the staged private `ps1` helper. The helper has
two loading paths:

- When the switchboard supplies the repository library root, it avoids
  `FindBin` and uses the supplied path.
- When run standalone without that root, it loads `FindBin` and discovers the
  library relative to the helper.

The helper parses canonical options with `_parse_ps1_options_fast`; abbreviated
or non-canonical forms use `Getopt::Long`. It then constructs the layered path
registry, configuration and indicator store, optionally synchronises collector
definitions, refreshes core indicators, and renders either the shell prompt or
the requested tmux status line. Prompt rendering includes current directory,
ticket context, branch lookup, job count, and (unless suppressed or delegated
to tmux) indicator formatting.

## Reproduction and measurements

The command-level comparison used the same host and isolated 6.03 installation
and exercised eight routes, with 20 repetitions per route. The table shows
median milliseconds per invocation and the ratio `6.03 / 6.05`; a ratio above
1.0 favours the current implementation.

| Route | 6.03 | 6.05 | Ratio |
| --- | ---: | ---: | ---: |
| Default, fresh process | 111.23 | 110.23 | 1.009x |
| Default, warm state | 110.06 | 109.19 | 1.008x |
| Extended, fresh process | 112.80 | 114.89 | 0.982x |
| Extended, warm state | 109.57 | 109.27 | 1.003x |
| No indicators, fresh process | 113.29 | 110.28 | 1.027x |
| No indicators, warm state | 110.73 | 110.02 | 1.006x |
| Tmux status top, fresh process | 109.97 | 111.11 | 0.990x |
| Tmux status top, warm state | 112.50 | 109.93 | 1.023x |

NYTProf attributed approximately 86-94 microseconds to `Prompt::render`, about
21 microseconds to the fast option parser, 35-36 microseconds to `_git_branch`,
and about 350 microseconds to collector work. A home-runtime filesystem probe
was about 2.17 milliseconds in the baseline and 63 microseconds in the current
source. Even eliminating the entire baseline probe would yield only about a
1.02x command-level ceiling. POSIX module loading at about 4.34 milliseconds
is already implemented in XS and is not a Perl conversion candidate.

## Conclusion and verification

The evidence does not support selecting a Perl routine for XS: the main prompt
renderer and parser are too small a share of total startup, while the larger
costs are process startup and system/library work. Replacing these small
routines would add build and portability complexity without a plausible route
to the 2x target. No `d2 ps1` runtime behavior was changed for this
investigation.

The regression tests also isolate prompt comparisons from inherited ticket and
tmux environment variables. The full non-instrumented test run passed 285 files
and 25,941 tests. The canonical instrumented coverage gate passed 285 files
and 25,900 tests with 100.0 statement, branch, condition, and subroutine
coverage across `lib/`, with no stale uncoverable annotations. The prompt
environment-isolation test and HTML attribute fallback regression are included
in those results. The release kwalitee gate passed 7 of 7 checks, the
post-build extracted-dashboard Docker guard passed 7 of 7 tests, and the
blank-container `cpanm` installation without `--notest` plus the documented
installed-runtime integration completed successfully for 6.05.
