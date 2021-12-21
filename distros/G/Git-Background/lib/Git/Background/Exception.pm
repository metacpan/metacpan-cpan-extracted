package Git::Background::Exception;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use overload (
    q("")    => '_stringify',
    bool     => sub () { return 1 },
    fallback => 1,
);

sub new {
    my ( $class, $args_ref ) = @_;

    my $self = {
        _exit_code => $args_ref->{exit_code},
        _stderr    => $args_ref->{stderr},
        _stdout    => $args_ref->{stdout},
    };
    bless $self, $class;

    return $self;
}

sub exit_code {
    my ($self) = @_;

    return $self->{_exit_code};
}

sub stderr {
    my ($self) = @_;

    my $stderr_ref = $self->{_stderr};
    return if !defined $stderr_ref;
    return @{$stderr_ref};
}

sub stdout {
    my ($self) = @_;

    my $stdout_ref = $self->{_stdout};
    return if !defined $stdout_ref;
    return @{$stdout_ref};
}

sub _stringify {
    my ($self) = @_;

    my $stderr = join "\n", $self->stderr;
    return $stderr if length $stderr;

    my $exit_code = $self->exit_code;
    return 'git exited with a fatal exit code but had no output to stderr' if !defined $exit_code;
    return "git exited with fatal exit code $exit_code but had no output to stderr";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Background::Exception - exception class for Git::Background

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

A new error object may be generated and thrown as follows:

    die Git::Background::Exception->new({
        stdout => $stdout,
        stderr => $stderr,
        exit_code => $exit_code,
    });


=head1 DESCRIPTION

This object is thrown by Git::Background if the Git process returned a
non-zero return code.

The object stringifies to either the output printed to STDERR by Git or, if
none was printed, a generic error message containing the exit code of Git.

=head1 USAGE

=head2 new( ARGS )

Constructor for this class.

=head3 exit_code (required)

The exit code returned by Git.

=head3 stderr (required)

An array reference containing all the output lines printed to STDERR by Git.

=head3 stdout (required)

An array reference containing all the output lines printed to STDOUT by Git.

=head2 exit_code

Returns the exit code returned by Git. This is the reason the exception was
thrown.

=head2 stderr

Returns a list of all the output lines printed to standard error by Git.

    my @stderr = $e->stderr;

=head2 stdout

Returns a list of all the output lines printed to standard output by Git.

    my @stdout = $e->stdout;

=head1 EXAMPLES

=head2 Example 1 Catch exception with Feature::Compat::Try

    use 5.014;
    use strict;
    use warnings;

    use lib qw(.. .. lib);

    use Feature::Compat::Try;
    use Scalar::Util qw(blessed);
    use Git::Background;

    my $git = Git::Background->new;
    try {
        $git->run('--invalid-arg')->get;
    }
    catch ($e) {
        die $e if !blessed $e || !$e->isa('Git::Background::Exception');

        my $exit_code = $e->exit_code;
        my $stderr    = join "\n", $e->stderr;
        warn "Git exited with exit code $exit_code\n$stderr\n";
    }

=head2 Example 2 Catch exception with eval

    use 5.006;
    use strict;
    use warnings;

    use lib qw(.. .. lib);

    use Scalar::Util qw(blessed);
    use Git::Background;

    my $git = Git::Background->new;

    if ( !eval { $git->run('--invalid-arg')->get; 1; } ) {
        my $e = $@;
        die $e if !blessed $e || !$e->isa('Git::Background::Exception');

        my $exit_code = $e->exit_code;
        my $stderr    = join "\n", $e->stderr;
        warn "Git exited with exit code $exit_code\n$stderr\n";
    }

=head1 SEE ALSO

L<Git::Wrapper::Exception>

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
