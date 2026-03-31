package Developer::Dashboard::Web::App;
$Developer::Dashboard::Web::App::VERSION = '0.72';
use strict;
use warnings;

use Capture::Tiny qw(capture);
use POSIX qw(strftime);
use URI;
use URI::Escape qw(uri_unescape);
use Cwd qw(cwd);

use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::Codec qw(decode_payload);

# new(%args)
# Constructs the browser-facing dashboard web application.
# Input: auth, pages, sessions, and optional actions/resolver objects.
# Output: Developer::Dashboard::Web::App object.
sub new {
    my ( $class, %args ) = @_;
    my $auth     = $args{auth}     || die 'Missing auth store';
    my $pages    = $args{pages}    || die 'Missing page store';
    my $sessions = $args{sessions} || die 'Missing session store';
    return bless {
        actions  => $args{actions},
        auth     => $auth,
        pages    => $pages,
        prompt   => $args{prompt},
        runtime  => $args{runtime} || Developer::Dashboard::PageRuntime->new,
        resolver => $args{resolver},
        sessions => $sessions,
    }, $class;
}

# handle(%args)
# Dispatches a single normalized web request into the dashboard app.
# Input: request path, query, method, headers, body, and remote address.
# Output: array reference of status code, content type, body, and optional headers hash.
sub handle {
    my ( $self, %args ) = @_;
    my $path    = $args{path}    || '/';
    my $query   = $args{query}   || '';
    my $method  = uc( $args{method} || 'GET' );
    my $headers = $args{headers} || {};
    my $body    = defined $args{body} ? $args{body} : '';

    my %params = _parse_query($query);
    my %body_params = $method eq 'POST' ? _parse_query($body) : ();
    my $tier = $self->{auth}->trust_tier(
        remote_addr => $args{remote_addr},
        host        => $headers->{host},
    );
    my $session;

    if ( $path eq '/login' && $method eq 'POST' ) {
        return $self->_handle_login(
            body        => $body,
            remote_addr => $args{remote_addr},
        );
    }

    if ( $path eq '/logout' ) {
        $session = $self->{sessions}->from_cookie( $headers->{cookie}, remote_addr => $args{remote_addr} );
        if ($session) {
            if ( ( $session->{role} || '' ) eq 'helper' && ( $session->{username} || '' ) ne '' ) {
                $self->{auth}->remove_user( $session->{username} );
            }
            $self->{sessions}->delete( $session->{session_id} );
        }
        return [
            302,
            'text/plain; charset=utf-8',
            "Redirecting\n",
            {
                'Location'   => '/login',
                'Set-Cookie' => _expired_session_cookie(),
            },
        ];
    }

    if ( $tier ne 'admin' ) {
        $session = $self->{sessions}->from_cookie( $headers->{cookie}, remote_addr => $args{remote_addr} );
        if ( !$session ) {
            return [ 401, 'text/html; charset=utf-8', $self->{auth}->login_page ];
        }
    }
    $self->{_current_request_context} = {
        tier        => $tier,
        remote_addr => $args{remote_addr} || '',
        host        => $headers->{host} || '',
        username    => ref($session) eq 'HASH' ? ( $session->{username} || '' ) : '',
        role        => ref($session) eq 'HASH' ? ( $session->{role} || '' ) : '',
    };

    if ( $path eq '/' ) {
        if ( exists $body_params{instruction} || exists $params{instruction} ) {
            my $instruction = exists $body_params{instruction} ? $body_params{instruction} : $params{instruction};
            my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
            $page->{meta}{raw_instruction} = $instruction;
            my $source_kind = 'transient';
            if ( exists $body_params{instruction} && ( $page->as_hash->{id} || '' ) ne '' ) {
                $self->{pages}->save_page($page);
                $source_kind = 'saved';
            }
            $page->{meta}{source_kind} = $source_kind;
            my $mode = $params{mode} || $body_params{mode} || 'edit';
            $page = $self->_page_with_runtime_state(
                $page,
                query_params => \%params,
                body_params  => \%body_params,
                path         => $path,
                remote_addr  => $args{remote_addr},
                headers      => $headers,
            );
            $page = $self->{runtime}->prepare_page(
                page            => $page,
                source          => $source_kind,
                runtime_context => { params => { %params, %body_params } },
            );
            return $self->_page_response( $page, $mode );
        }
        if ( my $token = $params{token} ) {
            my $page = $self->{pages}->load_transient_page($token);
            $page->{meta}{raw_instruction} = $page->canonical_instruction;
            my $mode = $params{mode} || 'edit';
            $page = $self->_page_with_runtime_state(
                $page,
                query_params => \%params,
                body_params  => \%body_params,
                path         => $path,
                remote_addr  => $args{remote_addr},
                headers      => $headers,
            );
            $page = $self->{runtime}->prepare_page(
                page            => $page,
                source          => 'transient',
                runtime_context => { params => { %params, %body_params } },
            );
            return $self->_page_response( $page, $mode );
        }

        return $self->_blank_editor_response;
    }

    if ( $path eq '/apps' ) {
        return [
            302,
            'text/plain; charset=utf-8',
            "Redirecting\n",
            { Location => '/app/index' },
        ];
    }

    if ( $path eq '/ajax' ) {
        return $self->_legacy_ajax_response(
            params       => { %params, %body_params },
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
    }

    if ( $path eq '/system/status' ) {
        my $payload = $self->_page_status_payload;
        return [ 200, 'application/json; charset=utf-8', json_encode($payload) ];
    }

    if ( $path eq '/marked.min.js' ) {
        return [ 200, 'application/javascript; charset=utf-8', "window.marked=window.marked||{parse:function(s){return s||'';}};\n" ];
    }

    if ( $path eq '/tiff.min.js' ) {
        return [ 200, 'application/javascript; charset=utf-8', "window.Tiff=window.Tiff||function(){};\n" ];
    }

    if ( $path eq '/loading.webp' ) {
        return [ 200, 'image/webp', '' ];
    }

    if ( $path =~ m{^/app/([^/]+)$} ) {
        return $self->_legacy_app_response(
            id           => $1,
            query_params => \%params,
            body_params  => \%body_params,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
    }

    if ( $path eq '/action' && $method eq 'POST' ) {
        if ( my $atoken = $params{atoken} ) {
            return $self->_encoded_action_response(
                token  => $atoken,
                params => { %params, %body_params },
            );
        }
        my $token = exists $params{token} ? $params{token} : ( $body_params{token} || '' );
        my $id    = exists $params{id}    ? $params{id}    : ( $body_params{id}    || '' );
        my $page  = $self->{pages}->load_transient_page($token);
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => \%params,
            body_params  => \%body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        return $self->_action_response(
            id     => $id,
            page   => $page,
            source => 'transient',
            params => { %params, %body_params },
        );
    }

    if ( $path =~ m{^/page/([^/]+)/source$} ) {
        my $page = $self->_load_named_page($1);
        $page->{meta}{raw_instruction} = $page->canonical_instruction;
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => \%params,
            body_params  => \%body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => $page->{meta}{source_kind} || 'saved',
            runtime_context => { params => { %params, %body_params } },
        );
        return [ 200, 'text/plain; charset=utf-8', $page->{meta}{raw_instruction} || $page->canonical_instruction ];
    }

    if ( $path =~ m{^/page/([^/]+)/edit$} ) {
        my $page = $self->_load_named_page($1);
        $page->{meta}{raw_instruction} = $page->canonical_instruction;
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => \%params,
            body_params  => \%body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => $page->{meta}{source_kind} || 'saved',
            runtime_context => { params => { %params, %body_params } },
        );
        return [ 200, 'text/html; charset=utf-8', $self->_edit_html($page) ];
    }

    if ( $path =~ m{^/page/([^/]+)/action/([^/]+)$} && $method eq 'POST' ) {
        my $page = $self->_load_named_page($1);
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => \%params,
            body_params  => \%body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => $page->{meta}{source_kind} || 'saved',
            runtime_context => { params => { %params, %body_params } },
        );
        return $self->_action_response(
            id     => $2,
            page   => $page,
            source => $page->{meta}{source_kind} || 'saved',
            params => { %params, %body_params },
        );
    }

    if ( $path =~ m{^/page/([^/]+)$} ) {
        my $page = $self->_load_named_page($1);
        $page->{meta}{raw_instruction} = $page->canonical_instruction;
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => \%params,
            body_params  => \%body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => $page->{meta}{source_kind} || 'saved',
            runtime_context => { params => { %params, %body_params } },
        );
        return [ 200, 'text/html; charset=utf-8', $self->_render_page_html( $page, 'render' ) ];
    }

    return [ 404, 'text/plain; charset=utf-8', "Not found\n" ];
}

