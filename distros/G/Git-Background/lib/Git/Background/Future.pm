package Git::Background::Future;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.003';

use Future 0.40;

use parent 'Future';

use File::Temp qw(:seekable);

sub new {
    my ( $class, $run ) = @_;

    my $self = $class->SUPER::new;
    $self->{_run} = $run;
    return $self;
}

sub await {
    my ($self) = @_;

    return $self if $self->{ready};

    return $self->fail( q{internal error: cannot find '_run'}, 'internal' ) if !defined $self->{_run};
    my $run = delete $self->{_run};

    my $e;
    my $ok = 1;
    {
        local $@;    ## no critic (Variables::RequireInitializationForLocalVars)
        $ok = eval {

            # prevent the "(in cleanup) process is already terminated" message
            $run->{_proc}->autoterminate(0);

            # wait for the process to finish
            $run->{_proc}->wait;

            1;
        };

        if ( !$ok ) {

            # The Future->fail exception must be true
            $e = qq{$@} || 'Failed to wait on Git process with Proc::Background';
        }
    }
    return $self->fail( $e, 'Proc::Background' ) if !$ok;

    # slurp back stdout
    my $stdout_fh = $run->{_stdout};
    $stdout_fh->seek( 0, SEEK_SET ) or return $self->fail( "Cannot seek stdout: $stdout_fh: $!", 'seek' );
    my @stdout = split /\r?\n/m, do {    ## no critic (RegularExpressions::RequireDotMatchAnything, RegularExpressions::RequireExtendedFormatting])
        local $/;                        ## no critic (Variables::RequireInitializationForLocalVars)
        scalar <$stdout_fh>;
    };
    return $self->fail( "Cannot read stdout: $stdout_fh: $!", 'readline' ) if $stdout_fh->error;

    # slurp back stderr
    my $stderr_fh = $run->{_stderr};
    $stderr_fh->seek( 0, SEEK_SET ) or return $self->fail( "Cannot seek stderr: $stderr_fh: $!", 'seek' );
    my @stderr = split /\r?\n/m, do {    ## no critic (RegularExpressions::RequireDotMatchAnything, RegularExpressions::RequireExtendedFormatting])
        local $/;                        ## no critic (Variables::RequireInitializationForLocalVars)
        scalar <$stderr_fh>;
    };
    return $self->fail( "Cannot read stderr: $stderr_fh: $!", 'readline' ) if $stderr_fh->error;

    # get exit code and signal from git process
    my $exit_code = $run->{_proc}->exit_code;

    my @result = (
        \@stdout,
        \@stderr,
        $exit_code,
    );

    # git died by a signal
    return $self->fail( 'Git was terminated by a signal', 'Proc::Background', @result ) if $run->{_proc}->exit_signal;

    if (
        # fatal error
        ( $exit_code == 128 ) ||

        # usage error
        ( $exit_code == 129 ) ||

        # non-zero return code
        ( $exit_code && $run->{_fatal} )
      )
    {

        my $stderr  = join "\n", @stderr;
        my $message = length $stderr ? $stderr : "git exited with fatal exit code $exit_code but had no output to stderr";

        # $run goes out of scope and the file handles and the proc object are freed
        return $self->fail( $message, 'git', @result );
    }

    # $run goes out of scope and the file handles and the proc object are freed
    return $self->done(@result);
}

sub exit_code {
    my ($self) = @_;

    my @result = $self->get;
    return $result[2];
}

sub is_done {
    my ($self) = @_;
    $self->_await_if_git_is_done;
    return $self->SUPER::is_done;
}

sub is_failed {
    my ($self) = @_;
    $self->_await_if_git_is_done;
    return $self->SUPER::is_failed;
}

sub is_ready {
    my ($self) = @_;
    $self->_await_if_git_is_done;
    return $self->SUPER::is_ready;
}

sub state {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self) = @_;
    $self->_await_if_git_is_done;
    return $self->SUPER::state;
}

sub stderr {
    my ($self) = @_;

    my @result = $self->get;
    return @{ $result[1] };
}

sub stdout {
    my ($self) = @_;

    my @result = $self->get;
    return @{ $result[0] };
}

sub _await_if_git_is_done {
    my ($self) = @_;

    if ( defined $self->{_run} && !$self->{_run}{_proc}->alive ) {
        $self->await;
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Background::Future - use L<Future> with L<Git::Background>

=head1 VERSION

Version 0.003

=head1 SYNOPSIS

    use Git::Background 0.002;
    my $future = Git::Background->run(qw(status -s));

    my @stdout = $future->stdout;

    my ($stdout_ref, $stderr_ref, $exit_code) = $future->get;

=head1 DESCRIPTION

This is a subclass of L<Future>. Please read the excellent documentation of
C<Future> to see what you can do with this module, this man page only
describes the changes to C<Future> specific to L<Git::Background>.

=head1 USAGE

=head2 new( RUN )

New C<Git::Background::Future> objects should be constructed by using the
C<run> method of L<Git::Background>.

=head2 await

Blocks and waits until the Git process finishes. Returns a finished future.

This method is called by C<get> or C<failure>.

=head2 exit_code

Calls C<get>, then returns the exit code of the Git process.

=head2 failure

Waits for the running Git process to finish by calling C<await>. Returns
undef if the future finished successfully, otherwise it returns a list with

    $message, $category, @details

For the C<$category> C<git> C<@details> is a list of C<stdout_ref>,
C<stderr_ref>, and C<exit_code>.

=head2 get

Waits for the running Git process to finish by calling C<await>. Throws a
L<Future::Exception> if the C<Future> didn't finish successfully. Returns
the stdout, stderr and exit code of the Git process.

    my $git = Git::Background->new($dir);
    my $future = $git->run('status', '-s');
    # waits for 'git status -s' to finish
    my ($stdout_ref, $stderr_ref, $rc) = $future->get;

=head2 is_done

L<Future/is_dome>

=head2 is_failed

L<Future/is_failed>

=head2 is_ready

L<Future/is_ready>

=head2 state

L<Future/state>

=head2 stderr

Calls C<get>, then returns all the lines written by the Git command to
stderr.

Because this command calls C<get>, the same exceptions can be thrown.

Note: C<get> returns all the output lines as array reference, C<stderr>
returns a list.

=head2 stdout

Calls C<get>, then returns all the lines written by the Git command to
stdout.

Because this command calls C<get>, the same exceptions can be thrown.

Note: C<get> returns all the output lines as array reference, C<stdout>
returns a list.

=head1 SEE ALSO

L<Git::Background>, L<Future>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Git-Background/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Git-Background>

  git clone https://github.com/skirmess/Git-Background.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2022 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
