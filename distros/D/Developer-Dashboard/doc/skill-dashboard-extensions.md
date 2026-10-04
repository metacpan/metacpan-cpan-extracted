# Skill Dashboard Extensions

An installed skill can extend the shared Dancer2 dashboard application by
providing `lib/Dashboard.pm` beneath its skill directory. The dashboard scans
active installed skills recursively when the web application starts, including
the startup paths used by `d2 restart`, `d2 restart web`, and `d2 serve`.

## Example

```perl
package Dashboard;
use Dancer2 appname => 'DeveloperDashboard';

get '/skill-status' => sub {
    return { status => 'ready' };
};

1;
```

Place skill-specific modules in that skill's `lib/`; that directory is added
to `@INC` while the extension loads. Use the shared `DeveloperDashboard`
application name so routes and settings join the dashboard's application.
New skill routes are placed before the dashboard catch-all route. Existing
core routes retain precedence.

## Security and operation

These files are trusted Perl code and execute during dashboard startup. Keep
them under the skill's own `lib/` directory; symlinks resolving outside that
directory are rejected. Extension routes pass through the dashboard's normal
authorization gate. A load or authorization integration error is reported and
prevents startup rather than silently disabling an extension. Test extensions
in the development service before enabling them in a production runtime.

See `t/76-web-dancerapp-coverage.t` for route, settings, authorization, and
startup coverage.

## Perl modules in skill pages and commands

For a page served from `/app/<skill>/<page>`, its CODE blocks place the exact
skill layer that supplied the page first in scoped `@INC`; other participating
skill layers follow. For a Perl script under `cli/`, the layer providing that
script is first in child-process `@INC` and `PERL5LIB`, before inherited skill
libraries and shared local Perl libraries. For example, `lib/DB.pm` can be
loaded with `use DB;` from either a page CODE block or the skill CLI without
manually modifying `@INC` or `PERL5LIB`.

The regression checks are in `t/116-pageruntime-coverage-2.t` and
`t/104-skilldispatcher-coverage.t`; both print `@INC` from the executed code
and assert that the owning skill's library directory is first.
