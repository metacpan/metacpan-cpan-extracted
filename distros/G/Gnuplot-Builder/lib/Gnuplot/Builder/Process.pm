package Gnuplot::Builder::Process;
use strict;
use warnings;
use IPC::Open3 qw(open3);
use Carp;
use Gnuplot::Builder::PartiallyKeyedList;
use POSIX qw(:sys_wait_h);
use File::Spec;
use Try::Tiny;
use Encode ();

sub _get_env {
    my ($basename, @default) = @_;
    my $name = "PERL_GNUPLOT_BUILDER_PROCESS_$basename";
    if(defined($ENV{$name}) && $ENV{$name} ne "") {
        return $ENV{$name};
    }else {
        return wantarray ? @default : $default[0];
    }
}

our $ASYNC = _get_env("ASYNC", 0);
our $NO_STDERR = _get_env("NO_STDERR", 0);
our @COMMAND = _get_env("COMMAND", qw(gnuplot --persist));
our $MAX_PROCESSES = _get_env("MAX_PROCESSES", 2);
our $PAUSE_FINISH = _get_env("PAUSE_FINISH", 0);
our $TAP = undef;
our $ENCODING = _get_env("ENCODING", undef);

my $END_SCRIPT_MARK = '@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@';
my $processes = Gnuplot::Builder::PartiallyKeyedList->new;

sub _clear_zombies {
    $_->_waitpid(0) foreach $processes->get_all_values(); ## cannot use each() method because _waitpid() manipulates $processes...
}

{
    my $null_handle;
    sub _null_handle {
        return $null_handle if defined $null_handle;
        my $devnull = File::Spec->devnull();
        open $null_handle, ">", $devnull or confess("Cannot open $devnull: $!");
        return $null_handle;
    }
}

## PUBLIC ONLY IN TESTS: number of processes it keeps now
sub FOR_TEST_process_num { $processes->size }

## PUBLIC ONLY IN TESTS
*FOR_TEST_clear_zombies = *_clear_zombies;

## Documented public method.
sub wait_all {
    while($processes->size > 0) {
        my $proc = $processes->get_at(0);
        $proc->_waitpid(1);
    }
}

## create a new gnuplot process, create a writer to it and run the
## given code. If the code throws an exception, the process is
## terminated. It returns the output of the gnuplot process.
##
## Fields in %args are:
##
## do (CODE-REF mandatory): the code to execute. $do->($writer).
## 
## async (BOOL optional, default = false): If set to true, it won't
## wait for the gnuplot process to finish. In this case, the return
## value is an empty string.
##
## no_stderr (BOOL optional, default = $NO_STDERR): If set to true,
## the return value won't include gnuplot's STDERR. It just includes
## STDOUT.
sub with_new_process {
    my ($class, %args) = @_;
    my $code = $args{do};
    croak "do parameter is mandatory" if !defined($code);
    my $async = defined($args{async}) ? $args{async} : $ASYNC;
    my $no_stderr = defined($args{no_stderr}) ? $args{no_stderr} : $NO_STDERR;
    my $process = $class->_new(capture => !$async, no_stderr => $no_stderr);
    my $result = "";
    try {
        $code->($process->_writer);
        $process->_close_input();
        if(!$async) {
            $result = $process->_wait_to_finish();
        }
    }catch {
        my $e = shift;
        $process->_terminate();
        die $e;
    };
    return $result;
}

## create a new gnuplot process. it blocks if the number of processes
## has reached $MAX_PROCESSES.
##
## Fields in %args are:
##
## capture (BOOL optional, default: false): If true, it keeps the
## STDOUT and STDERR of the process so that it can read them
## afterward. Otherwise, it just discards the output.
##
## no_stderr (BOOL optional, default: false): If true, STDERR is
## discarded instead of being redirected to STDOUT.
sub _new {
    my ($class, %args) = @_;
    _clear_zombies();
    while($MAX_PROCESSES > 0 && $processes->size() >= $MAX_PROCESSES) {
        ## wait for the first process to finish. it's not the smartest
        ## way, but is it possible to wait for specific set of
        ## processes?
        my $proc = $processes->get_at(0);
        $proc->_waitpid(1);
    }
    my $capture = $args{capture};
    my $no_stderr = $args{no_stderr};
    my ($write_handle, $read_handle, $pid);

    ## open3() does not seem to work well with lexical filehandles, so we use fileno()
    $pid = open3($write_handle,
                 $capture ? $read_handle : '>&'.fileno(_null_handle()),
                 $no_stderr ? '>&'.fileno(_null_handle()) : undef,
                 @COMMAND);
    my $self = bless {
        pid => $pid,
        write_handle => $write_handle,
        read_handle => $read_handle,
    }, $class;
    $processes->set($pid, $self);
    return $self;
}


