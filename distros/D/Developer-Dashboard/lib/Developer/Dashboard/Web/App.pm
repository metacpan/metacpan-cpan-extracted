package Developer::Dashboard::Web::App;

use strict;
use warnings;

our $VERSION = '2.26';

use Capture::Tiny qw(capture);
use POSIX qw(strftime);
use File::Spec;
use Scalar::Util qw(blessed);
use URI;
use URI::Escape qw(uri_unescape);
use Cwd qw(cwd);

use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::Platform qw(command_in_path);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::Codec qw(decode_payload);
use Developer::Dashboard::Zipper ();

# new(%args)
# Constructs the browser-facing dashboard web application.
# Input: auth, pages, sessions, config, and optional actions/resolver objects.
# Output: Developer::Dashboard::Web::App object.
sub new {
    my ( $class, %args ) = @_;
    my $auth     = $args{auth}     || die 'Missing auth store';
    my $pages    = $args{pages}    || die 'Missing page store';
    my $sessions = $args{sessions} || die 'Missing session store';
    return bless {
        actions  => $args{actions},
        auth     => $auth,
        config   => $args{config},
        pages    => $pages,
        prompt   => $args{prompt},
        runtime  => $args{runtime} || Developer::Dashboard::PageRuntime->new,
        resolver => $args{resolver},
        sessions => $sessions,
    }, $class;
}

# _transient_url_tokens_allowed()
# Reports whether tokenized transient web execution is enabled by environment.
# Input: none.
# Output: boolean true when DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS enables transient web tokens.
sub _transient_url_tokens_allowed {
    return defined $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS}
      && $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} =~ /\A(?:1|true|yes|on)\z/i;
}

# _transient_url_forbidden_response()
# Builds the default-deny response for tokenized transient web execution.
# Input: none.
# Output: response array reference with a 403 plain-text error.
sub _transient_url_forbidden_response {
    return [
        403,
        'text/plain; charset=utf-8',
        "Transient token URLs are disabled. Save the page as a bookmark file or set DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS=1.\n",
    ];
}

# handle(%args)
# Dispatches one normalized request through the service-side route map.
# Input: path, query, method, headers, body, and remote address.
# Output: array reference of status code, content type, body, and optional headers hash.
sub handle {
    my ( $self, %args ) = @_;
    my $path   = $args{path} || '/';
    my $method = uc( $args{method} || 'GET' );

    if ( $path eq '/login' && $method eq 'POST' ) {
        return $self->login_response(%args);
    }
    if ( $path eq '/logout' ) {
        return $self->logout_response(%args);
    }

    my $auth_response = $self->authorize_request(%args);
    return $auth_response if $auth_response;

    return $self->dispatch_request(%args);
}

# authorize_request(%args)
# Authenticates one browser request and seeds the per-request context.
# Input: normalized request path, headers, and remote address.
# Output: undef when authorized, otherwise an HTTP response array reference.
sub authorize_request {
    my ( $self, %args ) = @_;
    my $headers = $args{headers} || {};
    my $config_has_web_settings = blessed( $self->{config} ) && $self->{config}->can('web_settings');
    my $tier = $self->{auth}->trust_tier(
        remote_addr          => $args{remote_addr},
        host                 => $headers->{host},
        extra_loopback_hosts => (
            $config_has_web_settings
            ? ( $self->{config}->web_settings->{ssl_subject_alt_names} || [] )
            : []
        ),
    );
    my $session;

    if ( $tier ne 'admin' ) {
        return $self->_helper_access_disabled_response
          if !$self->{auth}->helper_users_enabled;
        $session = $self->{sessions}->from_cookie( $headers->{cookie}, remote_addr => $args{remote_addr} );
        if ( !$session ) {
            return [
                401,
                'text/html; charset=utf-8',
                $self->{auth}->login_page(
                    redirect_to => $self->_login_redirect_target(%args),
                ),
            ];
        }
    }

    $self->{_current_request_context} = {
        tier        => $tier,
        remote_addr => $args{remote_addr} || '',
        host        => $headers->{host} || '',
        username    => ref($session) eq 'HASH' ? ( $session->{username} || '' ) : '',
        role        => ref($session) eq 'HASH' ? ( $session->{role} || '' ) : '',
    };
    return;
}

# dispatch_request(%args)
# Routes one authorized normalized request to the matching service method.
# Input: path, query, method, headers, body, and remote address.
# Output: array reference of status code, content type, body, and optional headers hash.
sub dispatch_request {
    my ( $self, %args ) = @_;
    my $path   = $args{path} || '/';
    my $method = uc( $args{method} || 'GET' );

    return $self->root_response(%args) if $path eq '/';
    return $self->apps_redirect_response(%args) if $path eq '/apps';
    return $self->legacy_ajax_response(%args) if $path eq '/ajax';
    return $self->ajax_singleton_stop_response(%args) if $path eq '/ajax/singleton/stop';
    if ( $path =~ m{^/ajax/(.+)$} ) {
        return $self->legacy_ajax_file_response( ajax_file => uri_unescape($1), %args );
    }
    return $self->status_response(%args) if $path eq '/system/status';
    return $self->jquery_js_response(%args) if $path eq '/js/jquery.js' || $path eq '/js/jquery-4.0.0.min.js';
    return $self->marked_js_response(%args) if $path eq '/marked.min.js';
    return $self->tiff_js_response(%args) if $path eq '/tiff.min.js';
    return $self->loading_image_response(%args) if $path eq '/loading.webp';
    if ( $path =~ m{^/(js|css|others)/(.+)$} ) {
        return $self->static_file_response( type => $1, file => uri_unescape($2), %args );
    }
    if ( $path =~ m{^/app/(.+)/source$} ) {
        return $self->page_source_response( id => $1, %args );
    }
    if ( $path =~ m{^/app/(.+)/edit$} && $method eq 'POST' ) {
        return $self->page_edit_post_response( id => $1, %args );
    }
    if ( $path =~ m{^/app/(.+)/edit$} ) {
        return $self->page_edit_response( id => $1, %args );
    }
    if ( $path =~ m{^/app/(.+)/action/([^/]+)$} && $method eq 'POST' ) {
        return $self->page_action_response( id => $1, action_id => $2, %args );
    }
    if ( $path =~ m{^/app/(.+)$} ) {
        return $self->legacy_app_response( id => $1, %args );
    }
    if ( $path =~ m{^/skill/([^/]+)/(.+)$} ) {
        return $self->skill_route_response( skill_name => $1, route => $2, %args );
    }
    return $self->transient_action_response(%args) if $path eq '/action' && $method eq 'POST';

    return [ 404, 'text/plain; charset=utf-8', "Not found\n" ];
}

# _helper_access_disabled_response()
# Builds the outsider-access denial used before any helper user exists.
# Input: none.
# Output: response array reference with a bare 401 plain-text error body.
sub _helper_access_disabled_response {
    return [
        401,
        'text/plain; charset=utf-8',
        '',
    ];
}

# _handle_login(%args)
# Processes helper login form submissions and issues a session cookie.
# Input: request body and remote address.
# Output: response array reference.
sub _handle_login {
    my ( $self, %args ) = @_;
    my %form = _parse_query( $args{body} );
    my $redirect_to = $self->_sanitize_redirect_target( $form{redirect_to} );
    return $self->_helper_access_disabled_response
      if !$self->{auth}->helper_users_enabled;
    my $user = $self->{auth}->verify_user(
        username => $form{username},
        password => $form{password},
    );

    if ( !$user ) {
        return [
            401,
            'text/html; charset=utf-8',
            $self->{auth}->login_page(
                message     => 'Invalid username or password.',
                redirect_to => $redirect_to,
            ),
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
            'Location'   => $redirect_to || '/',
            'Set-Cookie' => _session_cookie( $session->{session_id} ),
        },
    ];
}

