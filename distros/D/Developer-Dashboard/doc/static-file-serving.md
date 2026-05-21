# Static File Serving Feature

## Overview

The Developer Dashboard now serves static files (JavaScript, CSS, images, and other assets) from a local public directory structure. This eliminates the need to download files from CDNs on every page load and provides better offline capability.

## Directory Structure

Static files are served from the effective lookup roots in this order:

1. `./.developer-dashboard/dashboard/public/...` when the current project has opted into a project-local runtime
2. `~/.developer-dashboard/dashboard/public/...`
3. the saved bookmark root `dashboards/public/...` for assets that ship beside saved bookmark files

Skill-local assets use a parallel route namespace:

1. `~/.developer-dashboard/skills/<repo-name>/dashboards/public/js/...` through `/js/<repo-name>/...`
2. `~/.developer-dashboard/skills/<repo-name>/dashboards/public/css/...` through `/css/<repo-name>/...`
3. `~/.developer-dashboard/skills/<repo-name>/dashboards/public/others/...` through `/others/<repo-name>/...`
4. nested child skills under `~/.developer-dashboard/skills/<repo-name>/skills/<sub-skill>/...`
   extend those same prefixes, for example
   `~/.developer-dashboard/skills/<repo-name>/skills/<sub-skill>/dashboards/public/js/foo/bar.js`
   maps to `/js/<repo-name>/<sub-skill>/foo/bar.js`

Skill-local Ajax handlers use:

1. `~/.developer-dashboard/skills/<repo-name>/dashboards/ajax/...` through `/ajax/<repo-name>/...`
2. nested child skills under
   `~/.developer-dashboard/skills/<repo-name>/skills/<sub-skill>/dashboards/ajax/...`
   map to `/ajax/<repo-name>/<sub-skill>/...`

The URL paths stay the same regardless of which on-disk root satisfies the
request.

When a request such as `/js/example-skill/foo/bar.js`,
`/js/example-skill/sub-skill/foo/bar.js`, or `/ajax/example-skill/sub-skill/foo`
does not exist in the skill-local tree, Developer Dashboard falls back to the
normal nested saved-bookmark path `dashboards/public/...` or `dashboards/ajax/...`
instead of assuming the leading path segments must always belong to a skill.

Example layout:
```
~/.developer-dashboard/dashboard/public/
├── js/          - JavaScript files
├── css/         - CSS stylesheets
└── others/      - Other static assets (images, JSON, XML, etc)
```

## Usage

Reference static files in bookmark HTML or page instructions using these URL patterns:

### JavaScript Files
```html
<script src="/js/jquery.js"></script>
<script src="/js/my-custom-script.js"></script>
<script src="/js/example-skill/skill.js"></script>
<script src="/js/example-skill/sub-skill/path/file.js"></script>
```

### CSS Stylesheets
```html
<link rel="stylesheet" href="/css/bootstrap.min.css">
<link rel="stylesheet" href="/css/custom-styles.css">
<link rel="stylesheet" href="/css/example-skill/skill.css">
<link rel="stylesheet" href="/css/example-skill/sub-skill/path/file.css">
```

### Other Assets (Images, Fonts, JSON, etc.)
```html
<img src="/others/logo.png">
<link rel="icon" href="/others/favicon.ico">
<script src="/others/config.json" type="application/json"></script>
<img src="/others/example-skill/icon.svg">
<img src="/others/example-skill/sub-skill/path/file.txt">
```

### Skill-local Ajax Endpoints
```html
<script>
var endpoints = {};
</script>
```

Skill bookmark CODE blocks can publish stable endpoints such as:

```perl
CODE1: Ajax jvar => 'endpoints.status', file => 'status', code => q{
print "ok\n";
};
```

When that page lives inside `~/.developer-dashboard/skills/example-skill/dashboards/...`,
the browser-facing endpoint becomes:

```text
/ajax/example-skill/status?type=text
```

Nested child skills extend that pattern:

```text
/ajax/example-skill/sub-skill/status?type=text
```

## Adding New Files

1. Copy your files to one of the appropriate directories:
   ```bash
   # JavaScript under the runtime public tree
   cp my-library.js ~/.developer-dashboard/dashboard/public/js/
   
   # CSS under the runtime public tree
   cp my-styles.css ~/.developer-dashboard/dashboard/public/css/
   
   # Images or other assets under the runtime public tree
   cp image.png ~/.developer-dashboard/dashboard/public/others/

   # Bookmark-local JavaScript shipped with saved pages
   cp jquery.js ~/.developer-dashboard/dashboards/public/js/
   ```

2. Reference them in your bookmark HTML:
   ```html
   <script src="/js/my-library.js"></script>
   <link rel="stylesheet" href="/css/my-styles.css">
   <img src="/others/image.png" alt="My Image">
   ```

## Supported File Types

The static file server automatically detects MIME types based on file extensions:

### JavaScript
- Extension: `.js`
- MIME Type: `application/javascript; charset=utf-8`

### CSS
- Extension: `.css`
- MIME Type: `text/css; charset=utf-8`

### JSON
- Extension: `.json`
- MIME Type: `application/json; charset=utf-8`

### XML
- Extension: `.xml`
- MIME Type: `application/xml; charset=utf-8`

### HTML
- Extension: `.html`, `.htm`
- MIME Type: `text/html; charset=utf-8`

### Text
- Extension: `.txt`
- MIME Type: `text/plain; charset=utf-8`

