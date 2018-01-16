package Firefox::Marionette;

use warnings;
use strict;
use Firefox::Marionette::Response();
use Firefox::Marionette::Element();
use Firefox::Marionette::Cookie();
use Firefox::Marionette::Window::Rect();
use Firefox::Marionette::Element::Rect();
use Firefox::Marionette::Timeouts();
use Firefox::Marionette::Capabilities();
use JSON();
use Socket();
use English qw( -no_match_vars );
use POSIX();
use File::Spec();
use URI();
use File::Temp();
use FileHandle();
use MIME::Base64();

BEGIN {
    if ( $OSNAME eq 'MSWin32' ) {
        require Win32;
        require Win32::Process;
        require Win32::Process::Info;
        Win32::Process::Info->import('NT');
    }
}

our $VERSION = '0.09';

sub _ANYPROCESS                    { return -1 }
sub _COMMAND                       { return 0 }
sub _DEFAULT_HOST                  { return 'localhost' }
sub _ANY_PORT                      { return 0 }
sub _WIN32_ERROR_SHARING_VIOLATION { return 32 }

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless {}, $class;
    my @arguments = ('-marionette');
    $self->{last_message_id} = 0;

    if (   ( defined $parameters{capabilities} )
        && ( $parameters{capabilities}->moz_headless() ) )
    {
        push @arguments, '-headless';
    }
    if ( $parameters{firefox_binary} ) {
        $self->{firefox_binary} = $parameters{firefox_binary};
    }
    if ( $parameters{profile_name} ) {
        $self->{profile} = $parameters{profile_name};
        push @arguments, ( '-P', $self->{profile_name} );
    }
    else {
        my $profile_directory = $self->_setup_new_profile();
        push @arguments,
          ( '-profile', $profile_directory, '--no-remote', '--new-instance' );
    }
    $self->{_pid} = $self->_launch(@arguments);
    my $socket = $self->_setup_local_connection_to_firefox(@arguments);
    my ( $session_id, $capabilities ) =
      $self->_initial_socket_setup( $socket, $parameters{capabilities} );
    if ( $self->_pid() != $capabilities->moz_process_id() ) {
        Carp::croak(
'Failed to correctly determined the Firefox process id through the initial connection capabilities'
        );
    }
    return $self;
}

sub _pid {
    my ($self) = @_;
    return $self->{_pid};
}

sub _launch {
    my ( $self, @arguments ) = @_;
    if ( $OSNAME eq 'MSWin32' ) {
        return $self->_launch_win32(@arguments);
    }
    else {
        return $self->_launch_unix(@arguments);
    }
}

sub _launch_win32 {
    my ( $self, @arguments ) = @_;
    my $binary = $self->_binary();
    Win32::Process::Create( my $process, "$binary",
        'firefox ' . ( join q[ ], map { q["] . $_ . q["] } @arguments ),
        0, Win32::Process::NORMAL_PRIORITY_CLASS(), q[.] )
      || Carp::croak( Win32::FormatMessage( Win32::GetLastError() ) );
    $self->{_win32_process} = $process;
    return $process->GetProcessID();
}

sub _launch_unix {
    my ( $self, @arguments ) = @_;
    my $binary = $self->_binary();
    my $pid;
    if ( $pid = fork ) {
    }
    elsif ( defined $pid ) {
        eval {
            exec {$binary} $binary, @arguments
              or Carp::croak("Failed to exec '$binary':$EXTENDED_OS_ERROR");
        } or do {
            chomp $EVAL_ERROR;
            warn "$EVAL_ERROR\n";
        };
        exit 1;
    }
    return $pid;
}

sub _binary {
    my ($self) = @_;
    my $binary = 'firefox';
    if ( $self->{firefox_binary} ) {
        $binary = $self->{firefox_binary};
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
        my $program_files_key;
        foreach my $possible ( 'ProgramFiles(x86)', 'ProgramFiles' ) {
            if ( $ENV{$possible} ) {
                $program_files_key = $possible;
                last;
            }
        }
        $binary = File::Spec->catfile(
            $ENV{$program_files_key},
            'Mozilla Firefox',
            'firefox.exe'
        );
    }
    elsif ( $OSNAME eq 'darwin' ) {
        $binary = '/Applications/Firefox.app/Contents/MacOS/firefox';
    }
    return $binary;
}

sub _firefox_alive {
    my ($self) = @_;
    if ( $OSNAME eq 'MSWin32' ) {
        my $alive         = 0;
        my $quoted_binary = quotemeta $self->_binary();
        my $info          = Win32::Process::Info->new();
        foreach my $process ( $info->GetProcInfo( $self->_pid() ) ) {
            $alive = 1;
        }
        return $alive;
    }
    else {
        waitpid _ANYPROCESS(), POSIX::WNOHANG();
        return kill 0, $self->_pid();
    }
}

