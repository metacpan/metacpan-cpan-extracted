<div>
    <a href="https://cpants.cpanauthors.org/dist/GDPR-IAB-TCFv2"><img src="https://cpants.cpanauthors.org/dist/GDPR-IAB-TCFv2.svg" alt='Kwalitee'/></a>
</div>

<div>
    <a href="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/linux.yml"><img src="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/linux.yml/badge.svg" alt='tests'/></a>
</div>

<div>
    <a href="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/windows.yml"><img src="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/windows.yml/badge.svg" alt='tests'/></a>
</div>

<div>
    <a href="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/macos.yml"><img src="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/macos.yml/badge.svg" alt='tests'/></a>
</div>

<div>
    <a href="https://coveralls.io/github/peczenyj/GDPR-IAB-TCFv2?branch=main"><img src="https://coveralls.io/repos/github/peczenyj/GDPR-IAB-TCFv2/badge.svg?branch=main" alt='Coverage Status' /></a>
</div>

<div>
    <a href="https://github.com/peczenyj/GDPR-IAB-TCFv2/blob/master/LICENSE"><img src="https://img.shields.io/cpan/l/GDPR-IAB-TCFv2.svg" alt='license'/></a>
</div>

<div>
    <a href="https://metacpan.org/dist/GDPR-IAB-TCFv2"><img src="https://img.shields.io/cpan/v/GDPR-IAB-TCFv2.svg" alt='cpan'/></a>
</div>

# NAME

GDPR::IAB::TCFv2 - TCF v2.3 distribution: parser, validator, CMP-validator, and CLI

# PROJECT STATUS

`GDPR::IAB::TCFv2` entered **maintenance mode** on 2026-05-15 with the
v0.512 release. The core parser, validator, and CMP-validator surfaces
are considered feature-complete for the IAB TCF v2.3 specification.

