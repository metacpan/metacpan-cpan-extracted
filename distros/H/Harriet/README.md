# NAME

Harriet - Daemon manager for testing

# SYNOPSIS

    use Harriet;

    my $harriet = Harriet->new('./t/harriet/');
    $harriet->load('stf');
    print $ENV{TEST_STF}, "\n";

# DESCRIPTION

**(THIS MODULE IS CURRENTLY UNDER DEVELOPMENT.)**

In some case, test code requires daemons like memcached, STF, or groonga.
If you are running these daemons for each test scripts, it eats lots of time.

Then, you need to keep the processes under the test suite.

Harriet solves this issue.

Harriet loads all daemons when starting [prove](https://metacpan.org/pod/prove). And set the daemon's end point to the environment variable.
And run the test cases. Test script can use the daemon process (You need to clear the data if you need.).

# TUTORIAL

## Writing harriet script

harriet script is just a perl script has `.pl` extension. Example code is here:

    # t/harriet/memcached.pl
    use strict;
    use utf8;

    use Test::TCP;

    $ENV{TEST_MEMCACHED} ||= do {
        my $server = Test::TCP->new(
            code => sub {
                my $port = shift;
                exec '/usr/bin/memcached', '-p', $port;
                die $!;
            }
        );
        $HARRIET_GUARDS::MEMCACHED = $server;
        '127.0.0.1:' . $server->port;
    };

This code runs memcached. It returns memcached's end point information and guard object. Harriet keeps guard objects while perl process lives.

(Guard object is optional.)

## Load harriet script

    use Harriet;

    my $harriet = Harriet->new('./t/harriet');
    $harriet->load('memcached');
    print $ENV{memcached}, "\n";

This script load the memcached daemon setup script.
harriet loads harriet script named 't/harriet/memcached.pl'.

## Save daemon process under the prove

    # .proverc
    -PHarriet=./t/harriet/

[App::Prove::Plugin::Harriet](https://metacpan.org/pod/App::Prove::Plugin::Harriet) loads harriet scripts under the `t/harriet/`, and set these to environment variables.

This plugin starts daemons before running test cases!

# WHY Harriet?

[Harriet](http://en.wikipedia.org/wiki/Harriet_\(tortoise\)) is very long lived tortoise. Harriet.pm makes long lived process.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