sub _setup_local_connection_to_firefox {
    my ( $self, @arguments ) = @_;
    my $host = _DEFAULT_HOST();
    my $port;
    my $binary = $self->_binary();
    my $socket;
    my $connected;
    while ( ( !$connected ) && ( $self->_firefox_alive() ) ) {
        $socket = undef;
        socket $socket, Socket::PF_INET(), Socket::SOCK_STREAM(), 0
          or Carp::croak("Failed to create a socket: $EXTENDED_OS_ERROR");
        binmode $socket;
        if ( $self->{profile_path} ) {
            $port = $self->_get_port();
            next if ( !defined $port );
            next if ( $port == 0 );
        }
        if ( connect $socket,
            Socket::pack_sockaddr_in( $port, Socket::inet_aton($host) ) )
        {
            $connected = 1;
        }
        elsif ( $EXTENDED_OS_ERROR == POSIX::ECONNREFUSED() ) {
            sleep 1;
        }
        else {
            Carp::croak(
                "Failed to connect to $host on port $port:$EXTENDED_OS_ERROR");
        }
    }
    if ( ( kill 0, $self->_pid() ) && ($socket) ) {
    }
    else {
        Carp::croak( q[Firefox failed to start as '] . join q[ ],
            $binary, @arguments );
    }
    return $socket;
}

sub _setup_new_profile {
    my ($self) = @_;
    my $profile_directory = File::Temp->newdir(
        File::Spec->catdir(
            File::Spec->tmpdir(), 'firefox_marionette_XXXXXXXXXX'
        )
    );
    $self->{profile_directory} = $profile_directory;
    $self->{profile_path} =
      File::Spec->catfile( $profile_directory, 'prefs.js' );
    my $profile_handle =
      FileHandle->new( $self->{profile_path},
        Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL(),
        Fcntl::S_IRWXU() )
      or Carp::croak(
        "Failed to open '$self->{profile_path}' for writing:$EXTENDED_OS_ERROR"
      );
    $self->_write_profile_contents($profile_handle)
      or Carp::croak(
        "Failed to write to '$self->{profile_path}':$EXTENDED_OS_ERROR");
    $profile_handle->close()
      or
      Carp::croak("Failed to close '$self->{profile_path}':$EXTENDED_OS_ERROR");
    return $profile_directory;
}

sub _write_profile_contents {
    my ( $self, $profile_handle ) = @_;
    my $port = _ANY_PORT();
    return $profile_handle->print(<<"_PROFILE_");
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "about:blank");
user_pref("startup.homepage_welcome_url.additional", "about:blank");
user_pref("xpinstall.signatures.required", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("marionette.port", $port);
_PROFILE_
}

sub _get_port {
    my ($self) = @_;
    my $port;
    my $profile_handle =
      FileHandle->new( $self->{profile_path}, Fcntl::O_RDONLY() )
      or ( ( $OSNAME eq 'MSWin32' )
        && ( $EXTENDED_OS_ERROR == _WIN32_ERROR_SHARING_VIOLATION() ) )
      or Carp::croak(
        "Failed to open '$self->{profile_path}' for reading:$EXTENDED_OS_ERROR"
      );
    if ($profile_handle) {
        while ( my $line = <$profile_handle> ) {
            if ( $line =~ /user_pref[(]"marionette.port",[ ]*(\d+)[)];\s*$/smx )
            {
                $port = $1;
            }
        }
        $profile_handle->close()
          or Carp::croak(
            "Failed to close '$self->{profile_path}':$EXTENDED_OS_ERROR");
    }
    if ($port) {
        return $port;
    }
}

sub _initial_socket_setup {
    my ( $self, $socket, $capabilities ) = @_;
    $self->{_socket} = $socket;
    my $initial_response = $self->_read_from_socket();
    $self->{marionette_protocol} = $initial_response->{marionetteProtocol};
    $self->{application_type}    = $initial_response->{applicationType};
    return $self->new_session($capabilities);
}

sub new_session {
    my ( $self, $capabilities ) = @_;
    my $parameters;
    if (   ( defined $capabilities )
        && ( $capabilities->isa('Firefox::Marionette::Capabilities') ) )
    {
        $parameters = {
            acceptInsecureCerts => $capabilities->accept_insecure_certs()
            ? JSON::true()
            : JSON::false(),
            pageLoadStrategy     => $capabilities->page_load_strategy(),
            'moz:webdriverClick' => $capabilities->moz_webdriver_click()
            ? JSON::true
            : JSON::false(),
            'moz:accessibilityChecks' =>
              $capabilities->moz_accessibility_checks() ? JSON::true()
            : JSON::false(),
        };
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:NewSession', $parameters ] );
    my $response = $self->_get_response($message_id);
    $self->{session_id} = $response->result()->{sessionId};
    return ( $self->{session_id},
        $self->_create_capabilities( $response->result()->{capabilities} ) );
}

sub _create_capabilities {
    my ( $self, $parameters ) = @_;
    return Firefox::Marionette::Capabilities->new(
        accept_insecure_certs => $parameters->{acceptInsecureCerts} ? 1 : 0,
        page_load_strategy    => $parameters->{pageLoadStrategy},
        timeouts              => Firefox::Marionette::Timeouts->new(
            page_load => $parameters->{timeouts}->{pageLoad},
            script    => $parameters->{timeouts}->{script},
            implicit  => $parameters->{timeouts}->{implicit},
        ),
        browser_version          => $parameters->{browserVersion},
        platform_name            => $parameters->{platformName},
        rotatable                => $parameters->{rotatable} ? 1 : 0,
        platform_version         => $parameters->{platformVersion},
        moz_profile              => $parameters->{'moz:profile'},
        moz_webdriver_click      => $parameters->{'moz:webdriverClick'} ? 1 : 0,
        moz_process_id           => $parameters->{'moz:processID'},
        browser_name             => $parameters->{browserName},
        moz_headless             => $parameters->{'moz:headless'} ? 1 : 0,
        moz_accessibility_checks => $parameters->{'moz:accessibilityChecks'}
        ? 1
        : 0,
    );
}

sub find_elements {
    my ( $self, $value, $using ) = @_;
    $using ||= 'xpath';
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:FindElements', { using => $using, value => $value }
        ]
    );
    my $response = $self->_get_response($message_id);
    return
      map { Firefox::Marionette::Element->new( $self, $_ ) }
      @{ $response->result() };
}

