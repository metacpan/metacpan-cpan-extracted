package Developer::Dashboard::PageDocument;

use strict;
use warnings;

our $VERSION = '2.76';

use Developer::Dashboard::JSON qw(json_decode json_encode);

our $LEGACY_SEP = ':--------------------------------------------------------------------------------:';
our @LEGACY_KEYS = ( qw(TITLE ICON BOOKMARK STASH NOTE HTML), map { sprintf 'CODE%d', $_ } 0 .. 1000 );

# new(%args)
# Constructs a page document from normalized field values.
# Input: page fields such as id, title, state, layout, and actions.
# Output: Developer::Dashboard::PageDocument object.
sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        id             => $args{id},
        title          => $args{title} // 'Untitled',
        description    => $args{description} // '',
        source_version => $args{source_version} // 1,
        mode           => $args{mode} // 'edit',
        tags           => $args{tags} || [],
        inputs         => $args{inputs} || [],
        state          => $args{state} || {},
        layout         => $args{layout} || {},
        actions        => $args{actions} || [],
        permissions    => $args{permissions} || {},
        meta           => $args{meta} || {},
    }, $class;

    return $self;
}

# from_hash($hash)
# Builds a page document from a plain hash structure.
# Input: page hash reference.
# Output: Developer::Dashboard::PageDocument object.
sub from_hash {
    my ( $class, $hash ) = @_;
    die 'Page document must be a hash reference' if ref($hash) ne 'HASH';
    return $class->new(%$hash);
}

# from_json($json)
# Builds a page document from JSON text.
# Input: JSON text string.
# Output: Developer::Dashboard::PageDocument object.
sub from_json {
    my ( $class, $json ) = @_;
    return $class->from_hash( json_decode($json) );
}

# from_instruction($text)
# Parses canonical instruction text into a page document.
# Input: instruction document text string.
# Output: Developer::Dashboard::PageDocument object.
sub from_instruction {
    my ( $class, $text ) = @_;
    $text = '' if !defined $text;

    my $source_format = 'modern';
    my %sections;
    if ( $text =~ /^===\s*[A-Z][A-Z0-9.]*\s*===/m ) {
        my $current = '';
        my @lines = split /\n/, $text, -1;
        for my $line (@lines) {
            if ( $line =~ /^===\s*([A-Z][A-Z0-9.]*)\s*===\s*$/ ) {
                $current = $1;
                $sections{$current} = [];
                next;
            }
            next if $current eq '';
            push @{ $sections{$current} }, $line;
        }
    }
    else {
        $source_format = 'legacy';
        %sections = _parse_legacy_sections($text);
    }

    die 'Instruction document did not contain any sections' if !keys %sections;

    my $state = _decode_stash_section( join( "\n", @{ $sections{STASH} || [] } ) );

    my %meta = ();
    $meta{icon} = _trim( join( "\n", @{ $sections{ICON} || [] } ) ) if exists $sections{ICON};

    my @codes;
    for my $section ( sort grep { /^CODE\d+$/ } keys %sections ) {
        push @codes, {
            id   => $section,
            body => _trim_trailing_newline( join( "\n", @{ $sections{$section} } ) ),
        };
    }
    $meta{codes} = \@codes if @codes;

    my $page = $class->new(
        id          => _trim( join( "\n", @{ $sections{BOOKMARK} || [] } ) ) || undef,
        title       => _trim( join( "\n", @{ $sections{TITLE} || [] } ) ) || 'Untitled',
        description => _trim_trailing_newline( join( "\n", @{ $sections{NOTE} || $sections{DESCRIPTION} || [] } ) ),
        state       => $state,
        layout      => {
            body => _trim_trailing_newline( join( "\n", @{ $sections{HTML} || [] } ) ),
        },
        meta        => {
            %meta,
            source_format => $source_format,
        },
    );

    return $page;
}

# merge_state($state)
# Merges runtime state into the page state hash.
# Input: state hash reference.
# Output: page document object.
sub merge_state {
    my ( $self, $state ) = @_;
    return $self if ref($state) ne 'HASH';

    for my $key ( keys %$state ) {
        $self->{state}{$key} = $state->{$key};
    }

    return $self;
}

# with_mode($mode)
# Sets the active page mode when a non-empty mode is given.
# Input: mode string.
# Output: page document object.
sub with_mode {
    my ( $self, $mode ) = @_;
    $self->{mode} = $mode if defined $mode && $mode ne '';
    return $self;
}

