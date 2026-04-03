package Developer::Dashboard::PageRuntime;

use strict;
use warnings;

our $VERSION = '1.33';

use Capture::Tiny qw(capture);
use DataHelper qw(j je);
use IO::Select;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Developer::Dashboard::PageRuntime::StreamHandle;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::RuntimeManager ();
use Folder ();
use Template;
use Zipper qw(Ajax acmdx zip unzip);

my $SANDPIT_SEQ = 0;

# new(%args)
# Constructs the legacy-style page runtime used by browser-rendered bookmarks.
# Input: optional path registry and folder alias data.
# Output: Developer::Dashboard::PageRuntime object.
sub new {
    my ( $class, %args ) = @_;
    return bless {
        files   => $args{files},
        paths   => $args{paths},
        aliases => $args{aliases} || {},
    }, $class;
}

# prepare_page(%args)
# Executes legacy CODE blocks, then applies Template Toolkit rendering.
# Input: page document, source kind, and runtime context hash.
# Output: updated page document object.
sub prepare_page {
    my ( $self, %args ) = @_;
    $self = __PACKAGE__->new if !ref($self);
    my $page   = $args{page} || die 'Missing page';
    my $source = $args{source} || 'saved';
    my $runtime_context = $args{runtime_context} || {};

    my $runtime = $self->run_code_blocks(
        page            => $page,
        source          => $source,
        runtime_context => $runtime_context,
    );

    $page->{meta}{runtime_outputs} = $runtime->{outputs};
    $page->{meta}{runtime_errors}  = $runtime->{errors};
    $self->_render_templates(
        page            => $page,
        runtime_context => $runtime_context,
    );
    return $page;
}

# run_code_blocks(%args)
# Executes CODE sections and returns captured stdout/stderr display chunks.
# Input: page document, source kind, and runtime context hash.
# Output: hash reference with outputs and errors arrays.
sub run_code_blocks {
    my ( $self, %args ) = @_;
    $self = __PACKAGE__->new if !ref($self);
    my $page   = $args{page} || die 'Missing page';
    my $codes  = $page->as_hash->{meta}{codes} || [];
    my $state  = $page->{state} || {};

    return { outputs => [], errors => [] } if ref($codes) ne 'ARRAY' || !@$codes;

    my @outputs;
    my @errors;
    my $sandpit = $self->_new_sandpit(
        state           => $state,
        runtime_context => $args{runtime_context} || {},
    );

    eval {
        CODE:
        for my $block (@$codes) {
            next if ref($block) ne 'HASH';
            my $code = $block->{body} // '';
            next if $code eq '';

            my $result = eval {
                $self->_run_single_block(
                    code            => $code,
                    page            => $page,
                    sandpit         => $sandpit,
                    source          => $args{source} || '',
                    state           => $state,
                    runtime_context => $args{runtime_context} || {},
                );
            };

            if ($@) {
                my $error = "$@";
                if ( $error =~ /^__DD_HIDE__/ ) {
                    next CODE;
                }
                if ( $error =~ /^__DD_STOP__(?:\n(.*))?/s ) {
                    push @errors, $1 if defined $1 && $1 ne '';
                    last CODE;
                }
                push @errors, $error;
                last CODE;
            }

            if ( ref( $result->{merge} ) eq 'HASH' ) {
                $page->merge_state( $result->{merge} );
                $state = $page->{state};
            }

            if ( ref( $result->{returns} ) eq 'ARRAY' ) {
                for my $value ( @{ $result->{returns} } ) {
                    if ( ref($value) eq 'HASH' ) {
                        $page->merge_state($value);
                        $state = $page->{state};
                    }
                    next if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
                    push @outputs, $self->_runtime_value_text($value);
                }
            }

            my $stdout = defined $result->{stdout} ? $result->{stdout} : '';
            my $stderr = defined $result->{stderr} ? $result->{stderr} : '';

            push @outputs, $stdout if $stdout ne '';
            push @errors, $stderr if $stderr ne '';
        }
        1;
    };

    $self->_destroy_sandpit($sandpit);

    return {
        outputs => \@outputs,
        errors  => \@errors,
    };
}