# login_response(%args)
# Executes the helper login submission route.
# Input: normalized request body and remote address.
# Output: response array reference.
sub login_response {
    my ( $self, %args ) = @_;
    return $self->_handle_login(
        body        => defined $args{body} ? $args{body} : '',
        remote_addr => $args{remote_addr},
    );
}

# logout_response(%args)
# Executes the logout route and expires any active helper session.
# Input: normalized request headers and remote address.
# Output: response array reference.
sub logout_response {
    my ( $self, %args ) = @_;
    my $headers = $args{headers} || {};
    my $session = $self->{sessions}->from_cookie( $headers->{cookie}, remote_addr => $args{remote_addr} );
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

# root_response(%args)
# Executes the root route for saved index redirects, blank editor, transient, and saved-from-root pages.
# Input: normalized request path, query, body, headers, and remote address.
# Output: response array reference.
sub root_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my $path = $args{path} || '/';
    my $headers = $args{headers} || {};

    if ( exists $body_params->{instruction} || exists $params->{instruction} ) {
        my $instruction = exists $body_params->{instruction} ? $body_params->{instruction} : $params->{instruction};
        my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
        $page->{meta}{raw_instruction} = $instruction;
        my $page_id = $page->as_hash->{id} || '';
        if ( $page_id eq '' && !_transient_url_tokens_allowed() ) {
            return _transient_url_forbidden_response();
        }
        my $source_kind = 'transient';
        if ( exists $body_params->{instruction} && $page_id ne '' ) {
            $self->{pages}->save_page($page);
            $source_kind = 'saved';
        }
        $page->{meta}{source_kind} = $source_kind;
        my $mode = $params->{mode} || $body_params->{mode} || 'edit';
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => $params,
            body_params  => $body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => $source_kind,
            runtime_context => { params => { %{$params}, %{$body_params} } },
        );
        return $self->_page_response( $page, $mode );
    }

    if ( my $token = $params->{token} ) {
        return _transient_url_forbidden_response() if !_transient_url_tokens_allowed();
        my $page = $self->{pages}->load_transient_page($token);
        $page->{meta}{raw_instruction} = $page->canonical_instruction;
        my $mode = $params->{mode} || 'edit';
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => $params,
            body_params  => $body_params,
            path         => $path,
            remote_addr  => $args{remote_addr},
            headers      => $headers,
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => 'transient',
            runtime_context => { params => { %{$params}, %{$body_params} } },
        );
        return $self->_page_response( $page, $mode );
    }

    if ( $self->_saved_page_exists('index') ) {
        return [
            302,
            'text/plain; charset=utf-8',
            "Redirecting\n",
            { Location => '/app/index' },
        ];
    }

    return $self->_blank_editor_response;
}

# apps_redirect_response(%args)
# Executes the `/apps` compatibility redirect route.
# Input: normalized request arguments.
# Output: response array reference.
sub apps_redirect_response {
    my ( $self, %args ) = @_;
    return [
        302,
        'text/plain; charset=utf-8',
        "Redirecting\n",
        { Location => '/app/index' },
    ];
}

# legacy_ajax_response(%args)
# Executes the `/ajax` route using query and body parameters from one request.
# Input: normalized request query, body, headers, and remote address.
# Output: response array reference.
sub legacy_ajax_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my %request_params = ( %{$params}, %{$body_params} );
    return _transient_url_forbidden_response() if !$self->_legacy_ajax_allowed( \%request_params );
    return $self->_legacy_ajax_response(
        params       => \%request_params,
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
}

# legacy_ajax_file_response(%args)
# Executes one `/ajax/<file>` compatibility route against a saved ajax file.
# Input: ajax file name plus normalized request query, body, headers, and remote address.
# Output: response array reference.
sub legacy_ajax_file_response {
    my ( $self, %args ) = @_;
    my $ajax_file = $args{ajax_file} || '';
    my ( $params, $body_params ) = $self->_request_params(%args);
    my %request_params = ( %{$params}, %{$body_params}, file => $ajax_file );
    return _transient_url_forbidden_response() if !$self->_legacy_ajax_allowed( \%request_params );
    return $self->_legacy_ajax_response(
        params       => \%request_params,
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
}

# status_response(%args)
# Executes the `/system/status` route.
# Input: normalized request arguments.
# Output: response array reference.
sub status_response {
    my ( $self, %args ) = @_;
    my $payload = $self->_page_status_payload;
    return [ 200, 'application/json; charset=utf-8', json_encode($payload) ];
}

# marked_js_response(%args)
# Serves the built-in marked shim asset.
# Input: normalized request arguments.
# Output: response array reference.
sub jquery_js_response {
    my ( $self, %args ) = @_;
    return [ 200, 'application/javascript; charset=utf-8', <<'JS' ];
(function () {
  function asArray(list) {
    return Array.prototype.slice.call(list || []);
  }

  function onReady(fn) {
    if (typeof fn !== 'function') return;
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function () { fn(window.jQuery); }, { once: true });
      return;
    }
    fn(window.jQuery);
  }

  function wrap(nodes) {
    var api = {
      nodes: nodes || [],
      length: (nodes || []).length,
      ready: function (fn) {
        if (this.nodes[0] === document) onReady(fn);
        return this;
      },
      text: function (value) {
        if (arguments.length === 0) {
          return this.nodes[0] ? this.nodes[0].textContent : '';
        }
        this.nodes.forEach(function (node) {
          node.textContent = value == null ? '' : String(value);
        });
        return this;
      }
    };
    return api;
  }

  function $(arg) {
    if (typeof arg === 'function') {
      onReady(arg);
      return wrap([document]);
    }
    if (arg === document) {
      return wrap([document]);
    }
    if (typeof arg === 'string') {
      return wrap(asArray(document.querySelectorAll(arg)));
    }
    if (arg && arg.nodeType) {
      return wrap([arg]);
    }
    return wrap([]);
  }

  $.ajax = function (options) {
    var opts = options || {};
    var xhr = new XMLHttpRequest();
    var method = opts.method || opts.type || 'GET';
    var successArgs = null;
    var failureArgs = null;
    var alwaysArgs = null;
    var finished = false;

    function remember(callback, args, store) {
      if (typeof callback !== 'function') return xhr;
      if (args) {
        callback.apply(xhr, args);
        return xhr;
      }
      store.push(callback);
      return xhr;
    }

    function runCallbacks(callbacks, args) {
      callbacks.forEach(function (callback) {
        callback.apply(xhr, args);
      });
    }

    function finishSuccess(payload) {
      if (finished) return;
      finished = true;
      successArgs = [payload, 'success', xhr];
      alwaysArgs = [xhr, 'success'];
      if (typeof opts.success === 'function') {
        opts.success(payload, 'success', xhr);
      }
      if (typeof opts.complete === 'function') {
        opts.complete(xhr, 'success');
      }
      runCallbacks(xhr._done_callbacks, successArgs);
      runCallbacks(xhr._always_callbacks, alwaysArgs);
    }

    function finishFailure(status, error) {
      if (finished) return;
      finished = true;
      failureArgs = [xhr, status, error];
      alwaysArgs = [xhr, status];
      if (typeof opts.error === 'function') {
        opts.error(xhr, status, error);
      }
      if (typeof opts.complete === 'function') {
        opts.complete(xhr, status);
      }
      runCallbacks(xhr._fail_callbacks, failureArgs);
      runCallbacks(xhr._always_callbacks, alwaysArgs);
    }

    xhr._done_callbacks = [];
    xhr._fail_callbacks = [];
    xhr._always_callbacks = [];
    xhr.done = function (callback) {
      return remember(callback, successArgs, xhr._done_callbacks);
    };
    xhr.fail = function (callback) {
      return remember(callback, failureArgs, xhr._fail_callbacks);
    };
    xhr.always = function (callback) {
      return remember(callback, alwaysArgs, xhr._always_callbacks);
    };
    xhr.then = function (onDone, onFail) {
      xhr.done(onDone);
      xhr.fail(onFail);
      return xhr;
    };
    xhr.open(method, opts.url || '', true);

    if (opts.headers && typeof opts.headers === 'object') {
      Object.keys(opts.headers).forEach(function (key) {
        xhr.setRequestHeader(key, opts.headers[key]);
      });
    }

    xhr.onreadystatechange = function () {
      var payload;
      if (xhr.readyState !== 4) return;
      if (xhr.status >= 200 && xhr.status < 300) {
        payload = xhr.responseText;
        if (opts.dataType === 'json') {
          try {
            payload = payload === '' ? null : JSON.parse(payload);
          } catch (error) {
            finishFailure('parsererror', error);
            return;
          }
        }
        finishSuccess(payload);
        return;
      }
      finishFailure('error', xhr.statusText || 'error');
    };

    xhr.onerror = function () {
      finishFailure('error', xhr.statusText || 'error');
    };

    xhr.onabort = function () {
      finishFailure('abort', xhr.statusText || 'abort');
    };

    if (opts.data && typeof opts.data === 'object' && !(opts.data instanceof FormData)) {
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
      xhr.send(new URLSearchParams(opts.data).toString());
      return xhr;
    }

    xhr.send(opts.data == null ? null : opts.data);
    return xhr;
  };

  $.ready = onReady;
  $.fn = {};
  window.jQuery = $;
  window.$ = $;
})();
JS
}

