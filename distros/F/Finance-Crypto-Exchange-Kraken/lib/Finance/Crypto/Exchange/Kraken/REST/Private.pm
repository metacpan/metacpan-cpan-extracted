package Finance::Crypto::Exchange::Kraken::REST::Private;
our $VERSION = '0.002';
use Moose::Role;

use Digest::SHA qw(hmac_sha512_base64 sha256);
use HTTP::Request::Common qw(POST);

# ABSTRACT: Role for Kraken "private" API calls

requires qw(call nonce has_key has_secret key secret);

sub _private {
    my ($self, $call, %payload) = @_;

    die "Unable to progress, no key set!" unless $self->has_key;
    die "Unable to progress, no secret set!" unless $self->has_secret;

    my $uri = $self->_uri->clone;
    $uri->path_segments(0, 'private', $call);

    my $nonce = $payload{nonce} = $self->nonce;

    my $req = POST($uri,
        Content => [ %payload ],
        'API-Key' => $self->key,
    );

    $req->header('API-Sign' => $self->_hmac($uri->path, $nonce, $req->content));

    return $req;
}

sub _hmac {
    my ($self, $path, $nonce, $content) = @_;
    return hmac_sha512_base64(
        join("", $path, sha256($nonce . $content)),
        $self->secret
    );
}

with qw(
    Finance::Crypto::Exchange::Kraken::REST::Private::User::Data
    Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading
    Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding
    Finance::Crypto::Exchange::Kraken::REST::Private::Websockets
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken::REST::Private - Role for Kraken "private" API calls

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Foo;
    with qw(Finance::Crypto::Exchange::Kraken::REST::Private);

=head1 DESCRIPTION

This role introduces all the private API calls Kraken supports.

=head1 SEE ALSO

=over

=item * L<Finance::Crypto::Exchange::Kraken::REST::Private::User::Data>

=item * L<Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading>

=item * L<Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding>

=item * L<Finance::Crypto::Exchange::Kraken::REST::Private::Websockets>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