# _runtime_value_text($value)
# Serializes a returned runtime value for in-page output after CODE execution.
# Input: returned Perl scalar reference from a CODE block.
# Output: Perl-ish text string.
sub _runtime_value_text {
    my ( $self, $value ) = @_;
    return '' if !defined $value;
    return '' if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return _runtime_legacy_value($value);
}

# _render_templates(%args)
# Processes legacy HTML and FORM.TT sections through Template Toolkit.
# Input: page document and runtime context hash.
# Output: none; mutates page layout in place.
sub _render_templates {
    my ( $self, %args ) = @_;
    my $page = $args{page} || die 'Missing page';
    my $layout = $page->{layout} || {};
    my $state  = $page->{state}  || {};
    my $request_context = $page->{meta}{request_context} || {};
    my $current_page = $args{runtime_context}{current_page} || $request_context->{path} || '';
    my %template_runtime = (
        %{ $args{runtime_context} || {} },
        current_page => $current_page,
    );
    my %template_env = (
        %ENV,
        current_page    => $current_page,
        runtime_context => \%template_runtime,
    );

    my $system = $self->_system_context(%args);
    my $tt = Template->new(
        {
            EVAL_PERL   => 1,
            INCLUDE_PATH => $self->{paths} ? $self->{paths}->dashboards_root : '.',
        }
    );

    for my $field ( qw(body form_tt) ) {
        my $template = $layout->{$field};
        next if !defined $template || $template eq '';
        my $rendered = '';
        my $page_data = $page->as_hash;
        my $ok = $tt->process(
            \$template,
            {
                app    => $page,
                parts  => $page,
                page   => $page_data,
                stash  => $state,
                id     => $page_data->{id},
                title  => $page_data->{title},
                description => $page_data->{description},
                mode   => $page_data->{mode},
                icon   => $page_data->{icon},
                ENV    => \%template_env,
                SYSTEM => $system,
                env    => \%template_env,
                func   => sub { return '' },
                method => sub {
                    my ( $class, $method, @rest ) = @_;
                    return '' if !$class || !$method || !$class->can($method);
                    return $class->$method(@rest);
                },
                eval => sub {
                    my ($code) = @_;
                    my $result = $self->_run_single_block(
                        code            => $code,
                        page            => $page,
                        source          => $args{source} || '',
                        state           => $state,
                        runtime_context => $args{runtime_context} || {},
                    );
                    die $result->{stderr} if defined $result->{stderr} && $result->{stderr} ne '';
                    return $result->{stdout};
                },
                %$state,
            },
            \$rendered,
        );

        if ($ok) {
            $page->{layout}{$field} = $rendered;
            next;
        }

        push @{ $page->{meta}{runtime_errors} ||= [] }, $tt->error;
    }

    if ( defined $layout->{form} && $layout->{form} ne '' ) {
        my $form = $layout->{form};
        $form =~ s/\[\%([\w\_]+)\%\]/_escape_html($page->{$1})/ge;
        $form =~ s/\[\#([\w\_]+)\#\]/_escape_html($state->{$1})/ge;
        if ( ref( $args{runtime_context}{params} ) eq 'HASH' ) {
            $form =~ s/\{\{([\w\_\-]+)\}\}/_escape_html($args{runtime_context}{params}{$1})/ge;
        }
        $page->{layout}{form} = $form;
    }
}

# _system_context(%args)
# Builds the generic SYSTEM hash exposed to bookmark Template Toolkit rendering.
# Input: runtime context hash.
# Output: hash reference of generic runtime/system values.
sub _system_context {
    my ( $self, %args ) = @_;
    return {
        cwd    => $args{runtime_context}{cwd} || '.',
        source => $args{source} || '',
        params => $args{runtime_context}{params} || {},
    };
}

# _run_single_block(%args)
# Executes one CODE block inside the active legacy sandpit package.
# Input: Perl code string, mutable stash hash, runtime context hash, and optional sandpit hash.
# Output: hash reference with stdout, stderr, returns, and merged stash.
sub _run_single_block {
    my ( $self, %args ) = @_;
    my $code            = $args{code} // '';
    my $state           = $args{state} || {};
    my $runtime         = $args{runtime_context} || {};
    my $sandpit         = $args{sandpit};
    my $destroy_sandpit = !$sandpit ? 1 : 0;

    Folder->configure(
        paths   => $self->{paths},
        aliases => $self->{aliases},
    );
    $sandpit ||= $self->_new_sandpit(
        state           => $state,
        runtime_context => $runtime,
    );

    my $package = $sandpit->{package} || die 'Missing sandpit package';
    my $wrapped_code = $self->_code_header($state) . $code;
    my @returns;
    local $Zipper::AJAX_CONTEXT = {
        allow_transient_urls => (
            defined $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS}
              && $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} =~ /\A(?:1|true|yes|on)\z/i
        ) ? 1 : 0,
        page_id      => $args{page} && ref( $args{page} ) ? ( $args{page}->as_hash->{id} || '' ) : '',
        runtime_root => $self->{paths} ? $self->{paths}->runtime_root : '',
        source       => $args{source} || '',
    };
    my ( $stdout, $stderr, $exit_code ) = capture {
        @returns = $package->__run_code($wrapped_code);
        return $?;
    };
    my @errors = $package->__errors();
    if (@errors) {
        my $error = join '', grep { defined $_ && $_ ne '' } @errors;
        $self->_destroy_sandpit($sandpit) if $destroy_sandpit;
        die $error if $error ne '';
    }

    $self->_destroy_sandpit($sandpit) if $destroy_sandpit;

    return {
        stdout  => $stdout,
        stderr  => $stderr,
        returns => \@returns,
        merge   => $state,
    };
}