# _handle_login(%args)
# Processes helper login form submissions and issues a session cookie.
# Input: request body and remote address.
# Output: response array reference.
sub _handle_login {
    my ( $self, %args ) = @_;
    my %form = _parse_query( $args{body} );
    my $user = $self->{auth}->verify_user(
        username => $form{username},
        password => $form{password},
    );

    if ( !$user ) {
        return [
            401,
            'text/html; charset=utf-8',
            $self->{auth}->login_page( message => 'Invalid username or password.' ),
        ];
    }

    my $session = $self->{sessions}->create(
        username    => $user->{username},
        role        => $user->{role},
        remote_addr => $args{remote_addr},
    );

    return [
        302,
        'text/plain; charset=utf-8',
        "Redirecting\n",
        {
            'Location'   => '/',
            'Set-Cookie' => _session_cookie( $session->{session_id} ),
        },
    ];
}

# _blank_editor_response()
# Builds the default free-form bookmark editor response.
# Input: none.
# Output: response array reference.
sub _blank_editor_response {
    my ($self) = @_;
    my $page = Developer::Dashboard::PageDocument->new(
        title       => 'Developer Dashboard',
        description => '',
        meta        => { source_kind => 'transient', source_format => 'legacy' },
    );
    return [ 200, 'text/html; charset=utf-8', $self->_edit_html($page) ];
}

# _page_response($page, $mode)
# Builds a page response for edit, render, or source mode.
# Input: page document object and mode string.
# Output: response array reference.
sub _page_response {
    my ( $self, $page, $mode ) = @_;
    my $source = $page->{meta}{raw_instruction} || $page->canonical_instruction;

    if ( $mode eq 'source' ) {
        return [ 200, 'text/plain; charset=utf-8', $source ];
    }
    if ( $mode eq 'render' ) {
        return [ 200, 'text/html; charset=utf-8', $self->_render_page_html( $page, 'render' ) ];
    }

    return [ 200, 'text/html; charset=utf-8', $self->_edit_html($page) ];
}

