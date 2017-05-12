package Devel::GDB;

use 5.006;
use strict;
use warnings;

use Devel::GDB::LowLevel;
use threads::shared;
use Thread::Semaphore;

use B qw( cstring );

=head1 NAME

Devel::GDB - Open and communicate a gdb session

=head1 SYNOPSIS

    use Devel::GDB;

    $gdb = new Devel::GDB();
    print $gdb->send_cmd('-environment-path');
    print $gdb->get('info functions');

The old C<get> syntax (of C<Devel::GDB-1.23>) has been deprecated and will not
be supported in future versions.  See the documentation of the C<get> function
for an explanation of why.

If you really want to use the old syntax, set $Devel::GDB::DEPRECATED to true:

    use Devel::GDB ;

    $Devel::GDB::DEPRECATED = 1;
    $gdb = new Devel::GDB();
    print $gdb->get('info functions', $timeout, $prompt, $notyet, $alldone);

=head1 DESCRIPTION

The C<Devel::GDB> package provides an interface for communicating with GDB.
Internally, it uses the I<GDB/MI> interpreter
(see L<http://sourceware.org/gdb/current/onlinedocs/gdb_25.html>), which
accurately informs the caller of the program state and, through the use of
tokens, guarantees that the results returned actually correspond to the request
sent.  By contrast, GDB's I<console> interpreter returns all responses on
C<STDOUT>, and thus there is no way to ensure that a particular response
corresponds to a particular request.

Therefore, it is obviously preferable to use GDB/MI when programmatically
interacting with GDB.  This can be done via the C<send_cmd> family of functions
(C<send_cmd>, C<send_cmd_excl>, and C<send_cmd_async>).  There are, however,
some cases when there is no GDB/MI command corresponding to a particular console
command, or it has not yet been implemented (for example, C<-symbol-type>,
corresponding to the console command C<ptype>, is not yet implemented as of GDB
6.6).  In this case, the C<get> function provides a workaround by capturing all
output sent to the console stream.

=cut

our $VERSION = '2.02';
our $DEBUG;
our $DEPRECATED;

=head1 CONSTRUCTOR

=head2 new

    $gdb = new Devel::GDB( '-use-threads' => 1 );
                           '-params'      => $extra_gdb_params );

Spawns a new GDB process.  In I<threaded> mode, this also spawns a listening
thread that asynchronously processes responses from GDB; in I<non-threaded>
mode, the caller is responsible for handling asynchronous output (that is,
output from GDB that is not directly solicited by a request).  See C<demux>,
C<get_reader>, and the L</Non-threaded Usage> example for further discussion.

The parameters to the constructor are passed in hash form.  The following
parameters control how GDB is invoked:

=over

=item C<-execfile>

The GDB binary to execute; defaults to C<"gdb">.

=item C<-params>

Pass additional parameters to GDB.  The value can be an array reference
(preferred) or a string.

=back

The following parameters control how to handle interaction with the I<inferior
process>, the program being debugged.  The default behavior is to give the
inferior process control of the terminal while it is running, returning control
to perl when the program is suspended or stopped (emulating the behavior of
gdb).  However, this only works when C<STDIN> is associated with a tty.  Two
other (mutually exclusive) options are available:

=over

=item C<-use-tty>

Specify the name of the tty that the inferior process should use for its I/O.
Note that this is the path to a tty (e.g. C<"/dev/pts/123">) and not an
C<IO::Pty> object.  See the example L</Debugging Inside an XTerm>.

=item C<-create-expect>

If this value is non-zero, create an C<Expect> object (which can be subsequently
retrieved by calling C<get_expect_obj>); this is useful if you want to
programmatically interact with the inferior process.  See the example
L</Programmatically Interacting with the Inferior Process>.

=back

Miscellaneous parameters:

=over

=item C<-use-threads>

Operate in threaded (1) or non-threaded (0) mode.  The default behavior is to
enable threaded mode if the C<threads> module has been loaded and disable it
otherwise.  Note that if C<-use-threads> is enabled, the caller B<must> call
C<use threads>, but C<-use-threads> can be disabled whether or not C<threads>
has been loaded.

Threaded mode is the easiest to deal with, as it does not require the caller to
interact with the GDB filehandles directly; for a simple non-threaded example,
see the L</Non-threaded Usage> example.

