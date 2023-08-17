# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2021-2023 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.010;
use strict;
use warnings;

package Git::Background::Future;

our $VERSION = '0.008';

use Future 0.49;
use parent 'Future';

sub new {
    my ( $class, $run ) = @_;

    my $self = $class->SUPER::new;
    $self->set_udata( '_run', $run );
    return $self;
}

sub await {
    my ($self) = @_;

    my $run = $self->udata('_run');

    return $self if !defined $run;

    $self->set_udata( '_run', undef );

    my $e;
    my $ok;
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

    my $stdout_file = $run->{_stdout};
    my $stderr_file = $run->{_stderr};
    my @stdout;
    my @stderr;
    {
        local $@;    ## no critic (Variables::RequireInitializationForLocalVars)
        $ok = eval {
            $e      = 'Cannot read stdout';
            @stdout = $stdout_file->lines_utf8( { chomp => 1 } );

            $e      = 'Cannot read stderr';
            @stderr = $stderr_file->lines_utf8( { chomp => 1 } );

            1;
        };

        if ( !$ok ) {
            if ( defined $@ && $@ ne q{} ) {
                $e .= ": $@";
            }
        }
    }
    return $self->fail( $e, 'Path::Tiny' ) if !$ok;

    # get exit code and signal from git process
    my $exit_code = $run->{_proc}->exit_code;

    my @result = (
        \@stdout,
        \@stderr,
        $exit_code,
        $stdout_file,
        $stderr_file,
    );

    # git died by a signal
    return $self->fail( 'Git was terminated by a signal', 'Proc::Background', @result ) if $run->{_proc}->exit_signal;

    if (
        # fatal error
        ( $exit_code == 128 )

        # usage error
        || ( $exit_code == 129 )

        # non-zero return code
        || ( $exit_code && $run->{_fatal} )
      )
    {
        my $message = join "\n", @stderr;
        if ( !length $message ) {
            $message = "git exited with fatal exit code $exit_code but had no output to stderr";
        }

        # $run goes out of scope and the file handles and the proc object are freed
        return $self->fail( $message, 'git', @result );
    }

    # $run goes out of scope and the file handles and the proc object are freed
    return $self->done(@result);
}

sub exit_code {
    my ($self) = @_;
    return ( $self->get )[2];
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

sub path_stderr {
    my ($self) = @_;
    return ( $self->get )[4];
}

sub path_stdout {
    my ($self) = @_;
    return ( $self->get )[3];
}

sub state {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self) = @_;
    $self->_await_if_git_is_done;
    return $self->SUPER::state;
}

sub stderr {
    my ($self) = @_;
    return @{ ( $self->get )[1] };
}

sub stdout {
    my ($self) = @_;
    return @{ ( $self->get )[0] };
}

sub _await_if_git_is_done {
    my ($self) = @_;

    my $run = $self->udata('_run');
    if ( defined $run && !$run->{_proc}->alive ) {
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

Version 0.008

=head1 SYNOPSIS

    use Git::Background 0.008;
    my $future = Git::Background->run(qw(status -s));

    my @stdout = $future->stdout;

    my ($stdout_ref, $stderr_ref, $exit_code, $stdout_path, $stderr_path) =
        $future->get;

=head1 DESCRIPTION

This is a subclass of L<Future>. Please read the excellent documentation of
C<Future> to see what you can do with this module, this man page only
describes the changes to C<Future> specific to L<Git::Background>.

=head2 UTF-8

The default is to read the output from Git on its stdout and stderr as UTF-8.

The strings returned by the C<get>, C<stderr>, and C<stdout> methods can
therefore contain wide characters. When you write this data to a file handle,
you must ensure that the destination also uses a suitable encoding. This is
necessary to correctly handle any wide characters in the data. You can do this
by setting the encoding of the destination filehandle, e.g.:

    binmode(STDOUT, ':encoding(UTF-8)');

=head1 USAGE

=head2 new( RUN )

New C<Git::Background::Future> objects should be constructed by using the
C<run> method of L<Git::Background>.

Current API available since 0.002.

=head2 await

Blocks and waits until the Git process finishes.

Returns the invocant future itself, so it is useful for chaining.

This method is called by C<get> or C<failure>.

See L<Future/await> for more information.

Current API available since 0.002.

=head2 exit_code

Calls C<get>, then returns the exit code of the Git process.

Because this command calls C<get>, the same exceptions can be thrown.

Current API available since 0.002.

=head2 failure

Waits for the running Git process to finish by calling C<await>. Returns
undef if the future finished successfully, otherwise it returns a list with

    $message, $category, @details

For the C<$category> C<git>, C<@details> is a list of C<stdout_ref>,
C<stderr_ref>, C<exit_code>, C<stdout_path>, and C<stderr_path>. See
C<get> for a description of these values.

Current API available since 0.008.

=head2 get

Waits for the running Git process to finish by calling C<await>. Throws a
L<Future::Exception> if the C<Future> didn't finish successfully. Returns
a list of  C<stdout_ref>, C<stderr_ref>, C<exit_code>, C<stdout_path>,
and C<stderr_path>.

    my $git = Git::Background->new($dir);
    my $future = $git->run('status', '-s');
    # waits for 'git status -s' to finish
    my ($stdout_ref, $stderr_ref, $rc) = $future->get;

=head3 stdout_ref

An array reference containing the stdout from git, split into lines
and chomped.

=head3 stderr_ref

An array reference containing the stderr from git, split into lines
and chomped.

=head3 exit_code

The exit code from git.

=head3 stdout_path

A L<Path::Tiny> object of a file containing the stdout from Git. This
can be used to read the data with a different binmode.

=head3 stderr_path

A L<Path::Tiny> object of a file containing the stderr from Git.

Current API available since 0.008.

=head2 is_done

L<Future/is_done>

Current API available since 0.002.

=head2 is_failed

L<Future/is_failed>

Current API available since 0.002.

=head2 is_ready

L<Future/is_ready>

Current API available since 0.002.

=head2 path_stderr

Calls C<get>, then returns the L<Path::Tiny> object for the file
containing the stderr from Git.

Because this command calls C<get>, the same exceptions can be thrown.

Current API available since 0.008.

=head2 path_stdout

Calls C<get>, then returns the L<Path::Tiny> object for the file
containing the stdout from Git.

Because this command calls C<get>, the same exceptions can be thrown.

Current API available since 0.008.

=head2 state

L<Future/state>

Current API available since 0.002.

=head2 stderr

Calls C<get>, then returns all the lines written by the Git command to
stderr.

Because this command calls C<get>, the same exceptions can be thrown.

Note: C<get> returns all the output lines as array reference, C<stderr>
returns a list.

Current API available since 0.002.

=head2 stdout

Calls C<get>, then returns all the lines written by the Git command to
stdout.

Because this command calls C<get>, the same exceptions can be thrown.

Note: C<get> returns all the output lines as array reference, C<stdout>
returns a list.

Current API available since 0.002.

=head1 SEE ALSO

L<Git::Background>, L<Future>, L<Path::Tiny>

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

=cut