# marked_js_response(%args)
# Serves the built-in marked shim asset.
# Input: normalized request arguments.
# Output: response array reference.
sub marked_js_response {
    my ( $self, %args ) = @_;
    return [ 200, 'application/javascript; charset=utf-8', "window.marked=window.marked||{parse:function(s){return s||'';}};\n" ];
}

# tiff_js_response(%args)
# Serves the built-in TIFF shim asset.
# Input: normalized request arguments.
# Output: response array reference.
sub tiff_js_response {
    my ( $self, %args ) = @_;
    return [ 200, 'application/javascript; charset=utf-8', "window.Tiff=window.Tiff||function(){};\n" ];
}

# loading_image_response(%args)
# Serves the built-in loading image response.
# Input: normalized request arguments.
# Output: response array reference.
sub loading_image_response {
    my ( $self, %args ) = @_;
    return [ 200, 'image/webp', '' ];
}

# static_file_response(%args)
# Serves one static asset from the dashboard public tree.
# Input: asset type and file name.
# Output: response array reference.
sub static_file_response {
    my ( $self, %args ) = @_;
    if ( ( $args{type} || '' ) eq 'js' ) {
        my $file = $args{file} || '';
        return $self->jquery_js_response(%args) if $file eq 'jquery.js' || $file eq 'jquery-4.0.0.min.js';
    }
    return $self->_serve_static_file( $args{type}, $args{file} );
}

# legacy_app_response(%args)
# Executes the saved `/app/<id>` render route and follows saved URL forwards.
# Input: saved app id plus normalized request query, body, headers, and remote address.
# Output: response array reference.
sub legacy_app_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    return $self->_legacy_app_response(
        id           => $args{id},
        query_params => $params,
        body_params  => $body_params,
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
}

# skill_route_response(%args)
# Executes routes provided by installed skills.
# Routes are namespaced under /skill/<repo-name>/<route>
# Input: skill_name, route, query params, headers, and remote address.
# Output: response array reference.
sub skill_route_response {
    my ( $self, %args ) = @_;
    my $skill_name = $args{skill_name} || '';
    my $route = $args{route} || '';
    
    return [ 400, 'text/plain; charset=utf-8', "Invalid skill name\n" ] if !$skill_name;
    return [ 400, 'text/plain; charset=utf-8', "Invalid skill route\n" ] if !$route;
    
    require Developer::Dashboard::SkillDispatcher;
    my $dispatcher = Developer::Dashboard::SkillDispatcher->new();
    return $dispatcher->route_response(
        app        => $self,
        skill_name => $skill_name,
        route      => $route,
    );
}

# transient_action_response(%args)
# Executes the transient `/action` route for encoded or token-backed actions.
# Input: normalized request path, query, body, headers, and remote address.
# Output: response array reference.
sub transient_action_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my $headers = $args{headers} || {};
    my $path = $args{path} || '/action';
    if ( my $atoken = $params->{atoken} ) {
        return _transient_url_forbidden_response() if !_transient_url_tokens_allowed();
        return $self->_encoded_action_response(
            token  => $atoken,
            params => { %{$params}, %{$body_params} },
        );
    }

    my $token = exists $params->{token} ? $params->{token} : ( $body_params->{token} || '' );
    return _transient_url_forbidden_response() if $token ne '' && !_transient_url_tokens_allowed();
    my $id   = exists $params->{id} ? $params->{id} : ( $body_params->{id} || '' );
    my $page = $self->{pages}->load_transient_page($token);
    $page = $self->_page_with_runtime_state(
        $page,
        query_params => $params,
        body_params  => $body_params,
        path         => $path,
        remote_addr  => $args{remote_addr},
        headers      => $headers,
    );
    return $self->_action_response(
        id     => $id,
        page   => $page,
        source => 'transient',
        params => { %{$params}, %{$body_params} },
    );
}

# page_source_response(%args)
# Executes the saved-page source route.
# Input: saved page id plus normalized request query, body, headers, and remote address.
# Output: response array reference.
sub page_source_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my $page = $self->_load_named_page( $args{id} );
    $page->{meta}{raw_instruction} = $page->{meta}{raw_instruction} || $page->canonical_instruction;
    $page = $self->_page_with_runtime_state(
        $page,
        query_params => $params,
        body_params  => $body_params,
        path         => $args{path} || '/app/' . $args{id} . '/source',
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
    $page = $self->{runtime}->prepare_page(
        page            => $page,
        source          => $page->{meta}{source_kind} || 'saved',
        runtime_context => { params => { %{$params}, %{$body_params} } },
    );
    return [ 200, 'text/plain; charset=utf-8', $page->{meta}{raw_instruction} || $page->canonical_instruction ];
}

# page_edit_post_response(%args)
# Executes the saved-page editor POST route.
# Input: saved page id plus normalized request path, query, body, headers, and remote address.
# Output: response array reference.
sub page_edit_post_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my $instruction = exists $body_params->{instruction} ? $body_params->{instruction} : $params->{instruction};
    if ( defined $instruction ) {
        my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
        $page->{meta}{raw_instruction} = $instruction;
        $page->{id} ||= $args{id};
        $page->{meta}{source_kind} = 'saved';
        $self->{pages}->save_page($page);
        my $mode = $params->{mode} || $body_params->{mode} || 'edit';
        $page = $self->_page_with_runtime_state(
            $page,
            query_params => $params,
            body_params  => $body_params,
            path         => $args{path} || '/app/' . $args{id} . '/edit',
            remote_addr  => $args{remote_addr},
            headers      => $args{headers} || {},
        );
        $page = $self->{runtime}->prepare_page(
            page            => $page,
            source          => 'saved',
            runtime_context => { params => { %{$params}, %{$body_params} } },
        );
        return $self->_page_response( $page, $mode );
    }
    return $self->page_edit_response(%args);
}

# page_edit_response(%args)
# Executes the saved-page editor GET route.
# Input: saved page id plus normalized request query, body, headers, and remote address.
# Output: response array reference.
sub page_edit_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my $page = $self->_load_named_page( $args{id} );
    $page->{meta}{raw_instruction} = $page->{meta}{raw_instruction} || $page->canonical_instruction;
    $page = $self->_page_with_runtime_state(
        $page,
        query_params => $params,
        body_params  => $body_params,
        path         => $args{path} || '/app/' . $args{id} . '/edit',
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
    $page = $self->{runtime}->prepare_page(
        page            => $page,
        source          => $page->{meta}{source_kind} || 'saved',
        runtime_context => { params => { %{$params}, %{$body_params} } },
    );
    return [ 200, 'text/html; charset=utf-8', $self->_edit_html($page) ];
}

