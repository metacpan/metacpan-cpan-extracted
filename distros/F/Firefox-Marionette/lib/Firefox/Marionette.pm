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
use Firefox::Marionette::Profile();
use Firefox::Marionette::Proxy();
use Firefox::Marionette::Exception();
use Firefox::Marionette::Exception::Response();
use JSON();
use IPC::Open3();
use Socket();
use English qw( -no_match_vars );
use POSIX();
use File::Spec();
use URI();
use Time::HiRes();
use File::Temp();
use FileHandle();
use MIME::Base64();
use DirHandle();
use Carp();
use Config;
use base qw(Exporter);

BEGIN {
    if ( $OSNAME eq 'MSWin32' ) {
        require Win32;
        require Win32::Process;
    }
}

our @EXPORT_OK =
  qw(BY_XPATH BY_ID BY_NAME BY_TAG BY_CLASS BY_SELECTOR BY_LINK BY_PARTIAL);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.77';

sub _ANYPROCESS                     { return -1 }
sub _COMMAND                        { return 0 }
sub _DEFAULT_HOST                   { return 'localhost' }
sub _MARIONETTE_PROTOCOL_VERSION_3  { return 3 }
sub _WIN32_ERROR_SHARING_VIOLATION  { return 0x20 }
sub _NUMBER_OF_MCOOKIE_BYTES        { return 16 }
sub _MAX_DISPLAY_LENGTH             { return 10 }
sub _NUMBER_OF_TERM_ATTEMPTS        { return 4 }
sub _MAX_VERSION_FOR_ANCIENT_CMDS   { return 31 }
sub _MAX_VERSION_FOR_NEW_CMDS       { return 61 }
sub _MIN_VERSION_FOR_NEW_SENDKEYS   { return 55 }
sub _MIN_VERSION_FOR_HEADLESS       { return 55 }
sub _MIN_VERSION_FOR_WD_HEADLESS    { return 56 }
sub _MIN_VERSION_FOR_SAFE_MODE      { return 55 }
sub _MIN_VERSION_FOR_MODERN_EXIT    { return 40 }
sub _MIN_VERSION_FOR_AUTO_LISTEN    { return 55 }
sub _MIN_VERSION_FOR_HOSTPORT_PROXY { return 57 }
sub _MIN_VERSION_FOR_XVFB           { return 12 }
sub _DEFAULT_SOCKS_VERSION          { return 5 }
sub _MILLISECONDS_IN_ONE_SECOND     { return 1_000 }
sub _DEFAULT_PAGE_LOAD_TIMEOUT      { return 300_000 }
sub _DEFAULT_SCRIPT_TIMEOUT         { return 30_000 }
sub _DEFAULT_IMPLICIT_TIMEOUT       { return 0 }
sub _WIN32_CONNECTION_REFUSED       { return 10_061 }
sub _OLD_PROTOCOL_NAME_INDEX        { return 2 }
sub _OLD_PROTOCOL_PARAMETERS_INDEX  { return 3 }
sub _OLD_INITIAL_PACKET_SIZE        { return 66 }
sub _READ_LENGTH_OF_OPEN3_OUTPUT    { return 50 }

sub BY_XPATH {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_XPATH()) HAS BEEN REPLACED BY find ****'
    );
    return 'xpath';
}

sub BY_ID {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_ID()) HAS BEEN REPLACED BY find_id ****'
    );
    return 'id';
}

sub BY_NAME {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_NAME()) HAS BEEN REPLACED BY find_name ****'
    );
    return 'name';
}

sub BY_TAG {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_TAG()) HAS BEEN REPLACED BY find_tag ****'
    );
    return 'tag name';
}

sub BY_CLASS {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_CLASS()) HAS BEEN REPLACED BY find_class ****'
    );
    return 'class name';
}

sub BY_SELECTOR {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_SELECTOR()) HAS BEEN REPLACED BY find_selector ****'
    );
    return 'css selector';
}

sub BY_LINK {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_LINK()) HAS BEEN REPLACED BY find_link ****'
    );
    return 'link text';
}

sub BY_PARTIAL {
    Carp::carp(
'**** DEPRECATED METHOD - using find(..., BY_PARTIAL()) HAS BEEN REPLACED BY find_partial ****'
    );
    return 'partial link text';
}

sub _download_directory {
    my ($self) = @_;
    my $directory;
    eval {
        my $context = $self->context();
        $self->context('chrome');
        $directory =
          $self->script( 'var branch = Components.classes["' . q[@]
              . 'mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService).getBranch(""); return branch.getStringPref ? branch.getStringPref("browser.download.downloadDir") : branch.getComplexValue("browser.download.downloadDir", Components.interfaces.nsISupportsString).data;'
          );
        $self->context($context);
    } or do {
        chomp $EVAL_ERROR;
        Carp::carp(
"Firefox does not support dynamically determining download directory:$EVAL_ERROR"
        );
        my $profile =
          Firefox::Marionette::Profile->parse(
            File::Spec->catfile( $self->{profile_directory}, 'prefs.js' ) );
        $directory = $profile->get_value('browser.download.downloadDir');
    };
    if ( $OSNAME eq 'cygwin' ) {
        $directory = $self->execute( 'cygpath', '-s', '-m', $directory );
    }
    return $directory;
}

sub mime_types {
    my ($self) = @_;
    return @{ $self->{mime_types} };
}

sub downloading {
    my ($self)    = @_;
    my $directory = $self->_download_directory();
    my $handle    = DirHandle->new($directory)
      or Firefox::Marionette::Exception->throw(
        "Failed to open directory '$directory':$EXTENDED_OS_ERROR");
    my $downloading = 0;
    while ( my $entry = $handle->read() ) {
        next if ( $entry eq File::Spec->updir() );
        next if ( $entry eq File::Spec->curdir() );
        if ( $entry =~ /[.]part$/smx ) {
            $downloading = 1;
            Carp::carp("Waiting for $entry to download");
        }
    }
    $handle->close()
      or Firefox::Marionette::Exception->throw(
        "Failed to close directory '$directory':$EXTENDED_OS_ERROR");
    return $downloading;
}

sub downloads {
    my ($self)    = @_;
    my $directory = $self->_download_directory();
    my $handle    = DirHandle->new($directory)
      or Firefox::Marionette::Exception->throw(
        "Failed to open directory '$directory':$EXTENDED_OS_ERROR");
    my @entries;
    while ( my $entry = $handle->read() ) {
        next if ( $entry eq File::Spec->updir() );
        next if ( $entry eq File::Spec->curdir() );
        push @entries, File::Spec->catfile( $directory, $entry );
    }
    $handle->close()
      or Firefox::Marionette::Exception->throw(
        "Failed to close directory '$directory':$EXTENDED_OS_ERROR");
    return @entries;
}

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless {}, $class;
    $self->{last_message_id}  = 0;
    $self->{creation_pid}     = $PROCESS_ID;
    $self->{sleep_time_in_ms} = $parameters{sleep_time_in_ms};
    $self->{mime_types}       = [
        qw(
          application/x-gzip
          application/gzip
          application/zip
          application/pdf
          application/octet-stream
          application/msword
          application/vnd.openxmlformats-officedocument.wordprocessingml.document
          application/vnd.openxmlformats-officedocument.wordprocessingml.template
          application/vnd.ms-word.document.macroEnabled.12
          application/vnd.ms-word.template.macroEnabled.12
          application/vnd.ms-excel
          application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
          application/vnd.openxmlformats-officedocument.spreadsheetml.template
          application/vnd.ms-excel.sheet.macroEnabled.12
          application/vnd.ms-excel.template.macroEnabled.12
          application/vnd.ms-excel.addin.macroEnabled.12
          application/vnd.ms-excel.sheet.binary.macroEnabled.12
          application/vnd.ms-powerpoint
          application/vnd.openxmlformats-officedocument.presentationml.presentation
          application/vnd.openxmlformats-officedocument.presentationml.template
          application/vnd.openxmlformats-officedocument.presentationml.slideshow
          application/vnd.ms-powerpoint.addin.macroEnabled.12
          application/vnd.ms-powerpoint.presentation.macroEnabled.12
          application/vnd.ms-powerpoint.template.macroEnabled.12
          application/vnd.ms-powerpoint.slideshow.macroEnabled.12
          application/vnd.ms-access
          )
    ];
    my %known_mime_types;
    foreach my $mime_type ( @{ $self->{mime_types} } ) {
        $known_mime_types{$mime_type} = 1;
    }
    foreach my $mime_type ( @{ $parameters{mime_types} } ) {
        if ( !$known_mime_types{$mime_type} ) {
            push @{ $self->{mime_types} }, $mime_type;
            $known_mime_types{$mime_type} = 1;
        }
    }
    my @arguments = $self->_setup_arguments(%parameters);
    $self->{_pid} = $self->_launch(@arguments);
    my $socket = $self->_setup_local_connection_to_firefox(@arguments);
    my ( $session_id, $capabilities ) =
      $self->_initial_socket_setup( $socket, $parameters{capabilities} );

    if ( ($session_id) && ($capabilities) && ( ref $capabilities ) ) {
    }
    elsif (( $self->marionette_protocol() <= _MARIONETTE_PROTOCOL_VERSION_3() )
        && ($capabilities)
        && ( ref $capabilities ) )
    {
    }
    else {
        Firefox::Marionette::Exception->throw(
            'Failed to correctly setup the Firefox process');
    }
    if ( $OSNAME eq 'cygwin' ) {
    }
    elsif ( $self->marionette_protocol() <= _MARIONETTE_PROTOCOL_VERSION_3() ) {
    }
    elsif ( $self->_pid() != $capabilities->moz_process_id() ) {
        Firefox::Marionette::Exception->throw(
'Failed to correctly determine the Firefox process id through the initial connection capabilities'
        );
    }
    $self->_check_timeout_parameters(%parameters);
    return $self;
}

sub _check_timeout_parameters {
    my ( $self, %parameters ) = @_;
    if (   ( defined $parameters{implicit} )
        || ( defined $parameters{page_load} )
        || ( defined $parameters{script} ) )
    {
        my $page_load =
          defined $parameters{page_load}
          ? $parameters{page_load}
          : _DEFAULT_PAGE_LOAD_TIMEOUT();
        my $script =
          defined $parameters{script}
          ? $parameters{script}
          : _DEFAULT_SCRIPT_TIMEOUT();
        my $implicit =
          defined $parameters{implicit}
          ? $parameters{implicit}
          : _DEFAULT_IMPLICIT_TIMEOUT();
        $self->timeouts(
            Firefox::Marionette::Timeouts->new(
                page_load => $page_load,
                script    => $script,
                implicit  => $implicit,
            )
        );
    }
    elsif ( $parameters{timeouts} ) {
        $self->timeouts( $parameters{timeouts} );
    }
    return;
}

sub _check_addons {
    my ( $self, %parameters ) = @_;
    $self->{addons} = 1;
    my @arguments = ();
    if ( !$parameters{addons} ) {
        if ( $self->_is_safe_mode_okay() ) {
            push @arguments, '-safe-mode';
            $self->{addons} = 0;
        }
    }
    return @arguments;
}

sub _check_visible {
    my ( $self, %parameters ) = @_;
    my @arguments = ();
    if (   ( defined $parameters{capabilities} )
        && ( !$parameters{capabilities}->moz_headless() ) )
    {
        if ( !$parameters{visible} ) {
            Carp::carp('Unable to launch firefox with -headless option');
        }
        $self->{visible} = 1;
    }
    elsif ( $parameters{visible} ) {
        $self->{visible} = 1;
    }
    else {
        if ( $self->_is_headless_okay() ) {
            push @arguments, '-headless';
            $self->{visible} = 0;
        }
        elsif (( $OSNAME eq 'MSWin32' )
            || ( $OSNAME eq 'darwin' )
            || ( $OSNAME eq 'cygwin' ) )
        {
        }
        else {
            if (   $self->_is_xvfb_okay()
                && $self->_xvfb_exists()
                && $self->_launch_xvfb() )
            {
                $self->{_launched_xvfb_anyway} = 1;
                $self->{visible}               = 0;
            }
            else {
                Carp::carp('Unable to launch firefox with -headless option');
                $self->{visible} = 1;
            }
        }
    }
    $self->_launch_xvfb_if_required();
    return @arguments;
}

sub _launch_xvfb_if_required {
    my ($self) = @_;
    if ( $self->{visible} ) {
        if (   ( $OSNAME eq 'MSWin32' )
            || ( $OSNAME eq 'darwin' )
            || ( $OSNAME eq 'cygwin' )
            || ( $ENV{DISPLAY} )
            || ( $self->{_launched_xvfb_anyway} ) )
        {
        }
        elsif ( $self->_xvfb_exists() && $self->_launch_xvfb() ) {
            $self->{_launched_xvfb_anyway} = 1;
        }
    }
    return;
}

sub _setup_arguments {
    my ( $self, %parameters ) = @_;
    my @arguments = qw(-marionette);

    if ( $parameters{firefox_binary} ) {
        $self->{firefox_binary} = $parameters{firefox_binary};
    }
    push @arguments, $self->_check_addons(%parameters);

    $self->{debug} = $parameters{debug};
    push @arguments, $self->_check_visible(%parameters);
    if ( $parameters{profile_name} ) {
        $self->{profile_name} = $parameters{profile_name};
        push @arguments, ( '-P', $self->{profile_name} );
    }
    else {
        my $profile_directory =
          $self->_setup_new_profile( $parameters{profile} );
        if ( $OSNAME eq 'cygwin' ) {
            $profile_directory =
              $self->execute( 'cygpath', '-s', '-m', $profile_directory );
        }
        my $path = File::Spec->catfile( $profile_directory, 'mimeTypes.rdf' );
        my $handle =
          FileHandle->new( $path,
            Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL() )
          or Firefox::Marionette::Exception->throw(
            "Failed to open '$path' for writing:$EXTENDED_OS_ERROR");
        $handle->print(
            <<'_RDF_') or Firefox::Marionette::Exception->throw("Failed to write to '$path':$EXTENDED_OS_ERROR");
<?xml version="1.0"?>
<RDF:RDF xmlns:NC="http://home.netscape.com/NC-rdf#"
         xmlns:RDF="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <RDF:Seq RDF:about="urn:mimetypes:root">
_RDF_
        foreach my $mime_type ( @{ $self->{mime_types} } ) {
            $handle->print(
                <<"_RDF_") or Firefox::Marionette::Exception->throw("Failed to write to '$path':$EXTENDED_OS_ERROR");
    <RDF:li RDF:resource="urn:mimetype:$mime_type"/>
_RDF_
        }
        $handle->print(
            <<'_RDF_') or Firefox::Marionette::Exception->throw("Failed to write to '$path':$EXTENDED_OS_ERROR");
  </RDF:Seq>
  <RDF:Description RDF:about="urn:root"
                   NC:en-US_defaultHandlersVersion="4" />
  <RDF:Description RDF:about="urn:mimetypes">
    <NC:MIME-types RDF:resource="urn:mimetypes:root"/>
  </RDF:Description>
_RDF_
        foreach my $mime_type ( @{ $self->{mime_types} } ) {
            $handle->print(
                <<"_RDF_") or Firefox::Marionette::Exception->throw("Failed to write to '$path':$EXTENDED_OS_ERROR");
  <RDF:Description RDF:about="urn:mimetype:handler:$mime_type"
                   NC:saveToDisk="true"
                   NC:alwaysAsk="false" />
  <RDF:Description RDF:about="urn:mimetype:$mime_type"
                   NC:value="$mime_type">
    <NC:handlerProp RDF:resource="urn:mimetype:handler:$mime_type"/>
  </RDF:Description>
_RDF_
        }
        $handle->print(
            <<'_RDF_') or Firefox::Marionette::Exception->throw("Failed to write to '$path':$EXTENDED_OS_ERROR");
</RDF:RDF>
_RDF_
        $handle->close
          or Firefox::Marionette::Exception->throw(
            "Failed to close '$path':$EXTENDED_OS_ERROR");
        push @arguments,
          ( '-profile', $profile_directory, '--no-remote', '--new-instance' );
    }
    return @arguments;
}

