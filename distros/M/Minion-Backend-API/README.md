# NAME

[Minion::Backend::API](https://metacpan.org/pod/Minion::Backend::API) - API Rest backend

# SYNOPSIS

    # simple
    use Minion::Backend::API;

    my $backend = Minion::Backend::API->new('https://my-api.com');

    # using with your own Mojo::UserAgent
    use Mojo::UserAgent;
    use Minion::Backend::API;

    my $ua = Mojo::UserAgent->new;
    my $backend = Minion::Backend::API->new('https://my-api.com', $ua);

# DESCRIPTION

[Minion::Backend::API](https://metacpan.org/pod/Minion::Backend::API) is a backend for [Minion](https://metacpan.org/pod/Minion)
based on [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent). This module need be used together with the module
[Mojolicious::Plugin::Minion::API](https://metacpan.org/pod/Mojolicious::Plugin::Minion::API), access it to see manual.

# ATTRIBUTES

[Minion::Backend::API](https://metacpan.org/pod/Minion::Backend::API) inherits all attributes from
[Minion::Backend](https://metacpan.org/pod/Minion::Backend) and implements the following new ones.

## url

    my $url  = $backend->url;
    $backend = $backend->url('https://my-api.com');

## ua

    my $ua   = $backend->ua;
    $backend = $backend->ua(Mojo::UserAgent->new);

## slow

    $backend->slow(0.2);

Slows down each request of dequeue. Default is 0.5 (half a second).

# SEE MORE OPTIONS

[Minion::Backend::Pg](https://metacpan.org/pod/Minion::Backend::Pg)

# SEE ALSO

[Mojolicious::Plugin::Minion::API](https://metacpan.org/pod/Mojolicious::Plugin::Minion::API),
[Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent),
[Minion](https://metacpan.org/pod/Minion),
[Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides),
https://mojolicious.org.

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
