package Git::Background;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Carp ();
use File::Temp qw(:seekable);
use Proc::Background 1.30;
use Scalar::Util ();

use Git::Background::Exception;

# Git::Background->new;
# Git::Background->new($dir);
# Git::Background->new( { dir => $dir, fatal => 0 } );
# Git::Background->new( $dir, { fatal => 0 } );
sub new {
    my ($class) = shift @_;

    my $self = {
        _fatal => !!1,
        _git   => ['git'],
    };
    bless $self, $class;

    # first argument is a scalar or object
    if ( @_ && ( ref $_[0] eq ref q{} || defined Scalar::Util::blessed $_[0] ) ) {
        my $arg = shift @_;

        # stringify objects (e.g. Path::Tiny)
        $self->{_dir} = "$arg";
    }

    # first/remaining argument is a hash ref
    if ( @_ && ref $_[0] eq ref {} ) {
        my $args = shift @_;

        Carp::croak 'Cannot specify dir as positional argument and in argument hash' if exists $self->{_dir} && exists $args->{dir};
        _set_args( $self, $args );
    }

    # unknown args
    Carp::croak 'usage: new( [DIR], [ARGS] )' if @_;

    return $self;
}

sub is_ready {
    my ($self) = @_;

    # run() was never called
    Carp::croak q{Nothing run() yet} if !defined $self->{_run};

    # the process is still alive
    return !$self->{_run}{_proc}->alive;
}

sub get {
    my ($self) = @_;

    Carp::croak q{Nothing run() yet} if !defined $self->{_run};

    my $run = delete $self->{_run};

    # prevent the "(in cleanup) process is already terminated" message
    $run->{_proc}->autoterminate(0);

    # wait for the process to finish
    $run->{_proc}->wait;

    # slurp back stderr
    my $stderr_fh = $run->{_stderr};
    my @stderr    = _slurp($stderr_fh);

    # git died by a signal
    if ( $run->{_proc}->exit_signal ) {
        warn join "\n", @stderr;    ## no critic (ErrorHandling::RequireCarping)
        Carp::croak 'Git was terminated by a signal';
    }

    # slurp back stdout
    my $stdout_fh = $run->{_stdout};
    my @stdout    = _slurp($stdout_fh);

    # get exit code and signal from git process
    my $exit_code = $run->{_proc}->exit_code;

    ## no critic (ErrorHandling::RequireCarping)
    die Git::Background::Exception->new(
        {
            stdout    => \@stdout,
            stderr    => \@stderr,
            exit_code => $exit_code,
        },
      )

      # die for every non-zero return code if fatal
      if ( $exit_code && $run->{_fatal} )

      # otherwise die only for fatal error
      || $exit_code == 128

      # or usage error
      || $exit_code == 129;

    # $run goes out of scope and the file handles and the proc object are freed
    return ( \@stdout, \@stderr, $exit_code );
}

sub run {
    my ( $self, @cmd ) = @_;

    Carp::croak 'You need to get() the result of the last run() first' if defined $self->{_run};

    # Create run "object"
    my $run = {
        _dir   => $self->{_dir},
        _fatal => $self->{_fatal},
        _git   => [ @{ $self->{_git} } ],

        _stdout => File::Temp->new,
        _stderr => File::Temp->new,
    };

    if ( @cmd && ref $cmd[-1] eq ref {} ) {
        my $args = pop @cmd;
        _set_args( $run, $args );
    }

    # Proc::Background
    my $proc_args = {
        stdin         => undef,
        stdout        => $run->{_stdout},
        stderr        => $run->{_stderr},
        command       => [ @{ $run->{_git} }, @cmd ],
        autodie       => 1,
        autoterminate => 1,
        ( defined $run->{_dir} ? ( cwd => $run->{_dir} ) : () ),
    };

    {
        local $Carp::Internal{ (__PACKAGE__) } = 1;
        $run->{_proc} = Proc::Background->new($proc_args);
    }
    $self->{_run} = $run;

    return $self;
}

sub stdout {
    my ($self) = @_;

    my ($stdout_ref) = $self->get;
    return @{$stdout_ref};
}