# page_action_response(%args)
# Executes the saved-page named action route.
# Input: saved page id, action id, and normalized request query, body, headers, and remote address.
# Output: response array reference.
sub page_action_response {
    my ( $self, %args ) = @_;
    my ( $params, $body_params ) = $self->_request_params(%args);
    my $page = $self->_load_named_page( $args{id} );
    $page = $self->_page_with_runtime_state(
        $page,
        query_params => $params,
        body_params  => $body_params,
        path         => $args{path} || '/app/' . $args{id} . '/action/' . $args{action_id},
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
    $page = $self->{runtime}->prepare_page(
        page            => $page,
        source          => $page->{meta}{source_kind} || 'saved',
        runtime_context => { params => { %{$params}, %{$body_params} } },
    );
    return $self->_action_response(
        id     => $args{action_id},
        page   => $page,
        source => $page->{meta}{source_kind} || 'saved',
        params => { %{$params}, %{$body_params} },
    );
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

# _saved_page_exists($id)
# Checks whether one saved page id resolves in the effective bookmark lookup roots.
# Input: page id string.
# Output: boolean true when the saved page exists, otherwise false.
sub _saved_page_exists {
    my ( $self, $id ) = @_;
    return 0 if !defined $id || $id eq '';
    return eval { $self->{pages}->load_saved_page($id); 1 } ? 1 : 0;
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

    my $page_id = $page->as_hash->{id} || '';
    my $is_saved = ( $page->{meta}{source_kind} || '' ) ne 'transient' && $page_id ne '';
    my $page_url = $is_saved ? $self->_saved_page_url($page_id) : '';
    my $urls = {
        edit   => $is_saved ? $page_url . '/edit' : $self->{pages}->editable_url($page),
        render => $is_saved ? $page_url : $self->{pages}->render_url($page),
        source => $is_saved ? $page_url . '/edit' : $self->{pages}->editable_url($page),
    };
    my $form_action = $is_saved ? $page_url . '/edit' : '/';

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
      overflow: hidden;
    }
    .editor-overlay,
    .instruction-editor {
      display: block;
      width: 100%;
      min-height: 520px;
      box-sizing: border-box;
      margin: 0;
      padding: 12px;
      font-family: Menlo, Consolas, "Courier New", monospace;
      font-size: 14px;
      line-height: 21px;
      white-space: pre;
      word-break: normal;
      overflow-wrap: normal;
      overflow: auto;
      tab-size: 4;
      letter-spacing: 0;
    }
    .editor-overlay-viewport {
      position: absolute;
      inset: 0;
      overflow: hidden;
      pointer-events: none;
      background: transparent;
    }
    .editor-overlay {
      position: absolute;
      top: 0;
      left: 0;
      min-width: 100%;
      color: #e6edf3;
      background: transparent;
      unicode-bidi: plaintext;
      direction: ltr;
      will-change: transform;
    }
    .instruction-editor {
      position: relative;
      z-index: 1;
      height: 520px;
      color: transparent;
      border: 0;
      resize: vertical;
      background: transparent;
      caret-color: #f8f8f2;
      outline: none;
      -webkit-text-fill-color: transparent;
      unicode-bidi: plaintext;
      direction: ltr;
      overflow: auto;
      scrollbar-gutter: stable both-edges;
    }
    .instruction-editor::selection {
      background: rgba(121, 192, 255, 0.35);
      -webkit-text-fill-color: transparent;
    }
    .tok-directive { color: #ffd866; font-weight: normal; text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 2px; }
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
  <form method="post" action="__FORM_ACTION__" id="instruction-form">
    <div class="editor-stack">
      <div class="editor-overlay-viewport" aria-hidden="true"><pre class="editor-overlay" id="instruction-highlight">__INITIAL_HIGHLIGHT__</pre></div>
      <textarea class="instruction-editor" id="instruction-editor" name="instruction" wrap="off" spellcheck="false" autocapitalize="off" autocomplete="off" autocorrect="off">__SOURCE__</textarea>
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
function ddStoreToken(tokens, html) {
  tokens.push(html);
  return '\u001eHL' + (tokens.length - 1) + '\u001e';
}
function ddRestoreTokens(text, tokens) {
  if (!Array.isArray(tokens) || !tokens.length) return text;
  return String(text).replace(/\u001eHL(\d+)\u001e/g, function(_, index) {
    return Object.prototype.hasOwnProperty.call(tokens, index) ? tokens[index] : '';
  });
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
  if (section === 'HTML') return ddHighlightHtmlLine(text, state);
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
  const tokens = [];
  css = css.replace(/\/\*[\s\S]*?\*\//g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-comment">' + match + '</span>');
  });
  css = css.replace(/([.#]?[A-Za-z_-][A-Za-z0-9_-]*)(\s*\{)/g, function(_, name, suffix) {
    return ddStoreToken(tokens, '<span class="tok-css">' + name + '</span>') + suffix;
  });
  css = css.replace(/([A-Za-z-]+)(\s*:)/g, function(_, name, suffix) {
    return ddStoreToken(tokens, '<span class="tok-attr">' + name + '</span>') + suffix;
  });
  css = css.replace(/(:\s*)([^;}{]+)/g, function(_, prefix, value) {
    return prefix + ddStoreToken(tokens, '<span class="tok-value tok-css">' + value + '</span>');
  });
  return ddRestoreTokens(css, tokens);
}
function ddHighlightJsText(text) {
  let js = ddEscapeHtml(text);
  const tokens = [];
  js = js.replace(/\/\/[^\n]*/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-comment">' + match + '</span>');
  });
  js = js.replace(/('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-string">' + match + '</span>');
  });
  js = js.replace(/\b(const|let|var|function|return|if|else|for|while|class|new|await|async|try|catch|throw)\b/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-js">' + match + '</span>');
  });
  return ddRestoreTokens(js, tokens);
}
function ddHighlightPerlLine(text) {
  let perl = ddEscapeHtml(text);
  const tokens = [];
  perl = perl.replace(/(\[%[\s\S]*?%\])/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-note">' + match + '</span>');
  });
  perl = perl.replace(/(^|\s)(#.*)$/g, function(_, prefix, comment) {
    return prefix + ddStoreToken(tokens, '<span class="tok-comment">' + comment + '</span>');
  });
  perl = perl.replace(/('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-string">' + match + '</span>');
  });
  perl = perl.replace(/\b(my|sub|return|if|elsif|else|for|foreach|while|last|next|die|print|use|local|our|state|undef)\b/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-perl-keyword">' + match + '</span>');
  });
  perl = perl.replace(/([$@%][A-Za-z_][A-Za-z0-9_]*)/g, function(match) {
    return ddStoreToken(tokens, '<span class="tok-perl-var">' + match + '</span>');
  });
  return ddRestoreTokens(perl, tokens);
}
function ddOverlayHtml(text) {
  const source = String(text);
  let html = ddHighlightInstruction(source);
  if (source.endsWith('\n')) html += ' ';
  return html;
}
function ddSyncEditorOverlay() {
  ddHighlight.style.minWidth = Math.max(ddEditor.scrollWidth, ddEditor.clientWidth) + 'px';
  ddHighlight.style.minHeight = Math.max(ddEditor.scrollHeight, ddEditor.clientHeight) + 'px';
  ddHighlight.style.transform = 'translate(' + (-ddEditor.scrollLeft) + 'px, ' + (-ddEditor.scrollTop) + 'px)';
}
function ddRenderEditor(text) {
  ddHighlight.innerHTML = ddOverlayHtml(text);
  ddSyncEditorOverlay();
}
ddEditor.addEventListener('input', function() {
  ddRenderEditor(ddEditor.value);
});
ddEditor.addEventListener('scroll', function() {
  ddSyncEditorOverlay();
});
ddEditor.addEventListener('change', function() {
  ddForm.submit();
});
window.addEventListener('resize', function() {
  ddSyncEditorOverlay();
});
ddEditor.value = __SOURCE_JSON__;
ddRenderEditor(ddEditor.value);
</script>
</body>
</html>
HTML

    $html =~ s/__TITLE__/$title/g;
    $html =~ s/__TOP_CHROME__/$self->_top_chrome_html( $page, \%$urls )/ge;
    $html =~ s/__INITIAL_HIGHLIGHT__/$self->_editor_overlay_html($raw_source)/ge;
    $html =~ s/__SOURCE__/$source/g;
    $html =~ s/__SOURCE_JSON__/_json_for_inline_script($raw_source)/ge;
    $html =~ s/__FORM_ACTION__/$form_action/g;
    return $html;
}