# stream_code_block(%args)
# Executes one CODE block and streams stdout/stderr chunks through callbacks.
# Input: Perl code string, mutable stash hash, runtime context hash, page/source metadata, and writer callbacks.
# Output: hash reference with streamed return values, merged stash, and trailing error text.
sub stream_code_block {
    my ( $self, %args ) = @_;
    my $code            = $args{code} // '';
    my $state           = $args{state} || {};
    my $runtime         = $args{runtime_context} || {};
    my $sandpit         = $args{sandpit};
    my $destroy_sandpit = !$sandpit ? 1 : 0;
    my $stdout_writer   = $args{stdout_writer} || \&_noop_writer;
    my $stderr_writer   = $args{stderr_writer} || \&_noop_writer;

    Folder->configure(
        paths   => $self->{paths},
        aliases => $self->{aliases},
    );
    $sandpit ||= $self->_new_sandpit(
        state           => $state,
        runtime_context => $runtime,
    );

    my $package = $sandpit->{package} || die 'Missing sandpit package';
    my $wrapped_code = $self->_code_header($state) . $code;
    my @returns;
    local $Zipper::AJAX_CONTEXT = {
        allow_transient_urls => (
            defined $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS}
              && $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} =~ /\A(?:1|true|yes|on)\z/i
        ) ? 1 : 0,
        page_id      => $args{page} && ref( $args{page} ) ? ( $args{page}->as_hash->{id} || '' ) : '',
        runtime_root => $self->{paths} ? $self->{paths}->runtime_root : '',
        source       => $args{source} || '',
    };

    tie *STDOUT, 'Developer::Dashboard::PageRuntime::StreamHandle', writer => $stdout_writer;
    tie *STDERR, 'Developer::Dashboard::PageRuntime::StreamHandle', writer => $stderr_writer;
    local $| = 1;
    my $old_stderr = select STDERR;
    $| = 1;
    select $old_stderr;
    @returns = $package->__run_code($wrapped_code);
    untie *STDOUT;
    untie *STDERR;

    my @errors = $package->__errors();
    my $error = join '', grep { defined $_ && $_ ne '' } @errors;

    if ( ref( $args{return_writer} ) eq 'CODE' ) {
        for my $value (@returns) {
            next if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
            $args{return_writer}->( $self->_runtime_value_text($value) );
        }
    }

    $self->_destroy_sandpit($sandpit) if $destroy_sandpit;

    return {
        returns => \@returns,
        merge   => $state,
        error   => $error,
    };
}

