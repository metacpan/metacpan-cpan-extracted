# NAME

Markdown::Publish::VitePress - publish distribution documentation with VitePress

# SYNOPSIS

```perl
use Markdown::Publish::VitePress;
my $publish_or=Markdown::Publish::VitePress->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine assembles documents, writes generated navigation when no authored
configuration is supplied, and runs VitePress in a temporary npm project.
Set `config` to an authored VitePress configuration; its original location is
preserved for relative imports. `npm`, `version`, `host`, `port`, and `output`
customise operation. `prepare` returns the temporary root, documentation
directory, and configuration path; `build` returns the site directory; `serve`
runs the foreground server. For generated configuration, `base` sets
VitePress's deployment base path. An authored configuration remains
authoritative.

Set `config_extend` to an ECMAScript module whose default export is a function
accepting `(config, context)`. It may return the generated configuration after
adding VitePress settings; synchronous and asynchronous functions are accepted.
The context contains the generated publication name, base, output, pages, and
navigation. `config` and `config_extend` cannot be combined.

```javascript
export default (config) => ({
  ...config,
  themeConfig: {...config.themeConfig, search: {provider: 'local'}},
});
```

# SEE ALSO

`Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
