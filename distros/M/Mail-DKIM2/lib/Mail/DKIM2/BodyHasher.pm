package Mail::DKIM2::BodyHasher;
use strict;
use warnings;

our $VERSION = '0.28';

use base 'Mail::DKIM2::HeaderParser';

use Carp;
use MIME::Base64 qw(encode_base64);
use Scalar::Util qw(weaken);
use Mail::DKIM2::Digest;
use Mail::DKIM2::MessageInstance;

sub known_options { return qw(Algs) }

sub init {
    my $self = shift;
    $self->SUPER::init;
    my $algs = $self->{Algs} // ['sha256'];
    croak "Algs must be a non-empty array reference"
        unless ref $algs eq 'ARRAY' && @$algs;
    my $impl = Mail::DKIM2::MessageInstance::hash_algs();
    my %digest;
    for my $alg (map { lc } @$algs) {
        croak "unsupported hash algorithm $alg" unless $impl->{$alg};
        $digest{$alg} //= Mail::DKIM2::Digest->new($alg);
    }
    $self->{_digest}  = \%digest;
    $self->{_pending} = '';
}

sub finish_header {
    my $self = shift;
    # Weak: the parser holds the sink, so a strong $self would be a cycle.
    weaken(my $weak = $self);
    $self->{_body_sink} = sub { $weak->_add_body($_[0]) };
}

# Hash a piece once a megabyte is waiting, holding back the CR and LF at
# its end until it is known whether they end the body.
sub _add_body {
    my $self = shift;
    $self->{_pending} .= $_[0];
    return if length $self->{_pending} < Mail::DKIM2::MessageInstance::BODY_CHUNK;
    my $took = Mail::DKIM2::MessageInstance::_body_digest_feed(
        [ values %{$self->{_digest}} ], \$self->{_pending}, 0);
    substr($self->{_pending}, 0, $took, '');
}

sub finish_body {
    my $self = shift;
    Mail::DKIM2::MessageInstance::_body_digest_feed(
        [ values %{$self->{_digest}} ], \$self->{_pending}, 1);
    $self->{_pending} = '';
    my $digest = $self->{_digest};
    $self->{_hashes} = {
        map { $_ => encode_base64($digest->{$_}->digest, '') } keys %$digest
    };
}

sub body_hashes {
    my $self = shift;
    croak "body_hashes before CLOSE" unless $self->{_hashes};
    return { %{$self->{_hashes}} };
}

sub body_hash {
    my ($self, $alg) = @_;
    croak "body_hash before CLOSE" unless $self->{_hashes};
    $alg = lc($alg // 'sha256');
    croak "body_hash: $alg was not among Algs" unless exists $self->{_hashes}{$alg};
    return $self->{_hashes}{$alg};
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::BodyHasher - the body hash of a message, streamed

=head1 SYNOPSIS

    my $hasher = Mail::DKIM2::BodyHasher->new(Algs => ['sha256'])
                 ->load($fh);
    my $mi = Mail::DKIM2::MessageInstance->calculate($header_block,
        undef, BodyHash => $hasher->body_hashes);

=head1 DESCRIPTION

The -08 section 6.1 body hash of a message, as
C<Mail::DKIM2::MessageInstance::body_digest_raw> computes it, from a
message fed through C<PRINT> and C<CLOSE> (or C<load>) in pieces of any
size. The body is hashed as it arrives and never held: at most a megabyte
of it is kept at a time. The header fields are parsed as the Signer and
Verifier parse them and are in C<< $self->{headers} >>.

It is for a host that holds a large message in a file and needs its body
hash for C<< MessageInstance->calculate >> (C<BodyHash>) or
C<< MessageInstance->verify >> (C<BodyHashes>), which then need only the
header block.

=head1 CONSTRUCTOR

=head2 new(%options)

C<Algs> is an array reference of hash algorithm names, default
C<['sha256']>; an unknown one croaks.

=head1 METHODS

C<PRINT>, C<CLOSE> and C<load> are L<Mail::DKIM2::HeaderParser>'s.

=head2 body_hashes()

After C<CLOSE>: a new hash reference of algorithm name to base64 body
hash, in the form C<calculate>'s C<BodyHash> and C<verify>'s
C<BodyHashes> take.

=head2 body_hash([$alg])

After C<CLOSE>: the base64 body hash by C<$alg> (default C<sha256>), which
must have been among C<Algs>.

=head1 SUBCLASS INTERFACE

=head2 known_options(), init(), finish_header(), finish_body()

As for L<Mail::DKIM2::HeaderParser>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