# stream_saved_ajax_file(%args)
# Executes one saved Ajax file as a real process and streams stdout/stderr chunks through callbacks.
# Input: saved file path, request params hash, optional singleton name, page/source metadata, and writer callbacks.
# Output: hash reference with exit_code and process status word.
sub stream_saved_ajax_file {
    my ( $self, %args ) = @_;
    my $path          = $args{path} || die 'Missing saved ajax file path';
    my $params        = $args{params} || {};
    my $stdout_writer = $args{stdout_writer} || \&_noop_writer;
    my $stderr_writer = $args{stderr_writer} || \&_noop_writer;
    my $singleton     = $self->_normalize_saved_ajax_singleton( $params->{singleton} );
    $self->_kill_saved_ajax_singleton($singleton) if $singleton ne '';
    my @command       = $self->_saved_ajax_command( path => $path );
    my %env           = $self->_saved_ajax_env(
        path      => $path,
        page      => $args{page} || '',
        type      => $args{type} || '',
        params    => $params,
        singleton => $singleton,
    );

    my $stdout = gensym;
    my $stderr = gensym;
    my $stdin  = gensym;
    my $pid = eval {
        local %ENV = ( %ENV, %env );
        open3( $stdin, $stdout, $stderr, @command );
    };
    die $@ if $@;
    close $stdin;

    my $select = IO::Select->new( $stdout, $stderr );
    my $stream_error = '';
    my $disconnected = 0;
    eval {
        while (1) {
            my @ready = $select->can_read(0.25);
            last if !@ready && !$select->count;
            for my $fh (@ready) {
                my $continued = $self->_drain_saved_ajax_ready_handle(
                    fh            => $fh,
                    path          => $path,
                    select        => $select,
                    stdout        => $stdout,
                    stdout_writer => $stdout_writer,
                    stderr_writer => $stderr_writer,
                );
                if ( !$continued ) {
                    $disconnected = 1;
                    die "__DD_AJAX_STREAM_DISCONNECTED__\n";
                }
            }
        }
        1;
    } or do {
        $stream_error = $@ || "Saved ajax stream failed\n";
    };

    $self->_close_saved_ajax_streams( $select, $stdout, $stderr );
    if ($disconnected) {
        $self->_terminate_saved_ajax_process($pid);
    }
    elsif ( $stream_error ne '' ) {
        $self->_terminate_saved_ajax_process($pid);
        die $stream_error if !$self->_looks_like_stream_disconnect_error($stream_error);
    }
    waitpid( $pid, 0 );
    return {
        disconnected => $disconnected ? 1 : 0,
        exit_code => $? >> 8,
        status    => $?,
    };
}

# _noop_writer(@parts)
# Accepts streamed output chunks when the caller does not need them.
# Input: zero or more ignored chunk parts.
# Output: empty string.
sub _noop_writer { return '' }

# _drain_saved_ajax_ready_handle(%args)
# Reads one ready saved-Ajax process pipe handle and forwards the chunk or error to the right writer.
# Input: ready fh, active select set, stdout fh, saved file path, and writer callbacks.
# Output: true value when streaming should continue, otherwise false when the client disconnected.
sub _drain_saved_ajax_ready_handle {
    my ( $self, %args ) = @_;
    my $fh            = $args{fh}            || die 'Missing ready handle';
    my $path          = $args{path}          || '';
    my $select        = $args{select}        || die 'Missing select set';
    my $stdout        = $args{stdout}        || die 'Missing stdout handle';
    my $stdout_writer = $args{stdout_writer} || \&_noop_writer;
    my $stderr_writer = $args{stderr_writer} || \&_noop_writer;
    my $chunk = '';
    my $bytes = $self->_stream_sysread( $fh, \$chunk );
    if ( !defined $bytes ) {
        return 1 if $!{EINTR};
        $stderr_writer->("Unable to read ajax stream for $path: $!\n");
        $select->remove($fh);
        close $fh;
        return 1;
    }
    if ( $bytes == 0 ) {
        $select->remove($fh);
        close $fh;
        return 1;
    }
    my $ready_fileno  = fileno($fh);
    my $stdout_fileno = fileno($stdout);
    if ( defined $ready_fileno && defined $stdout_fileno && $ready_fileno == $stdout_fileno ) {
        my $continued = $stdout_writer->($chunk);
        return defined $continued ? $continued : 1;
    }
    my $continued = $stderr_writer->($chunk);
    return defined $continued ? $continued : 1;
}

# _close_saved_ajax_streams($select, @handles)
# Closes the saved-Ajax select set and any remaining pipe handles after streaming stops.
# Input: IO::Select object plus zero or more pipe handles.
# Output: true value.
sub _close_saved_ajax_streams {
    my ( $self, $select, @handles ) = @_;
    if ( $select && eval { $select->can('handles') } ) {
        for my $fh ( $select->handles ) {
            next if !defined fileno($fh);
            $select->remove($fh);
            close $fh;
        }
    }
    for my $fh (@handles) {
        next if !defined $fh;
        next if !defined fileno($fh);
        close $fh;
    }
    return 1;
}

