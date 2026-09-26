# NAME

Markdown::Publish::Starlight - publish distribution documentation with Astro Starlight

# SYNOPSIS

```perl
use Markdown::Publish::Starlight;
my $publish_or=Markdown::Publish::Starlight->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine assembles documents and an ordered sidebar in a temporary Astro
Starlight project. Set `config` to an authored Astro configuration, or let the
engine create one. `npm`, `astro_version`, `starlight_version`, `host`, `port`,
and `output` customise operation. `prepare` returns the temporary root,
project directory, and configuration path; `build` returns the site directory;
`serve` runs the foreground server. For generated configuration, `base` sets
Astro's deployment base path. An authored configuration remains authoritative.
Local Markdown links such as `lib/Example/Module.pm.md` are resolved to the
corresponding Starlight page in the temporary project. An authored Astro
configuration is wrapped to retain this behavior; its Markdown processor must
be unified if it sets one explicitly.

Set `config_extend` to an ECMAScript module whose default export receives
`({astro, starlight}, context)`. It must return both objects. `astro` contains
the generated Astro settings and required Markdown processor; `starlight`
contains the generated title and sidebar options passed to the Starlight
integration. Extra `astro.integrations` are retained after the Starlight
integration. Synchronous and asynchronous functions are accepted. `config`
and `config_extend` cannot be combined.

```javascript
export default ({astro, starlight}) => ({
  astro,
  starlight: {
    ...starlight,
    social: [{icon: 'github', label: 'GitHub', href: 'https://github.com/example/project'}],
  },
});
```

# SEE ALSO

`Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