# as_hash()
# Returns the page document as a plain Perl hash structure.
# Input: none.
# Output: page hash reference.
sub as_hash {
    my ($self) = @_;
    return {
        id             => $self->{id},
        title          => $self->{title},
        description    => $self->{description},
        source_version => $self->{source_version},
        mode           => $self->{mode},
        tags           => $self->{tags},
        inputs         => $self->{inputs},
        state          => $self->{state},
        layout         => $self->{layout},
        actions        => $self->{actions},
        permissions    => $self->{permissions},
        meta           => $self->{meta},
    };
}

# canonical_json()
# Serializes the page document to canonical JSON.
# Input: none.
# Output: JSON text string.
sub canonical_json {
    my ($self) = @_;
    return json_encode( $self->as_hash );
}

# canonical_instruction()
# Serializes the page document to canonical instruction text.
# Input: none.
# Output: instruction document string.
sub canonical_instruction {
    my ($self) = @_;
    return $self->legacy_instruction;
}

# legacy_instruction()
# Serializes the page document to older colon-and-separator bookmark syntax.
# Input: none.
# Output: older instruction document string.
sub legacy_instruction {
    my ($self) = @_;
    my @sections;

    push @sections, [ 'TITLE', $self->{title} // 'Untitled' ];
    push @sections, [ 'ICON', $self->{meta}{icon} ] if defined $self->{meta}{icon} && $self->{meta}{icon} ne '';
    push @sections, [ 'BOOKMARK', $self->{id} ] if defined $self->{id} && $self->{id} ne '';
    push @sections, [ 'NOTE', $self->{description} ] if defined $self->{description} && $self->{description} ne '';
    push @sections, [ 'STASH', _legacy_stash_text( $self->{state} || {} ) ];
    push @sections, [ 'HTML', $self->{layout}{body} ] if defined $self->{layout}{body} && $self->{layout}{body} ne '';

    if ( ref( $self->{meta}{codes} ) eq 'ARRAY' ) {
        for my $code ( @{ $self->{meta}{codes} } ) {
            next if ref($code) ne 'HASH';
            my $id = $code->{id} || '';
            next if $id !~ /^CODE\d+$/;
            push @sections, [ $id, $code->{body} // '' ];
        }
    }

    my @chunks = map {
        my ( $name, $body ) = @$_;
        $body = '' if !defined $body;
        $body =~ s/\A\n+//;
        $body =~ s/\n+\z//;
        "$name: $body";
    } @sections;

    return join( "\n$LEGACY_SEP\n", @chunks ) . "\n";
}

# instruction_text()
# Returns the canonical instruction text alias.
# Input: none.
# Output: instruction document string.
sub instruction_text { return shift->canonical_instruction(@_) }

# render_template($text, %context)
# Expands simple [% key %] and [% parts.key %] placeholders from page context.
# Input: template text plus flat and nested context values.
# Output: rendered text string.
sub render_template { return shift; }

# render_html(%opts)
# Renders the page document into HTML for browser display.
# Input: optional action_urls, page_url, chrome_html, and nav_html values.
# Output: HTML string.
sub render_html {
    my ( $self, %opts ) = @_;

    my $title = _html( $self->{title} );
    my $desc  = _html( $self->{description} );
    my $body_html = defined $self->{layout}{body} ? $self->{layout}{body} : '';
    my $chrome_html = defined $opts{chrome_html} ? $opts{chrome_html} : '';
    my $nav_html = defined $opts{nav_html} ? $opts{nav_html} : '';

    my $runtime_bootstrap = '';
    my $runtime_output = '';
    for my $chunk ( @{ $self->{meta}{runtime_outputs} || [] } ) {
        next if !defined $chunk || ref($chunk);
        if ( $chunk =~ /\A<script>/ && $chunk =~ /(set_chain_value|dashboard_ajax_singleton_cleanup)/ ) {
            $runtime_bootstrap .= $chunk;
            next;
        }
        $runtime_output .= $chunk;
    }
    my $runtime_errors = '';
    for my $chunk ( @{ $self->{meta}{runtime_errors} || [] } ) {
        next if !defined $chunk || ref($chunk);
        $runtime_errors .= qq{<pre class="runtime-error">} . _html($chunk) . qq{</pre>\n};
    }
    my $legacy_bootstrap = _legacy_bootstrap();

    return <<"HTML";
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <style>
    :root {
      --bg: #f7f4ec;
      --panel: #fffdf7;
      --ink: #1f2a2e;
      --muted: #6a767b;
      --line: #d9d3c7;
      --accent: #0b7a75;
    }
    body {
      margin: 0;
      font-family: Georgia, "Times New Roman", serif;
      background: linear-gradient(180deg, #f2efe6 0%, #f7f4ec 100%);
      color: var(--ink);
    }
    main {
      max-width: 880px;
      margin: 32px auto;
      background: var(--panel);
      border: 1px solid var(--line);
      box-shadow: 0 12px 40px rgba(0,0,0,0.08);
      padding: 28px;
    }
    .body {
      line-height: 1.6;
      padding: 0 0 24px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
    }
    th, td {
      text-align: left;
      border-bottom: 1px solid var(--line);
      padding: 10px 8px;
      vertical-align: top;
    }
    th {
      width: 30%;
      color: var(--muted);
    }
    ul {
      padding-left: 20px;
    }
    .pill {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 999px;
      background: #dff3ef;
      color: var(--accent);
      font-size: 0.9rem;
    }
    .runtime-error {
      color: #b00020;
      white-space: pre-wrap;
    }
    .dashboard-nav-items {
      margin: 0 0 24px;
      padding: 14px 18px;
      border: 1px solid var(--line);
      background: var(--panel, #f3eee2);
      color: var(--text, var(--ink));
      border-radius: 14px;
    }
    .dashboard-nav-items ul {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-wrap: wrap;
      gap: 10px 18px;
      align-items: center;
    }
    .dashboard-nav-items li {
      margin: 0;
      padding: 0;
    }
    .dashboard-nav-items li + li {
      margin-top: 0;
      padding-top: 0;
      border-top: 0;
    }
    .dashboard-nav-items a {
      color: var(--text, var(--ink));
      text-decoration-color: var(--accent, currentColor);
    }
    .dashboard-nav-items a:hover {
      color: var(--accent, var(--text, var(--ink)));
    }
  </style>
</head>
<body>
$legacy_bootstrap
<main>
  $chrome_html
  $nav_html
  @{[ $desc ne '' ? qq{<p>$desc</p>} : '' ]}
  <section class="body">$body_html</section>
  $runtime_bootstrap
  $runtime_output
  $runtime_errors
</main>
</body>
</html>
HTML
}

# _decode_structured_json($text)
# Safely decodes structured JSON from instruction sections.
# Input: text block string.
# Output: decoded Perl value or empty hash reference on failure.
sub _decode_structured_json {
    my ($text) = @_;
    $text = _trim($text);
    return {} if $text eq '';
    my $value = eval { json_decode($text) };
    return defined $value ? $value : {};
}

# _decode_stash_section($text)
# Decodes older or modern STASH content into a hash reference.
# Input: stash section text string.
# Output: hash reference or empty hash reference on failure.
sub _decode_stash_section {
    my ($text) = @_;
    $text = _trim($text);
    return {} if $text eq '';
    if ( $text =~ /\A[\{\[]/ ) {
        my $value = eval { json_decode($text) };
        return $value if ref($value) eq 'HASH';
        return {};
    }
    my $hash = eval "+{ $text }";
    return ref($hash) eq 'HASH' ? $hash : {};
}

# _parse_legacy_sections($text)
# Parses older bookmark syntax separated by the older separator line.
# Input: full older bookmark text string.
# Output: hash of section name to arrayref of lines.
sub _parse_legacy_sections {
    my ($text) = @_;
    my %sections;
    my $markdown_sep = qr{^\s*---\s*$}m;
    my @parts = split /(?:\Q$LEGACY_SEP\E\s*\n?|$markdown_sep)/, $text;
    for my $part (@parts) {
        $part =~ s/\A[\r\n\s]+//;
        $part =~ s/[\r\n\s]+\z//;
        next if $part eq '';
        next if $part !~ /^([A-Za-z][A-Za-z0-9.]*)\s*:\s*(.*)$/s;
        my ( $name, $body ) = ( uc($1), $2 );
        $body =~ s/\A\s+//;
        next if !$name || !grep { $_ eq $name || ( $name =~ /^CODE\d+$/ && /^CODE\d+$/ ) } @LEGACY_KEYS;
        $sections{$name} = [ split /\n/, $body, -1 ];
    }
    return %sections;
}

# _legacy_stash_text($value)
# Serializes a hash reference into a simple older STASH body.
# Input: stash hash reference.
# Output: Perl-like older stash text.
sub _legacy_stash_text {
    my ($value) = @_;
    return '' if ref($value) ne 'HASH' || !keys %$value;
    my @pairs = map { sprintf "%s => %s", $_, _legacy_value( $value->{$_} ) } sort keys %$value;
    return join ",\n", @pairs;
}

# _legacy_value($value)
# Serializes a Perl scalar, array, or hash into a older bookmark value string.
# Input: scalar, array reference, or hash reference.
# Output: Perl-ish text string.
sub _legacy_value {
    my ($value) = @_;
    return 'undef' if !defined $value;
    if ( ref($value) eq 'ARRAY' ) {
        return "[\n  " . join( ",\n  ", map { _legacy_value($_) } @$value ) . "\n]";
    }
    if ( ref($value) eq 'HASH' ) {
        return "{\n  " . join( ",\n  ", map { sprintf "%s => %s", $_, _legacy_value( $value->{$_} ) } sort keys %$value ) . "\n}";
    }
    return $value =~ /\A-?\d+(?:\.\d+)?\z/ ? $value : "'" . _legacy_quote($value) . "'";
}

# _legacy_quote($text)
# Escapes a scalar string for older single-quoted stash serialization.
# Input: text string.
# Output: escaped string.
sub _legacy_quote {
    my ($text) = @_;
    $text =~ s/\\/\\\\/g;
    $text =~ s/'/\\'/g;
    return $text;
}

# _template_value($path, $context)
# Resolves a simple dot path from template context for placeholder expansion.
# Input: placeholder path string and context hash reference.
# Output: scalar string.
sub _template_value {
    my ( $path, $context ) = @_;
    my @parts = grep { defined && $_ ne '' } split /\./, _trim($path);
    my $value = $context;
    for my $part (@parts) {
        return '' if ref($value) ne 'HASH' || !exists $value->{$part};
        $value = $value->{$part};
    }
    return '' if !defined $value || ref($value);
    return $value;
}

# _legacy_bootstrap()
# Returns the older client bootstrap helpers used by old bookmark pages.
# Input: none.
# Output: JavaScript bootstrap string.
sub _legacy_bootstrap {
    return <<'JS';
<script>
function set_chain_value(obj, path, value) {
  let keys = (path || '').split('.');
  let current = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {};
    current = current[keys[i]];
  }
  current[keys[keys.length - 1]] = value;
}
function dashboard_ajax_singleton_cleanup(name) {
  if (!name) return;
  if (!window.__dashboardAjaxSingletons) window.__dashboardAjaxSingletons = {};
  if (window.__dashboardAjaxSingletons[name]) return;
  window.__dashboardAjaxSingletons[name] = true;
  window.addEventListener('pagehide', function() {
    let url = '/ajax/singleton/stop?singleton=' + encodeURIComponent(name);
    if (navigator.sendBeacon) {
      navigator.sendBeacon(url, '');
      return;
    }
    if (window.fetch) {
      fetch(url, { method: 'POST', keepalive: true, credentials: 'same-origin' }).catch(function () {});
    }
  });
}
function dashboard_target_nodes(target) {
  if (!target) return [];
  if (typeof target === 'string') return Array.prototype.slice.call(document.querySelectorAll(target));
  if (target instanceof Element) return [target];
  if (target.length && typeof target !== 'string') return Array.prototype.slice.call(target);
  return [];
}
function dashboard_render_value(value, options, formatter) {
  let rendered = value;
  if (options && options.type === 'json' && typeof value === 'string' && value !== '') {
    try {
      rendered = JSON.parse(value);
    } catch (error) {
      rendered = null;
    }
  }
  if (typeof formatter === 'function') return formatter(rendered);
  if (rendered === null || typeof rendered === 'undefined') return '';
  if (typeof rendered === 'object') return JSON.stringify(rendered);
  return String(rendered);
}
function dashboard_write_target(target, value, options, formatter) {
  let nodes = dashboard_target_nodes(target);
  let rendered = dashboard_render_value(value, options || {}, formatter);
  nodes.forEach(function(node) {
    if (options && options.type === 'html') {
      node.innerHTML = rendered;
      return;
    }
    if (node.tagName === 'INPUT' || node.tagName === 'TEXTAREA') {
      node.value = rendered;
      return;
    }
    node.textContent = rendered;
  });
  return rendered;
}
function fetch_value(url, target, options, formatter) {
  if (!url || !window.fetch) return Promise.resolve('');
  let settings = Object.assign({ credentials: 'same-origin' }, (options && options.fetch) || {});
  return window.fetch(url, settings).then(function(response) {
    if (!response.ok) throw new Error('Request failed with status ' + response.status);
    if (options && options.type === 'json') return response.text();
    return response.text();
  }).then(function(value) {
    return dashboard_write_target(target, value, options || {}, formatter);
  });
}
function dashboard_stream_settings(options) {
  let fetchOptions = (options && options.fetch) || {};
  let method = fetchOptions.method || options.method || 'GET';
  let body = typeof fetchOptions.body !== 'undefined' ? fetchOptions.body : (typeof options.body !== 'undefined' ? options.body : null);
  let headers = fetchOptions.headers || options.headers || {};
  let credentials = fetchOptions.credentials || options.credentials || 'same-origin';
  return {
    method: method,
    body: body,
    headers: headers,
    credentials: credentials
  };
}
function stream_data(url, target, options, formatter) {
  if (!url) return Promise.resolve('');
  if (!window.XMLHttpRequest) return fetch_value(url, target, options, formatter);
  let settings = dashboard_stream_settings(options || {});
  return new Promise(function(resolve, reject) {
    let xhr = new XMLHttpRequest();
    xhr.open(settings.method, url, true);
    xhr.withCredentials = settings.credentials !== 'omit';
    Object.keys(settings.headers || {}).forEach(function(name) {
      xhr.setRequestHeader(name, settings.headers[name]);
    });
    xhr.onprogress = function () {
      dashboard_write_target(target, xhr.responseText, options || {}, formatter);
    };
    xhr.onload = function () {
      if (xhr.status < 200 || xhr.status >= 300) {
        reject(new Error('Request failed with status ' + xhr.status));
        return;
      }
      resolve(dashboard_write_target(target, xhr.responseText, options || {}, formatter));
    };
    xhr.onerror = function () {
      reject(new Error('Stream request failed'));
    };
    xhr.send(settings.body);
  });
}
function stream_value(url, target, options, formatter) {
  return stream_data(url, target, options, formatter);
}
var ready_status = {};
function ready(options) {
  let doit = options.doit || function() {};
  let is_ok = options.is_ok || function() { return true; };
  let next = options.next || function() {};
  let fail = options.fail;
  let retries = 0;
  let max_retry = options.num_of_retry;
  let interval = (options.retry_interval || 1) * 1000;
  doit();
  let handle = setInterval(function() {
    if (is_ok()) {
      clearInterval(handle);
      return next();
    }
    retries++;
    if (max_retry && retries >= max_retry) {
      clearInterval(handle);
      if (fail) fail();
    }
  }, interval);
}
if (!window.configs) window.configs = {};
</script>
JS
}

# _trim($text)
# Trims leading and trailing whitespace from a text string.
# Input: text string.
# Output: trimmed text string.
sub _trim {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

# _trim_trailing_newline($text)
# Removes trailing newlines from a text block.
# Input: text string.
# Output: normalized text string.
sub _trim_trailing_newline {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\n+\z//;
    return $text;
}

# _html($text)
# Escapes text for safe HTML rendering.
# Input: text string.
# Output: escaped string.
sub _html {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    return $text;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PageDocument - common page model for Developer Dashboard

=head1 SYNOPSIS

  my $page = Developer::Dashboard::PageDocument->from_instruction($text);
  print $page->canonical_instruction;

=head1 DESCRIPTION

This module represents the common internal page model used by saved pages,
transient encoded pages, and provider-generated pages.

=head1 METHODS

=head2 new, from_hash, from_json, from_instruction, merge_state, with_mode, as_hash, canonical_json, canonical_instruction, instruction_text, render_html

Construct, mutate, serialize, and render page documents.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module parses and normalizes dashboard bookmark instruction documents. It understands the separator-based bookmark format, extracts fields such as C<TITLE>, C<BOOKMARK>, C<STASH>, C<HTML>, and C<CODE*> blocks, and preserves the raw instruction when callers need source-stable editing behavior.

=head1 WHY IT EXISTS

It exists because bookmark parsing is a core format contract. The editor, renderer, source view, seeded pages, and saved page store all need the same understanding of how a bookmark document is shaped.

=head1 WHEN TO USE

Use this file when changing bookmark syntax, source preservation, directive parsing, or any workflow that reads or writes the text instruction format behind saved pages.

=head1 HOW TO USE

Create or load a page document through the parsing helpers, then pass the normalized structure into the page runtime, page store, or web routes. Keep bookmark syntax rules in this module instead of scattering regex parsing around the codebase.

=head1 WHAT USES IT

It is used by page storage and rendering, by skill bookmark routing, by init/seed flows, and by tests that guard the bookmark document grammar.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::PageDocument -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
