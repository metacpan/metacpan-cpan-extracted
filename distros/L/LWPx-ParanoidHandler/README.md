# NAME

LWPx::ParanoidHandler - Handler for LWP::UserAgent that protects you from harm

# SYNOPSIS

    use LWPx::ParanoidHandler;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    make_paranoid($ua);

    my $res = $ua->request(GET 'http://127.0.0.1/');
    # my $res = $ua->request(GET 'http://google.com/');
    use Data::Dumper; warn Dumper($res);
    warn $res->status_line;

# DESCRIPTION

LWPx::ParanoidHandler is clever fire wall for LWP::UserAgent.
This module provides a handler to protect a request to internal servers.

It's useful to implement OpenID servers, crawlers, etc.

# FUNCTIONS

- make\_paranoid($ua\[, $dns\]);

    Make your LWP::UserAgent instance to paranoid.

    The $dns argument is instance of [Net::DNS::Paranoid](https://metacpan.org/pod/Net::DNS::Paranoid). It's optional.

# FAQ

- How can I timeout per request?

    Yes, [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) does not timeouts per request.

    I think it's my job. But [LWPx::ParanoidAgent](https://metacpan.org/pod/LWPx::ParanoidAgent) do this.

    You can do this by following form using alarm():

        my $res = eval {
            local $SIG{ALRM} = sub { die "ALRM\n" };
            alarm(10);
            my $res = $ua->get($url);
            alarm(0);
            $res;
        };
        $res = HTTP::Response->new(500, 'Timeout') unless $res;

    And I recommend to use [Furl](https://metacpan.org/pod/Furl). Furl can handle per-request timeout cleanly.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[LWPx::ParanoidAgent](https://metacpan.org/pod/LWPx::ParanoidAgent) have same feature as this module. But it's not currently maintain, and it's too hack-ish. LWPx::ParanoidHandler uses handler protocol provided by LWP::UserAgent, it's more safety.

This module uses a lot of code taken from LWPx::ParanoidAgent, thanks.

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
