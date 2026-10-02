package Devel::ebug;

use strict;
use warnings;
use Carp;
use Class::Accessor::Chained::Fast;
use Devel::StackTrace 2.00;
use Devel::ebug::Wire;
use IO::Select;
use IO::Socket::INET;
use Proc::Background;
use String::Koremutake;
use Text::ParseWords qw(shellwords);
use Module::Pluggable require => 1;

use base qw(Class::Accessor::Chained::Fast);

# ABSTRACT: A simple, extensible Perl debugger
our $VERSION = '0.68'; # VERSION

__PACKAGE__->mk_accessors(qw(
    backend
    port
    serializer
    program args socket proc pid running
    package filename line codeline subroutine finished));

# let's run the code under our debugger and connect to the server it
# starts up
# 'yaml' unless asked otherwise, so existing clients are unaffected.
sub _serializer {
  my($self) = @_;
  my $format = $self->serializer || $ENV{DEVEL_EBUG_SERIALIZER} || 'yaml';
  croak "unknown serializer '$format', expected 'yaml' or 'json'"
    unless $format eq 'yaml' or $format eq 'json';
  return $format;
}

sub load {
  my $self = shift;
  my $program = $self->program;

  # import all the plugins into our namespace
  eval { $_->import } for $self->plugins;

  my $k = String::Koremutake->new;
  my $secret = $k->integer_to_koremutake(int(rand(100_000)));

  # Listen on a port of the OS's choosing and have the backend connect back
  # to it, so that concurrent sessions can never collide over a port.
  my $listener = IO::Socket::INET->new(
    Listen    => 1,
    LocalAddr => 'localhost',
    LocalPort => 0,
    Proto     => 'tcp',
  ) || croak "Devel::ebug: could not listen for the backend: $!";

  $ENV{SECRET} = $secret;
  $ENV{DEVEL_EBUG_CONNECT} = $listener->sockport;
  # With args the command is run as a list, so they reach the program
  # verbatim instead of being split and interpolated by the shell.
  my @command;
  if (my $args = $self->args) {
    my @backend = $self->backend ? shellwords($self->backend) : ($^X, '-d:ebug::Backend');
    @command = (@backend, $program, @$args);
  } else {
    my $backend = $self->backend || "$^X -d:ebug::Backend";
    @command = ("$backend $program");
  }
  my $proc = Proc::Background->new(
    {'die_upon_destroy' => 1},
    @command
  );
  croak(qq{Devel::ebug: Failed to start up "$program" in load()}) unless $proc->alive;
  $self->proc($proc);
  $ENV{SECRET} = "";
  delete $ENV{DEVEL_EBUG_CONNECT};

  $self->socket($self->_accept_backend($listener, $secret));
  close $listener;

  $self->_handshake($secret);
}

# Wait for the backend we just started to connect back.  It announces
# itself by sending the secret, and anything else that connects to the
# listening port is turned away.
sub _accept_backend {
  my($self, $listener, $secret) = @_;
  my $program  = $self->program;
  my $select   = IO::Select->new($listener);
  my $deadline = time + 30;

  while (time < $deadline) {
    croak(qq{Devel::ebug: "$program" exited before the debugger could connect to it})
      unless $self->proc->alive;
    next unless $select->can_read(0.1);
    my $socket = $listener->accept or next;
    my $line = IO::Select->new($socket)->can_read(5) ? $socket->getline : undef;
    if (defined $line) {
      $line =~ s/\r?\n\z//;
      return $socket if $line eq $secret;
    }
    close $socket;
  }

  croak(qq{Devel::ebug: timed out waiting for "$program" to connect to the debugger; }
    . qq{is an older Devel::ebug::Backend being loaded that does not support DEVEL_EBUG_CONNECT?});
}