sub _is_xvfb_okay {
    my ($self) = @_;
    $self->_initialise_version();
    if (   ( $self->{_initial_version}->{major} )
        && ( $self->{_initial_version}->{major} < _MIN_VERSION_FOR_XVFB() ) )
    {
        return 0;
    }
    else {
        return 1;
    }
}

sub _is_new_hostport_okay {
    my ($self) = @_;
    $self->_initialise_version();
    if (
        ( $self->{_initial_version}->{major} )
        && ( $self->{_initial_version}->{major} <
            _MIN_VERSION_FOR_HOSTPORT_PROXY() )
      )
    {
        return 0;
    }
    else {
        return 1;
    }
}

sub _is_new_sendkeys_okay {
    my ($self) = @_;
    $self->_initialise_version();
    if (
        ( $self->{_initial_version}->{major} )
        && ( $self->{_initial_version}->{major} <
            _MIN_VERSION_FOR_NEW_SENDKEYS() )
      )
    {
        return 0;
    }
    else {
        return 1;
    }
}

sub _is_safe_mode_okay {
    my ($self) = @_;
    $self->_initialise_version();
    if (   ( $self->{_initial_version}->{major} )
        && ( $self->{_initial_version}->{major} < _MIN_VERSION_FOR_SAFE_MODE() )
      )
    {
        return 0;
    }
    else {
        return 1;
    }
}

sub _is_headless_okay {
    my ($self) = @_;
    $self->_initialise_version();
    my $min_version = _MIN_VERSION_FOR_HEADLESS();
    if ( ( $OSNAME eq 'MSWin32' ) || ( $OSNAME eq 'darwin' ) ) {
        $min_version = _MIN_VERSION_FOR_WD_HEADLESS();
    }
    if (   ( $self->{_initial_version}->{major} )
        && ( $self->{_initial_version}->{major} < $min_version ) )
    {
        return 0;
    }
    else {
        return 1;
    }
}

sub _is_auto_listen_okay {
    my ($self) = @_;
    $self->_initialise_version();
    if ( ( $self->{_initial_version}->{major} )
        && ( $self->{_initial_version}->{major} <
            _MIN_VERSION_FOR_AUTO_LISTEN() ) )
    {
        return 0;
    }
    else {
        return 1;
    }
}

sub execute {
    my ( $proto, $binary, @arguments ) = @_;
    my ( $writer, $reader, $error );
    my $pid;
    eval {
        $pid =
          IPC::Open3::open3( $writer, $reader, $error, $binary, @arguments );
    } or do {
        Carp::croak("Failed to execute '$binary':$EXTENDED_OS_ERROR");
    };
    waitpid $pid, 0;
    if ( $CHILD_ERROR == 0 ) {
        my ( $result, $output );
        while ( $result = read $reader, my $buffer,
            _READ_LENGTH_OF_OPEN3_OUTPUT() )
        {
            $output .= $buffer;
        }
        defined $result
          or Carp::croak( q[Failed to read STDOUT from ']
              . ( join q[ ], $binary, @arguments )
              . "':$EXTENDED_OS_ERROR" );
        chomp $output;
        return $output;
    }
    else {
        Carp::croak( q[Failed to execute ']
              . ( join q[ ], $binary, @arguments ) . q[':]
              . $proto->_error_message( $binary, $CHILD_ERROR ) );
    }
    return;
}

sub _initialise_version {
    my ($self) = @_;
    if ( defined $self->{_initial_version} ) {
    }
    else {
        my $binary         = $self->_binary();
        my $version_string = $self->execute( $binary, '--version' );
        if ( $version_string =~
            /Mozilla[ ]Firefox[ ](\d+)[.](\d+)(?:[.](\d+))?\s*$/smx )

# not anchoring the start of the regex b/c of issues with
# RHEL6 and dbus crashing with error messages like
# 'Failed to open connection to "session" message bus: /bin/dbus-launch terminated abnormally without any error message'
        {
            $self->{_initial_version}->{major} = $1;
            $self->{_initial_version}->{minor} = $2;
            $self->{_initial_version}->{patch} = $3;
        }
        else {
            Firefox::Marionette::Exception->throw(
"'$binary --version' did not produce output that looks like 'Mozilla Firefox \\d+[.]\\d+([.]\\d+)?':$version_string"
            );
        }
    }
    return;
}

sub _debug {
    my ($self) = @_;
    return $self->{debug};
}

sub _visible {
    my ($self) = @_;
    return $self->{visible};
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
    elsif (( $OSNAME ne 'darwin' )
        && ( $OSNAME ne 'cygwin' )
        && ( $self->_visible() )
        && ( !$ENV{DISPLAY} )
        && ( !$self->{_launched_xvfb_anyway} )
        && ( $self->_xvfb_exists() )
        && ( $self->_launch_xvfb() ) )
    { # if not MacOS or Win32 and no DISPLAY variable, launch Xvfb if at all possible
        local $ENV{DISPLAY}    = $self->_xvfb_display();
        local $ENV{XAUTHORITY} = $self->_xvfb_xauthority();
        return $self->_launch_unix(@arguments);
    }
    elsif ( $self->{_launched_xvfb_anyway} ) {
        local $ENV{DISPLAY}    = $self->_xvfb_display();
        local $ENV{XAUTHORITY} = $self->_xvfb_xauthority();
        return $self->_launch_unix(@arguments);
    }
    else {
        return $self->_launch_unix(@arguments);
    }
}

sub _launch_win32 {
    my ( $self, @arguments ) = @_;
    my $binary = $self->_binary();
    my ( $volume, $path, $name ) = File::Spec->splitpath($binary);
    my $result =
      Win32::Process::Create( my $process, $binary,
        $name . q[ ] . ( join q[ ], map { q["] . $_ . q["] } @arguments ),
        0, Win32::Process::NORMAL_PRIORITY_CLASS(), q[.] );
    if ( !$result ) {
        my $error = Win32::FormatMessage( Win32::GetLastError() );
        $error =~ s/[\r\n]//smxg;
        $error =~ s/[.]$//smxg;
        chomp $error;
        Firefox::Marionette::Exception->throw(
            "Failed to create process from '$binary':$error");
    }
    $self->{_win32_process} = $process;
    return $process->GetProcessID();
}

sub _xvfb_binary {
    return 'Xvfb';
}

sub _dev_fd_works {
    my ($self) = @_;
    my $test_handle =
      File::Temp::tempfile( File::Spec->tmpdir(),
        'firefox_marionette_dev_fd_test_XXXXXXXXXXX' )
      or Firefox::Marionette::Exception->throw(
        "Failed to open temporary file for writing:$EXTENDED_OS_ERROR");
    my @stats = stat '/dev/fd/' . fileno $test_handle;
    if ( scalar @stats ) {
        return 1;
    }
    elsif ( $OSNAME eq 'freebsd' ) {
        Carp::carp(
q[/dev/fd is not working.  Perhaps you need to mount fdescfs like so 'sudo mount -t fdescfs fdesc /dev/fd']
        );
    }
    else {
        Carp::carp("/dev/fd is not working for $OSNAME");
    }
    return 0;
}

sub _xvfb_exists {
    my ($self)   = @_;
    my $binary   = $self->_xvfb_binary();
    my $dev_null = File::Spec->devnull();
    if ( !$self->_dev_fd_works() ) {
        return 0;
    }
    eval { require Crypt::URandom; } or do {
        Carp::carp('Unable to load Crypt::URandom');
        return 0;
    };
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        if ( $CHILD_ERROR == 0 ) {
            return 1;
        }
    }
    elsif ( defined $pid ) {
        eval {
            open STDERR, q[>], $dev_null
              or Firefox::Marionette::Exception->throw(
                "Failed to redirect STDERR to $dev_null:$EXTENDED_OS_ERROR");
            open STDOUT, q[>], $dev_null
              or Firefox::Marionette::Exception->throw(
                "Failed to redirect STDOUT to $dev_null:$EXTENDED_OS_ERROR");
            exec {$binary} $binary, '-help'
              or Firefox::Marionette::Exception->throw(
                "Failed to exec '$binary':$EXTENDED_OS_ERROR");
        } or do {
            if ( $self->_debug() ) {
                chomp $EVAL_ERROR;
                warn "$EVAL_ERROR\n";
            }
        };
        exit 1;
    }
    else {
        Firefox::Marionette::Exception->throw(
            "Failed to fork:$EXTENDED_OS_ERROR");
    }
    return;
}

sub xvfb {
    my ($self) = @_;
    return $self->{_xvfb_pid};
}

sub _launch_xauth {
    my ( $self, $display_number ) = @_;
    my $auth_handle =
      FileHandle->new( $ENV{XAUTHORITY},
        Fcntl::O_CREAT() | Fcntl::O_WRONLY() | Fcntl::O_EXCL(),
        Fcntl::S_IRWXU() )
      or Firefox::Marionette::Exception->throw(
        "Failed to open '$ENV{XAUTHORITY}' for writing:$EXTENDED_OS_ERROR");
    $auth_handle->close()
      or Firefox::Marionette::Exception->throw(
        "Failed to close '$ENV{XAUTHORITY}':$EXTENDED_OS_ERROR");
    my $mcookie = unpack 'H*',
      Crypt::URandom::urandom( _NUMBER_OF_MCOOKIE_BYTES() );
    my $source_handle =
      File::Temp::tempfile( File::Spec->tmpdir(),
        'firefox_marionette_xauth_source_XXXXXXXXXXX' )
      or Firefox::Marionette::Exception->throw(
        "Failed to open temporary file for writing:$EXTENDED_OS_ERROR");
    fcntl $source_handle, Fcntl::F_SETFD(), 0
      or Firefox::Marionette::Exception->throw(
"Failed to clear the close-on-exec flag on a temporary file:$EXTENDED_OS_ERROR"
      );
    my $xauth_proto = q[.];
    $source_handle->print("add :$display_number $xauth_proto $mcookie\n");
    seek $source_handle, 0, Fcntl::SEEK_SET()
      or Firefox::Marionette::Exception->throw(
        "Failed to seek to start of temporary file:$EXTENDED_OS_ERROR");
    my $dev_null  = File::Spec->devnull();
    my $binary    = 'xauth';
    my @arguments = ( 'source', '/dev/fd/' . fileno $source_handle );

    if ( my $pid = fork ) {
        waitpid $pid, 0;
        if ( $CHILD_ERROR == 0 ) {
            close $source_handle
              or Firefox::Marionette::Exception->throw(
                "Failed to close temporary file:$EXTENDED_OS_ERROR");
            return 1;
        }
    }
    elsif ( defined $pid ) {
        eval {
            if ( !$self->_debug() ) {
                open STDERR, q[>], $dev_null
                  or Firefox::Marionette::Exception->throw(
                    "Failed to redirect STDERR to $dev_null:$EXTENDED_OS_ERROR"
                  );
                open STDOUT, q[>], $dev_null
                  or Firefox::Marionette::Exception->throw(
                    "Failed to redirect STDOUT to $dev_null:$EXTENDED_OS_ERROR"
                  );
            }
            exec {$binary} $binary, @arguments
              or Firefox::Marionette::Exception->throw(
                "Failed to exec '$binary':$EXTENDED_OS_ERROR");
        } or do {
            if ( $self->_debug() ) {
                chomp $EVAL_ERROR;
                warn "$EVAL_ERROR\n";
            }
        };
        exit 1;
    }
    else {
        Firefox::Marionette::Exception->throw(
            "Failed to fork:$EXTENDED_OS_ERROR");
    }
    return;
}

sub _xvfb_display {
    my ($self) = @_;
    return ":$self->{_xvfb_display_number}";
}

sub _xvfb_xauthority {
    my ($self) = @_;
    return File::Spec->catfile( $self->{_xvfb_authority_directory}->dirname(),
        'Xauthority' );
}

sub _launch_xvfb {
    my ($self) = @_;
    $self->{_xvfb_fbdir_directory} = File::Temp->newdir(
        File::Spec->catdir(
            File::Spec->tmpdir(), 'firefox_marionette_xvfb_fbdir_XXXXXXXXXXX'
        )
      )
      or Firefox::Marionette::Exception->throw(
        "Failed to create temporary directory:$EXTENDED_OS_ERROR");
    my $display_no_handle =
      File::Temp::tempfile( File::Spec->tmpdir(),
        'firefox_marionette_xvfb_display_XXXXXXXXXXX' )
      or Firefox::Marionette::Exception->throw(
        "Failed to open temporary file for writing:$EXTENDED_OS_ERROR");
    fcntl $display_no_handle, Fcntl::F_SETFD(), 0
      or Firefox::Marionette::Exception->throw(
"Failed to clear the close-on-exec flag on a temporary file:$EXTENDED_OS_ERROR"
      );
    my @arguments = (
        '-displayfd',  fileno $display_no_handle,
        '-screen',     '0',
        '1024x768x24', '-nolisten',
        'tcp',         '-fbdir',
        $self->{_xvfb_fbdir_directory}->dirname(),
    );
    my $binary   = $self->_xvfb_binary();
    my $dev_null = File::Spec->devnull();

    if ( my $pid = fork ) {
        $self->{_xvfb_pid} = $pid;
        my $display_number =
          $self->_wait_for_display_number( $pid, $display_no_handle );
        if ( !defined $display_number ) {
            return;
        }
        $self->{_xvfb_display_number} = $display_number;
        close $display_no_handle
          or Firefox::Marionette::Exception->throw(
            "Failed to close temporary file:$EXTENDED_OS_ERROR");
        $self->{_xvfb_authority_directory} = File::Temp->newdir(
            File::Spec->catdir(
                File::Spec->tmpdir(),
                'firefox_marionette_xvfb_auth_XXXXXXXXXXX'
            )
          )
          or Firefox::Marionette::Exception->throw(
            "Failed to create temporary directory:$EXTENDED_OS_ERROR");
        local $ENV{DISPLAY}    = $self->_xvfb_display();
        local $ENV{XAUTHORITY} = $self->_xvfb_xauthority();
        if ( $self->_launch_xauth($display_number) ) {
            return 1;
        }
    }
    elsif ( defined $pid ) {
        eval {
            if ( !$self->_debug() ) {
                open STDERR, q[>], $dev_null
                  or Firefox::Marionette::Exception->throw(
                    "Failed to redirect STDERR to $dev_null:$EXTENDED_OS_ERROR"
                  );
                open STDOUT, q[>], $dev_null
                  or Firefox::Marionette::Exception->throw(
                    "Failed to redirect STDOUT to $dev_null:$EXTENDED_OS_ERROR"
                  );
            }
            exec {$binary} $binary, @arguments
              or Firefox::Marionette::Exception->throw(
                "Failed to exec '$binary':$EXTENDED_OS_ERROR");
        } or do {
            if ( $self->_debug() ) {
                chomp $EVAL_ERROR;
                warn "$EVAL_ERROR\n";
            }
        };
        exit 1;
    }
    else {
        Firefox::Marionette::Exception->throw(
            "Failed to fork:$EXTENDED_OS_ERROR");
    }
    return;
}

sub _wait_for_display_number {
    my ( $self, $pid, $display_no_handle ) = @_;
    my $display_number = [];
    while ( $display_number !~ /^\d+$/smx ) {
        seek $display_no_handle, 0, Fcntl::SEEK_SET()
          or Firefox::Marionette::Exception->throw(
            "Failed to seek to start of temporary file:$EXTENDED_OS_ERROR");
        defined sysread $display_no_handle, $display_number,
          _MAX_DISPLAY_LENGTH()
          or Firefox::Marionette::Exception->throw(
            "Failed to read from temporary file:$EXTENDED_OS_ERROR");
        chomp $display_number;
        if ( $display_number !~ /^\d+$/smx ) {
            sleep 1;
        }
        waitpid $pid, POSIX::WNOHANG();
        if ( !kill 0, $pid ) {
            Carp::carp('Xvfb has crashed before sending a display number');
            return;
        }
        else {
            sleep 1;
        }
    }
    return $display_number;
}

sub _launch_unix {
    my ( $self, @arguments ) = @_;
    my $binary = $self->_binary();
    my $pid;
    if ( $OSNAME eq 'cygwin' ) {
        eval {
            $pid =
              IPC::Open3::open3( my $writer, my $reader, my $error, $binary,
                @arguments );
        } or do {
            Firefox::Marionette::Exception->throw(
                "Failed to exec '$binary':$EXTENDED_OS_ERROR");
        };
    }
    else {
        my $dev_null = File::Spec->devnull();
        if ( $pid = fork ) {
        }
        elsif ( defined $pid ) {
            eval {
                if ( !$self->_debug() ) {
                    open STDERR, q[>], $dev_null
                      or Firefox::Marionette::Exception->throw(
"Failed to redirect STDERR to $dev_null:$EXTENDED_OS_ERROR"
                      );
                    open STDOUT, q[>], $dev_null
                      or Firefox::Marionette::Exception->throw(
"Failed to redirect STDOUT to $dev_null:$EXTENDED_OS_ERROR"
                      );
                }
                exec {$binary} $binary, @arguments
                  or Firefox::Marionette::Exception->throw(
                    "Failed to exec '$binary':$EXTENDED_OS_ERROR");
            } or do {
                if ( $self->_debug() ) {
                    chomp $EVAL_ERROR;
                    warn "$EVAL_ERROR\n";
                }
            };
            exit 1;
        }
        else {
            Firefox::Marionette::Exception->throw(
                "Failed to fork:$EXTENDED_OS_ERROR");
        }
    }
    return $pid;
}

sub _binary {
    my ($self) = @_;
    my $binary = 'firefox';
    if ( $self->{firefox_binary} ) {
        $binary = $self->{firefox_binary};
    }
    else {
        if ( $OSNAME eq 'MSWin32' ) {
          SEARCH:
            foreach my $possible ( 'ProgramFiles', 'ProgramFiles(x86)' ) {
                if (
                    ( $ENV{$possible} )
                    && (
                        -e File::Spec->catfile(
                            $ENV{$possible}, 'Mozilla Firefox',
                            'firefox.exe'
                        )
                    )
                  )
                {
                    $binary =
                      File::Spec->catfile( $ENV{$possible}, 'Mozilla Firefox',
                        'firefox.exe' );
                    last;
                }
            }
        }
        elsif ( $OSNAME eq 'darwin' ) {
            $binary = '/Applications/Firefox.app/Contents/MacOS/firefox';
        }
        elsif ( $OSNAME eq 'cygwin' ) {
            my $windows_x86_firefox_path =
              "$ENV{PROGRAMFILES} (x86)/Mozilla Firefox/firefox.exe";
            my $windows_firefox_path =
              "$ENV{PROGRAMFILES}/Mozilla Firefox/firefox.exe";
            if ( -e $windows_x86_firefox_path ) {
                $binary = $windows_x86_firefox_path;
            }
            elsif ( -e $windows_firefox_path ) {
                $binary = $windows_firefox_path;
            }
            $binary = $self->execute( 'cygpath', '-s', '-m', $binary );
        }
    }
    return $binary;
}

sub child_error {
    my ($self) = @_;
    return $self->{_child_error};
}

sub _signal_name {
    my ( $self, $number ) = @_;
    my @sig_names = split q[ ], $Config{sig_name};
    return $sig_names[$number];
}

sub error_message {
    my ($self) = @_;
    return $self->_error_message( 'Firefox', $self->child_error() );
}

sub _error_message {
    my ( $self, $binary, $child_error ) = @_;
    my $message;
    if ( !defined $child_error ) {
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
        $message = Win32::FormatMessage( Win32::GetLastError() );
    }
    else {

        if (   ( POSIX::WIFEXITED($child_error) )
            || ( POSIX::WIFSIGNALED($child_error) ) )
        {
            if ( POSIX::WIFEXITED($child_error) ) {
                $message =
                    $binary
                  . ' exited with a '
                  . POSIX::WEXITSTATUS($child_error);
            }
            elsif ( POSIX::WIFSIGNALED($child_error) ) {
                my $name = $self->_signal_name( POSIX::WTERMSIG($child_error) );
                if ( defined $name ) {
                    $message = "$binary killed by a $name signal ("
                      . POSIX::WTERMSIG($child_error) . q[)];
                }
                else {
                    $message =
                        $binary
                      . ' killed by a signal ('
                      . POSIX::WTERMSIG($child_error) . q[)];
                }
            }
        }
    }
    return $message;
}