# _json_for_inline_script($text)
# Encodes text as JSON for inline script assignment without allowing HTML parser breakouts.
# Input: raw text string.
# Output: JSON string literal safe for inclusion inside a <script> block.
sub _json_for_inline_script {
    my ($text) = @_;
    my $json = json_encode( defined $text ? $text : '' );
    $json =~ s/</\\u003c/g;
    $json =~ s/>/\\u003e/g;
    $json =~ s/&/\\u0026/g;
    return $json;
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

# _editor_overlay_html($source)
# Generates the browser overlay HTML while preserving the textarea's final blank line geometry.
# Input: canonical bookmark instruction text.
# Output: highlighted HTML string with a trailing sentinel when the source ends in a newline.
sub _editor_overlay_html {
    my ( $self, $source ) = @_;
    my $html = $self->_highlight_instruction_html($source);
    $html .= ' ' if defined $source && $source =~ /\n\z/;
    return $html;
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
    return $self->_highlight_html_text( $text, $state ) if $section eq 'HTML';
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
            my ( $before, $tag, $mode_name, $after ) = $line =~ m{\A(.*?)(<(script|style)\b[\s\S]*?>)(.*)\z}is;
            if ( defined $tag ) {
                my $mode = lc( $mode_name || '' ) eq 'script' ? 'script' : 'style';
                $out .= $self->_highlight_markup_text($before);
                $out .= $self->_highlight_markup_text($tag);
                $line = $after;
                $state->{html_mode} = $mode;
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
    my $helper = ref($self) || __PACKAGE__;
    my $css = _escape_html($text);
    my @tokens;
    $css =~ s{(/\*[\s\S]*?\*/)}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-comment">$1</span>} )}ge;
    $css =~ s!([.\#]?[A-Za-z_-][A-Za-z0-9_-]*)(\s*\{)!$helper->_highlight_store_token( \@tokens, qq{<span class="tok-css">$1</span>} ) . $2!ge;
    $css =~ s!([A-Za-z-]+)(\s*:)!$helper->_highlight_store_token( \@tokens, qq{<span class="tok-attr">$1</span>} ) . $2!ge;
    $css =~ s!(:\s*)([^;\}\{]+)!$1 . $helper->_highlight_store_token( \@tokens, qq{<span class="tok-value tok-css">$2</span>} )!ge;
    return $helper->_highlight_restore_tokens( $css, \@tokens );
}

# _highlight_js_text($text)
# Highlights JavaScript-like text inside HTML script blocks.
# Input: raw JavaScript text fragment.
# Output: highlighted HTML fragment.
sub _highlight_js_text {
    my ( $self, $text ) = @_;
    my $helper = ref($self) || __PACKAGE__;
    my $js = _escape_html($text);
    my @tokens;
    $js =~ s{(//[^\n]*)}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-comment">$1</span>} )}ge;
    $js =~ s{('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-string">$1</span>} )}ge;
    $js =~ s{\b(const|let|var|function|return|if|else|for|while|class|new|await|async|try|catch|throw)\b}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-js">$1</span>} )}ge;
    return $helper->_highlight_restore_tokens( $js, \@tokens );
}

# _highlight_perl_text($text)
# Highlights Perl-like text inside CODE sections.
# Input: raw Perl text fragment.
# Output: highlighted HTML fragment.
sub _highlight_perl_text {
    my ( $self, $text ) = @_;
    my $helper = ref($self) || __PACKAGE__;
    my $perl = _escape_html($text);
    my @tokens;
    $perl =~ s{(\[%[\s\S]*?%\])}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-note">$1</span>} )}ge;
    my $comment = '';
    if ( $perl =~ /\A(.*?)(\s\#.*|\#.*)\z/ ) {
        $perl = $1;
        $comment = $helper->_highlight_store_token( \@tokens, qq{<span class="tok-comment">$2</span>} );
    }
    $perl =~ s{('(?:\\.|[^'])*'|&quot;(?:\\.|[^&])*?&quot;)}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-string">$1</span>} )}ge;
    $perl =~ s{\b(my|sub|return|if|elsif|else|for|foreach|while|last|next|die|print|use|local|our|state|undef)\b}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-perl-keyword">$1</span>} )}ge;
    $perl =~ s{([$@%][A-Za-z_][A-Za-z0-9_]*)}{$helper->_highlight_store_token( \@tokens, qq{<span class="tok-perl-var">$1</span>} )}ge;
    return $helper->_highlight_restore_tokens( $perl . $comment, \@tokens );
}

# _highlight_store_token($tokens, $html)
# Replaces one rendered highlight fragment with a placeholder so later regex passes do not mutate inserted markup.
# Input: token array reference and rendered HTML fragment string.
# Output: placeholder marker string.
sub _highlight_store_token {
    my ( $self, $tokens, $html ) = @_;
    push @{$tokens}, $html;
    return sprintf "\x1EHL%d\x1E", scalar( @{$tokens} ) - 1;
}

# _highlight_restore_tokens($text, $tokens)
# Restores placeholder-protected highlight fragments after all regex passes finish.
# Input: placeholder-bearing text string and token array reference.
# Output: highlighted HTML string.
sub _highlight_restore_tokens {
    my ( $self, $text, $tokens ) = @_;
    return $text if ref($tokens) ne 'ARRAY' || !@{$tokens};
    $text =~ s/\x1EHL(\d+)\x1E/( defined $tokens->[$1] ? $tokens->[$1] : '' )/ge;
    return $text;
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
    my $request_context = $page->{meta}{request_context} || {};
    my $current_page = $self->_effective_current_page($page);
    my $transient_allowed = _transient_url_tokens_allowed();
    my %action_urls;
    for my $action ( @{ $page->as_hash->{actions} || [] } ) {
        next if ref($action) ne 'HASH' || !$action->{id};
        my $saved_action_url = $self->_saved_page_url( $page->as_hash->{id} || '' );
        $saved_action_url .= '/action/' . $action->{id} if $saved_action_url ne '';
        my $atoken = $self->{actions}
          ? $self->{actions}->encode_action_payload(
              action => $action,
              page   => $page,
              source => $page->{meta}{source_kind} || 'saved',
            )
          : undef;
        $action_urls{ $action->{id} } = $atoken
          ? ( $transient_allowed ? '/action?atoken=' . URI::Escape::uri_escape($atoken) : $saved_action_url )
          : $saved_action_url;
    }
    my $page_url = ( $page->{meta}{source_kind} || '' ) eq 'transient'
      ? $self->{pages}->editable_url($page)
      : $self->_saved_page_url( $page->as_hash->{id} || '' );
    my $runtime_context = {
        params       => { %{ $page->{state} || {} } },
        current_page => $current_page,
    };
    return $page->render_html(
        action_urls => \%action_urls,
        page_url    => $page_url,
        chrome_html => $self->_top_chrome_html(
            $page,
            {
                edit   => ( ( $page->{meta}{source_kind} || '' ) eq 'transient' && $transient_allowed ) ? '/?token=' . $self->{pages}->encode_page($page) : $page_url . '/edit',
                render => ( ( $page->{meta}{source_kind} || '' ) eq 'transient' && $transient_allowed ) ? '/?mode=render&token=' . $self->{pages}->encode_page($page) : $page_url,
                source => ( ( $page->{meta}{source_kind} || '' ) eq 'transient' && $transient_allowed ) ? '/?token=' . $self->{pages}->encode_page($page) : $page_url . '/edit',
            },
        ),
        nav_html => $self->_nav_items_html(
            page            => $page,
            runtime_context => $runtime_context,
        ),
    );
}

# _effective_current_page($page)
# Resolves the logical page path used by nav fragments and runtime template context.
# Input: page document object.
# Output: request path string, preferring the saved bookmark route for transient play of named bookmarks.
sub _effective_current_page {
    my ( $self, $page ) = @_;
    my $request_context = $page->{meta}{request_context} || {};
    my $request_path = $request_context->{path} || '';
    my $page_id = $page->as_hash->{id} || '';

    return $self->_saved_page_url($page_id)
      if $request_path eq '/'
      && $page_id ne ''
      && ( $page->{meta}{source_kind} || '' ) eq 'transient';

    return $request_path;
}

# _nav_items_html(%args)
# Renders saved nav/*.tt bookmark fragments between page chrome and body.
# Input: page document object and runtime context hash reference.
# Output: HTML fragment string.
sub _nav_items_html {
    my ( $self, %args ) = @_;
    my $page = $args{page} || return '';
    my $page_id = $page->as_hash->{id} || '';
    return '' if $page_id =~ m{\Anav/};
    return '' if ( $page->{meta}{skill_route_id} || '' ) =~ m{\Anav/};

    my $paths = $self->{pages}{paths} || return '';
    my @roots = $paths->can('dashboards_layers') ? $paths->dashboards_layers : $paths->dashboards_roots;
    my %nav_ids;
    my @nav_ids;
    for my $dashboards_root (@roots) {
        my $nav_root = File::Spec->catdir( $dashboards_root, 'nav' );
        next if !-d $nav_root;
        opendir my $dh, $nav_root or next;
        for my $entry ( sort grep {
            $_ ne '.' && $_ ne '..'
              && $_ =~ /\.tt\z/
              && -f File::Spec->catfile( $nav_root, $_ )
        } readdir $dh )
        {
            my $nav_id = 'nav/' . $entry;
            push @nav_ids, $nav_id if !$nav_ids{$nav_id}++;
        }
        closedir $dh;
    }
    my @items;
    my $current_page = $args{runtime_context}{current_page} || '';
    for my $nav_id (@nav_ids) {
        my $nav_page = eval { $self->_load_named_page($nav_id) };
        next if !$nav_page || $@;
        $nav_page->{meta}{raw_instruction} = $nav_page->canonical_instruction;
        $nav_page = $self->{runtime}->prepare_page(
            page            => $self->_page_with_runtime_state(
                $nav_page,
                query_params => $args{runtime_context}{params} || {},
                body_params  => {},
                path         => $self->_saved_page_url($page_id),
                remote_addr  => $self->{_current_request_context}{remote_addr},
                headers      => { host => $self->{_current_request_context}{host} || '' },
            ),
            source          => $nav_page->{meta}{source_kind} || 'saved',
            runtime_context => {
                %{ $args{runtime_context} || { params => {} } },
                current_page => $current_page,
            },
        );
        my $fragment = $self->_page_fragment_html($nav_page);
        next if $fragment eq '';
        push @items, qq{<li data-nav-id="} . _escape_html($nav_id) . qq{">$fragment</li>};
    }

    require Developer::Dashboard::SkillDispatcher;
    my $dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $paths );
    for my $nav_page ( @{ $dispatcher->all_skill_nav_pages || [] } ) {
        $nav_page = $self->{runtime}->prepare_page(
            page            => $self->_page_with_runtime_state(
                $nav_page,
                query_params => $args{runtime_context}{params} || {},
                body_params  => {},
                path         => $self->_saved_page_url($page_id),
                remote_addr  => $self->{_current_request_context}{remote_addr},
                headers      => { host => $self->{_current_request_context}{host} || '' },
            ),
            source          => 'skill',
            runtime_context => {
                %{ $args{runtime_context} || { params => {} } },
                current_page => $current_page,
            },
        );
        my $nav_id = $nav_page->as_hash->{id} || '';
        my $fragment = $self->_page_fragment_html($nav_page);
        next if $fragment eq '';
        push @items, qq{<li data-nav-id="} . _escape_html($nav_id) . qq{">$fragment</li>};
    }

    return '' if !@items;
    return qq{<section class="dashboard-nav-items"><ul>} . join( '', @items ) . qq{</ul></section>};
}

# _page_fragment_html($page)
# Builds a body-level HTML fragment from a prepared page document.
# Input: prepared page document object.
# Output: HTML fragment string.
sub _page_fragment_html {
    my ( $self, $page ) = @_;
    return '' if !$page;

    my $fragment = defined $page->{layout}{body} ? $page->{layout}{body} : '';

    for my $chunk ( @{ $page->{meta}{runtime_outputs} || [] } ) {
        next if !defined $chunk || ref($chunk);
        $fragment .= $chunk;
    }
    for my $chunk ( @{ $page->{meta}{runtime_errors} || [] } ) {
        next if !defined $chunk || ref($chunk);
        $fragment .= qq{<pre class="runtime-error">} . _escape_html($chunk) . qq{</pre>\n};
    }

    return $fragment;
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
# Loads an older /app/<name> resource as either a bookmark page or saved URL forward.
# Input: bookmark id and request metadata.
# Output: response array reference.
sub _legacy_app_response {
    my ( $self, %args ) = @_;
    my $id = $args{id} || die 'Missing app id';
    my $parsed = eval { $self->_load_named_page($id) };
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

    my $raw = eval { $self->{pages}->read_saved_entry($id) };
    if ( !defined $raw || $@ ) {
        my $skill_response = $self->_skill_app_fallback_response( id => $id, %args );
        return $skill_response if $skill_response;
        return $self->_missing_named_page_response($id);
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
    return $self->dispatch_request(
        path        => $path,
        query       => $query,
        method      => 'GET',
        body        => '',
        remote_addr => $args{remote_addr},
        headers     => $args{headers} || {},
    );
}

# _skill_app_fallback_response(%args)
# Attempts the /app/<skill> or /app/<skill>/<page> fallback before the blank saved-page editor opens.
# Input: unresolved app id plus normalized request metadata.
# Output: response array reference for a matched skill route, a 404 for missing namespaced skill routes, or undef when the id is not a skill route.
sub _skill_app_fallback_response {
    my ( $self, %args ) = @_;
    my $id = $args{id} || return;
    my ( $skill_name, @rest ) = split m{/+}, $id;
    return if !$skill_name;

    require Developer::Dashboard::SkillDispatcher;
    require Developer::Dashboard::SkillManager;
    my $dispatcher = Developer::Dashboard::SkillDispatcher->new();
    my $manager = Developer::Dashboard::SkillManager->new();
    my $installed_skill = $manager->get_skill_path( $skill_name, include_disabled => 1 );
    if ( !$installed_skill ) {
        return @rest ? [ 404, 'text/plain; charset=utf-8', "Not found\n" ] : undef;
    }
    if ( !$dispatcher->get_skill_path($skill_name) ) {
        return [ 404, 'text/plain; charset=utf-8', "Not found\n" ];
    }

    return $dispatcher->route_response(
        app          => $self,
        skill_name   => $skill_name,
        route        => join( '/', @rest ),
        query_params => $args{query_params} || {},
        body_params  => $args{body_params}  || {},
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
        path         => '/app/' . $id,
    );
}

# _missing_named_page_response($id)
# Builds the editor response for an unknown /app/<id> route using a blank bookmark template.
# Input: requested app id string without the /app/ prefix.
# Output: response array reference containing the edit view.
sub _missing_named_page_response {
    my ( $self, $id ) = @_;
    my $bookmark_path = $self->_saved_page_url($id);
    my $instruction = join "\n",
        'TITLE: Developer Dashboard',
        ':--------------------------------------------------------------------------------:',
        "BOOKMARK: $bookmark_path",
        ':--------------------------------------------------------------------------------:',
        'HTML:',
        '',
        'Blank page',
        '';
    my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
    $page->{meta}{raw_instruction} = $instruction;
    $page->{meta}{source_kind} = 'saved';
    return [ 200, 'text/html; charset=utf-8', $self->_edit_html($page) ];
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
# Decodes and executes an older /ajax token payload.
# Input: request params and metadata.
# Output: response array reference.
sub _legacy_ajax_response {
    my ( $self, %args ) = @_;
    my $params = $args{params} || {};
    my $type  = $params->{type} || 'text';
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
    my $code;
    my $saved_path = '';
    if ( my $token = $params->{token} ) {
        $code = eval { decode_payload($token) };
        return [ 400, 'text/plain; charset=utf-8', "$@" ] if $@;
    }
    elsif ( ( $params->{file} || '' ) ne '' ) {
        my $runtime_root = $self->{pages}{paths} ? $self->{pages}{paths}->runtime_root : '';
        $saved_path = eval {
            Developer::Dashboard::Zipper::saved_ajax_file_path(
                file         => $params->{file},
                runtime_root => $runtime_root,
            );
        };
        return [ 400, 'text/plain; charset=utf-8', "$@" ] if $@;
        return [ 404, 'text/plain; charset=utf-8', "Ajax handler not found\n" ] if $saved_path eq '' || !-f $saved_path;
    }
    else {
        return [ 400, 'text/plain; charset=utf-8', "missing token\n" ];
    }
    my $page = Developer::Dashboard::PageDocument->new(
        id    => ( $params->{page} || $params->{file} || '' ),
        title => 'Bookmark Ajax',
    );
    return [
        200,
        $types{$type} || 'text/plain; charset=utf-8',
        {
            stream => sub {
                my ($writer) = @_;
                if ($saved_path ne '') {
                    $self->{runtime}->stream_saved_ajax_file(
                        path          => $saved_path,
                        page          => $params->{page} || '',
                        type          => $type,
                        params        => $params,
                        stdout_writer => $writer,
                        stderr_writer => $writer,
                    );
                    return;
                }
                my $result = $self->{runtime}->stream_code_block(
                    code            => $code,
                    page            => $page,
                    source          => 'transient',
                    state           => {},
                    runtime_context => { params => $params },
                    stdout_writer   => $writer,
                    stderr_writer   => $writer,
                    return_writer   => $writer,
                );
                $writer->( $result->{error} ) if defined $result->{error} && $result->{error} ne '';
            },
        },
    ];
}

# _legacy_ajax_allowed($params)
# Checks whether an older /ajax request is allowed under the transient token policy.
# Input: flat request parameter hash reference.
# Output: boolean true when no token is present or transient token URLs are enabled.
sub _legacy_ajax_allowed {
    my ( $self, $params ) = @_;
    return 1 if ref($params) ne 'HASH';
    return 1 if ( $params->{file} || '' ) ne '';
    return 1 if ( $params->{token} || '' ) eq '';
    return _transient_url_tokens_allowed();
}

# ajax_singleton_stop_response(%args)
# Terminates one saved-Ajax singleton worker on explicit browser page-lifecycle cleanup.
# Input: normalized request params containing one singleton name.
# Output: response array reference with a no-content status.
sub ajax_singleton_stop_response {
    my ( $self, %args ) = @_;
    my ($params) = $self->_request_params(%args);
    my $singleton = $self->{runtime}->_normalize_saved_ajax_singleton( $params->{singleton} );
    $self->{runtime}->_kill_saved_ajax_singleton($singleton) if $singleton ne '';
    return [ 204, 'text/plain; charset=utf-8', '' ];
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

# _request_params(%args)
# Parses the normalized raw query/body strings for one request.
# Input: request method, raw query string, and raw body string.
# Output: query-parameter and body-parameter hash references.
sub _request_params {
    my ( $self, %args ) = @_;
    my $query = defined $args{query} ? $args{query} : '';
    my $body  = defined $args{body}  ? $args{body}  : '';
    my $method = uc( $args{method} || 'GET' );
    my %params = _parse_query($query);
    my %body_params = $method eq 'POST' ? _parse_query($body) : ();
    return ( \%params, \%body_params );
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

# _login_redirect_target(%args)
# Builds the original request path/query that helper login should return to.
# Input: normalized request path and query values.
# Output: sanitized relative redirect target string, defaulting to '/'.
sub _login_redirect_target {
    my ( $self, %args ) = @_;
    my $path = defined $args{path} && $args{path} ne '' ? $args{path} : '/';
    my $query = defined $args{query} && $args{query} ne '' ? '?' . $args{query} : '';
    return $self->_sanitize_redirect_target( $path . $query );
}

# _sanitize_redirect_target($target)
# Validates a post-login redirect target so helpers only return to local app routes.
# Input: requested redirect target string.
# Output: safe relative redirect target string, or '/' when invalid.
sub _sanitize_redirect_target {
    my ( $self, $target ) = @_;
    $target = _trim($target);
    return '/' if $target eq '';
    return '/' if $target !~ m{\A/};
    return '/' if $target =~ m{\A//};
    return '/' if $target =~ m{[\r\n]};
    return '/' if $target =~ m{\A/login(?:\z|[/?#])};
    return $target;
}

# _normalized_saved_page_id($id)
# Normalizes one saved bookmark id for route generation.
# Input: saved bookmark id string, optionally already prefixed with /app/.
# Output: bookmark id string without leading /app/ or duplicate slashes.
sub _normalized_saved_page_id {
    my ( $self, $id ) = @_;
    $id = _trim($id);
    $id =~ s{\A/+app/+}{};
    $id =~ s{\A/+}{};
    return $id;
}

# _saved_page_url($id)
# Builds the canonical /app/<id> route for one saved bookmark id.
# Input: saved bookmark id string.
# Output: canonical /app/<id> path string, or empty string when id is empty.
sub _saved_page_url {
    my ( $self, $id ) = @_;
    my $normalized = $self->_normalized_saved_page_id($id);
    return '' if $normalized eq '';
    return '/app/' . $normalized;
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
  <div style="text-align:right;white-space:pre-wrap;font-family:'Segoe UI Emoji','Noto Color Emoji','Segoe UI Symbol',Georgia,'Times New Roman',serif">%s<span id="status-on-top">%s</span></div>
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
    @pairs = $self->_ip_pairs_from_ipconfig;
    return @pairs if @pairs;
    return $self->_ip_pairs_from_ifconfig;
}

# _ip_pairs_from_ip()
# Reads IPv4 interface/address pairs using the `ip` command when available.
# Input: none.
# Output: list of hashes with iface and ip keys.
sub _ip_pairs_from_ip {
    my ($self) = @_;
    return () if !command_in_path('ip');
    my ( $stdout, undef, $exit_code ) = capture {
        system 'ip', '-o', '-4', 'addr', 'show', 'up', 'scope', 'global';
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

# _ip_pairs_from_ipconfig()
# Reads IPv4 interface/address pairs using Windows ipconfig output when available.
# Input: none.
# Output: list of hashes with iface and ip keys.
sub _ip_pairs_from_ipconfig {
    my ($self) = @_;
    return () if !command_in_path('ipconfig');
    my ( $stdout, undef, $exit_code ) = capture {
        system 'ipconfig';
        return $? >> 8;
    };
    return () if $exit_code != 0 || !defined $stdout || $stdout eq '';
    my @pairs;
    my $iface = '';
    for my $line ( split /\n/, $stdout ) {
        if ( $line =~ /^\S.*adapter\s+(.+?):\s*$/i ) {
            $iface = $1;
            next;
        }
        next if $iface eq '';
        next if $line !~ /IPv4[^:]*:\s*(\d+\.\d+\.\d+\.\d+)/i;
        my $ip = $1;
        next if $ip =~ /^127\./;
        push @pairs, { iface => $iface, ip => $ip };
    }
    return @pairs;
}

# _ip_pairs_from_ifconfig()
# Reads IPv4 interface/address pairs using `ifconfig` as a fallback on systems without `ip`.
# Input: none.
# Output: list of hashes with iface and ip keys.
sub _ip_pairs_from_ifconfig {
    my ($self) = @_;
    return () if !command_in_path('ifconfig');
    my ( $stdout, undef, $exit_code ) = capture {
        system 'ifconfig';
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
# Renders the older page-header indicator summary for page chrome.
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
# Builds the `/system/status` payload from the indicator store.
# Input: none.
# Output: hash reference with array, hash, and status maps.
sub _page_status_payload {
    my ($self) = @_;
    my $indicators = $self->{prompt} ? $self->{prompt}{indicators} : undef;
    return { array => [], hash => {}, status => {} } if !$indicators || !$indicators->can('page_header_payload');
    if ( $self->{config} && $self->{config}->can('collectors') ) {
        $indicators->sync_collectors( $self->{config}->collectors );
    }
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

# _serve_static_file($type, $filename)
# Serves static files from the public directory (js, css, others).
# Input: $type (js, css, or others), $filename (requested filename).
# Output: array reference of status code, content type, body.
sub _serve_static_file {
    my ( $self, $type, $filename ) = @_;

    # Prevent directory traversal attacks
    return [ 400, 'text/plain; charset=utf-8', "Bad Request\n" ]
        if $filename =~ /\.\./;

    my @public_roots = $self->_static_file_roots($type);
    my $file_path = '';
    for my $public_dir (@public_roots) {
        my $candidate = File::Spec->catfile( $public_dir, $filename );
        my $real_path = eval { File::Spec->rel2abs($candidate) } || '';
        my $quoted_public = quotemeta($public_dir);
        next if $real_path !~ /^$quoted_public(?:\/|\z)/;
        next if !-f $candidate || !-r $candidate;
        $file_path = $candidate;
        last;
    }
    return [ 404, 'text/plain; charset=utf-8', "Not Found\n" ] if $file_path eq '';

    # Determine content type
    my $content_type = $self->_get_content_type( $type, $filename );

    # Read and return file
    open my $fh, '<', $file_path or return [ 500, 'text/plain; charset=utf-8', "Internal Server Error\n" ];
    my $content = do { local $/; <$fh> };
    close $fh;

    return [ 200, $content_type, $content ];
}

# _static_file_roots($type)
# Returns candidate public directories for static file serving in lookup order.
# Input: asset type string such as js, css, or others.
# Output: ordered list of directory path strings.
sub _static_file_roots {
    my ( $self, $type ) = @_;
    my @roots;
    my %seen;

    my $paths = $self->{pages} && ref( $self->{pages} ) eq 'Developer::Dashboard::PageStore'
      ? $self->{pages}{paths}
      : undef;
    if ($paths) {
        for my $runtime_root ( $paths->runtime_roots ) {
            my $root = File::Spec->catdir( $runtime_root, 'dashboard', 'public', $type );
            push @roots, $root if !$seen{$root}++;
        }
        for my $dashboards_root ( $paths->dashboards_roots ) {
            my $root = File::Spec->catdir( $dashboards_root, 'public', $type );
            push @roots, $root if !$seen{$root}++;
        }
    }

    my $home_root = File::Spec->catdir(
        $ENV{HOME} || $ENV{USERPROFILE} || '/root',
        '.developer-dashboard',
        'dashboard',
        'public',
        $type
    );
    push @roots, $home_root if !$seen{$home_root}++;
    return @roots;
}

# _get_content_type($type, $filename)
# Determines the MIME type based on file type and extension.
# Input: $type (js, css, or others), $filename (requested filename).
# Output: MIME type string.
sub _get_content_type {
    my ( $self, $type, $filename ) = @_;

    if ( $type eq 'js' ) {
        return 'application/javascript; charset=utf-8';
    }
    elsif ( $type eq 'css' ) {
        return 'text/css; charset=utf-8';
    }
    elsif ( $filename =~ /\.json$/i ) {
        return 'application/json; charset=utf-8';
    }
    elsif ( $filename =~ /\.xml$/i ) {
        return 'application/xml; charset=utf-8';
    }
    elsif ( $filename =~ /\.txt$/i ) {
        return 'text/plain; charset=utf-8';
    }
    elsif ( $filename =~ /\.html?$/i ) {
        return 'text/html; charset=utf-8';
    }
    elsif ( $filename =~ /\.svg$/i ) {
        return 'image/svg+xml';
    }
    elsif ( $filename =~ /\.png$/i ) {
        return 'image/png';
    }
    elsif ( $filename =~ /\.jpe?g$/i ) {
        return 'image/jpeg';
    }
    elsif ( $filename =~ /\.gif$/i ) {
        return 'image/gif';
    }
    elsif ( $filename =~ /\.webp$/i ) {
        return 'image/webp';
    }
    elsif ( $filename =~ /\.ico$/i ) {
        return 'image/x-icon';
    }
    else {
        return 'application/octet-stream';
    }
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
page rendering modes, and page/action execution endpoints. It also provides
static file serving for JavaScript, CSS, and other assets from the public
directory structure (~/.developer-dashboard/dashboard/public/{js,css,others}).

=head1 METHODS

=head2 new, handle

Construct and dispatch the local web application.

=head2 _serve_static_file($type, $filename)

Serves static files from the public directory.

Input: $type (js, css, or others subdirectory), $filename (requested filename).
Output: array reference of [status_code, content_type, body].

Security: Prevents directory traversal attacks and verifies files are within
the public directory before serving.

=head2 _get_content_type($type, $filename)

Determines the MIME type for a file based on its type and extension.

Input: $type (js, css, or others), $filename (requested filename).
Output: MIME type string suitable for Content-Type header.

Supports: JS, CSS, JSON, XML, HTML, SVG, PNG, JPEG, GIF, WebP, ICO, and others.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the main route backend for the browser application. It handles login and logout, saved and transient page render/source/edit routes, status endpoints, saved Ajax endpoints, API dashboard and SQL dashboard routes, and the auth checks that decide whether a request is local admin, helper user, or unauthorized outsider.

=head1 WHY IT EXISTS

It exists because the dashboard browser surface is large and security-sensitive. Centralizing route behavior, auth gating, saved-page handling, Ajax endpoints, and response shaping keeps the product behavior coherent and testable.

=head1 WHEN TO USE

Use this file when changing browser routes, helper login behavior, page render/source/edit flows, saved Ajax endpoints, or the runtime JSON and HTML responses for dashboard workspaces.

=head1 HOW TO USE

Construct it with the action runner, auth service, page store, prompt, page resolver, page runtime, and session store, then hand it to the Dancer adapter or PSGI bootstrap. Route-specific behavior belongs here rather than in the transport wrapper.

=head1 WHAT USES IT

It is used by C<Developer::Dashboard::Web::DancerApp>, by C<app.psgi>, by the CLI web server wrapper, and by the broad web/browser regression suite that covers routes, auth, Ajax, and workspace behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Web::App -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/03-web-app.t t/08-web-update-coverage.t t/web_app_static_files.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
