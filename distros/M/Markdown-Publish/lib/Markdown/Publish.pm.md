# NAME

Markdown::Publish - common documentation publication operations

# SYNOPSIS

```perl
use Markdown::Publish;

my $publish_or=Markdown::Publish->new({
    module  => 'Markdown::Publish::MkDocs',
    sources => ['doc'],
    config  => 'doc/mkdocs/mkdocs.yml',
});

$publish_or->run('build');
$publish_or->run('serve');
$publish_or->run('gh');
$publish_or->run('gh-push');
$publish_or->run('cloudflare');
```

# DESCRIPTION

This module selects one publishing engine and provides the shared operations
for assembling Markdown, splitting chapters, normalising links and assets,
and publishing a built site through a temporary Git worktree. The engine
classes implement their own `prepare`, `build`, and `serve` methods. No
Makefile is needed; `ASPEER::MakeMaker::Markdown::Publish` supplies optional
MakeMaker targets.

An existing `doc/` directory is the default publication boundary. When it is
assembled, Markdown beneath `lib/` and `bin/` is mirrored under those paths in
the temporary site documents. A guide can link to `lib/Example/Module.pm.md`.
Mirrored pages are available through links but are not added to generated
navigation. When `doc/` is absent, sidecars become the default source pages.
Set `sources` explicitly to include other directories. Source files are never rewritten;
assembly and engine-specific Markdown adjustments happen in temporary trees.
Nested Markdown under `doc/` remains available for links but does not appear
in generated navigation. When no `index.md` was authored, the first top-level
page becomes the home page in each engine; its original URL remains available.

# CONFIGURATION

The default engine is `Markdown::Publish::MkDocs`. Select another class
with `module`. `MARKDOWN_PUBLISH_MODULE` overrides `module`, including
when it comes from a JSON file or MakeMaker metadata. The `mkdocs`, `vitepress`,
`docusaurus`, and `starlight` shortcuts select the bundled publishers. A fully
qualified name may select another installed subclass. Engine settings are
flat, rather than nested beneath engine names:

```perl
{
    module  => 'Markdown::Publish::Docusaurus',
    sources => ['doc'],
    name    => 'Example documentation',
    config  => 'doc/docusaurus/docusaurus.config.js',
    output  => 'site',
    branch  => 'gh-pages',
    cloudflare => {config => 'wrangler.jsonc'},
}
```

The `config` path and other engine-specific options are described by the
selected engine module. `load_config($filename)` accepts a JSON object
containing the settings directly, under `publish`, or under
`x_documentation.publish`. `new({config_file => $filename})` is equivalent.
Do not combine `config_file` with inline settings.

`base` sets the deployment path for generated VitePress, Docusaurus, and
Starlight configuration. It must begin and end with `/`; for example,
`base => '/example/'`. An authored engine configuration remains authoritative
for its own base path.

Set `config_extend` instead of `config` to customise a generated configuration.
The two settings cannot be combined. MkDocs inherits the supplied YAML file.
VitePress and Starlight load an ECMAScript module whose default export is a
function; Docusaurus loads a CommonJS module exporting a synchronous function.
Each function receives the generated configuration followed by a context object
containing `name`, `base`, `output`, `pages`, and `navigation`, and must return
the configuration to use.

VitePress and Docusaurus receive their native configuration object. Starlight
receives `{astro, starlight}` so its Astro settings and the options passed to
the Starlight integration can be extended separately. Generated values remain
in effect unless the function explicitly replaces them.

For a static documentation Worker, a minimal authored `wrangler.jsonc` is:

```jsonc
{
    "name": "example-docs",
    "compatibility_date": "2026-09-22",
    "assets": {
        "directory": "./site",
        "not_found_handling": "404-page"
    },
    "observability": {
        "enabled": true,
        "traces": {"enabled": true}
    }
}
```

Use the current compatibility date for a new Worker and choose the intended
Worker name. The deploy action replaces `assets.directory` with the selected
engine's actual build output; the authored file remains unchanged.

# METHODS

## new

Loads and constructs the selected engine class. A direct engine-class
constructor may be used when the class is already known.

## load_config

Reads a JSON configuration and constructs its selected engine.

## run

Dispatches `build`, `serve`, `gh`, `gh-push`, or `cloudflare`. `gh` builds the
site and updates the local publication branch. It does not contact a remote;
push the branch through the repository's normal Git workflow. `gh-push`
performs the same build and local branch update, then pushes that branch to
`origin`. These are explicit publishing actions, not part of `build` or
`serve`. `cloudflare`
builds and deploys the static files to a Cloudflare Worker without committing
or pushing Git.

## source_directories

Returns the configured source roots or the default roots described above.

## prepare_docs

Assembles source Markdown and assets in a temporary directory. Returns the
temporary root, assembled document directory, and ordered pages.

## split

Splits a guide at top-level headings outside code fences and repairs links to
anchors moved into another generated page.

## publish_gh

Builds and commits to a temporary worktree for the configured local branch. It
does not change the current checkout or contact a remote. When `base` is not
configured, this action derives it from the `origin` repository name. A normal
project repository uses `/<repository>/`, while a repository named
`<owner>.github.io` uses `/`. If `origin` is unavailable, the Git top-level
directory name is used. This inferred value applies only to the GitHub Pages
build; ordinary builds, local preview, and Cloudflare publication keep their
normal base path.

## publish_gh_push

Runs `publish_gh`, then pushes the resulting publication branch to `origin`.
It does not force the update or push any other branch.

## publish_cloudflare

Builds through the selected engine, then deploys that output as Workers Static
Assets using Wrangler. Set `cloudflare.config` to an existing, dedicated
Wrangler configuration file for the intended Worker. `cloudflare.wrangler`
selects the executable (`wrangler` by default); `cloudflare.environment`
optionally selects an authored Wrangler environment. The site directory is
passed with `--assets`, overriding the config file's asset directory. Missing
configuration or build output is fatal before deployment. Authentication
comes from Wrangler's existing login or environment, not publication metadata.

The Wrangler config owns the Worker name, compatibility date, routing, and
other deployment settings. Use a static-assets-only config without a `main`
script for this documentation workflow. Publishing to an existing Worker can
update its settings; review its config before invoking this remote action.

# SEE ALSO

`Markdown::Publish::MkDocs`,
`Markdown::Publish::VitePress`,
`Markdown::Publish::Docusaurus`,
`Markdown::Publish::Starlight`,
`ASPEER::MakeMaker::Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of Markdown::Publish. Copyright (c) 2026 Andrew
Speer. This is free software; you can redistribute it and/or modify it under
the same terms as Perl 5.
