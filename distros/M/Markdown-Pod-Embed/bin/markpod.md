# NAME

markpod - merge Markdown documentation into Perl files

# USAGE

`markpod --inplace --recursive lib bin` updates discovered source files.
`--dry-run` reports intended changes without writing. `--nobackup` suppresses
backup files. Without `--inplace`, complete transformed source is printed.

Use `--extract-markdown FILE` or `--extract-pod FILE` to print documentation
only. `--dialect GitHub` selects the Markdown::Pod dialect.

`--version` prints the installed program version.

Supply files explicitly, or use `--recursive` with directories. Unsupported
options and failed operations exit nonzero. A file with no Markdown source is
skipped. See Markdown::Pod::Embed for source precedence and preservation rules.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
