# Publishing documentation with Markdown::Publish {#introduction}

This module lets you publish documentation - either in Docbook XML or Markdown format as a static site using publishing engines such as MkDocs etc. You can preview the output before pushing the finished site to GitHub Pages or another static hosting location.

The module assembles the documents and hands them to a publishing engine: MkDocs, VitePress, Docusaurus, or Astro Starlight. Its companion module, `ASPEER::MakeMaker::Markdown::Publish`, adds `make` targets to a Perl distribution Makefile. The assembly and publication stage satys in `Markdown::Publish`, so the same setup can be driven by MakeMaker, a JSON project file, the command-line utility, or Perl code.

The rest of this article explains what those commands do, how source discovery works, how to customise each engine, and how to publish without accidentally mixing local builds with remote operations.

# Quick start

For quick start configure the MakeMaker adapter, run `make doc`, then run `make publish_serve`.

    perl -MASPEER::MakeMaker::Markdown::Publish -MASPEER::MakeMaker::Markdown::Pod
    make doc
    make publish_serve

# Workflow {#mental-model}

It helps to separate documentation maintenance from site assembly and publication. They are related, but they do not have the same side effects.

1.  `make doc`, supplied by `ASPEER::MakeMaker::Markdown::Pod`, converts maintained DocBook articles to Markdown and merges Markdown sidecars into Perl sources as POD documentation.

2.  A build or preview directs `Markdown::Publish` to copy the selected Markdown and assets into a temporary assembly, create navigation, and invoke the chosen site generator.

3.  A publication action pushes the completed site somewhere else. GitHub publication updates the "gh-pages" branch; Cloudflare publication invokes Wrangler to push as a Pages site.

!!! note

    The publisher step expects Markdown. DocBook is an authoring format in
    the wider toolchain, bit is not understood directly by the site
    backends. Run `make doc` after changing an XML article so that its
    sibling Markdown is current before building the site.

# Documentation layout {#document-layout}

The default convention is to put project articles and explanatory Markdown beneath `doc/`. Put a module's sidecar Markdown beside the module, such as `lib/Example/Client.pm.md`, and put an executable's sidecar beside the executable under `bin/`.

``` text
Example-Client/
├── Makefile.PL
├── doc/
│   ├── example-client.xml
│   ├── example-client.md
│   └── images/
│       └── request-flow.svg
├── lib/
│   └── Example/
│       ├── Client.pm
│       └── Client.pm.md
└── bin/
    ├── example-client
    └── example-client.md
```

If there is no `doc/`, the publisher falls back to the sidecars beneath `lib/` and `bin/` and will. An explicit `sources` list replaces these conventions; it is exact rather than additive. Source files and directories named as sources must exist.

A top-level article containing several level-one Markdown headings is split into sections, one per heading. Links to anchors that move into another page are repaired during assembly. If no `index.md` exists, then the first top-level page also becomes the home page while its original URL remains available.