sub _reap {
    my ($self) = @_;
    if ( $OSNAME eq 'MSWin32' ) {
        if ( $self->{_win32_process} ) {
            $self->{_win32_process}->GetExitCode( my $exit_code );
            if ( $exit_code != Win32::Process::STILL_ACTIVE() ) {
                $self->{_child_error} = $exit_code;
            }
        }
    }
    else {
        while ( ( my $pid = waitpid _ANYPROCESS(), POSIX::WNOHANG() ) > 0 ) {
            if ( ( $self->_pid() ) && ( $pid == $self->_pid() ) ) {
                $self->{_child_error} = $CHILD_ERROR;
            }
            elsif ( ( $self->xvfb() ) && ( $pid == $self->xvfb() ) ) {
                $self->{_xvfb_child_error} = $CHILD_ERROR;
            }
        }
    }
    return;
}

sub alive {
    my ($self) = @_;
    if ( $OSNAME eq 'MSWin32' ) {
        if ( $self->{_win32_process} ) {
            $self->{_win32_process}->GetExitCode( my $exit_code );
            $self->_reap();
            if ( $exit_code == Win32::Process::STILL_ACTIVE() ) {
                return 1;
            }
        }
        return 0;
    }
    elsif ( $self->_pid() ) {
        $self->_reap();
        return kill 0, $self->_pid();
    }
    else {
        return;
    }
}

sub _setup_local_connection_to_firefox {
    my ( $self, @arguments ) = @_;
    my $host = _DEFAULT_HOST();
    my $port;
    my $socket;
    my $connected;
    while ( ( !$connected ) && ( $self->alive() ) ) {
        $socket = undef;
        socket $socket, Socket::PF_INET(), Socket::SOCK_STREAM(), 0
          or Firefox::Marionette::Exception->throw(
            "Failed to create a socket:$EXTENDED_OS_ERROR");
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
        elsif (( $OSNAME eq 'MSWin32' )
            && ( $EXTENDED_OS_ERROR == _WIN32_CONNECTION_REFUSED() ) )
        {
            sleep 1;
        }
        else {
            Firefox::Marionette::Exception->throw(
                "Failed to connect to $host on port $port:$EXTENDED_OS_ERROR");
        }
    }
    $self->_reap();
    if ( ( $self->alive() ) && ($socket) ) {
    }
    else {
        my $error_message =
          $self->error_message() ? $self->error_message() : q[];
        Firefox::Marionette::Exception->throw($error_message);
    }
    return $socket;
}

sub _setup_new_profile {
    my ( $self, $profile ) = @_;
    $self->{profile_directory} = File::Temp->newdir(
        File::Spec->catdir(
            File::Spec->tmpdir(), 'firefox_marionette_profile_XXXXXXXXXXX'
        )
      )
      or Firefox::Marionette::Exception->throw(
        "Failed to create temporary directory:$EXTENDED_OS_ERROR");
    my $profile_path =
      File::Spec->catfile( $self->{profile_directory}, 'prefs.js' );
    $self->{profile_path} = $profile_path;
    if ($profile) {
    }
    else {
        $profile = Firefox::Marionette::Profile->new();
    }
    my $mime_types = join q[,], $self->mime_types();
    $profile->set_value( 'browser.helperApps.neverAsk.saveToDisk',
        $mime_types );
    if ( !$self->_is_auto_listen_okay() ) {
        socket my $socket, Socket::PF_INET(), Socket::SOCK_STREAM(), 0
          or Firefox::Marionette::Exception->throw(
            "Failed to create a socket:$EXTENDED_OS_ERROR");
        bind $socket, Socket::sockaddr_in( 0, Socket::INADDR_LOOPBACK() )
          or Firefox::Marionette::Exception->throw(
            "Failed to bind socket:$EXTENDED_OS_ERROR");
        my $port = ( Socket::sockaddr_in( getsockname $socket ) )[0];
        close $socket
          or Firefox::Marionette::Exception->throw(
            "Failed to close random socket:$EXTENDED_OS_ERROR");
        $profile->set_value( 'marionette.defaultPrefs.port', $port );
        $profile->set_value( 'marionette.port',              $port );
    }
    $profile->save($profile_path);
    return $self->{profile_directory};
}

sub _get_port {
    my ($self) = @_;
    my $port;
    my $profile_handle =
      FileHandle->new( $self->{profile_path}, Fcntl::O_RDONLY() )
      or ( ( $OSNAME eq 'MSWin32' )
        && ( $EXTENDED_OS_ERROR == _WIN32_ERROR_SHARING_VIOLATION() ) )
      or Firefox::Marionette::Exception->throw(
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
          or Firefox::Marionette::Exception->throw(
            "Failed to close '$self->{profile_path}':$EXTENDED_OS_ERROR");
    }
    return $port;
}

sub _initial_socket_setup {
    my ( $self, $socket, $capabilities ) = @_;
    $self->{_socket} = $socket;
    my $initial_response = $self->_read_from_socket();
    $self->{marionette_protocol} = $initial_response->{marionetteProtocol};
    $self->{application_type}    = $initial_response->{applicationType};
    if ( !$self->marionette_protocol() ) {
        if ( $self->{_initial_packet_size} == _OLD_INITIAL_PACKET_SIZE() ) {
            $self->{_old_protocols_key} = 'type';
        }
        else {
            $self->{_old_protocols_key} = 'name';
        }
        my $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(), $message_id, 'getMarionetteID', 'to' => 'root'
            ]
        );
        my $next_message = $self->_read_from_socket();
        $self->{marionette_id} = $next_message->{id};
    }
    return $self->new_session($capabilities);
}

sub _request_proxy {
    my ( $self, $proxy ) = @_;
    my $build = {};
    if ( $proxy->type() ) {
        $build->{proxyType} = $proxy->type();
    }
    elsif ( $proxy->pac() ) {
        $build->{proxyType} = 'pac';
    }
    if ( $proxy->pac() ) {
        $build->{proxyAutoconfigUrl} = $proxy->pac()->as_string();
    }
    if ( $proxy->ftp() ) {
        $build->{proxyType} ||= 'manual';
        $build->{ftpProxy} = $proxy->ftp();
    }
    if ( $proxy->http() ) {
        $build->{proxyType} ||= 'manual';
        $build->{httpProxy} = $proxy->http();
    }
    if ( $proxy->none() ) {
        $build->{proxyType} ||= 'manual';
        $build->{noProxy} = [ $proxy->none() ];
    }
    if ( $proxy->https() ) {
        $build->{proxyType} ||= 'manual';
        $build->{sslProxy} = $proxy->https();
    }
    if ( $proxy->socks() ) {
        $build->{proxyType} ||= 'manual';
        $build->{socksProxy} = $proxy->socks();
    }
    if ( $proxy->socks_version() ) {
        $build->{proxyType} ||= 'manual';
        $build->{socksProxyVersion} = $build->{socksVersion} =
          $proxy->socks_version() + 0;
    }
    elsif ( $proxy->socks() ) {
        $build->{proxyType} ||= 'manual';
        $build->{socksProxyVersion} = $build->{socksVersion} =
          _DEFAULT_SOCKS_VERSION();
    }
    return $self->_convert_proxy_before_request($build);
}

sub _convert_proxy_before_request {
    my ( $self, $build ) = @_;
    if ( defined $build ) {
        foreach my $key (qw(ftpProxy socksProxy sslProxy httpProxy)) {
            if ( defined $build->{$key} ) {
                if ( !$self->_is_new_hostport_okay() ) {
                    if ( $build->{$key} =~ s/:(\d+)$//smx ) {
                        $build->{ $key . 'Port' } = $1 + 0;
                    }
                }
            }
        }
    }
    return $build;
}

sub _proxy_from_env {
    my ($self) = @_;
    my $build;
    foreach my $key (qw(ftp all https http)) {
        my $full_name = $key . '_proxy';
        if ( $ENV{$full_name} ) {
        }
        elsif ( $ENV{ uc $full_name } ) {
            $full_name = uc $full_name;
        }
        if ( $ENV{$full_name} ) {
            $build->{proxyType} = 'manual';
            my $value = $ENV{$full_name};
            if ( $value !~ /^\w+:\/\//smx ) { # add an http scheme if none exist
                $value = 'http://' . $value;
            }
            my $uri       = URI->new($value);
            my $build_key = $key;
            if ( $key eq 'https' ) {
                $build_key = 'ssl';
            }
            $build->{ $build_key . 'Proxy' } = $uri->host_port();
        }
    }
    return $self->_convert_proxy_before_request($build);
}

sub _new_session_parameters {
    my ( $self, $capabilities ) = @_;
    my $parameters = {};
    $parameters->{capabilities}->{requiredCapabilities} =
      {};    # for Mozilla 50 (and below???)
    if (   ( defined $capabilities )
        && ( ref $capabilities )
        && ( ref $capabilities eq 'Firefox::Marionette::Capabilities' ) )
    {
        my $actual = {};
        if ( defined $capabilities->accept_insecure_certs() ) {

            $actual->{acceptInsecureCerts} =
              $capabilities->accept_insecure_certs()
              ? JSON::true()
              : JSON::false();
        }
        if ( defined $capabilities->page_load_strategy() ) {
            $actual->{pageLoadStrategy} = $capabilities->page_load_strategy();
        }
        if ( defined $capabilities->moz_webdriver_click() ) {
            $actual->{'moz:webdriverClick'} =
              $capabilities->moz_webdriver_click()
              ? JSON::true()
              : JSON::false();
        }
        if (
            defined $capabilities->moz_use_non_spec_compliant_pointer_origin() )
        {
            $actual->{'moz:useNonSpecCompliantPointerOrigin'} =
              $capabilities->moz_use_non_spec_compliant_pointer_origin()
              ? JSON::true()
              : JSON::false();
        }
        if ( defined $capabilities->moz_accessibility_checks() ) {
            $actual->{'moz:accessibilityChecks'} =
              $capabilities->moz_accessibility_checks()
              ? JSON::true()
              : JSON::false();
        }
        if ( $capabilities->proxy() ) {
            $actual->{proxy} = $self->_request_proxy( $capabilities->proxy() );
        }
        elsif ( my $env_proxy = $self->_proxy_from_env() ) {
            $actual->{proxy} = $env_proxy;
        }
        $parameters = $actual;    # for Mozilla 57 and after
        foreach my $key ( sort { $a cmp $b } keys %{$actual} ) {
            $parameters->{capabilities}->{requiredCapabilities}->{$key} =
              $actual->{$key};    # for Mozilla 56 (and below???)
        }
        $parameters->{capabilities}->{requiredCapabilities} ||=
          {};                     # for Mozilla 50 (and below???)
    }
    elsif ( my $env_proxy = $self->_proxy_from_env() ) {
        $parameters->{proxy} = $env_proxy;    # for Mozilla 57 and after
        $parameters->{capabilities}->{requiredCapabilities}->{proxy} =
          $env_proxy;                         # for Mozilla 56 (and below???)
    }
    return $parameters;
}