sub version {
    my ( $self, $args ) = @_;

    if ( !defined Scalar::Util::blessed $self ) {
        $self = $self->new;
    }

    my @cmd = ('--version');
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

# ---------- functions ----------

sub _set_args {
    my ( $target, $args ) = @_;

    my %keys = map { $_ => 1 } keys %{$args};

    if ( delete $keys{dir} ) {
        if ( defined $args->{dir} ) {

            # stringify objects (e.g. Path::Tiny)
            $target->{_dir} = "$args->{dir}";
        }
        else {
            delete $target->{_dir};
        }
    }

    if ( delete $keys{fatal} ) {
        $target->{_fatal} = !!$args->{fatal};
    }

    if ( delete $keys{git} ) {
        my $git = $args->{git};
        $target->{_git} = [ ( defined Scalar::Util::reftype $git && Scalar::Util::reftype $git eq Scalar::Util::reftype [] ) ? @{ $args->{git} } : $git ];
    }

    my @keys = sort keys %keys;
    Carp::croak 'Unknown argument' . ( @keys > 1 ? 's' : q{} ) . q{: '} . join( q{', '}, @keys ) . q{'} if @keys;

    return;
}

sub _slurp {
    my ($fh) = @_;

    $fh->seek( 0, SEEK_SET ) or Carp::croak "Cannot seek $fh: $!";
    my @lines = $fh->getlines;

    if ( $fh->error ) {
        Carp::croak "Cannot read $fh: $!";
    }

    for my $line (@lines) {
        $line =~ s{\r?\n?\z}{}xsm;
    }

    return @lines;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Background - Perl interface to run Git commands (in the background)

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    my $git = Git::Background->new($dir);
    $git->run('status', '-s');
    my @status = $git->stdout;

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

Enabled by default. The C<fatal> option controls if C<get> and C<stdout>
throw an exception when Git returns a non-zero return code.

Please not that C<get> and C<stdout> always throws an exception if Git
returns 128 (fatal Git error) or 129 (Git usage error) regardless of
C<fatal>. C<get> and C<stdout> also throws an exception if
another error happens, e.g. if the output from Git cannot be read.

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
    $git->run('status', '-s', { fatal => 0 } );

    my ($stdout, $stderr, $exit_code) = $git->get;
    if ( $exit_code ) {
        say q{Unable to run 'git status -s'};
    }
    else {
        my @status = split /\n/, $stdout;
        ...;
    }

The call returns immediately and the Git command runs in its own process.
All output produced by Git is redirected to a L<File::Temp> temporary file.

If there's already a Git command running for this object you have to run
C<get> or C<stdout> first or C<run> will croak.

C<run> returns itself to allow chaining.

    # Waits on the clone and dies if an error happens
    Git::Background->new->run('clone', $url, $dir)->get;

C<Proc::Background> is run with C<autoterminate> set, which will kill the
Git process if the object is destroyed.

=head2 get

Waits for the running Git process to finish. Throws an exception if C<run>
was never called. Returns the stdout, stderr and exit code of the Git
process.

    my $git = Git::Background->new($dir);
    # dies, because no run was called
    my ($stdout_ref) = $git->get;

    my $git = Git::Background->new($dir);
    $git->run('status', '-s');
    # waits for 'git status -s' to finish
    my ($stdout_ref, $stderr_ref, $rc) = $git->get;

C<wait> throws an exception if I cannot read the output of Git or if the Git
process was terminated by a signal.

Throws a L<Git::Background::Exception> exception if Git terminated with an
exit code of 128 or 129 and, as long as fatal is true, for any other
non-zero return code. Fatal defaults to true and can be changed by the call
to C<new> and C<run>.

    my $git = Git::Background->new( { fatal => 0 } );

    # dies, because Git will exit with exit code 129
    $git->run('--unknown-option')->get;

=head2 is_ready

Returns something false if the Git command is still running, otherwise
something true. Throws an exception if nothing was C<run> yet.

=head2 stdout

Calls C<get>, then returns all the lines written by the Git command to
stdout.

Because this command calls C<get>, the same exceptions can be thrown.

Note: C<get> returns all the output lines as array reference, C<stdout>
returns a list.

    my $git = Git::Background->new($dir);
    my ($stdout_ref) = $git->run( qw(status -s) )->get;
    my @stdout = $git->run( qw(status -s) )->stdout;

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

C<version> can be run on the class or an object.

    my $git = Git::Background->new( { git => '/opt/git/bin/git' } );
    say 'You have Git version ', $git->version;

=head1 EXAMPLES

=head2 Example 1 Clone a repository

Cloning a repository is a bit special as it's the only Git command that
cannot be run in a workspace and the target directory must not exist.

There are two ways to use a C<Git::Background> object without the workspace
directory:

    my $git = Git::Background->new;
    $git->run('clone', $url, $dir);
    $git->get;

    # later, use a new object for working with the cloned repository
    $git = Git::Background->new($dir);
    $git->run('status', '-s');
    my @stdout = $git->stdout;

Alternatively you can overwrite the directory for the call to clone:

    my $git = Git::Background->new($dir);
    $git->run('clone', $url, $dir, { dir => undef});
    $git->get;

    # then use the same object for working with the cloned repository
    $git->run('status', '-s');
    my @dstdout = $git->stdout;

=head1 SEE ALSO

L<Git::Repository>, L<Git::Wrapper>

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

This software is Copyright (c) 2021 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