=item C<-readline-fn>

Probably only useful in non-threaded mode, this lets the user specify a callback
function $fn to be called when waiting for a response from GDB.  It is invoked
with one parameter, the C<Devel::GDB> instance, and is expected to return one
full line of output (or C<undef> if EOF was reached).  The default
implementation uses buffered I/O:

    $fn = sub { return readline($_[0]->get_reader); }

Typically, in non-threaded mode, the caller will be using C<select> to multiplex
multiple file streams (e.g. C<STDIN> and C<get_reader>); in this case, you will
likely want to specify a value for C<-readline-fn> which, at a minimum, uses
C<sysread> rather than C<readline>.

=back

=cut

sub new
{
    my $class  = shift;

    # Break up @_ into our params and those passed to $level0
    my (@params, @level0_params);
    %_ = @_;
    while(my @p = each(%_))
    {
        $p[0] =~ /^-(use-threads|readline-fn)$/ and push @params, @p
            or push @level0_params, @p
    }

    my $self = bless
    {
        next_token     => 0,
        response       => {},
        sinks          => {},
        LOCK_shared    => 0,
        LOCK_excl      => new Thread::Semaphore,
        DEAD           => 0,                            # Set to 1 when _the_gdb_thread exits
        '-use-threads' => $threads::VERSION,            # Use threads if they're enabled (user can override)
        '-readline-fn' => \&_readline, 
        @params
    };

    if($DEPRECATED)
    {
        $self->{'-readline-fn'} = undef;

        die "Threads cannot be enabled when \$Devel::GDB::DEPRECATED is set!"
            if $self->{'-use-threads'};
    }

    share($self->{'next_token'});
    share($self->{'response'});
    share($self->{'sinks'});
    share($self->{'LOCK_shared'});
    share($self->{'DEAD'});

    $self->{level0} = new Devel::GDB::LowLevel( @level0_params );

    if($self->{'-use-threads'})
    {
        # Don't dynamically load "threads" here: things get messy because
        # threads::shared is already loaded
        die "Please 'use threads' before instantiating Devel::GDB with -use-threads => 1!"
            unless($threads::VERSION);

        $self->{trT} = threads->create( \&_the_gdb_thread, $self )
            or die "can't create thread: $@\n";
    }

    return $self;
}

=head1 METHODS

=over

=item send_cmd

    $response = $gdb->send_cmd($command)

Send C<$command> to GDB, and block until a response is received.  In threaded
mode, this does not prevent other threads from simultaneously sending requests.

The C<$command> can be a GDB/MI command, prefixed with a hyphen (e.g.
C<"-exec-run">) or a console command (C<"run">).  However, the response returned
will always be a GDB/MI response, so C<< $gdb->send_cmd("info variables") >> will
only return C<"done">; the actual output you probably wanted will be dumped into
the console stream.  To execute console commands and capture the output sent
back to the console, use C<get>.

=cut

sub send_cmd
{
    my $self = shift;
    my ($cmd) = @_;

    $self->_lock_shared();
    my ($result, $token) = $self->_send_cmd($cmd);
    $self->_unlock_shared();

    return wantarray ? ($result, $token) : $result;
}

=item send_cmd_excl

    $gdb->send_cmd_excl($cmd, $before_fn, $after_fn)

Send C<$cmd> to GDB in I<exclusive mode>.  In threaded mode, this means that other
C<send_cmd> and C<send_cmd_excl> calls will not coincide with this call.  In
non-threaded mode, this ensures that any pending C<send_cmd_async> calls are
processed before proceeding.

If provided, the C<$before_fn> and C<$after_fn> functions will, respectively, be
called before the command is sent (after the exclusive lock is aquired) and
after the result has been received (before the exclusive lock is released).

=cut

sub send_cmd_excl
{
    my $self = shift;
    my ($cmd, $before_fn, $after_fn) = @_;

    $self->_lock_exclusive();
    $before_fn->() if $before_fn;

    my ($result, $token) = $self->_send_cmd($cmd);

    $after_fn->() if $after_fn;
    $self->_unlock_exclusive();

    return wantarray ? ($result, $token) : $result;
}

=item send_cmd_async

    $gdb->send_cmd_excl($cmd, $callback_fn)

B<Not yet implemented.>

