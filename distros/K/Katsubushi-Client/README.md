# NAME

Katubushi::Client - A client library for katsubushi

# SYNOPSIS

    use Katubushi::Client;
    my $client = Katsubushi::Client->new({
        servers => ["127.0.0.1:11212", "10.8.0.1:11212"],
    });
    my $id = $client->fetch;
    my @ids = $client->fetch_multi(3);

# DESCRIPTION

Katubushi::Client is a client library for katsubushi (github.com/kayac/go-katsubushi).

# LICENSE

Copyright (C) KAYAC Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
