# NAME

LinkEmbedder - Embed / expand oEmbed resources and other URL / links

# SYNOPSIS

    use LinkEmbedder;

    my $embedder = LinkEmbedder->new(force_secure => 1);

    $embedder->get_p("https://xkcd.com/927")->then(sub {
      my $link = shift;
      print $link->html;
    })->wait;

# DESCRIPTION

[LinkEmbedder](https://metacpan.org/pod/LinkEmbedder) is a module that can expand an URL into a rich HTML snippet or
simply to extract information about the URL.

This module replaces [Mojolicious::Plugin::LinkEmbedder](https://metacpan.org/pod/Mojolicious::Plugin::LinkEmbedder).

Go to [https://thorsen.pm/linkembedder](https://thorsen.pm/linkembedder) to see a demo of how it works.

These web pages are currently supported:

- [https://imgur.com/](https://imgur.com/)
- [https://instagram.com/](https://instagram.com/)

    Instagram need some additional JavaScript. Please look at
    [https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl](https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl) and
    [https://www.instagram.com/developer/embedding/](https://www.instagram.com/developer/embedding/)
    for more information.

- [https://appear.in/](https://appear.in/)
- [https://gist.github.com](https://gist.github.com)
- [https://github.com](https://github.com)
- [http://ix.io](http://ix.io)
- [https://maps.google.com](https://maps.google.com)
- [https://metacpan.org](https://metacpan.org)
- [https://paste.fedoraproject.org/](https://paste.fedoraproject.org/)
- [https://paste.opensuse.org](https://paste.opensuse.org)
- [http://paste.scsys.co.uk](http://paste.scsys.co.uk)
- [https://pastebin.com](https://pastebin.com)
- [https://www.spotify.com/](https://www.spotify.com/)
- [https://ted.com](https://ted.com)
- [https://travis-ci.org](https://travis-ci.org)
- [https://twitter.com](https://twitter.com)

    Twitter need some additional JavaScript. Please look at
    [https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl](https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl) and
    [https://dev.twitter.com/web/javascript/initialization](https://dev.twitter.com/web/javascript/initialization)
    for more information.

- [https://vimeo.com](https://vimeo.com)
- [https://youtube.com](https://youtube.com)
- [https://www.xkcd.com/](https://www.xkcd.com/)
- HTML

    Any web page will be parsed, and "og:", "twitter:", meta tags and other
    significant elements will be used to generate a oEmbed response.

- Images

    URLs that looks like an image is automatically converted into an img tag.

- Video

    URLs that looks like a video resource is automatically converted into a video tag.

# ATTRIBUTES

## force\_secure

    $bool = $self->force_secure;
    $self = $self->force_secure(1);

This attribute will translate any unknown http link to https.

This attribute is EXPERIMENTAL. Feeback appreciated.

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