# _terminate_saved_ajax_process($pid)
# Stops one saved-Ajax worker process after stream cancellation or writer failure.
# Input: child process id integer.
# Output: true value.
sub _terminate_saved_ajax_process {
    my ( $self, $pid ) = @_;
    return 1 if !$pid;
    return 1 if !kill 0, $pid;
    kill 'TERM', $pid;
    for ( 1 .. 20 ) {
        return 1 if !kill 0, $pid;
        sleep 0.05;
    }
    kill 'KILL', $pid if kill 0, $pid;
    return 1;
}

# _looks_like_stream_disconnect_error($error)
# Detects writer failures that mean the browser stream was closed and the worker should just be stopped.
# Input: raw exception text from one writer callback.
# Output: boolean true when the error matches a disconnect or closed-stream condition.
sub _looks_like_stream_disconnect_error {
    my ( $self, $error ) = @_;
    return 1 if !defined $error || $error eq '';
    return 1 if $error =~ /^__DD_AJAX_STREAM_DISCONNECTED__/;
    return $error =~ /(broken pipe|client disconnected|connection reset|stream closed|connection aborted|write failed|closed handle)/i ? 1 : 0;
}

# _stream_sysread($fh, $chunk_ref)
# Reads one chunk from a saved-Ajax process pipe.
# Input: fh and scalar reference that receives the read chunk.
# Output: byte count or undef on read error.
sub _stream_sysread {
    my ( $self, $fh, $chunk_ref ) = @_;
    return sysread( $fh, ${$chunk_ref}, 8192 );
}

# _saved_ajax_command(%args)
# Resolves the process command used to execute one saved Ajax file.
# Input: saved file path.
# Output: command list suitable for open3.
sub _saved_ajax_command {
    my ( $self, %args ) = @_;
    my $path = $args{path} || die 'Missing saved ajax file path';
    open my $fh, '<', $path or die "Unable to read saved ajax file $path: $!";
    my $first_line = <$fh>;
    close $fh;
    return ($path) if defined $first_line && $first_line =~ /^#!/;
    return ( 'sh', $path ) if $path =~ /\.(?:sh|bash)\z/;
    return ( 'python3', $path ) if $path =~ /\.py\z/;
    return ( $^X, '-e', $self->_saved_ajax_perl_wrapper, $path );
}

# _saved_ajax_env(%args)
# Builds the environment variables exposed to one saved Ajax process run.
# Input: saved file path, page id, type, optional singleton name, and request params hash.
# Output: hash of environment key/value pairs.
sub _saved_ajax_env {
    my ( $self, %args ) = @_;
    my $params = ref( $args{params} ) eq 'HASH' ? $args{params} : {};
    return (
        DEVELOPER_DASHBOARD_AJAX_FILE   => $args{path} || '',
        DEVELOPER_DASHBOARD_AJAX_PAGE   => $args{page} || '',
        DEVELOPER_DASHBOARD_AJAX_SINGLETON => $self->_normalize_saved_ajax_singleton( $args{singleton} ),
        DEVELOPER_DASHBOARD_AJAX_TYPE   => $args{type} || '',
        DEVELOPER_DASHBOARD_AJAX_PARAMS => json_encode($params),
        QUERY_STRING                    => _query_string_from_params($params),
        REQUEST_METHOD                  => 'GET',
    );
}

# _normalize_saved_ajax_singleton($singleton)
# Validates one saved-Ajax singleton identifier before it is exposed to the process layer.
# Input: optional singleton string.
# Output: normalized singleton string or an empty string.
sub _normalize_saved_ajax_singleton {
    my ( $self, $singleton ) = @_;
    return '' if !defined $singleton || $singleton eq '';
    die "Invalid ajax singleton name\n" if $singleton =~ /[[:cntrl:]]/;
    return $singleton;
}

