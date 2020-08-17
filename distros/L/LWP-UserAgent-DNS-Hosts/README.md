# NAME

LWP::UserAgent::DNS::Hosts - Override LWP HTTP/HTTPS request's host like /etc/hosts

# SYNOPSIS

    use LWP::UserAgent;
    use LWP::UserAgent::DNS::Hosts;

    # add entry
    LWP::UserAgent::DNS::Hosts->register_host(
        'www.cpan.org' => '127.0.0.1',
    );

    # add entries
    LWP::UserAgent::DNS::Hosts->register_hosts(
        'search.cpan.org' => '192.168.0.100',
        'pause.perl.org'  => '192.168.0.101',
    );

    # read hosts file
    LWP::UserAgent::DNS::Hosts->read_hosts('/path/to/my/hosts');

    LWP::UserAgent::DNS::Hosts->enable_override;

    # override request hosts with peer addr defined above
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://www.cpan.org/");
    print $res->content; # is same as "http://127.0.0.1/" content

# DESCRIPTION

LWP::UserAgent::DNS::Hosts is a module to override HTTP/HTTPS request
peer addresses that uses LWP::UserAgent.

This module concept was got from [LWP::Protocol::PSGI](https://metacpan.org/pod/LWP%3A%3AProtocol%3A%3APSGI).

# METHODS

- register\_host($host, $peer\_addr)

        LWP::UserAgent::DNS::Hosts->register_host($host, $peer_addr);

    Registers a pair of hostname and peer ip address.

        # /etc/hosts
        127.0.0.1    example.com

    equals to:

        LWP::UserAgent::DNS::Hosts->register_hosts('example.com', '127.0.0.1');

- register\_hosts(%host\_addr\_pairs)

        LWP::UserAgent::DNS::Hosts->register_hosts(
            'example.com' => '192.168.0.1',
            'example.org' => '192.168.0.2',
            ...
        );

    Registers pairs of hostname and peer ip address.

- read\_hosts($file\_or\_string)

        LWP::UserAgent::DNS::Hosts->read_hosts('hosts.my');

        LWP::UserAgent::DNS::Hosts->read_hosts(<<'__HOST__');
            127.0.0.1      example.com
            192.168.0.1    example.net example.org
        __HOST__

    Registers "/etc/hosts" syntax entries.

- clear\_hosts

    Clears registered pairs.

- enable\_override

        LWP::UserAgent::DNS::Hosts->enable_override;
        my $guard = LWP::UserAgent::DNS::Hosts->enable_override;

    Enables to override hook.

    If called in a non-void context, returns a [Guard](https://metacpan.org/pod/Guard) object that
    automatically resets the override when it goes out of context.

- disable\_override

        LWP::UserAgent::DNS::Hosts->disable_override;

    Disables to override hook.

    If you use the guard interface described above,
    it will be automatically called for you.

# AUTHOR

NAKAGAWA Masaki <masaki@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[LWP::Protocol](https://metacpan.org/pod/LWP%3A%3AProtocol), [LWP::Protocol::http](https://metacpan.org/pod/LWP%3A%3AProtocol%3A%3Ahttp), [LWP::Protocol::https](https://metacpan.org/pod/LWP%3A%3AProtocol%3A%3Ahttps)
