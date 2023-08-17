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

package Git::Background;

our $VERSION = '0.007';

use Carp       ();
use File::Temp ();
use Future 0.40;
use Proc::Background 1.30;
use Scalar::Util ();

use Git::Background::Future;

# Git::Background->new;
# Git::Background->new($dir);
# Git::Background->new( { dir => $dir, fatal => 0 } );
# Git::Background->new( $dir, { fatal => 0 } );
sub new {
    my $class = shift;

  NEW: {
        my $self;

        last NEW if @_ > 2;

        my $dir;

        # first argument is a scalar or object
        if ( @_ && ( ref $_[0] eq ref q{} || defined Scalar::Util::blessed $_[0] ) ) {
            my $arg = shift @_;

            # stringify objects (e.g. Path::Tiny)
            $dir = "$arg";
        }

        last NEW if @_ > 1;

        # first/remaining argument is a hash ref
        if ( @_ && ref $_[0] eq ref {} ) {
            my $args = shift @_;
            $self = $class->_process_args($args);
        }
        else {
            $self = $class->_process_args;
        }

        last NEW if @_;

        if ( defined $dir ) {
            Carp::croak 'Cannot specify dir as positional argument and in argument hash' if exists $self->{_dir};
            $self->{_dir} = $dir;
        }

        bless $self, $class;
        return $self;
    }

    # unknown args
    Carp::croak 'usage: new( [DIR], [ARGS] )';
}

sub run {
    my ( $self, @cmd ) = @_;

    Carp::croak 'Cannot use run() in void context. (The git process would immediately get killed.)' if !defined wantarray;    ## no critic (Community::Wantarray)

    my $config;
    if ( @cmd && ref $cmd[-1] eq ref {} ) {
        my $args = pop @cmd;
        $config = $self->_process_args($args);
    }
    else {
        $config = $self->_process_args;
    }

    my $stdout = File::Temp->new;
    my $stderr = File::Temp->new;
    binmode $stdout, ':encoding(UTF-8)';    ## no critic (InputOutput::RequireCheckedSyscalls)
    binmode $stderr, ':encoding(UTF-8)';    ## no critic (InputOutput::RequireCheckedSyscalls)

    # Proc::Background
    my $proc_args = {
        stdin         => undef,
        stdout        => $stdout,
        stderr        => $stderr,
        command       => [ @{ $config->{_git} }, @cmd ],
        autodie       => 1,
        autoterminate => 1,
        ( defined $config->{_dir} ? ( cwd => $config->{_dir} ) : () ),
    };

    my $proc;
    my $e;
    {
        local @_;    ## no critic (Variables::RequireInitializationForLocalVars)
        local $Carp::Internal{ (__PACKAGE__) } = 1;

        $proc = eval { Proc::Background->new($proc_args); };

        if ( !defined $proc ) {

            # The Future->fail exception must be true
            $e = qq{$@} || 'Failed to run Git with Proc::Background';
        }
    }
    return Git::Background::Future->fail( $e, 'Proc::Background' ) if !defined $proc;

    return Git::Background::Future->new(
        {
            _fatal  => $config->{_fatal},
            _proc   => $proc,
            _stdout => $stdout,
            _stderr => $stderr,
        },
    );
}

sub version {
    my ( $self, $args ) = @_;

    my @cmd = qw(--version);

    if ( defined $args ) {
        push @cmd, $args;
    }

    my $version = eval {
        for my $line ( $self->run(@cmd)->stdout ) {
            if ( $line =~ s{ \A git \s version \s }{}xsm ) {
                return $line;
            }
        }

        return;
    };

    return $version;
}

