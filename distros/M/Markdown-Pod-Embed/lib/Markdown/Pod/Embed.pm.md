# NAME

Markdown::Pod::Embed - maintain Perl documentation from Markdown

# SYNOPSIS

```perl
use Markdown::Pod::Embed;
my $processor_or=Markdown::Pod::Embed->new({nobackup => 1});
$processor_or->update('lib/Example.pm');
```

# DESCRIPTION

A nonempty `Example.pm.md` sidecar is the preferred documentation source. When
it is absent or empty, Markdown inside `=begin markdown` blocks is used instead.
Plain POD without a Markdown source is preserved. Generated documentation keeps
both the embedded Markdown and its POD rendering, so embedded-only authoring
continues to work.

Relative Markdown links to existing companion `*.pm.md` sidecars remain file
links in the retained Markdown. In the generated POD, their destinations become
the package declared by the companion `.pm` file, so module links work in both
renderings. Other relative links, unresolved targets, fragments, and external
URLs are preserved as written.

A leading Markdown page title immediately before `# NAME` is retained in the
Markdown but omitted from the POD rendering. UTF-8 documentation receives an
encoding declaration, and inline code and emphasis use safe POD delimiters when
their contents would otherwise conflict with POD syntax.

This library has no MakeMaker integration. Use ASPEER::MakeMaker::Markdown::Pod for
repository targets and maintenance.

# PUBLIC METHODS

`new(\%options)` constructs a processor. Options are `dialect` (default `GitHub`),
`nobackup` (suppress `.bak` copies), and `dry_run` (calculate without writing).

`source($filename)` returns the selected Markdown, or undef when none exists.

`process($filename)` prepares the transformed source in memory. It returns undef
for an undocumented file, zero when unchanged, or a positive value when changed.

`update($filename)` prepares and writes changed source. It has the same return
values as `process`; dry-run reports the intended result without writing.

`markdown()` and `pod()` return the most recently processed documentation.
`ppi_doc_or()` returns the prepared PPI document; `serialize()` on that object
returns the complete transformed source.

`discover(@files_or_directories)` is a class method returning a sorted array
reference of source paths. It finds `.pm`, `.pl`, and executable sidecar targets.
Normal recursive scans exclude `t`, `node_modules`, `.git`, `.venv`, `blib`,
`build`, and `site`. Explicit files may be supplied from those directories.

The existing `markpod_process`, `markpod_process_and_update`, and
`markpod_markdown_source` names remain aliases of the corresponding operations.
`markpod_inplace_update($filename)` saves the result of `process`.
`markpod_markdown_text($markdown)` renders plain text using Pandoc.

# ERRORS AND FILE SAFETY

Failures throw an exception. Updates preserve permissions and replace the file
only after writing the complete result. Symlinks are not replaced. Insertion
after a data section without existing POD is refused; move documentation ahead
of the data or supply an appropriate existing documentation block first.

# LICENSE

This software is copyright (c) 2026 by Andrew Speer. It may be distributed under
the same terms as Perl itself.