######## 
######## OBJECT METHODS
######## 

## Return the writer code-ref for this process.
sub _writer {
    my ($self) = @_;
    croak "Input end is already closed" if not defined $self->{write_handle};
    my $write_handle = $self->{write_handle};
    my $pid = $self->{pid};
    return sub {
        my $msg = join "", @_;
        $msg = Encode::encode($ENCODING, $msg) if defined $ENCODING;
        $TAP->($pid, "write", $msg) if defined $TAP;
        print $write_handle ($msg);
    };
    ## If we are serious about avoiding dead-lock, we must use
    ## select() to check writability first and to read from the
    ## read_handle. But I guess the dead-lock happens only if the
    ## user inputs too much data and the gnuplot outputs too much
    ## data to STDOUT/STDERR. That's rare.
}

## lexical sub because MockTool uses it, too.
my $_finishing_commands = sub {
    if($PAUSE_FINISH) {
        return ('pause mouse close', 'exit');
    }else {
        return ('exit');
    }
};

## Close the input channel. You can call this method multiple times.
sub _close_input {
    my ($self) = @_;
    return if not defined $self->{write_handle};
    my $writer = $self->_writer;
    $writer->("\n");
    foreach my $statement (qq{set print "-"}, qq{print '$END_SCRIPT_MARK'}, $_finishing_commands->()) {
        $writer->($statement . "\n");
    }
    undef $writer;
    close $self->{write_handle};
    $self->{write_handle} = undef;
}

sub _waitpid {
    my ($self, $blocking) = @_;
    my $result = waitpid($self->{pid}, $blocking ? 0 : WNOHANG);
    if($result == $self->{pid} || $result == -1) {
        $processes->delete($self->{pid});
    }
}

## Blocks until the process finishes. It automatically close the input
## channel if necessary.
##
## If "capture" attribute is true, it returns the output of the
## gnuplot process. Otherwise it returns an empty string.
sub _wait_to_finish {
    my ($self) = @_;
    $self->_close_input();

    my $result = "";
    my $read_handle = $self->{read_handle};
    if(defined $read_handle) {
        while(defined(my $line = <$read_handle>)) {
            $result .= $line;

            ## Wait for $END_SCRIPT_MARK that we told the gnuplot to
            ## print. It is not enough to wait for EOF from $read_handle,
            ## because in some cases, $read_handle won't be closed even
            ## after the gnuplot process exits. For example, in Linux
            ## 'wxt' terminal, 'gnuplot --persist' process spawns its own
            ## child process to handle the wxt window. That child process
            ## inherits the file descriptors from the gnuplot process, and
            ## it won't close the output fd. So $read_handle won't be
            ## closed until we close the wxt window. This is not good
            ## especially we are in REPL mode.
            my $end_position = index($result, $END_SCRIPT_MARK);
            if($end_position != -1) {
                $result = substr($result, 0, $end_position);
                last;
            }
        }
        close $read_handle;
    }
    ## Do not actually wait for the process to finish, because it can
    ## be a long-lasting process with plot windows.
    return $result;
}

sub _terminate {
    my ($self) = @_;
    kill 'TERM', $self->{pid};
}

#### #### #### #### #### #### #### #### #### #### #### #### #### 

package Gnuplot::Builder::Process::MockTool;
use strict;
use warnings;

## tools for a process who mocks gnuplot, i.e., the process who
## communicates with Gnuplot::Builder::Process.