### Images
- `.svg` → `image/svg+xml`
- `.png` → `image/png`
- `.jpg`, `.jpeg` → `image/jpeg`
- `.gif` → `image/gif`
- `.webp` → `image/webp`
- `.ico` → `image/x-icon`

### Unknown Types
- Default: `application/octet-stream`

## Security

The static file server implements the following security measures:

1. **Directory Traversal Prevention**: Filenames containing `..` are rejected with a 400 Bad Request response.

2. **Directory Boundary Enforcement**: Files are verified to be within their designated public directory. Attempts to escape the public directory return a 403 Forbidden response.

3. **File Existence Check**: Non-existent or unreadable files return a 404 Not Found response.

4. **Read-Only Access**: Only readable files are served; the server does not support uploads or modifications.

## API Implementation

### Route Patterns
```
GET /js/<filename>      - Serve JavaScript files
GET /css/<filename>     - Serve CSS files
GET /others/<filename>  - Serve other static assets
GET /js/<repo-name>/<filename>     - Serve skill-local JavaScript files
GET /css/<repo-name>/<filename>    - Serve skill-local CSS files
GET /others/<repo-name>/<filename> - Serve skill-local assets
GET /ajax/<repo-name>/<filename>   - Serve skill-local saved Ajax handlers
GET /js/<repo-name>/<sub-skill>/<filename>     - Serve nested skill-local JavaScript files
GET /css/<repo-name>/<sub-skill>/<filename>    - Serve nested skill-local CSS files
GET /others/<repo-name>/<sub-skill>/<filename> - Serve nested skill-local assets
GET /ajax/<repo-name>/<sub-skill>/<filename>   - Serve nested skill-local saved Ajax handlers
```

### Response Codes
- `200` - File successfully served
- `400` - Bad request (e.g., directory traversal attempt)
- `403` - Forbidden (file outside public directory)
- `404` - File not found
- `500` - Internal server error

## Example Usage in Bookmarks

### jQuery AJAX Example
```
TITLE: AJAX Test
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>
$.ajax({
    url: '/ajax/test',
    type: 'GET',
    dataType: 'text',
    success: function (response) {
        console.log('Success:', response);
    },
    error: function (xhr, status, error) {
        console.error('Error:', error);
    }
});
</script>
<div id="result"></div>
:--------------------------------------------------------------------------------:
CODE1: Fetch from /ajax/test
```

### Multiple CSS and JS Files
```
TITLE: Styled Application
:--------------------------------------------------------------------------------:
HTML: <link rel="stylesheet" href="/css/bootstrap.min.css">
<link rel="stylesheet" href="/css/custom.css">
<script src="/js/jquery.js"></script>
<script src="/js/bootstrap.min.js"></script>
<script src="/js/app.js"></script>
<div id="app"></div>
:--------------------------------------------------------------------------------:
CODE1: Initialize application
```

## Performance Benefits

1. **No External Downloads**: All files are served locally, reducing latency and network dependency.

2. **Caching**: Files are served with appropriate Content-Type headers for browser caching.

3. **Offline Support**: Since files are stored locally, the dashboard can function offline.

4. **Faster Page Loads**: Reduced dependency on external CDNs eliminates CDN latency.

## File Size Limitations

Built-in compatibility asset:
- `/js/jquery.js` serves the bundled local copy of jQuery 4.0.0
- `/js/jquery-4.0.0.min.js` is kept as a compatibility alias for the same bundled payload

Additional files can be added as needed. There are no built-in size restrictions, but large files should be minified to optimize page load times.

## Troubleshooting

### Inline Bookmark Script Content Breaks the Editor
- Saved bookmark source is embedded back into the browser editor during edit/view-source routes.
- Literal HTML such as `</script>` is now escaped before the editor boot script assigns the source text, so inline bookmark scripts no longer spill raw source text below the page.

### Bookmark Ajax `set_chain_value` Errors on Play Routes
- `Ajax jvar => 'foo.bar', ...` helpers depend on the page bootstrap defining `set_chain_value()`.
- The bootstrap now loads before bookmark body HTML, so the generated binding script runs after the helper exists.

### File Not Found (404)
- Verify the file exists in the correct directory:
  - `./.developer-dashboard/dashboard/public/js/` for project-local JavaScript
  - `~/.developer-dashboard/dashboard/public/js/` for JavaScript
  - `./.developer-dashboard/dashboard/public/css/` for project-local CSS
  - `~/.developer-dashboard/dashboard/public/css/` for CSS
  - `./.developer-dashboard/dashboard/public/others/` for project-local assets
  - `~/.developer-dashboard/dashboard/public/others/` for other files
  - `./.developer-dashboard/dashboards/public/js/` for bookmark-local JavaScript
  - `./.developer-dashboard/dashboards/public/css/` for bookmark-local CSS
  - `./.developer-dashboard/dashboards/public/others/` for bookmark-local assets
- Check that the filename in the URL matches exactly (case-sensitive on Unix/Linux)
- Ensure the file has read permissions

### Forbidden (403)
- This indicates the file path is outside the designated public directory
- Do not use absolute paths; use relative paths like `/js/filename.js`
- Do not include path traversal attempts like `../` in the filename

### Wrong MIME Type
- If a file is served with an incorrect MIME type, rename it with the correct extension
- The server determines MIME type purely from file extension

## See Also

- `Developer::Dashboard::Web::App` - Main app module
- [Static Files Configuration](./public-static-files-config.md) - Configuration guide
