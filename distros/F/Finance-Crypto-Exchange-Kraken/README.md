# DESCRIPTION

Talk to the Kraken REST API within Perl

# SYNOPSIS

    package Foo;
    use Finance::Crypto::Exchange::Kraken;

    my $kraken = Finance::Crypto::Exchange::Kraken->new(
        key    => 'your very secret key',
        secret => 'your very secret secret',
    );

    # For all methods, please visit the documentation
    $kraken->get_server_time;

# METHODS

## call

    my $req = HTTP::Request->new(GET, ...);
    $self->call($req);

A very simple API call function.
Decodes the JSON for you on success, otherwise dies a horrible death with the
error Kraken gives back to you.

You should not be needing this method, this function is public because all the
roles use it.

## nonce

Create a nonce

# SEE ALSO

- [Finance::Crypto::Exchange::Kraken::REST::Public](https://metacpan.org/pod/Finance%3A%3ACrypto%3A%3AExchange%3A%3AKraken%3A%3AREST%3A%3APublic)
- [Finance::Crypto::Exchange::Kraken::REST::Private](https://metacpan.org/pod/Finance%3A%3ACrypto%3A%3AExchange%3A%3AKraken%3A%3AREST%3A%3APrivate)
- [Finance::Crypto::Exchange::Kraken::REST::Private::User::Data](https://metacpan.org/pod/Finance%3A%3ACrypto%3A%3AExchange%3A%3AKraken%3A%3AREST%3A%3APrivate%3A%3AUser%3A%3AData)
- [Finance::Crypto::Exchange::Kraken::REST::Private::User::Trading](https://metacpan.org/pod/Finance%3A%3ACrypto%3A%3AExchange%3A%3AKraken%3A%3AREST%3A%3APrivate%3A%3AUser%3A%3ATrading)
- [Finance::Crypto::Exchange::Kraken::REST::Private::User::Funding](https://metacpan.org/pod/Finance%3A%3ACrypto%3A%3AExchange%3A%3AKraken%3A%3AREST%3A%3APrivate%3A%3AUser%3A%3AFunding)
- [Finance::Crypto::Exchange::Kraken::REST::Private::Websockets](https://metacpan.org/pod/Finance%3A%3ACrypto%3A%3AExchange%3A%3AKraken%3A%3AREST%3A%3APrivate%3A%3AWebsockets)

There is another module that does more or less the same:
[Finance::Bank::Kraken](https://metacpan.org/pod/Finance%3A%3ABank%3A%3AKraken) but it requires a more hands on approach.
