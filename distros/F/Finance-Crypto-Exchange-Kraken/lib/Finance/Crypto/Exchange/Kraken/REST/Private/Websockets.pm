package Finance::Crypto::Exchange::Kraken::REST::Private::Websockets;
our $VERSION = '0.002';
use Moose::Role;

# ABSTRACT: Finance::Crypto::Exchange::Kraken::REST::Private::Websockets needs an abstract

requires qw(
    _private
);

sub get_websockets_token {
    my $self = shift;
    my $req = $self->_private('GetWebSocketsToken', @_);
    return $self->call($req);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Crypto::Exchange::Kraken::REST::Private::Websockets - Finance::Crypto::Exchange::Kraken::REST::Private::Websockets needs an abstract

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Foo;

    use Moose;
    with qw(Finance::Crypto::Exchange::Kraken::REST::Private::Websockets);

=head1 DESCRIPTION

This role introduces the REST API for websockets Kraken supports. For extensive
information please have a look at the L<Kraken API
manual|https://www.kraken.com/features/api#ws-auth>

=head1 METHODS

=head2 get_websockets_token

L<https://api.kraken.com/0/private/GetWebsocketsToken>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