In maintenance mode the maintainer commits to bug fixes, security
fixes, CPAN-tester regression triage, and tracking IAB-spec updates
(TCF v2.4 / v3 if and when they ship). Larger feature work -- the
remaining roadmap phases (GVL-aware validator, Special Features /
Special Purposes, CLI configuration loading), the distribution items
(DockerHub automation, Debian package), and the sister-distribution
ideas in ["ECOSYSTEM"](#ecosystem) -- is now tracked as `help-wanted` issues on
GitHub.

Patches and PRs from the community are welcome and will continue to be
reviewed. See `TODO` at the repository root for the full
help-wanted list and `CONTRIBUTING` for the patching workflow.

# SYNOPSIS

This module is the documentation hub for the `GDPR-IAB-TCFv2`
distribution. It exposes a thin `Parse` delegate that returns an
instance of [GDPR::IAB::TCFv2::Parser](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AParser):

    use feature qw<say>;
    use GDPR::IAB::TCFv2;

    my $consent = GDPR::IAB::TCFv2->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

    say $consent->cmp_id;             # 21
    say $consent->consent_language;   # 'EN'
    say $consent->is_v23 ? 'v2.3' : 'older';

For declarative compliance checks, see [GDPR::IAB::TCFv2::Validator](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator).
For one-liner / shell-use shortcuts, see ["ONE-LINER USAGE"](#one-liner-usage) below.

# COMPONENTS

The distribution ships several pieces. Each link below jumps to the
relevant module or section.

## [GDPR::IAB::TCFv2::Parser](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AParser)

The bit-stream parser. `Parse` returns an instance whose accessors,
predicates, and JSON serializer answer every question about a TC
string.

## [GDPR::IAB::TCFv2::Validator](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator)

Declarative compliance checks. `$validator->validate($tc_string)`
asserts a vendor's presence in the string for a given purpose set on a
given legal basis.

## [GDPR::IAB::TCFv2::CMPValidator](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3ACMPValidator)

Validates that a TC string's `cmp_id` is registered in the IAB's
public CMP list (file, JSON, or URL-loaded snapshot).

## [iabtcfv2](https://metacpan.org/pod/iabtcfv2) (Perl module)

A pure-exporter short alias for one-liner and shell use. Provides
`tcf($s)` and `validator(%opts)` as importable functions. See
["ONE-LINER USAGE"](#one-liner-usage).

## `bin/iabtcfv2` (CLI)

Subcommand-style command-line utility. `iabtcfv2 dump` emits parsed
JSON; `iabtcfv2 validate` runs declarative compliance checks against
a vendor identity and a purpose set. See ["COMMAND LINE TOOLS"](#command-line-tools).

## Docker image

Pre-built Docker Hub image `peczenyj/gdpr-iab-tcfv2` wraps the CLI
for portable use. See ["DOCKER USAGE"](#docker-usage).

# INCOMPATIBLE CHANGES

## v0.500

The parser implementation moved from `GDPR::IAB::TCFv2` to a new
subpackage [GDPR::IAB::TCFv2::Parser](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AParser). The class-method delegate
remains: `GDPR::IAB::TCFv2->Parse(...)` still works and is the
recommended entry point. However, the returned object is now blessed
into `GDPR::IAB::TCFv2::Parser` rather than `GDPR::IAB::TCFv2`:

    my $c = GDPR::IAB::TCFv2->Parse($s);

    # Before v0.500:
    ref($c) eq 'GDPR::IAB::TCFv2'             # true
    $c->isa('GDPR::IAB::TCFv2')               # true

    # v0.500 and later:
    ref($c) eq 'GDPR::IAB::TCFv2::Parser'     # true
    $c->isa('GDPR::IAB::TCFv2::Parser')       # true
    $c->isa('GDPR::IAB::TCFv2')               # false

Every method call, every JSON output byte, and every CLI behavior is
unchanged. The break only affects code that asserts the exact class
name via `ref`, `isa`, `blessed`, `Storable::thaw`, or similar.

# CONSTRUCTOR

## Parse

`GDPR::IAB::TCFv2->Parse($tc_string, %opts)` is the entry point
for parsing TCF v2.3 consent strings. It delegates to
[GDPR::IAB::TCFv2::Parser->Parse](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AParser#Parse)
and returns a `GDPR::IAB::TCFv2::Parser` object; see that page for
the full constructor contract (`strict`, `prefetch`, `json`
options).

# COMMAND LINE TOOLS

This distribution includes a unified command line tool to work with TC strings.

## iabtcfv2

The `iabtcfv2` utility provides several subcommands for TCF v2.3 strings.

### dump

Parses TC strings and output them as JSON.

    # Basic usage
    iabtcfv2 dump "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Pretty printed JSON
    iabtcfv2 dump --pretty "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Stream multiple strings from STDIN as JSON Lines
    cat strings.txt | iabtcfv2 dump

    # Pipe through `jq -s` if you need a single JSON array
    cat strings.txt | iabtcfv2 dump | jq -s .

    # Short flags can be bundled (the last bundled short may take a value)
    iabtcfv2 dump -pi "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"
    iabtcfv2 dump -pv 284 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Long options accept the GNU `--opt=value` form
    iabtcfv2 dump --vendor-id=284 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

### validate

Validates TC strings against a vendor identity and a set of declared purpose
lists, emitting one JSON record per string (or text lines with `--text`).
The vendor must be allowed for every purpose in `--consent-purposes` on a
consent basis, and for every purpose in `--legitimate-interest-purposes`
on a legitimate-interest basis. Exit code is `0` when every string is
valid, `1` on any parse or validation failure, `2` on bad CLI usage.

    # Basic usage: vendor must appear in the TC string
    iabtcfv2 validate -v 284 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Require vendor 284 to be allowed for purposes 1 and 3 on consent basis
    iabtcfv2 validate -v 284 -C 1,3 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Require both consent (purposes 1, 3) and legitimate interest (purpose 7)
    iabtcfv2 validate -v 284 -C 1,3 -L 7 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Accumulate every failing rule (validate_all) instead of fail-fast
    iabtcfv2 validate -av 284 -C 1,3 -L 7 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Human-readable text output instead of JSON
    iabtcfv2 validate -tv 284 -C 1,3 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Reject TC strings whose policy version is below 5 (TCF v2.3)
    iabtcfv2 validate -v 284 -m 5 "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

    # Pipeline-friendly: -q suppresses output, only the exit code is meaningful
    if iabtcfv2 validate -qv 284 -C 1,3 "$tc_string"; then
        echo "ok"
    fi

    # Stream multiple strings from STDIN as JSON Lines (pipe through
    # `jq -s` if you need a single JSON array)
    cat strings.txt | iabtcfv2 validate -v 284 -C 1,3

See `iabtcfv2 --help` or `perldoc iabtcfv2` for more details.

For script-free invocation without `bin/iabtcfv2`, see
["ONE-LINER USAGE"](#one-liner-usage).

# ONE-LINER USAGE

The distribution supports `perl -M...` one-liners directly. The
[iabtcfv2](https://metacpan.org/pod/iabtcfv2) module exports `tcf($s)` (which returns a
`GDPR::IAB::TCFv2::Parser`) and `validator(%opts)` (which returns a
`GDPR::IAB::TCFv2::Validator`), making short scripts even shorter.

## Print one field

    perl -Miabtcfv2 -E 'say tcf(shift)->cmp_id' "$tc"

Equivalent long form (no shortcut module):

    perl -MGDPR::IAB::TCFv2 -E 'say GDPR::IAB::TCFv2->Parse(shift)->cmp_id' "$tc"

## Multi-field TSV

    perl -Miabtcfv2 -E '
        my $c = tcf(shift);
        say join("\t", $c->cmp_id, $c->cmp_version, $c->consent_language,
                       $c->vendor_list_version, $c->policy_version)
    ' "$tc"

## Emulate \`iabtcfv2 dump --pretty\` via core JSON::PP

    perl -Miabtcfv2 -MJSON::PP -E '
        say JSON::PP->new->convert_blessed->canonical->pretty
                    ->encode(tcf(shift))
    ' "$tc"

## Stream multiple strings on STDIN

    perl -Miabtcfv2 -nE '
        chomp;
        my $c = eval { tcf($_) } or next;
        say join("\t", $_, $c->cmp_id)
    ' < strings.txt

## Validate

    perl -Miabtcfv2 -E '
        my $r = validator(vendor_id => 284, consent_purpose_ids => [1,3])
                ->validate(shift);
        say $r ? "ok" : "fail: $r"
    ' "$tc"

# DOCKER USAGE

This tool is also available as a Docker image on Docker Hub.

## Basic Usage

    docker run --rm peczenyj/gdpr-iab-tcfv2 dump "CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA"

## Processing Streams (STDIN)

To process a stream of strings via pipe:

    cat strings.txt | docker run -i --rm peczenyj/gdpr-iab-tcfv2 dump

To type strings manually:

    docker run -it --rm peczenyj/gdpr-iab-tcfv2 dump

# ACRONYMS

[GDPR](https://gdpr-info.eu/): General Data Protection Regulation

[IAB](https://iabeurope.eu/about-us/): Interactive Advertising Bureau

[TCF](https://iabeurope.eu/transparency-consent-framework/): The Transparency & Consent Framework

# FUNCTIONS

## looksLikeIsConsentVersion2

Will check if a given tc string starts with a literal `C`.

# ECOSYSTEM

The following **sister distributions** are intentionally left as
`help-wanted` ideas rather than shipped from this module. Each one is
companion glue for a popular Perl framework and would add a runtime
dependency on its host framework, so they belong as separate CPAN
distributions rather than features of `GDPR::IAB::TCFv2` itself.

- [GDPR::IAB::TCFv2::Validator::LIVR](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator%3A%3ALIVR)

    LIVR rule-engine binding for JSON-shaped TC string payloads.

- [GDPR::IAB::TCFv2::Validator::TypeTiny](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator%3A%3ATypeTiny)

    Reusable Type::Tiny constraints (parameterized by purpose / vendor
    sets) for Moo, Moose, or pure-Perl callers that prefer type-level
    enforcement.

- [Plack::Middleware::GDPR::TCFv2](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AGDPR%3A%3ATCFv2)

    Plack middleware that decodes a TC string from a request header or
    cookie, attaches a parsed `GDPR::IAB::TCFv2` object to `$env`,
    and short-circuits the response when consent is missing or invalid.

- [GDPR::IAB::TCFv2::Validator::Moose](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator%3A%3AMoose)

    Moose attribute traits and role-based validation for Moose-end-to-end
    projects.

- [GDPR::IAB::TCFv2::Validator::FormValidator](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator%3A%3AFormValidator)

    `Data::FormValidator` profile glue for legacy applications that drive
    business validation through DFV.

The `help-wanted` issues on GitHub track each of these ideas; see
[https://github.com/peczenyj/GDPR-IAB-TCFv2/issues?q=label%3Aecosystem](https://github.com/peczenyj/GDPR-IAB-TCFv2/issues?q=label%3Aecosystem)
and `TODO` for context.

# SEE ALSO

[GDPR::IAB::TCFv2::Parser](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AParser) for the parser API.

[GDPR::IAB::TCFv2::Validator](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3AValidator) for declarative compliance checks.

[GDPR::IAB::TCFv2::CMPValidator](https://metacpan.org/pod/GDPR%3A%3AIAB%3A%3ATCFv2%3A%3ACMPValidator) for CMP-list validation.

[iabtcfv2](https://metacpan.org/pod/iabtcfv2) for one-liner / shell-use shortcuts.

The original IAB documentation of [TCF v2](https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md).

# AUTHOR

Tiago Peczenyj [mailto:tiago.peczenyj+cpan@gmail.com](mailto:tiago.peczenyj+cpan@gmail.com)

# THANKS

Special thanks to [ikegami](https://metacpan.org/author/IKEGAMI) for the patience on several question about Perl on [Stack Overflow](https://stackoverflow.com).

# BUGS

Please report any bugs or feature requests to [https://github.com/peczenyj/GDPR-IAB-TCFv2/issues](https://github.com/peczenyj/GDPR-IAB-TCFv2/issues).

# LICENSE AND COPYRIGHT

Copyright 2023-2026 Tiago Peczenyj

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.

# DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
