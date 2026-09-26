# Docbook::Convert

Convert DocBook documentation to Markdown. For large guides, the new
Pandoc pipeline expands included examples and preserves section IDs and MkDocs
admonitions using the filters supplied with this distribution.

## GitHub Attestations

The release workflow generates [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
for distribution archives. Install the [GitHub CLI](https://cli.github.com/)
with `gh attestation` support and authenticate with `gh auth login`.

Download `Docbook-Convert-VERSION.tar.gz` from a GitHub release, MetaCPAN,
or a CPAN mirror, replace `VERSION`, and verify it with:

```sh
gh attestation verify Docbook-Convert-VERSION.tar.gz --repo aspeer/pm-Docbook-Convert
```

A successful verification confirms that the archive checksum matches an
attestation from this repository. The workflow publishes the same archive to
GitHub Releases and CPAN. Older releases and GitHub's automatically generated
source-code archives are not covered.

## Install and convert

Install the CPAN prerequisites with `cpanm .`, and install Pandoc, xmllint
and xsltproc through your system package manager.

```sh
docbook-convert --pandoc doc/guide.xml > doc/guide.md
```

```perl
use Docbook::Convert::Pandoc;
my $markdown=Docbook::Convert::Pandoc->new()->convert_file('doc/guide.xml');
```

See [the Pandoc API](lib/Docbook/Convert/Pandoc.pm.md) and
[the examples](examples/README.md).

The custom Markdown renderer remains available through `docbook-convert --markdown`.
A failed Pandoc conversion does not silently fall back to it. Direct DocBook-to-POD
conversion is retired; use Markdown::Pod::Embed for Perl sidecar documentation.

After ASPEER::MakeMaker::Markdown::Pod is installed, rerun
`perl Makefile.PL` to enable this distribution's own `make doc` targets.
