# NAME

HTTP::Session - simple session

# SYNOPSIS

    use HTTP::Session;

    my $session = HTTP::Session->new(
        store   => HTTP::Session::Store::Memcached->new(
            memd => Cache::Memcached->new({
                servers => ['127.0.0.1:11211'],
            }),
        ),
        state   => HTTP::Session::State::Cookie->new(
            name => 'foo_sid'
        ),
        request => $c->req,
    );

# DESCRIPTION

Yet another session manager.

easy to integrate with [PSGI](https://metacpan.org/pod/PSGI) =)

# METHODS

- my $session = HTTP::Session->new(store => $store, state => $state, request => $req)

    This method creates new instance of HTTP::Session.

    `store` is instance of HTTP::Session::Store::\*.

    `state` is instance of HTTP::Session::State::\*.

    `request` is duck typed object.`request` object should have `header`, `address`, `param`.
    You can use PSGI's $env instead.

- $session->html\_filter($html)

    filtering HTML

- $session->redirect\_filter($url)

    filtering redirect URL

- $session->header\_filter($res)

    filtering header

- $session->response\_filter($res)

    filtering response. this method runs html\_filter, redirect\_filter and header\_filter.

    $res should be PSGI's response array, instance of [HTTP::Response](https://metacpan.org/pod/HTTP::Response), or [HTTP::Engine::Response](https://metacpan.org/pod/HTTP::Engine::Response).

- $session->keys()

    keys of session.

- $session->get(key)

    get session item

- $session->set(key, val)

    set session item

- $session->remove(key)

    remove item.

- $session->as\_hashref()

    session as hashref.

- $session->expire()

    expire the session

- $session->regenerate\_session\_id(\[$delete\_old\])

    regenerate session id.remove old one when $delete\_old is true value.

- $session->finalize()

    commit the session data.

# CLEANUP SESSION

Some storage doesn't care the old session data.Please call $store->cleanup( $min ); manually.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

# THANKS TO

    kazuhooku
    amachang
    walf443
    yappo
    nekokak

# REPOSITORY

I use github.
repo url is here [http://github.com/tokuhirom/http-session/tree/master](http://github.com/tokuhirom/http-session/tree/master)

# SEE ALSO

[Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session), [Sledge::Session](https://metacpan.org/pod/Sledge::Session)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