# _kill_saved_ajax_singleton($singleton)
# Terminates older saved-Ajax Perl workers that share one singleton identifier.
# Input: validated singleton string.
# Output: true value.
sub _kill_saved_ajax_singleton {
    my ( $self, $singleton ) = @_;
    return 1 if !defined $singleton || $singleton eq '';
    my $pattern = '^dashboard ajax: ' . $self->_quote_process_pattern_literal($singleton) . '$';
    Developer::Dashboard::RuntimeManager->_pkill_perl($pattern);
    return 1;
}

# _quote_process_pattern_literal($text)
# Escapes one literal string so it is safe for both pkill regex matching and Perl fallback matching.
# Input: untrusted literal string.
# Output: regex-safe literal string.
sub _quote_process_pattern_literal {
    my ( $self, $text ) = @_;
    $text =~ s/([\\.^$|(){}\[\]*+?])/\\$1/g;
    return $text;
}

# _query_string_from_params($params)
# Serializes flat Ajax params back into a URL query string for child process environment use.
# Input: flat hash reference of request params.
# Output: URL-encoded query string.
sub _query_string_from_params {
    my ($params) = @_;
    return '' if ref($params) ne 'HASH' || !%{$params};
    require URI::Escape;
    return join '&',
      map {
          URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape( defined $params->{$_} ? $params->{$_} : '' )
      } sort keys %{$params};
}

# _saved_ajax_perl_wrapper()
# Builds the Perl bootstrap source used for saved Ajax files without a shebang.
# Input: none.
# Output: Perl source string.
sub _saved_ajax_perl_wrapper {
    return <<'PERL';
use strict;
use warnings;
use DataHelper qw(j je);
use Developer::Dashboard::JSON qw(json_decode);
use Zipper qw(Ajax acmdx zip unzip);
my $old_stdout = select STDOUT;
$| = 1;
select STDERR;
$| = 1;
select $old_stdout;

our $AJAX_STASH = {};
our $AJAX_PARAMS = eval { json_decode( $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS} || '{}' ) };
$AJAX_PARAMS = {} if ref($AJAX_PARAMS) ne 'HASH';
my $singleton = $ENV{DEVELOPER_DASHBOARD_AJAX_SINGLETON} || '';
$0 = "dashboard ajax: $singleton" if $singleton ne '';

sub stash {
    my ($input) = @_;
    die "no input" if !defined $input;
    if ( ref($input) eq 'HASH' ) {
        @{$AJAX_STASH}{ keys %{$input} } = values %{$input};
        return $input;
    }
    return $AJAX_STASH->{$input};
}

sub hide {
    my ($input) = @_;
    stash($input) if ref($input) eq 'HASH';
    return "__DD_HIDE__";
}

sub void {
    my ($input) = @_;
    stash($input) if defined $input;
    return;
}

sub stop {
    my ($message) = @_;
    die defined $message ? $message : '';
}

sub params {
    return $AJAX_PARAMS;
}

my $file = shift @ARGV;
open my $fh, '<', $file or die "Unable to read $file: $!";
local $/;
my $code = <$fh>;
close $fh;
eval "{ $code }";
die $@ if $@;
PERL
}

# _code_header($state)
# Builds the legacy lexical stash header injected before each CODE block.
# Input: mutable stash hash reference.
# Output: Perl source string.
sub _code_header {
    my ( $self, $state ) = @_;
    $state ||= {};

    my @keys = grep { /^[A-Za-z_][A-Za-z0-9_]*$/ } sort keys %$state;
    return '' if !@keys;

    my $header = sprintf 'my (%s) = @{ $stash }{qw(%s)};' . "\n",
      join( ', ', map { '$' . $_ } @keys ),
      join( ' ', @keys );
    $header .= sprintf 'my (%s) = map { \\$stash->{$_} } qw(%s);' . "\n",
      join( ', ', map { '$' . $_ . '_r' } @keys ),
      join( ' ', @keys );
    return $header;
}