sub new_session {
    my ( $self, $capabilities ) = @_;
    my $parameters = $self->_new_session_parameters($capabilities);
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),                              $message_id,
            $self->_command('WebDriver:NewSession'), $parameters
        ]
    );
    my $response = $self->_get_response($message_id);
    $self->{session_id} = $response->result()->{sessionId};
    my $new;
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        $new =
          $self->_create_capabilities( $response->result()->{capabilities} );
    }
    elsif ( ref $response->result()->{value} ) {
        $new =
          $self->_create_capabilities( $response->result()->{value} );
    }
    else {
        $new = $self->capabilities();
    }
    $self->{_browser_version} = $new->browser_version();

    if ( ( defined $capabilities ) && ( defined $capabilities->timeouts() ) ) {
        $self->timeouts( $capabilities->timeouts() );
        $new->timeouts( $capabilities->timeouts() );
    }
    return ( $self->{session_id}, $new );
}

sub browser_version {
    my ($self) = @_;
    if ( defined $self->{_browser_version} ) {
        return $self->{_browser_version};
    }
    else {
        return join q[.],
          map { defined $_ ? $_ : () } $self->{_initial_version}->{major},
          $self->{_initial_version}->{minor},
          $self->{_initial_version}->{patch};
    }
}

sub _create_capabilities {
    my ( $self, $parameters ) = @_;
    my $pid = $parameters->{'moz:processID'} || $parameters->{processId};
    if ( ($pid) && ( $OSNAME eq 'cygwin' ) ) {
        $pid = $self->_pid();
    }
    my $headless = $self->_visible() ? 0 : 1;
    if ( defined $parameters->{'moz:headless'} ) {
        if ( $parameters->{'moz:headless'} != $headless ) {
            Firefox::Marionette::Exception->throw(
                'moz:headless has not been determined correctly');
        }
    }
    else {
        $parameters->{'moz:headless'} = $headless;
    }
    if ( !defined $self->{_page_load_timeouts_key} ) {
        if ( $parameters->{timeouts} ) {
            if ( defined $parameters->{timeouts}->{'page load'} ) {
                $self->{_page_load_timeouts_key} = 'page load';
            }
            else {
                $self->{_page_load_timeouts_key} = 'pageLoad';
            }
        }
        else {
            $self->{_no_timeouts_command}    = {};
            $self->{_page_load_timeouts_key} = 'pageLoad';
            $self->timeouts(
                Firefox::Marionette::Timeouts->new(
                    page_load => _DEFAULT_PAGE_LOAD_TIMEOUT(),
                    script    => _DEFAULT_SCRIPT_TIMEOUT(),
                    implicit  => _DEFAULT_IMPLICIT_TIMEOUT(),
                )
            );
        }
    }
    elsif ( $self->{_no_timeouts_command} ) {
        $parameters->{timeouts} = {
            $self->{_page_load_timeouts_key} =>
              $self->{_no_timeouts_command}->page_load(),
            script   => $self->{_no_timeouts_command}->script(),
            implicit => $self->{_no_timeouts_command}->implicit(),
        };
    }
    my %optional = $self->_get_optional_capabilities($parameters);

    return Firefox::Marionette::Capabilities->new(
        timeouts => Firefox::Marionette::Timeouts->new(
            page_load =>
              $parameters->{timeouts}->{ $self->{_page_load_timeouts_key} },
            script   => $parameters->{timeouts}->{script},
            implicit => $parameters->{timeouts}->{implicit},
        ),
        browser_version => defined $parameters->{browserVersion}
        ? $parameters->{browserVersion}
        : $parameters->{version},
        platform_name => defined $parameters->{platformName}
        ? $parameters->{platformName}
        : $parameters->{platform},
        rotatable        => $parameters->{rotatable} ? 1 : 0,
        platform_version => $parameters->{platformVersion},
        moz_profile      => $parameters->{'moz:profile'}
          || $self->{profile_directory},
        moz_process_id => $pid,
        moz_build_id   => $parameters->{'moz:buildID'}
          || $parameters->{appBuildId},
        browser_name => $parameters->{browserName},
        moz_headless => $headless,
        %optional,
    );
}

sub _get_optional_capabilities {
    my ( $self, $parameters ) = @_;
    my %optional;
    if (   ( defined $parameters->{proxy} )
        && ( keys %{ $parameters->{proxy} } ) )
    {
        $optional{proxy} = Firefox::Marionette::Proxy->new(
            $self->_response_proxy( $parameters->{proxy} ) );
    }
    if ( defined $parameters->{'moz:accessibilityChecks'} ) {
        $optional{moz_accessibility_checks} =
          $parameters->{'moz:accessibilityChecks'} ? 1 : 0;
    }
    if ( defined $parameters->{'moz:webdriverClick'} ) {
        $optional{moz_webdriver_click} =
          $parameters->{'moz:webdriverClick'} ? 1 : 0;
    }
    if ( defined $parameters->{acceptInsecureCerts} ) {
        $optional{accept_insecure_certs} =
          $parameters->{acceptInsecureCerts} ? 1 : 0;
    }
    if ( defined $parameters->{pageLoadStrategy} ) {
        $optional{page_load_strategy} = $parameters->{pageLoadStrategy};
    }
    if ( defined $parameters->{'moz:useNonSpecCompliantPointerOrigin'} ) {
        $optional{moz_use_non_spec_compliant_pointer_origin} =
          $parameters->{'moz:useNonSpecCompliantPointerOrigin'} ? 1 : 0;
    }
    return %optional;
}

sub _response_proxy {
    my ( $self, $parameters ) = @_;
    my %proxy;
    if ( defined $parameters->{proxyType} ) {
        $proxy{type} = $parameters->{proxyType};
    }
    if ( defined $parameters->{proxyAutoconfigUrl} ) {
        $proxy{pac} = $parameters->{proxyAutoconfigUrl};
    }
    if ( defined $parameters->{ftpProxy} ) {
        $proxy{ftp} = $parameters->{ftpProxy};
        if ( $parameters->{ftpProxyPort} ) {
            $proxy{ftp} .= q[:] . $parameters->{ftpProxyPort};
        }
    }
    if ( defined $parameters->{httpProxy} ) {
        $proxy{http} = $parameters->{httpProxy};
        if ( $parameters->{httpProxyPort} ) {
            $proxy{http} .= q[:] . $parameters->{httpProxyPort};
        }
    }
    if ( defined $parameters->{sslProxy} ) {
        $proxy{https} = $parameters->{sslProxy};
        if ( $parameters->{sslProxyPort} ) {
            $proxy{https} .= q[:] . $parameters->{sslProxyPort};
        }
    }
    if ( defined $parameters->{noProxy} ) {
        $proxy{none} = $parameters->{noProxy};
    }
    if ( defined $parameters->{socksProxy} ) {
        $proxy{socks} = $parameters->{socksProxy};
        if ( $parameters->{socksProxyPort} ) {
            $proxy{socks} .= q[:] . $parameters->{socksProxyPort};
        }
    }
    if ( defined $parameters->{socksProxyVersion} ) {
        $proxy{socks_version} = $parameters->{socksProxyVersion};
    }
    elsif ( defined $parameters->{socksVersion} ) {
        $proxy{socks_version} = $parameters->{socksVersion};
    }
    return %proxy;
}

sub find_elements {
    my ( $self, $value, $using ) = @_;
    Carp::carp(
        '**** DEPRECATED METHOD - find_elements HAS BEEN REPLACED BY find ****'
    );
    return $self->_find( $value, $using );
}

sub list {
    my ( $self, $value, $using, $from ) = @_;
    Carp::carp('**** DEPRECATED METHOD - list HAS BEEN REPLACED BY find ****');
    return $self->_find( $value, $using, $from );
}

sub list_by_id {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
        '**** DEPRECATED METHOD - list_by_id HAS BEEN REPLACED BY find_id ****'
    );
    return $self->_find( $value, 'id', $from );
}

sub list_by_name {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - list_by_name HAS BEEN REPLACED BY find_name ****'
    );
    return $self->_find( $value, 'name', $from );
}

sub list_by_tag {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - list_by_tag HAS BEEN REPLACED BY find_tag ****'
    );
    return $self->_find( $value, 'tag name', $from );
}

sub list_by_class {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - list_by_class HAS BEEN REPLACED BY find_class ****'
    );
    return $self->_find( $value, 'class name', $from );
}

sub list_by_selector {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - list_by_selector HAS BEEN REPLACED BY find_selector ****'
    );
    return $self->_find( $value, 'css selector', $from );
}

sub list_by_link {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - list_by_link HAS BEEN REPLACED BY find_link ****'
    );
    return $self->_find( $value, 'link text', $from );
}

sub list_by_partial {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - list_by_partial HAS BEEN REPLACED BY find_partial ****'
    );
    return $self->_find( $value, 'partial link text', $from );
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
            $self->_command('WebDriver:AddCookie'),
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
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
'is_selected method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:IsElementSelected'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response) ? 1 : 0;
}

sub _response_result_value {
    my ( $self, $response ) = @_;
    return $response->result()->{value};
}

sub is_enabled {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
'is_enabled method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:IsElementEnabled'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response) ? 1 : 0;
}

sub is_displayed {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
'is_displayed method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:IsElementDisplayed'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response) ? 1 : 0;
}

sub send_keys {
    my ( $self, $element, $text ) = @_;
    Carp::carp(
        '**** DEPRECATED METHOD - send_keys HAS BEEN REPLACED BY type ****');
    return $self->type( $element, $text );
}

sub type {
    my ( $self, $element, $text ) = @_;
    if (
        !(
               ( ref $element )
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
            'type method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    my $parameters = { id => $element->uuid(), text => $text };
    if ( !$self->_is_new_sendkeys_okay() ) {
        $parameters->{value} = [ split //smx, $text ];
    }
    $self->_send_request(
        [
            _COMMAND(),                                   $message_id,
            $self->_command('WebDriver:ElementSendKeys'), $parameters
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub delete_session {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:DeleteSession') ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub minimise {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, $self->_command('WebDriver:MinimizeWindow')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub maximise {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, $self->_command('WebDriver:MaximizeWindow')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub refresh {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:Refresh') ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

my %_deprecated_commands = (
    'Marionette:Quit'                 => 'quitApplication',
    'Marionette:SetContext'           => 'setContext',
    'Marionette:GetContext'           => 'getContext',
    'Marionette:AcceptConnections'    => 'acceptConnections',
    'Marionette:GetScreenOrientation' => 'getScreenOrientation',
    'Marionette:SetScreenOrientation' => 'setScreenOrientation',
    'Addon:Install'                   => 'addon:install',
    'Addon:Uninstall'                 => 'addon:uninstall',
    'WebDriver:AcceptAlert'           => 'acceptDialog',
    'WebDriver:AcceptDialog'          => 'acceptDialog',
    'WebDriver:AddCookie'             => 'addCookie',
    'WebDriver:Back'                  => 'goBack',
    'WebDriver:CloseChromeWindow'     => 'closeChromeWindow',
    'WebDriver:CloseWindow'           => [
        {
            command      => 'closeWindow',
            before_major => _MAX_VERSION_FOR_ANCIENT_CMDS()
        },
        { command => 'close', before_major => _MAX_VERSION_FOR_NEW_CMDS() }
    ],
    'WebDriver:DeleteAllCookies' => 'deleteAllCookies',
    'WebDriver:DeleteCookie'     => 'deleteCookie',
    'WebDriver:DeleteSession'    => 'deleteSession',
    'WebDriver:DismissAlert'     => 'dismissDialog',
    'Marionette:GetWindowType'   => [
        {
            command      => 'getWindowType',
            before_major => _MAX_VERSION_FOR_NEW_CMDS(),
        },
    ],
    'WebDriver:DismissAlert'           => 'dismissDialog',
    'WebDriver:ElementClear'           => 'clearElement',
    'WebDriver:ElementClick'           => 'clickElement',
    'WebDriver:ElementSendKeys'        => 'sendKeysToElement',
    'WebDriver:ExecuteAsyncScript'     => 'executeAsyncScript',
    'WebDriver:ExecuteScript'          => 'executeScript',
    'WebDriver:FindElement'            => 'findElement',
    'WebDriver:FindElements'           => 'findElements',
    'WebDriver:Forward'                => 'goForward',
    'WebDriver:FullscreenWindow'       => 'fullscreen',
    'WebDriver:GetActiveElement'       => 'getActiveElement',
    'WebDriver:GetActiveFrame'         => 'getActiveFrame',
    'WebDriver:GetAlertText'           => 'getTextFromDialog',
    'WebDriver:GetCapabilities'        => 'getSessionCapabilities',
    'WebDriver:GetChromeWindowHandle'  => 'getChromeWindowHandle',
    'WebDriver:GetChromeWindowHandles' => 'getChromeWindowHandles',
    'WebDriver:GetCookies'             => [
        {
            command      => 'getAllCookies',
            before_major => _MAX_VERSION_FOR_ANCIENT_CMDS()
        },
        {
            command      => 'getCookies',
            before_major => _MAX_VERSION_FOR_NEW_CMDS()
        }
    ],
    'WebDriver:GetCurrentChromeWindowHandle' =>
      [ { command => 'getChromeWindowHandle', before_major => 60 } ],
    'WebDriver:GetCurrentURL' => [
        {
            command      => 'getUrl',
            before_major => _MAX_VERSION_FOR_ANCIENT_CMDS()
        },
        {
            command      => 'getCurrentUrl',
            before_major => _MAX_VERSION_FOR_NEW_CMDS()
        }
    ],
    'WebDriver:GetElementAttribute' => 'getElementAttribute',
    'WebDriver:GetElementCSSValue'  => 'getElementValueOfCssProperty',
    'WebDriver:GetElementProperty'  => 'getElementProperty',
    'WebDriver:GetElementRect'      => 'getElementRect',
    'WebDriver:GetElementTagName'   => 'getElementTagName',
    'WebDriver:GetElementText'      => 'getElementText',
    'WebDriver:GetPageSource'       => 'getPageSource',
    'WebDriver:GetTimeouts'         => 'getTimeouts',
    'WebDriver:GetTitle'            => 'getTitle',
    'WebDriver:GetWindowHandle'     => [
        {
            command      => 'getWindow',
            before_major => _MAX_VERSION_FOR_ANCIENT_CMDS()
        },
        {
            command      => 'getWindowHandle',
            before_major => _MAX_VERSION_FOR_NEW_CMDS()
        }
    ],
    'WebDriver:GetWindowHandles' => [
        {
            command      => 'getWindows',
            before_major => _MAX_VERSION_FOR_ANCIENT_CMDS()
        },
        {
            command      => 'getWindowHandles',
            before_major => _MAX_VERSION_FOR_NEW_CMDS()
        }
    ],
    'WebDriver:GetWindowRect' =>
      [ { command => 'getWindowSize', before_major => 60 } ],
    'WebDriver:IsElementDisplayed' => 'isElementDisplayed',
    'WebDriver:IsElementEnabled'   => 'isElementEnabled',
    'WebDriver:IsElementSelected'  => 'isElementSelected',
    'WebDriver:MaximizeWindow'     => 'maximizeWindow',
    'WebDriver:MinimizeWindow'     => 'minimizeWindow',
    'WebDriver:Navigate'           => [
        { command => 'goUrl', before_major => _MAX_VERSION_FOR_ANCIENT_CMDS() },
        { command => 'get',   before_major => _MAX_VERSION_FOR_NEW_CMDS() }
    ],
    'WebDriver:NewSession'     => 'newSession',
    'WebDriver:PerformActions' => 'performActions',
    'WebDriver:Refresh'        => 'refresh',
    'WebDriver:ReleaseActions' => 'releaseActions',
    'WebDriver:SendAlertText'  => 'sendKeysToDialog',
    'WebDriver:SetTimeouts'    => 'setTimeouts',
    'WebDriver:SetWindowRect' =>
      [ { command => 'setWindowSize', before_major => 60 } ],
    'WebDriver:SwitchToFrame'       => 'switchToFrame',
    'WebDriver:SwitchToParentFrame' => 'switchToParentFrame',
    'WebDriver:SwitchToShadowRoot'  => 'switchToShadowRoot',
    'WebDriver:SwitchToWindow'      => 'switchToWindow',
    'WebDriver:TakeScreenshot'      => [
        {
            command      => 'screenShot',
            before_major => _MAX_VERSION_FOR_ANCIENT_CMDS()
        },
        {
            command      => 'takeScreenshot',
            before_major => _MAX_VERSION_FOR_NEW_CMDS()
        }
    ],
);

sub _command {
    my ( $self, $command ) = @_;
    if ( defined $self->browser_version() ) {
        my ( $major, $minor, $patch ) = split /[.]/smx,
          $self->browser_version();
        if ( $_deprecated_commands{$command} ) {
            if ( ref $_deprecated_commands{$command} ) {
                foreach my $command ( @{ $_deprecated_commands{$command} } ) {
                    if ( $major < $command->{before_major} ) {
                        return $command->{command};
                    }
                }
            }
            elsif ( $major < _MAX_VERSION_FOR_NEW_CMDS() ) {

                return $_deprecated_commands{$command};
            }
        }
    }
    return $command;
}

sub capabilities {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetCapabilities')
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        return $self->_create_capabilities(
            $response->result()->{capabilities} );
    }
    else {
        return $self->_create_capabilities( $response->result()->{value} );
    }

}

sub delete_cookies {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:DeleteAllCookies')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub delete_cookie {
    my ( $self, $name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:DeleteCookie'), { name => $name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub cookies {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:GetCookies') ] );
    my $response = $self->_get_response($message_id);
    my @cookies;
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        @cookies = @{ $response->result() };
    }
    else {
        @cookies = @{ $response->result()->{value} };
    }
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
    } @cookies;
}

sub tag_name {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
            'tag_name method requires a Firefox::Marionette::Element parameter'
        );
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetElementTagName'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response) ? 1 : 0;
}