Send C<$cmd> to GDB in I<async mode>.  This returns immediately, rather than
blocking until a response is received; instead, the C<$callback_fn> callback
function is called, with the response as the first argument.

This will likely only be supported in non-threaded mode.

=cut

sub send_cmd_async
{
    my $self = shift;
    my ($cmd, $callback) = @_;

    die "send_cmd_async() cannot be used in threaded mode"
        if $self->{'-use-threads'};

    $self->_send_cmd($cmd, 1, $callback);
}


=item get

    $gdb->get($command)

Issues the C<$command> to GDB, and returns all output sent to the console output
stream.  Note that there is no way to ensure that the output "belongs" to a
particular command, so it is possible that spurious output will be included!  In
particular, if you call C<< $gdb->get($command) >> immediately after creating the
C<Devel::GDB> object, and don't suppress GDB's initialization messages (by
passing C<-q> to C<-params>), some of these messages may end up in the response to
C<get>.

In list context, returns C<($buffer, $error)>, with exactly one of the two
defined; C<$buffer> is the text captured from the console stream and C<$error>
is the GDB/MI error message.  In scalar context, only C<$buffer> is returned
(C<undef> if there was an error).

=item get (DEPRECATED)

    $gdb->get($command, $timeout, $prompt, $notyet, $alldone)

This version of C<get> is used when C<$Devel::GDB::DEPRECATED> is true, and
provides backwards compatibility with older versions of C<Devel::GDB>.
It is not compatible with any of the new features (e.g. C<send_cmd>, threaded
mode) and will be removed in future versions.

This method is flawed in a number of ways: the semantics of when C<$notyet> is
called are unclear, the handling of C<$timeout> is broken, and most importantly,
the fact that it allows execution to be interrupted can put the module into an
inconsistent state.

No new code should use this function.

=cut

sub get
{
    my $self = shift;

    if($DEPRECATED or @_ > 1)
    {
        return $self->_get_deprecated(@_);
    }

    my ($cmd) = @_;

    my $buffer = &share([]);
    my $before_fn = $self->_generate_redirector('console', $buffer);
    my $after_fn  = $self->_generate_undirector('console');

    my $result = $self->send_cmd_excl($cmd, $before_fn, $after_fn);

    # Return undef if send_cmd_excl returned undef (EOF)
    return undef unless defined($result);

    # Return the buffer, if the command succeeded
    if($result =~ /^done/)
    {
        return join('', @$buffer);
    }

    # Check if GDB gave us an error
    if($result =~ /^error,(.*)/)
    {
        return wantarray ? (undef, $1) : undef;
    }

    # Otherwise, something strange happened
    return wantarray ? (undef, "Unexpected result: $result") : undef;
}

=item get_expect_obj

Returns the C<Expect> object created by C<-create-expect>.

=cut

sub get_expect_obj
{
    my $self = shift;
    return $self->{level0}->get_expect_obj;
}

=item get_reader

Returns the filehandle from which to read GDB responses.

In non-threaded mode, the caller will need this filehandle in its
C<-readline-fn>; in addition, to support asynchronous GDB responses, the caller
should pass lines read from this filehandle to C<demux>.

=cut

sub get_reader
{
    my $self = shift;
    return $self->{level0}->get_reader;
}

=item demux

    $gdb->demux($line)

Process a line read from the GDB stream (see C<get_reader>).  This should
only be called in non-threaded mode.  (See example: L</Non-threaded Usage>)

=cut

sub demux
{
    my $self = shift;

    die "Cannot call demux() in threaded mode!"
        if $self->{'-use-threads'};

    return $self->_demux(@_);
}

=item interrupt

Send SIGINT to the GDB session, interrupting the inferior process
(if any).

=cut

sub interrupt
{
    my $self = shift;
    $self->{level0}->interrupt;
}

=item end

Kills the GDB connection.  You B<must> call this to ensure that the GDB process
is killed gracefully.

=cut

sub end
{
    my $self = shift;

    # Don't talk to level0 if it's already dead
    unless($self->{'DEAD'})
    {
        $self->{level0}->interrupt;
        $self->{level0}->send("-gdb-exit");
    }

    $self->{trT}->join
        if $self->{trT};
}