# _new_sandpit(%args)
# Creates one throwaway package used across CODE blocks for a single page run.
# Input: mutable stash hash reference and runtime context hash.
# Output: hash reference containing the generated package name.
sub _new_sandpit {
    my ( $self, %args ) = @_;
    my $package = sprintf 'Developer::Dashboard::Sandpit::%d::%d::%d', $$, time, ++$SANDPIT_SEQ;
    $package =~ s/[^A-Za-z0-9:]/_/g;

    my $compiled = <<"PERL";
package $package;
use strict;
use warnings;
use DataHelper qw(j je);
use Zipper qw(Ajax acmdx zip unzip);

our \$stash = {};
our \$runtime = {};
our \@errors = ();

sub __add_error {
    push \@errors, grep { defined \$_ && \$_ ne '' } \@_;
}

sub __errors {
    my \@copy = \@errors;
    \@errors = ();
    return \@copy;
}

sub stash {
    my (\$input) = \@_;
    die "no input" if !defined \$input;
    if (ref(\$input) eq 'HASH') {
        \@{\$stash}{keys %\$input} = values %\$input;
        return \$input;
    }
    return \$stash->{\$input};
}

sub hide {
    my (\$input) = \@_;
    stash(\$input) if ref(\$input) eq 'HASH';
    return "__DD_HIDE__";
}

sub void {
    my (\$input) = \@_;
    stash(\$input) if defined \$input;
    return;
}

sub stop {
    my (\$message) = \@_;
    die "__DD_STOP__\\n" . (defined \$message ? \$message : '');
}

sub params {
    return \$runtime->{params} || {};
}

sub __initial_context {
    my (\$class, \$next_stash, \$next_runtime) = \@_;
    \$stash = \$next_stash || {};
    \$runtime = \$next_runtime || {};
    \@errors = ();
    return 1;
}

sub __run_code {
    my (\$class, \$code) = \@_;
    my \@result = eval "{\$code}";
    __add_error(\$@) if \$@;
    return \@result;
}

1;
PERL
    my $ok = eval $compiled;
    die "Unable to setup sandpit $@\n" if !$ok;

    $package->__initial_context(
        $args{state} || {},
        $args{runtime_context} || {},
    );

    return { package => $package };
}

# _destroy_sandpit($sandpit)
# Clears the generated sandpit package to avoid runtime symbol leakage across page runs.
# Input: sandpit hash reference created by _new_sandpit.
# Output: none.
sub _destroy_sandpit {
    my ( $self, $sandpit ) = @_;
    return if ref($sandpit) ne 'HASH' || !$sandpit->{package};
    my $stash = $sandpit->{package};
    no strict 'refs';
    %{"${stash}::"} = ();
    return;
}

# _escape_html($text)
# Escapes scalar text for safe HTML interpolation in legacy FORM blocks.
# Input: text scalar.
# Output: escaped text scalar.
sub _escape_html {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    return $text;
}

# _runtime_legacy_value($value)
# Serializes a Perl scalar, array, or hash into a Perl-ish runtime text form.
# Input: scalar, array reference, or hash reference.
# Output: Perl-ish text string.
sub _runtime_legacy_value {
    my ($value) = @_;
    return 'undef' if !defined $value;
    if ( ref($value) eq 'ARRAY' ) {
        return "[\n  " . join( ",\n  ", map { _runtime_legacy_value($_) } @$value ) . "\n]";
    }
    if ( ref($value) eq 'HASH' ) {
        return "{\n  " . join( ",\n  ", map { sprintf "%s => %s", $_, _runtime_legacy_value( $value->{$_} ) } sort keys %$value ) . "\n}";
    }
    return $value =~ /\A-?\d+(?:\.\d+)?\z/ ? $value : "'" . _runtime_legacy_quote($value) . "'";
}

# _runtime_legacy_quote($text)
# Escapes a scalar string for runtime Perl-ish single-quoted output.
# Input: text string.
# Output: escaped string.
sub _runtime_legacy_quote {
    my ($text) = @_;
    $text =~ s/\\/\\\\/g;
    $text =~ s/'/\\'/g;
    return $text;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PageRuntime - legacy bookmark renderer and CODE executor

=head1 SYNOPSIS

  my $runtime = Developer::Dashboard::PageRuntime->new(paths => $paths);
  $runtime->prepare_page(page => $page, source => 'saved');

=head1 DESCRIPTION

This module applies Template Toolkit rendering to bookmark HTML and executes
legacy C<CODE*> blocks while capturing STDOUT and STDERR for in-page display.

=head1 METHODS

=head2 new, prepare_page, run_code_blocks, stream_code_block, stream_saved_ajax_file

Construct the runtime, render bookmark templates, execute in-process CODE
blocks, and stream saved Ajax files as real child processes.

=cut
