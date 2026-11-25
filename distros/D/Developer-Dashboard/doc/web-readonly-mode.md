# Web Serve Modes

`d2 serve --no-editor` and `d2 serve --no-endit` start the web
service in browser read-only mode.

In that mode:

- saved page render routes still work
- the top-left Share, Play, and View Source links are hidden
- `/app/<id>/edit` is denied with `403`
- `/app/<id>/source` is denied with `403`
- bookmark-save POST requests are denied with `403`
- the setting is persisted in `config/config.json` under `web.no_editor`
- `d2 restart` keeps the same read-only state until a later
  `d2 serve --editor` run turns it off again

This mode is for serving existing saved pages without exposing the bookmark
editor or raw bookmark source through the browser.

`d2 serve --no-indicators` and `d2 serve --no-indicator` start
the web service with the whole top-right browser chrome area cleared.

In that mode:

- saved page render routes still work
- the left-side Share, Play, View Source, and Logout links still behave as normal
- the right-top indicator strip is hidden
- the right-top username is hidden
- the right-top host or IP link is hidden
- the right-top live date-time line is hidden
- `/system/status` still returns the normal indicator payload
- terminal prompt output such as `d2 ps1` is unchanged
- the setting is persisted in `config/config.json` under `web.no_indicators`
- `d2 restart` keeps the same browser-only chrome state until a later
  `d2 serve --indicators` run turns it back on again

This mode is for serving existing saved pages while removing the browser-only
top-right chrome area without changing non-browser indicator behavior.
