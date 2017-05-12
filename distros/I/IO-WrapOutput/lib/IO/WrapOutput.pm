package IO::WrapOutput;
BEGIN {
  $IO::WrapOutput::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $IO::WrapOutput::VERSION = '0.07';
}

use strict;
use warnings FATAL => 'all';
use Carp 'croak';
use IO::Handle;
use Symbol 'gensym';
use base 'Exporter';

our @EXPORT      = qw(wrap_output unwrap_output);
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = (ALL => [@EXPORT]);

my ($orig_stderr, $orig_stdout);

sub wrap_output {
    # 2-arg open() here because Perl 5.6 doesn't understand the '>&' mode
    # with a 3-arg open
    open $orig_stdout, '>&'.fileno(STDOUT) or croak("Can't dup STDOUT: $!");
    open $orig_stderr, '>&'.fileno(STDERR) or croak("Can't dup STDERR: $!");

    my ($read_stdout, $write_stdout) = (gensym(), gensym());
    pipe $read_stdout, $write_stdout;
    open STDOUT, '>&'.fileno($write_stdout) or croak("Can't pipe STDOUT: $!");

    my ($read_stderr, $write_stderr) = (gensym(), gensym());
    pipe $read_stderr, $write_stderr;
    open STDERR, '>&'.fileno($write_stderr) or croak("Can't pipe STDERR: $!");
    STDERR->autoflush(1);

    return $read_stdout, $read_stderr;
}

sub unwrap_output {
    open STDOUT, '>&'.fileno($orig_stdout) or croak("Can't dup STDOUT: $!");
    open STDERR, '>&'.fileno($orig_stderr) or croak("Can't dup STDERR: $!");
    STDERR->autoflush(1);
    return;
}

1;

=encoding utf8

=head1 NAME

IO::WrapOutput - Wrap your output filehandles with minimal fuss

=head1 SYNOPSIS

 use IO::WrapOutput;
 use Module::Which::Hogs::STDOUT::And::STDERR;

 my $foo = Module::Which::Hogs::STDOUT::And::STDERR->new();
 my ($stdout, $stderr) = wrap_output();

 # read from $stdout and $stderr

 # then, later, restore the original handles
 $foo->shutdown;
 unwrap_output();


 # example using POE::Wheel::ReadLine
 use strict;
 use warnings;
 use IO::WrapOutput;
 use POE;
 use POE::Wheel::ReadLine;
 use POE::Wheel::ReadWrite;

 POE::Session->create(
     package_states => [main => [qw(_start got_output got_input)]],
 );

 $poe_kernel->run();

 sub _start {
     my ($heap) = $_[HEAP];

     $heap->{console} = POE::Wheel::ReadLine->new(
         InputEvent => 'got_input',
     );

     my ($stdout, $stderr) = wrap_output();
     $heap->{stdout_reader} = POE::Wheel::ReadWrite->new(
         Handle     => $stdout,
         InputEvent => 'got_output',
     );
     $heap->{stderr_reader} = POE::Wheel::ReadWrite->new(
         Handle     => $stderr,
         InputEvent => 'got_output',
     );

     # request the first line
     $heap->{console}->get('>');
 }

 sub got_output {
     my ($heap, $line) = @_[HEAP, ARG0];
     $heap->{console}->put($line);
 }

 sub got_input {
     my ($heap, $line, $exception) = @_[HEAP, ARG0, ARG1];

     if (defined $exception && $exception eq 'interrupt') {
         # terminate the console
         unwrap_output();
         delete $heap->{console};
         delete $heap->{stdout_reader};
         delete $heap->{stderr_reader};
         print "Terminated\n";
         return;
     }

     # do something with $line ...

     # request the next line
     $heap->{console}->get();
 }

=head1 DESCRIPTION

When you have a module (e.g. POE::Wheel::ReadLine) which needs all output
to go through a method that it provides, it can be cumbersome (or even
impossible) to change all the code in an asynchronous/event-driven program
to do that instead of printing directly to STDOUT/STDERR. That's
where C<IO::WrapOutput> comes in.

You just do the setup work for the output-hogging module in question, then
call C<wrap_output> which will return filehandles that you can read from.
Then you take what you get from those filehandles and feed it into your
output-hogging module's output method. After you stop using the
output-hogging module, you can restore your original STDOUT/STDERR handles
with C<unwrap_output>.

=head1 FUNCTIONS

=head2 C<wrap_output>

Takes no arguments. Replaces the current STDOUT and STDERR handles with
pipes, and returns the read ends of those pipes back to you. Any copies
made of the STDOUT/STDERR handles before calling this function will still
be attached to the process' terminal.

 my ($stdout, $stderr) = wrap_output();

=head2 C<unwrap_output>

Takes no arguments. Restores the original STDOUT and STDERR handles.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