sub window_rect {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:GetWindowRect') ]
    );
    my $response = $self->_get_response($message_id);
    my $result   = $response->result();
    if ( $result->{value} ) {
        $result = $result->{value};
    }
    my $old = Firefox::Marionette::Window::Rect->new(
        pos_x  => $result->{x},
        pos_y  => $result->{y},
        width  => $result->{width},
        height => $result->{height},
        wstate => $result->{state},
    );
    if ( defined $new ) {
        $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(),
                $message_id,
                $self->_command('WebDriver:SetWindowRect'),
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
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
            'rect method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetElementRect'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    my $result   = $response->result();
    if ( $result->{value} ) {
        $result = $result->{value};
    }
    return Firefox::Marionette::Element::Rect->new(
        pos_x  => $result->{x},
        pos_y  => $result->{y},
        width  => $result->{width},
        height => $result->{height},
    );
}

sub text {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
            'text method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetElementText'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub clear {
    my ( $self, $element ) = @_;
    if (
        !(
               ( ref $element )
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
            'clear method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:ElementClear'),
            { id => $element->uuid() }
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
            && ( ref $element eq 'Firefox::Marionette::Element' )
        )
      )
    {
        Firefox::Marionette::Exception->throw(
            'click method requires a Firefox::Marionette::Element parameter');
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:ElementClick'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub timeouts {
    my ( $self, $new ) = @_;
    my $old;
    if ( $self->{_no_timeouts_command} ) {
        if ( !defined $self->{_no_timeouts_command}->{page_load} ) {
            $self->{_no_timeouts_command} = $new;
        }
        $old = $self->{_no_timeouts_command};
    }
    else {
        my $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(), $message_id,
                $self->_command('WebDriver:GetTimeouts')
            ]
        );
        my $response = $self->_get_response($message_id);
        $old = Firefox::Marionette::Timeouts->new(
            page_load =>
              $response->result()->{ $self->{_page_load_timeouts_key} },
            script   => $response->result()->{script},
            implicit => $response->result()->{implicit}
        );
    }
    if ( defined $new ) {
        if ( $self->{_no_timeouts_command} ) {
            my $message_id = $self->_new_message_id();
            $self->_send_request(
                [
                    _COMMAND(),
                    $message_id,
                    'timeouts',
                    {
                        type => 'implicit',
                        ms   => $new->implicit(),
                    }
                ]
            );
            $self->_get_response($message_id);
            $message_id = $self->_new_message_id();
            $self->_send_request(
                [
                    _COMMAND(),
                    $message_id,
                    'timeouts',
                    {
                        type => 'script',
                        ms   => $new->script(),
                    }
                ]
            );
            $self->_get_response($message_id);
            $message_id = $self->_new_message_id();
            $self->_send_request(
                [
                    _COMMAND(),
                    $message_id,
                    'timeouts',
                    {
                        type => 'default',
                        ms   => $new->page_load(),
                    }
                ]
            );
            $self->_get_response($message_id);
            $self->{_no_timeouts_command} = $new;
        }
        else {
            my $message_id = $self->_new_message_id();
            $self->_send_request(
                [
                    _COMMAND(),
                    $message_id,
                    $self->_command('WebDriver:SetTimeouts'),
                    {
                        $self->{_page_load_timeouts_key} => $new->page_load(),
                        script                           => $new->script(),
                        implicit                         => $new->implicit()
                    }
                ]
            );
            $self->_get_response($message_id);
        }
    }
    return $old;
}

sub active_element {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetActiveElement')
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( ref $self->_response_result_value($response) ) {
        return Firefox::Marionette::Element->new( $self,
            %{ $self->_response_result_value($response) } );
    }
    else {
        return Firefox::Marionette::Element->new( $self,
            ELEMENT => $self->_response_result_value($response) );
    }
}

sub uri {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:GetCurrentURL') ]
    );
    my $response = $self->_get_response($message_id);
    return URI->new( $self->_response_result_value($response) );
}

sub full_screen {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:FullscreenWindow')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub dismiss_alert {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:DismissAlert') ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub send_alert_text {
    my ( $self, $text ) = @_;
    my $message_id = $self->_new_message_id();
    my $parameters = { text => $text };
    if ( !$self->_is_new_sendkeys_okay() ) {
        $parameters->{value} = [ split //smx, $text ];
    }
    $self->_send_request(
        [
            _COMMAND(),                                 $message_id,
            $self->_command('WebDriver:SendAlertText'), $parameters
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub accept_alert {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:AcceptAlert') ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub accept_dialog {
    my ($self) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - using accept_dialog() HAS BEEN REPLACED BY accept_alert ****'
    );
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:AcceptDialog') ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub alert_text {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:GetAlertText') ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub selfie {
    my ( $self, $element, @remaining ) = @_;
    my $message_id = $self->_new_message_id();
    my $parameters = {};
    my %extra;
    if (   ( ref $element )
        && ( ref $element eq 'Firefox::Marionette::Element' ) )
    {
        $parameters = { id => $element->uuid() };
        %extra      = @remaining;
    }
    elsif (( defined $element )
        && ( not( ref $element ) )
        && ( ( scalar @remaining ) % 2 ) )
    {
        %extra   = ( $element, @remaining );
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
        [
            _COMMAND(),                                  $message_id,
            $self->_command('WebDriver:TakeScreenshot'), $parameters
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( $extra{hash} ) {
        return $self->_response_result_value($response);
    }
    else {
        my $handle = File::Temp::tempfile(
            File::Spec->catfile(
                File::Spec->tmpdir(), 'firefox_marionette_selfie_XXXXXXXXXXX'
            )
          )
          or Firefox::Marionette::Exception->throw(
            "Failed to open temporary file for writing:$EXTENDED_OS_ERROR");
        binmode $handle;
        my $content = $self->_response_result_value($response);
        $content =~ s/^data:image\/png;base64,//smx;
        $handle->print( MIME::Base64::decode_base64($content) )
          or Firefox::Marionette::Exception->throw(
            "Failed to write to temporary file:$EXTENDED_OS_ERROR");
        $handle->seek( 0, Fcntl::SEEK_SET() )
          or Firefox::Marionette::Exception->throw(
            "Failed to seek to start of temporary file:$EXTENDED_OS_ERROR");
        return $handle;
    }
}

sub current_chrome_window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetCurrentChromeWindowHandle')
        ]
    );
    my $response = $self->_get_response($message_id);
    if (   ( defined $response->{result}->{ok} )
        && ( $response->{result}->{ok} ) )
    {
        $response = $self->_get_response($message_id);
    }
    return $self->_response_result_value($response);
}

sub chrome_window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetChromeWindowHandle')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub chrome_window_handles {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetChromeWindowHandles')
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        return @{ $response->result() };
    }
    else {
        return @{ $response->result()->{value} };
    }
}

sub window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetWindowHandle')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub window_handles {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetWindowHandles')
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        return @{ $response->result() };
    }
    else {
        return @{ $response->result()->{value} };
    }
}

sub new_window {
    my ( $self, %parameters ) = @_;

    foreach my $key (qw(focus)) {
        if ( defined $parameters{$key} ) {
            $parameters{$key} =
              $parameters{$key} ? JSON::true() : JSON::false();
        }
    }
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:NewWindow'), {%parameters}
        ]
    );
    my $response = $self->_get_response($message_id);
    return $response->result()->{handle};
}

sub close_current_chrome_window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:CloseChromeWindow')
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( ref $response->result() eq 'HASH' ) {
        return ( $self->_response_result_value($response) );
    }
    else {
        return @{ $response->result() };
    }
}

sub close_current_window_handle {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:CloseWindow') ] );
    my $response = $self->_get_response($message_id);
    if ( ref $response->result() eq 'HASH' ) {
        return ( $response->result() );
    }
    else {
        return @{ $response->result() };
    }
}

sub css {
    my ( $self, $element, $property_name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            $self->_command('WebDriver:GetElementCSSValue'),
            { id => $element->uuid(), propertyName => $property_name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub property {
    my ( $self, $element, $name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            $self->_command('WebDriver:GetElementProperty'),
            { id => $element->uuid(), name => $name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub attribute {
    my ( $self, $element, $name ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:GetElementAttribute'),
            { id => $element->uuid(), name => $name }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub find_element {
    my ( $self, $value, $using ) = @_;
    Carp::carp(
        '**** DEPRECATED METHOD - find_element HAS BEEN REPLACED BY find ****');
    return $self->find( $value, $using );
}

sub find {
    my ( $self, $value, $using, $from ) = @_;
    return $self->_find( $value, $using, $from );
}

sub find_id {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'id', $from );
}

sub find_name {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'name', $from );
}

sub find_tag {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'tag name', $from );
}

sub find_class {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'class name', $from );
}

sub find_selector {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'css selector', $from );
}

sub find_link {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'link text', $from );
}

sub find_partial {
    my ( $self, $value, $from ) = @_;
    return $self->_find( $value, 'partial link text', $from );
}

sub find_by_id {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
        '**** DEPRECATED METHOD - find_by_id HAS BEEN REPLACED BY find_id ****'
    );
    return $self->find_id( $value, $from );
}

sub find_by_name {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - find_by_name HAS BEEN REPLACED BY find_name ****'
    );
    return $self->find_name( $value, $from );
}

sub find_by_tag {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - find_by_tag HAS BEEN REPLACED BY find_tag ****'
    );
    return $self->find_tag( $value, $from );
}

sub find_by_class {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - find_by_class HAS BEEN REPLACED BY find_class ****'
    );
    return $self->find_class( $value, $from );
}

sub find_by_selector {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - find_by_selector HAS BEEN REPLACED BY find_selector ****'
    );
    return $self->find_selector( $value, $from );
}

sub find_by_link {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - find_by_link HAS BEEN REPLACED BY find_link ****'
    );
    return $self->find_link( $value, $from );
}

sub find_by_partial {
    my ( $self, $value, $from ) = @_;
    Carp::carp(
'**** DEPRECATED METHOD - find_by_partial HAS BEEN REPLACED BY find_partial ****'
    );
    return $self->find_partial( $value, $from );
}

sub _find {
    my ( $self, $value, $using, $from ) = @_;
    $using ||= 'xpath';
    my $message_id = $self->_new_message_id();
    my $parameters = { using => $using, value => $value };
    if ( defined $from ) {
        if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() )
        {
            $parameters->{element} = $from->uuid();
        }
        else {
            $parameters->{ELEMENT} = $from->uuid();
        }
    }
    my $command =
      wantarray ? 'WebDriver:FindElements' : 'WebDriver:FindElement';
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command($command), $parameters, ] );
    my $response =
      $self->_get_response( $message_id, { using => $using, value => $value } );
    if (wantarray) {
        if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() )
        {
            return
              map { Firefox::Marionette::Element->new( $self, %{$_} ) }
              @{ $response->result() };
        }
        elsif (( ref $self->_response_result_value($response) )
            && ( ( ref $self->_response_result_value($response) ) eq 'ARRAY' )
            && ( ref $self->_response_result_value($response)->[0] )
            && ( ( ref $self->_response_result_value($response)->[0] ) eq
                'HASH' ) )
        {
            return
              map { Firefox::Marionette::Element->new( $self, %{$_} ) }
              @{ $self->_response_result_value($response) };
        }
        else {
            return
              map { Firefox::Marionette::Element->new( $self, ELEMENT => $_ ) }
              @{ $self->_response_result_value($response) };
        }
    }
    else {
        if (
            (
                $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3()
            )
            || ( $self->{_initial_packet_size} != _OLD_INITIAL_PACKET_SIZE() )
          )
        {
            return Firefox::Marionette::Element->new( $self,
                %{ $self->_response_result_value($response) } );
        }
        else {
            return Firefox::Marionette::Element->new( $self,
                ELEMENT => $self->_response_result_value($response) );
        }
    }
}