## Receive data from Gnuplot::Builder::Process and execute the $code
## with the received data.
sub receive_from_builder {
    my ($input_handle, $output_handle, $code) = @_;
    while(defined(my $line = <$input_handle>)) {
        $code->($line);

        ## Windows does not signal EOF on $input_handle so we must
        ## detect the end of script by ourselves.
        if(index($line, $END_SCRIPT_MARK) != -1) {
            print $output_handle "$END_SCRIPT_MARK\n";
            $code->("$_\n") foreach $_finishing_commands->();
            last;
        }
    }
}


1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Process - gnuplot process manager

=head1 SYNOPSIS

    use Gnuplot::Builder::Process;
    
    @Gnuplot::Builder::Process::COMMAND = ("/path/to/gnuplot", "-p");
    $Gnuplot::Builder::Process::ENCODING = "utf8";

=head1 DESCRIPTION

L<Gnuplot::Builder::Process> class manages gnuplot processes spawned
by all L<Gnuplot::Builder::Script> objects.

You can configure its package variables to change its behavior.

=head1 CLASS METHODS

=head2 Gnuplot::Builder::Process->wait_all()

Wait for all gnuplot processes to finish.

If there is no gnuplot process running, this method returns immediately.

=head1 PACKAGE VARIABLES

B<< The default values for these variables may be changed in future releases. >>

=head2 $ASYNC

If set to true, plotting methods of L<Gnuplot::Builder::Script> run in the asynchronous mode by default.
See L<Gnuplot::Builder::Script> for detail.

By default, it's C<0> (false).

You can also set this variable by the environment variable
C<PERL_GNUPLOT_BUILDER_PROCESS_ASYNC>.

=head2 @COMMAND

The command and arguments to run a gnuplot process.

By default, it's C<("gnuplot", "--persist")>.

You can also set this variable by the environment variable
C<PERL_GNUPLOT_BUILDER_PROCESS_COMMAND>.


=head2 $ENCODING

If set, L<Gnuplot::Builder> encodes the script string in the specified encoding just before streaming into the gnuplot process.
You can specify any encoding names recognizable by L<Encode> module.

By default it's C<undef>, meaning it doesn't encode the script.

You can also set this variable by the environment variable
C<PERL_GNUPLOT_BUILDER_PROCESS_ENCODING>.

=head2 $MAX_PROCESSES

Maximum number of gnuplot processes that can run in parallel.
If C<$MAX_PROCESSES> <= 0, the number of processes is unlimited.

By default, it's C<2>.

You can also set this variable by the environment variable
C<PERL_GNUPLOT_BUILDER_PROCESS_MAX_PROCESSES>.

=head2 $NO_STDERR

If set to true, gnuplot's STDERR will not appear in the return value of L<Gnuplot::Builder::Script>'s plotting methods
(C<plot()>, C<plot_with()>, C<splot()> ... etc).
It returns STDOUT only. You can use this to prevent warnings in the output.

By default it is C<0> (false).
You can also set this variable by the environment variable
C<PERL_GNUPLOT_BUILDER_PROCESS_NO_STDERR>.


=head2 $PAUSE_FINISH

If set to true, L<Gnuplot::Builder> sends "pause mouse close" command to the gnuplot process
just before finishing the script.

By default, it's C<0> (false).

You can also set this variable by the environment variable
C<PERL_GNUPLOT_BUILDER_PROCESS_PAUSE_FINISH>.

=head2 $TAP

A subroutine reference to tap the IPC with the gnuplot process. This is useful for debugging.

If set, the subroutine reference is called for each event.

    $TAP->($pid, $event, $body)

where C<$pid> is the PID of the gnuplot process,
C<$event> is a string describing the event type,
and C<$body> is an object describing the event.

Currently C<$event> is always C<"write">, which is called every time some data is written to the gnuplot process.
C<$body> is the written string.

To set C<$TAP> from outside the program, use L<Gnuplot::Builder::Tap>.

Example:

    local $Gnuplot::Builder::Process::TAP = sub {
        my ($pid, $event, $body) = @_;
        warn "PID:$pid, EVENT:$event, BODY:$body";
    };


=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>


=cut

