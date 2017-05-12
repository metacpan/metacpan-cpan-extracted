
=head1 NAME

GTM::Run - run interactive processes 

=head1 SYNOPSIS

   use GTM::Run;

   my $hdl = new GTM::Run ("mumps -direct");
   $hdl->expect(
        qr/GTM\>/,
        qr/^%.*/m,
        sub {
            die $_[1] if $_[2];
            shift->write ("D ^\%GO\n");
        }
   );

=head1 DESCRIPTION

This module is a helper-module for running interactive
processes in a "expect"-like way.

=head1 METHODS

=over 4

=cut

package GTM::Run;
use common::sense;
use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;
use POSIX qw(setsid dup2 _exit waitpid);
use re 'eval';
use GTM qw(set_busy output %override);

our $VERSION = $GTM::VERSION;
our $midx;

=item $handle = B<new> GTM::Run ($command)

Creates a GTM::Run object.
The $command is either a single string, which is then passed to a shell, or an arrayref,
which is passed to the "execvp" function.
If command is not a fully qualified command (ie: starts not with /) $ENV{gtm_dist} will be prepended.

=cut 

sub new {
    my ($class, $cmd) = @_;
    my $self = bless {@_}, $class;
    if (ref $cmd eq "ARRAY") {
        $cmd->[0] = "$ENV{gtm_dist}/$cmd->[0]" unless $cmd->[0] =~ m@^/@;
    } else {
        $cmd = "$ENV{gtm_dist}/$cmd" unless $cmd =~ m@^/@;
    }

    my ($fh1, $fh2) = portable_socketpair;
    my $pid = fork;
    if (!defined $pid) {
        die "can't fork: $!";
    }
    if (!$pid) {
        setsid;
        close $fh2;
        dup2 (fileno $fh1, 0);
        dup2 (fileno $fh1, 1);
        dup2 (fileno $fh1, 2);
        close $fh1;
        local %ENV = (%ENV, %override);
        ref $cmd
          ? exec {$cmd->[0]} @$cmd
          : exec $cmd;

        _exit (99);
    }
    my $hdl = new AnyEvent::Handle (
        fh       => $fh2,
        no_delay => 1,
        on_error => sub {
            my ($hdl, $fatal, $msg) = @_;
            die "on_error fatal=$fatal msg=\"$msg\"\n";
            $hdl->destroy;
        },

    );
    $self->{pid} = $pid;
    $self->{hdl} = $hdl;
    set_busy (1);
    $self;
}

sub merge_regexp (@) {
    my @re = @_;
    @re = map { qr{(?:$_(?{$GTM::Run::midx= mArK;}))}x } @re;
    my $r = join "|", @re;
    $r =~ s/mArK/$_/ for (0 .. @re - 1);
    $r;
}

=item $handle->B<close> ()

Closes the command. This runs waitpid so be sure that your command will terminate.
For mumps this means that "Halt\n" must be written before.

=cut

sub close ($) {
    my $self = shift;
    my $hdl  = $self->{hdl};
    die "already closed" if $self->{closed};
    $hdl->on_eof   (undef);
    $hdl->on_error (sub { });
    $hdl->on_read  (sub { });
    $self->flush;
    $hdl->destroy;
    waitpid ($self->{pid}, 0) if kill (0, $self->{pid});
    set_busy (0);
    $self->{closed} = 1;

}

=item $handle->B<write> ($data, ...)

writes $data to the process

=cut

sub write ($@) {
    my $self = shift;
    my $hdl  = $self->{hdl};
    $hdl->push_write (join "", @_);
}

our $expect_debug = 0;

=item $handle->B<debug> ($bool)

writes regular expression debug-info to STDERR if enabled.
Here an example:

    $self->expect(
        qr/^No globals selected/m,
        qr/^Header Label:/m,
        sub {
           ...
        },
   );

This writes:

  RE: (?m-xis:^No globals selected) == 0
  RE: (?m-xis:^Header Label:) == 1
  RE: match index == 1

if debugging is enabled.

=cut

sub debug ($$) {
    $expect_debug = !!$_[1];
}

=item $handle->B<expect> ($re0, [$re1,...,] &cb [, $re .... &cb])

Waits for input that matches one of the given regular expressions.
&cb will be invoked with three arguments: $class, $data, $reidx.
$reidx is the index of the regular expression that matched.

A callback may die - B<close> will be invoked and the die
gets propagated.
Subsequent callbacks within the same expect-call will be skipped. 

=cut

sub expect($@) {
    my $self = shift;
    my $hdl  = $self->{hdl};
    my @re;
    my $mre;
    my $done;
    my $die;
    for my $i (@_) {
        if (ref $i eq "Regexp") {
            push @re, $i;
            next;
        }
        die "expected code-ref or regexp" if (ref $i ne "CODE");
        my $mre = merge_regexp (@re);
        my @xre = @re;
        my $cv  = AnyEvent->condvar;
        local $midx;
        $hdl->push_read (
            regex => $mre,
            sub {
                return if $done;
                if ($expect_debug) {
                    for (my $i = 0 ; $i < @xre ; $i++) {
                        print STDERR "RE: $xre[$i] == $i\n";
                    }
                    print STDERR "RE: match index == $midx\n\n";
                }
                eval { $i->($self, $_[1], $midx); };
                if ($@) {
                    $done = 1;
                    $die  = $@;
                    $self->close;
                }
                $cv->send;
            },
        );
        @re = ();

        $cv->recv;
        die $die if $die;
    }
}

sub DESTROY {
    my $hdl = shift;
    $hdl->close unless $hdl->{closed};
}

=item $hdl->B<flush> ()

Waits until the output buffer is empty.

=cut

sub flush ($) {
    my $self = shift;
    my $hdl  = $self->{hdl};
    my $cv   = AnyEvent->condvar;
    $hdl->on_drain (sub { $cv->send });
    $cv->recv;

}

=back

=head1 SEE ALSO

L<GTM>

=head1 AUTHOR

   Stefan Traby <stefan@hello-penguin.com>
   http://oesiman.de/gt.m/

=cut

1;