sub active_frame {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, $self->_command('WebDriver:GetActiveFrame')
        ]
    );
    my $response = $self->_get_response($message_id);
    if ( defined $self->_response_result_value($response) ) {
        if ( ref $self->_response_result_value($response) ) {
            return Firefox::Marionette::Element->new( $self,
                %{ $self->_response_result_value($response) } );
        }
        else {
            return Firefox::Marionette::Element->new( $self,
                ELEMENT => $self->_response_result_value($response) );
        }
    }
    else {
        return;
    }
}

sub title {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:GetTitle') ] );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub quit {
    my ( $self, $flags ) = @_;
    if ( !$self->alive() ) {
        my $socket = delete $self->{_socket};
        if ($socket) {
            close $socket
              or Firefox::Marionette::Exception->throw(
                "Failed to close socket to firefox:$EXTENDED_OS_ERROR");
        }
    }
    elsif ( $self->_socket() ) {
        if ( $self->_session_id() ) {
            $flags ||=
              ['eAttemptQuit']
              ;    # ["eConsiderQuit", "eAttemptQuit", "eForceQuit"]
            my $message_id = $self->_new_message_id();
            $self->_send_request(
                [
                    _COMMAND(), $message_id,
                    $self->_command('Marionette:Quit'), { flags => $flags }
                ]
            );
            my $response = $self->_get_response($message_id);
            my $socket   = delete $self->{_socket};
            if ( $OSNAME eq 'MSWin32' ) {
                $self->{_win32_process}->Wait( Win32::Process::INFINITE() );
                $self->_reap();
            }
            else {
                if (
                    ( $self->{_initial_version}->{major} )
                    && ( $self->{_initial_version}->{major} <
                        _MIN_VERSION_FOR_MODERN_EXIT() )
                  )
                {
                    close $socket
                      or Firefox::Marionette::Exception->throw(
                        "Failed to close socket to firefox:$EXTENDED_OS_ERROR");
                    $socket = undef;
                }
                while ( kill 0, $self->_pid() ) {
                    sleep 1;
                    $self->_reap();
                }
            }
            if ( defined $socket ) {
                close $socket
                  or Firefox::Marionette::Exception->throw(
                    "Failed to close socket to firefox:$EXTENDED_OS_ERROR");
            }
        }
    }
    $self->_terminate_process();
    if ( my $pid = $self->xvfb() ) {
        my $int_signal = $self->_signal_number('INT');
        while ( kill 0, $pid ) {
            kill $int_signal, $pid;
            sleep 1;
            $self->_reap();
        }
        delete $self->{_xvfb_display_number};
        delete $self->{_xvfb_authority_directory};
    }
    return $self->child_error();
}

sub _terminate_process {
    my ($self) = @_;
    if ( $OSNAME eq 'MSWin32' ) {
        if ( $self->{_win32_process} ) {
            $self->{_win32_process}->Kill(1);
            sleep 1;
            $self->{_win32_process}->GetExitCode( my $exit_code );
            while ( $exit_code == Win32::Process::STILL_ACTIVE() ) {
                $self->{_win32_process}->Kill(1);
                sleep 1;
                $exit_code = $self->{_win32_process}->Kill(1);
            }
        }
    }
    elsif ( ( $self->_pid() ) && ( kill 0, $self->_pid() ) ) {
        my $term_signal = $self->_signal_number('TERM')
          ;    # https://support.mozilla.org/en-US/questions/752748
        if ( $term_signal > 0 ) {
            my $count = 0;
            while (( $count < _NUMBER_OF_TERM_ATTEMPTS() )
                && ( kill $term_signal, $self->_pid() ) )
            {
                $count += 1;
                sleep 1;
                $self->_reap();
            }
        }
        my $kill_signal = $self->_signal_number('KILL');   # no more mr nice guy
        if ( $kill_signal > 0 ) {
            while ( kill $kill_signal, $self->_pid() ) {
                sleep 1;
                $self->_reap();
            }
        }
    }
    return;
}

sub context {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('Marionette:GetContext') ] );
    my $response;
    eval { $response = $self->_get_response($message_id); } or do {
        Carp::carp( 'Retrieving context is not supported for Firefox '
              . $self->browser_version() . q[:]
              . $EVAL_ERROR );
    };
    my $context;
    if ( defined $response ) {
        $context =
          $self->_response_result_value($response);    # 'content' or 'chrome'
    }
    else {
        $context = $self->{'_context'} || 'content';
    }
    $self->{'_context'} = $context;
    if ( defined $new ) {
        $message_id = $self->_new_message_id();
        $self->_send_request(
            [
                _COMMAND(), $message_id,
                $self->_command('Marionette:SetContext'), { value => $new }
            ]
        );
        $response = $self->_get_response($message_id);
        $self->{'_context'} = $new;
    }
    return $context;
}