You can link to markdown documentation for modules and scripts using the convention `lib/Examples/Client.pm.md` - markdown sidecars will be assembled until the `doc/` as a root directory when publishing (i.e. You don't need to specify the document as `../`)

# MakeMaker targets {#makemaker-setup}

Options to customise the output can be added to `Makefile.PL` in `META_MERGE.x_documentation.publish` section, e.g.

``` perl
use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1;
};

eval {
    require ASPEER::MakeMaker::Markdown::Publish;
    ASPEER::MakeMaker::Markdown::Publish->import();
    1;
};

WriteMakefile(
    NAME         => 'Example::Client',
    VERSION_FROM => 'lib/Example/Client.pm',
    META_MERGE   => {
        'meta-spec' => {version => 2},
        x_documentation => {
            publish => {
                module  => 'mkdocs',
                name    => 'Example::Client',
                sources => ['doc'],
            },
        },
    },
);
```

Publisher settings and preferences can also be set with environment variables (see section below).

Regenerate the Makefile after changing `Makefile.PL` as changing an inline setting also requires regeneration.

``` sh
perl Makefile.PL
make doc
make publish_serve
```

When `name` is omitted, the MakeMaker adapter uses the distribution's `NAME` as the documentation title. MkDocs is the default engine, so both `module` and `name` can be omitted in this example. Keeping them visible is useful in a template because it makes the intended site clear.

# Work with the make targets {#make-targets}

Once the Makefile has been generated, the adapter supplies targets you can build to.

`make publish_build`

: Assemble the documents and render the static site into the configured output directory, `site/` by default.

`make publish_serve`

: Assemble the documents and run the selected engine's foreground development server. Stop it with Ctrl-C.

`make publish_gh`

: Build the site and create or update the local publication branch, normally `gh-pages`. It does not contact a remote.

`make publish_gh-push`

: Perform the same local branch update and then push only that branch to `origin`. The push is not forced but if no clashes will be propagated immediately.

`make publish_cloudflare`

: Build the site and deploy its static files with an explicitly configured Wrangler file. It does not update a Git branch.

The targets call the same engine API as the standalone utility. The MakeMaker adapter does not maintain another implementation of site assembly or Git publication.

# Choose the common options {#common-configuration}

Engine settings are flat values in the `publish` object. They are not nested beneath the selected engine name. These options are shared by the normal workflows:

`module`

: Selects `mkdocs`, `vitepress`, `docusaurus`, `starlight`, or a fully qualified installed subclass. MkDocs is the default. You can also supply your own custom module if inheriting, e.g. "ACME::Publish"

`sources`

: An array of source directories. Omit it to use the `doc/` convention and sidecar fallback.

`name`

: The generated site title. Under MakeMaker it defaults to `NAME`; standalone use otherwise defaults to `Documentation`.

`output`

: The rendered site directory. The default is `site/`.

`base`

: The deployment path for generated VitePress, Docusaurus, and Starlight configuration. It begins and ends with a slash, for example `/example-client/`.

`branch`

: The local Git publication branch. The default is `gh-pages`.

`config`

: An authored native engine configuration. It is authoritative where the selected backend documents that behaviour.

`config_extend`

: A supplemental file that customises generated defaults. It cannot be combined with `config`.

`host` and `port`

: Override the development server listener where the backend supports it.

`MARKDOWN_PUBLISH_MODULE` overrides the configured engine at runtime. This is handy for comparing renderers without editing `Makefile.PL` or a project file:

``` sh
MARKDOWN_PUBLISH_MODULE=starlight make publish_serve
MARKDOWN_PUBLISH_MODULE=vitepress make publish_build
```

`MARKDOWN_PUBLISH_HOST` and `MARKDOWN_PUBLISH_PORT` provide global preview defaults. `MARKDOWN_PUBLISH_NPM_VERBOSE=1` shows normal npm installation output for the Node-based publishers.

# Select a publishing engine {#selecting-an-engine}

All four engines consume the same Markdown source, but their native tooling and configuration differ.

## MkDocs {#mkdocs-engine}

MkDocs is the default and the lightest choice for this workflow. Install MkDocs and the theme or plugins required by your configuration. The backend accepts `command`, `strict`, `address`, and `output`. Strict builds are enabled by default.

A root `mkdocs.yml` is used directly. Another file named by `config` is normally inherited by a temporary configuration which supplies the assembled `docs_dir`, output directory, and navigation. Set `config_mode` to `direct` only when the authored file deliberately owns those paths as well.

## VitePress {#vitepress-engine}

VitePress runs in a temporary npm project. Set `npm` to another npm executable, `version` to a particular VitePress version, and `host`, `port`, or `output` as needed. An authored configuration named by `config` keeps its original location so its relative imports still work.

## Docusaurus {#docusaurus-engine}

Docusaurus also runs in a temporary npm project and accepts `npm`, `version`, `host`, `port`, and `output`. The generated project uses the classic preset, disables the blog, and places the documents at the site root.

## Astro Starlight {#starlight-engine}

Starlight accepts `npm`, `astro_version`, `starlight_version`, `host`, `port`, and `output`. The generated project includes a Markdown link resolver so links to mirrored module pages become the routes that Starlight actually emits. An authored Astro configuration is wrapped to retain this resolver; if it supplies a Markdown processor, that processor must be unified.

# Extend generated configuration {#supplemental-configuration}

Most projects want to retain generated paths and navigation while adding a theme choice, search, social links, or validation policy. Use `config_extend` for that case. Use `config` when you intend to own the native engine configuration instead. Supplying both is an error.

## MkDocs supplemental YAML {#mkdocs-supplement}

MkDocs inherits the named YAML before the publisher supplies its assembly paths and navigation.

``` perl
publish => {
    module        => 'mkdocs',
    config_extend => 'doc/mkdocs/site.yml',
},
```

``` yaml
theme:
  name: material
  features:
    - navigation.sections
markdown_extensions:
  - admonition
```

## VitePress extension function {#vitepress-supplement}

VitePress loads an ECMAScript module. Its default export receives the generated VitePress configuration and a context object.

``` javascript
export default (config, context) => ({
  ...config,
  description: `${context.name} reference`,
  themeConfig: {
    ...config.themeConfig,
    search: {provider: 'local'},
  },
});
```

## Docusaurus extension function {#docusaurus-supplement}

Docusaurus loads a CommonJS module. It returns the complete configuration to use.

``` javascript
module.exports = (config, context) => ({
  ...config,
  tagline: `${context.name} reference`,
  onBrokenLinks: 'throw',
});
```

## Starlight extension function {#starlight-supplement}

Starlight separates Astro configuration from the options passed to the Starlight integration. Return both objects. Extra Astro integrations are retained after the generated Starlight integration.

``` javascript
export default ({astro, starlight}, context) => ({
  astro,
  starlight: {
    ...starlight,
    description: `${context.name} reference`,
    social: [{
      icon: 'github',
      label: 'GitHub',
      href: 'https://github.com/example/example-client',
    }],
  },
});
```

# Publish to GitHub Pages {#github-pages}

Start with the local-only action. It builds the site in a temporary directory, creates a temporary Git worktree, replaces the content of the publication branch, commits changed output, and removes the worktree. Your current checkout stays on its existing branch.

``` sh
make doc
make publish_build
make publish_gh
git log --oneline --decorate -1 gh-pages
git push origin gh-pages
```

The final push is shown separately so you can inspect the result first. When that separation is unnecessary, use `make publish_gh-push`. It updates the same local branch and runs `git push origin gh-pages`; it does not force the update or push another branch.

GitHub project sites normally live beneath the repository name. During a GitHub publication action, the publisher derives `/repository-name/` from `origin`. A repository named `owner.github.io` uses `/`. If no origin URL is available, the checkout directory name is the fallback. Set `base` explicitly when the published URL uses another path.

!!! warning

    `publish_gh-push` will push to remote. Use `publish_gh` when the
    repository's authoritative remote is not GitHub, when GitHub is only a
    mirror, or when you want to review the publication commit before pushing
    it.

# Use a project.json file {#project-json}

A standalone project file can be used outside MakeMaker, or inside it when you want publication settings to change without regenerating the Makefile. The conventional filename is `doc/project.json`. The file may contain the publisher settings directly, beneath `publish`, or in the complete `x_documentation.publish` shape used by MakeMaker.

``` json
{
  "x_documentation": {
    "publish": {
      "module": "starlight",
      "name": "Example::Client",
      "sources": ["doc"],
      "output": "site",
      "branch": "gh-pages",
      "config_extend": "doc/starlight.extend.mjs"
    }
  }
}
```

Run the utility from the project root. It automatically reads `doc/project.json` when present, or accepts another path with `--config`.

``` sh
markdown-publish build
markdown-publish serve
markdown-publish gh
markdown-publish gh-push

markdown-publish serve --config config/documentation.json
```

To make the MakeMaker targets read the same external file, set only `config_file` in the metadata. Do not combine it with inline publisher options.

``` perl
x_documentation => {
    publish => {
        config_file => 'doc/project.json',
    },
},
```

The file is read when a target runs, so editing it does not require `perl Makefile.PL`. This is often the nicest arrangement for a project that changes themes and publishing details more often than its build metadata.

# Use command-line options for a quick build {#command-line-options}

A small project does not need a JSON file. Select the engine and common values directly:

``` sh
markdown-publish serve \
  --module vitepress \
  --source doc \
  --name 'Example::Client' \
  --base '/example-client/' \
  --output site
```

Repeat `--source` to name several exact source roots. The remaining common options are `--branch`, `--version`, and `--help`. Put native engine options, supplemental configuration, and Cloudflare settings in a JSON file; the command line intentionally exposes only the common quick-start choices.

When a project file is selected explicitly or found automatically, `--module` cannot replace its engine. Use `MARKDOWN_PUBLISH_MODULE` for a deliberate runtime engine override.

# Publish static assets with Cloudflare {#cloudflare-publication}

Cloudflare publication requires a dedicated Wrangler configuration. Keep the Worker name, compatibility date, routes, and other deployment settings there. The publisher builds once and passes the actual output directory to Wrangler with `--assets`; it does not rewrite the authored file.

``` json
{
  "name": "example-client-docs",
  "compatibility_date": "2026-09-25",
  "assets": {
    "directory": "./site",
    "not_found_handling": "404-page"
  },
  "observability": {
    "enabled": true
  }
}
```

Point the publication configuration at that file. The executable defaults to `wrangler`; an authored Wrangler environment is optional.

``` json
{
  "publish": {
    "module": "mkdocs",
    "name": "Example::Client",
    "cloudflare": {
      "config": "wrangler.docs.jsonc",
      "wrangler": "wrangler",
      "environment": "production"
    }
  }
}
```

``` sh
markdown-publish cloudflare --config doc/project.json
# or, with the MakeMaker adapter:
make publish_cloudflare
```

!!! warning

    This command deploys to Cloudflare. Review the Worker name, account,
    routes, environment, and current Wrangler login before running it. Keep
    tokens and other credentials out of project metadata and source control.

# Drive the publisher from Perl {#perl-api}

The MakeMaker and command-line entry points are conveniences. A script can construct the selected backend and dispatch the same actions directly.

``` perl
use strict;
use warnings;
use Markdown::Publish;

my $publish_or=Markdown::Publish->new({
    module  => 'starlight',
    name    => 'Example::Client',
    sources => ['doc'],
    output  => 'site',
});

my $site_dn=$publish_or->run('build');
```

To read a project file, call `Markdown::Publish->load_config()` or pass only `config_file` to the base constructor.

``` perl
my $publish_or=
    Markdown::Publish->load_config('doc/project.json');
$publish_or->run('serve');
```

Backend constructors are also available when the engine is already known. The supported actions are `build`, `serve`, `gh`, `gh-push`, and `cloudflare`.

# A practical documentation cycle {#practical-workflow}

A maintainable workflow keeps authored material, generated Markdown, site output, and remote publication distinct.

1.  Edit DocBook articles, Markdown articles, and source sidecars.

2.  Run `make doc` and review the generated Markdown and POD changes.

3.  Run `make publish_serve` and inspect navigation, links, code blocks, images, and the home page.

4.  Run `make publish_build` so strict or production-only build failures appear before publication.

5.  Commit the authored and durable generated documentation through the project's normal source-control workflow.

6.  Run `make publish_gh` and inspect the local branch, or run an explicitly authorised remote publication action.

Site assembly happens in temporary directories, while the rendered output uses `site/` by default. Keep generated site output out of the source branch unless the project has a specific reason to track it. The publication branch is the durable Git representation of that output.

# When something does not look right {#troubleshooting}

The site title is “Documentation”

: Set `name`. MakeMaker normally derives it from `NAME`, but standalone configurations need their own friendly name.

GitHub Pages has missing styles or broken links

: Check `base`. Leave it unset for normal repository-name inference, or set the exact path explicitly when the published URL differs.

A module sidecar is missing from navigation

: This is expected when `doc/` exists. Sidecars are mirrored for links, while top-level project articles form generated navigation. Name `lib/` explicitly as a source if those pages should become the primary publication.

An XML edit is absent from the site

: Run `make doc`. The publisher reads the sibling Markdown generated from the DocBook source.

A custom config loses generated navigation

: Use `config_extend` when you want to supplement generated defaults. A `config` file is intentionally authoritative.

The wrong engine runs

: Check `MARKDOWN_PUBLISH_MODULE` first because it overrides metadata and JSON configuration. Then check the `module` value in the active configuration source.

An npm installation fails without enough detail

: Set `MARKDOWN_PUBLISH_NPM_VERBOSE=1` and repeat the build to see normal npm output.

# Where to go next {#next-steps}

Start with MkDocs and convention-based discovery. Add explicit sources only when the default boundary is not the one you want. Add a supplemental configuration when the generated site needs a theme or integration. Move to an authoritative native configuration only when the project genuinely needs to own the engine's complete layout.

The module reference for `Markdown::Publish` describes its methods and publication contracts. The backend module references document engine-specific settings, and `ASPEER::MakeMaker::Markdown::Publish` documents the MakeMaker adapter. Use those references for exact API details; use this article as the end-to-end map of how the pieces fit together.
