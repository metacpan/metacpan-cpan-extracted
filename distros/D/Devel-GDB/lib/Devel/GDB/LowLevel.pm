package Devel::GDB::LowLevel;

use 5.006;
use strict;
use warnings;

use FileHandle;
use IPC::Open2;
use POSIX;

use threads::shared;

=head1 NAME

Devel::GDB::LowLevel - Low-level interface for communicating with GDB

=head1 DESCRIPTION

This module is used internally by L<Devel::GDB>.  It handles the low-level I/O
of communicating with the GDB process.

=cut

our $VERSION = '2.0';
our $DEBUG;

our %PARAMS;

=head1 CONSTRUCTOR

=over

=item new

Spawns a GDB process.  Because this class only facilitates communication with
GDB (I<not> with the inferior process being debugged), you have to decide what
to do with the C<STDIN>, C<STDOUT>, and C<STDERR> of that process.  There are a
few options available:

=over

=item *

If STDIN is a tty, we can have the inferior process communicate directly
with the controlling tty (emulating the default behavior of gdb):

    $gdb = new Devel::GDB::LowLevel( '-execfile' => $path_to_gdb,
                                     '-params'   => $extra_gdb_params );

=item *

Or, we can create an C<Expect> object to communicate with the inferior process:

    $gdb = new Devel::GDB::LowLevel( '-create-expect' => 1 );
    $expect = $gdb->get_expect_obj();


=item *

Or, we can create our own tty and use that:

    $gdb = new Devel::GDB::LowLevel( '-use-tty' => '/dev/pts/123' );

=back

=back

=cut

sub new
{
    my $class = shift or die "Who am I? no class provided. please read the manual\n" ;

    # Load parameters
    my $self = bless
      { '-execfile'    => 'gdb',                        # gdb executable
        '-params'      => '' ,                          # additional parameters
        @_ }, $class ;

    # Complain about any invalid parameters
    foreach (keys %$self)
    {
        die "$class: Invalid parameter $_"
            unless /^-(execfile|params|use-tty|create-expect)$/;
    }

    die "Cannot use both -use-tty and -create-expect!"
        if $self->{'-use-tty'} && $self->{'-create-expect'};

    # Create the TX lock
    $self->{LOCK_tx} = &share(\my $tmp);

    # Create a tty if necessary
    my $tty = $self->{'-use-tty'} ||
              $self->{'-create-expect'} && $self->_new_expect() ||
              ttyname(0)
        or die "$class: STDIN must be a tty when neither -use-tty nor -create-expect are specified";

    # Build the parameter list
    my @params = (ref $self->{'-params'} eq 'ARRAY') ? @{$self->{'-params'}} : split(/\s+/, $self->{'-params'});

    unshift @params, '--interpreter=mi';
    unshift @params, "--tty=$tty";

    # Open the GDB pipe (Note that open2 will die if the fork() fails, but if
    # exec() fails, we'll just get a SIGPIPE later.)
    @{$self}{qw/PID IN OUT/}  = $self->_pipe_open( $self->{'-execfile'}, @params );

    return $self;
}

=head1 METHODS

=over

=item send

Sends a raw line of text to GDB.  This should not contain any newlines (they
will be stripped).  This method only sends a request, and does not wait for a
response.

=cut

sub send
{
    my $self = shift;
    my ($line) = @_;

    $line =~ s/[\r\n]//s;

    {
        local $\ = "\n";
        lock $self->{LOCK_tx};

        my $fh = $self->{OUT};
        print $fh $line;
        print STDERR ">>> $line"
            if $DEBUG;
    }
}

=item get_reader

Returns the file handle from which to read GDB responses.

=cut

sub get_reader
{
    my $self = shift;
    return $self->{IN};
}

=item get_expect_obj

Returns the C<Expect> object created in the constructor.  Dies if 
C<'-create-expect'> was not passed to C<new>.

=cut

sub get_expect_obj
{
    my $self = shift;
    $self->{expect_obj} or die;
}

=item interrupt

Send SIGINT to the GDB session, interrupting the inferior process
(if any).

=cut

sub interrupt
{
    my $self = shift;
    kill 2, $self->{PID};
}

sub _new_expect
{
    require Expect;

    my $self = shift;

    $self->{expect_obj} = new Expect;
    $self->{expect_obj}->log_stdout(0);

    # Disable echo on the pty
    my $fd = fileno($self->{expect_obj});
    my $termios = new POSIX::Termios;
    $termios->getattr($fd);
    $termios->setlflag($termios->getlflag & ~&POSIX::ECHO);
    $termios->setattr($fd);

    return $self->{expect_obj}->slave->ttyname;
}

sub _pipe_open
{
    my $self = shift;
    my @cmd = @_;

    $SIG{PIPE} = sub { $self->_pipe_sig(); };
    my ($in, $out) = (new FileHandle, new FileHandle) ;
    my $pid = open2($in, $out, @cmd) ;
    ($pid, $in, $out)
}

sub _pipe_sig
{
    my $self = shift;

    # Check if $self->{PID} is really dead?

    die "SIGPIPE: GDB terminated unexpectedly?";
}

1;

__END__

=back

=head1 SEE ALSO

L<IPC::Open2>

=head1 AUTHORS

Antal Novak E<lt>afn@cpan.orgE<gt>, Josef Ezra E<lt>jezra@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Antal Novak & Josef Ezra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