sub attach {
    my ($self, $port, $key) = @_;

    # import all the plugins into our namespace
    eval { $_->import } for $self->plugins;

    # try and connect to the server
    my $socket;
    foreach ( 1 .. 10 ) {
        $socket = IO::Socket::INET->new(
            PeerAddr   => "localhost",
            PeerPort   => $port,
            Proto      => 'tcp',
            ReuseAddr => 1,
        );
        last if $socket;
        sleep 1;
    }
    die "Could not connect: $!" unless $socket;
    $self->socket($socket);

    $self->_handshake($key, $port);
}

sub _handshake {
    my ($self, $key, $port) = @_;

    # talk() would report a closed connection as a lost program; here it
    # means our secret was turned away, which deserves its own message
    $self->_send(
        {   command => "ping",
            version => $Devel::ebug::VERSION,
            secret  => $key,
        }
    );
    my $response = $self->_receive(1);
    unless ($response) {
        die "The debugger did not answer the handshake"
          . (defined $port ? " on port $port; the key may be wrong, or the port may belong to another session" : "")
          . "\n";
    }
    my $version = $response->{version};
    die "Client version $version != our version $Devel::ebug::VERSION"
        unless do { no warnings 'uninitialized'; $version eq $Devel::ebug::VERSION };
    $self->pid($response->{pid});
    $self->running(0);

    $self->basic;    # get basic information for the first line
}

#
# FIXME : this would mean that plugin writers don't need to Export stuff
#
#sub load_plugins {
#    my $self = shift;
#    my $obj = Devel::Symdump->new($self->plugins);
#
#    for ($obj->functions) {
#        my $name = (split /::/)[-1];
#        next if substr($name,0,1) eq '_';
#        *basic = \&$_;
#    }
#
#}



# Requests and responses go over the socket one line at a time; see
# Devel::ebug::Wire for how a line is put together.
# The debugger went away mid-conversation: the program exited without
# the debugger's cleanup running, was killed, or crashed.
sub _lost {
  my($self) = @_;
  $self->running(0);
  my $program = defined $self->pid ? sprintf('the program (pid %d)', $self->pid) : 'the program';
  my $what = "$program has exited or been killed";

  # When we started it, say how it ended.  The connection can close a
  # moment before the process is reaped, so give it a short while.
  if (my $proc = $self->proc) {
    for (1 .. 20) {
      last unless $proc->alive;
      select(undef, undef, undef, 0.05);
    }
    my $status = $proc->alive ? undef : $proc->wait;
    if (defined $status) {
      $what = $status & 127
        ? sprintf('%s was killed by signal %d', $program, $status & 127)
        : sprintf('%s exited with status %d', $program, $status >> 8);
    }
  }
  croak "Devel::ebug: lost the connection to the debugger; $what";
}

sub talk {
  my($self, $req) = @_;
  croak "Devel::ebug: the program is running; call wait_for_stop() before '$req->{command}'"
    if $self->running;
  $self->_send($req);
  return $self->_receive;
}

sub _send {
  my($self, $req) = @_;
  my $format = $self->_serializer;
  # Writing to a debugger that has gone away raises SIGPIPE, which would
  # kill the frontend outright; turn it into an error that can be caught.
  local $SIG{PIPE} = 'IGNORE';
  $self->socket->print(Devel::ebug::Wire::encode($format, $req) . "\n")
    or $self->_lost;
}