# _edit_html($page)
# Renders the browser edit/source view for a page.
# Input: page document object.
# Output: HTML string.
sub _edit_html {
    my ( $self, $page ) = @_;
    my $raw_source = $page->{meta}{raw_instruction} || $page->canonical_instruction;
    my $source = $raw_source;
    $source =~ s/&/&amp;/g;
    $source =~ s/</&lt;/g;
    $source =~ s/>/&gt;/g;

    my $urls = {
        edit   => $self->{pages}->editable_url($page),
        render => $self->{pages}->render_url($page),
        source => $self->{pages}->editable_url($page),
    };

    my $title = $page->as_hash->{title};
    $title =~ s/&/&amp;/g;
    $title =~ s/</&lt;/g;
    $title =~ s/>/&gt;/g;

    my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>__TITLE__</title>
  <style>
    body { margin: 0; font-family: Georgia, serif; background: #f5efe2; color: #1f2a2e; }
    main { max-width: 980px; margin: 32px auto; background: #fffef9; border: 1px solid #ddd3c2; padding: 24px; }
    .editor-stack {
      position: relative;
      min-height: 520px;
      border: 1px solid #2a2f36;
      background: #1f2328;
    }
    .editor-overlay,
    .instruction-editor {
      width: 100%;
      min-height: 520px;
      box-sizing: border-box;
      margin: 0;
      padding: 12px;
      font-family: "Courier New", monospace;
      font-size: 14px;
      line-height: 1.5;
      white-space: pre-wrap;
      overflow: auto;
      tab-size: 4;
    }
    .editor-overlay {
      position: absolute;
      inset: 0;
      pointer-events: none;
      color: #e6edf3;
      background: transparent;
      unicode-bidi: plaintext;
      direction: ltr;
    }
    .instruction-editor {
      position: relative;
      z-index: 1;
      color: transparent;
      border: 0;
      resize: vertical;
      background: transparent;
      caret-color: #f8f8f2;
      outline: none;
      -webkit-text-fill-color: transparent;
      unicode-bidi: plaintext;
      direction: ltr;
    }
    .instruction-editor::selection {
      background: rgba(121, 192, 255, 0.35);
      -webkit-text-fill-color: transparent;
    }
    .tok-directive { color: #ffd866; font-weight: bold; }
    .tok-separator { color: #5c6370; }
    .tok-html { color: #78dce8; }
    .tok-tag { color: #ff7ab2; }
    .tok-attr { color: #ffcf6a; }
    .tok-value { color: #a9dc76; }
    .tok-css { color: #78dce8; }
    .tok-js { color: #ab9df2; }
    .tok-code { color: #a9dc76; }
    .tok-perl-keyword { color: #ff7ab2; }
    .tok-perl-var { color: #78dce8; }
    .tok-string { color: #ffd866; }
    .tok-comment { color: #727b84; }
    .tok-note { color: #ff6188; }
    a { color: #0b7a75; margin-right: 18px; text-decoration: none; }
  </style>
</head>
<body>
<main>
  __TOP_CHROME__
  <form method="post" action="/" id="instruction-form">
    <div class="editor-stack">
      <pre class="editor-overlay" id="instruction-highlight" aria-hidden="true">__INITIAL_HIGHLIGHT__</pre>
      <textarea class="instruction-editor" id="instruction-editor" name="instruction" spellcheck="false" autocapitalize="off" autocomplete="off" autocorrect="off">__SOURCE__</textarea>
    </div>
  </form>
</main>
<script>
const ddForm = document.getElementById('instruction-form');
const ddEditor = document.getElementById('instruction-editor');
const ddHighlight = document.getElementById('instruction-highlight');
function ddEscapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}
function ddHighlightInstruction(text) {
  const state = { section: '', htmlMode: '' };
  return String(text).split('\n').map((line) => ddHighlightLine(line, state)).join('\n');
}
function ddHighlightLine(line, state) {
  if (line === ':--------------------------------------------------------------------------------:') {
    return '<span class="tok-separator">' + ddEscapeHtml(line) + '</span>';
  }
  const match = line.match(/^([A-Za-z][A-Za-z0-9.]*:)(\s*)(.*)$/);
  if (match) {
    state.section = match[1].slice(0, -1).toUpperCase();
    state.htmlMode = '';
    return '<span class="tok-directive">' + ddEscapeHtml(match[1]) + '</span>' +
      ddEscapeHtml(match[2]) +
      ddHighlightSectionText(match[3], state);
  }
  return ddHighlightSectionText(line, state);
}
function ddHighlightSectionText(text, state) {
  const section = state.section || '';
  if (/^CODE\d+$/.test(section)) return ddHighlightPerlLine(text);
  if (section === 'HTML' || section === 'FORM' || section === 'FORM.TT') return ddHighlightHtmlLine(text, state);
  if (section === 'STASH' || section === 'NOTE') return ddHighlightNoteLine(text);
  return ddEscapeHtml(text);
}
function ddHighlightNoteLine(text) {
  return ddEscapeHtml(text).replace(/(\[%[\s\S]*?%\])/g, '<span class="tok-note">$1</span>');
}
function ddHighlightHtmlLine(text, state) {
  let line = text;
  let output = '';
  while (line.length) {
    if (state.htmlMode === 'script') {
      const closeAt = line.search(/<\/script\s*>/i);
      if (closeAt >= 0) {
        output += ddHighlightJsText(line.slice(0, closeAt));
        const closeText = line.slice(closeAt).match(/^<\/script\s*>/i)[0];
        output += ddHighlightMarkupText(closeText);
        line = line.slice(closeAt + closeText.length);
        state.htmlMode = '';
        continue;
      }
      output += ddHighlightJsText(line);
      line = '';
      continue;
    }
    if (state.htmlMode === 'style') {
      const closeAt = line.search(/<\/style\s*>/i);
      if (closeAt >= 0) {
        output += ddHighlightCssText(line.slice(0, closeAt));
        const closeText = line.slice(closeAt).match(/^<\/style\s*>/i)[0];
        output += ddHighlightMarkupText(closeText);
        line = line.slice(closeAt + closeText.length);
        state.htmlMode = '';
        continue;
      }
      output += ddHighlightCssText(line);
      line = '';
      continue;
    }
    const openAt = line.search(/<(script|style)\b/i);
    if (openAt >= 0) {
      output += ddHighlightMarkupText(line.slice(0, openAt));
      const rest = line.slice(openAt);
      const tagMatch = rest.match(/^<(script|style)\b[\s\S]*?>/i);
      if (!tagMatch) {
        output += ddHighlightMarkupText(rest);
        line = '';
        continue;
      }
      const tagText = tagMatch[0];
      output += ddHighlightMarkupText(tagText);
      line = rest.slice(tagText.length);
      state.htmlMode = tagMatch[1].toLowerCase() === 'script' ? 'script' : 'style';
      continue;
    }
    output += ddHighlightMarkupText(line);
    line = '';
  }
  return output;
}
function ddHighlightMarkupText(text) {
  let html = ddEscapeHtml(text);
  html = html.replace(/(&lt;!--[\s\S]*?--&gt;)/g, '<span class="tok-comment">$1</span>');
  html = html.replace(/(\[%[\s\S]*?%\])/g, '<span class="tok-note">$1</span>');
  html = html.replace(/(&lt;\/?)([A-Za-z0-9:-]+)([^&]*?)(\/?&gt;)/g, function(_, open, tag, attrs, close) {
    let rendered = '<span class="tok-tag">' + open + tag + '</span>';
    rendered += attrs.replace(/([A-Za-z_:][-A-Za-z0-9_:.]*)(\s*=\s*)(&quot;.*?&quot;|'.*?'|[^\s>]+)/g, function(__, name, eq, value) {
      let valueClass = 'tok-value';
      if (name === 'style') valueClass += ' tok-css';
      if (name.startsWith('on')) valueClass += ' tok-js';
      return '<span class="tok-attr">' + name + '</span>' + eq + '<span class="' + valueClass + '">' + value + '</span>';
    });
    rendered += '<span class="tok-tag">' + close + '</span>';
    return rendered;
  });
  return html;
}
function ddHighlightCssText(text) {
  let css = ddEscapeHtml(text);
  css = css.replace(/\/\*[\s\S]*?\*\//g, '<span class="tok-comment">$&</span>');
  css = css.replace(/([.#]?[A-Za-z_-][A-Za-z0-9_-]*)(\s*\{)/g, '<span class="tok-css">$1</span>$2');
  css = css.replace(/([A-Za-z-]+)(\s*:)/g, '<span class="tok-attr">$1</span>$2');
  css = css.replace(/(:\s*)([^;}{]+)/g, '$1<span class="tok-value tok-css">$2</span>');
  return css;
}
function ddHighlightJsText(text) {
  let js = ddEscapeHtml(text);
  js = js.replace(/\/\/[^\n]*/g, '<span class="tok-comment">$&</span>');
  js = js.replace(/('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)/g, '<span class="tok-string">$1</span>');
  js = js.replace(/\b(const|let|var|function|return|if|else|for|while|class|new|await|async|try|catch|throw)\b/g, '<span class="tok-js">$1</span>');
  return js;
}
function ddHighlightPerlLine(text) {
  let perl = ddEscapeHtml(text);
  perl = perl.replace(/(\[%[\s\S]*?%\])/g, '<span class="tok-note">$1</span>');
  perl = perl.replace(/(^|\s)(#.*)$/g, '$1<span class="tok-comment">$2</span>');
  perl = perl.replace(/('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)/g, '<span class="tok-string">$1</span>');
  perl = perl.replace(/\b(my|sub|return|if|elsif|else|for|foreach|while|last|next|die|print|use|local|our|state|undef)\b/g, '<span class="tok-perl-keyword">$1</span>');
  perl = perl.replace(/([$@%][A-Za-z_][A-Za-z0-9_]*)/g, '<span class="tok-perl-var">$1</span>');
  return perl;
}
function ddRenderEditor(text) {
  ddHighlight.innerHTML = ddHighlightInstruction(text);
}
ddEditor.addEventListener('input', function() {
  ddRenderEditor(ddEditor.value);
});
ddEditor.addEventListener('scroll', function() {
  ddHighlight.scrollTop = ddEditor.scrollTop;
  ddHighlight.scrollLeft = ddEditor.scrollLeft;
});
ddEditor.addEventListener('change', function() {
  ddForm.submit();
});
ddEditor.value = __SOURCE_JSON__;
ddRenderEditor(ddEditor.value);
</script>
</body>
</html>
HTML

    $html =~ s/__TITLE__/$title/g;
    $html =~ s/__TOP_CHROME__/$self->_top_chrome_html( $page, \%$urls )/ge;
    $html =~ s/__INITIAL_HIGHLIGHT__/$self->_highlight_instruction_html($raw_source)/ge;
    $html =~ s/__SOURCE__/$source/g;
    $html =~ s/__SOURCE_JSON__/json_encode($raw_source)/ge;
    return $html;
}

# _highlight_instruction_html($source)
# Generates the initial syntax-coloured editor HTML from bookmark source text.
# Input: canonical bookmark instruction text.
# Output: highlighted HTML string for the editable source area.
sub _highlight_instruction_html {
    my ( $self, $source ) = @_;
    my %state = ( section => '', html_mode => '' );
    return join "\n", map { $self->_highlight_editor_line( $_, \%state ) } split /\n/, ( $source // '' ), -1;
}

# _highlight_editor_line($line, $state)
# Highlights a single bookmark editor line while preserving exact layout.
# Input: raw line text and mutable parser state hash reference.
# Output: highlighted HTML fragment for that line.
sub _highlight_editor_line {
    my ( $self, $line, $state ) = @_;
    if ( $line eq ':--------------------------------------------------------------------------------:' ) {
        return qq{<span class="tok-separator">} . _escape_html($line) . qq{</span>};
    }
    if ( $line =~ /^([A-Za-z][A-Za-z0-9.]*:)(\s*)(.*)\z/ ) {
        my ( $directive, $space, $rest ) = ( $1, $2, $3 );
        $state->{section}   = uc substr( $directive, 0, -1 );
        $state->{html_mode} = '';
        return qq{<span class="tok-directive">} . _escape_html($directive) . qq{</span>}
          . _escape_html($space)
          . $self->_highlight_section_text( $rest, $state );
    }
    return $self->_highlight_section_text( $line, $state );
}

# _highlight_section_text($text, $state)
# Dispatches line highlighting based on the active bookmark section.
# Input: raw line text and mutable parser state hash reference.
# Output: highlighted HTML fragment.
sub _highlight_section_text {
    my ( $self, $text, $state ) = @_;
    my $section = $state->{section} || '';
    return $self->_highlight_perl_text($text) if $section =~ /^CODE\d+$/;
    return $self->_highlight_html_text( $text, $state ) if $section eq 'HTML' || $section eq 'FORM' || $section eq 'FORM.TT';
    return $self->_highlight_note_text($text) if $section eq 'STASH' || $section eq 'NOTE';
    return _escape_html($text);
}

# _highlight_note_text($text)
# Highlights TT-style placeholders inside simple text sections.
# Input: raw section line text.
# Output: highlighted HTML fragment.
sub _highlight_note_text {
    my ( $self, $text ) = @_;
    my $html = _escape_html($text);
    $html =~ s{(\[%[\s\S]*?%\])}{<span class="tok-note">$1</span>}g;
    return $html;
}

# _highlight_html_text($text, $state)
# Highlights HTML section text with HTML, CSS, and JavaScript awareness.
# Input: raw section line text and mutable parser state hash reference.
# Output: highlighted HTML fragment.
sub _highlight_html_text {
    my ( $self, $text, $state ) = @_;
    my $line = $text;
    my $out  = '';
    while ( length $line ) {
        if ( ( $state->{html_mode} || '' ) eq 'script' ) {
            if ( $line =~ m{</script\s*>}i ) {
                my ( $before, $close, $after ) = $line =~ m{\A(.*?)(</script\s*>)(.*)\z}is;
                $out .= $self->_highlight_js_text($before);
                $out .= $self->_highlight_markup_text($close);
                $line = $after;
                $state->{html_mode} = '';
                next;
            }
            $out .= $self->_highlight_js_text($line);
            last;
        }
        if ( ( $state->{html_mode} || '' ) eq 'style' ) {
            if ( $line =~ m{</style\s*>}i ) {
                my ( $before, $close, $after ) = $line =~ m{\A(.*?)(</style\s*>)(.*)\z}is;
                $out .= $self->_highlight_css_text($before);
                $out .= $self->_highlight_markup_text($close);
                $line = $after;
                $state->{html_mode} = '';
                next;
            }
            $out .= $self->_highlight_css_text($line);
            last;
        }
        if ( $line =~ m{<(script|style)\b}i ) {
            my ( $before, $tag, $after ) = $line =~ m{\A(.*?)(<(?:script|style)\b[\s\S]*?>)(.*)\z}is;
            if ( defined $tag ) {
                $out .= $self->_highlight_markup_text($before);
                $out .= $self->_highlight_markup_text($tag);
                $line = $after;
                $state->{html_mode} = lc($1) eq 'script' ? 'script' : 'style';
                next;
            }
        }
        $out .= $self->_highlight_markup_text($line);
        last;
    }
    return $out;
}

# _highlight_markup_text($text)
# Highlights markup fragments, tag names, attributes, and inline TT tokens.
# Input: raw HTML-ish text fragment.
# Output: highlighted HTML fragment.
sub _highlight_markup_text {
    my ( $self, $text ) = @_;
    my $html = _escape_html($text);
    $html =~ s{(&lt;!--[\s\S]*?--&gt;)}{<span class="tok-comment">$1</span>}g;
    $html =~ s{(\[%[\s\S]*?%\])}{<span class="tok-note">$1</span>}g;
    $html =~ s{(&lt;/?)([A-Za-z0-9:-]+)([^&]*?)(/?&gt;)}
              {$self->_highlight_tag_markup( $1, $2, $3, $4 )}ge;
    return $html;
}

# _highlight_tag_markup($open, $tag, $attrs, $close)
# Highlights a single escaped markup tag without changing surrounding layout.
# Input: escaped opening token, tag name, attribute text, and closing token.
# Output: highlighted HTML fragment.
sub _highlight_tag_markup {
    my ( $self, $open, $tag, $attrs, $close ) = @_;
    $attrs =~ s{([A-Za-z_:][-A-Za-z0-9_:.]*)(\s*=\s*)(&quot;.*?&quot;|'.*?'|[^\s>]+)}
             {my ( $name, $eq, $value ) = ( $1, $2, $3 );
              my $value_class = $name eq 'style' ? 'tok-value tok-css' : $name =~ /^on/ ? 'tok-value tok-js' : 'tok-value';
              qq{<span class="tok-attr">$name</span>$eq<span class="$value_class">$value</span>}}ge;
    return qq{<span class="tok-tag">$open$tag</span>$attrs<span class="tok-tag">$close</span>};
}

# _highlight_css_text($text)
# Highlights CSS-like text inside HTML style blocks or style attributes.
# Input: raw CSS text fragment.
# Output: highlighted HTML fragment.
sub _highlight_css_text {
    my ( $self, $text ) = @_;
    my $css = _escape_html($text);
    $css =~ s{(/\*[\s\S]*?\*/)}{<span class="tok-comment">$1</span>}g;
    $css =~ s!([.\#]?[A-Za-z_-][A-Za-z0-9_-]*)(\s*\{)!<span class="tok-css">$1</span>$2!g;
    $css =~ s!([A-Za-z-]+)(\s*:)!<span class="tok-attr">$1</span>$2!g;
    $css =~ s!(:\s*)([^;\}\{]+)!$1 . qq{<span class="tok-value tok-css">$2</span>}!ge;
    return $css;
}

# _highlight_js_text($text)
# Highlights JavaScript-like text inside HTML script blocks.
# Input: raw JavaScript text fragment.
# Output: highlighted HTML fragment.
sub _highlight_js_text {
    my ( $self, $text ) = @_;
    my $js = _escape_html($text);
    $js =~ s{(//[^\n]*)}{<span class="tok-comment">$1</span>}g;
    $js =~ s{('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)}{<span class="tok-string">$1</span>}g;
    $js =~ s{\b(const|let|var|function|return|if|else|for|while|class|new|await|async|try|catch|throw)\b}{<span class="tok-js">$1</span>}g;
    return $js;
}

# _highlight_perl_text($text)
# Highlights Perl-like text inside CODE sections.
# Input: raw Perl text fragment.
# Output: highlighted HTML fragment.
sub _highlight_perl_text {
    my ( $self, $text ) = @_;
    my $perl = _escape_html($text);
    $perl =~ s{(\[%[\s\S]*?%\])}{<span class="tok-note">$1</span>}g;
    if ( $perl =~ /\A(.*?)(\s\#.*|\#.*)\z/ ) {
        $perl = $1 . qq{<span class="tok-comment">$2</span>};
    }
    $perl =~ s{('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)}{<span class="tok-string">$1</span>}g;
    $perl =~ s{\b(my|sub|return|if|elsif|else|for|foreach|while|last|next|die|print|use|local|our|state|undef)\b}{<span class="tok-perl-keyword">$1</span>}g;
    $perl =~ s{([$@%][A-Za-z_][A-Za-z0-9_]*)}{<span class="tok-perl-var">$1</span>}g;
    return $perl;
}

# _escape_html($text)
# Escapes plain text for safe HTML output in the bookmark editor.
# Input: raw text.
# Output: escaped HTML-safe text.
sub _escape_html {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return $text;
}

# _render_page_html($page, $mode)
# Renders the browser page view and action URLs for a page.
# Input: page document object and mode string.
# Output: HTML string.
sub _render_page_html {
    my ( $self, $page, $mode ) = @_;
    $page->with_mode( $mode || 'render' );
    my %action_urls;
    for my $action ( @{ $page->as_hash->{actions} || [] } ) {
        next if ref($action) ne 'HASH' || !$action->{id};
        my $atoken = $self->{actions}
          ? $self->{actions}->encode_action_payload(
              action => $action,
              page   => $page,
              source => $page->{meta}{source_kind} || 'saved',
            )
          : undef;
        $action_urls{ $action->{id} } = $atoken
          ? '/action?atoken=' . URI::Escape::uri_escape($atoken)
          : '/page/' . ( $page->as_hash->{id} || '' ) . '/action/' . $action->{id};
    }
    my $page_url = ( $page->{meta}{source_kind} || '' ) eq 'transient'
      ? $self->{pages}->editable_url($page)
      : '/page/' . ( $page->as_hash->{id} || '' );
    return $page->render_html(
        action_urls => \%action_urls,
        page_url    => $page_url,
        chrome_html => $self->_top_chrome_html(
            $page,
            {
                edit   => ( $page->{meta}{source_kind} || '' ) eq 'transient' ? '/?token=' . $self->{pages}->encode_page($page) : $page_url . '/edit',
                render => ( $page->{meta}{source_kind} || '' ) eq 'transient' ? '/?mode=render&token=' . $self->{pages}->encode_page($page) : $page_url,
                source => ( $page->{meta}{source_kind} || '' ) eq 'transient' ? '/?token=' . $self->{pages}->encode_page($page) : $page_url . '/edit',
            },
        ),
    );
}

# _action_response(%args)
# Executes a named page action and converts the result into an HTTP response.
# Input: page object, action id, source classification, and params.
# Output: response array reference.
sub _action_response {
    my ( $self, %args ) = @_;
    return [ 501, 'text/plain; charset=utf-8', "Action runner is not configured\n" ] if !$self->{actions};
    my $page = $args{page};
    my $id   = $args{id} || '';
    my ($action) = grep { ref($_) eq 'HASH' && ( $_->{id} || '' ) eq $id } @{ $page->as_hash->{actions} || [] };
    return [ 404, 'text/plain; charset=utf-8', "Action not found\n" ] if !$action;

    my $result = eval {
        $self->{actions}->run_page_action(
            action => $action,
            page   => $page,
            params => $args{params} || {},
            source => $args{source} || 'saved',
        );
    };
    if ($@) {
        return [ 403, 'text/plain; charset=utf-8', "$@" ];
    }
    if ( ref($result) eq 'HASH' && exists $result->{body} ) {
        return [ 200, $result->{content_type} || 'text/plain; charset=utf-8', $result->{body} ];
    }
    return [ 200, 'application/json; charset=utf-8', json_encode($result) ];
}

# _encoded_action_response(%args)
# Executes an encoded action payload and converts it into an HTTP response.
# Input: encoded action token and params hash reference.
# Output: response array reference.
sub _encoded_action_response {
    my ( $self, %args ) = @_;
    return [ 501, 'text/plain; charset=utf-8', "Action runner is not configured\n" ] if !$self->{actions};
    my $result = eval {
        $self->{actions}->run_encoded_action(
            token  => $args{token},
            params => $args{params} || {},
        );
    };
    if ($@) {
        return [ 403, 'text/plain; charset=utf-8', "$@" ];
    }
    if ( ref($result) eq 'HASH' && exists $result->{body} ) {
        return [ 200, $result->{content_type} || 'text/plain; charset=utf-8', $result->{body} ];
    }
    return [ 200, 'application/json; charset=utf-8', json_encode($result) ];
}

# _load_named_page($id)
# Loads a page using the resolver when present or the page store otherwise.
# Input: page id string.
# Output: page document object.
sub _load_named_page {
    my ( $self, $id ) = @_;
    return $self->{resolver}->load_named_page($id) if $self->{resolver};
    return $self->{pages}->load_saved_page($id);
}

# _legacy_app_response(%args)
# Loads a legacy /app/<name> resource as either a bookmark page or saved URL forward.
# Input: bookmark id and request metadata.
# Output: response array reference.
sub _legacy_app_response {
    my ( $self, %args ) = @_;
    my $id = $args{id} || die 'Missing app id';
    my $raw = $self->{pages}->read_saved_entry($id);
    my $parsed = eval { $self->{pages}->load_saved_page($id) };
    if ($parsed) {
        $parsed = $self->_page_with_runtime_state(
            $parsed,
            query_params => $args{query_params} || {},
            body_params  => $args{body_params}  || {},
            path         => '/app/' . $id,
            remote_addr  => $args{remote_addr},
            headers      => $args{headers},
        );
        $parsed = $self->{runtime}->prepare_page(
            page            => $parsed,
            source          => 'saved',
            runtime_context => { params => {} },
        );
        return [ 200, 'text/html; charset=utf-8', $self->_render_page_html( $parsed, 'render' ) ];
    }

    my $target = _trim($raw);
    my $uri = URI->new($target);
    my $path = $uri->path;
    my %bookmark_params = _parse_query( scalar( $uri->query // '' ) );
    my %forward_params = (
        %bookmark_params,
        %{ $args{query_params} || {} },
        %{ $args{body_params}  || {} },
    );
    my $query = _build_query( \%forward_params );
    return $self->handle(
        path        => $path,
        query       => $query,
        method      => 'GET',
        body        => '',
        remote_addr => $args{remote_addr},
        headers     => $args{headers} || {},
    );
}

# _build_query($params)
# Builds a URL query string from a flat hash reference.
# Input: flat hash reference of request parameters.
# Output: URL-encoded query string.
sub _build_query {
    my ($params) = @_;
    return '' if ref($params) ne 'HASH' || !%{$params};
    return join '&',
      map {
          URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape( defined $params->{$_} ? $params->{$_} : '' )
      } sort keys %{$params};
}

# _legacy_ajax_response(%args)
# Decodes and executes a legacy /ajax token payload.
# Input: request params and metadata.
# Output: response array reference.
sub _legacy_ajax_response {
    my ( $self, %args ) = @_;
    my $params = $args{params} || {};
    my $token = $params->{token} || return [ 400, 'text/plain; charset=utf-8', "missing token\n" ];
    my $type  = $params->{type} || 'html';
    my %types = (
        html => 'text/html; charset=utf-8',
        text => 'text/plain; charset=utf-8',
        json => 'application/json; charset=utf-8',
        js   => 'application/javascript; charset=utf-8',
        xml  => 'application/xml; charset=utf-8',
        yml  => 'text/plain; charset=utf-8',
        yaml => 'text/plain; charset=utf-8',
        xslt => 'application/xml; charset=utf-8',
    );
    my $code = eval { decode_payload($token) };
    return [ 400, 'text/plain; charset=utf-8', "$@" ] if $@;
    my $page = Developer::Dashboard::PageDocument->new(
        title => 'Legacy Ajax',
        meta  => {
            source_format => 'legacy',
            codes => [ { id => 'CODE0', body => $code } ],
        },
    );
    $page = $self->{runtime}->prepare_page(
        page            => $page,
        source          => 'saved',
        runtime_context => { params => $params },
    );
    my $body = join '', @{ $page->{meta}{runtime_outputs} || [] };
    my $errors = join '', @{ $page->{meta}{runtime_errors} || [] };
    $body .= $errors if $errors ne '';
    return [ 200, $types{$type} || 'text/plain; charset=utf-8', $body ];
}

# _parse_query($query)
# Parses a URL-encoded query/body string into a flat parameter hash.
# Input: query string.
# Output: key/value hash.
sub _parse_query {
    my ($query) = @_;
    return () if !defined $query || $query eq '';
    my %params;
    for my $pair ( split /&/, $query ) {
        my ( $k, $v ) = split /=/, $pair, 2;
        next if !defined $k || $k eq '';
        $k =~ tr/+/ /;
        my $name = uri_unescape($k);
        if ( defined $v && $name ne 'token' && $name ne 'atoken' ) {
            $v =~ tr/+/ /;
        }
        $params{$name} = defined $v ? uri_unescape($v) : '';
    }
    return %params;
}

# _page_with_runtime_state($page, %args)
# Merges request-time state into a page document before rendering or actions.
# Input: page document object plus query/body/context metadata.
# Output: updated page document object.
sub _page_with_runtime_state {
    my ( $self, $page, %args ) = @_;
    my %params = (
        %{ $args{query_params} || {} },
        %{ $args{body_params}  || {} },
    );
    my $request_ctx = $self->{_current_request_context} || {};
    delete @params{ grep { exists $params{$_} } qw(token atoken id mode instruction) };
    $page->merge_state(\%params) if %params;
    $page->{meta}{request_context} = {
        host        => $args{headers}{host} || $request_ctx->{host} || '',
        path        => $args{path} || '',
        remote_addr => $args{remote_addr} || $request_ctx->{remote_addr} || '',
        tier        => $request_ctx->{tier} || 'helper',
        username    => $request_ctx->{username} || '',
        role        => $request_ctx->{role} || '',
    };
    return $page;
}

# _trim($text)
# Trims leading and trailing whitespace from text.
# Input: text string.
# Output: trimmed string.
sub _trim {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

# _top_chrome_html($page, $urls)
# Builds the shared top-of-page chrome for edit and render views.
# Input: page document object and hash reference of edit/render/source URLs.
# Output: HTML snippet string.
sub _top_chrome_html {
    my ( $self, $page, $urls ) = @_;
    $urls ||= {};
    my $share = $urls->{edit}   || '';
    my $play  = $urls->{render} || '';
    my $src   = $urls->{source} || '';
    my $mode  = $page->as_hash->{mode} || 'edit';
    my $ctx   = $page->{meta}{request_context} || {};
    my @links;
    push @links, qq{<a href="$play" id="play-url">Play</a>} if $mode ne 'render' && $play ne '';
    push @links, qq{<a href="$src" id="view-source-url">View Source</a>} if $mode ne 'edit' && $src ne '';
    push @links, q{<a href="/logout" id="logout-url">Logout</a>}
      if ( $ctx->{tier} || '' ) eq 'helper';
    my $nav = join ' ', @links;
    my $status = $self->_prompt_summary;
    my $context = $self->_top_context_html($page);
    return sprintf <<'HTML', $share, $nav, $context, $status;
<div class="dd-top-chrome" style="display:flex;justify-content:space-between;gap:16px;align-items:flex-start;margin-bottom:16px;padding-bottom:12px;border-bottom:1px solid #ddd3c2">
  <div>
    <div><a href="%s" id="share-url">Right Click Copy &amp; Share or Bookmark This Page</a></div>
    <div style="margin-top:6px">%s</div>
  </div>
  <div style="text-align:right;white-space:pre-wrap">%s<span id="status-on-top">%s</span></div>
</div>
<script>
(function() {
  function renderTopStatus(items) {
    return (items || []).map(function(row) {
      return '<span id="status-' + row.prog + '">' + row.status + row.alias + '</span> ';
    }).join('');
  }
  function updateTopStatus(payload) {
    if (!payload || !payload.array) return;
    var top = document.getElementById('status-on-top');
    if (top) top.innerHTML = renderTopStatus(payload.array);
  }
  setInterval(function() {
    fetch('/system/status', { headers: { 'Accept': 'application/json' } })
      .then(function(res) { return res.json(); })
      .then(updateTopStatus)
      .catch(function() {});
  }, 5000);
  function pad(value) {
    return String(value).padStart(2, '0');
  }
  function updateDateTime() {
    var node = document.getElementById('status-datetime');
    if (!node) return;
    var now = new Date();
    node.textContent = now.getFullYear() + '-' +
      pad(now.getMonth() + 1) + '-' +
      pad(now.getDate()) + ' ' +
      pad(now.getHours()) + ':' +
      pad(now.getMinutes()) + ':' +
      pad(now.getSeconds());
  }
  updateDateTime();
  setInterval(updateDateTime, 1000);
})();
</script>
HTML
}

# _top_context_html($page)
# Builds the old-style top-right user, host, and date context line for browser chrome.
# Input: page document object.
# Output: HTML snippet string.
sub _top_context_html {
    my ( $self, $page ) = @_;
    my $ctx = $page->{meta}{request_context} || {};
    my $user = (
        ( $ctx->{tier} || '' ) eq 'helper' && ( $ctx->{username} || '' ) ne ''
    ) ? $ctx->{username} : ( $ENV{USER} || eval { getpwuid($<) } || 'user' );
    my $host = $ctx->{host} || '';
    $host =~ s/^https?:\/\///;
    $host =~ s/\/.*$//;
    my ( $host_only, $port ) = split /:/, $host, 2;
    my $machine_ip = $self->_machine_ip || $host_only || $ctx->{remote_addr} || '127.0.0.1';
    my $host_href = 'http://' . $machine_ip . ( defined $port && $port ne '' ? ':' . $port : '' );
    my $now = strftime '%Y-%m-%d %H:%M:%S', localtime;
    return sprintf q{<span class="user-name-and-icon">&#128129;&#127996; %s</span> <span id="status-server">&#128187; <a href="%s">%s</a></span> &#128467; <span id="status-datetime">%s</span><br>},
      _escape_html($user),
      _escape_html($host_href),
      _escape_html($machine_ip),
      _escape_html($now);
}

# _machine_ip()
# Discovers the preferred machine IPv4 address, preferring VPN-style interfaces before other global addresses.
# Input: none.
# Output: IPv4 address string or undef when unavailable.
sub _machine_ip {
    my ($self) = @_;
    my @candidates = $self->_ip_candidates;
    return $candidates[0] if @candidates;
    return;
}

# _ip_candidates()
# Collects candidate machine IPv4 addresses from system network interfaces.
# Input: none.
# Output: ordered list of IPv4 address strings.
sub _ip_candidates {
    my ($self) = @_;
    my @pairs = $self->_ip_interface_pairs;
    my @vpn;
    my @preferred;
    my @other;
    for my $pair (@pairs) {
        push @other, $pair->{ip};
        push @vpn, $pair->{ip} if $pair->{iface} =~ /^(?:tun|tap|ppp|utun|wg|vpn)/i;
        push @preferred, $pair->{ip} if $pair->{iface} =~ /^(?:eth|en|wlan|wl)/i;
    }
    my %seen;
    return grep { !$seen{$_}++ } ( @vpn, @preferred, @other );
}

# _ip_interface_pairs()
# Reads active global IPv4 interface/address pairs from the host system.
# Input: none.
# Output: list of hashes with iface and ip keys.
sub _ip_interface_pairs {
    my ($self) = @_;
    my @pairs = $self->_ip_pairs_from_ip;
    return @pairs if @pairs;
    return $self->_ip_pairs_from_ifconfig;
}

# _ip_pairs_from_ip()
# Reads IPv4 interface/address pairs using the `ip` command when available.
# Input: none.
# Output: list of hashes with iface and ip keys.
sub _ip_pairs_from_ip {
    my ($self) = @_;
    my ( $stdout, undef, $exit_code ) = capture {
        system 'sh', '-c', 'command -v ip >/dev/null 2>&1 && ip -o -4 addr show up scope global';
        return $? >> 8;
    };
    return () if $exit_code != 0 || !defined $stdout || $stdout eq '';
    my @pairs;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /^\d+:\s+([^ ]+)\s+inet\s+(\d+\.\d+\.\d+\.\d+)\//;
        push @pairs, { iface => $1, ip => $2 };
    }
    return @pairs;
}

# _ip_pairs_from_ifconfig()
# Reads IPv4 interface/address pairs using `ifconfig` as a fallback on systems without `ip`.
# Input: none.
# Output: list of hashes with iface and ip keys.
sub _ip_pairs_from_ifconfig {
    my ($self) = @_;
    my ( $stdout, undef, $exit_code ) = capture {
        system 'sh', '-c', 'command -v ifconfig >/dev/null 2>&1 && ifconfig';
        return $? >> 8;
    };
    return () if $exit_code != 0 || !defined $stdout || $stdout eq '';
    my @pairs;
    my $iface = '';
    for my $line ( split /\n/, $stdout ) {
        if ( $line =~ /^([A-Za-z0-9._:-]+):\s/ ) {
            $iface = $1;
            next;
        }
        next if $iface eq '';
        next if $line !~ /\binet\s+(?:addr:)?(\d+\.\d+\.\d+\.\d+)/;
        my $ip = $1;
        next if $ip =~ /^127\./;
        push @pairs, { iface => $iface, ip => $ip };
    }
    return @pairs;
}

# _prompt_summary()
# Renders the legacy-style page-header indicator summary for page chrome.
# Input: none.
# Output: short status strip string.
sub _prompt_summary {
    my ($self) = @_;
    my $payload = $self->_page_status_payload;
    my @items = @{ $payload->{array} || [] };
    my @parts;
    for my $item (@items) {
        push @parts, $item->{status} . $item->{alias};
    }
    return join ' ', @parts;
}

# _page_status_payload()
# Builds the legacy `/system/status` payload from the indicator store.
# Input: none.
# Output: hash reference with array, hash, and status maps.
sub _page_status_payload {
    my ($self) = @_;
    my $indicators = $self->{prompt} ? $self->{prompt}{indicators} : undef;
    return { array => [], hash => {}, status => {} } if !$indicators || !$indicators->can('page_header_payload');
    return $indicators->page_header_payload;
}

# _session_cookie($session_id)
# Builds the Set-Cookie header value for a dashboard session.
# Input: session id string.
# Output: cookie header string.
sub _session_cookie {
    my ($session_id) = @_;
    return "dashboard_session=$session_id; Path=/; HttpOnly; SameSite=Strict";
}

# _expired_session_cookie()
# Builds a Set-Cookie header that expires the dashboard session cookie.
# Input: none.
# Output: cookie header string.
sub _expired_session_cookie {
    return 'dashboard_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0';
}

1;

__END__

=head1 NAME

Developer::Dashboard::Web::App - local web application for Developer Dashboard

=head1 SYNOPSIS

  my $app = Developer::Dashboard::Web::App->new(
      auth     => $auth,
      pages    => $pages,
      sessions => $sessions,
  );

=head1 DESCRIPTION

This module handles the browser-facing dashboard routes, helper login flow,
page rendering modes, and page/action execution endpoints.

=head1 METHODS

=head2 new, handle

Construct and dispatch the local web application.

=cut
