# Contributing

Report bugs and proposed changes in [GitHub issues](https://github.com/viasnake/Discord-Client/issues).
For bugs, include the Perl version, operating system, expected result and a small
reproducer. Remove tokens and authorization headers from examples and logs.

## Development

```sh
cpanm --installdeps .
prove -lr t
```

To install dependencies locally:

```sh
cpanm --local-lib-contained local --installdeps .
PERL5LIB=local/lib/perl5 prove -lr t
```

`Time::HiRes` 1.9764 or newer is required for Windows monotonic clocks.
TLS dependencies may require OpenSSL and zlib development libraries.

Use a short-lived branch for one change and open a pull request.
Use Conventional Commits. Write code, comments and developer documentation in
English. Keep REST, Gateway and Interactions separate and preserve the
`IO::Async`/`Future` API. See [Architecture](docs/DESIGN.md).

## Readability

Use descriptive names and explicit processing steps in code, examples and tests.
Split responsibilities into functions when that makes the flow easier to follow.
Comment each logical processing group in English. Explain its purpose,
ordering or constraints without repeating each statement.

Follow [perlstyle](https://perldoc.perl.org/perlstyle): separate logical groups
with blank lines and expand blocks containing multiple processing steps.
Keep simple accessors concise. Prefer early returns for invalid inputs and
completed cases so the main path does not accumulate nesting.

Give each function one clear responsibility. Compose the existing components
through explicit inputs and Future results; keep network access, scheduling
and application callbacks at their existing boundaries.

Use four spaces per indentation level, including continued statements.
Do not pad assignments, hash pairs, method definitions or comments to align
with adjacent lines. The formatter adjusts line breaks to a 120-column limit.

Install the pinned development tools, then check all Perl sources:

```sh
cpanm Perl::Critic@1.156 Perl::Tidy@20260826
perlcritic --profile .perlcriticrc lib t examples Makefile.PL
```

The enabled policy is `CodeLayout::RequireTidyCode`, using `.perltidyrc`.
CI runs the same command. Format a changed file with
`perltidy --profile=.perltidyrc --backup-and-modify-in-place path/to/file.pm`;
inspect the diff and remove the `.bak` file after checking it.
For dependencies installed under `local/`, use `PERL5LIB=local/lib/perl5` and
the tools in `local/bin/`. These are development tools, not runtime or
distribution-test dependencies.

## Tests

Use [Test2::V1](https://metacpan.org/pod/Test2::V1) with `use v5.26`,
`use warnings` and `T2->...` assertions. Use `is` for data, `ref_is` for object
identity and `dies` for exceptions. Import fixture helpers explicitly.

Test inputs, observable results and failure conditions. Name each scenario and
use fresh fixtures. Avoid assertions about private methods or object layout.
For bot scenarios, register handlers through `Discord::Client`, start the client
and deliver events through the test transport. Check replies, returned Futures
and shutdown. Keep focused component tests for protocol and resource limits.
Use fake transports and controlled clocks for protocol and cancellation tests.
Local HTTP/TLS tests exercise the real adapters using temporary, CA-signed
loopback certificates. Normal tests must not contact Discord or need credentials.
With controlled clocks, check Future
completion before inspecting a failure so a regression fails instead of hanging.

Update relevant documentation with code changes.
Record published releases in `Changes`; keep development notes out of it.
Run `prove -lr t` before submitting a pull request.

## Documentation

Keep public API documentation in each module's POD. Include a minimal example,
method arguments, return values and failure conditions. Link to related modules
and protocol sources where they are discussed. Do not duplicate API text in
Markdown. README covers installation and a first bot; `docs/DESIGN.md` describes
the architecture for maintainers.

Check edited modules with `podchecker` and read them with
`perldoc -T -F lib/Discord/Client.pm` (replace the path for another module).

## Workflows and releases

Update and check pinned Actions with `pinact run --update` and
`pinact run --check --verify-comment`.

Test and build the distribution:

```sh
perl Makefile.PL
make disttest
make dist
```

Distribution tests check CPAN metadata, shipped public packages and indexing
exclusions. Verify that installed POD is readable with `perldoc`.
Before release, confirm author/contact details and PAUSE permissions,
set the version, and verify CI and distribution tests. When publishing, record
the released version and date in `Changes`. The first entry only needs
"Initial release"; later entries describe changes since the preceding release.
CPAN uploads and GitHub publishing require explicit maintainer permission.
