# HTML::Anchor::Audit

An offline Perl library and command for checking section links in UTF-8 HTML articles. It reports missing `#targets`, repeated IDs and ambiguous references with line numbers, Unicode character columns and UTF-8 byte positions.

This is useful before publishing saved article HTML, including Gutenberg exports, or inside an editor/static-content pipeline. The library accepts strings; the command reads local files. Neither fetches URLs, changes articles nor sends telemetry.

## Install

Requires Perl 5.16 or later and HTML::Parser 3.72 or later. Other runtime dependencies ship with Perl. From a source release:

```sh
cpanm HTML::Parser
perl Makefile.PL
make
make test
make install
```

On Strawberry Perl for Windows, use `gmake` instead of `make`. To try the source before installation:

```sh
perl -Ilib script/html-anchor-audit examples/article.html
perl -Ilib script/html-anchor-audit --json examples/article.html
```

The example intentionally contains a missing target and a repeated ID, so it exits with status 1. Use `--help` for limits. Exit status 2 means an input or usage error.

## Library API

```perl
use utf8;
use HTML::Anchor::Audit qw(audit_html);

my $report = audit_html('<a href="#intro">Start</a><h2 id="intro">Intro</h2>');
for my $issue (@{ $report->{issues} }) {
    printf "%s at %d:%d\n", $issue->{code}, $issue->{line}, $issue->{column};
}
```

Use `audit_utf8` for UTF-8 bytes or `audit_html` for already decoded characters. API documentation is in `lib/HTML/Anchor/Audit.pm`. Unicode normalization is only a diagnostic hint; it never silently changes IDs or makes an invalid target valid.

## Scope and alternatives

Only fragment-only links on `<a>` and `<area>` are checked against static IDs and legacy `<a name>`. Exact and percent-decoded matches, Arabic IDs, HTML attribute entities and source positions are supported. A nonempty first `<base href>` and text-fragment directives cause links to be marked ignored. Template contents are ignored. See POD for the complete matching and report contract.

This is not a complete HTML5 DOM parser, WordPress validator or external link checker. Malformed nesting, duplicate attributes, SVG/XML, scripting-dependent `noscript` content and some HTML5 entity edge cases can differ from a browser. Theme-generated and JavaScript-generated IDs are unavailable in saved content.

The W3C Link Checker already checks anchors and fragments and is better suited to a website crawl. HTML::SimpleLinkExtor extracts links; HTML::Lint checks broader HTML errors; WWW::LinkRot checks remote URLs. This module has a narrower offline API, structured source locations and Unicode normalization hints. See `docs/comparison.md` for the pre-release comparison.

## Development

```sh
prove -lr t
perl Makefile.PL
make disttest
```

The test suite exercises valid/broken HTML, Unicode, encoded IDs, matching precedence, ignored contexts, UTF-8 locations, limits, CLI output, exit codes and preservation of input files. See `docs/validation.md` for the actual environments tested.

## Maintainer

Nedal Shabaan, [Idraaak](https://idraaak.com/). MIT license. Report reproducible bugs through GitHub issues.
