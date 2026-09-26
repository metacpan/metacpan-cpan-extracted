# NAME

markdown-publish - build, preview, and publish Perl distribution documentation

# USAGE

```sh
markdown-publish build
markdown-publish serve --config doc/project.json
markdown-publish gh --config doc/project.json
markdown-publish gh-push --config doc/project.json
markdown-publish cloudflare --config doc/project.json
```

`build` prepares and renders the site. `serve` starts the selected engine's
foreground local server. `gh` builds, updates the configured publication
branch, and leaves it local. Push that branch through the repository's normal
Git workflow. `gh-push` performs the same operation and then pushes the
publication branch to `origin`.

`cloudflare` builds the selected engine and deploys its output to a Cloudflare
Worker using the `cloudflare.config` Wrangler file in the JSON configuration.
It does not change a Git branch or push to GitHub.

MkDocs is used when no backend is selected. `--module` selects a backend when
no configuration file is used. Otherwise put `module` in the JSON configuration.
`MARKDOWN_PUBLISH_MODULE` overrides either selection. Bundled publishers may be
selected with `mkdocs`, `vitepress`, `docusaurus`, or `starlight`; a fully
qualified name may select another installed subclass. Without `--config`, an
existing `doc/project.json` is read automatically. Other options are repeatable
`--source DIRECTORY`, `--name`, `--base`, `--output`, and `--branch`. The base
must begin and end with `/`. For `gh` and `gh-push`, it defaults to the path
implied by the `origin` repository name: `/<repository>/`, or `/` for an
`<owner>.github.io` repository.

`--version` prints the installed program version.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