sub _generate_redirector
{
    my $self = shift;
    my ($stream, $buffer) = @_;

    return sub
    {
        lock $self->{sinks};

        die "Something wrong here: cannot have multiple redirectors for the same stream!"
            if defined($self->{sinks}->{$stream});

        $self->{sinks}->{$stream} = $buffer;
    };
}

sub _generate_undirector
{
    my $self = shift;
    my ($stream) = @_;

    return sub
    {
        lock $self->{sinks};

        die "Something wrong here: trying to undirect $stream when no redirection is in place!"
            unless defined($self->{sinks}->{$stream});

        delete $self->{sinks}->{$stream};
    };
}

# Acquire a shared lock.  Blocks if the exclusive lock is held,
# until the exclusive lock is released.
sub _lock_shared
{
    my $self = shift;

    lock $self->{'LOCK_shared'};

    # Acquire the exclusive lock if we're the first shared lock holder
    if(!$self->{'LOCK_shared'})
    {
        # Note: if _lock_exclusive blocks, then nobody can acquire the lock on
        # LOCK_shared.  This won't result in any deadlocks, since the only 
        # possible LOCK_shared waiters are other _lock_shared() callers, and
        # NOT _unlock_shared() (since the lock count is zero!)
        $self->_lock_exclusive();
    }

    $self->{'LOCK_shared'}++;
    printf STDERR "+++ Shared lock count is now $self->{LOCK_shared}\n"
        if $DEBUG;
}

sub _unlock_shared
{
    my $self = shift;

    lock $self->{'LOCK_shared'};
    $self->{'LOCK_shared'}--;

    # Release the exclusive lock if we're the last shared lock holder
    if(!$self->{'LOCK_shared'})
    {
        $self->_unlock_exclusive();
    }

    printf STDERR "--- Shared lock count is now $self->{LOCK_shared}\n"
        if $DEBUG;
}

# Acquire an exclusive lock.  Blocks if any shared or exclusive locks are
# held, until they are all released.
sub _lock_exclusive
{
    my $self = shift;

    # Acquire the exclusive lock.  This will block until
    # (a) the shared-lock count goes to zero, and
    # (b) nobody else is holding an exclusive lock.
    $self->{'LOCK_excl'}->down;

    printf STDERR "+++ EXCLUSIVE LOCK AQUIRED\n"
        if $DEBUG;
}

# Release an exclusive lock.
sub _unlock_exclusive
{
    my $self = shift;
    $self->{'LOCK_excl'}->up;

    printf STDERR "--- EXCLUSIVE LOCK RELEASED\n"
        if $DEBUG;
}

sub _send_cmd
{
    my $self = shift;
    my ($cmd, $is_async, $callback) = @_;

    die "Not yet implemented"
        if $is_async;

    # Make sure there's no token there
    $cmd =~ s/^[0-9]+//;

    # Make sure it's a GBM/MI command; otherwise, turn it into one
    if($cmd !~ /^-/)
    {
        $cmd = '-interpreter-exec console "' . _escape($cmd) . '"';
    }

    # Generate a token
    my $token = $self->_generate_token();

    # Send the command, and wait for a response
    $self->{level0}->send($token . $cmd);

    # Wait until we get a response
    my $response = $self->_wait($token);

    return ($response, $token);
}

sub _escape
{
    my ($string) = @_;
    my $qstring = cstring($string);

    # Remove the quotes around it
    $qstring =~ s/^"(.*)"$/$1/;

    return $qstring;
}

my %unesc = (  "\\" => "\\",
               "\"" => "\"",
               "a"  => "\a",
               "b"  => "\b",
               "t"  => "\t",
               "n"  => "\n",
               "f"  => "\f",
               "r"  => "\r",
               "e"  => "\e",
               "v"  => "\013",
            );

