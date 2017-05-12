# NAME

HTML::HeadParser::Liberal - More Liberal HTML Head Section Parsing

# SYNOPSIS

    use HTML::HeadParser::Liberal;

# DESCRIPTION

HTML::HeadParser::Liberal is an evasive module that patches HTML::HeadParser
directly (and globally) so that workarounds for certain quirks are enabled.

Currently this module supposrts the following:

- Meta names passed to HTTP::Headers are munged

    Currently all ":"'s are converted to a hyphen, so things like 

        <meta name="twitter:card" ...>

    doesn't choke, and you can access this value from HTTP::Headers like

        $h->header('X-Meta-Twitter-Card');

    Note that YOU DO NOT NEED THIS HACK if you're using a recent enough LWP.
    Because of this I was initially going to let this module die a slow death,
    but then I have since been told that there are environments stuck with old
    modules, so I guess there are some situations where this module is still
    useful.

# LICENSE

Copyright (C) Daisuke Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke Maki &lt;lestrrat>
