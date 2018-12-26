# NAME

LinkEmbedder - Embed / expand oEmbed resources and other URL / links

# SYNOPSIS

    use LinkEmbedder;

    my $embedder = LinkEmbedder->new;
    $embedder->get_p("http://xkcd.com/927")->then(sub {
      my $link = shift;
      print $link->html;
    })->wait;

# DESCRIPTION

[LinkEmbedder](https://metacpan.org/pod/LinkEmbedder) is a module that can expand an URL into a rich HTML snippet or
simply to extract information about the URL.

Note that this module is currently EXPERIMENTAL. It will replace
[Mojolicious::Plugin::LinkEmbedder](https://metacpan.org/pod/Mojolicious::Plugin::LinkEmbedder) when it gets stable.

These web pages are currently supported:

- [http://imgur.com/](http://imgur.com/)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=http://imgur.com/gallery/ohL3e](http://home.thorsen.pm/demo/link-embedder?url=http://imgur.com/gallery/ohL3e)

- [https://instagram.com/](https://instagram.com/)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://www.instagram.com/p/BSRYg\_Sgbqe/](http://home.thorsen.pm/demo/link-embedder?url=https://www.instagram.com/p/BSRYg_Sgbqe/)

    Instagram need some additional JavaScript. Please look at
    [https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl](https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl) and
    [https://www.instagram.com/developer/embedding/](https://www.instagram.com/developer/embedding/)
    for more information.

- [https://appear.in/](https://appear.in/)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://appear.in/link-embedder-demo](http://home.thorsen.pm/demo/link-embedder?url=https://appear.in/link-embedder-demo)

- [https://gist.github.com](https://gist.github.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://gist.github.com/jhthorsen/3738de6f44f180a29bbb](http://home.thorsen.pm/demo/link-embedder?url=https://gist.github.com/jhthorsen/3738de6f44f180a29bbb)

- [https://github.com](https://github.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t](http://home.thorsen.pm/demo/link-embedder?url=https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t)

- [https://ix.io](https://ix.io)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=http://ix.io/fpW](http://home.thorsen.pm/demo/link-embedder?url=http://ix.io/fpW)

- [https://maps.google.com](https://maps.google.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https%3A%2F%2Fwww.google.no%2Fmaps%2Fplace%2FOslo%2C%2BNorway%2F%4059.8937806%2C10.645035…m4!1s0x46416e61f267f039%3A0x7e92605fd3231e9a!8m2!3d59.9138688!4d10.7522454](http://home.thorsen.pm/demo/link-embedder?url=https%3A%2F%2Fwww.google.no%2Fmaps%2Fplace%2FOslo%2C%2BNorway%2F%4059.8937806%2C10.645035…m4!1s0x46416e61f267f039%3A0x7e92605fd3231e9a!8m2!3d59.9138688!4d10.7522454)

- [https://metacpan.org](https://metacpan.org)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://metacpan.org/pod/Mojolicious](http://home.thorsen.pm/demo/link-embedder?url=https://metacpan.org/pod/Mojolicious)

- [https://paste.fedoraproject.org/](https://paste.fedoraproject.org/)

    Example: [http://home.thorsen.pm/demo/link-embedder?https://paste.fedoraproject.org/paste/9qkGGjN-D3fL2M-bimrwNQ](http://home.thorsen.pm/demo/link-embedder?https://paste.fedoraproject.org/paste/9qkGGjN-D3fL2M-bimrwNQ)

- [http://paste.opensuse.org](http://paste.opensuse.org)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=http://paste.opensuse.org/2931429](http://home.thorsen.pm/demo/link-embedder?url=http://paste.opensuse.org/2931429)

- [http://paste.scsys.co.uk](http://paste.scsys.co.uk)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=http://paste.scsys.co.uk/557716](http://home.thorsen.pm/demo/link-embedder?url=http://paste.scsys.co.uk/557716)

- [http://pastebin.com](http://pastebin.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://pastebin.com/V5gZTzhy](http://home.thorsen.pm/demo/link-embedder?url=https://pastebin.com/V5gZTzhy)

- [https://www.spotify.com/](https://www.spotify.com/)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=spotify:track:0aBi2bHHOf3ZmVjt3x00wv](http://home.thorsen.pm/demo/link-embedder?url=spotify:track:0aBi2bHHOf3ZmVjt3x00wv)

- [https://ted.com](https://ted.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://www.ted.com/talks/jill\_bolte\_taylor\_s\_powerful\_stroke\_of\_insight](http://home.thorsen.pm/demo/link-embedder?url=https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight)

- [https://travis-ci.org](https://travis-ci.org)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://travis-ci.org/Nordaaker/convos/builds/47421379](http://home.thorsen.pm/demo/link-embedder?url=https://travis-ci.org/Nordaaker/convos/builds/47421379)

- [https://twitter.com](https://twitter.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://twitter.com/jhthorsen/status/786688349536972802](http://home.thorsen.pm/demo/link-embedder?url=https://twitter.com/jhthorsen/status/786688349536972802)

    Twitter need some additional JavaScript. Please look at
    [https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl](https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl) and
    [https://dev.twitter.com/web/javascript/initialization](https://dev.twitter.com/web/javascript/initialization)
    for more information.

- [https://vimeo.com](https://vimeo.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https://vimeo.com/154038415](http://home.thorsen.pm/demo/link-embedder?url=https://vimeo.com/154038415)

- [https://youtube.com](https://youtube.com)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DOspRE1xnLjE](http://home.thorsen.pm/demo/link-embedder?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DOspRE1xnLjE)

- [https://www.xkcd.com/](https://www.xkcd.com/)

    Example: [http://home.thorsen.pm/demo/link-embedder?url=http://xkcd.com/927](http://home.thorsen.pm/demo/link-embedder?url=http://xkcd.com/927)

- HTML

    Any web page will be parsed, and "og:", "twitter:", meta tags and other
    significant elements will be used to generate a oEmbed response.

    Example: [http://home.thorsen.pm/demo/link-embedder?url=http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html](http://home.thorsen.pm/demo/link-embedder?url=http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html)

- Images

    URLs that looks like an image is automatically converted into an img tag.

- Video

    URLs that looks like a video resource is automatically converted into a video tag.

# ATTRIBUTES

## ua

    $ua = $self->ua;

Holds a [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) object.

## url\_to\_link

    $hash_ref = $self->url_to_link;

Holds a mapping between host names and [link class](https://metacpan.org/pod/LinkEmbedder::Link) to use.

# METHODS

## get

    $self = $self->get_p($url, sub { my ($self, $link) = @_ });

Same as ["get\_p"](#get_p), but takes a callback instead of returning a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise).

## get\_p

    $promise = $self->get_p($url)->then(sub { my $link = shift });

Used to construct a new [LinkEmbedder::Link](https://metacpan.org/pod/LinkEmbedder::Link) object and retrieve information
about the URL.

## serve

    $self = $self->serve(Mojolicious::Controller->new, $url);

Used as a helper for [Mojolicious](https://metacpan.org/pod/Mojolicious) web applications to reply to an oEmbed
request.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
