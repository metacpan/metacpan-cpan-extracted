package Kubernetes::REST::AuthTokenFile;
our $VERSION = '1.107';
# ABSTRACT: Bearer token read from a file, re-read when the file changes
use Moo;
use Carp qw(croak);
use Path::Tiny qw(path);
use Time::HiRes ();
use namespace::clean;


has file => (
    is => 'ro',
    required => 1,
);


has description => (
    is => 'ro',
    default => sub { 'token file' },
);


has refresh => (
    is => 'ro',
    default => sub { 1 },
);


has _token => (
    is => 'rw',
    init_arg => undef,
);

has _fingerprint => (
    is => 'rw',
    init_arg => undef,
);

sub BUILD {
    my $self = shift;
    # The first read is fatal: a caller naming a token file has said this is
    # how it authenticates, and there is nothing to fall back on yet.
    $self->_read_file;
    return;
}

sub token {
    my $self = shift;


    return $self->_token unless $self->refresh;

    my $fingerprint = $self->_fingerprint_now;
    my $known = $self->_fingerprint;

    # Unreadable right now, or unchanged: keep what we have.
    return $self->_token
        if !defined $fingerprint
        or (defined $known and $fingerprint eq $known);

    my $token = eval { $self->_read_file };
    return defined $token ? $token : $self->_token;
}

# What "the file changed" is measured on: device and inode, size, and
# modification time.
#
# Inode is the one that matters for a rotation. The kubelet does not overwrite
# a mounted token, it writes a new timestamped directory and swaps the ..data
# symlink onto it, so the path resolves to a different file afterwards - and
# stat() follows symlinks, so it is the new file that gets measured. Size and
# mtime are what catch a plain overwrite in place, which is what a login helper
# writing the file itself tends to do.
#
# Time::HiRes::stat rather than stat, because core stat reports mtime in whole
# seconds and two writes within the same second are then indistinguishable.
#
# What this does not catch: an in-place rewrite that keeps the inode, the exact
# same size, and a modification time the filesystem cannot tell apart from the
# previous one. Nothing short of reading the file on every call would, and
# reading it on every call is the thing this stat exists to avoid.
sub _fingerprint_now {
    my $self = shift;
    my @stat = Time::HiRes::stat($self->file) or return undef;
    return join ':', @stat[0, 1, 7, 9];
}

sub _read_file {
    my $self = shift;
    my $file = $self->file;

    # Fingerprint first, content second. Should the file change between the
    # two, the pair on record is an old fingerprint with new content, so the
    # next call reads once too often - the other order would record a new
    # fingerprint with old content and never look again.
    my $fingerprint = $self->_fingerprint_now;

    my $token = eval { path($file)->slurp_raw };
    croak 'Cannot read the ' . $self->description . " ($file): $@"
        unless defined $token;

    # Such a file ends with a newline more often than not, and a newline inside
    # an Authorization header is not something a server ever sees as intended.
    $token =~ s/\A\s+//;
    $token =~ s/\s+\z//;
    croak 'The ' . $self->description . " ($file) holds no token"
        unless length $token;

    $self->_token($token);
    $self->_fingerprint($fingerprint);

    return $token;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::AuthTokenFile - Bearer token read from a file, re-read when the file changes

=head1 VERSION

version 1.107

=head1 SYNOPSIS

    use Kubernetes::REST::AuthTokenFile;

    my $auth = Kubernetes::REST::AuthTokenFile->new(
        file => '/var/run/secrets/kubernetes.io/serviceaccount/token',
    );

    my $api = Kubernetes::REST->new(
        server => $server,
        credentials => $auth,
    );

    # Read once, and again whenever the file has changed since
    my $token = $auth->token;

    # Read once and never again
    my $fixed = Kubernetes::REST::AuthTokenFile->new(
        file => $path,
        refresh => 0,
    );

=head1 DESCRIPTION

Authentication credentials whose bearer token lives in a file: a kubeconfig
user's C<tokenFile>, or the service account token mounted into a pod at
F</var/run/secrets/kubernetes.io/serviceaccount/token>.

Kubernetes rotates those files. The kubelet replaces a projected service
account token well before it expires, and a client that read the file once at
startup keeps sending a token that stops being valid while a good one sits in
the file next to it. This class re-reads instead: every call to L</token>
checks whether the file has changed, and reads it again when it has.

L<Kubernetes::REST> asks its C<credentials> for a C<token()> on every request,
so passing one of these is all a long-running process needs.

=head2 file

Required. Path to the file holding the token. Used as given on every read, so
an absolute path is the safe choice for a process that may C<chdir> - that is
what L<Kubernetes::REST::Kubeconfig> passes.

=head2 description

How this file is named in error messages, e.g. C<tokenFile of user 'prod'> or
C<service account token>. Defaults to C<token file>.

=head2 refresh

Whether L</token> looks at the file again after the first read. True by
default. With C<< refresh => 0 >> the file is read exactly once, when the object is
built, and the token stays what it was then - the behaviour of a plain
L<Kubernetes::REST::AuthToken>, for a caller who wants no per-call C<stat> or
knows the file never changes.

=head2 token

    my $token = $auth->token;

The bearer token. Reads the file again if it has changed since the last read,
otherwise hands back what was read then.

Cost: one C<stat> per call, so one extra syscall per request. That is the price
of noticing a rotation without a timer, and it is deliberate.

If the file cannot be read any more, or holds no token, the last good token is
returned instead of dying: a rotation can take the file away for a moment, and
an error there would break a client that is one C<stat> away from recovering on
its own. Only the very first read, in the constructor, is fatal.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::AuthToken> - Credentials holding a fixed token

=item * L<Kubernetes::REST::Kubeconfig> - Builds these from a C<tokenFile>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