sub _unescape
{
   # Looks like we have to do this one ourselves
   my ($string) = @_;

   # Unescape any \X for various characters X (including \\ and \")
   $string =~ s/\\([\\\"abtnfrev])/$unesc{$1} || "\\$1"/esg;

   # Unescape \OCTAL for various octal values
   $string =~ s/\\(0[0-7]+)/chr(oct($1))/esg;

   return $string;
}

sub _generate_token
{
    my $self = shift;

    lock $self->{next_token};
    lock $self->{response};

    # Create the actual token
    my $token = $self->{next_token}++;

    # Create a shared variable for one response received on this token (used by demux)
    # (subsequent responses will be treated as "late responses")
    $self->{response}->{$token} = &share(\my $tmp);

    # Return the token and the buffer
    return $token;
}

sub _wait
{
    my $self = shift;
    my ($token) = @_;

    # Wait until the buffer is non-empty
    my $response = $self->{response}->{$token};
    lock($response);
    until(defined $$response)
    {
        last if($self->{'DEAD'});

        if($self->{'-use-threads'})
        {
            cond_wait($response);
        }
        else
        {
            last unless $self->_message_loop();
        }
    }

    # Keep the response, then delete the entry in $self->{response}
    delete $self->{response}->{$token};
    return $$response;
}

sub _the_gdb_thread
{
    my $self = shift;

    # Close the duplicated filehandle: we don't need it in this thread
    close $self->{level0}->{TTY}
        if $self->{level0}->{TTY};

    while($self->_message_loop()) { }

    # Set the DEAD flag
    $self->{'DEAD'} = 1;

    # Wake up any threads stuck in _wait().
    #
    # Note: _wait() tests the DEAD flag AFTER locking $self->{response}->{$token},
    # so there's no race condition here: we won't get the $response lock until
    # after it's released by cond_wait().
    {
        lock $self->{response};
        foreach my $token (keys %{$self->{response}})
        {
            my $response = $self->{response}->{$token};
            if(defined $response)
            {
                lock $response;
                cond_signal($response);
            }
        }
    }
}

sub _readline
{
    my $self = shift;
    local $/ = "\n";
    return readline($self->get_reader);
}

sub _message_loop
{
    my $self = shift;

    die "The new API is not available when \$Devel::GDB::DEPRECATED is set!"
        if $DEPRECATED;

    my $line = $self->{'-readline-fn'}->($self);
    if(defined $line)
    {
        chomp $line;
        $self->_demux($line);
        return 1;
    }

    return 0;
}

sub _demux
{
    my $self = shift;
    my ($line) = @_;

    printf STDERR "<<< %s\n", $line
        if $DEBUG;

    if($line eq '(gdb) ')
    {
        # Ignore it
    }
    elsif($line =~ /^~"(.*)"$/)
    {
        $self->_record_stream('console', _unescape($1));
    }
    elsif($line =~ /^@"(.*)"$/)
    {
        $self->_record_stream('target', _unescape($1));
    }
    elsif($line =~ /^&"(.*)"$/)
    {
        $self->_record_stream('log', _unescape($1));
    }
    elsif($line =~ /^([0-9]+)\^(.*)$/)
    {
        $self->_record_result($2, $1);
    }
    elsif($line =~ /^([0-9]+)\*(.*)$/)
    {
        $self->_record_async_exec($2, $1);
    }
    elsif($line =~ /^([0-9]+)\+(.*)$/)
    {
        $self->_record_async_status($2, $1);
    }
    elsif($line =~ /^([0-9]+)=*(.*)$/)
    {
        $self->_record_async_notify($2, $1);
    }
}

sub _record_stream($$$)
{
    my $self = shift;
    my ($stream, $input) = @_;

    # Split line if it's multiple lines
    foreach my $line (split "\n", $input)
    {
        # Add (back) newline terminator
        $line = "$line\n";

        # Use redirection if it's set up
        lock $self->{sinks};
        if(defined $self->{sinks}->{$stream})
        {
            push @{$self->{sinks}->{$stream}}, $line;
            next;
        }

        # Hack: GDB prints "Quit" to the log stream if we sent it SIGINT
        # when the inferior process is not running.  Swallow this spurious
        # output.
        next if $line eq "Quit\n";

        # Otherwise, dump it to STDERR for now
        local $\ = "";
        print STDERR $line;
    }
}

sub _record_result($$$)
{
    my $self = shift;
    my ($line, $token) = @_;

    my $response = $self->{response}->{$token};
    lock $response if defined($response);

    # Process the first response, and only the first response
    #
    # Note: we avoid a race condition with _wait() by checking
    # defined($self->{response}->{$token}) rather than defined($response)
    if(defined $self->{response}->{$token} and !defined($$response))
    {
        $$response = $line;
        cond_signal($response);
    }

    # All others are handled as "late responses"
    else
    {
        return $self->_record_stream('late_response', "($token) $line");
    }
}

sub _record_async_exec($$$)
{
    my $self = shift;
    my ($line, $token) = @_;

    local $, = ": ";
    local $\ = "\n";
    print STDERR "exec-async-output", $token, $line;
}

sub _record_async_status($$$)
{
    my $self = shift;
    my ($line, $token) = @_;

    local $, = ": ";
    local $\ = "\n";
    print STDERR "status-async-output", $token, $line;
}

sub _record_async_notify($$$)
{
    my $self = shift;
    my ($line, $token) = @_;

    local $, = ": ";
    local $\ = "\n";
    print STDERR "notify-async-output", $token, $line;
}

sub _pipe_read {
    my ($out, $to, $pr, $cb) = @_ ;
    $out = $out->{OUT} unless ref($out) =~ /GLOB|FileHandle/ ;
    $to ||= undef ;
    my $rmask = '' ;
    vec ($rmask, fileno( $out ), 1) = 1 ;
    my ($buf, $buffer, $err) ;
    while (not $err) {
        my $nread;
        if ( $cb ) {
            # this call back should be called every second. if it
            # returns true, abandon. Not mswin supported
            for( ; !defined($to) or 0 < $to; --$to if defined($to)) {
                my $r = $rmask ;
                ($nread) = select ($r, undef, undef, 1 ) ;
                last if $nread ;
                last if $cb -> ($to) and $err = 'STOPPED' ;
            }
        }
        else {
            my $r = $rmask ;
            ($nread) = select $r, undef, undef, $to ;
        }
        last if ! $nread and $err = 'TIMEOUT' ;
        $buffer ||= '' ;
        sysread $out, $buf, 10_000 ;
        last if ! $buf and $err = 'EOF' ;
        $buffer .= $buf ;
        last if ! $pr or $buffer =~ /$pr/s ;
    }

    return ($buffer, $err || '');
}

sub _get_deprecated
{
    # returns (buffer, error, prompt) in array context
    # return buffer in scalar context (undef if error)
    my $self = shift or die 'whoami';
    my ($cmd, $timeout, undef, $wait_callback, $done_callback) = @_ ;

    die "This syntax is deprecated.  Please update your code, or set \$Devel::GDB::DEPRECATED = 1"
        unless $DEPRECATED;

    die "Deprecated get() is not compatible with threads"
        if $self->{'-use-threads'};

    # Make sure it's a GBM/MI command; otherwise, turn it into one
    if($cmd !~ /^-/)
    {
        $cmd = '-interpreter-exec console "' . _escape($cmd) . '"';
    }

    $self->{'level0'}->send($cmd);

    my ($buffer, $err) = _pipe_read( $self->get_reader, $timeout, qr/(^|\n)\^/, $wait_callback ) ;
    $done_callback and $done_callback->();

    if($err)
    {
        return wantarray ? ($buffer, $err) : undef;
    }

    # Filter out the console output stream (discard everything else)
    my @lines = grep { /^~"(.*)"$/ } (split /\n/, $buffer);

    # Unescape the contents of the stream
    s/^~"(.*)"$/_unescape($1)/xe
        foreach(@lines);

    # Return the result
    $buffer = join('', @lines);

    return wantarray ? ($buffer, $err) : $buffer;
}

1;

__END__

=back

=head1 EXAMPLES

=head2 Non-threaded Usage

    use Devel::GDB;
    use IO::BufferedSelect;

    my $gdb = new Devel::GDB( '-use-threads' => 0, 
                              '-readline-fn' => \&message_loop );

    my $gdb_fh = $gdb->get_reader;

    my $bs = new IO::BufferedSelect(\*STDIN, $gdb_fh);

    sub message_loop
    {
        my @result = $bs->read_line($gdb_fh);
        return @result ? $result[0][1] : undef;
    }

    OUTER:
    while(1)
    {
        my @ready = $bs->read_line();
        foreach( @ready )
        {
            my ($fh, $line) = @$_;
            defined($line) or last OUTER;
            chomp $line;

            if($fh == \*STDIN)
            {
                print STDERR "RECEIVED: $line\n";
                my $result = $gdb->get($line);
                last unless defined($result);
                print STDERR $result;
            }
            else
            {
                $gdb->demux($line);
            }
        }
    }

=head2 Programmatically Interacting with the Inferior Process

Here's a simple example that communicates with an inferior process (in this
case, C<tr>) using the C<Expect> module.

    use strict;
    use warnings;
    use threads;
    use Devel::GDB;

    my $gdb = new Devel::GDB( '-create-expect' => 1 );
    my $e = $gdb->get_expect_obj;

    $gdb->send_cmd("file tr");
    $gdb->send_cmd("set args a-zA-Z A-Za-z");
    $gdb->send_cmd("-exec-run");

    $e->send("one TWO\n");
    $e->send("ONE two\n");

    $e->expect(undef, '-re', '^.+$')
        and $e->match =~ /^ONE two/
        and print "ok 1\n"
        or die;

    $e->expect(undef, '-re', '^.+$')
        and $e->match =~ /^one TWO/
        and print "ok 2\n"
        or die;

    $gdb->end;

    $e->slave->close;
    $e->expect(undef);
    printf "EXPECT(EOF): %s\n", $e->before;

=head2 Debugging Inside an XTerm

Here's an example that spawns an xterm and runs the inferior process inside it.
Commands are read from STDIN, and responses written to STDERR.

    use strict;
    use warnings;
    use threads;
    use Devel::GDB;
    use IO::Pty;
    use POSIX;

    sub set_termios_lflag($$$)
    {
        my($fd, $flag, $value) = @_;
        my $termios = new POSIX::Termios;
        $termios->getattr($fd);
        $termios->setlflag($value ? ($termios->getlflag | $flag) : ($termios->getlflag & ~$flag));
        $termios->setattr($fd);
        undef $termios;
    }

    my $pty = new IO::Pty;

    # Disable echo temporarily
    set_termios_lflag(fileno($pty), &POSIX::ECHO, 0);

    # Fork an xterm
    unless(my $xterm_pid = fork)
    {
        die "Fork failed" unless defined($xterm_pid);

        # Reopen $fd with close-on-exec disabled
        my $fd  = fileno($pty);
        $^F = $fd > $^F ? $fd : $^F;
        local *MASTER;
        open(MASTER, "<&=$fd") and $fd == fileno(\*MASTER)
            or die "Failed reopening pty handle";

        my $cmd = "xterm -Sxx$fd";

        print "calling exec($cmd)\n";
        exec($cmd);
        die "exec() failed: $!";
    }

    # xterm likes to write its window id to the pty; eat it up
    # (echo is disabled so the inferior process doesn't see this output)
    my $window_id = readline($pty->slave);

    # Now turn echo back on
    set_termios_lflag(fileno($pty), &POSIX::ECHO, 1);

    # No longer need the master (but don't close the slave!)
    close $pty;

    # Create the GDB object, telling the inferior process to use the new xterm's pty
    my $gdb = new Devel::GDB( '-use-tty' => $pty->ttyname );

    while(<STDIN>)
    {
        chomp;

        if(/^Z/)
        {
            $gdb->interrupt;
            next;
        }

        my $result = $gdb->send_cmd($_);
        last unless defined($result);
        print STDERR "[GDB] $result\n";
    }

    $gdb->end;

=head1 TODO

There are a number of features that will be made available in future versions of
C<Devel::GDB>.  Among them:

=over

=item *

Finish implementing C<send_cmd_async>.

=item *

Add an interface for redirecting GDB/MI output.  Currently, all C<out-of-band-records>
(see L<http://sourceware.org/gdb/current/onlinedocs/gdb_25.html#SEC246>)
are redirected to C<STDERR>; there should be a facility for callers to specify
what to do with each stream.

=item *

In order to allow full-fledged GDB front-ends to be implemented with this
module, we need a more "intelligent" layer above C<Devel::GDB>: rather than
simply sending commands and receiving their results, the hypothetical
C<Devel::GDB::HighLevel> module would be aware of the program state; it would
know whether or not the inferior process is running, what breakpoints are set,
and so forth.

=back

=head1 SEE ALSO

L<Devel::GDB::LowLevel>

=head1 AUTHORS

Antal Novak E<lt>afn@cpan.orgE<gt>, Josef Ezra E<lt>jezra@cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Antal Novak & Josef Ezra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