sub add_cookie {
    my ( $self, $cookie ) = @_;
    my $domain = $cookie->domain();
    if ( !defined $domain ) {
        my $uri = $self->uri();
        if ($uri) {
            my $obj = URI->new($uri);
            $domain = $obj->host();
        }
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            'WebDriver:AddCookie',
            {
                cookie => {
                    httpOnly => $cookie->http_only()
                    ? JSON::true()
                    : JSON::false(),
                    secure => $cookie->secure() ? JSON::true() : JSON::false(),
                    domain => $domain,
                    path   => $cookie->path(),
                    value  => $cookie->value(),
                    expiry => $cookie->expiry(),
                    name   => $cookie->name()
                }
            }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub is_selected {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
'is_selected method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:IsElementSelected', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value} ? 1 : 0;
}

sub is_enabled {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
'is_enabled method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:IsElementEnabled', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value} ? 1 : 0;
}

sub is_displayed {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
'is_displayed method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:IsElementDisplayed', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value} ? 1 : 0;
}

sub send_keys {
    my ( $self, $element, $text ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
            'send_keys method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, 'WebDriver:ElementSendKeys',
            { id => $element->uuid(), text => $text }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub minimise {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:MinimizeWindow' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub maximise {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:MaximizeWindow' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub refresh {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request( [ _COMMAND(), $message_id, 'WebDriver:Refresh' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub capabilities {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetCapabilities' ] );
    my $response = $self->_get_response($message_id);
    return $self->_create_capabilities( $response->result()->{capabilities} );
}

sub delete_cookies {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:DeleteAllCookies' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub delete_cookie {
    my ( $self, $name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, 'WebDriver:DeleteCookie', { name => $name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub cookies {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request( [ _COMMAND(), $message_id, 'WebDriver:GetCookies' ] );
    my $response = $self->_get_response($message_id);
    return map {
        Firefox::Marionette::Cookie->new(
            http_only => $_->{httpOnly} ? 1 : 0,
            secure    => $_->{secure}   ? 1 : 0,
            domain    => $_->{domain},
            path      => $_->{path},
            value     => $_->{value},
            expiry    => $_->{expiry},
            name      => $_->{name},
          )
    } @{ $response->result() };
}

sub tag_name {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
            'tag_name method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:GetElementTagName', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub window_rect {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetWindowRect' ] );
    my $response = $self->_get_response($message_id);
    my $old      = Firefox::Marionette::Window::Rect->new(
        pos_x  => $response->result()->{x},
        pos_y  => $response->result()->{y},
        width  => $response->result()->{width},
        height => $response->result()->{height},
        state  => $response->result()->{state},
    );
    if ( defined $new ) {
        $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(),
                $message_id,
                'WebDriver:SetWindowRect',
                {
                    x      => $new->pos_x(),
                    y      => $new->pos_y(),
                    width  => $new->width(),
                    height => $new->height()
                }
            ]
        );
        $self->_get_response($message_id);
    }
    return $old;
}

sub rect {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
            'rect method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:GetElementRect', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return Firefox::Marionette::Element::Rect->new(
        pos_x  => $response->result()->{x},
        pos_y  => $response->result()->{y},
        width  => $response->result()->{width},
        height => $response->result()->{height},
    );
}

sub text {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
            'text method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:GetElementText', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub clear {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
            'clear method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:ElementClear', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub click {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( $element->isa('Firefox::Marionette::Element') )
        )
      )
    {
        Carp::croak(
            'click method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:ElementClick', { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub timeouts {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetTimeouts' ] );
    my $response = $self->_get_response($message_id);
    my $old      = Firefox::Marionette::Timeouts->new(
        page_load => $response->result()->{pageLoad},
        script    => $response->result()->{script},
        implicit  => $response->result()->{implicit}
    );
    if ( defined $new ) {
        $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(),
                $message_id,
                'WebDriver:SetTimeouts',
                {
                    pageLoad => $new->page_load(),
                    script   => $new->script(),
                    implicit => $new->implicit()
                }
            ]
        );
        $self->_get_response($message_id);
    }
    return $old;
}

sub active_element {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetActiveElement' ] );
    my $response = $self->_get_response($message_id);
    return Firefox::Marionette::Element->new( $self,
        $response->result()->{value} );
}

sub uri {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetCurrentURL' ] );
    my $response = $self->_get_response($message_id);
    return URI->new( $response->result()->{value} );
}

sub full_screen {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:FullscreenWindow' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub dismiss_alert {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:DismissAlert' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub send_alert_text {
    my ( $self, $text ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:SendAlertText', { text => $text }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub accept_dialog {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:AcceptDialog' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub alert_text {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetAlertText' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub selfie {
    my ( $self, $element, @remaining ) = @_;
    my $message_id = $self->_new_message_id();
    my $parameters;
    my %extra;
    if (   ( defined $element )
        && ( $element->isa('Firefox::Marionette::Element') ) )
    {
        $parameters = { id => $element->uuid() };
        %extra = @remaining;
    }
    elsif (( defined $element )
        && ( not( ref $element ) )
        && ( ( scalar @remaining ) % 2 ) )
    {
        %extra = ( $element, @remaining );
        $element = undef;
    }
    if ( $extra{highlights} ) {
        foreach my $highlight ( @{ $extra{highlights} } ) {
            push @{ $parameters->{highlights} }, $highlight->uuid();
        }
    }
    foreach my $key (qw(hash full scroll)) {
        if ( $extra{$key} ) {
            $parameters->{$key} = JSON::true();
        }
    }
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:TakeScreenshot', $parameters ] );
    my $response = $self->_get_response($message_id);
    if ( $extra{hash} ) {
        return $response->result()->{value};
    }
    else {
        my $handle = File::Temp::tempfile(
            File::Spec->catfile(
                File::Spec->tmpdir(), 'firefox_marionette_selfie_XXXXXXXXXXX'
            )
          )
          or Carp::croak(
            "Failed to open temporary file for writing:$EXTENDED_OS_ERROR");
        binmode $handle;
        $handle->print(
            MIME::Base64::decode_base64( $response->result()->{value} ) )
          or
          Carp::croak("Failed to write to temporary file:$EXTENDED_OS_ERROR");
        $handle->seek( 0, Fcntl::SEEK_SET() )
          or Carp::croak(
            "Failed to seek to start of temporary file:$EXTENDED_OS_ERROR");
        return $handle;
    }
}

sub current_chrome_window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetCurrentChromeWindowHandle' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub chrome_window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetChromeWindowHandle' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub chrome_window_handles {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetChromeWindowHandles' ] );
    my $response = $self->_get_response($message_id);
    return @{ $response->result() };
}

sub window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetWindowHandle' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub window_handles {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetWindowHandles' ] );
    my $response = $self->_get_response($message_id);
    return @{ $response->result() };
}

sub css {
    my ( $self, $element, $property_name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:GetElementCSSValue',
            { id => $element->uuid(), propertyName => $property_name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub attribute {
    my ( $self, $element, $name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:GetElementAttribute',
            { id => $element->uuid(), name => $name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub find_element {
    my ( $self, $value, $using ) = @_;
    $using ||= 'xpath';
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:FindElement', { using => $using, value => $value }
        ]
    );
    my $response = $self->_get_response($message_id);
    return Firefox::Marionette::Element->new( $self,
        $response->result()->{value} );
}

sub active_frame {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetActiveFrame' ] );
    my $response = $self->_get_response($message_id);
    if ( defined $response->result()->{value} ) {
        return Firefox::Marionette::Element->new( $self,
            $response->result()->{value} );
    }
    else {
        return;
    }
}

sub title {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request( [ _COMMAND(), $message_id, 'WebDriver:GetTitle' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub quit {
    my ( $self, $flags ) = @_;
    $flags ||=
      ['eAttemptQuit'];    # ["eConsiderQuit", "eAttemptQuit", "eForceQuit"]
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'Marionette:Quit', { flags => $flags } ] );
    my $response = $self->_get_response($message_id);
    close $self->_socket()
      or Carp::croak("Failed to close socket to firefox:$EXTENDED_OS_ERROR");
    delete $self->{_socket};
    if ( $OSNAME eq 'MSWin32' ) {
        $self->{_win32_process}->Wait( Win32::Process::INFINITE() );
    }
    else {
        while ( kill 0, $self->_pid() ) {
            waitpid _ANYPROCESS(), POSIX::WNOHANG();
        }
    }
    return $self;
}

sub context {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'Marionette:GetContext' ] );
    my $response = $self->_get_response($message_id);
    my $context  = $response->result()->{value};        # 'content' or 'chrome'
    if ( defined $new ) {
        $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(), $message_id,
                'Marionette:SetContext', { value => $new }
            ]
        );
        $response = $self->_get_response($message_id);
    }
    return $context;
}

sub accept_connections {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'Marionette:AcceptConnections',
            { value => $new ? JSON::true() : JSON::false() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub async_script {
    my ( $self, $script, %parameters ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            'WebDriver:ExecuteAsyncScript',
            { script => $script, %parameters }
        ]
    );
    return $self;
}

sub script {
    my ( $self, $script, %parameters ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:ExecuteScript', { script => $script, %parameters }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub page_source {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:GetPageSource', { sessionId => $self->_session_id() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub back {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request( [ _COMMAND(), $message_id, 'WebDriver:Back' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub forward {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request( [ _COMMAND(), $message_id, 'WebDriver:Forward' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub screen_orientation {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetScreenOrientation' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub switch_to_parent_frame {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:SwitchToParentFrame' ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub window_type {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, 'WebDriver:GetWindowType' ] );
    my $response = $self->_get_response($message_id);
    return $response->result()->{value};
}

sub switch_to_frame {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            'WebDriver:SwitchToFrame', { element => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub go {
    my ( $self, $uri ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, 'WebDriver:Navigate',
            { url => "$uri", sessionId => $self->_session_id() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

my $x = <<'_DOC_';
  // WebDriver service
#  "WebDriver:AcceptDialog": GeckoDriver.prototype.acceptDialog,
#  "WebDriver:AddCookie": GeckoDriver.prototype.addCookie,
#  "WebDriver:Back": GeckoDriver.prototype.goBack,
  "WebDriver:CloseChromeWindow": GeckoDriver.prototype.closeChromeWindow,
  "WebDriver:CloseWindow": GeckoDriver.prototype.close,
#  "WebDriver:DeleteAllCookies": GeckoDriver.prototype.deleteAllCookies,
#  "WebDriver:DeleteCookie": GeckoDriver.prototype.deleteCookie,
  "WebDriver:DeleteSession": GeckoDriver.prototype.deleteSession,
#  "WebDriver:DismissAlert": GeckoDriver.prototype.dismissDialog,
#  "WebDriver:ElementClear": GeckoDriver.prototype.clearElement,
#  "WebDriver:ElementClick": GeckoDriver.prototype.clickElement,
#  "WebDriver:ElementSendKeys": GeckoDriver.prototype.sendKeysToElement,
#  "WebDriver:ExecuteAsyncScript": GeckoDriver.prototype.executeAsyncScript,
#  "WebDriver:ExecuteScript": GeckoDriver.prototype.executeScript,
#  "WebDriver:FindElement": GeckoDriver.prototype.findElement,
#  "WebDriver:FindElements": GeckoDriver.prototype.findElements,
#  "WebDriver:Forward": GeckoDriver.prototype.goForward,
#  "WebDriver:FullscreenWindow": GeckoDriver.prototype.fullscreenWindow,
#  "WebDriver:GetActiveElement": GeckoDriver.prototype.getActiveElement,
#  "WebDriver:GetActiveFrame": GeckoDriver.prototype.getActiveFrame,
#  "WebDriver:GetAlertText": GeckoDriver.prototype.getTextFromDialog,
#  "WebDriver:GetCapabilities": GeckoDriver.prototype.getSessionCapabilities,
#  "WebDriver:GetChromeWindowHandle": GeckoDriver.prototype.getChromeWindowHandle,
  "WebDriver:GetChromeWindowHandles": GeckoDriver.prototype.getChromeWindowHandles,
#  "WebDriver:GetCookies": GeckoDriver.prototype.getCookies,
  "WebDriver:GetCurrentChromeWindowHandle": GeckoDriver.prototype.getChromeWindowHandle,
#  "WebDriver:GetCurrentURL": GeckoDriver.prototype.getCurrentUrl,
#  "WebDriver:GetElementAttribute": GeckoDriver.prototype.getElementAttribute,
#  "WebDriver:GetElementCSSValue": GeckoDriver.prototype.getElementValueOfCssProperty,
  "WebDriver:GetElementProperty": GeckoDriver.prototype.getElementProperty,
#  "WebDriver:GetElementRect": GeckoDriver.prototype.getElementRect,
#  "WebDriver:GetElementTagName": GeckoDriver.prototype.getElementTagName,
#  "WebDriver:GetElementText": GeckoDriver.prototype.getElementText,
#  "WebDriver:GetPageSource": GeckoDriver.prototype.getPageSource,
#  "WebDriver:GetScreenOrientation": GeckoDriver.prototype.getScreenOrientation,
#  "WebDriver:GetTimeouts": GeckoDriver.prototype.getTimeouts,
#  "WebDriver:GetTitle": GeckoDriver.prototype.getTitle,
#  "WebDriver:GetWindowHandle": GeckoDriver.prototype.getWindowHandle,
#  "WebDriver:GetWindowHandles": GeckoDriver.prototype.getWindowHandles,
#  "WebDriver:GetWindowRect": GeckoDriver.prototype.getWindowRect,
#  "WebDriver:GetWindowType": GeckoDriver.prototype.getWindowType,
#  "WebDriver:IsElementDisplayed": GeckoDriver.prototype.isElementDisplayed,
#  "WebDriver:IsElementEnabled": GeckoDriver.prototype.isElementEnabled,
#  "WebDriver:IsElementSelected": GeckoDriver.prototype.isElementSelected,
#  "WebDriver:MinimizeWindow": GeckoDriver.prototype.minimizeWindow,
#  "WebDriver:MaximizeWindow": GeckoDriver.prototype.maximizeWindow,
#  "WebDriver:Navigate": GeckoDriver.prototype.get,
#  "WebDriver:NewSession": GeckoDriver.prototype.newSession,
  "WebDriver:PerformActions": GeckoDriver.prototype.performActions,
#  "WebDriver:Refresh":  GeckoDriver.prototype.refresh,
  "WebDriver:ReleaseActions": GeckoDriver.prototype.releaseActions,
#  "WebDriver:SendAlertText": GeckoDriver.prototype.sendKeysToDialog,
  "WebDriver:SetScreenOrientation": GeckoDriver.prototype.setScreenOrientation
#  "WebDriver:SetTimeouts": GeckoDriver.prototype.setTimeouts,
#  "WebDriver:SetWindowRect": GeckoDriver.prototype.setWindowRect,
#  "WebDriver:SwitchToFrame": GeckoDriver.prototype.switchToFrame,
  "WebDriver:SwitchToParentFrame": GeckoDriver.prototype.switchToParentFrame,
  "WebDriver:SwitchToShadowRoot": GeckoDriver.prototype.switchToShadowRoot,
  "WebDriver:SwitchToWindow": GeckoDriver.prototype.switchToWindow,
#  "WebDriver:TakeScreenshot": GeckoDriver.prototype.takeScreenshot,
_DOC_

sub marionette_protocol {
    my ($self) = @_;
    return $self->{marionette_protocol};
}

sub application_type {
    my ($self) = @_;
    return $self->{application_type};
}

sub _session_id {
    my ($self) = @_;
    return $self->{session_id};
}

sub _new_message_id {
    my ($self) = @_;
    $self->{last_message_id} += 1;
    return $self->{last_message_id};
}

sub _send_request {
    my ( $self, $object ) = @_;
    my $json   = JSON::encode_json($object);
    my $length = length $json;
    my $result = syswrite $self->_socket(), "$length:$json";
    if ( !defined $result ) {
        Carp::croak("Failed to send request to firefox:$EXTENDED_OS_ERROR");
    }
}

sub _read_from_socket {
    my ($self) = @_;
    my $number_of_bytes_in_response;
    my $initial_buffer;
    while ( !defined $number_of_bytes_in_response ) {
        my $number_of_bytes = sysread $self->_socket(), my $octet, 1;
        if ( defined $number_of_bytes ) {
            $initial_buffer .= $octet;
        }
        if ( $initial_buffer =~ s/^(\d+)://smx ) {
            ($number_of_bytes_in_response) = ($1);
        }
    }
    my $number_of_bytes_already_read = 0;
    my $json                         = q[];
    while ( $number_of_bytes_already_read < $number_of_bytes_in_response ) {
        my $number_of_bytes_read = sysread $self->_socket(), my $buffer,
          $number_of_bytes_in_response - $number_of_bytes_already_read;
        if ( defined $number_of_bytes_read ) {
            $json .= $buffer;
            $number_of_bytes_already_read += $number_of_bytes_read;
        }
        else {
            Carp::croak(
                "Failed to read from socket to firefox:$EXTENDED_OS_ERROR");
        }
    }
    my $parameters = JSON::decode_json($json);
    return $parameters;
}

sub _socket {
    my ($self) = @_;
    return $self->{_socket};
}

sub _get_response {
    my ( $self, $message_id ) = @_;
    my $next_message = $self->_read_from_socket();
    my $response     = Firefox::Marionette::Response->new($next_message);
    while ( $response->message_id() < $message_id ) {
        $next_message = $self->_read_from_socket();
        $response     = Firefox::Marionette::Response->new($next_message);
    }
    return $response;
}

sub DESTROY {
    my ($self) = @_;
    if ( $self->_socket() ) {
        $self->quit();
    }
    return;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Firefox::Marionette - Automate the Firefox browser with the Marionette protocol

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Firefox::Marionette();
    use v5.10;

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    $firefox->find_element('//input[@id="search-input"]')->send_keys('Test::More');

    my $file_handle = $firefox->selfie(highlights => [ $firefox->find_element('//button[@name="lucky"]') ])

    $firefox->find_element('//button[@name="lucky"]')->click();

    say $firefox->page_source();

=head1 DESCRIPTION

This is a client module to automate the Mozilla Firefox browser via the L<Marionette protocol|https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/Protocol>

=head1 SUBROUTINES/METHODS

=head2 new
 
accepts an optional hash as a parameter.  Allowed keys are below;

=over 4

=item * firefox_binary - use the specified path to the L<Firefox|https://firefox.org/> binary, rather than the default path.

=item * capabilities - use the supplied L<capabilities|Firefox::Marionette::Capabilities> object, for example to set whether the browser should L<accept insecure certs|Firefox::Marionette::Capabilities#accept_insecure_certs>

=item * profile_name - pick a specific existing profile to automate, rather than creating a new profile.  Note that L<firefox|https://firefox.com> refuses to allow more than one instance of a profile to run at the same time.

=back

This method returns a new C<Firefox::Marionette> object, connected to an instance of L<firefox|https://firefox.com>
 
=head2 go

Navigates the current browsing context to the given L<URI|URI> and waits for the document to load or the session's L<page timeout|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods

=head2 uri

returns the current L<URI|URI> of current top level browsing context for Desktop.  It is equivalent to the javascript 'document.location.href'

=head2 title

returns the current title of the window.

=head2 find_element

returns the first element in the current browsing context that matches the search parameters supplied;

=over 4

=item * the first parameter is a scalar search value.  This can be an L<xpath|https://en.wikipedia.org/wiki/XPath> expression such as C<//button[@name="foo"]> to find all button elements that have a 'name' of 'foo'.

=item * the second optional parameter is a scalar search strategy.  This defaults to 'xpath'

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout.

=back

=head2 find_elements

returns the elements in the current browsing context that match the search parameters supplied;

=over 4

=item * the first parameter is a scalar search value.  This can be an L<xpath|https://en.wikipedia.org/wiki/XPath> expression such as C<//button[@name="foo"]> to find all button elements that have a 'name' of 'foo'.

=item * the second optional parameter is a scalar search strategy.  This defaults to 'xpath'

=back

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout.

=head2 css

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a scalar CSS property name as the second parameter.  It returns the value of the computed style for that property.

=head2 attribute 

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a scalar attribute name as the second parameter.  It returns the value of the attribute with the supplied name.

=head2 script 

accepts a scalar containing a javascript function that is executed in the browser.  Returns the result of the javascript function.

The executing javascript is subject to the L<scripts|Firefox::Marionette::Timeouts#scripts> timeout.

=head2 async_script 

accepts a scalar containing a javascript function that is executed in the browser.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

The executing javascript is subject to the L<scripts|Firefox::Marionette::Timeouts#scripts> timeout.

=head2 page_source

returns the page source of the content document.

=head2 context

returns the context type that is Marionette's current target for browsing context scoped commands.

=head2 add_cookie

accepts a single L<cookie|Firefox::Marionette::Cookie> object as the first parameter and adds it to the current cookie jar.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 delete_cookie

deletes a single cookie by name.  Accepts a scalar containing the cookie name as a parameter.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 delete_cookies

here be cookie monsters! This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 cookies

returns the contents of the cookie jar in scalar or list context.

=head2 send_keys

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a string as the second parameter.  It sends the string to the specified L<element|Firefox::Marionette::Element> in the current page, such as filling out a text box. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 is_displayed

accepts an L<element|Firefox::Marionette::Element> as the first parameter.  This method returns true or false depending on if the element is displayed.

=head2 is_enabled

accepts an L<element|Firefox::Marionette::Element> as the first parameter.  This method returns true or false depending on if the element is enabled.

=head2 is_selected

accepts an L<element|Firefox::Marionette::Element> as the first parameter.  This method returns true or false depending on if the element is selected.

=head2 active_element

returns the active element of the current browsing context's document element, if the document element is non-null.

=head2 back

causes the browser to traverse one step backward in the joint history of the current browsing context.  The browser will wait for the one step backward to complete or the session's L<page timeout|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 forward

causes the browser to traverse one step forward in the joint history of the current browsing context. The browser will wait for the one step forward to complete or the session's L<page timeout|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 active_frame

returns the current active L<frame|Firefox::Marionette::Element> if there is one in the current browsing context.  Otherwise, this method returns undef.

=head2 switch_to_frame

accepts a L<frame|Firefox::Marionette::Element> as a parameter and switches to it within the current window.

=head2 switch_to_parent_frame

set the current browsing context for future commands to the parent of the current browsing context

=head2 full_screen

full screens the firefox window. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 minimise

minimises the firefox window. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 maximise

maximises the firefox window. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 refresh

refreshes the current page.  The browser will wait for the page to completely refresh or the session's L<page timeout|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 alert_text

Returns the message shown in a currently displayed modal message box

=head2 dismiss_alert

dismisses a currently displayed modal message box

=head2 accept_dialog

accepts a currently displayed modal message box

=head2 send_alert_text

sends keys to the input field of a currently displayed modal message box

=head2 capabilities

returns the L<capabilities|Firefox::Marionette::Capabilities> of the current firefox binary

=head2 screen_orientation

returns the current browser orientation.  This will be one of the valid primary orientation values 'portrait-primary', 'landscape-primary', 'portrait-secondary', or 'landscape-secondary'.

=head2 selfie

returns a L<File::Temp|File::Temp> object containing a lossless PNG image screenshot.  If an L<element|Firefox::Marionette::Element> is passed as a parameter, the screenshot will be restricted to the element.  

If an L<element|Firefox::Marionette::Element> is not passed as a parameter and the current L<context|Firefox::Marionette#context> is 'chrome', a screenshot of the current viewport will be returned.

If an L<element|Firefox::Marionette::Element> is not passed as a parameter and the current L<context|Firefox::Marionette#context> is 'content', a screenshot of the current frame will be returned.

The parameters after the L<element|Firefox::Marionette::Element> parameter are taken to be a optional hash with the following allowed keys;

=over 4

=item * hash - return a SHA256 hex encoded digest of the PNG image rather than the image itself

=item * full - take a screenshot of the whole document unless the first L<element|Firefox::Marionette::Element> parameter has been supplied.

=item * scroll - scroll to the L<element|Firefox::Marionette::Element> supplied

=item * highlights - a reference to a list containing L<elements|Firefox::Marionette::Element> to draw a highlight around

=back

=head2 tag_name

accepts a L<Firefox::Marionette::Element|Firefox::Marionette::Element> object as the first parameter and returns the relevant tag name.  For example 'a' or 'input'.

=head2 window_rect

accepts an optional <position and size|Firefox::Marionette::Window::Rect> as a parameter, sets the current browser window to that position and size and returns the previous L<position, size and state|Firefox::Marionette::Window::Rect> of the browser window.  If no parameter is supplied, it returns the current  L<position, size and state|Firefox::Marionette::Window::Rect> of the browser window.

=head2 rect

accepts a L<element|Firefox::Marionette::Element> as the first parameter and returns the current L<position and size|Firefox::Marionette::Element::Rect> of the L<element|Firefox::Marionette::Element>

=head2 text

accepts a L<element|Firefox::Marionette::Element> as the first parameter and returns the text that is contained by that element (if any)

=head2 clear

accepts a L<element|Firefox::Marionette::Element> as the first parameter and clears any user supplied input

=head2 click

accepts a L<element|Firefox::Marionette::Element> as the first parameter and sends a 'click' to it.  The browser will wait for any page load to complete or the session's L<page timeout|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning.

=head2 timeouts

returns the current L<timeouts|Firefox::Marionette::Timeouts> for page loading, searching, and scripts.

=head2 new_session

creates a new WebDriver session.  It is expected that the caller performs the necessary checks on the requested capabilities to be WebDriver conforming.  The WebDriver service offered by Marionette does not match or negotiate capabilities beyond type and bounds checks.

=head2 window_type

returns the current window's type.  This should be 'navigator:browser'.

=head2 window_handle

returns the current window's handle. On desktop this typically corresponds to the currently selected tab.  returns an opaque server-assigned identifier to this window that uniquely identifies it within this Marionette instance.  This can be used to switch to this window at a later point.

=head2 window_handles

returns a list of top-level browsing contexts. On desktop this typically corresponds to the set of open tabs for browser windows, or the window itself for non-browser chrome windows.  Each window handle is assigned by the server and is guaranteed unique, however the return array does not have a specified ordering.

=head2 accept_connections

Enables or disables accepting new socket connections.  By calling this method with `false` the server will not accept any further connections, but existing connections will not be forcible closed. Use `true` to re-enable accepting connections.

Please note that when closing the connection via the client you can end-up in a non-recoverable state if it hasn't been enabled before.

=head2 current_chrome_window_handle 

see L<chrome_window_handle|Firefox::Marionette#chrome_window_handle>.

=head2 chrome_window_handle

returns an server-assigned integer identifiers for the current chrome window that uniquely identifies it within this Marionette instance.  This can be used to switch to this window at a later point. This corresponds to a window that may itself contain tabs.

=head2 chrome_window_handles

returns identifiers for each open chrome window for tests interested in managing a set of chrome windows and tabs separately.

=head2 application_type

returns the application type for the Marionette protocol.  Should be 'gecko'.

=head2 marionette_protocol

returns the version for the Marionette protocol.  Current most recent version is '3'.

=head2 quit

Marionette will stop accepting new connections before ending the current session, and finally attempting to quit the application

=head1 DIAGNOSTICS

=over
 
=item C<< Failed to create a socket: %s >>
 
The module was unable to even create a socket.  Something is seriously wrong with your environment
 
=item C<< Failed to send request to firefox: %s >>
 
The module was unable to perform a syswrite on the socket connected to firefox.
 
=item C<< Failed to correctly determined the Firefox process id through the initial connection capabilities >>
 
The module was found that firefox is reporting through it's L<Capabilities|Firefox::Marionette::Capabilities#moz_process_id> object a different process id than this module was using.  This is probably a bug in this module's logic.  Please report as described in the BUGS AND LIMITATIONS section below.
 
=back

=head1 CONFIGURATION AND ENVIRONMENT

Firefox::Marionette requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-firefox-marionette@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Dick  C<< <ddick@cpan.org> >>

=head1 ACKNOWLEDGEMENTS
 
Thanks to the entire Mozilla organisation for a great browser and to the team behind Marionette for providing a great interface for automation.
 
Thanks also to the authors of the documentation in the following sources;

=over 4

=item * L<Marionette Protocol|https://firefox-source-docs.mozilla.org/testing/marionette/marionette/index.html>

=item * L<Marionette Documentation|https://firefox-source-docs.mozilla.org/testing/marionette/marionette/index.html>

=item * L<Marionette driver.js at github|https://github.com/mozilla/gecko-dev/blob/master/testing/marionette/driver.js>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018, David Dick C<< <ddick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic/perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