sub _process_args {
    my ( $self, $args ) = @_;

    if ( !defined Scalar::Util::blessed($self) ) {
        $self = {
            _fatal => !!1,
            _git   => ['git'],
        };
    }

    my %args_keys = map { $_ => 1 } keys %{$args};
    my %config;

    # dir
    if ( exists $args->{dir} ) {

        # stringify objects (e.g. Path::Tiny)
        $config{_dir} = "$args->{dir}";
        delete $args_keys{dir};
    }
    elsif ( exists $self->{_dir} ) {
        $config{_dir} = $self->{_dir};
    }

    # fatal
    if ( exists $args->{fatal} ) {
        $config{_fatal} = !!$args->{fatal};
        delete $args_keys{fatal};
    }
    else {
        $config{_fatal} = $self->{_fatal};
    }

    # git
    if ( exists $args->{git} ) {
        my $git = $args->{git};
        $config{_git} = [ ( defined Scalar::Util::reftype($git) && Scalar::Util::reftype($git) eq Scalar::Util::reftype( [] ) ) ? @{ $args->{git} } : $git ];
        delete $args_keys{git};
    }
    else {
        $config{_git} = [ @{ $self->{_git} } ];
    }

    #
    my @unknown = sort keys %args_keys;
    Carp::croak 'Unknown argument' . ( @unknown > 1 ? 's' : q{} ) . q{: '} . join( q{', '}, sort @unknown ) . q{'} if @unknown;

    return \%config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Background - use Git commands with L<Future>

=head1 VERSION

Version 0.007

=head1 SYNOPSIS

    use Git::Background 0.002;

    my $git = Git::Background->new($dir);
    my $future = $git->run('status', '-s');
    my @status = $future->stdout;

    my $future = Git::Background->run('status', '-s', { dir => $dir });
    my @status = $future->stdout;

=head1 USAGE

=head2 new( [DIR], [ARGS] )

Creates and returns a new C<Git::Background> object. If you specify the
C<dir> positional argument, or use the C<dir> argument in the args hash
the directory is passed as C<cwd> option to L<Proc::Background> causing it
to change into that directory before running the Git command.

Both, the C<dir> positional argument and the args hash are optional. An
exception is thrown if you specify both.

    my $git = Git::Background->new;
    my $git = Git::Background->new($dir);
    my $git = Git::Background->new( { dir => $dir, fatal => 0 } );
    my $git = Git::Background->new( $dir, { fatal => 0 } );

C<new> either returns a valid C<Git::Background> object or throws an
exception.

The following options can be passed in the args hash to new. They are used
as defaults for calls to C<run>.

=head3 dir

This will be passed as C<cwd> argument to L<Proc::Background> whenever you
call C<run>. If you don't specify a C<dir> all Git commands are executed in
whatever the current working directory is when you call C<run>.

=head3 fatal

Enabled by default. The C<fatal> option controls if
L<Git::Background::Future/await> returns a failed C<Future> when Git returns a
non-zero return code.

Please not that L<Git::Background::Future/await> always returns a failed
C<Future> if Git returns 128 (fatal Git error) or 129 (Git usage error)
regardless of C<fatal>. And a failed C<Future> is returned if another error
happens, e.g. if the output from Git cannot be read.

=head3 git

The Git command used to run. This defaults to C<git> and lets
L<Proc::Background> work its magic to find the binary on your platform.

This can be either a string,

    my $git = Git::Background->new( { git => '/opt/git/bin/git' } );

or an array ref.

    my $git = Git::Background->new({
        git => [ qw( /usr/bin/sudo -u nobody git ) ],
    });


=head2 run( @CMD, [ARGS] )

This runs the specified Git command in the background by passing it on to
C<Git::Background>. The last argument can be an argument hash that takes the
same arguments as C<new>.

    my $git = Git::Background->new($dir);
    my $future = $git->run('status', '-s', { fatal => 0 } );

    if ( $future->await->is_failed ) {
        say q{Unable to run 'git status -s'};
    }
    else {
        my @status = $future->stdout;
    }

The call returns a L<Git::Background::Future> and the Git command runs in its
own process. All output produced by Git is redirected to a L<File::Temp>
temporary file.

C<Proc::Background> is run with C<autoterminate> set, which will kill the
Git process if the future is destroyed.

Since version 0.004 C<run> C<croaks> if it gets called in void context.

=head2 version( [ARGS] )

Returns the version of the used Git binary or undef if no Git command was
found. This call uses the same, optional, argument hash as C<run>. The call
is wrapped in an eval which ensures that this method never throws an error
and can be used to check if a Git is available.

    my $version = Git::Background->version;
    if ( !defined $version ) {
        say "No Git binary found.";
    }
    else {
        say "You have Git version $version";
    }

=head1 EXAMPLES

=head2 Example 1 Clone a repository

Cloning a repository is a bit special as it's the only Git command that
cannot be run in a workspace and the target directory must not exist.

There are two ways to use a C<Git::Background> object without the workspace
directory:

    my $future = Git::Background->run('clone', $url, $dir);
    $future->get;

    # later, use a new object for working with the cloned repository
    my $git = Git::Background->new($dir);
    my $future = $git->run('status', '-s');
    my @stdout = $future->stdout;

Alternatively you can overwrite the directory for the call to clone:

    my $git = Git::Background->new($dir);
    my $future = $git->run('clone', $url, $dir, { dir => undef });
    $future->get;

    # then use the same object for working with the cloned repository
    my $future = $git->run('status', '-s');
    my @dstdout = $future->stdout;

=head1 SEE ALSO

L<Git::Repository>, L<Git::Wrapper>, L<Future>, L<Git::Version::Compare>

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