# Read one response.  A closed connection is an error, unless $allow_eof
# is true, in which case it returns undef.
sub _receive {
  my($self, $allow_eof) = @_;
  my $socket = $self->socket;
  my $data = <$socket>;
  unless (defined $data) {
    return undef if $allow_eof;
    $self->_lost;
  }

  # The backend answers in the format it was asked in, but detect rather
  # than assume: it costs nothing and keeps a mismatch from being silent.
  return Devel::ebug::Wire::decode(Devel::ebug::Wire::detect($data), $data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug - A simple, extensible Perl debugger

=head1 VERSION

version 0.68

=head1 SYNOPSIS

  use Devel::ebug;
  my $ebug = Devel::ebug->new;
  $ebug->program("calc.pl");
  $ebug->load;
 
  print "At line: "       . $ebug->line       . "\n";
  print "In subroutine: " . $ebug->subroutine . "\n";
  print "In package: "    . $ebug->package    . "\n";
  print "In filename: "   . $ebug->filename   . "\n";
  print "Code: "          . $ebug->codeline   . "\n";
  $ebug->step;
  $ebug->step;
  $ebug->next;
  my($stdout, $stderr) = $ebug->output;
  my $actual_line = $ebug->break_point(6);
  $ebug->break_point(6, '$e == 4');
  $ebug->break_point("t/Calc.pm", 29);
  $ebug->break_point("t/Calc.pm", 29, '$i == 2');
  $ebug->break_on_load("t/Calc.pm");
  my $actual_line = $ebug->break_point_subroutine("main::add");
  $ebug->break_point_delete(29);
  $ebug->break_point_delete("t/Calc.pm", 29);
  my @filenames    = $ebug->filenames();
  my @break_points = $ebug->break_points();
  my @break_points = $ebug->break_points("t/Calc.pm");
  my @break_points = $ebug->break_points_with_condition();
  my @break_points = $ebug->break_points_with_condition("t/Calc.pm");
  my @break_points = $ebug->all_break_points_with_condition();
  $ebug->watch_point('$x > 100');
  my $codelines = $ebug->codelines(@span);
  $ebug->run;
  my $pad  = $ebug->pad;
  foreach my $k (sort keys %$pad) {
    my $v = $pad->{$k};
    print "Variable: $k = $v\n";
  }
  my $v = $ebug->eval('2 ** $exp');
  my( $v, $is_exception ) = $ebug->eval('die 123');
  my $y = $ebug->yaml('$z');
  my @frames = $ebug->stack_trace;
  my @frames2 = $ebug->stack_trace_human;
  $ebug->undo;
  $ebug->return;
  print "Finished!\n" if $ebug->finished;

=head1 DESCRIPTION

A debugger is a computer program that is used to debug other
programs. L<Devel::ebug> is a simple, extensible Perl debugger with a
clean API. Using this module, you may easily write a Perl debugger to
debug your programs. Alternatively, it comes with an interactive
debugger, L<ebug>.

perl5db.pl, Perl's current debugger is currently 2,600 lines of magic
and special cases. The code is nearly unreadable: fixing bugs and
adding new features is fraught with difficulties. The debugger has no
test suite which has caused breakage with changes that couldn't be
properly tested. It will also not debug regexes. L<Devel::ebug> is
aimed at fixing these problems and delivering a replacement debugger
which provides a well-tested simple programmatic interface to
debugging programs. This makes it easier to build debuggers on top of
L<Devel::ebug>, be they console-, curses-, GUI- or Ajax-based.

There are currently two user interfaces to L<Devel::debug>, L<ebug>
and L<ebug_http>. L<ebug> is a console-based interface to debugging
programs, much like perl5db.pl. L<ebug_http> is an innovative
web-based interface to debugging programs.

Note that if you're debugging a program, you can invoke the debugger
in the program itself by using the INT signal:

  kill 2, $$ if $square > 100;

L<Devel::ebug> is a work in progress.

Internally, L<Devel::ebug> consists of two parts. The frontend is
L<Devel::ebug>, which you interact with. The frontend starts the code
you are debugging in the background under the backend (running it
under perl -d:ebug code.pl), and the two talk over a TCP socket on
localhost, which the frontend uses to drive the backend. This adds some
flexibility in the debugger.

When L</load> starts the program, the frontend listens on a port chosen
by the operating system and passes it to the backend in the
C<DEVEL_EBUG_CONNECT> environment variable, along with a random secret
word in C<SECRET>. The backend connects back to that port and sends the
secret before anything else, so the frontend can tell it apart from
anything else that connects. Because the port is chosen by the operating
system, any number of debugging sessions can run concurrently.

Without C<DEVEL_EBUG_CONNECT>, the backend instead listens on a port from
3141-4165 derived from the secret, and waits for a frontend to attach
with that secret, as L<ebug_server> and L<ebug_client> do. A frontend
with the wrong secret is turned away without ending the session.

=head1 CONSTRUCTOR

=head2 new

The constructor creats a L<Devel::ebug> object:

  my $ebug = Devel::ebug->new;

=head2 program

The program method selects which program to load:

  $ebug->program("calc.pl");

The program is run through the shell, so it may also carry arguments for
the program (C<"add.pl 3 4">), subject to the shell's word splitting and
interpolation.  To pass arguments that must arrive exactly as given, set
L</args> instead.

=head2 args

The args method sets the command-line arguments for the program, as an
array reference:

  $ebug->program("add.pl");
  $ebug->args([ 3, "four and a half" ]);

When args is set the program is started without going through the shell,
so each argument reaches the program's C<@ARGV> unchanged, even if it
contains spaces, quotes or other shell metacharacters.  In that case
L</program> is taken as the path of the program alone.  The arguments are
used again each time the program is restarted, for example by C<undo>.

=head2 serializer

The serializer method selects how requests and responses are written on the
socket between the frontend and the backend:

  $ebug->serializer("json");

C<yaml> is the default and is what every existing client speaks: L<YAML>
output, hex packed onto a single line.  C<json> writes one plain JSON object
per line instead, which is the format to choose when the other end is not
Perl - a JSON line can be read by anything, whereas hex packed YAML asks a
client for a YAML parser, object deserialization and a hex decoder first.

It can also be set with the C<DEVEL_EBUG_SERIALIZER> environment variable,
which is how to choose the format for a frontend you do not construct
yourself, such as L<ebug_client>.

The backend replies in whichever format each request arrived in, so nothing
has to be arranged with it beforehand.  Selecting C<json> uses
L<Cpanel::JSON::XS> if it is installed, and otherwise requires L<JSON::PP>,
which has shipped with perl since 5.14 but is not otherwise a prerequisite
of this distribution.

See L<Devel::ebug::Wire> for the details of both formats.

=head2 load

The load method loads the program and gets ready to debug it:

  $ebug->load;

=head1 METHODS

If the program being debugged goes away without the debugger's help, for
example because it was killed, crashed in XS code or called
C<POSIX::_exit>, any method that talks to it croaks with an error that
begins C<Devel::ebug: lost the connection to the debugger>. For a program
started with L</load>, the error also says how it ended.

=head2 break_point

The break_point method sets a break point in a program. If you are
running through a program, the execution will stop at a break point.
Break points can be set in a few ways.

A break point can be set at a line number in the current file:

  my $actual_line = $ebug->break_point(6);

A break point can be set at a line number in the current file with a
condition that must be true for execution to stop at the break point:

  my $actual_line = $ebug->break_point(6, '$e = 4');

A break point can be set at a line number in a file:

  my $actual_line = $ebug->break_point("t/Calc.pm", 29);

A break point can be set at a line number in a file with a condition
that must be true for execution to stop at the break point:

  my $actual_line = $ebug->break_point("t/Calc.pm", 29, '$i == 2');

Breakpoints can not be set on some lines (for example comments); in
this case a breakpoint will be set at the next breakable line, and the
line number will be returned. If no such line exists, no breakpoint is
set and the function returns C<undef>.

=head2 break_on_load

Set a breakpoint on file loading, the file name can be relative or absolute.

=head2 break_point_delete

The break_point_delete method deletes an existing break point. A break
point at a line number in the current file can be deleted:

  $ebug->break_point_delete(29);

A break point at a line number in a file can be deleted:

  $ebug->break_point_delete("t/Calc.pm", 29);

=head2 break_point_subroutine

The break_point_subroutine method sets a break point in a program
right at the beginning of the subroutine. The subroutine is specified
with the full package name:

  my $line = $ebug->break_point_subroutine("main::add");
  $ebug->break_point_subroutine("Calc::fib");

It takes an optional condition, as L</break_point> does, so that the
program only stops when the condition is true. At that point the
subroutine has just been called, so C<@_> holds its arguments:

  $ebug->break_point_subroutine("Calc::fib", '$_[1] > 5');

The return value is the line at which the break point is set.

=head2 break_points

The break_points method returns a list of all the line numbers in a
given file that have a break point set.

Return the list of breakpoints in the current file:

  my @break_points = $ebug->break_points();

Return the list of breakpoints in a given file:

  my @break_points = $ebug->break_points("t/Calc.pm");

=head2 break_points_with_condition

The break_points method returns a list of break points for a given file.

Return the list of breakpoints in the current file:

  my @break_points = $ebug->break_points_with_condition();

Return the list of breakpoints in a given file:

  my @break_points = $ebug->break_points_with_condition("t/Calc.pm");

Each element of the list has the form

  { filename  => "t/Calc.pm",
    line      => 29,
    condition => "$foo > 12",
    }

where C<condition> might not be present.

=head2 all_break_points_with_condition

Like C<break_points_with_condition> but returns a list of break points
for the whole program.

=head2 codeline

The codeline method returns the line of code that is just about to be
executed:

  print "Code: "          . $ebug->codeline   . "\n";

=head2 codelines

The codelines method returns lines of code.

It can return all the code lines in the current file:

  my @codelines = $ebug->codelines();

It can return a span of code lines from the current file:

  my @codelines = $ebug->codelines(1, 3, 4, 5);

It can return all the code lines in a file:

  my @codelines = $ebug->codelines("t/Calc.pm");

It can return a span of code lines in a file:

  my @codelines = $ebug->codelines("t/Calc.pm", 5, 6);

=head2 eval

The eval method evaluates Perl code in the current program and returns
the result. If the evaluation results in an exception, C<$@> is
returned.

  my $v = $ebug->eval('2 ** $exp');

In list context, eval also returns a flag indicating if the evaluation
resulted in an exception.

  my( $v, $is_exception ) = $ebug->eval('die 123');

=head2 filename

The filename method returns the filename of the currently running code:

  print "In filename: "   . $ebug->filename   . "\n";

=head2 filenames

The filenames method returns a list of the filenames of all the files
currently loaded:

  my @filenames = $ebug->filenames();

=head2 finished

The finished method returns whether the program has finished running:

  print "Finished!\n" if $ebug->finished;

=head2 interrupt

The interrupt method asks a running program to stop at the next statement,
as if a break point were there. It is meant for a program started with
L</run_nowait>, or for calling from a signal handler during L</run>:

  $ebug->run_nowait;
  ...
  $ebug->interrupt;
  $ebug->wait_for_stop;

It returns true if the program was signalled, and false without doing
anything if the program is not running. Call L</wait_for_stop> afterwards
to find out where it stopped.

Interrupting works by sending C<SIGINT> to the program, so it is only
supported for a program started with L</load> on the same host, and not on
Windows; it croaks otherwise. Like pressing Ctrl-C, it takes effect once
the program next executes a Perl statement, so a long call into XS code
finishes first.

=head2 line

The line method returns the line number of the statement about to be
executed:

  print "At line: "       . $ebug->line       . "\n";

=head2 next

The next method steps onto the next line in the program. It executes
any subroutine calls but does not step through them.

  $ebug->next;

=head2 output

The output method returns any content the program has output to either
standard output or standard error:

  my($stdout, $stderr) = $ebug->output;

=head2 package

The package method returns the package of the currently running code:

  print "In package: "    . $ebug->package    . "\n";

=head2 pad

  my $pad  = $ebug->pad;
  foreach my $k (sort keys %$pad) {
    my $v = $pad->{$k};
    print "Variable: $k = $v\n";
  }

=head2 pid

The pid method returns the process id of the program being debugged, as
reported by the program itself. This can differ from the process started
by L</load> when the program is run through the shell.

=head2 return

The return subroutine returns from a subroutine. It continues running
the subroutine, then single steps when the program flow has exited the
subroutine:

  $ebug->return;

It can also return your own values from a subroutine, for testing
purposes:

  $ebug->return(3.141);

=head2 run

The run subroutine starts executing the code. It will only stop on a
break point, a watch point, an L</interrupt> or the end of the program.
To start running without waiting for it to stop, see L</run_nowait>.

  $ebug->run;

=head2 run_nowait

The run_nowait method starts executing the code like L</run>, but returns
straight away instead of waiting for the program to stop:

  $ebug->run_nowait;

While the program is running, the only methods that may be called are
L</interrupt>, L</running> and L</wait_for_stop>; anything else croaks.
The L</socket> becomes readable when the program stops, so a frontend with
an event loop can wait on it rather than calling L</wait_for_stop> right
away.

=head2 running

The running method returns true between L</run_nowait> and
L</wait_for_stop>:

  print "still going\n" if $ebug->running;

=head2 socket

The socket method returns the socket connected to the program being
debugged. Do not read from or write to it; it is only useful for waiting,
for example with L<IO::Select>, for it to become readable after
L</run_nowait>.

=head2 step

The step method steps onto the next line in the program. It steps
through into any subroutine calls.

  $ebug->step;

=head2 subroutine

The subroutine method returns the subroutine of the currently working
code:

  print "In subroutine: " . $ebug->subroutine . "\n";

=head2 stack_trace

The stack_trace method returns the current stack trace, using
L<Devel::StackTrace>. It returns a list of L<Devel::StackTraceFrame>
methods:

  my @traces = $ebug->stack_trace;
  foreach my $trace (@traces) {
    print $trace->package, "->",$trace->subroutine,
    "(", $trace->filename, "#", $trace->line, ")\n";
  }

=head2 stack_trace_human

The stack_trace_human method returns the current stack trace in a human-readable format:

  my @traces = $ebug->stack_trace_human;
  foreach my $trace (@traces) {
    print "$trace\n";
  }

=head2 undo

The undo method undoes the last action. It accomplishes this by
restarting the process and passing (almost) all the previous commands
to it. Note that commands which do not change state are
ignored. Commands that change state are: break_point, break_point_delete,
break_point_subroutine, eval, next, step, return, run and watch_point.

  $ebug->undo;

It can also undo multiple commands:

  $ebug->undo(3);

=head2 wait_for_stop

The wait_for_stop method waits for a program started with L</run_nowait>
to stop, at a break point, a watch point, an L</interrupt> or the end of
the program, and updates L</filename>, L</line> and so on to match:

  $ebug->wait_for_stop;
  print $ebug->filename, ":", $ebug->line, "\n";

It returns straight away if the program is not running.

=head2 watch_point

The watch point method sets a watch point. A watch point has a
condition, and the debugger will stop running as soon as this
condition is true:

  $ebug->watch_point('$x > 100');

=head2 yaml

The eval method evaluates Perl code in the current program and returns
the result of YAML's Dump() method:

  my $y = $ebug->yaml('$z');

=head1 SEE ALSO

=over 4

=item L<perldebguts>

The guts of debugging Perl

=item L<Devel::Chitin>

A class that exposes the Perl debugging facilities as an API, with
some functional overlap with L<Devel::ebug>.

=item L<ebug>

Command-line interface to L<Devel::ebug>

=item L<ebug_http>

Web based interface to L<Devel::ebug>

=back

=head1 CAVEATS

L<Devel::ebug> does not support Perls prior to 5.10.1.

L<Devel::ebug> does not handle signals under Windows.

Running C<perl -d:ebug script.pl> directly does not work, and will fail
with C<No DB::DB routine defined>. L<Devel::ebug> is the frontend class;
it is not itself a C<-d> debugger backend. The backend is the internal
L<Devel::ebug::Backend> module, which is invoked automatically as
C<perl -d:ebug::Backend script.pl> when you call C<< $ebug->load >>. To
debug a script, either use the L<ebug> command, or use L<Devel::ebug>
programmatically:

  my $ebug = Devel::ebug->new;
  $ebug->program('script.pl');
  $ebug->load;

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

Richard Leach (HYDAHY)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2026 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