sub accept_connections {
    my ( $self, $new ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            $self->_command('Marionette:AcceptConnections'),
            { value => $new ? JSON::true() : JSON::false() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub async_script {
    my ( $self, $script, %parameters ) = @_;
    delete $parameters{script};
    $parameters{args} ||= [];
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:ExecuteAsyncScript'),
            { script => $script, %parameters }
        ]
    );
    return $self;
}

sub interactive {
    my ($self) = @_;
    if ( $self->loaded() ) {
        return 1;
    }
    else {
        return $self->script(
'if (document.readyState === "interactive") { return 1; } else { return 0 }'
        );
    }
}

sub loaded {
    my ($self) = @_;
    return $self->script(
'if (document.readyState === "complete") { return 1; } else { return 0 }'
    );
}

sub _script_parameters {
    my ( $self, %parameters ) = @_;
    delete $parameters{script};
    $parameters{args} ||= [];
    my %mapping = (
        timeout => 'scriptTimeout',
        new     => 'newSandbox',
    );
    foreach my $from ( sort { $a cmp $b } keys %mapping ) {
        my $to = $mapping{$from};
        if ( defined $parameters{$to} ) {
            Carp::carp(
"**** DEPRECATED PARAMETER - using $to as a parameter for the script(...) method HAS BEEN REPLACED BY the $from parameter ****"
            );
        }
        elsif ( defined $parameters{$from} ) {
            $parameters{$to} = $parameters{$from};
            delete $parameters{$from};
        }
    }
    foreach my $key (qw(newSandbox)) {
        if ( defined $parameters{$key} ) {
            $parameters{$key} =
              $parameters{$key} ? JSON::true() : JSON::false();
        }
    }
    return %parameters;
}

sub script {
    my ( $self, $script, %parameters ) = @_;
    %parameters = $self->_script_parameters(%parameters);
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:ExecuteScript'),
            { script => $script, value => $script, %parameters }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub json {
    my ($self) = @_;
    my $content = $self->strip();
    return JSON::decode_json($content);
}

sub strip {
    my ($self)  = @_;
    my $content = $self->html();
    my $header  = quotemeta
'<html xmlns="http://www.w3.org/1999/xhtml"><head><link rel="alternate stylesheet" type="text/css" href="resource://gre-resources/plaintext.css" title="Wrap Long Lines" /></head><body><pre>';
    my $footer = quotemeta '</pre></body></html>';
    $content =~ s/^$header(.*)$footer$/$1/smx;
    $header = quotemeta
'<html><head><link rel="alternate stylesheet" type="text/css" href="resource://content-accessible/plaintext.css" title="Wrap Long Lines"></head><body><pre>';
    $content =~ s/^$header(.*)$footer$/$1/smx;
    $header = quotemeta
'<html><head><link rel="alternate stylesheet" type="text/css" href="resource://gre-resources/plaintext.css" title="Wrap Long Lines"></head><body><pre>';
    $content =~ s/^$header(.*)$footer$/$1/smx;
    $header = quotemeta
'<html><head><link rel="alternate stylesheet" type="text/css" href="resource://content-accessible/plaintext.css" title="Wrap Long Lines"></head><body><pre>';
    $content =~ s/^$header(.*)$footer$/$1/smx;
    $header = quotemeta
'<html xmlns="http://www.w3.org/1999/xhtml"><head><link title="Wrap Long Lines" href="resource://gre-resources/plaintext.css" type="text/css" rel="alternate stylesheet" /></head><body><pre>';
    $content =~ s/^$header(.*)$footer$/$1/smx;
    return $content;
}

sub html {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            $self->_command('WebDriver:GetPageSource'),
            { sessionId => $self->_session_id() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub page_source {
    my ($self) = @_;
    Carp::carp(
        '**** DEPRECATED METHOD - page_source HAS BEEN REPLACED BY html ****');
    return $self->html();
}

sub back {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:Back') ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub forward {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [ _COMMAND(), $message_id, $self->_command('WebDriver:Forward') ] );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub screen_orientation {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('Marionette:GetScreenOrientation')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub switch_to_parent_frame {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:SwitchToParentFrame')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub window_type {
    my ($self) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id, $self->_command('Marionette:GetWindowType')
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub switch_to_shadow_root {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:SwitchToShadowRoot'),
            { id => $element->uuid() }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub switch_to_window {
    my ( $self, $window_handle ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('WebDriver:SwitchToWindow'),
            { value => "$window_handle", name => "$window_handle" }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub switch_to_frame {
    my ( $self, $element ) = @_;
    my $message_id = $self->_new_message_id();
    my $parameters;
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        $parameters = { element => $element->uuid() };
    }
    else {
        $parameters = { ELEMENT => $element->uuid() };
    }
    $self->_send_request(
        [
            _COMMAND(),                                 $message_id,
            $self->_command('WebDriver:SwitchToFrame'), $parameters,
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
            _COMMAND(),
            $message_id,
            $self->_command('WebDriver:Navigate'),
            {
                url       => "$uri",
                value     => "$uri",
                sessionId => $self->_session_id()
            }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub sleep_time_in_ms {
    my ( $self, $new ) = @_;
    my $old = $self->{sleep_time_in_ms} || 1;
    if ( defined $new ) {
        $self->{sleep_time_in_ms} = $new;
    }
    return $old;
}

sub bye {
    my ( $self, $code ) = @_;
    my $found = 1;
    while ( !$found ) {
        eval { &{$code} } and do {
            Time::HiRes::sleep(
                $self->sleep_time_in_ms() / _MILLISECONDS_IN_ONE_SECOND() );
          }
          or do {
            if (
                ( ref $EVAL_ERROR )
                && (
                    (
                        ref $EVAL_ERROR eq
                        'Firefox::Marionette::Exception::NotFound'
                    )
                    || (
                        ref $EVAL_ERROR eq
                        'Firefox::Marionette::Exception::StaleElement' )
                )
              )
            {
                $found = 0;
            }
            else {
                Carp::croak($EVAL_ERROR);
            }
          };
    }
    return $self;
}

sub await {
    my ( $self, $code ) = @_;
    my $result;
    while ( !$result ) {
        $result = eval { &{$code} } or do {
            if (
                ( ref $EVAL_ERROR )
                && (
                    (
                        ref $EVAL_ERROR eq
                        'Firefox::Marionette::Exception::NotFound'
                    )
                    || (
                        ref $EVAL_ERROR eq
                        'Firefox::Marionette::Exception::StaleElement' )
                    || (
                        ref $EVAL_ERROR eq
                        'Firefox::Marionette::Exception::NoSuchAlert' )
                )
              )
            {
            }
            elsif ( ref $EVAL_ERROR ) {
                Carp::croak($EVAL_ERROR);
            }
        };
        if ( !$result ) {
            Time::HiRes::sleep(
                $self->sleep_time_in_ms() / _MILLISECONDS_IN_ONE_SECOND() );
        }
    }
    return $result;
}

sub install {
    my ( $self, $path, $temporary ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(),
            $message_id,
            $self->_command('Addon:Install'),
            {
                path      => "$path",
                temporary => $temporary ? JSON::true() : JSON::false()
            }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self->_response_result_value($response);
}

sub uninstall {
    my ( $self, $id ) = @_;
    my $message_id = $self->_new_message_id();
    $self->_send_request(
        [
            _COMMAND(), $message_id,
            $self->_command('Addon:Uninstall'), { id => $id }
        ]
    );
    my $response = $self->_get_response($message_id);
    return $self;
}

sub marionette_protocol {
    my ($self) = @_;
    return $self->{marionette_protocol} || 0;
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

sub addons {
    my ($self) = @_;
    return $self->{addons};
}

sub _convert_request_to_old_protocols {
    my ( $self, $original ) = @_;
    my $new;
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        $new = $original;
    }
    else {
        $new->{ $self->{_old_protocols_key} } =
          $original->[ _OLD_PROTOCOL_NAME_INDEX() ];
        $new->{parameters} = $original->[ _OLD_PROTOCOL_PARAMETERS_INDEX() ];
        if (   ( ref $new->{parameters} )
            && ( ( ref $new->{parameters} ) eq 'HASH' ) )
        {
            if ( defined $new->{parameters}->{id} ) {
                $new->{parameters}->{element} = $new->{parameters}->{id};
            }
            foreach my $key (
                sort { $a cmp $b }
                keys %{ $original->[ _OLD_PROTOCOL_PARAMETERS_INDEX() ] }
              )
            {
                next if ( $key eq $self->{_old_protocols_key} );
                $new->{$key} = $new->{parameters}->{$key};
            }
        }
    }
    return $new;
}

sub _send_request {
    my ( $self, $object ) = @_;
    $object = $self->_convert_request_to_old_protocols($object);
    my $json   = JSON::encode_json($object);
    my $length = length $json;
    if ( $self->_debug() ) {
        warn ">> $length:$json\n";
    }
    my $result = syswrite $self->_socket(), "$length:$json";
    if ( !defined $result ) {
        my $socket_error = $EXTENDED_OS_ERROR;
        if ( $self->alive() ) {
            Firefox::Marionette::Exception->throw(
                "Failed to send request to firefox:$socket_error");
        }
        else {
            my $error_message =
              $self->error_message() ? $self->error_message() : q[];
            Firefox::Marionette::Exception->throw($error_message);
        }
    }
    return;
}

sub _read_from_socket {
    my ($self) = @_;
    my $number_of_bytes_in_response;
    my $initial_buffer;
    while ( ( !defined $number_of_bytes_in_response ) && ( $self->alive() ) ) {
        my $number_of_bytes = sysread $self->_socket(), my $octet, 1;
        if ( defined $number_of_bytes ) {
            $initial_buffer .= $octet;
        }
        else {
            my $socket_error = $EXTENDED_OS_ERROR;
            if ( $self->alive() ) {
                Firefox::Marionette::Exception->throw(
"Failed to read size of response from socket to firefox:$socket_error"
                );
            }
            else {
                my $error_message =
                  $self->error_message() ? $self->error_message() : q[];
                Firefox::Marionette::Exception->throw($error_message);
            }
        }
        if ( $initial_buffer =~ s/^(\d+)://smx ) {
            ($number_of_bytes_in_response) = ($1);
        }
    }
    if ( !defined $self->{_initial_packet_size} ) {
        $self->{_initial_packet_size} = $number_of_bytes_in_response;
    }
    my $number_of_bytes_already_read = 0;
    my $json                         = q[];
    while (( defined $number_of_bytes_in_response )
        && ( $number_of_bytes_already_read < $number_of_bytes_in_response )
        && ( $self->alive() ) )
    {
        my $number_of_bytes_read = sysread $self->_socket(), my $buffer,
          $number_of_bytes_in_response - $number_of_bytes_already_read;
        if ( defined $number_of_bytes_read ) {
            $json .= $buffer;
            $number_of_bytes_already_read += $number_of_bytes_read;
        }
        else {
            my $socket_error = $EXTENDED_OS_ERROR;
            if ( $self->alive() ) {
                Firefox::Marionette::Exception->throw(
"Failed to read response from socket to firefox:$socket_error"
                );
            }
            else {
                my $error_message =
                  $self->error_message() ? $self->error_message() : q[];
                Firefox::Marionette::Exception->throw($error_message);
            }
        }
    }
    if ( $self->_debug() ) {
        warn "<< $number_of_bytes_in_response:$json\n";
    }
    return $self->_decode_json($json);
}

sub _decode_json {
    my ( $self, $json ) = @_;
    my $parameters;
    eval { $parameters = JSON::decode_json($json); } or do {
        if ( $self->alive() ) {
            if ($EVAL_ERROR) {
                chomp $EVAL_ERROR;
                die "$EVAL_ERROR\n";
            }
        }
        else {
            my $error_message =
              $self->error_message() ? $self->error_message() : q[];
            Firefox::Marionette::Exception->throw($error_message);
        }
    };
    return $parameters;
}

sub _socket {
    my ($self) = @_;
    return $self->{_socket};
}

sub _get_response {
    my ( $self, $message_id, $parameters ) = @_;
    my $next_message = $self->_read_from_socket();
    my $response =
      Firefox::Marionette::Response->new( $next_message, $parameters );
    if ( $self->marionette_protocol() == _MARIONETTE_PROTOCOL_VERSION_3() ) {
        while ( $response->message_id() < $message_id ) {
            $next_message = $self->_read_from_socket();
            $response =
              Firefox::Marionette::Response->new( $next_message, $parameters );
        }
    }
    return $response;
}

sub _signal_number {
    my ( $self, $name ) = @_;
    my @sig_nums  = split q[ ], $Config{sig_num};
    my @sig_names = split q[ ], $Config{sig_name};
    my %signals_by_name;
    my $idx = 0;
    foreach my $sig_name (@sig_names) {
        $signals_by_name{$sig_name} = $sig_nums[$idx];
        $idx += 1;
    }
    return $signals_by_name{$name};
}

sub DESTROY {
    my ($self) = @_;
    if ( $self->{creation_pid} == $PROCESS_ID ) {
        $self->quit();
    }
    return;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Firefox::Marionette - Automate the Firefox browser with the Marionette protocol

=head1 VERSION

Version 0.77

=head1 SYNOPSIS

    use Firefox::Marionette();
    use v5.10;

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    say $firefox->html();

    $firefox->find_class('container-fluid')->find_id('search-input')->type('Test::More');

    my $file_handle = $firefox->selfie(highlights => [ $firefox->find_name('lucky') ]);

    $firefox->find('//button[@name="lucky"]')->click();

    $firefox->await(sub { $firefox->interactive() && $firefox->find_partial('Download') })->click();

=head1 DESCRIPTION

This is a client module to automate the Mozilla Firefox browser via the L<Marionette protocol|https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/Protocol>

=head1 SUBROUTINES/METHODS

=head2 new
 
accepts an optional hash as a parameter.  Allowed keys are below;

=over 4

=item * firefox_binary - use the specified path to the L<Firefox|https://firefox.org/> binary, rather than the default path.

=item * capabilities - use the supplied L<capabilities|Firefox::Marionette::Capabilities> object, for example to set whether the browser should L<accept insecure certs|Firefox::Marionette::Capabilities#accept_insecure_certs> or whether the browser should use a L<proxy|Firefox::Marionette::Proxy>.

=item * profile_name - pick a specific existing profile to automate, rather than creating a new profile.  Note that L<firefox|https://firefox.com> refuses to allow more than one instance of a profile to run at the same time.  Profile names can be obtained by using the L<Firefox::Marionette::Profile::names()|Firefox::Marionette::Profile#names> method.  NOTE: firefox ignores any changes made to the profile on the disk while it is running.

=item * profile - create a new profile based on the supplied profile.  NOTE: firefox ignores any changes made to the profile on the disk while it is running.

=item * debug - should firefox's debug to be available via STDERR. This defaults to "0".

=item * addons - should any firefox extensions and themes be available in this session.  This defaults to "0".

=item * mime_types - any MIME types that Firefox will encounter during this session.  MIME types that are not specified will result in a hung browser (the File Download popup will appear).

=item * sleep_time_in_ms - the amount of time (in milliseconds) that this module should sleep when unsuccessfully calling the subroutine provided to the L<await|Firefox::Marionette#await> or L<bye|Firefox::Marionette#bye> methods.  This defaults to "1" millisecond.

=item * visible - should firefox be visible on the desktop.  This defaults to "0".

=item * timeouts - a shortcut to allow directly providing a L<timeout|Firefox::Marionette::Timeout> object, instead of needing to use timeouts from the capabilities parameter.  Overrides the timeouts provided (if any) in the capabilities parameter.

=item * page_load - a shortcut to allow directly providing the L<page_load|Firefox::Marionette::Timeout#page_load> timeout, instead of needing to use timeouts from the capabilities parameter.  Overrides all longer ways.

=item * script - a shortcut to allow directly providing the L<script|Firefox::Marionette::Timeout#script> timeout, instead of needing to use timeouts from the capabilities parameter.  Overrides all longer ways.

=item * implicit - a shortcut to allow directly providing the L<implicit|Firefox::Marionette::Timeout#implicit> timeout, instead of needing to use timeouts from the capabilities parameter.  Overrides all longer ways.

=back

This method returns a new C<Firefox::Marionette> object, connected to an instance of L<firefox|https://firefox.com>.  In a non MacOS/Win32/Cygwin environment, if necessary (no DISPLAY variable can be found and visible has been set to true) and possible (Xvfb can be executed successfully), this method will also automatically start an L<Xvfb|https://en.wikipedia.org/wiki/Xvfb> instance.
 
=head2 go

Navigates the current browsing context to the given L<URI|URI> and waits for the document to load or the session's L<page_load|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning, which, by default is 5 minutes.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods

=head2 uri

returns the current L<URI|URI> of current top level browsing context for Desktop.  It is equivalent to the javascript C<document.location.href>

=head2 title

returns the current title of the window.

=head2 find

accepts an L<xpath expression|https://en.wikipedia.org/wiki/XPath> as the first parameter and returns the first L<element|Firefox::Marionette::Element> that matches this expression.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    $firefox->find('//input[@id="search-input"]')->type('Test::More');

    # OR in list context 

    foreach my $element ($firefox->find('//input[@id="search-input"]')) {
        $element->type('Test::More');
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_id

accepts an L<id|https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/id> as the first parameter and returns the first L<element|Firefox::Marionette::Element> with a matching 'id' property.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    $firefox->find_id('search-input')->type('Test::More');

    # OR in list context 

    foreach my $element ($firefox->find_id('search-input')) {
        $element->type('Test::More');
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_name

This method returns the first L<element|Firefox::Marionette::Element> with a matching 'name' property.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_name('q')->type('Test::More');

    # OR in list context 

    foreach my $element ($firefox->find_name('q')) {
        $element->type('Test::More');
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_class

accepts a L<class name|https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/class> as the first parameter and returns the first L<element|Firefox::Marionette::Element> with a matching 'class' property.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_class('form-control home-search-input')->type('Test::More');

    # OR in list context 

    foreach my $element ($firefox->find_class('form-control home-search-input')) {
        $element->type('Test::More');
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_selector

accepts a L<CSS Selector|https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors> as the first parameter and returns the first L<element|Firefox::Marionette::Element> that matches that selector.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_selector('input.home-search-input')->type('Test::More');

    # OR in list context 

    foreach my $element ($firefox->find_selector('input.home-search-input')) {
        $element->type('Test::More');
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_tag

accepts a L<tag name|https://developer.mozilla.org/en-US/docs/Web/API/Element/tagName> as the first parameter and returns the first L<element|Firefox::Marionette::Element> with this tag name.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    my $element = $firefox->find_tag('input');

    # OR in list context 

    foreach my $element ($firefox->find_tag('input')) {
        # do something
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_link

accepts a text string as the first parameter and returns the first link L<element|Firefox::Marionette::Element> that has a matching link text.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_link('API')->click();

    # OR in list context 

    foreach my $element ($firefox->find_link('API')) {
        $element->click();
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 find_partial

accepts a text string as the first parameter and returns the first link L<element|Firefox::Marionette::Element> that has a partially matching link text.

This method is subject to the L<implicit|Firefox::Marionette::Timeouts#implicit> timeout, which, by default is 0 seconds.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_partial('AP')->click();

    # OR in list context 

    foreach my $element ($firefox->find_partial('AP')) {
        $element->click();
    }

If no elements are found, a L<not found|Firefox::Marionette::Exception::NotFound> exception will be thrown. 

=head2 css

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a scalar CSS property name as the second parameter.  It returns the value of the computed style for that property.

=head2 attribute 

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a scalar attribute name as the second parameter.  It returns the initial value of the attribute with the supplied name.  This method will return the initial content, the L<property|Firefox::Marionette#property> method will return the current content.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    my $element = $firefox->find_id('search_input');
    !defined $element->attribute('value') or die "attribute is not defined!");
    $element->type('Test::More');
    !defined $element->attribute('value') or die "attribute is still not defined!");

=head2 property

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a scalar attribute name as the second parameter.  It returns the current value of the property with the supplied name.  This method will return the current content, the L<attribute|Firefox::Marionette#attribute> method will return the initial content.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    my $element = $firefox->find_id('search_input');
    $element->property('value') eq '' or die "Initial property is the empty string";
    $element->type('Test::More');
    $element->property('value') eq 'Test::More' or die "This property should have changed!";

=head2 interactive

returns true if C<document.readyState === "interactive"> or if L<loaded|Firefox::Marionette#loaded> is true

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_id('search_input')->type('Type::More');
    $firefox->find('//button[@name="lucky"]')->click();
    while(!$firefox->interactive()) {
        # redirecting to Test::More page
    }

=head2 loaded

returns true if C<document.readyState === "complete">

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
    $firefox->find_id('search_input')->type('Type::More');
    $firefox->find('//button[@name="lucky"]')->click();
    while(!$firefox->loaded()) {
        # redirecting to Test::More page
    }

=head2 mime_types

returns a list of MIME types that will be downloaded by firefox and made available from the L<downloads|Firefox::Marionette#downloads> method

    use Firefox::Marionette();
    use v5.10;

    my $firefox = Firefox::Marionette->new(mime_types => [ 'application/pkcs10' ])

    foreach my $mime_type ($firefox->mime_types()) {
        say $mime_type;
    }

=head2 downloads

returns a list of file paths (including partial downloads) of downloads during this Firefox session.

    use Firefox::Marionette();
    use v5.10;

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    $firefox->find_class('container-fluid')->find_id('search-input')->type('Test::More');

    $firefox->find('//button[@name="lucky"]')->click();

    $firefox->await(sub { $firefox->interactive() && $firefox->find_partial('Download') })->click();

    while(!$firefox->downloads()) { sleep 1 }

    foreach my $path ($firefox->downloads()) {
        say $path;
    }

=head2 downloading

returns true if any files in L<downloads|Firefox::Marionette#downloads> end in C<.part>

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    $firefox->find_class('container-fluid')->find_id('search-input')->type('Test::More');

    $firefox->find('//button[@name="lucky"]')->click();

    $firefox->await(sub { $firefox->interactive() && $firefox->find_partial('Download') })->click();

    while(!$firefox->downloads()) { sleep 1 }

    while($firefox->downloading()) { sleep 1 }

    foreach my $path ($firefox->downloads()) {
        say $path;
    }

=head2 script 

accepts a scalar containing a javascript function body that is executed in the browser, and an optional hash as a second parameter.  Allowed keys are below;

=over 4

=item * args - The reference to a list is the arguments passed to the function body.

=item * timeout - A timeout to override the default L<script|Firefox::Marionette::Timeouts#script> timeout, which, by default is 30 seconds.

=item * sandbox - Name of the sandbox to evaluate the script in.  The sandbox is cached for later re-use on the same L<window|https://developer.mozilla.org/en-US/docs/Web/API/Window>object if C<new> is false.  If he parameter is undefined, the script is evaluated in a mutable sandbox.  If the parameter is "system", it will be evaluted in a sandbox with elevated system privileges, equivalent to chrome space.

=item * new - Forces the script to be evaluated in a fresh sandbox.  Note that if it is undefined, the script will normally be evaluted in a fresh sandbox.

=item * filename - Filename of the client's program where this script is evaluated.

=item * line - Line in the client's program where this script is evaluated.

=back

Returns the result of the javascript function.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    if ($firefox->script('return window.find("lucky");')) {
        # luckily!
    }

The executing javascript is subject to the L<script|Firefox::Marionette::Timeouts#script> timeout, which, by default is 30 seconds.

=head2 async_script 

accepts a scalar containing a javascript function that is executed in the browser.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

The executing javascript is subject to the L<script|Firefox::Marionette::Timeouts#script> timeout, which, by default is 30 seconds.

=head2 html

returns the page source of the content document.  This page source can be wrapped in html that firefox provides.  See the L<json|Firefox::Marionette#json> method for an alternative when dealing with response content types such as application/json and L<strip|Firefox::Marionette#strip> for an alterative when dealing with other non-html content types such as text/plain.

    use Firefox::Marionette();
    use v5.10;

    say Firefox::Marionette->new()->go('https://metacpan.org/')->html();

=head2 strip

returns the page source of the content document after an attempt has been made to remove typical firefox html wrappers of non html content types such as text/plain and application/json.  See the L<json|Firefox::Marionette#json> method for an alternative when dealing with response content types such as application/json and L<html|Firefox::Marionette#html> for an alterative when dealing with html content types.  This is a convenience method that wraps the L<html|Firefox::Marionette#html> method.

    use Firefox::Marionette();
    use JSON();
    use v5.10;

    say JSON::decode_json(Firefox::Marionette->new()->go('https://fastapi.metacpan.org/v1/download_url/Firefox::Marionette")->strip())->{version};

=head2 json

returns a L<JSON|JSON> object that has been parsed from the page source of the content document.  This is a convenience method that wraps the L<strip|Firefox::Marionette#strip> method.

    use Firefox::Marionette();
    use v5.10;

    say Firefox::Marionette->new()->go('https://fastapi.metacpan.org/v1/download_url/Firefox::Marionette")->json()->{version};

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

=head2 type

accepts an L<element|Firefox::Marionette::Element> as the first parameter and a string as the second parameter.  It sends the string to the specified L<element|Firefox::Marionette::Element> in the current page, such as filling out a text box. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 await

accepts a subroutine reference as a parameter and then executes the subroutine.  If a L<not found|Firefox::Marionette::Exception::NotFound> exception is thrown, this method will sleep for L<sleep_time_in_ms|Firefox::Marionette#sleep_time_in_ms> milliseconds and then execute the subroutine again.  When the subroutine executes successfully, it will return what the subroutine returns.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new(sleep_time_in_ms => 5)->go('https://metacpan.org/');

    $firefox->find_id('search-input')->type('Test::More');

    $firefox->find_name('lucky')->click();

    $firefox->await(sub { $firefox->interactive() && $firefox->find_partial('Download') })->click();

=head2 bye

accepts a subroutine reference as a parameter and then executes the subroutine.  If the subroutine executes successfully, this method will sleep for L<sleep_time_in_ms|Firefox::Marionette#sleep_time_in_ms> milliseconds and then execute the subroutine again.  When a L<not found|Firefox::Marionette::Exception::NotFound> exception is thrown, this method will return L<itself|Firefox::Marionette> to aid in chaining methods.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    $firefox->find_id('search-input')->type('Test::More');

    $firefox->find_name('lucky')->click();

    $firefox->bye(sub { $firefox->find_name('lucky') })->await(sub { $firefox->interactive() && $firefox->find_partial('Download') })->click();

=head2 sleep_time_in_ms

accepts a new time to sleep in L<await|Firefox::Marionette#await> or L<bye|Firefox::Marionette#bye> methods and returns the previous time.  The default time is "1" millisecond.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new(sleep_time_in_ms => 5); # setting default time to 5 milliseconds

    my $old_time_in_ms = $firefox->sleep_time_in_ms(8); # setting default time to 8 milliseconds, returning 5 (milliseconds)

=head2 is_displayed

accepts an L<element|Firefox::Marionette::Element> as the first parameter.  This method returns true or false depending on if the element is displayed.

=head2 is_enabled

accepts an L<element|Firefox::Marionette::Element> as the first parameter.  This method returns true or false depending on if the element is enabled.

=head2 is_selected

accepts an L<element|Firefox::Marionette::Element> as the first parameter.  This method returns true or false depending on if the element is selected.

=head2 active_element

returns the active element of the current browsing context's document element, if the document element is non-null.

=head2 back

causes the browser to traverse one step backward in the joint history of the current browsing context.  The browser will wait for the one step backward to complete or the session's L<page_load|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning, which, by default is 5 minutes.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 forward

causes the browser to traverse one step forward in the joint history of the current browsing context. The browser will wait for the one step forward to complete or the session's L<page_load|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning, which, by default is 5 minutes.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 active_frame

returns the current active L<frame|Firefox::Marionette::Element> if there is one in the current browsing context.  Otherwise, this method returns undef.

=head2 switch_to_shadow_root

accepts an L<element|Firefox::Marionette::Element> as a parameter and switches to it's L<shadow root|https://www.w3.org/TR/shadow-dom/>

=head2 switch_to_window

accepts a window handle (either the result of L<window_handles|Firefox::Marionette#window_handles> or a window name as a parameter and switches focus to this window.

=head2 switch_to_frame

accepts a L<frame|Firefox::Marionette::Element> as a parameter and switches to it within the current window.

=head2 switch_to_parent_frame

set the current browsing context for future commands to the parent of the current browsing context

=head2 new_window

accepts an optional hash as the parameter.  Allowed keys are below;

=over 4

=item * focus - a boolean field representing if the new window be opened in the foreground (focused) or background (not focused). Defaults to false.

=item * type - the type of the new window. Can be one of 'tab' or 'window'. Defaults to 'tab'.

=back

Returns the window handle for the new window.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new();

    my $window_handle = $firefox->new_window(type => 'tab');

    $firefox->switch_to_window($window_handle);

=head2 close_current_chrome_window_handle

closes the current chrome window (that is the entire window, not just the tabs).  It returns a list of still available chrome window handles. You will need to L<switch_to_window|Firefox::Marionette#switch_to_window> to use another window.

=head2 close_current_window_handle

closes the current window/tab.  It returns a list of still available window/tab handles.

=head2 full_screen

full screens the firefox window. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 minimise

minimises the firefox window. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 maximise

maximises the firefox window. This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 refresh

refreshes the current page.  The browser will wait for the page to completely refresh or the session's L<page_load|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning, which, by default is 5 minutes.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

=head2 alert_text

Returns the message shown in a currently displayed modal message box

=head2 dismiss_alert

dismisses a currently displayed modal message box

=head2 accept_alert

accepts a currently displayed modal message box

=head2 send_alert_text

sends keys to the input field of a currently displayed modal message box

=head2 capabilities

returns the L<capabilities|Firefox::Marionette::Capabilities> of the current firefox binary.  You can retrieve L<timeouts|Firefox::Marionette::Timeouts> or a L<proxy|Firefox::Marionette::Proxy> with this method.

=head2 screen_orientation

returns the current browser orientation.  This will be one of the valid primary orientation values 'portrait-primary', 'landscape-primary', 'portrait-secondary', or 'landscape-secondary'.  This method is only currently available on Android (Fennec).

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

accepts an optional L<position and size|Firefox::Marionette::Window::Rect> as a parameter, sets the current browser window to that position and size and returns the previous L<position, size and state|Firefox::Marionette::Window::Rect> of the browser window.  If no parameter is supplied, it returns the current  L<position, size and state|Firefox::Marionette::Window::Rect> of the browser window.

=head2 rect

accepts a L<element|Firefox::Marionette::Element> as the first parameter and returns the current L<position and size|Firefox::Marionette::Element::Rect> of the L<element|Firefox::Marionette::Element>

=head2 text

accepts a L<element|Firefox::Marionette::Element> as the first parameter and returns the text that is contained by that element (if any)

=head2 clear

accepts a L<element|Firefox::Marionette::Element> as the first parameter and clears any user supplied input

=head2 click

accepts a L<element|Firefox::Marionette::Element> as the first parameter and sends a 'click' to it.  The browser will wait for any page load to complete or the session's L<page_load|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning, which, by default is 5 minutes.

=head2 timeouts

returns the current L<timeouts|Firefox::Marionette::Timeouts> for page loading, searching, and scripts.

=head2 new_session

creates a new WebDriver session.  It is expected that the caller performs the necessary checks on the requested capabilities to be WebDriver conforming.  The WebDriver service offered by Marionette does not match or negotiate capabilities beyond type and bounds checks.

=head2 delete_session

deletes the current WebDriver session.

=head2 window_type

returns the current window's type.  This should be 'navigator:browser'.

=head2 window_handle

returns the current window's handle. On desktop this typically corresponds to the currently selected tab.  returns an opaque server-assigned identifier to this window that uniquely identifies it within this Marionette instance.  This can be used to switch to this window at a later point.

=head2 window_handles

returns a list of top-level browsing contexts. On desktop this typically corresponds to the set of open tabs for browser windows, or the window itself for non-browser chrome windows.  Each window handle is assigned by the server and is guaranteed unique, however the return array does not have a specified ordering.

=head2 accept_connections

Enables or disables accepting new socket connections.  By calling this method with false the server will not accept any further connections, but existing connections will not be forcible closed. Use true to re-enable accepting connections.

Please note that when closing the connection via the client you can end-up in a non-recoverable state if it hasn't been enabled before.

=head2 current_chrome_window_handle 

see L<chrome_window_handle|Firefox::Marionette#chrome_window_handle>.

=head2 chrome_window_handle

returns an server-assigned integer identifiers for the current chrome window that uniquely identifies it within this Marionette instance.  This can be used to switch to this window at a later point. This corresponds to a window that may itself contain tabs.

=head2 chrome_window_handles

returns identifiers for each open chrome window for tests interested in managing a set of chrome windows and tabs separately.

=head2 install

accepts the fully qualified path to an .xpi addon file as the first parameter and an optional true/false second parameter to indicate if the xpi addon file should be a temporary addition (just for the existance of this browser instance).  Unsigned xpi addon files may be loaded temporarily.  It returns the GUID for the addon which may be used as a parameter to the L<uninstall|Firefox::Marionette#uninstall> method.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new();

    my $extension_id = $firefox->install('/full/path/to/gnu_terry_pratchett-0.4-an+fx.xpi');

=head2 uninstall

accepts the GUID for the addon to uninstall.  The GUID is returned when from the L<install|Firefox::Marionette#install> method.  This method returns L<itself|Firefox::Marionette> to aid in chaining methods.

    use Firefox::Marionette();

    my $firefox = Firefox::Marionette->new();

    my $extension_id = $firefox->install('/full/path/to/gnu_terry_pratchett-0.4-an+fx.xpi');

    # do something

    $firefox->uninstall($extension_id); # not recommended to uninstall this extension IRL.

=head2 application_type

returns the application type for the Marionette protocol.  Should be 'gecko'.

=head2 marionette_protocol

returns the version for the Marionette protocol.  Current most recent version is '3'.

=head2 addons

returns if pre-existing addons (extensions/themes) are allowed to run.  This will be true for Firefox versions less than 55, as -safe-mode cannot be automated.

=head2 xvfb

returns the pid of the xvfb process if it exists.

=head2 quit

Marionette will stop accepting new connections before ending the current session, and finally attempting to quit the application.  This method returns the $? (CHILD_ERROR) value for the Firefox process

=head2 browser_version

This method returns version of firefox.

=head2 execute

This utility method executes a command with arguments and returns STDOUT as a chomped string.  It is a simple method only intended for the Firefox::Marionette::* modules.

=head2 child_error

This method returns the $? (CHILD_ERROR) for the Firefox process, or undefined if the process has not yet exited.

=head2 error_message

This method returns a human readable error message describing how the Firefox process exited (assuming it started okay).  On Win32 platforms this information is restricted to exit code.

=head2 alive

This method returns true or false depending on if the Firefox process is still running.

=head1 DIAGNOSTICS

=over
 
=item C<< Failed to correctly setup the Firefox process >>

The module was unable to retrieve a session id and capabilities from Firefox when it requests a L<new_session|Firefox::Marionette#new_session> as part of the initial setup of the connection to Firefox.

=item C<< Failed to correctly determined the Firefox process id through the initial connection capabilities >>
 
The module was found that firefox is reporting through it's L<Capabilities|Firefox::Marionette::Capabilities#moz_process_id> object a different process id than this module was using.  This is probably a bug in this module's logic.  Please report as described in the BUGS AND LIMITATIONS section below.
 
=item C<< '%s --version' did not produce output that looks like 'Mozilla Firefox \\d+[.]\\d+([.]\\d+)?':%s >>
 
The Firefox binary did not produce a version number that could be recognised as a Firefox version number.
 
=item C<< Failed to create process from '%s':%s >>
 
The module was to start Firefox process in a Win32 environment.  Something is seriously wrong with your environment.
 
=item C<< Failed to redirect %s to %s:%s >>
 
The module was unable to redirect a file handle's output.  Something is seriously wrong with your environment.
 
=item C<< Failed to exec %s:%s >>
 
The module was unable to run the Firefox binary.  Check the path is correct and the current user has execute permissions.
 
=item C<< Failed to fork:%s >>
 
The module was unable to fork itself, prior to executing a command.  Check the current C<ulimit> for max number of user processes.
 
=item C<< Failed to open directory '%s':%s >>
 
The module was unable to open a directory.  Something is seriously wrong with your environment.
 
=item C<< Failed to close directory '%s':%s >>
 
The module was unable to close a directory.  Something is seriously wrong with your environment.
 
=item C<< Failed to open '%s' for writing:%s >>
 
The module was unable to create a file in your temporary directory.  Maybe your disk is full?
 
=item C<< Failed to open temporary file for writing:%s >>
 
The module was unable to create a file in your temporary directory.  Maybe your disk is full?
 
=item C<< Failed to close '%s':%s >>
 
The module was unable to close a file in your temporary directory.  Maybe your disk is full?
 
=item C<< Failed to close temporary file:%s >>
 
The module was unable to close a file in your temporary directory.  Maybe your disk is full?
 
=item C<< Failed to create temporary directory:%s >>
 
The module was unable to create a directory in your temporary directory.  Maybe your disk is full?
 
=item C<< Failed to clear the close-on-exec flag on a temporary file:%s >>
 
The module was unable to call fcntl using F_SETFD for a file in your temporary directory.  Something is seriously wrong with your environment.
 
=item C<< Failed to seek to start of temporary file:%s >>
 
The module was unable to seek to the start of a file in your temporary directory.  Something is seriously wrong with your environment.
 
=item C<< Failed to create a socket:%s >>
 
The module was unable to even create a socket.  Something is seriously wrong with your environment.
 
=item C<< Failed to connect to %s on port %d:%s >>
 
The module was unable to connect to the Marionette port.  This is probably a bug in this module's logic.  Please report as described in the BUGS AND LIMITATIONS section below.
 
=item C<< Firefox killed by a %s signal (%d) >>
 
Firefox crashed after being hit with a signal.  
 
=item C<< Firefox exited with a %d >>
 
Firefox has exited with an error code
 
=item C<< Failed to bind socket:%s >>
 
The module was unable to bind a socket to any port.  Something is seriously wrong with your environment.
 
=item C<< Failed to close random socket:%s >>
 
The module was unable to close a socket without any reads or writes being performed on it.  Something is seriously wrong with your environment.
 
=item C<< moz:headless has not been determined correctly >>
 
The module was unable to correctly determine whether Firefox is running in "headless" or not.  This is probably a bug in this module's logic.  Please report as described in the BUGS AND LIMITATIONS section below.
 
=item C<< %s method requires a Firefox::Marionette::Element parameter >>
 
This function was called incorrectly by your code.  Please supply a L<Firefox::Marionette::Element|Firefox::Marionette::Element> parameter when calling this function.
 
=item C<< Failed to write to temporary file:%s >>
 
The module was unable to write to a file in your temporary directory.  Maybe your disk is full?

=item C<< Failed to close socket to firefox:%s >>
 
The module was unable to even close a socket.  Something is seriously wrong with your environment.
 
=item C<< Failed to send request to firefox:%s >>
 
The module was unable to perform a syswrite on the socket connected to firefox.  Maybe firefox crashed?
 
=item C<< Failed to read size of response from socket to firefox:%s >>
 
The module was unable to read from the socket connected to firefox.  Maybe firefox crashed?
 
=item C<< Failed to read response from socket to firefox:%s >>
 
The module was unable to read from the socket connected to firefox.  Maybe firefox crashed?
 
=back

=head1 CONFIGURATION AND ENVIRONMENT

Firefox::Marionette requires no configuration files or environment variables.  It will however use the DISPLAY and XAUTHORITY environment variables to try to connect to an X Server.
It will also use the HTTP_PROXY, HTTPS_PROXY, FTP_PROXY and ALL_PROXY environment variables as defaults if the session L<capabilities|Firefox::Marionette::Capabilities> do not specify proxy information.

=head1 DEPENDENCIES

Firefox::Marionette requires the following non-core Perl modules
 
=over
 
=item *
L<JSON|JSON>
 
=item *
L<URI|URI>
 
=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Currently the following Marionette methods have not been implemented;

=over
 
=item * WebDriver:ReleaseAction

=item * WebDriver:PerformActions

=item * WebDriver:SetScreenOrientation

=back

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-firefox-marionette@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over

=item *
L<MozRepl|MozRepl>

=item *
L<Selenium::Firefox|Selenium::Firefox>

=item *
L<Firefox::Application|Firefox::Application>

=item *
L<Mozilla::Mechanize|Mozilla::Mechanize>

=item *
L<Gtk2::MozEmbed|Gtk2::MozEmbed>

=back

=head1 AUTHOR

David Dick  C<< <ddick@cpan.org> >>

=head1 ACKNOWLEDGEMENTS
 
Thanks to the entire Mozilla organisation for a great browser and to the team behind Marionette for providing an interface for automation.
 
Thanks also to the authors of the documentation in the following sources;

=over 4

=item * L<Marionette Protocol|https://firefox-source-docs.mozilla.org/testing/marionette/marionette/index.html>

=item * L<Marionette Documentation|https://firefox-source-docs.mozilla.org/testing/marionette/marionette/index.html>

=item * L<Marionette driver.js at github|https://github.com/mozilla/gecko-dev/blob/master/testing/marionette/driver.js>

=item * L<about:config|http://kb.mozillazine.org/About:config_entries>

=item * L<nsIPrefService interface|https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsIPrefService>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019, David Dick C<< <ddick@cpan.org> >>. All rights reserved.

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
