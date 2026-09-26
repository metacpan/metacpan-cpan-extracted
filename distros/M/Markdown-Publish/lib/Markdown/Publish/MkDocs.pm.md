# NAME

Markdown::Publish::MkDocs - publish distribution documentation with MkDocs

# SYNOPSIS

```perl
use Markdown::Publish::MkDocs;
my $publish_or=Markdown::Publish::MkDocs->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine prepares a MkDocs configuration and runs MkDocs. Set `config` to
an authored YAML file. A root `mkdocs.yml` is used directly; other files are
inherited by a temporary configuration that supplies the assembled documents
and navigation. Set `config_mode => 'direct'` when an authored file already
owns that layout. `command`, `strict`, `address`, and `output` customise the
build and local server. `prepare($preview)` returns the configuration path;
`build` returns the site directory; `serve` runs the foreground server.

`config_extend` explicitly selects a supplemental YAML file for inheritance.
It cannot be combined with `config` or direct mode. The publisher retains
control of the assembled `docs_dir`, `site_dir`, and generated navigation.

When no home page is authored, the first top-level assembled page is also used
for `index.md`. Its original URL remains available for existing links.

# SEE ALSO

`Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
